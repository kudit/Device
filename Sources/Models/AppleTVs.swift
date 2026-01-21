//
//  AppleTVs.swift
//  Device
//
//  Created by Ben Ku on 4/18/25.
//

import Compatibility

public struct AppleTV: IdiomType {
    public let device: Device
    public init(knownDevice: Device) {
        self.device = knownDevice
    }

    public init(
        officialName: String,
        identifiers: [String],
        introduction: DateString? = nil,
        supportId: String,
        launchOSVersion: Version,
        unsupportedOSVersion: Version?,
        image: String?,
        capabilities: Capabilities = [],
        models: [String] = [],
        cpu: CPU)
    {
        device = Device(
            idiom: .tv,
            officialName: officialName,
            identifiers: identifiers,
            introduction: introduction,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities.union(Device.Idiom.tv.capabilities),
            models: models,
            colors: [.black],
            cpu: cpu)
    }

    public init(identifier: String) { // Public for DeviceKit testing
        self.init(
            officialName: "Unknown  TV",
            identifiers: [identifier],
            introduction: nil,
            supportId: .unknownSupportId,
            launchOSVersion: "18",
            unsupportedOSVersion: nil,
            image: nil,
            cpu: .unknown)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return "appletv"
    }

    public static let all = [ // https://support.apple.com/en-us/101605  // Public for DeviceKit testing
        
        AppleTV(
            officialName: "Apple TV 4K (3rd generation) Wi-Fi + Ethernet",
            identifiers: ["AppleTV14,1"],
            introduction: 2022.introductionYear,
            supportId: "SP886",
            launchOSVersion: "16.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/fall-2022-apple-tv-w-remote.png",
            capabilities: [.ethernet],
            models: ["A2843"],
            cpu: .a15),
        AppleTV(
            officialName: "Apple TV 4K (3rd generation) Wi-Fi",
            identifiers: ["AppleTV14,1"],
            introduction: 2022.introductionYear,
            supportId: "SP886",
            launchOSVersion: "16.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/fall-2022-apple-tv-w-remote.png",
            models: ["A2737"],
            cpu: .a15),
        AppleTV(
            officialName: "Apple TV 4K (2nd generation)",
            identifiers: ["AppleTV11,1"],
            introduction: 2021.introductionYear,
            supportId: "SP845",
            launchOSVersion: "14.5",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-4k-2nd-gen.png",
            capabilities: [.ethernet],
            models: ["A2169"],
            cpu: .a12),
        AppleTV(
            officialName: "Apple TV 4K (1st generation)",
            identifiers: ["AppleTV6,2"],
            introduction: 2017.introductionYear,
            supportId: "SP769",
            launchOSVersion: "11",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-4k.jpg",
            capabilities: [.ethernet],
            models: ["A1842"],
            cpu: .a10x),
        AppleTV(
            officialName: "Apple TV HD",
            identifiers: ["AppleTV5,3"],
            introduction: 2015.introductionYear,
            supportId: "SP724",
            launchOSVersion: "9",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-4gen-hd.jpg",
            capabilities: [.ethernet, .usbC],
            models: ["A1625"],
            cpu: .a8),
        // These models don't support app development but are here since they're in the identification page and are here for reference.
        AppleTV(
            officialName: "Apple TV (3rd generation) rev A", // separate model due to quiet replacement: https://everymac.com/systems/apple/apple-tv/specs/apple-tv-3rd-generation-early-2013-specs.html
            identifiers: ["AppleTV3,2"],
            introduction: "2013-01-29",
            supportId: "SP648",
            launchOSVersion: "6.1",
            unsupportedOSVersion: "8",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-3gen.jpg",
            capabilities: [.ethernet], // .microUSB
            models: ["A1469"],
            cpu: .a5),
        AppleTV(
            officialName: "Apple TV (3rd generation)",
            identifiers: ["AppleTV3,1"],
            introduction: 2012.introductionYear,
            supportId: "SP648",
            launchOSVersion: "5.1",
            unsupportedOSVersion: "8",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-3gen.jpg",
            capabilities: [.ethernet], // .microUSB
            models: ["A1427"],
            cpu: .a5),
        AppleTV(
            officialName: "Apple TV (2nd generation)",
            identifiers: ["AppleTV2,1"],
            introduction: 2010.introductionYear,
            supportId: "SP598",
            launchOSVersion: "4.1", // iOS variant
            unsupportedOSVersion: "7", // max 6.2.1
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-2gen.jpg",
            capabilities: [.ethernet],
            models: ["A1378"],
            cpu: .a4),
        AppleTV(
            officialName: "Apple TV (1st generation)",
            identifiers: ["AppleTV1,1"],
            introduction: 2007.introductionYear,
            supportId: "SP19",
            launchOSVersion: "10.4.7", // stripped down macOS
            unsupportedOSVersion: "10.5", // not updated
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-1gen.jpg",
            capabilities: [.ethernet],
            models: ["A1218"],
            cpu: .intel_pm1),
    ]
}
