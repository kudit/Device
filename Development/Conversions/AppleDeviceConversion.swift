//
//  AppleDevice.swift
//  Device
//
//  Created by Ben Ku on 4/16/25.
//
// For exporting/importing from the AppleDevice project:
// https://github.com/superepicstudios/apple-devices/blob/main/swift/Sources/AppleDevices/Resources/data.json

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
import Compatibility

let adDevices = iPod.allDevices
    + AppleVision.allDevices
    + AppleTV.allDevices
    + AppleWatch.allDevices
    + HomePod.allDevices
    + iPad.allDevices
    + iPhone.allDevices

struct AppleDeviceVersion: Codable, Equatable {
    var min: Version
    var max: Version?
}

struct AppleDeviceSoftwareItem: Codable, Equatable {
    var device_version: AppleDeviceVersion
    var id: String
    var name: String
    var version: AppleDeviceVersion
}

struct AppleDeviceChip: Codable, Equatable {
    var id: String
    var name: String
    init(chip: CPU) {
        id = chip.caseName
        name = chip.rawValue
    }

    static let appleDeviceCPUMap = [
        "apl0098": CPU.s5L8900,
        "apl0278": .s5L8720,
        "apl2298": .s5L8922,
        "apl0298": .s5L8920,
    ]
    var cpu: CPU {
        for cpu in CPU.allCases {
            if cpu.caseName == id || cpu.rawValue == name || cpu == Self.appleDeviceCPUMap[id] {
                return cpu
            }
        }
        debug("Unknown CPU \(id): \(name)", level: .ERROR)
        return .unknown
    }
}

extension Device.Idiom {
    init(appleDeviceName: String) {
        switch appleDeviceName {
        case "Mac":
            self = .mac
        case "iPod touch":
            self = .pod
        case "iPhone":
            self = .phone
        case "iPad":
            self = .pad
        case "Apple TV":
            self = .tv
        case "CarPlay":
            self = .carPlay
        case "Apple Watch":
            self = .watch
        case "HomePod":
            self = .homePod
        case "Apple Vision Pro":
            self = .vision
        default:
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

extension Capability {
    static let appleDeviceTraits: [String: Capability] = [
        "button.action": .actionButton,
        "button.camera": .cameraControl,
//        "button.home": .biometrics(.touchID),
        // this can be determined if we have touchID or no biometrics so we don't actually need to set anything
        "display.always-on": .alwaysOnDisplay,
        "display.dynamic-island": .dynamicIsland,
//        "display.fluid": .adaptiveRefreshRate,?
        "display.notch": .notch,
//        "display.pro-motion": .proMotion,
        "id.face": .biometrics(.faceID),
        "id.optic": .biometrics(.opticID),
        "id.touch": .biometrics(.touchID),
        "intelligence": .appleIntelligence,
    ]
        
    init?(trait: String) {
        for (key, value) in Capability.appleDeviceTraits {
            if key == trait {
                self = value
                return
            }
        }
        return nil
    }
    
    var appleDeviceTrait: String? {
        for (key, value) in Capability.appleDeviceTraits {
            if self == value {
                return key
            }
        }
        return nil
    }
}

struct AppleDevice: Codable, Equatable, DeviceBridge {
    var name: String
    var gen_name: String?
    var year: Int
    var family: String
    var chip: AppleDeviceChip
    var software: [AppleDeviceSoftwareItem]
    var traits: [String]
    var internal_names: [String]
    var a_numbers: [String]
    var ids: [String]
        
    static let nameMapping = [
        "iPad mini (7th Gen)": "iPad mini (A17 Pro)",
        "iPad Pro (11-inch) (5th Gen)": "iPad Pro 11-inch (M4)",
        "iPad Air (11-inch) (2nd Gen)": "iPad Air 11-inch (M3)",
        "iPad Air (13-inch) (2nd Gen)": "iPad Air 13-inch (M3)",
        "iPad (11th Gen)": "iPad (A16)",
        "(3rd Gen)": "(3rd generation)",
        "(4th Gen)": "(4th generation)",
        "Ultra (2nd Gen)" : "Ultra 2",
        ]

    var device: Device {
        var lastVersion = software.last?.device_version.max
        if lastVersion?.majorVersion ?? 0 > 17 {
            lastVersion = nil // supports current
        } else {
            lastVersion?.majorVersion++
            lastVersion?.minorVersion = 0
            lastVersion?.patchVersion = 0
        }
        
        var capabilities = Capabilities()
        for trait in traits {
            if let capability = Capability(trait: trait) {
                capabilities.insert(capability)
            }
        }
        
        // "fix" device names
        var officialName = gen_name ?? .unknown
        for (mdName, myName) in Self.nameMapping {
            officialName = officialName.replacingOccurrences(of: mdName, with: myName)
        }
        
        return Device(
            idiom: .init(appleDeviceName: name),
            officialName: officialName,
            identifiers: ids,
            introduction: year.introductionYear,
            supportId: .unknownSupportId,
            launchOSVersion: .zero, // always use original since this data is often bad
            //software.first?.device_version.min ?? .zero,
            unsupportedOSVersion: lastVersion,
            image: nil,
            capabilities: capabilities,
            models: a_numbers,
            colors: [],
            cpu: chip.cpu)
    }
    
//    func merged(from base: Device) -> Device {
//        // look up base device based off of ids?
//        if let identifier = ids.first, let base = Device(identifier: identifier) {
//            self.device.merged(from: base)
//        }

    var source: String {
        self.asJSON(outputFormatting: [.prettyPrinted]) // sortedKeys?
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
    
    static let fromJSON: [AppleDevice] = {
        // import Apple Device data.json
        if let url = Bundle.main.url(forResource: "appleDeviceData", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                var jsonString = String(decoding: data, as: UTF8.self)

                let devices = try [AppleDevice](fromJSON: jsonString)
                // TODO: split AppleTV3,1 and AppleTV3,2
                // TODO: split AppleTV14,1 (for wifi and wifi + Ethernet versions)
                // ignore AirTags and AirPods
                return devices.filter { !["AirTag", "AirPod"].contains($0.family) }
            } catch {
                debug("error:\(error)", level: .ERROR)
            }
        }
        return []
    }()
    
    static func generate() -> String {
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

    }
}

extension Device {
    func asAppleDevice() -> AppleDevice {
        var traits = [String]()
        if (biometrics == nil || biometrics == Biometrics.none) && [.phone, .pod, .pad].contains(idiom) {
            traits.append("button.home")
        }
        // go through capabilities and map
        traits.append(contentsOf: capabilities.compactMap { $0.appleDeviceTrait })
        return AppleDevice(
            name: idiom.appleDeviceName,
            gen_name: officialName,
            year: introduction?.date?.year ?? 1902,
            family: idiom.identifier,
            chip: AppleDeviceChip(chip: cpu),
            software: [],
            traits: traits,
            internal_names: [],
            a_numbers: models,
            ids: identifiers
        )
    }
}
