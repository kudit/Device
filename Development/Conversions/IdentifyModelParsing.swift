//
//  IdentifyModelParsing.swift
//  Device
//
//  Created by Ben Ku on 3/10/25.
//


#if canImport(Device) // since this is needed in XCode but is unavailable in Playgrounds.
import Device
import Color
import Compatibility
#endif

// For Compatibility
public extension String {
    /// Normalized string removing any whitespace characters.
    var normalizedCollapsedWhitespace: String {
        return self.normalized.replacingCharacters(in: .whitespacesAndNewlines, with: "")
    }
}
public extension String {
    /// Whitespace collapsed and then replacing occurrances of ` \n` with `\n` and then collapsed again.
    var superCollapseWhitespace: String {
        self.whitespaceCollapsed.replacingOccurrences(of: " \n", with: "\n").whitespaceCollapsed
    }
}

public extension Capabilities {
    /// Returns `true` iff the array contains all of the values.
    func containsAll(_ capabilities: Capabilities) -> Bool {
        if capabilities.macForm != self.macForm {
            return false
        }
//        if capabilities.pencils != self.pencils { // may want to check but this breaks if this has pencils and capabilities has none.
//            return false
//        }
        for capability in capabilities {
            if !Capability.allCases.contains(capability) {
                continue // skip non simple capabilities
            }
            if !self.contains(capability) {
                return false
            }
        }
        return true
    }
}

struct ParsedItem: DeviceBridge {    
    static var diffIgnoreKeys: [String] {
        ["source"] // filter out and ignore these paths when calculating exact match - for things like DeviceKit comments or images/support URLs since we know those may differ
    }

    var officialName: String
    var idiom = Device.Idiom.unspecified
    var identifiers: [String] = []
    var yearIntroduced: Int?
    var supportId = String.unknownSupportId
    var unsupportedOSVersion: Version? = nil
    var image: String? = nil
    var capabilities = Capabilities()
    var partNumbers: [String] = []
    var cpu = CPU.unknown
    var source: String
    
    // since multiple bridges may have the same source, unique ID
    var id: String {
        "\(officialName)\(source)"
    }
    
    var matched: Device {
        Device.forcedLookup(identifier: identifiers.first, model: partNumbers.first, officialNameHint: officialName)
    }

    var merged: Device {
        // create device for each identifier since we may want to split out
        return Device(
            idiom: idiom,
            officialName: officialName,
            identifiers: identifiers,
            introduction: yearIntroduced?.introductionYear,
            supportId: supportId,
            launchOSVersion: .zero,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities,
            models: partNumbers,
            colors: .default,
            cpu: cpu
        ).merged(from: matched)
    }
    
    func bridge(from device: Device) -> ParsedItem {
        var officialName = device.officialName
        if device.safeOfficialName.lowercased() == self.officialName.lowercased() || device.officialName.contains(self.officialName) { // last case is to capture Mac16,6, Mac16,7, and others that had to be split into two entries for different processors.
            officialName = self.officialName
        }
        // zero out fields/data that aren't available in the parsed item so we match
        var yearIntroduced = device.introduction?.date?.year
        if self.yearIntroduced == nil {
            yearIntroduced = nil // don't bother comparing if we don't have this data
        }
        var supportId = device.supportId
        if self.supportId == .unknownSupportId {
            supportId = .unknownSupportId 
        }
        var unsupportedOSVersion = device.unsupportedOSVersion
        if self.unsupportedOSVersion == nil {
            unsupportedOSVersion = nil
        }
        var capabilities = device.capabilities
        if self.capabilities.isEmpty || capabilities.containsAll(self.capabilities) {
            capabilities = self.capabilities
        }
        var models = device.models
        if models.containsAll(self.partNumbers) || self.partNumbers.containsAll(models) && device.identifiers.containsAny(["Mac16,7"]) { // check for split items
            models = self.partNumbers
        }
        var cpu = device.cpu
        if self.cpu == .unknown {
            cpu = .unknown
        }
        return ParsedItem(
            officialName: officialName,
            idiom: device.idiom,
            identifiers: device.identifiers,
            yearIntroduced: yearIntroduced,
            supportId: supportId,
            unsupportedOSVersion: unsupportedOSVersion,
            image: device.image,
            capabilities: capabilities,
            partNumbers: models,
            cpu: cpu,
            source: source)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 8, *)
actor PageParser: DeviceBridgeLoader {
    static let identifyPages = [
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

    let url: String
    var content: String?
    var items: [ParsedItem] = []

    init(url: String) {
        self.url = url
    }

    func devices() async -> [ParsedItem] {
        let content = try? await fetchURL(urlString: url)
        if content?.contains("Identify your Apple Watch") ?? false, let parts = content?.components(separatedBy: "<h2 ") {
            // Apple Watch pages
            let parts = parts.dropFirst().dropFirst().dropLast().dropLast() // top header & find your part header and learn more footer and legal footer.
            parts.forEach { parseItem(source: $0) }
        } else if content?.contains("<h2 class=\"gb-header") ?? false, let parts = content?.components(separatedBy: "<h2 class=\"gb-header alignment horizontal-align-left\">"), parts.count > 1 {
            // iPod Touch page is sectioned differently
            parts.forEach { parseItem(source: $0) }
        } else if content?.contains("<h3 class=\"gb-header\">") ?? false, let parts = content?.components(separatedBy: "<img class=\"gb-image\" alt=\"") {
            // MacBook page is sectioned differently
            parts.forEach { parseItem(source: $0) }
        } else if let parts = content?.components(separatedBy: "<h2 class=\"gb-header\">") {
            let parts = parts.dropFirst() // top header
            parts.forEach { parseItem(source: $0) }
        }
        return items
    }

    func parseItem(source: String) {
        var idiom = Device.Idiom.unspecified
        var identifiers: [String] = []
        var yearIntroduced: Int? = nil
        var supportId = String.unknownSupportId
        var unsupportedOSVersion: Version? = nil
        var image: String? = nil
        var image2: String? = nil
        var capabilities = Capabilities()
        var partNumbers: [String] = []
        var cpu = CPU.unknown
        var watchCaseModels = [String: [String]]() // map case size to part numbers
        var watchIdentifiers = [String: [String]]() // map case size to set of identifiers

        var string = source.replacingOccurrences(of: "‑", with: "-") // replace non-breaking hyphen with normal hyphen.

        // Apple TV sections don't have the identifier, just the model number
        guard var officialName = string.extract(from: nil, to: "</") else {
            debug("Parse could not find a name section in: \(source)", level: .WARNING)
            return // needs a title at least!
        }
        if officialName.contains("src="), let macbookTitle = officialName.extract(from: nil, to: "\"") {
            officialName = macbookTitle
        }
        if officialName.contains("iPod") && !officialName.contains("iPod touch") {
            return // don't include iPods that aren't touches
        }
        if officialName.contains("Apple Watch") {
            // pull off partial start tag
            guard let trimmed = officialName.extract(from: "class=\"gb-header\">", to: nil) else {
                debug("Unable to get name for Apple Watch!: \(officialName)", level: .WARNING)
                return
            }
            officialName = trimmed.tagsStripped
//            debug("Parsing \(officialName)")
            idiom = .watch
        }
        officialName = officialName.tagsStripped.trimmed.whitespaceCollapsed.replacingOccurrences(of: " M4 Pro or M4 Max", with: "")

        // make sure this isn't the header or footer section
        // note: original iphone has "The model number" so M isn't capitalized.
        guard string.contains("Model Identifier") || string.contains("odel number") || string.contains("Model:") else {
            debug("No models so skipping", level: .WARNING)
            return // don't add any
        }
        // strip out headers that aren't stripped from above.
        if string.contains("<!DOCTYPE html>") || string.contains("Find the model number") || string.contains("Find your Apple TV model number") {
            // bad Apple TV section
            return // don't add
        }
        // strip out additional header
        if string.hasPrefix("Find the model number") {
            string = string.extract(from: "<h2 id=\"ipadpro\" class=\"gb-header\">", to: nil) ?? string
        }

        // get introduction year
        if string.contains("Year introduced"), var yearIntroducedString = string.extract(from: "Year introduced: ", to: "</p>") {
            if yearIntroducedString.contains(" ") { // iPhone 3G and 4 have multple dates.
                yearIntroducedString = yearIntroducedString.replacingOccurrences(of: ",", with: " ").extract(from: nil, to: " ") ?? yearIntroducedString
            }
            yearIntroduced = Int(yearIntroducedString)
        } else {
            // try looking for year in officialName
            for year in 2000...Date.nowBackport.year {
                if officialName.contains("\(year)") {
                    yearIntroduced = Int(year)
                }
            }
        }
        
        if let identifierTag = string.extract(from: "Model Identifier", to: "</p>") {
            // could be multiple!  Pull first one
            // TODO: Possibly branch for multiple devices ParsedItems here?  If there is a pattern, set a flag to not merge?
            identifiers = identifierTag.replacingOccurrences(of: ", ", with: ";").replacingOccurrences(of: [":"," "], with: "").tagsStripped.components(separatedBy: ";").map { $0.trimmed }
//            let device = Device(identifier: self.identifiers!.first!, officialNameHint: self.title)
//            self.device = device
        }

        // get image URL
        let imageTag = string.extract(from: "<img class=\"gb-image\"", to: "/>") ?? string
        if let imageURL = imageTag.extract(from: "src=\"", to: "\"") {
            image = imageURL
        }
        // for Apple Watch (get alternate image for larger size)
        if idiom == .watch {
            let imageParts = string.components(separatedBy: "<img").compactMap { $0.extract(from: "src=\"", to: "\"") }
            for ip in imageParts {
                if ip.containsAny(["stainless", "titanium"]) {
                    image2 = ip
                    break
                }
            }
            if image2 == nil {
                image2 = image
            }
        }
        
        let isiPhone = string.contains("iPhone")
        if isiPhone {
            idiom = .phone
        }
        let modelStartTag = "<ul class=\"list gb-list\"><li class=\"gb-list_item\"><p class=\"gb-paragraph\">"
        if string.contains("iPad") || string.contains("iPod") || isiPhone, var modelNumbers = string.extract(from: "odel number", to: isiPhone ? "</p>" : "</ul>") {
            // ipads (need to add the </p> tag since stripping tags may result in stuff between lines being removed.
            modelNumbers = modelNumbers.replacingOccurrences(of: ["</p>", "back cover", ".", ")", ":", "on", "and", "April", "August", "America", "Air", "Arab", "Armenia", "iPad", "Cellular", "Wi-Fi", ","], with: " ").tagsStripped.whitespaceCollapsed
            let modelNumbers = modelNumbers.split(separator: " ").filter { $0.count > 3 && $0.hasPrefix("A") }.map { String($0) }
            partNumbers = modelNumbers
        } else if var modelNumber = string.extract(from: "odel number", to: "</p>") {
            // apple tv
            if officialName.contains("Apple TV"), let model = modelNumber.extract(from: ": ", to: " ") {
                modelNumber = model
                idiom = .tv
                partNumbers = [modelNumber]
            } else {
                debug("Models that are not Apple TV")
            }
        } else if let extractedPartNumbers = string.extract(from: "Part Number", to: "</p>"), let extractedPartNumbers = extractedPartNumbers.extract(from: ">", to: nil)?.replacingOccurrences(of: "&nbsp;", with: " ") {
            // macs
            partNumbers = extractedPartNumbers.replacingOccurrences(of: "; ", with: ", ").components(separatedBy: ", ").map { $0.trimmed }
        } else if idiom == .watch {
            let watchModelParts = string.components(separatedBy: modelStartTag)
            for watchModelPart in watchModelParts {
                guard watchModelPart.contains("mm case") else {
                    continue
                }
                if let modelNumbersSection = watchModelPart.extract(from: nil, to: "</ul>") {
                    // get case models (need to return multiple parsed items)
                    let modelParts = modelNumbersSection.components(separatedBy: "</li>")
                    for modelPart in modelParts {
                        let modelPart = modelPart.tagsStripped.whitespaceCollapsed.trimmed
                        // determine case
                        guard let caseSize = modelPart.extract(from: nil, to: " case ") else {
                            continue
                        }
                        guard let modelsSection = modelPart.extract(from: "Model:", to: ")") else {
                            continue
                        }
                        let models = modelsSection.components(separatedBy: ";")
                        for model in models {
                            guard let model = model.trimmed.components(separatedBy: " ").first else {
                                continue
                            }
                            watchCaseModels[caseSize, default: []] += [model]
                        }
                    }
                }
            }

        } else if let modelNumber = string.extract(from: modelStartTag, to: "</ul>") {
            // get case models (need to return 2 parsed items!) - just pull first case and up to user to copy to second?
            if let caseSize = modelNumber.extract(from: nil, to: " case"), let modelNumber = modelNumber.replacingOccurrences(of: ")", with: " ").extract(from: "Model: ", to: " ") {
                var title = officialName.replacingOccurrences(of: ["(GPS)", "(GPS + Cellular)", "Aluminum", "Stainless Steel"], with: "").trimmed
                // Apple Watch
                if !title.contains("Ultra") {
                    title += " \(caseSize)"
                }
                officialName = title
                partNumbers = [modelNumber]
            }
        } else if let extractedPartNumbers = string.extract(from: "Model: ", to: ")") {
            let modelNumbers = extractedPartNumbers.split(separator: " ").filter { $0.count > 3 && $0.hasPrefix("A") && !$0.hasPrefix("As") && !$0.hasPrefix("Am") }.map { String($0) }
            partNumbers = modelNumbers
        }
        partNumbers.removeDuplicates()
//        partNumbers.sort() // we actually want the order parsed as this may not be alphabetical.
        
        if let newestCompatibleOS = string.extract(from: "Newest compatible operating system", to: "</p>") {
            if let newestCompatibleOS = newestCompatibleOS.extract(from: ">", to: nil)?.trimmed {
                // determine version
                for (version, _) in Version.macOSs {
                    if version.previousMacOS().macOSName == newestCompatibleOS { // can't just increment major version since many macOS 10.X is the version.
                        unsupportedOSVersion = version
                    }
                }
            }
        }
        
        // Get SupportID
        if let sid = string.extract(from: "<a href=\"/en-us/", to: "\"") {
            supportId = sid
        } else if let sid = string.extract(from: "<a href=\"https://support.apple.com/kb/", to: "\"") {
            supportId = sid
        } else if let sid = string.extract(from: "<a href=\"https://support.apple.com/", to: "\"") {
            // iPads don't have the /kb/ part.
            supportId = sid
        }
        // fix since sp622 is lowercase for some reason
        supportId = supportId.uppercased()
        
        // try to parse idiom
        if idiom == .unspecified {
            for i in Device.Idiom.allCases {
                if string.contains(i.identifier) {
                    idiom = i
                    break
                }
            }
        }
                
        // check for string.contains("Thunderbolt") to register capability
        if string.contains("Thunderbolt") {
            capabilities.insert(.thunderbolt)
        }
        if string.contains("USB-C") {
            capabilities.insert(.usbC)
        }
        if string.contains("Headphone") {
            capabilities.insert(.headphoneJack)
        }
        if string.contains("Ethernet") {
            capabilities.insert(.ethernet)
        }
        if string.contains("Action button") {
            capabilities.insert(.actionButton)
        }
        if string.contains("no SIM tray") && !string.contains("CDMA model has no SIM tray") {
            capabilities.insert(.esim)
        }

        // be sure not to hit on iPad with A17 Pro processor that isn't a pro device.
        if officialName.contains(" Pro") && !officialName.contains(" Pro)") {
            capabilities.insert(.pro)
        }
        if officialName.lowercased().contains(" mini") {
            capabilities.insert(.mini)
        }
        if officialName.contains(" Air") {
            capabilities.insert(.air)
        }
        if officialName.contains(" Plus") {
            capabilities.insert(.plus)
        }
        if officialName.contains(" Max") {
            capabilities.insert(.max)
        }
        
        // check for Mac form to add
        if idiom == .mac {
            let macForm: Mac.Form
            let year = yearIntroduced ?? 0
            if officialName.contains(" Pro") && year > 2015
                || officialName.contains(" Air") && year > 2017
                || officialName.contains("iMac") && year > 2020
            {
                if !identifiers.containsAny(["MacBookPro14,1", "MacBookPro13,1"]) { // 13 inch without touchbar
                    capabilities.insert(.biometrics(.touchID))
                }
            }
            if officialName.contains("Mac Pro") && !officialName.contains("iMac") {
                if year < 2013 {
                    macForm = .macProGen1
                } else if year == 2013 {
                    macForm = .macProGen2
                } else {
                    macForm = .macProGen3
                }
            } else if officialName.contains("MacBook") {
                if year < 2012 { // June 11, 2012
                    // MagSafe can be found on the MacBook (2006–2011), MacBook Pro (2006 through mid-2012, non-Retina) and MacBook Air (2008–2011) notebook computers.
                    macForm = .macBook
                    capabilities.insert(.magSafe1)
                } else if year < 2016 && officialName.contains(" Pro") || year < 2018 && officialName.contains(" Air") {
                    macForm = .macBookGen1 // MagSafe 2
                } else if year < 2021 || officialName.contains("MacBook Pro (13-inch, M2") {
                    // models with USB-C-only charging:
                    macForm = .macBook
                    capabilities.formUnion([.cameras([.faceTimeHD720p]), .usbC])
                } else {
                    macForm = .macBookGen2
                }
            } else if officialName.contains("Mac mini") {
                macForm = .macMini
            } else if officialName.contains("Mac Studio") {
                macForm = .macStudio
            } else if officialName.contains("iMac") {
                macForm = .iMac
            } else {
                debug("Unknown Mac form: \(officialName)", level: .ERROR)
                macForm = .macBook
            }
            capabilities.insert(.macForm(macForm))
        }

        // TODO: Check for <chip> section.
        var parsedChip: String?
        if string.contains("""
<p class="gb-paragraph"><b>Chip:
"""), let pc = string.extract(from: "<p class=\"gb-paragraph\"><b>Chip:", to: "</p>")?.tagsStripped.trimmed {
            parsedChip = pc
        } else if string.contains("This model has the"), let pc = string.extract(from: "This model has the", to: "chip")?.tagsStripped.trimmed, !pc.contains(" or ") {
            parsedChip = pc
        }
        if let parsedChip {
            // append to the product name
            officialName += " \(parsedChip)"
        }
        for c in CPU.allCases.reversed() { // longer ones first
//            debug("CHECKING \(c.rawValue)")
            if let parsedChip {
                if parsedChip.deviceNormalized.contains(c.rawValue.deviceNormalized.replacingOccurrences(of: "apple ", with: "")) {
                    cpu = c
                    break // get first one
                }
            } else if officialName.deviceNormalized.contains(c.caseName) && !partNumbers.definition.deviceNormalized.contains(c.caseName) { // make sure this isn't part of a model code
                cpu = c
                break // get first one
            }
        }

        // TODO: Determine when this is actually useful
//        if let matched, matched.safeOfficialName.normalizedCollapsedWhitespace.trimming(matched.cpu.caseName) == officialName.normalizedCollapsedWhitespace {
//            officialName = matched.officialName // ignore parsed name and use the matching device name for normalization
//        }
        
        if identifiers.count == 0 {
            // attempt to look up identifier in other ways
            
            // look through part numbers and add any matching identifiers.  May end up with a lot, but that would also hint to us that the part numbers are tied to specific identifiers.
            for partNumber in partNumbers {
                if let matched = Device.lookup(model: partNumber, officialNameHint: officialName).first {
                    identifiers.append(contentsOf: matched.identifiers)
                } else {
                    identifiers.append("UnknownPartNumber:\(partNumber)")
                }
            }
            
            // Apple watch needs to handle things differently, so attach an identifier for each case size
            for (caseSize, models) in watchCaseModels {
                for model in models.unique {
                    let hint = officialName.contains("Ultra") ? officialName : "\(officialName) \(caseSize)"
                    if let device = Device.lookup(model: model, officialNameHint: hint).first {
                        var identifiers = watchIdentifiers[caseSize] ?? []
                        identifiers.append(contentsOf: device.identifiers)
                        watchIdentifiers[caseSize] = identifiers
                    } else {
                        debug("Unknown \(hint) model: \(model)", level: .WARNING)
                        continue
                    }
                }
            }

            // if we still don't have a matched device at this point, try looking up from the Support ID if available
            if supportId != .unknownSupportId, let matched = Device.lookup(supportId: supportId, officialNameHint: officialName).first {
                identifiers.append(contentsOf: matched.identifiers)
            }
        }
        // map to case name for generic handling of identifiers
        if idiom != .watch {
            watchIdentifiers[.unknown] = identifiers
        } else {
//            debug("Parsing \(officialName)")
//            debug(watchIdentifiers)
        }
        for (caseName, identifiers) in watchIdentifiers {
            var image = image
            var officialName = officialName
            if idiom == .watch {
                // just do for this scope so we can reset for each case name
                if !officialName.contains("Ultra") { // Ultras don't include case size.
                    officialName = "\(officialName) \(caseName)"
                }
                partNumbers = (watchCaseModels[caseName] ?? []).unique
                // pick image (first one for smaller version, first non-aluminum for larger variant)
                let cases = watchCaseModels.keys.sorted()
                if caseName == cases.last {
                    image = image2
                }
            }
            var identifiers = identifiers.unique
            for identifier in identifiers {
//                let matched = Device.forcedLookup(identifier: identifier, officialNameHint: officialName) // or create a blank device with identifier
//                
//                // Apple Watches have issues with which image, so assume that the matched one is correct if available
//                if idiom == .watch {
//                    image = matched.image // TODO: Change to pick the aluminum variant if available
//                }
                
                var ids = [identifier]
                var mergeDuplicates = false
                // grouping is normally fine, but Mac16,11 needs to be split due to different processors!
                if !["Mac16,11", "Mac16,5", "Mac16,7", "Mac16,6", "Mac16,8", "Mac15,6", "Mac15,7"].contains(identifier) {
                    mergeDuplicates = true
                    // Mac15,6 needs to be separate but Mac15,8 & Mac15,10 should be grouped
                    if identifier == "Mac15,8" {
                        identifiers = ["Mac15,8", "Mac15,10"]
                    } else if identifier == "Mac15,9" {
                        identifiers = ["Mac15,9", "Mac15,11"]
                    }
                    ids = identifiers
                }
                
                
                // create bridge device for each identifier since we may want to split out
                let parsedItem = ParsedItem(
                    officialName: officialName,
                    idiom: idiom,
                    identifiers: ids,
                    yearIntroduced: yearIntroduced,
                    supportId: supportId,
                    unsupportedOSVersion: unsupportedOSVersion,
                    image: image,
                    capabilities: capabilities,
                    partNumbers: partNumbers,
                    cpu: cpu,
                    source: source)
                items.append(parsedItem)
                if mergeDuplicates {
                    break // don't make duplicates
                }
            }
        }
    }
}
