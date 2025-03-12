//
//  IdentifyModelParsing.swift
//  Device
//
//  Created by Ben Ku on 3/10/25.
//


#if canImport(SwiftUI)
import SwiftUI
#if canImport(Device) // since this is needed in XCode but is unavailable in Playgrounds.
import Device
import Color
import Compatibility
#endif

// For Compatibility
public extension CharacterSet {
    func allCharacters() -> [Character] {
        var result: [Character] = []
        for plane: UInt8 in 0...16 where self.hasMember(inPlane: plane) {
            for unicode in UInt32(plane) << 16 ..< UInt32(plane + 1) << 16 {
                if let uniChar = UnicodeScalar(unicode), self.contains(uniChar) {
                    result.append(Character(uniChar))
                }
            }
        }
        return result
    }
    var asString: String {
        return String(self.allCharacters())
    }
}
public extension String {
    var normalizedCollapsedWhitespace: String {
        return self.normalized.replacingCharacters(in: .whitespacesAndNewlines, with: "")
    }
}

struct ParsedItem: Identifiable {
    var string: String
    
    var title: String?
    var image: String?
    var identifiers: [String]?
    var partNumbers: [String]?
    var supportId: String?
    var newestCompatibleOS: String?
    var unsupportedOSVersion: Version?

    var device: Device?
    var updatedDevice: Device

    var id: String { string }
    
    // TODO: Find a way to have this parse an item and create a second item for merged entries (with different processors).  Perhaps have static func that returns an array of items?  Similarly consolidate Apple Watch models (if returns a similar parsed item, then we should be able to de-dup?  Or just count twice).
    init?(string: String) {
        self.string = string
        var string = string.replacingOccurrences(of: "‑", with: "-")
        var parsedIdiom = Device.Idiom.unspecified
        // make sure this isn't the header or footer section
        // note: original iphone has "The model number" so M isn't capitalized.
        guard string.contains("Model Identifier") || string.contains("odel number") || string.contains("Model:") else {
            return nil
        }
        // strip out headers that aren't stripped from above.
        if string.contains("<!DOCTYPE html>") || string.contains("Find the model number") || string.contains("Find your Apple TV model number") {
            return nil
        }
        if string.hasPrefix("Find the model number") {
            string = string.extract(from: "<h2 id=\"ipadpro\" class=\"gb-header\">", to: nil) ?? string
        }
        // Apple TV sections don't have the identifier, just the model number
        guard var title = string.extract(from: nil, to: "</") else {
            return nil // needs a title at least!
        }
        if title.contains("src="), let macbookTitle = title.extract(from: nil, to: "\"") {
            title = macbookTitle
        }
        if title.contains("iPod") && !title.contains("iPod touch") {
            // don't include iPods that aren't touches
            return nil
        }
        title = title.tagsStripped.trimmed
        self.title = title
        if let imageTag = string.extract(from: "<img class=\"gb-image\"", to: "/>"), let imageURL = imageTag.extract(from: "src=\"", to: "\"") {
            self.image = imageURL
        }
        let isiPhone = string.contains("iPhone")
        if isiPhone {
            parsedIdiom = .phone
        }
        if string.contains("iPad") || string.contains("iPod") || isiPhone, var modelNumbers = string.extract(from: "odel number", to: isiPhone ? "</p>" : "</ul>") {
            // ipads (need to add the </p> tag since stripping tags may result in stuff between lines being removed.
            modelNumbers = modelNumbers.replacingOccurrences(of: ["</p>", "back cover", ".", ")", ":", "on", "and", "April", "August", "America", "Air", "Arab", "iPad", "Cellular", "Wi-Fi"], with: " ").tagsStripped.whitespaceCollapsed
            let modelNumbers = modelNumbers.split(separator: " ").filter { $0.count > 3 && $0.hasPrefix("A") }.map { String($0) }
            self.partNumbers = modelNumbers
            if modelNumbers.count > 0 {
                self.device = Device.lookup(model: modelNumbers.first!, officialNameHint: title).first
            }
        } else if var modelNumber = string.extract(from: "odel number", to: "</p>") {
            // apple tv
            if title.contains("Apple TV"), let model = modelNumber.extract(from: ": ", to: " ") {
                modelNumber = model
                parsedIdiom = .tv
                self.partNumbers = [modelNumber]
            } else {
                debug("Models that are not Apple TV")
            }
            self.device = Device.lookup(model: modelNumber, officialNameHint: title).first
        } else if let partNumbers = string.extract(from: "Part Number", to: "</p>"), let partNumbers = partNumbers.extract(from: ">", to: nil)?.replacingOccurrences(of: "&nbsp;", with: " ") {
            // macs
            self.partNumbers = partNumbers.replacingOccurrences(of: "; ", with: ", ").components(separatedBy: ", ").map { $0.trimmed }
        } else if let modelNumber = string.extract(from: "<ul class=\"list gb-list\"><li class=\"gb-list_item\"><p class=\"gb-paragraph\">", to: "</ul>") {
            // get case models (need to return 2 parsed items!) - just pull first case and up to user to copy to second?
            if let caseSize = modelNumber.extract(from: nil, to: " case"), let modelNumber = modelNumber.replacingOccurrences(of: ")", with: " ").extract(from: "Model: ", to: " "), var title = self.title?.replacingOccurrences(of: ["(GPS)", "(GPS + Cellular)", "Aluminum", "Stainless Steel"], with: "").trimmed {
                // Apple Watch
                if !title.contains("Ultra") {
                    title += " \(caseSize)"
                }
                self.title = title
                self.partNumbers = [modelNumber]
                self.device = Device.lookup(model: modelNumber, officialNameHint: title).first
            }
        }
        self.partNumbers = self.partNumbers?.unique
        if let newestCompatibleOS = string.extract(from: "Newest compatible operating system", to: "</p>") {
            if let newestCompatibleOS = newestCompatibleOS.extract(from: ">", to: nil)?.trimmed {
                self.newestCompatibleOS = newestCompatibleOS
                // determine version
                for (version, _) in Version.macOSs {
                    if version.previousMacOS().macOSName == newestCompatibleOS {
                        self.unsupportedOSVersion = version
                    }
                }
            }
        }
        if let supportId = string.extract(from: "<a href=\"/en-us/", to: "\"") {
            self.supportId = supportId
        } else if let supportId = string.extract(from: "See the <a href=\"https://support.apple.com/kb/", to: "\"") {
            self.supportId = supportId
        } else if let supportId = string.extract(from: "See the <a href=\"https://support.apple.com/", to: "\"") {
            // iPads don't have the /kb/ part.
            self.supportId = supportId
        }
        if let identifierTag = string.extract(from: "Model Identifier", to: "</p>") {
            // could be multiple!  Pull first one
            let identifiers = identifierTag.replacingOccurrences(of: ", ", with: ";").replacingOccurrences(of: [":"," "], with: "").tagsStripped.components(separatedBy: ";").map { $0.trimmed }
            self.identifiers = identifiers
            if let identifier = identifiers.first {
                self.device = Device.lookup(identifier: identifier, officialNameHint: title).first
            }
//            let device = Device(identifier: self.identifiers!.first!, officialNameHint: self.title)
//            self.device = device
        }
        if let supportId, device == nil {
            device = Device.lookup(supportId: supportId).first
        }
        // try to parse idiom
        if parsedIdiom == .unspecified {
            for idiom in Device.Idiom.allCases {
                if string.contains(idiom.identifier) {
                    parsedIdiom = idiom
                    break
                }
            }
        }
        if let device, device.safeOfficialName.normalizedCollapsedWhitespace.trimming(device.cpu.caseName) == title.normalizedCollapsedWhitespace {
            title = device.officialName // ignore written name and use the matching device name
        }
        // TODO: check for string.contains("Thunderbolt") to register capability
        self.updatedDevice = Device(
            idiom: parsedIdiom,
            officialName: title,
            identifiers: identifiers ?? device?.identifiers ?? [],
            supportId: supportId ?? device?.supportId ?? .unknownSupportId,
            launchOSVersion: device?.launchOSVersion ?? "0.0",
            unsupportedOSVersion: unsupportedOSVersion ?? device?.unsupportedOSVersion,
            image: image ?? device?.image,
            capabilities: device?.capabilities ?? [],
            models: partNumbers ?? device?.models ?? [],
            colors: device?.colors ?? .default,
            cpu: device?.cpu ?? .unknown
        )
    }
    
    var exactMatch: Bool {
        device?.definition == updatedDevice.definition
    }
}

@MainActor
class PageParser: ObservableObject {
    static var shared = PageParser()
    static var identifyPages = [
        "MacBook Pros": "https://support.apple.com/en-us/108052",
        "iPods": "https://support.apple.com/en-us/103823",
        "iPads": "https://support.apple.com/en-us/108043",
        "iPhones": "https://support.apple.com/en-us/108044",
        "MacBook Air": "https://support.apple.com/en-us/102869",
        "MacBooks": "https://support.apple.com/en-us/103257",
        "iMacs": "https://support.apple.com/en-us/108054",
        "Mac Pros": "https://support.apple.com/en-us/102887",
        "Mac minis": "https://support.apple.com/en-us/102852",
        "Mac Studios": "https://support.apple.com/en-us/102231",
        "Apple TVs": "https://support.apple.com/en-us/101605",
        "Apple Watches": "https://support.apple.com/en-us/108056",
    ]
    
    
    @Published var url: String? {
        didSet {
            parsing = true
            background {
                await self.parse()
            }
        }
    }
    @Published var parsing = false
    @Published var content: String?
    @Published var items: [ParsedItem] = []
        
    func parse() async {
        defer {
            parsing = false
        }
        guard let url else {
            debug("Attempting to parse when URL not set!", level: .ERROR)
            return
        }
        do {
            content = try await fetchURL(urlString: url)
            if content?.contains("<h2 id=\"one\" class=\"gb-header\">") ?? false, let parts = content?.components(separatedBy: "<h3 class=\"gb-header\">") {
                // Apple Watch pages
                items = parts.compactMap { ParsedItem(string: $0) }
            } else if content?.contains("<h2 class=\"gb-header") ?? false, let parts = content?.components(separatedBy: "<h2 class=\"gb-header alignment horizontal-align-left\">"), parts.count > 1 {
                // iPod Touch page is sectioned differently
                items = parts.compactMap { ParsedItem(string: $0) }
            } else if content?.contains("<h3 class=\"gb-header\">") ?? false, let parts = content?.components(separatedBy: "<img class=\"gb-image\" alt=\"") {
                // MacBook page is sectioned differently
                items = parts.compactMap { ParsedItem(string: $0) }
            } else if let parts = content?.components(separatedBy: "<h2 class=\"gb-header\">") {
                items = parts.compactMap { ParsedItem(string: $0) }
            }
        } catch {
            debug(error)
        }
    }
}

protocol StringRepresentable {
    var str: String { get }
}
extension String: StringRepresentable {
    var str: String { self }
}
extension [String]: StringRepresentable {
    var str: String { self.joined(separator: ", ") }
}
extension Optional: StringRepresentable {
    public var str: String {
        if self == nil {
            return "nil"
        }
        if let version = self as? Version? {
            guard let version else {
                // latest version should apply
                let currentVersion = Array(Version.macOSs.keys).last!
                return currentVersion.macOSName
            }
            let previous = version.previousMacOS()
            return previous.macOSName
        }
        if let string = self as? String?, let string {
            return string
        }
        if let strings = self as? [String]?, let strings {
            return strings.str
        }
        return "Unknown"
    }
}

public extension String {
    var whitespaceStripped: String {
        replacingCharacters(in: .whitespacesAndNewlines, with: "")
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct ValueDiffView<DeviceType: StringRepresentable, ItemType: StringRepresentable>: View {
    var item: ParsedItem
    var deviceKeypath: KeyPath<Device, DeviceType>
    var itemKeypath: KeyPath<ParsedItem, ItemType>
    var deviceString: String? {
        guard let device = item.device else { return nil }
        return device[keyPath: deviceKeypath].str
    }
    var itemString: String {
        return item[keyPath: itemKeypath].str
    }
    var deviceKeyName: String {
        String(describing: deviceKeypath).replacingOccurrences(of: "\\Device.", with: "")
    }
    var itemKeyName: String {
        String(describing: itemKeypath).replacingOccurrences(of: "\\ParsedItem.", with: "")
    }
    
    var body: some View {
        // check for prefix since we may have a more specific device version like "Mac mini (2024)" vs "Mac mini (2024) M4 Pro"
        if let deviceString, deviceString != itemString {
            Backport.LabeledContent("Device \(deviceKeyName)", value: deviceString.definition)
                .backport.textSelection(.enabled)
            Backport.LabeledContent("Parsed \(itemKeyName)", value: itemString.definition)
                .backport.textSelection(.enabled)
            Divider()
//        } else {
//            Text("NO DEVICE STRING or Device contained in Item or Item contained in Device")
//            Backport.LabeledContent("Device \(deviceKeyName)", value: "\"\(String(describing: deviceString))\"")
//            Backport.LabeledContent("Parsed \(itemKeyName)", value: "\"\(itemString)\"")
//                .textSelection(.enabled)
//            Divider()
        }
    }
}

public extension String {
    var lines: [String] {
        return self.components(separatedBy: "\n")
    }
    func collapse(_ string: String) -> String {
        var returnString = self
        // collapse runs
        let double = string + string
        while returnString.contains(double) {
            returnString = returnString.replacingOccurrences(of: double, with: string)
        }
        return returnString
    }
    var superCollapseWhitespace: String {
        self.whitespaceCollapsed.replacingOccurrences(of: " \n", with: "\n").whitespaceCollapsed
    }
}

public extension Text {
    @inlinable
    static func += (lhs: inout Text, rhs: Text) {
        lhs = lhs + rhs
    }
}
public extension [Text] {
    func joined(separator: Text = Text("")) -> Text {
        var joined = Text("")
        for element in self {
            joined += element
            if element != self.last! {
                joined += separator
            }
        }
        return joined
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct DiffView: View {
    var stringA: String
    var stringB: String
    enum DiffMode: CaseIterable {
        case left
        case both
        case right
    }
    @State var viewMode: DiffMode = .both
    func mergedLine(_ a: String?, _ b: String?) -> Text {
        var merged: [Text] = []
        if let a {
            if a != b {
                merged += [Text(a)
                    .foregroundColor(.blue)]
            } else {
                merged += [Text(a)]
            }
        }
        if let b, a != b {
            merged += [Text(b)
                .foregroundColor(Color.magenta)]
        }
        return merged.joined(separator: Text("\n"))
    }
    
    func merged(_ a: String?, _ b: String?) -> Text {
        var merged: [Text] = []
        let stringsA = a?.lines ?? []
        let stringsB = b?.lines ?? []
        let maxLineCount = max(stringsA.count, stringsB.count)
        for i in 0..<maxLineCount {
            merged += [mergedLine(stringsA[safe: i], stringsB[safe: i])]
        }
        return merged.joined(separator: Text("\n"))
    }
    
    var body: some View {
        Picker("Show", selection: $viewMode) {
            ForEach(DiffMode.allCases, id: \.self) { mode in
                Text(String(describing: mode))
                    .tag(mode)
            }
        }
        .pickerStyle(.segmentedBackport)
        merged(viewMode == .right ? nil : stringA, viewMode == .left ? nil : stringB)
            .backport.textSelection(.enabled)
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview {
    List {
        DiffView(stringA: Device(identifier: "iPhone16,1").definition, stringB: Device(identifier: "iPhone16,2").definition)
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct PageParserRow: View {
    var item: ParsedItem

    enum ViewMode: CaseIterable {
        case diff
        case items
        case html
    }
    @State var mode = ViewMode.diff
    var body: some View {
        if let device = item.device {
            VStack {
                DeviceInfoView(device: device)
                    .background(item.exactMatch ? .green : .red)
                if !item.exactMatch {
                    Picker("Show", selection: $mode) {
                        ForEach(ViewMode.allCases, id: \.self) { mode in
                            Text(String(describing: mode))
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmentedBackport)
                    if mode == .items {
                        ValueDiffView(item: item, deviceKeypath: \.officialName, itemKeypath: \.title)
                        ValueDiffView(item: item, deviceKeypath: \.identifiers, itemKeypath: \.identifiers)
                        ValueDiffView(item: item, deviceKeypath: \.supportId, itemKeypath: \.supportId)
                        ValueDiffView(item: item, deviceKeypath: \.image, itemKeypath: \.image)
                        ValueDiffView(item: item, deviceKeypath: \.models, itemKeypath: \.partNumbers)
                        ValueDiffView(item: item, deviceKeypath: \.unsupportedOSVersion, itemKeypath: \.unsupportedOSVersion)
                    }
                    if mode == .diff {
                        DiffView(stringA: item.device?.definition ?? "NO DEVICE", stringB: item.updatedDevice.definition)
                    }
                    if mode == .html {
                        Text(item.string.superCollapseWhitespace)
                            .backport.textSelection(.enabled)
                    }
                }
                Divider()
            }
        } else {
            VStack {
                Text(item.title ?? "Unknown")
                    .backport.background(.red)
                DiffView(stringA: item.device?.definition ?? "NO DEVICE", stringB: item.updatedDevice.definition)
                Text(item.string.superCollapseWhitespace)
                    .backport.textSelection(.enabled)
            }
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct IdentifyModelParsingView: View {
    
    @ObservedObject var pageParser = PageParser.shared
    
    @State var searchText = "" {
        didSet {
            debug("Setting parsing URL to \(searchText)")
            pageParser.url = searchText
        }
    }
    
    var body: some View {
        List {
            if pageParser.url != nil {
                if pageParser.parsing {
                    ProgressView("Parsing…")
                } else if pageParser.items.count == 0 {
                    Text("Unable to parse results!")
                    Text(pageParser.content ?? "NO CONTENT")
                        .backport.textSelection(.enabled)
                } else {
                    ForEach(pageParser.items) { item in
                        PageParserRow(item: item)
                    }
                }
            } else {
                Text("Enter URL above to parse or select one of the presets below:")
                ForEach(PageParser.identifyPages.sorted(by: >), id: \.key) { (label, page) in
                    Button(label) {
                        self.searchText = page
                    }
                }
            }
        }
        .toolbar {
            Button("Reset") {
                pageParser.url = nil
            }
        }
        .searchable(text: $searchText) // Adds a search field.
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview {
    IdentifyModelParsingView()
}

#endif
