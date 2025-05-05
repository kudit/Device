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

struct ParsedItem: DeviceBridge {
    var source: String
    var device: Device
    var matched: Device
    
    var id: String { source }
    
    static func generate() -> String {
        "NOT IMPLEMENTED SINCE HTML"
    }
}

actor PageParserProcessor {
    let url: String
    var content: String?
    var items: [ParsedItem] = []

    init(url: String) {
        self.url = url
    }
    
    func parse() async {
        let content = try? await fetchURL(urlString: url)
        if content?.contains("<h2 id=\"one\" class=\"gb-header\">") ?? false, let parts = content?.components(separatedBy: "<h3 class=\"gb-header\">") {
            // Apple Watch pages
            parts.forEach { parseItem(source: $0) }
        } else if content?.contains("<h2 class=\"gb-header") ?? false, let parts = content?.components(separatedBy: "<h2 class=\"gb-header alignment horizontal-align-left\">"), parts.count > 1 {
            // iPod Touch page is sectioned differently
            parts.forEach { parseItem(source: $0) }
        } else if content?.contains("<h3 class=\"gb-header\">") ?? false, let parts = content?.components(separatedBy: "<img class=\"gb-image\" alt=\"") {
            // MacBook page is sectioned differently
            parts.forEach { parseItem(source: $0) }
        } else if let parts = content?.components(separatedBy: "<h2 class=\"gb-header\">") {
            parts.forEach { parseItem(source: $0) }
        }
    }
    
    // TODO: Find a way to have this parse an item and create a second item for merged entries (with different processors).  Perhaps have static func that returns an array of items?  Similarly consolidate Apple Watch models (if returns a similar parsed item, then we should be able to de-dup?  Or just count twice).
    func parseItem(source: String) {
        var idiom = Device.Idiom.unspecified
        var identifiers: [String] = []
        var introduction: DateString? = nil
        var supportId = String.unknownSupportId
        var unsupportedOSVersion: Version? = nil
        var image: String? = nil
        var capabilities = Capabilities()
        var partNumbers: [String] = []
        var cpu = CPU.unknown
                
        var string = source.replacingOccurrences(of: "‑", with: "-")
        // make sure this isn't the header or footer section
        // note: original iphone has "The model number" so M isn't capitalized.
        guard string.contains("Model Identifier") || string.contains("odel number") || string.contains("Model:") else {
            return // don't add any
        }
        // strip out headers that aren't stripped from above.
        if string.contains("<!DOCTYPE html>") || string.contains("Find the model number") || string.contains("Find your Apple TV model number") {
            return // don't add
        }
        // strip out additional header
        if string.hasPrefix("Find the model number") {
            string = string.extract(from: "<h2 id=\"ipadpro\" class=\"gb-header\">", to: nil) ?? string
        }
        // Apple TV sections don't have the identifier, just the model number
        guard var officialName = string.extract(from: nil, to: "</") else {
            return // needs a title at least!
        }
        if officialName.contains("src="), let macbookTitle = officialName.extract(from: nil, to: "\"") {
            officialName = macbookTitle
        }
        if officialName.contains("iPod") && !officialName.contains("iPod touch") {
            return // don't include iPods that aren't touches
        }
        if officialName.contains("Apple Watch") {
            officialName = officialName.replacingOccurrences(of: ["Titanium", "Herm&egrave;s", " (GPS + Cellular)"], with: "")
        }
        officialName = officialName.tagsStripped.trimmed.whitespaceCollapsed.replacingOccurrences(of: " M4 Pro or M4 Max", with: "")

        // get introduction date
        if string.contains("Year introduced"), var yearIntroducedString = string.extract(from: "Year introduced: ", to: "</p>") {
            if yearIntroducedString.contains(" ") { // iPhone 3G and 4 have multple dates.
                yearIntroducedString = yearIntroducedString.replacingOccurrences(of: ",", with: " ").extract(from: nil, to: " ") ?? yearIntroducedString
            }
            introduction = DateString(yearIntroducedString.introductionYear)
        } else {
            // try looking for year in officialName
            for year in 2000...Date.now.year {
                if officialName.contains("\(year)") {
                    introduction = year.introductionYear
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
        if let imageTag = string.extract(from: "<img class=\"gb-image\"", to: "/>"), let imageURL = imageTag.extract(from: "src=\"", to: "\"") {
            image = imageURL
        }
        
        let isiPhone = string.contains("iPhone")
        if isiPhone {
            idiom = .phone
        }
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
        } else if let modelNumber = string.extract(from: "<ul class=\"list gb-list\"><li class=\"gb-list_item\"><p class=\"gb-paragraph\">", to: "</ul>") {
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
        } else if let sid = string.extract(from: "See the <a href=\"https://support.apple.com/kb/", to: "\"") {
            supportId = sid
        } else if let sid = string.extract(from: "See the <a href=\"https://support.apple.com/", to: "\"") {
            // iPads don't have the /kb/ part.
            supportId = sid
        }
        
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
            let year = introduction?.date?.year ?? 0
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
                if parsedChip.deviceNormalizedName.contains(c.rawValue.deviceNormalizedName.replacingOccurrences(of: "apple ", with: "")) {
                    cpu = c
                    break // get first one
                }
            } else if officialName.deviceNormalizedName.contains(c.caseName) && !partNumbers.definition.deviceNormalizedName.contains(c.caseName) { // make sure this isn't part of a model code
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
                }
            }

            // if we still don't have a matched device at this point, try looking up from the Support ID if available
            if supportId != .unknownSupportId, let matched = Device.lookup(supportId: supportId, officialNameHint: officialName).first {
                identifiers.append(contentsOf: matched.identifiers)
            }
        }
        identifiers = identifiers.unique
        for identifier in identifiers {
            let matched = Device.lookup(identifier: identifier, officialNameHint: officialName).first ?? Device(identifier: identifier) // or create a blank device with identifier

            // Apple Watches have issues with which image, so assume that the matched one is correct if available
            if idiom == .watch {
                image = matched.image
            }

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

            
            // create device for each identifier since we may want to split out
            let device = Device(
                idiom: idiom,
                officialName: officialName,
                identifiers: ids,
                introduction: introduction,
                supportId: supportId,
                launchOSVersion: .zero,
                unsupportedOSVersion: unsupportedOSVersion,
                image: image,
                capabilities: capabilities,
                models: partNumbers,
                colors: .default,
                cpu: cpu
            )
            
            let parsedItem = ParsedItem(source: source, device: device, matched: matched)
            items.append(parsedItem)
            if mergeDuplicates {
                break // don't make duplicates
            }
        }
    }
}


@MainActor
class PageParser: ObservableObject {
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
    
    let url: String
    @Published var parsing = false
    @Published var content: String?
    @Published var items: [ParsedItem] = []

    init(url: String) {
        parsing = true
        self.url = url
    }
    
    nonisolated
    func parse() async {
        let processor = PageParserProcessor(url: url)
        await processor.parse()
        let content = await processor.content
        let items = await processor.items
        main {
            self.items = items
            self.content = content
            self.parsing = false
        }
    }
}
