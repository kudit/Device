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
        ["officialName"] // filter out and ignore these paths when calculating exact match - for things like DeviceKit comments or images/support URLs since we know those may differ
    }
    // https://gist.github.com/adamawolf/3048717
    static let nameMapping = [
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
        //        "inch 6th Gen": "inch (M2)",
        //        "inch 7th Gen": "inch (M3)",
        //        "inch 5th Gen": "inch (M4)",
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
        var officialName = officialName
            .replacingOccurrences(of: "mini", with: "Mini")
            .replacingOccurrences(of: " inch", with: "-inch")
            .replacingOccurrences(of: ["+", "Rev A", "1st Gen", "1TB", "10.2-inch", "case", "CDMA", "GPS", "GSM", "Cellular", "LTE", "WiFi", "China", "Global", "New Revision", ", ", "()"], with: "")
            .replacingOccurrences(of: "(2017)", with: "(5th generation)")
            .replacingOccurrences(of: "10.5-inch 2nd Gen", with: "(10.5-inch)")
            .replacingOccurrences(of: "XR", with: "Xʀ")
            .trimmed
        if identifier.identifierVersion.majorVersion == 16 && officialName.contains("iPad Pro 11-inch") {
            officialName = "iPad Pro 11-inch (M4)"
        }
        if identifier.identifierVersion.majorVersion == 1 && officialName.contains("Apple Watch") {
            officialName = officialName.replacingOccurrences(of: "Watch ", with: "Watch (1st generation) ")
        }
        for (mdName, myName) in Self.nameMapping {
            officialName = officialName.replacingOccurrences(of: mdName, with: myName)
        }
        for gen in 2...9 {
            let ordinal = "\(gen)\(gen.ordinal)"
            officialName = officialName.replacingOccurrences(of: "\(ordinal) Gen", with: "(\(ordinal) generation)")
        }
//        if identifier.identifierVersion.majorVersion == 6 && officialName.contains("Apple Watch SE") {
//            officialName = officialName.replacingOccurrences(of: "SE ", with: "SE (2nd generation) ")
//        }
        if identifier.identifierVersion.majorVersion == 14 && officialName.contains("iPad Pro 11-inch") {
            officialName = "iPad Pro 11-inch (4th generation)"
        }
        
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
    
    func bridge(from device: Device) -> MobileDevice {
        // use local whatever the device has as long as it contains the local
//        guard device.identifiers.contains(identifier) else {
//            return MobileDevice(identifier: .unknownIdentifier, officialName: device.officialName)
//        }
        let identifierIndex = device.identifiers.firstIndex(of: identifier) ?? -1
        var officialName = device.officialName
            .replacingOccurrences(of: "(3rd generation)", with: "3")
        if device.idiom == .watch {
            if identifier.identifierNumber < 7.9 {
                officialName += " case"
            }
            if identifierIndex == 1 {
                officialName += " (GPS+Cellular)"
            }
        }
        if device.idiom == .pad {
            officialName = officialName
                .replacingOccurrences(of: "(M2)", with: "6th Gen")
                .replacingOccurrences(of: ["(",")"], with: "")
                .replacingOccurrences(of: "generation", with: "Gen")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "Mini 2", with: "mini retina")
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
        if !device.officialName.contains(String.unknown) {
            officialName = self.officialName
        }
        return MobileDevice(identifier: identifier, officialName: officialName)
    }
}

struct MobileDeviceLoader: DeviceBridgeLoader {
    func devices() async throws -> [MobileDevice] {
        var devices = [MobileDevice]()
        let lines = try await fetchURL(urlString: "https://gist.githubusercontent.com/adamawolf/3048717/raw/Apple_mobile_device_types.txt").lines
        for line in lines {
            guard line.trimmed != "" else {
//                print("skipping blank line")
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
