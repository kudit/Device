//
//  AppleDevice.swift
//  Device
//
//  Created by Ben Ku on 4/16/25.
//
// https://fuckingappledevices.com
// For exporting/importing from the AppleDevice project:
// https://github.com/superepicstudios/apple-devices/blob/main/swift/Sources/AppleDevices/Resources/data.json
// https://raw.githubusercontent.com/superepicstudios/apple-devices/refs/heads/main/swift/Sources/AppleDevices/Resources/data.json

// Data file order (by year then by identifier):
// iPod Touch
// AirTag
// Apple Vision Pro
// AirPods
// AppleTV
// Apple Watch
// HomePod
// iPad
// iPhone

import Device

struct AppleDeviceVersion: Codable, Equatable {
    var min: Version
    var max: Version?
}

struct AppleDeviceSoftwareItem: Codable, Equatable, CustomStringConvertible {
    var device_version: AppleDeviceVersion
    var id: String
    var name: String
    var version: AppleDeviceVersion
    var description: String {
        "Supported OSs: \(device_version.min) < \(device_version.max, default: "<current>")"
    }
}

struct AppleDeviceChip: Codable, Equatable, Hashable {
    var id: String
    var name: String
    init(chip: CPU) {
        // check map for exceptions
        let chipCase = chip.caseName
        var chipName = chip.rawValue
        if let adCpu = Self.appleDeviceCPUMap.firstKey(for: chip) {
            self = adCpu
            return
        }
        if !chipName.contains(" ") && !chipName.hasPrefix("AP") && !chipName.hasPrefix("Apple") { // all unnamed cases
            chipName = "Apple \(chipName.uppercased())"
        }
        id = chipCase
        name = chipName
    }
    init(_ id: String) {
        self.init(id, id.uppercased())
    }
    init(_ id: String, _ name: String) {
        self.id = id
        self.name = name
    }

    static let appleDeviceCPUMap = [
        Self("apl0098"): CPU.s5L8900,
        Self("apl0278"): .s5L8720,
        Self("apl2298"): .s5L8922,
        Self("apl0298"): .s5L8920,
        Self("a10", "Apple A10 Fusion"): .a10,
        Self("a15", "Apple A15 Bionic"): .a15,
        Self("a12x", "Apple A12X Bionic"): .a12x,
        Self("a12z", "Apple A12Z Bionic"): .a12z,
        Self("a13", "Apple A13 Bionic"): .a13,
        Self("a17pro", "Apple A17 Pro"): .a17pro,
        Self("a18pro", "Apple A18 Pro"): .a18pro,
        Self("a19pro", "Apple A19 Pro"): .a19pro,
    ]
    var cpu: CPU {
        for cpu in CPU.allCases {
            if cpu.caseName == id || cpu.rawValue == name || cpu == Self.appleDeviceCPUMap[self] {
                return cpu
            }
        }
        debug("Unknown CPU \(id): \(name)", level: .ERROR)
        return .unknown
    }
}

extension Device.Idiom {
    init(appleDeviceName: String) {
        if appleDeviceName.contains("Mac") {
            self = .mac
        } else if appleDeviceName.contains("iPod touch") {
            self = .pod
        } else if appleDeviceName.contains("iPhone") {
            self = .phone
        } else if appleDeviceName.contains("iPad") {
            self = .pad
        } else if appleDeviceName.contains("Apple TV") {
            self = .tv
        } else if appleDeviceName.contains("CarPlay") {
            self = .carPlay
        } else if appleDeviceName.contains("Apple Watch") {
            self = .watch
        } else if appleDeviceName.contains("HomePod") {
            self = .homePod
        } else if appleDeviceName.contains("Apple Vision") {
            self = .vision
        } else {
            self = .unspecified
        }
    }
    public var appleDeviceName: String {
        switch self {
        case .unspecified:
            return "Unspecified"
        case .mac:
            return "Mac"
        case .pod:
            return "iPod touch"
        case .phone:
            return "iPhone"
        case .pad:
            return "iPad"
        case .tv:
            return "Apple TV"
        case .carPlay:
            return "CarPlay"
        case .watch:
            return "Apple Watch"
        case .homePod:
            return "HomePod"
        case .vision:
            return "Apple Vision Pro"
            //            @unknown default:
            //                return "UnknownDevice"
        }
    }
}

enum AppleDeviceTrait: String, Codable, RawRepresentable {
    case actionButton = "button.action"
    case cameraControl = "button.camera"
    case homeButton = "button.home"
    case alwaysOnDisplay = "display.always-on"
    case dynamicIsland = "display.dynamic-island"
    case fluidDisplay = "display.fluid" // edge-to-edge display?  ignore since we don't really use this.
    case proMotion = "display.pro-motion"
    case displayNotch = "display.notch"
    case faceID = "id.face"
    case opticID = "id.optic"
    case touchID = "id.touch"
    case appleIntelligence = "intelligence"
    // For AirPods
    case audioANC = "audio.anc" // active noise cancellation?
    case audioSpatial = "audio.spatial"
    static let unmappedTraits: [AppleDeviceTrait] = [.fluidDisplay, .proMotion]
}

extension Capability {
    static let appleDeviceTraits: [AppleDeviceTrait: Capability] = [
        .actionButton: .actionButton,
        .cameraControl: .cameraControl,
//        .homeButton: .biometrics(.touchID), // not all button.home has touchID
        // this can be determined if we have touchID or no biometrics so we don't actually need to set anything
        .alwaysOnDisplay: .alwaysOnDisplay,
        .dynamicIsland: .dynamicIsland,
//        .fluidDisplay: ?,
        .displayNotch: .notch,
//        .proMotion: .proMotion,
        .faceID: .biometrics(.faceID),
        .opticID: .biometrics(.opticID),
        .touchID: .biometrics(.touchID),
        .appleIntelligence: .appleIntelligence,
    ]
        
    init?(appleDeviceTrait: AppleDeviceTrait) {
        for (key, value) in Capability.appleDeviceTraits {
            if key == appleDeviceTrait {
                self = value
                return
            }
        }
        return nil
    }
    
    var appleDeviceTrait: AppleDeviceTrait? {
        for (key, value) in Capability.appleDeviceTraits {
            if self == value {
                return key
            }
        }
        return nil
    }
}

extension Version {
    var unsupportedOSVersion: Version? {
        if majorVersion > 18 {
            return nil // supports current
        } else {
            var nextMajor = majorVersion + 1
            if nextMajor == 19 {
                nextMajor = 26
            }
            return .init(majorVersion: nextMajor, minorVersion: 0, patchVersion: 0)
        }
    }
}
extension Version {
    var maxSupportedVersion: Version {
        return .init(majorVersion: self.majorVersion - 1, minorVersion: 6, patchVersion: 1)
    }
}

struct AppleDevice: DeviceBridge {
    static var diffIgnoreKeys: [String] {
        ["name", "family"] // filter out and ignore these paths when calculating exact match - for things like DeviceKit comments or images/support URLs since we know those may differ
    }

    var name: String
    var gen_name: String?
    var year: Int
    var family: String
    var chip: AppleDeviceChip
    var software: [AppleDeviceSoftwareItem]
    var traits: [AppleDeviceTrait]
    var internal_names: [String]
    var a_numbers: [String]
    var ids: [String]
    
//    static let nameMapping = [ // AppleDevice name : Device officialName
//        "iPad mini (7th Gen)": "iPad mini (A17 Pro)",
//        "iPad Pro (11-inch) (5th Gen)": "iPad Pro 11-inch (M4)",
//        "iPad Air (11-inch) (2nd Gen)": "iPad Air 11-inch (M3)",
//        "iPad Air (13-inch) (2nd Gen)": "iPad Air 13-inch (M3)",
//        "iPad (11th Gen)": "iPad (A16)",
//        "(3rd Gen)": "(3rd generation)",
//        "(4th Gen)": "(4th generation)",
//        "Ultra (2nd Gen)" : "Ultra 2",
//    ]

    var matched: Device {
        Device.forcedLookup(identifier: ids.first, officialNameHint: gen_name)
    }
        
    var merged: Device {
        var capabilities = matched.capabilities
        for trait in traits {
            if let capability = Capability(appleDeviceTrait: trait) {
                capabilities.insert(capability)
            }
        }
        
        // "fix" device names
        var officialName = matched.officialName
        if let gen_name, gen_name != "Unspecified" {
            officialName = gen_name
        }
                
        let models = a_numbers.count == 0 ? matched.models : a_numbers
                        
        return Device(
            idiom: .init(appleDeviceName: name),
            officialName: officialName,
            identifiers: ids,
            introduction: year.introductionYear,
            supportId: matched.supportId,
            launchOSVersion: software.first?.device_version.min ?? matched.launchOSVersion,
            unsupportedOSVersion: software.last?.device_version.max?.unsupportedOSVersion ?? matched.unsupportedOSVersion,
            image: matched.image,
            capabilities: capabilities,
            models: models,
            colors: matched.colors,
            cpu: chip.cpu)
    }

    func bridge(from device: Device) -> Self {
        var traits = [AppleDeviceTrait]()
        if (device.biometrics == nil || device.biometrics == Biometrics.none) && [.phone, .pod, .pad].contains(device.idiom) {
            traits.append(.homeButton)
        }
        for unmapped in AppleDeviceTrait.unmappedTraits {
            if self.traits.contains(unmapped) {
                traits.append(unmapped) // not tracking (yet)
            }
        }
        // go through capabilities and map
        traits.append(contentsOf: device.capabilities.compactMap { $0.appleDeviceTrait })
        // It's all over the place for iPads.
        if device.biometrics == .touchID { // TODO: Restrict to iPads before a certain year?
//            if !self.traits.contains(.touchID) { // Hack to remove touchID flag if the parsed device doesn't have it
//                traits.remove(.touchID)
//            }
            if self.traits.contains(.homeButton) { // only include homeButton if the parsed device has a homeButton since we're not tracking it in this framework.
                traits.append(.homeButton)
            }
        }
/*
        // "fix"es because Apple Device list has some bad data
        if traits.contains(.displayNotch) && device.idiom == .pad {
//            traits.remove(.displayNotch) // Figure out which devices are showing notch on iPad??
        }
        // "fix" because Apple Device list is missing action button
        if device.identifiers.contains("Watch7,12") {
            traits.remove(.actionButton)
        }*/
        
        if Set(traits) == Set(self.traits) {
            traits = self.traits // make sure this is the same order since it isn't a set.
        }

//        for (mdName, myName) in Self.nameMapping {
//            officialName = officialName.replacingOccurrences(of: mdName, with: myName)
//        }

        var name = device.idiom.appleDeviceName
        if self.name.contains(name) {
            name = self.name // ignore Apple TV HD is just called Apple TV
        }
        
        var gen_name: String? = device.officialName
        if self.gen_name == .unknown || self.gen_name == nil {
            // local data isn't better, but doesn't need to be updated, so don't flag as different
            gen_name = self.gen_name
        }
        
//        // "fix" Apple Vision Pro naming inconsistency NOTE: family will likely never be bad, so just assume it's my value and ignore.
//        var family = device.idiom.identifier
//        if self.family == "Apple_Vision" {
//            family = self.family
//        } else if self.family == "Apple_TV" {
//            family = self.family
//        } else if self.family == "Apple_Watch" {
//            family = self.family
//        }
        
        var software = software
        // update fields with device values if available
        if !software.isEmpty, let swf = software.first, let swl = software.last {
            let minVersion = swf.device_version.min
            if minVersion != device.launchOSVersion && device.launchOSVersion.majorVersion != minVersion.majorVersion { // "fix" since this data has the launch for iPod9,1 as 12.3 when other sources say 12.3.1 (among others)
                software[0].device_version.min = device.launchOSVersion
            }
            if let maxVersion = device.unsupportedOSVersion?.maxSupportedVersion, swl.device_version.max?.majorVersion != maxVersion.majorVersion {
                software[software.count - 1].device_version.max = maxVersion
            }
        }
        var year = device.introduction?.date?.year ?? 1902
        if ids.containsAny(["AppleTV1,1", "AppleTV3,2", "Watch7,5", "iPad7,11", "iPhone11,8", "iPhone11,2", "iPhone11,4"]) {
            software = self.software // "fix" to ignore completely since this software was never updated or the AppleDevice data is bad (due to split?)
            year = self.year
        }
//        [AppleDeviceSoftwareItem(
//            device_version: AppleDeviceVersion(
//                min: device.launchOSVersion,
//                max: device.unsupportedOSVersion.maxSupportedVersion(hint: software.device_version?.max)),
//            id: device.idiom.osName.lowercased(),
//            name: device.idiom.osName,
//            version: AppleDeviceVersion(min: "1.0", max: "26.0"))],
        
        // make sure we ignore if this already exists (Device version may have more)
        var a_numbers = a_numbers
        if device.models.containsAll(a_numbers) {
            a_numbers = self.a_numbers
        }
        
        // Apple Watch ids are grouped, so ignore the fact that we've split
        var ids = device.identifiers
        if self.ids.containsAll(ids) {
            ids = self.ids
        }

        return AppleDevice(
            name: name,
            gen_name: gen_name,
            year: year,
            family: self.family,
            chip: AppleDeviceChip(chip: device.cpu),
            software: software,
            traits: traits,
            internal_names: internal_names, // codenames (don't store so just use default)
            a_numbers: a_numbers,
            ids: ids)
    }
        
    var source: String {
        self.prettyJSON
    }
    //    {
    //        "name" : "iPod touch",
    //        "gen_name" : "iPod touch (2nd Gen)",
    //        "year" : 2008,
    //        "family" : "iPod",
    //        "chip" : {
    //            "id" : "apl0278",
    //            "name" : "APL0278"
    //        },
    //        "software" : [
    //            {
    //                "device_version" : {
    //                    "min" : "2.1.1",
    //                    "max" : "3.2.2"
    //                },
    //                "id" : "iphoneos",
    //                "name" : "iPhone OS",
    //                "version" : {
    //                    "min" : "1.0",
    //                    "max" : "3.2.2"
    //                }
    //            },
    //            {
    //                "device_version" : {
    //                    "min" : "4.0",
    //                    "max" : "4.2.1"
    //                },
    //                "id" : "ios",
    //                "name" : "iOS",
    //                "version" : {
    //                    "min" : "4.0",
    //                    "max" : "18.4.1"
    //                }
    //            }
    //        ],
    //        "traits" : [
    //            "button.home"
    //        ],
    //        "internal_names" : [
    //            "N72AP"
    //        ],
    //        "a_numbers" : [
    //            "A1288",
    //            "A1319"
    //        ],
    //        "ids" : [
    //            "iPod2,1"
    //        ]
    //    },
}

struct AppleDeviceLoader: DeviceBridgeLoader {
    typealias Bridge = AppleDevice
    
    func devices() async throws -> [AppleDevice] {
        // import Apple Device data.json
        let jsonString = try await fetchURL(urlString: "https://raw.githubusercontent.com/superepicstudios/apple-devices/refs/heads/main/swift/Sources/AppleDevices/Resources/data.json")

        let devices = try [AppleDevice](fromJSON: jsonString)
        var returnDevices = [AppleDevice]()
        // split AppleTV3,1 and AppleTV3,2
        for device in devices {
            // ignore AirTags and AirPods
            if ["AirTag", "AirPod"].contains(device.family) { continue }
            if device.ids.contains("AppleTV3,1") {
                // split
                var splitDevice = device
                for id in device.ids {
                    splitDevice.ids = [id]
                    returnDevices.append(splitDevice)
                }
            } else if device.ids.contains("AppleTV14,1") {
                // split AppleTV14,1 (for wifi and wifi + Ethernet versions)
                var splitDevice = device
                splitDevice.gen_name = "Apple TV 4K (3rd generation) Wi-Fi + Ethernet"
                returnDevices.append(splitDevice)
                splitDevice.gen_name = "Apple TV 4K (3rd generation) Wi-Fi"
                returnDevices.append(splitDevice)
            } else {
                returnDevices.append(device)
            }
        }
        return returnDevices
    }
    
    // MARK: - for generation

/*    // For generating a new file based on our data in case we want to submit a pull request?
    func generate() -> String {
        let adDevices = iPod.allDevices
            + AppleVision.allDevices
            + AppleTV.allDevices
            + AppleWatch.allDevices
            + HomePod.allDevices
            + iPad.allDevices
            + iPhone.allDevices
        let mapped = adDevices.map { $0.asAppleDevice() }
        return mapped.asJSON(outputFormatting: .prettyPrinted).replacingOccurrences(of: "  ", with: "\t")
        //    {
        //        "name" : "iPod touch",
        //        "gen_name" : "iPod touch (2nd Gen)",
        //        "year" : 2008,
        //        "family" : "iPod",
        //        "chip" : {
        //            "id" : "apl0278",
        //            "name" : "APL0278"
        //        },
        //        "software" : [
        //            {
        //                "device_version" : {
        //                    "min" : "2.1.1",
        //                    "max" : "3.2.2"
        //                },
        //                "id" : "iphoneos",
        //                "name" : "iPhone OS",
        //                "version" : {
        //                    "min" : "1.0",
        //                    "max" : "3.2.2"
        //                }
        //            },
        //            {
        //                "device_version" : {
        //                    "min" : "4.0",
        //                    "max" : "4.2.1"
        //                },
        //                "id" : "ios",
        //                "name" : "iOS",
        //                "version" : {
        //                    "min" : "4.0",
        //                    "max" : "18.4.1"
        //                }
        //            }
        //        ],
        //        "traits" : [
        //            "button.home"
        //        ],
        //        "internal_names" : [
        //            "N72AP"
        //        ],
        //        "a_numbers" : [
        //            "A1288",
        //            "A1319"
        //        ],
        //        "ids" : [
        //            "iPod2,1"
        //        ]
        //    },

    }*/
}
