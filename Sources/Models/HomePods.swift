//
//  Accessories.swift
//  Device
//
//  Created by Ben Ku on 4/18/25.
//

import Compatibility

public struct HomePod: IdiomType {
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
        colors: [MaterialColor],
        cpu: CPU)
    {
        device = Device(
            idiom: .homePod,
            officialName: officialName,
            identifiers: identifiers,
            introduction: introduction,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities.union(Device.Idiom.homePod.capabilities),
            models: models,
            colors: colors,
            cpu: cpu)
    }
    
    init(identifier: String) {
        self.init(
            officialName: "Unknown HomePod",
            identifiers: [identifier],
            supportId: .unknownSupportId,
            launchOSVersion: "11",
            unsupportedOSVersion: nil,
            image: nil,
            colors: .default,
            cpu: .unknown
        )
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        if self.is(.mini) {
            return "homepodmini"
        }
        return "homepod"
    }

    static let all = [
        
        HomePod(
            officialName: "HomePod",
            identifiers: ["AudioAccessory1,1", "AudioAccessory1,2"], // TODO: What is AudioAccessory1,2?
            introduction: 2018.introductionYear,
            supportId: "SP773",
            launchOSVersion: "1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/homepod/2018-homepod-colors.png",
            models: ["A1639"],
            colors: [.spacegrayHome, .whiteHome],
            cpu: .a8),
        HomePod(
            officialName: "HomePod mini",
            identifiers: ["AudioAccessory5,1"],
            introduction: 2020.introductionYear,
            supportId: "SP834",
            launchOSVersion: "14.2", // audioOS
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/SZLF0YNV/images/sp/111914_homepod-mini-colours.png",
            capabilities: [.mini],
            models: ["A2374"],
            colors: .homePodMini,
            cpu: .s5),
        HomePod(
            officialName: "HomePod (2nd generation)",
            identifiers: ["AudioAccessory6,1"],
            introduction: 2023.introductionYear,
            supportId: "SP888",
            launchOSVersion: "16", // audioOS
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/SZLF0YNV/images/sp/111843_homepod-2gen.png",
            models: ["A2825"],
            colors: .homePod,
            cpu: .s7),
        
    ]
}
