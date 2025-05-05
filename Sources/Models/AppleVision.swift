//
//  AppleVision.swift
//  Device
//
//  Created by Ben Ku on 4/18/25.
//

import Compatibility

public struct AppleVision: IdiomType, HasCameras {
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
        cpu: CPU
    ) {
        device = Device(
            idiom: .vision,
            officialName: officialName,
            identifiers: identifiers,
            introduction: introduction,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: Device.Idiom.vision.capabilities,
            models: models,
            colors: [.silver],
            cpu: cpu
        )
    }
    
    init(identifier: String) {
        self.init(
            officialName: "Unknown  Vision Device",
            identifiers: [identifier],
            introduction: nil,
            supportId: .unknownSupportId,
            launchOSVersion: "2",
            unsupportedOSVersion: nil,
            image: nil,
            cpu: .unknown)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return "visionpro"
    }

    static let all = [

        AppleVision(
            officialName: "Apple Vision Pro",
            identifiers: ["RealityDevice14,1"],
            introduction: 2024.introductionYear,
            supportId: "SP911",
            launchOSVersion: "1.0.2",
            unsupportedOSVersion: nil,
            image: "https://help.apple.com/assets/65E610E3F8593B4BE30B127E/65E610E47F977D429402E427/en_US/4609019342a9aa9c2560aaeb92e6c21a.png",
            models: ["A2117"],
            cpu: .m2),
        
    ]
}
