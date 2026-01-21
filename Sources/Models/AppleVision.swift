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
            capabilities: Device.Idiom.vision.capabilities.union(capabilities),
            models: models,
            colors: [.silver],
            cpu: cpu
        )
    }
    
    public init(identifier: String) { // Public for DeviceKit testing
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

    public static let all = [ // Public for DeviceKit testing

        AppleVision(
            officialName: "Apple Vision Pro (M5)",
            identifiers: ["RealityDevice17,1"],
            introduction: "2025-10-22",
            supportId: "https://www.apple.com/apple-vision-pro/specs/",
            launchOSVersion: "26.0.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/vision-pro/apple-vision-pro-m5.png",
            models: ["A3416"],
            cpu: .m5),

        AppleVision(
            officialName: "Apple Vision Pro (M2)",
            identifiers: ["RealityDevice14,1"],
            introduction: "2024-02-02",
            supportId: "117810", //"SP911"
            launchOSVersion: "1.0.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/vision-pro/apple-vision-pro.png",
            models: ["A2117"],
            cpu: .m2),
        
    ] // Models: https://support.apple.com/en-mk/125375
}
