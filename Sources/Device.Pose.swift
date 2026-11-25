import Foundation
import Compatibility
#if canImport(UIKit)
import UIKit
#endif

public extension Device {
	/// Current physical orientation of the device, separate from window layout and legacy UIKit directions.
	enum Orientation: String, CaseIterable, Hashable, Codable, Sendable, SymbolRepresentable {
		case unknown, portrait
		case cameraTopLeft, cameraTopRight, cameraBottomLeft, cameraBottomRight
		case faceUp, faceDown

		/// Converts a legacy UIKit direction; tablets and foldables use the back-camera corner.
		public init(legacy: Device.LegacyOrientation, idiom: Device.Idiom, isFoldable: Bool = false) {
			switch legacy {
			case .unknown: self = .unknown
			case .faceUp: self = .faceUp
			case .faceDown: self = .faceDown
			case .portrait: self = isFoldable || idiom == .pad ? .cameraTopRight : .portrait
			case .portraitUpsideDown: self = .cameraBottomLeft
			case .landscapeLeft: self = .cameraTopLeft
			case .landscapeRight: self = .cameraBottomRight
			}
		}

		/// Nearest UIKit cardinal direction for compatibility bridges.
		public var legacyOrientation: Device.LegacyOrientation {
			switch self {
			case .portrait, .cameraTopRight: return .portrait
			case .cameraBottomLeft: return .portraitUpsideDown
			case .cameraTopLeft: return .landscapeLeft
			case .cameraBottomRight: return .landscapeRight
			case .faceUp: return .faceUp
			case .faceDown: return .faceDown
			case .unknown: return .unknown
			}
		}

		public init(legacyOrientation: Device.LegacyOrientation, idiom: Device.Idiom, isFoldable: Bool = false) {
			self.init(legacy: legacyOrientation, idiom: idiom, isFoldable: isFoldable)
		}

		/// Human-readable test label that explains the camera-corner cases.
		public var accessibilityDescription: String {
			switch self {
			case .unknown: return "Orientation unavailable"
			case .portrait: return "Portrait"
			case .cameraTopLeft: return "Camera upper left"
			case .cameraTopRight: return "Camera upper right"
			case .cameraBottomLeft: return "Camera lower left"
			case .cameraBottomRight: return "Camera lower right"
			case .faceUp: return "Face up"
			case .faceDown: return "Face down"
			}
		}

		public var symbolName: String {
			switch self {
			case .unknown: return "questionmark.square.dashed"
			case .portrait: return "rectangle.portrait"
			case .cameraTopLeft, .cameraTopRight, .cameraBottomLeft, .cameraBottomRight: return "square.split.bottomrightquarter"
			case .faceUp: return "square"
			case .faceDown: return "square.fill"
			}
		}

		public var isLandscape: Bool {
			[.cameraTopLeft, .cameraBottomRight].contains(self)
		}

		public var isCameraCorner: Bool {
			switch self {
			case .cameraTopLeft, .cameraTopRight, .cameraBottomLeft, .cameraBottomRight: return true
			default: return false
			}
		}

		public var isFaceUpOrDown: Bool {
			self == .faceUp || self == .faceDown
		}

		public var rotationDegrees: Double {
			switch self {
			case .cameraTopRight, .portrait: return 0
			case .cameraBottomRight: return 90
			case .cameraBottomLeft: return 180
			case .cameraTopLeft: return -90
			default: return 0
			}
		}

		/// Rotation that moves the marked lower-right corner to the rear-camera corner.
		var cameraCornerRotationDegrees: Double {
			switch self {
			case .cameraTopLeft: return 180
			case .cameraTopRight: return -90
			case .cameraBottomLeft: return 90
			case .cameraBottomRight: return 0
			default: return 0
			}
		}
	}

	/// Previous cardinal orientation cases used by UIKit and source compatibility bridges.
	enum LegacyOrientation: Int, Hashable, Codable, Sendable, CaseIterable {
		case unknown = 0, portrait = 1, portraitUpsideDown = 2, landscapeLeft = 3, landscapeRight = 4, faceUp = 5, faceDown = 6
		public var symbolName: String {
			switch self {
			case .unknown: return "questionmark.square"
			case .portrait: return "rectangle.portrait"
			case .portraitUpsideDown: return "rectangle.portrait.slash"
			case .landscapeLeft: return "rectangle"
			case .landscapeRight: return "rectangle.fill"
			case .faceUp: return "square.fill"
			case .faceDown: return "square.slash"
			}
		}
		public var accessibilityDescription: String {
			switch self {
			case .unknown: return "Orientation unavailable"
			case .portrait: return "Portrait"
			case .portraitUpsideDown: return "Portrait upside down"
			case .landscapeLeft: return "Landscape left"
			case .landscapeRight: return "Landscape right"
			case .faceUp: return "Face up"
			case .faceDown: return "Face down"
			}
		}
	}

	/// The configured side of Apple Watch's Digital Crown.
	enum CrownSide: String, Hashable, Codable, Sendable, CaseIterable {
		case left, right
		public var symbolName: String { "applewatch.side.right" }
		public var rotationDegrees: Double { self == .left ? 180 : 0 }
		public var accessibilityDescription: String { "Crown on the \(rawValue)" }
	}



	/// Physical posture of the device, independent of its orientation and window layout.
	enum Pose: String, CaseIterable, Hashable, Codable, Sendable {
		case unknown, closed, tent, book, seated, fullyOpen

		func symbolName(for device: any DeviceType, orientation: Device.Orientation) -> String {
			switch self {
			case .unknown: return "questionmark.square.dashed"
			case .closed:
				switch orientation {
				case .cameraTopLeft: return "pose.closed.landscape.left"
				case .cameraBottomRight: return "pose.closed.landscape.right"
				case .cameraBottomLeft: return "pose.closed.portrait.upsidedown"
				default: return "pose.closed.portrait"
				}
			case .tent: return "pose.tent"
			case .book: return "pose.book"
			case .seated: return "pose.seated"
			case .fullyOpen: return orientation.isLandscape ? "pose.open.portrait" : "pose.open.landscape"
			}
		}

		static func inferred(
			orientation: Device.Orientation?,
			hinge: Device.Hinge?,
			gravityZ: Double?,
			isFoldable: Bool
		) -> Self {
			guard isFoldable else { return .unknown }
			guard let hinge else { return .unknown }
			if hinge.status == .closed {
				guard hinge.angle.degrees > 0 else { return .closed }
			}
			if hinge.status == .fullyOpen || hinge.angle.degrees >= 180 { return .fullyOpen }
			// When the Duo rests on its camera bump, its screen faces upward while
			// the hinge remains partly open. Preserve that posture instead of
			// classifying it from the last camera-corner orientation (often book).
			if orientation == .faceUp || orientation == .faceDown {
				return abs(gravityZ ?? 0) >= 0.9 ? .seated : .unknown
			}
			switch orientation {
			case .cameraTopLeft: return .seated
			case .cameraTopRight, .cameraBottomLeft: return .book
			case .cameraBottomRight:
				// In the lower-right camera corner, gravity distinguishes the usual
				// tent position from the uncommon seated position resting on the camera
				// bump. A nearly horizontal device plane has |gravityZ| close to 1.
				return abs(gravityZ ?? 0) >= 0.9 ? .seated : .tent
			default: return .unknown
			}
		}

		var accessibilityDescription: String {
			switch self {
			case .unknown: return "Posture unavailable"
			case .closed: return "Closed"
			case .tent: return "Tent"
			case .book: return "Book"
			case .seated: return "Seated"
			case .fullyOpen: return "Fully open"
			}
		}

		static func supported(for device: any DeviceType) -> [Self] {
			if device.screens.count > 1 { return [.closed, .tent, .book, .seated, .fullyOpen] }
			return []
		}
	}

}

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
public extension Device.Orientation {
	/// Converts UIKit's cardinal orientation into this framework's camera-corner orientation.
	init(uiDeviceOrientation: UIDeviceOrientation, idiom: Device.Idiom, isFoldable: Bool = false) {
		let legacy: Device.LegacyOrientation
		switch uiDeviceOrientation {
		case .portrait: legacy = .portrait
		case .portraitUpsideDown: legacy = .portraitUpsideDown
		case .landscapeLeft: legacy = .landscapeLeft
		case .landscapeRight: legacy = .landscapeRight
		case .faceUp: legacy = .faceUp
		case .faceDown: legacy = .faceDown
		default: legacy = .unknown
		}
		self.init(legacy: legacy, idiom: idiom, isFoldable: isFoldable)
	}

	/// Nearest UIKit cardinal orientation; camera-corner directions map through the legacy bridge.
	var uiDeviceOrientation: UIDeviceOrientation {
		switch legacyOrientation {
		case .portrait: return .portrait
		case .portraitUpsideDown: return .portraitUpsideDown
		case .landscapeLeft: return .landscapeLeft
		case .landscapeRight: return .landscapeRight
		case .faceUp: return .faceUp
		case .faceDown: return .faceDown
		case .unknown: return .unknown
		}
	}
}
#endif
#if canImport(SwiftUI)
import SwiftUI

private func poseAssetName(_ name: String) -> String {
	if #available(iOS 17, macOS 14, tvOS 17, watchOS 10, macCatalyst 17, *) {
		return name
	}
	return "\(name).legacy"
}

/// Renders a device-family pose glyph and rotates it for the selected orientation.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct DevicePoseView: View {
	public let pose: Device.Pose
	public let device: any DeviceType
	public let orientation: Device.Orientation
	public init(pose: Device.Pose, device: any DeviceType, orientation: Device.Orientation = .portrait) { self.pose = pose; self.device = device; self.orientation = orientation }
	@MainActor public init() { device = Device.current.device; pose = Device.current.pose; orientation = Device.current.deviceOrientation }
	public var body: some View {
		let glyphOrientation = orientation.isFaceUpOrDown
			? DisplayMonitor.shared.lastCameraCornerOrientation
				?? Device.Orientation(legacy: .portrait, idiom: device.idiom, isFoldable: device.screens.count > 1)
			: orientation
		let name = pose.symbolName(for: device, orientation: glyphOrientation)
		// Load package pose artwork directly so a same-named SF Symbol cannot
		// shadow the corrected artwork. Keep unknown-state system symbols resolvable.
		// Image(symbolName:) prefers system symbols, which can shadow these assets
		// on newer OS releases and reintroduce the broken closed landscape glyph.
		let image = name.hasPrefix("pose.")
			? SwiftUI.Image(poseAssetName(name), bundle: .module)
			: Image(symbolName: name)
		image
		.accessibility(label: Text(pose.accessibilityDescription))
	}
}

/// Shows the device's own idiom glyph rotated to the reported orientation.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct DeviceOrientationView: View {
	/// Device orientation represented by the icon.
	public let orientation: Device.Orientation
	/// Device model used to choose an idiom-specific glyph.
	public let device: any DeviceType
	/// Creates an orientation indicator using the device's most specific available symbol.
	public init(orientation: Device.Orientation, device: any DeviceType) { self.orientation = orientation; self.device = device }
	public var body: some View {
		ZStack {
			SwiftUI.Image(symbolName: orientation.symbolName)
				.rotationEffect(.degrees(orientation.cameraCornerRotationDegrees))
			if orientation.isFaceUpOrDown,
			   let cameraCorner = DisplayMonitor.shared.lastCameraCornerOrientation {
				GeometryReader { geometry in
					let diameter = max(4, min(geometry.size.width, geometry.size.height) * 0.13)
					let inset = diameter * 0.8
					Circle()
						.fill(Color.primary)
						.frame(width: diameter, height: diameter)
						.position(
							x: cameraCorner == .cameraTopLeft || cameraCorner == .cameraBottomLeft ? inset : geometry.size.width - inset,
							y: cameraCorner == .cameraTopLeft || cameraCorner == .cameraTopRight ? inset : geometry.size.height - inset
						)
				}
				.allowsHitTesting(false)
			}
		}
		.accessibility(label: Text(orientation.accessibilityDescription))
	}
}

/// Shows the configured Digital Crown side using Apple's watch glyph.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct WatchCrownSideView: View {
	public let side: Device.CrownSide
	public init(side: Device.CrownSide) { self.side = side }
	public var body: some View {
		SwiftUI.Image(symbolName: side.symbolName)
			.rotationEffect(.degrees(side.rotationDegrees))
			.backport.accessibilityLabel(side.accessibilityDescription)
	}
}
#endif
