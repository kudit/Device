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
        colors: [AppleMaterialColor],
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
    
    public init(identifier: String) { // Public for DeviceKit testing
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
    public var symbolName: SFSymbol {
        if self.is(.mini) {
            return "homepodmini.fill"
        }
        return "homepod.fill"
    }

    public static let all = [ // Public for DeviceKit testing
        
        HomePod(
            officialName: "HomePod",
            identifiers: ["AudioAccessory1,1", "AudioAccessory1,2"], // TODO: What is AudioAccessory1,2?
            introduction: "2018-02-09",
            supportId: "SP773",
            launchOSVersion: "11.0.2",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/homepod/2018-homepod-colors.png",
            models: ["A1639"],
            colors: [.spacegrayHome, .whiteHome],
            cpu: .a8),
        HomePod(
            officialName: "HomePod mini",
            // AppleDB also publishes the single-unit alias for this hardware.
            identifiers: ["AudioAccessory5,1", "AudioAccessorySingle5,1"],
            introduction: "2020-11-16",
            supportId: "SP834",
            launchOSVersion: "14.2", // audioOS
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/SZLF0YNV/images/sp/111914_homepod-mini-colours.png",
            capabilities: [.mini],
            models: ["A2374", "A2531"], // second is China Mainland version.
            colors: .homePodMini,
            cpu: .s5),
        HomePod(
            officialName: "HomePod (2nd generation)",
            identifiers: ["AudioAccessory6,1"],
            introduction: "2023-02-03",
            supportId: "SP888",
            launchOSVersion: "16", // audioOS
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/SZLF0YNV/images/sp/111843_homepod-2gen.png",
            models: ["A2825", "A2878"],
            colors: .homePod,
            cpu: .s7),
		HomePod(
			officialName: "HomePod mini 2",
			// Published firmware and AppleDB identify this generation separately
			// from the original mini. The A-number is not yet in Apple's support
			// material, so do not copy the original mini's model number here.
			identifiers: ["AudioAccessory11,1"],
			introduction: "2026-10-30",
			supportId: .unknownSupportId,
			launchOSVersion: "27.2", // audioOS
			unsupportedOSVersion: nil,
			image: "https://store.storeimages.cdn-apple.com/1/as-images.apple.com/is/homepod-mini-select-202610?wid=1080&hei=800&fmt=jpeg&qlt=90&.v=K2c3bEwyaWVDeDZkdHpLbHkwcGVSdWV6Y2RFUDJIZjNNL0drRzBRQnVCN2J2QWtudTM3aGhQSXBRdG9ZWloyNEJkRlpCNVhYU3AwTldRQldlSnpRa0N2TE82ZG83bTM1bXRKeHlobm5SWGs",
			capabilities: [.mini],
			models: [],
			// Keep the catalog colors empty until Apple publishes accurate
			// swatch values; the original mini's palette is not this model's.
			colors: .homePodMini2,
			cpu: .s10),

    ]
}
