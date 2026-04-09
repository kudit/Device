//
//  MacLookup.swift
//  Device
//
//  Created by Ben Ku on 9/12/25.
//
#if canImport(SwiftUI) && canImport(Foundation)

// MARK: - Migration of JSON format used here: https://github.com/voyager-software/MacLookup/blob/master/Sources/MacLookup/Resources/all-macs.json
struct MacLookup: DeviceBridge {
    static var diffIgnoreKeys: [String] {
        ["notes"] // filter out and ignore these paths when calculating exact match - for things like DeviceKit comments or images/support URLs since we know those may differ
    }

    var models: [String] // identifiers
    var kind: String // form
    var colors: [String] // Convert to MaterialColors
    var name: String
    var notes: [String]?
    var variant: String // included in name so unused
    var parts: [String] // part numbers MGTF3xx/a
    
    var source: String {
        self.prettyJSON
    }
    
    var cpu: CPU {
        let nameString = name.lowercased()
        for processor in CPU.allCases {
            let str = String(describing: processor) // convert to string for lookup of m1, etc.
            if nameString.contains(str.lowercased()) {
                return processor
            }
        }
        //        print("Unable to process string: \(nameString)")
        return .unknown
    }
        
    var matched: Device {
        Device.forcedLookup(identifier: models.first, model: parts.first, officialNameHint: name)
    }
    
    var merged: Device {
        let form = Mac.Form.create(from: kind)
        // convert colors to MaterialColors
        var materials = [MaterialColor]()
        for color in colors {
            materials.append(MaterialColor(named: color, context: self.name))
        }
        // if we match, go ahead and use the matched order
        let materialsNames = materials.map { $0.caseName }.sorted()
        let colorNames = matched.colors.map { $0.caseName }.sorted()
        if materials.isEmpty || materialsNames == colorNames {
            // just use the matched colors since we clearly aren't providing here or aren't correct
            materials = matched.colors
        }
        
        // convert name to cpu
        var cpu = cpu
        var capabilities = form.capabilities
        if name.contains("Pro") {
            capabilities.insert(.pro)
        }
        if name.contains("Air") {
            capabilities.insert(.air)
        }
        if name == "iMac Pro" {
            cpu = .xeonE5
        }
        // assume all the ones we're importing are new enough that they have USB-C
        capabilities.insert(.usbC)
        capabilities.subtract(form.capabilities) // will automatically be added by form so no need to double add.
        return Mac(
            officialName: name,
            identifiers: models.distilled,
            introduction: nil,
            supportId: .unknownSupportId,
            launchOSVersion: .zero,
            unsupportedOSVersion: nil,
            form: form,
            image: nil,
            capabilities: capabilities,
            models: parts.distilled,
            colors: materials,
            cpu: cpu
        ).device.merged(from: matched)
    }
    
    func bridge(from device: Device) -> Self {
        let variant = name.extract(from: "(", to: ")") ?? ""
        var kindString = "Mac"
        if let mac = device.idiomatic as? Mac {
            kindString = mac.form.kindString(context: device)
        }
        var colors = device.colors.map { $0.name }
        if colors.sorted() == self.colors.sorted() {
            colors = self.colors // if we match, go ahead and use Bridge order so comparison will match
        }
        if self.colors.isEmpty {
            // if our bridge doesn't have the data, it doesn't matter what the others have as it will always use that
            colors = []
        }
        var models = device.models
        if device.identifiers.contains("Mac16,5") { // hack to break because this is actually combined identifier models.
            models = self.parts
        }
        return MacLookup(
            models: device.identifiers,
            kind: kindString,
            colors: colors,
            name: name, // the name will likely not match, so don't bother showing the difference.
            notes: notes, // we will always have nil notes so ignore
            variant: variant,
            parts: models)
    }
}

extension [String] {
    var distilled: [String] {
        var items = [String]()
        for item in self {
//            items += item.split(separator: "; ").map { String($0) } // using the collection method rather than the string method which isn't available in iOS < 16
            items += item.components(separatedBy: "; ")
        }
        return items
    }
}
extension Mac.Form {
    /// Name (ex: "MacBook Pro", "iMac", "Mac mini")
    static func create(from kindString: String) -> Mac.Form {
        if kindString.hasPrefix("Mac Pro") {
            return .macProGen3
        }
        if kindString.hasPrefix("iMac") {
            return .iMac
        }
        if kindString.hasPrefix("MacBook") {
            return .macBook
        }
        if kindString.hasPrefix("Mac mini") {
            return .macMini
        }
        if kindString.hasPrefix("Mac Studio") {
            return .macStudio
        }
        return .macBook
    }
    func kindString(context: Device) -> String {
        var kindString: String
        switch self {
        case .macProGen3, .macProGen1, .macProGen2:
            kindString = "Mac"
        case .iMac:
            kindString = "iMac"
        case .macBook, .macBookGen1, .macBookGen2:
            kindString = "MacBook"
        case .macMini:
            kindString = "Mac mini"
        case .macStudio:
            kindString = "Mac Studio"
        }
        if context.is(.pro) {
            kindString += " Pro"
        }
        if context.is(.air) {
            kindString += " Air"
        }
        if context.officialName.contains("Server") {
            kindString += " Server"
        }
        return kindString
    }
    var hasBattery: Bool {
        return self == .macBook
    }
    static func capabilities(from kindString: String) -> Capabilities {
        var capabilities = Capabilities()
        if kindString.contains("Pro") {
            capabilities.insert(.pro)
        }
        if kindString.contains("Air") {
            capabilities.insert(.air)
        }
        return capabilities
    }
}

extension [String] {
    mutating func splitJoined() {
        var fixed = [String]()
        for part in self {
            if part.contains(";") {
                fixed.append(contentsOf: part.split(separator: ";").map { String($0).trimmed })
            } else {
                fixed.append(part)
            }
        }
        self = fixed
    }
    mutating func collapseKeys(_ keys: [String]) {
        for key in keys {
            if self.contains(key) {
                self = [key] // includes Mac16,10 but they shouldn't be joined because different processors.
            }
        }
    }
}


struct MacLookupLoader: DeviceBridgeLoader {
    let sourceURL = "https://raw.githubusercontent.com/voyager-software/MacLookup/refs/heads/master/Sources/MacLookup/Resources/all-macs.json"
    func devices() async throws -> [MacLookup] {
        let jsonString = try await fetchURL(urlString: sourceURL)

        var devices = try [MacLookup](fromJSON: jsonString)
        
        // fix joined identifiers or models
        for i in 0..<devices.count {
            devices[i].models.splitJoined()
            devices[i].models.collapseKeys(["Mac16,11", "Mac16,6", "Mac16,5", "Mac15,6", "Mac15,7"])
            devices[i].parts.splitJoined()
        }
        
        // TODO: Split certain devices and join others
        
        
        return devices
    }
    
//    func generate() async -> String {
//        return Mac.all.map { $0.asMacLookup() }.asJSON(outputFormatting: .prettyPrinted)
//    }
}
#endif
