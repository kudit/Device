//
//  AppleDBConversion.swift
//  Device
//
//  AppleDB is a useful secondary catalog for discovering identifiers and
//  newly published models. It is intentionally compared as source data and
//  never treated as authoritative over Apple's support material.
//
#if canImport(SwiftUI) && canImport(Foundation)
struct AppleDBColor: Codable, Equatable, Sendable {
    var name: String
    var hex: MixedTypeField // either a String or a [String]
    var released: DateString
    var discontinued: DateString?
    var key: String
}
extension MaterialColor {
    var appleDBHex: MixedTypeField {
        .string(self.rawValue.replacingOccurrences(of: "#", with: "").uppercased())
    }
}
extension Biometrics {
    var appleDBString: String {
        switch self {
        case .none: return "No"
        case .touchID: return "Touch ID sensor"
        case .faceID: return "Face ID sensor"
        case .opticID: return "Optic ID sensor"
        @unknown default: return "Unknown"
        }
    }
}
extension Device {
    var appleDBInfo: [MixedTypeField]? {
        var info: [MixedTypeField] = []
        if let biometrics {
            let sensors = [
                "type": "Sensors",
                "Biometrics": biometrics.appleDBString,
            ]
            if let sensors = MixedTypeField(encoding: sensors) {
                info.append(sensors)
            }
        }
        if let screen {
            let display: MixedTypeField = [
                "type": "Display",
                "Resolution": ["x": .int(screen.resolution.width), "y": .int(screen.resolution.height)],
                "Screen_Size": .string("\(screen.diagonal ?? 0)\""), // have to manually define since string interpolation
                "Pixels_per_Inch": .int(screen.ppi ?? 0),
            ]
            info.append(display)
        }
        return info
    }
}
extension MixedTypeField? {
    var firstValue: String {
        guard var value: MixedTypeField = self else {
            return ""
        }
        if let array = value.arrayValue, let firstValue = array.first, let firstValue {
            value = firstValue
        }
        return value.stringValue ?? ""
    }
}
extension CPU {
    var appleDBString: String {
        self.caseName.uppercased().replacingOccurrences(of: ["PRO"], with: "")
    }
}
struct AppleDBRecord: DeviceBridge {
    var name: String
    var identifier: [String]
    var soc: MixedTypeField? // String or [String] (should be all upper case)
    var cpid: MixedTypeField? // String or [String]
    var arch: String?
    var type: String
    var board: [String] = []
    var bdid: String?
    var model: [String]
    var released: MixedTypeField? // DateString or [DateString]
    var discontinued: MixedTypeField? // DateString or [DateString]
    var colors: [AppleDBColor]?
    var info: [MixedTypeField]? // can get core numbers, memory, connectivity, sensors, biometrics, Headphone_Jack bool, Display resolution, PPI,
    var key: String
    var imageKey: String
    var `internal`: Bool?
    
    init(name: String, identifier: [String], soc: MixedTypeField? = nil, cpid: MixedTypeField? = nil, arch: String? = nil, type: String, board: [String] = [], bdid: String? = nil, model: [String], released: MixedTypeField? = nil, discontinued: MixedTypeField? = nil, colors: [AppleDBColor]? = nil, info: [MixedTypeField]? = nil, key: String, imageKey: String, `internal`: Bool? = nil) {
        self.name = name
        self.identifier = identifier
        self.soc = soc
        self.cpid = cpid
        self.arch = arch
        self.type = type
        self.board = board
        self.bdid = bdid
        self.model = model
        self.released = released
        self.discontinued = discontinued
        self.colors = colors
        self.info = info
        self.key = key
        self.imageKey = imageKey
        self.internal = `internal`
    }
    
    // synthesized for DeviceBridge
    var comparisonIdentifiers: [String] { identifier }
    var comparisonCPUs: [CPU] { cpus }
    var source: String { prettyJSON }
    var matched: Device { Device.forcedLookup(identifier: identifier.first, model: model.first, officialNameHint: name) }
    var merged: Device {
        let base = matched
        // Preserve AppleDB's ordered model list so model-order errors remain
        // visible in the Device projection instead of disappearing in Merged.
        let sourceDevice = Device(
            idiom: base.idiom,
            officialName: base.officialName,
            identifiers: base.identifiers,
            introduction: DateString(rawValue: released.firstValue),
            supportId: base.supportId,
            launchOSVersion: base.launchOSVersion, // TODO: we should be able to determine the launch version from the info data...
            unsupportedOSVersion: base.unsupportedOSVersion,
            image: base.image,
            capabilities: base.capabilities,
            models: model,
            colors: base.colors,
            cpu: cpus.first ?? .unknown)
        return sourceDevice.merged(from: base)
    }

    func bridge(from device: Device) -> Self {
        var result = self
        // Preserve bridge-only fields from the source record. Device cannot
        // reconstruct AppleDB board, CPID, architecture, or lifecycle data.
        result.name = device.officialName
        result.identifier = device.identifiers
        result.soc = .string(device.cpu.appleDBString)
        result.released = .string(device.introduction?.rawValue ?? "")
        result.type = device.idiom.identifier
        result.model = device.models
        // Hold until we have a better way of mapping and displaying this.
//    result.colors = device.colors.map { AppleDBColor(name: $0.name, hex: $0.appleDBHex, released: device.introduction ?? "", key: $0.name) }
//    result.info = device.appleDBInfo
//    result.key = device.identifiers.first ?? device.officialName
//    result.imageKey = result.key
        return result
    }

    func bridgeValuesEqual(_ key: String, _ left: Any?, _ right: Any?) -> Bool {
        if key.isEmpty { return areEqual(left, right) }
        if key == "identifier" || key == "identifiers" {
            return identifierSet(left) == identifierSet(right)
        }
//    if key == "colors" {
//      return colorNameSet(left) == colorNameSet(right)
//    }
        if key == "released" {
            return String(describing: left) == String(describing: right)
        }
        // AppleDB hex values are not stable enough to mark as source errors.
        return true
    }

    private func identifierSet(_ value: Any?) -> Set<String> {
        if let values = value as? [String] { return Set(values) }
        if let value = value as? String { return [value] }
        return []
    }

    private func colorNameSet(_ value: Any?) -> Set<String> {
        guard let values = value as? [AppleDBColor] else { return [] }
        return Set(values.map { $0.name.normalized })
    }
    
    var cpus: [CPU] {
        CPU.sourceChoices(in: soc.firstValue)
    }
}

struct AppleDBLoader: DeviceBridgeLoader {
    // AppleDB's public API is versioned; this endpoint supplies the complete
    // catalog and keeps the comparison reproducible for a given revision.
    let sourceURL = "https://api.appledb.dev/device/main.json"
    
    let name = "AppleDB.dev"

    func devices() async throws -> [AppleDBRecord] {
        let jsonString = try await fetchURL(urlString: sourceURL)
        debug("AppleDB: received \(jsonString.count) characters")
        do {
            let devices = try [AppleDBRecord](fromJSON: jsonString)
            debug("AppleDB: extracted \(devices.count) device records")
            // AppleDB also publishes accessories, cases, and internal parts.
            // Migration compares hardware idioms only, so retain records whose
            // type maps to one of Device's supported idiom identifiers.
            let idiomTypes = Set(Device.Idiom.allCases.flatMap { idiom in
                [idiom.identifier.lowercased(), idiom.label.lowercased()]
            })
            return devices.filter { idiomTypes.contains($0.type.lowercased()) }
        } catch {
            debug("decoding error: \(error)", level: .WARNING)
            throw error
        }
    }
}
#endif
