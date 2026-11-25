//
//  HomeView.swift
//  Device
//

import Compatibility

/// Display-equipped Apple HomeView accessories, separate from speaker-only HomePod devices.
public struct HomeView: IdiomType {
	public let device: Device

	/// Wraps an already catalogued HomeView device.
	public init(knownDevice: Device) {
		self.device = knownDevice
	}

	/// Creates a HomeView model from its published hardware metadata.
	public init(
		officialName: String,
		identifiers: [String],
		introduction: DateString? = nil,
		supportId: String = .unknownSupportId,
		launchOSVersion: Version,
		unsupportedOSVersion: Version? = nil,
		image: String? = nil,
		capabilities: Capabilities = [],
		models: [String] = [],
		colors: [AppleMaterialColor] = [],
		cpu: CPU = .unknown
	) {
		device = Device(
			idiom: .homeView,
			officialName: officialName,
			identifiers: identifiers,
			introduction: introduction,
			supportId: supportId,
			launchOSVersion: launchOSVersion,
			unsupportedOSVersion: unsupportedOSVersion,
			image: image,
			capabilities: capabilities.union(Device.Idiom.homeView.capabilities).union([.touchDisplay]),
			models: models,
			colors: colors,
			cpu: cpu
		)
	}

	/// Creates a fallback HomeView record for an identifier not yet in the catalog.
	public init(identifier: String) {
		self.init(
			officialName: "Unknown HomeView",
			identifiers: [identifier],
			launchOSVersion: .zero,
			cpu: .unknown
		)
	}

	/// SF Symbol representing HomeView hardware.
	public var symbolName: SFSymbol {
        "house.fill"
    }

	public static let all = [
		HomeView(
			officialName: "HomeView",
			identifiers: ["HomeAccessory17,1"],
			introduction: "2026-11-13",
			supportId: "https://www.apple.com/apple-homeview/specs/",
			launchOSVersion: "27.3",
			image: "https://store.storeimages.cdn-apple.com/1/as-images.apple.com/is/homeview-finish-select-202610-homeview-standalone?wid=5120&hei=2880&fmt=webp&qlt=90&.v=VGdIY0tGWW9ZcWpES3pId3FubTgybm9rVXQrQXBwbjdYUGx6UjVjN1FSa1FTSG9UL1hrVGdwVEJqZi83N3NmUThHVUZrb2Ixc1JuUHord2JOR2ZkK1NYR1ZZZnEyMVlVQUliTThGMjNyaFNsT0QveVowekhVWTJkcUpWRWQxdUJYTDJxZTFBUXE3Yzg4WG9xNGRVODJn&traceId=1",
			capabilities: [.cameras([.centerStage]), .appleIntelligence],
			colors: [.solidSilver, .homeStarlight, .homeRosePink, .homeSpaceGray],
			cpu: .a18
		),
		HomeView(
			officialName: "HomeView (Wall Mounted)",
			identifiers: ["HomeAccessory17,2"],
			introduction: "2026-11-13",
			supportId: "https://www.apple.com/apple-homeview/specs/",
			launchOSVersion: "27.3",
			image: "https://store.storeimages.cdn-apple.com/1/as-images.apple.com/is/homeview-finish-select-202610-homeview-wallmount?wid=5120&hei=2880&fmt=webp&qlt=90&.v=VGdIY0tGWW9ZcWpES3pId3FubTgybm9rVXQrQXBwbjdYUGx6UjVjN1FSbmU1bi90WFNUVkI0OHUySFNYQ2xISThLcXQxZ1h0QThIT2dnUm5qbGk5OUJkSERIUjY1Wk1Od3FtNjF6NFZLVXQySWZqcm1IM1hkZHl2S2lFQkp6MlhvcE1KVitsNmU0UWZlS1hvNGpxMVh3&traceId=1",
			capabilities: [.cameras([.centerStage]), .appleIntelligence],
			colors: [.solidSilver, .homeSpaceGray],
			cpu: .a18
		)
	]
}
