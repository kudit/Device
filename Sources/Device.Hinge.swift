import Compatibility
import struct Compatibility.Angle
#if canImport(SwiftUI)
import SwiftUI
#endif

public extension Device {
	/// Portable hinge angle type, Codable even on deployment targets predating SwiftUI.
	typealias HingeAngle = Angle

	/// A live foldable-device hinge measurement. Non-foldable or unsupported devices return nil.
	struct Hinge: Hashable, Codable, Sendable {
		/// Open-ended native status values remain forward-compatible with new operating systems.
		public enum Status: String, RawRepresentable, Hashable, Codable, Sendable {
			case closed
			case partiallyOpen
			case fullyOpen
		}
        
        public typealias Angle = Device.HingeAngle
        
        public var status: Status
        /// Uses the portable Codable angle even when a SwiftUI-capable SDK targets older macOS.
        public var angle: Angle
		/// True whenever the hinge is no longer fully closed.
		public var isOpen: Bool { status != .closed || angle.degrees > 0 }
		/// True only when the hinge has reached its fully open state.
		public var isFullyOpen: Bool { status == .fullyOpen && angle.degrees >= 180 }
        public init(status: Status, angle: Angle) {
            self.status = status
            self.angle = angle
        }
        
		public func inferredPose(for orientation: Device.Orientation? = nil, gravityZ: Double? = nil) -> Device.Pose {
			Device.Pose.inferred(
				orientation: orientation,
				hinge: self,
				gravityZ: gravityZ,
				isFoldable: true
			)
        }
	}
}

#if canImport(SwiftUI)
#if !DEVICE_DISABLE_DUO_SDK && (DEVICE_HAS_DUO_SDK || canImport(SwiftUI, _version: 8.0.85.29)) // WHY IS THIS LINE NECESSARY???
@available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
public extension Device.Hinge {
    init(_ value: SwiftUI.DeviceHinge) {
        self.status = .init(value.status)
        self.angle = .radians(value.angle.radians)
    }
    // no swiftUIValue because apparently DeviceHinge objects can only be gotten from the system and can't be constructed.
}
@available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
public extension Device.Hinge.Status {
    /// Returns the native SwiftUI hinge status value when the running SDK and OS expose it.
    var swiftUIValue: SwiftUI.DeviceHinge.Status {
        switch self {
        case .closed: return .closed
        case .partiallyOpen: return .partiallyOpen
        case .fullyOpen: return .fullyOpen
        }
    }
    init(_ value: SwiftUI.DeviceHinge.Status) {
        switch value {
        case .closed:
            self = .closed
        case .partiallyOpen:
            self = .partiallyOpen
        case .fullyOpen:
            fallthrough
        default:
            self = .fullyOpen
        }
    }
}
#endif
#endif

public extension Device.Hinge {
	/// Previous and current values delivered by the hinge-change backport.
	struct Context: Equatable, Sendable {
		public var hinge: Device.Hinge?
		public init(hinge: Device.Hinge? = nil) { self.hinge = hinge }
	}
}
