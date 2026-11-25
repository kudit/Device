import Foundation
import Compatibility
#if canImport(Combine)
import Combine
#endif
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif
#if os(watchOS)
import WatchKit
#endif
#if canImport(CoreMotion) && os(iOS) && !targetEnvironment(macCatalyst)
import CoreMotion
#endif

/// Owns live OS discovery. Snapshots remain usable independently of this observable provider.
/// Start/stop are idempotent; windows are never retained by the monitor.
@MainActor
final class DisplayMonitor: ObservableObjectBackport {
	static let shared = DisplayMonitor()
	var _objectWillChange: AnyObject?
	#if canImport(Combine)
	@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
	var objectWillChange: ObservableObjectPublisher { backportObjectWillChange }
	#endif
	private(set) var displays: [DisplaySnapshot] = []
	private(set) var presentations: [PresentationSnapshot] = []
	private(set) var discovery: DisplayDiscovery = .unavailable
	#if canImport(UIKit) || canImport(AppKit)
	private var tokens: [NSObjectProtocol] = []
	#endif
	private var started = false
	private var displayIDs: [ObjectIdentifier: String] = [:]
	// NSScreen wrappers can be replaced while the underlying connected output stays the same.
	private var desktopDisplayIDs: [UInt32: String] = [:]
	private var windowIDs: [ObjectIdentifier: String] = [:]
	private(set) var lastCameraCornerOrientation: Device.Orientation?
	#if canImport(CoreMotion) && os(iOS) && !targetEnvironment(macCatalyst)
	private let motionManager = CMMotionManager()
	private var gravityX: Double?
	private var gravityY: Double?
	private var gravityZ: Double?
	private var lastPublishedOrientation: Device.LegacyOrientation?
	private var motionOwners: Set<UUID> = []
	private var oneShotMotionOwners: Set<UUID> = []
	private var motionUpdateCompletions: [UUID: (Device.Orientation, Device.Pose) -> Void] = [:]
	#endif
	/// Refresh notifications may be forwarded to a containing current-device provider.
	var didChange: (() -> Void)?
	init() {}
	deinit {
		#if canImport(UIKit) || canImport(AppKit)
		for token in tokens { NotificationCenter.default.removeObserver(token) }
		#endif
		#if os(iOS) && !targetEnvironment(macCatalyst)
		if started { main { UIDevice.current.endGeneratingDeviceOrientationNotifications() } }
		if !motionOwners.isEmpty { motionManager.stopDeviceMotionUpdates() }
		#endif
	}
	private var measuredOrientation: Device.LegacyOrientation {
		#if os(iOS) && !targetEnvironment(macCatalyst)
		let motion = motionManager.deviceMotion?.gravity
		let x = motion?.x ?? gravityX
		let y = motion?.y ?? gravityY
		let z = motion?.z ?? gravityZ
		let mapped = x.flatMap { gx in y.flatMap { gy in z.flatMap { gz in Self.orientation(gravityX: gx, gravityY: gy, gravityZ: gz) } } }
			?? Self.orientation(UIDevice.current.orientation)
		return mapped
		#elseif os(watchOS)
		return WKInterfaceDevice.current().crownOrientation == .left ? .portrait : .portraitUpsideDown
		#elseif os(macOS) || os(tvOS)
		return .landscapeLeft
		#else
		return .unknown
		#endif
	}
	private var measuredDeviceOrientation: Device.Orientation {
		let device = Device.current.device
		return Device.Orientation(legacy: measuredOrientation, idiom: device.idiom, isFoldable: device.screens.count > 1)
	}
	var deviceOrientation: Device.Orientation {
		let orientation = measuredDeviceOrientation
		if orientation.isCameraCorner { lastCameraCornerOrientation = orientation }
		return orientation
	}
	/// Starts a shared motion stream for a live consumer; the owner must stop it when done.
	func startPoseMonitoring(owner: UUID) {
		#if canImport(CoreMotion) && os(iOS) && !targetEnvironment(macCatalyst)
		guard motionOwners.insert(owner).inserted else { return }
		guard motionOwners.count == 1 else { return }
		startMotionUpdates()
		UIDevice.current.beginGeneratingDeviceOrientationNotifications()
		#else
		_ = owner
		#endif
	}
	/// Releases a live consumer's motion stream, stopping sensors after the final owner leaves.
	func stopPoseMonitoring(owner: UUID) {
		#if canImport(CoreMotion) && os(iOS) && !targetEnvironment(macCatalyst)
		motionOwners.remove(owner)
		oneShotMotionOwners.remove(owner)
		motionUpdateCompletions.removeValue(forKey: owner)
		guard motionOwners.isEmpty else { return }
		motionManager.stopDeviceMotionUpdates()
		UIDevice.current.endGeneratingDeviceOrientationNotifications()
		#else
		_ = owner
		#endif
	}
	/// Requests one fresh pose sample without leaving Core Motion active afterward.
	func requestMotionUpdate(_ completion: @escaping (Device.Orientation, Device.Pose) -> Void) {
		#if canImport(CoreMotion) && os(iOS) && !targetEnvironment(macCatalyst)
		guard motionManager.isDeviceMotionAvailable else { completion(deviceOrientation, pose); return }
		let owner = UUID()
		motionOwners.insert(owner)
		oneShotMotionOwners.insert(owner)
		motionUpdateCompletions[owner] = completion
		if motionOwners.count == 1 {
			startMotionUpdates()
			UIDevice.current.beginGeneratingDeviceOrientationNotifications()
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
			guard let monitor = self, let pending = monitor.motionUpdateCompletions.removeValue(forKey: owner) else { return }
			monitor.oneShotMotionOwners.remove(owner)
			monitor.motionOwners.remove(owner)
			pending(monitor.deviceOrientation, monitor.pose)
			if monitor.motionOwners.isEmpty {
				monitor.motionManager.stopDeviceMotionUpdates()
				UIDevice.current.endGeneratingDeviceOrientationNotifications()
			}
		}
		#else
		completion(deviceOrientation, pose)
		#endif
	}
	func requestPoseUpdate(_ completion: @escaping (Device.Pose) -> Void) {
		requestMotionUpdate { _, pose in completion(pose) }
	}
	#if canImport(CoreMotion) && os(iOS) && !targetEnvironment(macCatalyst)
	private func startMotionUpdates() {
		guard motionManager.isDeviceMotionAvailable else { return }
		motionManager.deviceMotionUpdateInterval = 0.2
		motionManager.startDeviceMotionUpdates(to: .main) { [weak self] sample, _ in
			guard let owner = self, let sample else { return }
			main { owner.receiveMotionSample(sample.gravity.x, sample.gravity.y, sample.gravity.z) }
		}
	}
	private func receiveMotionSample(_ x: Double, _ y: Double, _ z: Double) {
		gravityX = x; gravityY = y; gravityZ = z
		let orientation = measuredOrientation
		let cameraCorner = measuredDeviceOrientation
		if cameraCorner.isCameraCorner { lastCameraCornerOrientation = cameraCorner }
		if orientation != lastPublishedOrientation {
			lastPublishedOrientation = orientation
			// Device orientation and pose can change while the display inventory stays fixed.
			objectWillChangeBackport()
			didChange?()
		}
		for owner in Array(oneShotMotionOwners) {
			guard let completion = motionUpdateCompletions.removeValue(forKey: owner) else { continue }
			oneShotMotionOwners.remove(owner)
			motionOwners.remove(owner)
			completion(deviceOrientation, pose)
		}
		if motionOwners.isEmpty {
			motionManager.stopDeviceMotionUpdates()
			UIDevice.current.endGeneratingDeviceOrientationNotifications()
		}
	}
	#endif
	private var measuredGravityZ: Double? {
		#if canImport(CoreMotion) && os(iOS) && !targetEnvironment(macCatalyst)
		return motionManager.deviceMotion?.gravity.z ?? gravityZ
		#else
		return nil
		#endif
	}
	var pose: Device.Pose {
		let measured = measuredDeviceOrientation
		return Device.Pose.inferred(orientation: measured,
			hinge: DeviceHingeRegistry.shared.current, gravityZ: measuredGravityZ,
			isFoldable: Device.current.device.screens.count > 1)
	}
	#if os(iOS) && !targetEnvironment(macCatalyst)
	static func orientation(gravityX x: Double, gravityY y: Double, gravityZ z: Double) -> Device.LegacyOrientation {
		if abs(z) >= abs(x) && abs(z) >= abs(y) && abs(z) > 0.7 { return z > 0 ? .faceDown : .faceUp }
		if abs(y) >= abs(x) { return y < 0 ? .portrait : .portraitUpsideDown }
		// Core Motion's gravity.x sign is opposite the UIKit landscape labels:
		// negative X means the device is rotated into landscapeLeft.
		return x < 0 ? .landscapeLeft : .landscapeRight
	}
	private static func orientation(_ orientation: UIDeviceOrientation) -> Device.LegacyOrientation {
		switch orientation {
		case .portrait: return .portrait
		case .portraitUpsideDown: return .portraitUpsideDown
		case .landscapeLeft: return .landscapeLeft
		case .landscapeRight: return .landscapeRight
		case .faceDown: return .faceDown
		case .faceUp: return .faceUp
		case .unknown: return .unknown
		@unknown default: return .unknown
		}
	}
	#endif
	func start() {
		guard !started else { return }; started = true
		#if canImport(UIKit) || canImport(AppKit)
		var names: [Notification.Name] = []
		#if canImport(UIKit) && !os(watchOS)
		#if !os(visionOS)
		names += [UIScreen.didConnectNotification, UIScreen.didDisconnectNotification, UIScreen.modeDidChangeNotification, UIScreen.brightnessDidChangeNotification]
		#endif
		if #available(iOS 13, tvOS 13, *) {
			names += [UIScene.didActivateNotification, UIScene.willDeactivateNotification, UIScene.didDisconnectNotification, UIScene.willConnectNotification, UIScene.didEnterBackgroundNotification]
		}
		#if os(iOS) && !targetEnvironment(macCatalyst)
		// Device orientation is observed only while a pose consumer owns the motion stream.
		#endif
		#elseif canImport(AppKit)
		names += [NSApplication.didChangeScreenParametersNotification, NSWindow.didMoveNotification, NSWindow.didResizeNotification, NSWindow.didChangeScreenNotification, NSWindow.didChangeBackingPropertiesNotification, NSWindow.didBecomeKeyNotification, NSWindow.didResignKeyNotification, NSWindow.willCloseNotification]
		#endif
		for name in names {
				tokens.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
					guard let owner = self else { return }
					main { owner.refresh() }
				})
		}
		#endif
		refresh()
	}
	func stop() {
		guard started else { return }; started = false
		#if canImport(CoreMotion) && os(iOS) && !targetEnvironment(macCatalyst)
		motionManager.stopDeviceMotionUpdates()
		if !motionOwners.isEmpty { UIDevice.current.endGeneratingDeviceOrientationNotifications() }
		motionOwners.removeAll()
		oneShotMotionOwners.removeAll()
		motionUpdateCompletions.removeAll()
		#endif
		#if canImport(UIKit) || canImport(AppKit)
		for token in tokens { NotificationCenter.default.removeObserver(token) }; tokens.removeAll()
		#endif
	}
	/// Rebuilds shared pose/display state after the single registered hinge observer changes.
	func hingeDidChange() {
		// Angle changes may leave the coarse pose and display inventory unchanged,
		// but live gauge views still need a redraw for each new hinge sample.
		objectWillChangeBackport()
		refresh()
	}
	private func displayID(_ object: AnyObject) -> String {
		let key = ObjectIdentifier(object)
		if let id = displayIDs[key] { return id }
		let id = UUID().uuidString; displayIDs[key] = id; return id
	}
	private func windowID(_ object: AnyObject) -> String {
		let key = ObjectIdentifier(object)
		if let id = windowIDs[key] { return id }
		let id = UUID().uuidString; windowIDs[key] = id; return id
	}
	/// Remeasures inventory; stable values retain their previous capture timestamp.
	func refresh() {
		var outputs: [DisplaySnapshot] = []
		var windows: [PresentationSnapshot] = []
		var coverage = DisplayDiscovery.unavailable
		#if canImport(UIKit) && !os(watchOS)
		if #available(iOS 13, tvOS 13, *) {
			coverage = .appScenes
			let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
			for scene in scenes {
				#if !os(visionOS)
				let display = snapshot(for: scene.screen)
				if !outputs.contains(where: { $0.id == display.id }) { outputs.append(display) }
				#endif
				for window in scene.windows {
					let snapshot = presentation(for: window)
					windows.append(snapshot)
					if !outputs.contains(where: { $0.id == snapshot.display.id }) { outputs.append(snapshot.display) }
				}
			}
			#if !os(visionOS)
			if scenes.isEmpty {
				// SwiftUI availability does not imply that the host opted into scenes.
				coverage = .legacyScreenInventory
				outputs = UIScreen.screens.map { snapshot(for: $0) }
			}
			#endif
		} else {
			#if !os(visionOS)
			coverage = .legacyScreenInventory
			outputs = UIScreen.screens.map { snapshot(for: $0) }
			#endif
		}
		#elseif canImport(AppKit)
		coverage = .desktopInventory
		outputs = NSScreen.screens.map { snapshot(for: $0) }
		windows = (NSApp?.windows ?? []).compactMap { presentation(for: $0) }
		#elseif os(watchOS)
		coverage = .legacyScreenInventory
		let screen = WKInterfaceDevice.current()
		outputs = [.init(id: "watch-local", name: "Local display", bounds: .init(width: Double(screen.screenBounds.width), height: Double(screen.screenBounds.height), space: .display), scale: Double(screen.screenScale))]
		#endif
		outputs = outputs.map { new in displays.first(where: { $0.hasSameMeasurements(as: new) }) ?? new }.sorted { $0.id < $1.id }
		windows = windows.map { new in presentations.first(where: { $0.hasSameMeasurements(as: new) }) ?? new }.sorted { $0.id < $1.id }
		let activeDisplays = Set(outputs.map(\.id) + outputs.compactMap(\.mirroredDisplayID))
		let activeWindows = Set(windows.map(\.id))
		displayIDs = displayIDs.filter { activeDisplays.contains($0.value) }
		desktopDisplayIDs = desktopDisplayIDs.filter { activeDisplays.contains($0.value) }
		windowIDs = windowIDs.filter { activeWindows.contains($0.value) }
		guard outputs != displays || windows != presentations || coverage != discovery else { return }
		objectWillChangeBackport(); displays = outputs; presentations = windows; discovery = coverage
		didChange?()
	}
}

#if canImport(Combine)
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension DisplayMonitor: @preconcurrency ObservableObject {}
#endif

#if canImport(UIKit) && !os(watchOS)
extension DisplayMonitor {
	#if !os(visionOS)
	private func measuredBrightness(_ screen: UIScreen) -> Double? {
		#if os(tvOS)
		return nil
		#else
		return Double(screen.brightness)
		#endif
	}
	func snapshot(for screen: UIScreen) -> DisplaySnapshot {
		let mode = screen.currentMode.map { DisplaySnapshot.Mode(pixels: .init(width: Double($0.size.width), height: Double($0.size.height))) }
		let refresh: Int?
		if #available(iOS 10.3, tvOS 10.2, *) { refresh = screen.maximumFramesPerSecond } else { refresh = nil }
		return .init(id: displayID(screen), bounds: DisplayRect(screen.bounds, space: .display), scale: Double(screen.scale),
			nativePixels: .init(width: Double(screen.nativeBounds.width), height: Double(screen.nativeBounds.height)), mode: mode,
			mirroredDisplayID: screen.mirrored.map { displayID($0) }, maximumFramesPerSecond: refresh, brightness: measuredBrightness(screen))
	}
	#endif
	func presentation(for window: UIWindow, localBounds: CGRect? = nil, safeArea: UIEdgeInsets? = nil, hinge: Device.Hinge? = nil) -> PresentationSnapshot {
		let display: DisplaySnapshot
		let frame: DisplayRect?
		#if os(visionOS)
		display = .init(id: displayID(window.windowScene ?? window), name: "Virtual output; physical panel unavailable", scale: Double(window.traitCollection.displayScale))
		frame = nil
		#else
		if #available(iOS 13, tvOS 13, *), let scene = window.windowScene { display = snapshot(for: scene.screen) }
		else { display = snapshot(for: window.screen) }
		// UIWindow.frame is already expressed in screen coordinates. Converting
		// window.bounds (whose origin is window-local) produced an origin that
		// drifted as the window resized and could use the wrong coordinate basis.
		let windowFrame = window.frame
		let screenOrigin = display.bounds.map { CGPoint(x: CGFloat($0.x), y: CGFloat($0.y)) } ?? .zero
		frame = .init(x: Double(windowFrame.minX - screenOrigin.x), y: Double(windowFrame.minY - screenOrigin.y),
			width: Double(windowFrame.width), height: Double(windowFrame.height), space: .display)
		#endif
		var activation = PresentationSnapshot.Activation.unknown
		var orientation: PresentationSnapshot.Orientation?
		if #available(iOS 13, tvOS 13, *), let scene = window.windowScene {
			switch scene.activationState {
			case .foregroundActive: activation = .foregroundActive
			case .foregroundInactive: activation = .foregroundInactive
			case .background: activation = .background
			case .unattached: activation = .unattached
			@unknown default: activation = .unknown
			}
			#if !os(visionOS) && !os(tvOS)
			switch scene.interfaceOrientation {
			case .portrait: orientation = .portrait
			case .portraitUpsideDown: orientation = .portraitUpsideDown
			case .landscapeLeft: orientation = .landscapeLeft
			case .landscapeRight: orientation = .landscapeRight
			default: orientation = .unknown
			}
			#endif
		}
		let insets: UIEdgeInsets?
		if let safeArea { insets = safeArea }
		else if #available(iOS 11, tvOS 11, *) { insets = window.safeAreaInsets } else { insets = nil }
		func sizeClass(_ value: UIUserInterfaceSizeClass) -> PresentationSnapshot.SizeClass {
			value == .compact ? .compact : value == .regular ? .regular : .unspecified
		}
		return .init(id: windowID(window), display: display, windowBounds: .init(window.bounds, space: .window), windowFrame: frame,
			localBounds: localBounds.map { .init($0, space: .localView) },
			safeArea: insets.map { .init(top: Double($0.top), leading: Double($0.left), bottom: Double($0.bottom), trailing: Double($0.right)) },
			activation: activation, interfaceOrientation: orientation,
			horizontalSizeClass: sizeClass(window.traitCollection.horizontalSizeClass), verticalSizeClass: sizeClass(window.traitCollection.verticalSizeClass), hinge: hinge)
	}
}
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
extension DisplayMonitor {
	private func desktopDisplayID(_ screen: NSScreen) -> String {
		guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else { return displayID(screen) }
		let key = number.uint32Value
		if let id = desktopDisplayIDs[key] { return id }
		let id = UUID().uuidString; desktopDisplayIDs[key] = id; return id
	}
	func snapshot(for screen: NSScreen) -> DisplaySnapshot {
		let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
		let nativeID = number.map { CGDirectDisplayID($0.uint32Value) }
		let nativeMode = nativeID.flatMap { CGDisplayCopyDisplayMode($0) }
		let mirror = nativeID.map { CGDisplayMirrorsDisplay($0) }.flatMap { mirrorID -> String? in
			guard mirrorID != kCGNullDirectDisplay,
				let source = NSScreen.screens.first(where: { ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value == mirrorID }) else { return nil }
			return desktopDisplayID(source)
		}
		let name: String?
		if #available(macOS 10.15, *) { name = screen.localizedName } else { name = nil }
		return .init(id: desktopDisplayID(screen), name: name, bounds: .init(screen.frame, space: .desktopBottomLeft), scale: Double(screen.backingScaleFactor),
			mode: nativeMode.map { .init(pixels: .init(width: Double($0.pixelWidth), height: Double($0.pixelHeight)), refreshRate: $0.refreshRate > 0 ? $0.refreshRate : nil) }, mirroredDisplayID: mirror,
			brightness: nativeID.flatMap { Self.measuredBrightness(for: $0) })
	}
	/// Brightness is not available through the supported Core Graphics display-ID APIs.
	/// The former IOKit service bridge was removed from the macOS SDK, so avoid
	/// depending on an unavailable or private mapping and report no measurement.
	private static func measuredBrightness(for displayID: CGDirectDisplayID) -> Double? {
		nil
	}
	func presentation(for window: NSWindow, localBounds: CGRect? = nil, safeArea: DisplayInsets? = nil) -> PresentationSnapshot? {
		guard let screen = window.screen else { return nil }
		// Convert AppKit's global bottom-left desktop coordinates to a top-left
		// position relative to the hosting display for the live screen card.
		let frame = window.frame
		let screenFrame = screen.frame
		let position = DisplayRect(x: Double(frame.minX - screenFrame.minX), y: Double(screenFrame.maxY - frame.maxY),
			width: Double(frame.width), height: Double(frame.height), space: .display)
		return .init(id: windowID(window), display: snapshot(for: screen), windowBounds: .init(window.contentView?.bounds ?? .zero, space: .window), windowFrame: position,
			localBounds: localBounds.map { .init($0, space: .localView) }, safeArea: safeArea,
			activation: !window.isVisible ? .background : NSApp?.isActive == true ? .foregroundActive : .foregroundInactive)
	}
}
#endif

#if canImport(CoreGraphics)
import CoreGraphics
extension DisplayRect {
	init(_ rect: CGRect, space: Space) { self.init(x: Double(rect.origin.x), y: Double(rect.origin.y), width: Double(rect.width), height: Double(rect.height), space: space) }
}
#endif
