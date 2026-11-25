#if canImport(Foundation)
import Foundation
import Compatibility

/// Each foreground observer owns its own sample. Detaching one does not erase others.
@MainActor
final class DeviceHingeRegistry {
	static let shared = DeviceHingeRegistry()
	private struct Sample { let hinge: Device.Hinge; let date: Date; let order: UInt64 }
	private var sequence: UInt64 = 0
	private var samples: [UUID: Sample] = [:]
	private var latestSample: Sample?
	var current: Device.Hinge? { samples.values.max { $0.order < $1.order }?.hinge ?? latestSample?.hinge }
	func update(_ hinge: Device.Hinge?, observer: UUID) {
		if let hinge {
			sequence &+= 1
			let sample = Sample(hinge: hinge, date: Date(), order: sequence)
			samples[observer] = sample
			latestSample = sample
		}
		else { samples.removeValue(forKey: observer) }
		// Publish hinge-driven pose changes through the shared device/display provider.
		DisplayMonitor.shared.hingeDidChange()
	}
	func remove(_ observer: UUID) {
		samples.removeValue(forKey: observer)
		// Retain the newest live sample while any observer remains attached, but
		// discard the registry's snapshot after its final observer detaches.
		latestSample = samples.values.max { $0.order < $1.order }
		DisplayMonitor.shared.hingeDidChange()
	}
}

#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
	/// Native old/new hinge contexts when the SDK supports them; no synthetic events otherwise.
	/// The verified SwiftUI module version enables the native adapter automatically.
	/// DEVICE_HAS_DUO_SDK is an explicit override for other verified SDK distributions.
	@ViewBuilder
	func onHingeChange(isEnabled: Bool = true, _ action: @escaping (Device.Hinge.Context, Device.Hinge.Context) -> Void) -> some View {
		#if os(iOS) && !targetEnvironment(macCatalyst) && !DEVICE_DISABLE_DUO_SDK && (DEVICE_HAS_DUO_SDK || canImport(SwiftUI, _version: 8.0.85.29))
		if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
			content.modifier(NativeDeviceHingeObserver(isEnabled: isEnabled, action: action))
		} else { content }
		#else
		content
		#endif
	}
}

#if os(iOS) && !targetEnvironment(macCatalyst) && !DEVICE_DISABLE_DUO_SDK && (DEVICE_HAS_DUO_SDK || canImport(SwiftUI, _version: 8.0.85.29))
@available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *)
private struct NativeDeviceHingeObserver: ViewModifier {
	let isEnabled: Bool
	let action: (Device.Hinge.Context, Device.Hinge.Context) -> Void
	@Environment(\.scenePhase) private var phase
	@State private var observer = UUID()
	@State private var latest: Device.Hinge?
	func body(content: Content) -> some View {
		// System overlays such as Control Center can make the scene inactive while
		// the app remains visible. Keep observing in that state so the hinge dial
		// retains its last sample; stop only once the scene is backgrounded.
		content.onHingeChange(isEnabled: isEnabled && phase != .background) { old, new in
			let previous = Device.Hinge.Context(hinge: old.hinge.map(Device.Hinge.init))
			let current = Device.Hinge.Context(hinge: new.hinge.map(Device.Hinge.init))
			latest = current.hinge
			DeviceHingeRegistry.shared.update(current.hinge, observer: observer)
			action(previous, current)
		}
		.onChange(of: isEnabled) { enabled in
			if !enabled { detach() }
		}
		.onChange(of: phase) { phase in
			if phase == .background { detach() }
		}
		.onDisappear { detach() }
	}
	private func detach() {
		let previous = Device.Hinge.Context(hinge: latest)
		latest = nil; DeviceHingeRegistry.shared.remove(observer)
		// Availability loss is meaningful only when this observer had a sample.
		if previous.hinge != nil { action(previous, .init()) }
	}
}
#endif
#endif
#endif
