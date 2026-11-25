//
//  AppleDBConversion.swift
//  Device
//
//  AppleDB is a useful secondary catalog for discovering identifiers and
//  newly published models. It is intentionally compared as source data and
//  never treated as authoritative over Apple's support material.
//

import Color
import Foundation
#if canImport(SwiftUI)
import SwiftUI // for Color
#endif

/// AppleDB uses user-facing type names for a few families where Device keeps
/// compact machine identifiers. Keep this mapping local to the AppleDB adapter.
private extension Device.Idiom {
    var appleDBTypeName: String {
        switch self {
        case .watch: return "Watch"
        case .tv: return "AppleTV"
        case .homePod: return "AudioAccessory"
        default: return identifier
        }
    }
}

struct AppleDBColor: Codable, Equatable, Sendable {
    var name: String
    var hex: MixedTypeField // either a String or a [String] DOES NOT INCLUDE #!
    var released: DateString
    var discontinued: DateString?
    var key: String

	var swatches: [String] {
		if let array = hex.arrayValue {
			return array.compactMap { "#\(String(describing: $0?.stringValue))" }
		}
		if let string = hex.stringValue {
			return [string]
		}
		return []
	}
}
extension AppleDBColor: ColorComparable {
	var comparisonColor: AppleMaterialColor {
		AppleMaterialColor(swatches: swatches, name: name)
	}
}
extension AppleDBColor: Definable {
    /// Emits the compact source literal used in AppleDB bridge definitions.
    var definition: String {
//        let discontinuedValue = discontinued.map { "\"\($0.rawValue)\"" } ?? "nil"
		return "\"\(name)\": \(hex.definition)"
		// full version but for our purposes we really want a clearer compact version for display since we aren't really using this to define the value.
//        return "AppleDBColor(name: \"\(name)\", hex: \(hex.definition), released: \"\(released.rawValue)\", discontinued: \(discontinuedValue), key: \"\(key)\")"
    }
}
extension AppleMaterialColor {
    var appleDBHex: MixedTypeField {
		let appleDBArray = self.swatches.map { MixedTypeField(stringLiteral: $0.replacingOccurrences(of: "#", with: "").uppercased()) }
		if appleDBArray.count == 1 {
			return appleDBArray.first!
		} else {
			return .array(appleDBArray)
		}
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
        for screen in screens {
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
		var cpu = self.rawValue.replacingOccurrences(of: "Apple ", with: "")
		if cpu == caseName {
			cpu = cpu.uppercased()
		} else if cpu.contains(" ") && !cpu.contains("Pro") {
			cpu = cpu.extract(from: nil , to: " ") ?? cpu
		}
		return cpu
    }
}
struct AppleDBRecord: DeviceBridge {
    static var diffIgnoreKeys: [String] {
        // The raw AppleDB specification block is not a stable Device schema;
        // synthesized capability fields should carry the actionable diffs.
        ["info"]
    }
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
    /// Compact capability projections derived once from the raw info blocks.
    var hasCompass: Bool?
    var hasBarometer: Bool?
    var hasNFC: Bool?
    var biometrics: Biometrics?
    
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
        self.hasCompass = nil
        self.hasBarometer = nil
        self.hasNFC = nil
        self.biometrics = nil
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
        // AppleDB calls HomePod records AudioAccessory; emit the canonical
        // bridge type so the generated representation matches Device's idiom.
        result.type = device.idiom.appleDBTypeName
        result.model = device.models
        result.hasCompass = device.has(.compass)
        result.hasBarometer = device.has(.barometer)
        result.hasNFC = device.has(.nfc)
        result.biometrics = device.biometrics
        // Hold until we have a better way of mapping and displaying this.
		result.colors = device.colors.map { AppleDBColor(name: $0.name, hex: $0.appleDBHex, released: device.introduction ?? "", key: $0.name) }
//    result.info = device.appleDBInfo
//    result.key = device.identifiers.first ?? device.officialName
//    result.imageKey = result.key
        return result
    }

    func bridgeValuesEqual(_ key: String, _ left: Any?, _ right: Any?) -> Bool {
        if key.isEmpty { return areEqual(left, right) }
        if key == "type",
           let lhs = left as? String,
           let rhs = right as? String {
            let aliases: Set<Set<String>> = [["homepod", "audioaccessory"]]
            if lhs.lowercased() != rhs.lowercased(),
               aliases.contains(Set([lhs.lowercased(), rhs.lowercased()])) {
                return true
            }
        }
        if key == "identifier" || key == "identifiers" {
            let leftIdentifiers = identifierSet(left)
            let rightIdentifiers = identifierSet(right)
            // AppleDB has used AudioAccessory5,1 as an additional alias for
            // the same HomePod mini record. Treat that one extra identifier
            // as compatible when both sides retain AudioAccessorySingle5,1.
            if leftIdentifiers.symmetricDifference(rightIdentifiers) == Set(["AudioAccessory5,1"]),
               leftIdentifiers.contains("AudioAccessorySingle5,1"),
               rightIdentifiers.contains("AudioAccessorySingle5,1") {
                return true
            }
            // AppleDB commonly emits one record per identifier while Device
            // groups Wi-Fi/cellular variants. Any known overlap means the
            // values describe the same hardware; the merge retains the full
            // local set and classifies the split representation as yellow.
            return !leftIdentifiers.isDisjoint(with: rightIdentifiers)
        }
//    if key == "colors" {
//      return colorNameSet(left) == colorNameSet(right)
//    }
        if key == "released" {
            return releaseValues(left) == releaseValues(right)
        }
        if key == "model" || key == "models" {
            return modelSet(left) == modelSet(right)
        }
        if key == "colors",
           let lhs = left as? [AppleDBColor],
           let rhs = right as? [AppleDBColor] {
            // Keep names case-sensitive so a source rename is visible, while
            // allowing tiny CSS rounding differences in each ordered swatch.
            guard lhs.map(\.name) == rhs.map(\.name), lhs.count == rhs.count else { return false }
            return zip(lhs, rhs).allSatisfy { local, source in
                guard local.swatches.count == source.swatches.count else { return false }
                return zip(local.swatches, source.swatches).allSatisfy { localHex, sourceHex in
					Color(string: localHex, defaultColor: .grayFixed).delta(Color(string: sourceHex, defaultColor: .grayFixed)) < 0.05
                }
            }
        }
        return true
    }

    func compatibleWhenMergedDiffers(_ key: String, left: Any?, merged: Any?, right: Any?) -> Bool {
        if key == "released" {
            let local = releaseValues(left)
            let source = releaseValues(right)
            let localDate = local.sorted().first ?? ""
            // AppleDB records the Rev A's approximate shipping date, while
            // Device intentionally preserves its earlier introduction date.
            // Keep this known distinction compatible instead of reporting a
            // false mismatch for the AppleTV3,2 model.
            if identifier.contains("AppleTV3,2"),
               local.contains("2013-01-29"),
               source.contains("2013-03-10") {
                return true
            }
            let yearOnly = localDate.isEmpty || localDate.hasSuffix("-01-01")
            let primaryIdentifier = identifier.first == matched.identifiers.first
            let primaryModel = model.first == matched.models.first
            // AppleDB may record regional release dates for secondary
            // identifiers. Those are a warning unless our local date is only
            // a year (or unknown), where the date remains actionable.
            return (!primaryIdentifier && !yearOnly) || (!primaryModel && !yearOnly) || (!local.isEmpty && local.isSubset(of: source))
        }
		if key == "soc" { return false }
		if key == "colors" { return true }
		guard key == "model" || key == "models" else { return false }
		// Model lists are source-catalog details and routinely differ by region,
		// storage configuration, or whether AppleDB has finished its grouping.
		// Any non-identical list is therefore a compatible difference, not a red
		// hardware mismatch.
		return true
    }

    /// AppleDB frequently publishes only some of a Device definition's model
    /// numbers. A partial list is useful source information, but it is not an
    /// error when every AppleDB model is already known locally.
    private func identifierSet(_ value: Any?) -> Set<String> {
        if let values = value as? [String] { return Set(values) }
        if let value = value as? String { return [value] }
        return []
    }

    private func modelSet(_ value: Any?) -> Set<String> {
        if let values = value as? [String] { return Set(values) }
        if let value = value as? String { return [value] }
        // PropertyIterable can expose optional key-path values; unwrap those
        // before comparing so an AppleDB model list is compared as a set.
        if let value {
            let mirror = Mirror(reflecting: value)
            if mirror.displayStyle == .optional,
               let child = mirror.children.first {
                return modelSet(child.value)
            }
        }
        return []
    }

    private func releaseValues(_ value: Any?) -> Set<String> {
        if let string = value as? String { return [string] }
        if let mixed = value as? MixedTypeField {
            if let string = mixed.stringValue { return [string] }
            if let array = mixed.arrayValue { return Set(array.compactMap { $0?.stringValue }) }
        }
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
	private let mirrorURL = "https://raw.githubusercontent.com/littlebyteorg/appledb/gh-pages/device/main.json"
    
    let name = "AppleDB.dev"

    func devices() async throws -> [AppleDBRecord] {
		// AppleDB documents its API as static data hosted from the same public
		// gh-pages branch; use that mirror if the API host is unavailable or its
		// response is not decodable, rather than treating one endpoint failure as
		// an empty catalog.
		var devices: [AppleDBRecord]
		let apiPayload: String?
		do {
			apiPayload = try await fetchURL(urlString: sourceURL)
		} catch {
			debug("AppleDB API request failed; trying its repository mirror: \(error)", level: .WARNING)
			apiPayload = nil
		}
		if let apiPayload {
			debug("AppleDB: received \(apiPayload.count) characters")
			do {
				devices = try decodeRecords(apiPayload)
			} catch {
				debug("AppleDB API payload could not be decoded; trying its repository mirror: \(error)", level: .WARNING)
				devices = try await fetchMirrorRecords()
			}
		} else {
			devices = try await fetchMirrorRecords()
		}
            for index in devices.indices {
                guard let info = devices[index].info else {
                    devices[index].hasCompass = nil
                    devices[index].hasBarometer = nil
                    devices[index].hasNFC = nil
                    devices[index].biometrics = nil
                    continue
                }
                let text = String(describing: info)
                devices[index].hasCompass = text.contains("Compass")
                devices[index].hasBarometer = text.contains("Barometer")
                devices[index].hasNFC = text.contains("NFC") || text.contains("Near-field")
                devices[index].biometrics = text.contains("Face ID") ? .faceID : text.contains("Touch ID") ? .touchID : text.contains("Optic ID") ? .opticID : nil
            }
            debug("AppleDB: extracted \(devices.count) device records")
            // AppleDB also publishes accessories, cases, and internal parts.
            // Migration compares hardware idioms only, so retain records whose
            // type maps to one of Device's supported idiom identifiers.
            let idiomTypes = Set(Device.Idiom.allCases.flatMap { idiom in
                [idiom.identifier.lowercased(), idiom.label.lowercased()]
            })
            let appleDBAliases: Set<String> = [
                "mac", "macbook", "macbookair", "macbookpro", "macmini", "macpro", "macstudio",
                "iphone", "ipad", "ipod", "appletv", "applewatch", "watch", "visionpro",
                "realitydevice", "audioaccessory", "homepod"
            ]
			return devices.filter {
				let type = $0.type.lowercased().replacingOccurrences(of: " ", with: "")
				guard idiomTypes.contains(type) || appleDBAliases.contains(type) else { return false }
				let name = $0.name.lowercased()
				// Developer Transition Kit and unreleased records are not customer
				// devices and should not create migration comparisons.
				if name.contains("developer transition kit") || name.contains("unreleased") || $0.internal == true || $0.released == nil {
					return false
				}
				// Device intentionally starts these families at the first models
				// represented by Apple's identification material.
				if $0.identifier.contains(where: { $0.hasPrefix("MacPro1,") || $0.hasPrefix("MacPro2,") || $0.hasPrefix("MacPro3,") || $0.hasPrefix("Macmini1,") || $0.hasPrefix("Macmini2,") }) {
					return false
				}
				// The migration catalog contains iPod touch definitions, but
                // original click-wheel iPods are outside Device's supported
                // hardware model and should not create unmatched rows.
                if $0.type.lowercased() == "ipod" {
					// AppleDB labels click-wheel editions as "iPod (Touch
                    // Wheel)"; only retain the literal iPod touch family.
					return name.contains("ipod touch") && !name.contains("touch wheel")
				}
				return true
			}
    }

	/// Decodes the documented GitHub Pages mirror used when the API endpoint fails.
	private func fetchMirrorRecords() async throws -> [AppleDBRecord] {
		let mirrorPayload = try await fetchURL(urlString: mirrorURL)
		debug("AppleDB mirror: received \(mirrorPayload.count) characters")
		return try decodeRecords(mirrorPayload)
	}

	/// Accepts both API publication shapes and isolates malformed catalog rows.
	/// A single incomplete accessory must not make the entire AppleDB catalog
	/// appear unavailable to the migration viewer.
	private func decodeRecords(_ payload: String) throws -> [AppleDBRecord] {
		if let records = try? [AppleDBRecord](fromJSON: payload) {
			return records
		}
		let data = Data(payload.utf8)
		let root = try JSONSerialization.jsonObject(with: data)
		let rawRecords: [Any]
		if let array = root as? [Any] {
			rawRecords = array
		} else if let dictionary = root as? [String: Any] {
			rawRecords = dictionary.values.sorted { lhs, rhs in
				let leftName = (lhs as? [String: Any])?["name"] as? String ?? ""
				let rightName = (rhs as? [String: Any])?["name"] as? String ?? ""
				return leftName.localizedStandardCompare(rightName) == .orderedAscending
			}
		} else {
			throw NSError(domain: "AppleDB", code: 1, userInfo: [NSLocalizedDescriptionKey: "Expected a JSON array or object of device records."])
		}
		var records = [AppleDBRecord]()
		var skipped = 0
		let decoder = JSONDecoder()
		for value in rawRecords {
			guard JSONSerialization.isValidJSONObject(value),
				let recordData = try? JSONSerialization.data(withJSONObject: value),
				let record = try? decoder.decode(AppleDBRecord.self, from: recordData) else {
				skipped += 1
				continue
			}
			records.append(record)
		}
		guard !records.isEmpty else {
			throw NSError(domain: "AppleDB", code: 2, userInfo: [NSLocalizedDescriptionKey: "No AppleDB device records could be decoded."])
		}
		if skipped > 0 {
			debug("AppleDB: skipped \(skipped) malformed record(s); retained \(records.count)", level: .WARNING)
		}
		return records
	}
}
