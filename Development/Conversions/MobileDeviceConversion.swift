//
//  MobileDeviceConversion.swift
//  Device
//
//  Created by Ben Ku on 4/29/25.
//
#if DEBUG
@testable import Device

struct MobileDevice: DeviceBridge {
    static var diffIgnoreKeys: [String] {
        ["officialName"] // MobileDevice names are advisory; Device remains authoritative and name differences are warnings.
    }

    /// Ignores presentation differences while retaining generation and case-size differences.
    func bridgeValuesEqual(_ key: String, _ left: Any?, _ right: Any?) -> Bool {
        if key == "officialName", let left = left as? String, let right = right as? String {
            return convertToDevice(left).deviceNormalized == convertToDevice(right).deviceNormalized
        }
        return areEqual(left, right)
    }
    // https://gist.github.com/adamawolf/3048717
    // post issues: https://gist.github.com/adamawolf/3048717#gistcomment-5779044
    static let nameMapping = [
        // These source spellings are stable identifier-specific exceptions. Keep
        // them in the bridge so upstream text remains visible while the merged
        // proposal can use Device's canonical name.
        "1st Gen iPod": "iPod touch",
        "iPhone SE (GSM)": "iPhone SE (1st generation)",
        "2nd Gen iPod": "iPod touch (2nd generation)",
        "3rd Gen iPod": "iPod touch (3rd generation)",
        "4th Gen iPod": "iPod touch (4th generation)",
        "5th Gen iPod": "iPod touch (5th generation)",
        "6th Gen iPod": "iPod touch (6th generation)",
        "7th Gen iPod": "iPod touch (7th generation)",
        "iPad 3G": "iPad",
        "2nd Gen iPad": "iPad 2",
        "3rd Gen iPad": "iPad (3rd generation)",
        "4th Gen iPad Mini": "iPad Mini 4",
        "iPad (4th generation) Mini": "iPad Mini 4",
        "4th Gen iPad": "iPad (4th generation)",
        "iPad Mini Retina": "iPad Mini 2",
        "iPad Pro 11-inch 3rd Gen": "iPad Pro 11-inch",
        "iPad Pro 2nd Gen": "iPad Pro 12.9-inch (2nd generation)",
        "iPad Pro 11-inch 4th Gen": "iPad Pro 11-inch (2nd generation)",
        "iPad Pro 11-inch 5th Gen": "iPad Pro 11-inch (3rd generation)",
        "iPad Air 11-inch 6th Gen": "iPad Air 11-inch (M2)",
        "iPad Air 13-inch 6th Gen": "iPad Air 13-inch (M2)",
        "iPad Air 11-inch 7th Gen": "iPad Air 11-inch (M3)",
        "iPad Air 13-inch 7th Gen": "iPad Air 13-inch (M3)",
        "iPad 11th Gen": "iPad (A16)",
        "iPad Mini 7th Gen": "iPad mini (A17 Pro)",
        //    "inch 6th Gen": "inch (M2)",
        //    "inch 7th Gen": "inch (M3)",
        //    "inch 5th Gen": "inch (M4)",
        "12.9-inch 7th Gen": "13-inch (M4)",
        "mini 7th Gen": "mini (A17 Pro)",
    ]


    var identifier: String
    var officialName: String

    var source: String {
        "\(identifier) : \(officialName)"
    }

    var matched: Device {
        Device.forcedLookup(identifier: identifier, officialNameHint: officialName)
    }

    var merged: Device {
        // look up existing
        let device = matched
        
        // massage values
        if device.officialName.contains("Unknown") {
            debug("Unknown device! \(device.officialName)", level: .ERROR)
        }
        let officialName = normalizedName(officialName)

        return Device(
            idiom: device.idiom,
            officialName: officialName,
            identifiers: [identifier],
            supportId: device.supportId,
            launchOSVersion: device.launchOSVersion,
            unsupportedOSVersion: device.unsupportedOSVersion,
            image: device.image,
            capabilities: device.capabilities,
            colors: device.colors,
            cpu: device.cpu
        ).merged(from: device)
    }

    /// Applies the same source spelling rules to both sides without inferring a missing generation.
    private func normalizedName(_ name: String) -> String {
        var officialName = name
            .replacingOccurrences(of: "mini", with: "Mini")
            .replacingOccurrences(of: " inch", with: "-inch")
            .replacingOccurrences(of: "-inch", with: "inch")
            .replacingOccurrences(of: ["+", "Rev A", "1st Gen", "1TB", "10.2-inch", "case", "CDMA", "GPS", "GSM", "Cellular", "LTE", "WiFi", "China", "Global", "New Revision", ", ", "()"], with: "")
            .replacingOccurrences(of: "(2017)", with: "(5th generation)")
            .replacingOccurrences(of: "10.5-inch 2nd Gen", with: "(10.5-inch)")
            .replacingOccurrences(of: "XR", with: "Xʀ")
            .trimmed
        if identifier.identifierVersion.majorVersion == 16 && officialName.contains("iPad Pro 11-inch") {
            officialName = "iPad Pro 11-inch (M4)"
        }
        if identifier.identifierVersion.majorVersion == 1 && officialName.contains("Apple Watch") && !officialName.contains("generation") {
            officialName = officialName.replacingOccurrences(of: "Watch ", with: "Watch (1st generation) ")
        }
        for (mdName, myName) in Self.nameMapping {
            officialName = officialName.replacingOccurrences(of: mdName, with: myName)
        }
        for gen in 2...9 {
            let ordinal = "\(gen)\(gen.ordinal)"
            officialName = officialName.replacingOccurrences(of: "\(ordinal) Gen", with: "(\(ordinal) generation)")
        }
//    if identifier.identifierVersion.majorVersion == 6 && officialName.contains("Apple Watch SE") {
//      officialName = officialName.replacingOccurrences(of: "SE ", with: "SE (2nd generation) ")
//    }
        if identifier.identifierVersion.majorVersion == 14 && officialName.contains("iPad Pro 11-inch") {
            officialName = "iPad Pro 11-inch (4th generation)"
        }
        
        // SE 2/3 and ordinal generation spellings are equivalent, but bare SE
        // must stay distinct so an omitted second generation is not normalized away.
        return officialName
            .replacingOccurrences(of: "Watch SE 2", with: "Watch SE (2nd generation)")
            .replacingOccurrences(of: "Watch SE 3", with: "Watch SE (3rd generation)")
            .replacingOccurrences(of: "\\(\\s*\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmed
    }

    func bridge(from device: Device) -> MobileDevice {
        // use local whatever the device has as long as it contains the local
//    guard device.identifiers.contains(identifier) else {
//      return MobileDevice(identifier: .unknownIdentifier, officialName: device.officialName)
//    }
        let identifierIndex = device.identifiers.firstIndex(of: identifier) ?? -1
        // Keep the generation wording; normalization handles source aliases
        // without turning third-generation iPads and iPods into ambiguous names.
        var officialName = convertToBridge(device.officialName)
        // Reuse the single source/canonical name table in reverse when a
        // bridge record has an exact canonical match; this keeps conversion
        // rules data-driven without a second identifier conditional table.
        if let sourceName = Self.nameMapping.first(where: { $0.value == officialName })?.key {
            officialName = sourceName
        }
        if device.idiom == .watch {
            // MobileDevice places the connectivity qualifier before the case size;
            // normalize the generated bridge value to that spelling so a known
            // local device does not create a false name delta.
            if identifierIndex == 1 {
                if let sizeRange = officialName.range(of: #" \d+mm$"#, options: .regularExpression) {
                    officialName.insert(contentsOf: " (GPS + Cellular)", at: sizeRange.lowerBound)
                } else {
                    officialName += " (GPS + Cellular)"
                }
            }
            if identifier.identifierNumber < 7.9 {
                officialName += " case"
            }
        }
        if device.idiom == .pad {
            // MobileDevice omits the diagonal for this legacy grouped Pro family;
            // apply the source convention before adding the identifier-specific
            // connectivity suffix so WiFi and cellular records remain distinct.
            if device.officialName == "iPad Pro 12.9-inch (2nd generation)" {
                officialName = "iPad Pro 2nd Gen"
            }
            // MobileDevice labels the M3 Air generation as 7th Gen while the
            // Device model names the processor; preserve that bridge spelling.
            officialName = officialName
                .replacingOccurrences(of: "iPad Air 11inch (M3)", with: "iPad Air 11-inch 7th Gen")
                .replacingOccurrences(of: "iPad Air 13inch (M3)", with: "iPad Air 13-inch 7th Gen")
            officialName = convertToBridge(officialName, pad: true)
            if identifierIndex == 0 {
                officialName += " (WiFi)"
            }
            if identifierIndex == 1 {
                if identifier.identifierNumber < 4 {
                    officialName += " GSM+LTE"
                } else if identifier.identifierNumber < 5 {
                    officialName += " (GSM+CDMA)"
                } else {
                    officialName += " (WiFi+Cellular)"
                }
            }
            if identifierIndex == 2 {
                if identifier.identifierNumber < 4 {
                    officialName += " CDMA+LTE"
                } else {
                    officialName += " (China)"
                }
            }
        }
        // Keep the local spelling here. Copying self.officialName for known
        // identifiers hid every upstream naming error before diffing could see it.
        return MobileDevice(identifier: identifier, officialName: officialName)
    }

    /// Produces the exact compact spelling used by Apple_mobile_device_types.txt.
    /// This is deliberately separate from comparison normalization: generated
    /// bridge text should preserve spaces and connectivity punctuation.
    private func convertToBridge(_ name: String, pad: Bool = false) -> String {
        var result = name.replacingOccurrences(of: "-inch", with: "inch")
            .replacingOccurrences(of: " inch", with: "inch")
            .replacingOccurrences(of: " (GPS+Cellular)", with: " (GPS + Cellular)")
            .replacingOccurrences(of: "(GPS+Cellular)", with: "(GPS + Cellular)")
        if pad {
            result = result
                .replacingOccurrences(of: "(M2)", with: "6th Gen")
                .replacingOccurrences(of: "generation", with: "Gen")
                .replacingOccurrences(of: " (", with: " ")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "Mini 2", with: "mini retina")
                .replacingOccurrences(of: "-inch", with: "inch")
        }
        return result
    }

    /// Converts a MobileDevice source spelling into Device's canonical name
    /// before lookup and comparison. The direction is explicit so source
    /// formatting never leaks into the local model.
    private func convertToDevice(_ name: String) -> String {
        normalizedName(name)
    }

}

struct MobileDeviceLoader: DeviceBridgeLoader {
    let sourceURL = "https://gist.githubusercontent.com/adamawolf/3048717/raw/Apple_mobile_device_types.txt"
    let name = "MobileDevice Hardware"

    func devices() async throws -> [MobileDevice] {
        var devices = [MobileDevice]()
        let lines = try await fetchURL(urlString: sourceURL).lines
        for line in lines {
            guard line.trimmed != "" else {
//        print("skipping blank line")
                continue
            }
            let parts = line.components(separatedBy: " : ")
            guard parts.count == 2 else {
                debug("Unknown part: \(line)", level: .WARNING)
                continue
            }
            let (identifier, officialName) = (parts[0], parts[1])
            let device = MobileDevice(identifier: identifier, officialName: officialName)
            if device.officialName.contains("iPhone Simulator") {
                // skip simulator entries
                continue
            }
            devices.append(device)
        }
        return devices
    }
    
    func generate() -> String {
        let groups = [Device.Idiom.phone, .pod, .pad, .watch, .mac, .homePod, .tv, .vision]
        var results = """
i386 : iPhone Simulator
x86_64 : iPhone Simulator
arm64 : iPhone Simulator
"""
        for group in groups {
            results += "\n"
            var items = [Version: String]()
            for device in group.devices {
                for identifier in device.identifiers {
                    // sort number
                    items[identifier.identifierVersion] = identifier
                }
            }
            for key in items.keys.sorted() {
                let identifier = items[key]!
                let device = Device(identifier: identifier)
                // TODO: Map official name back to device name
                results += "\(identifier) : \(device.officialName)\n"
            }
        }
        return results
    }
}
#endif
