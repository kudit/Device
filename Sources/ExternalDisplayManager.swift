import Foundation
import Compatibility

/// Content rotation chosen for each output, independently of its physical/window measurements.
public enum ExternalDisplayOrientation: Int, CaseIterable, Codable, Sendable, CustomStringConvertible {
	case upright, bottomAtLeft, bottomAtRight, upsideDown
	public var id: Self { self }
	public var description: String {
		switch self { case .upright: return "Right Side Up"; case .bottomAtLeft: return "Bottom at Left"; case .bottomAtRight: return "Bottom at Right"; case .upsideDown: return "Upside Down" }
	}
	public var rotated: Bool { self == .bottomAtLeft || self == .bottomAtRight }
	public var degrees: Double {
		switch self { case .upright: return 0; case .bottomAtLeft: return -90; case .bottomAtRight: return 90; case .upsideDown: return 180 }
	}
	/// Rotated content dimensions, without modifying display or window bounds.
	public func contentSize(for size: DisplaySize) -> DisplaySize {
		rotated ? .init(width: size.height, height: size.width) : size
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension ExternalDisplayOrientation: Identifiable {}

/// Builder input giving each external presentation its own identity and rotation.
public struct ExternalPresentationContext: Sendable {
	public let presentation: PresentationSnapshot
	public let orientation: ExternalDisplayOrientation
	/// Source layout when the OS explicitly reports mirroring; nil for extended output.
	public let mirroredSource: PresentationSnapshot?
	public var contentBounds: DisplayRect {
		let size = orientation.contentSize(for: mirroredSource?.localBounds?.size ?? mirroredSource?.windowBounds?.size ?? presentation.windowBounds?.size ?? presentation.localBounds?.size ?? .zero)
		return .init(width: size.width, height: size.height, space: .rotatedContent)
	}
	/// Fits the rotated bounding box, not the pre-rotation canvas (important for mirrored portrait output).
	public func scaleToFit(in output: DisplaySize) -> Double {
		let rendered = orientation.contentSize(for: contentBounds.size)
		guard rendered.width > 0, rendered.height > 0 else { return 1 }
		return min(output.width / rendered.width, output.height / rendered.height)
	}
	public init(presentation: PresentationSnapshot, orientation: ExternalDisplayOrientation, mirroredSource: PresentationSnapshot? = nil) { self.presentation = presentation; self.orientation = orientation; self.mirroredSource = mirroredSource }
}

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import Combine
#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Environment value for the user-selected rotation of Device-managed output content.
/// Display hardware orientation remains separate from this per-presentation choice.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
struct ExternalPresentationOrientationKey: EnvironmentKey {
	static let defaultValue: ExternalDisplayOrientation? = nil
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension EnvironmentValues {
	var externalPresentationOrientation: ExternalDisplayOrientation? {
		get { self[ExternalPresentationOrientationKey.self] }
		set { self[ExternalPresentationOrientationKey.self] = newValue }
	}
}

/// Device's presentation-keyed successor to KuditFrameworks.ExternalDisplayManager.
/// Qualify Device.ExternalDisplayManager while both libraries export the old name.
/// Setup is idempotent. Teardown removes only this manager's windows and observers.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
public final class ExternalDisplayManager: ObservableObject {
	public static let shared = ExternalDisplayManager()
	@Published private var rotations: [String: ExternalDisplayOrientation] = [:]
	@Published public private(set) var presentationIDs: [String] = []
	private var builder: ((ExternalPresentationContext) -> AnyView)?
	private var ownedPresentationIDs: [String] = []
	private var nativePresentationIDs: [UUID: String] = [:]
	private var observers: [NSObjectProtocol] = []
	#if canImport(UIKit) && !os(watchOS)
	private var windows: [String: UIWindow] = [:]
	#elseif canImport(AppKit)
	private var windows: [String: NSWindow] = [:]
	#endif
	public var displayConnected: Bool { !presentationIDs.isEmpty }
	public init() {}
	deinit { for observer in observers { NotificationCenter.default.removeObserver(observer) } }
	/// Installs legacy scene-window presentation, including displays connected before setup.
	public static func setup<Content: View>(@ViewBuilder _ content: @escaping (ExternalPresentationContext) -> Content) {
		shared.install { AnyView(content($0)) }
	}
	/// Source-compatible builder for content that does not need output identity.
	public static func setup<Content: View>(@ViewBuilder _ content: @escaping () -> Content) { setup { _ in content() } }
	public func orientation(for id: String) -> ExternalDisplayOrientation { rotations[id] ?? .upright }
	public func setOrientation(_ value: ExternalDisplayOrientation, for id: String) { rotations[id] = value }
	public func stop() {
		for observer in observers { NotificationCenter.default.removeObserver(observer) }; observers.removeAll()
		#if canImport(UIKit) && !os(watchOS)
		for window in windows.values { window.isHidden = true }; windows.removeAll()
		#elseif canImport(AppKit)
		for window in windows.values { window.close() }; windows.removeAll()
		#endif
		ownedPresentationIDs = []; builder = nil; rebuildPresentationIDs()
	}
	private func install(_ builder: @escaping (ExternalPresentationContext) -> AnyView) {
		self.builder = builder
		if observers.isEmpty {
			let names: [Notification.Name]
			#if canImport(UIKit) && !os(watchOS)
			var events = [UIScene.willConnectNotification, UIScene.didDisconnectNotification, UIScene.didActivateNotification]
			#if !os(visionOS)
			// Output mode/disconnection events can require reconciling existing scene windows.
			events += [UIScreen.didConnectNotification, UIScreen.didDisconnectNotification, UIScreen.modeDidChangeNotification]
			#endif
			names = events
			#elseif canImport(AppKit)
			names = [NSApplication.didChangeScreenParametersNotification]
			#else
			names = []
			#endif
			for name in names {
				observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
					guard let owner = self else { return }
					main { owner.reconcile() }
				})
			}
		}
		reconcile()
	}
	private func reconcile() {
		guard builder != nil else { return }
		var valid = Set<String>()
		#if canImport(UIKit) && !os(watchOS) && !os(visionOS)
		for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }) {
			let role = scene.session.role
			var external = role == .windowExternalDisplay
			if #available(iOS 16, tvOS 16, *) { external = external || role == .windowExternalDisplayNonInteractive }
			guard external else { continue }
			let key = scene.session.persistentIdentifier; valid.insert(key)
			if windows[key] == nil {
				let window = UIWindow(windowScene: scene)
				window.rootViewController = UIHostingController(rootView: ExternalPresentationRoot(manager: self))
				windows[key] = window; window.isHidden = false
			}
		}
		for key in Array(windows.keys) where !valid.contains(key) { windows.removeValue(forKey: key)?.isHidden = true }
		#elseif canImport(AppKit)
		// An output window becoming key must not turn the app's internal window into an external output.
		let owned = Set(windows.values.map(ObjectIdentifier.init))
		let primary = NSApp?.windows.first(where: { $0.isVisible && !owned.contains(ObjectIdentifier($0)) })?.screen ?? NSScreen.screens.first
		for screen in NSScreen.screens where screen != primary {
			let key = DisplayMonitor.shared.snapshot(for: screen).id; valid.insert(key)
			if windows[key] == nil {
				let window = NSWindow(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false, screen: screen)
				window.isReleasedWhenClosed = false
				window.contentView = NSHostingView(rootView: ExternalPresentationRoot(manager: self))
				windows[key] = window; window.orderFront(nil)
			}
			if windows[key]?.frame != screen.frame { windows[key]?.setFrame(screen.frame, display: true) }
		}
		for key in Array(windows.keys) where !valid.contains(key) { windows.removeValue(forKey: key)?.close() }
		#endif
		#if canImport(UIKit) && !os(watchOS)
		let ids = windows.values.map { DisplayMonitor.shared.presentation(for: $0).id }.sorted()
		#elseif canImport(AppKit)
		let ids = windows.values.compactMap { DisplayMonitor.shared.presentation(for: $0)?.id }.sorted()
		#else
		let ids: [String] = []
		#endif
		ownedPresentationIDs = ids
		rebuildPresentationIDs()
		DisplayMonitor.shared.start(); DisplayMonitor.shared.refresh()
	}
	/// Tracks OS-owned scene-accessory content without retaining its window.
	func registerNativePresentation(_ id: String?, owner: UUID) {
		nativePresentationIDs[owner] = id
		rebuildPresentationIDs()
	}
	private func rebuildPresentationIDs() {
		let next = Array(Set(ownedPresentationIDs + Array(nativePresentationIDs.values))).sorted()
		if presentationIDs != next { presentationIDs = next }
		let retained = rotations.filter { next.contains($0.key) }
		if rotations != retained { rotations = retained }
	}
	fileprivate func makeContent(_ context: ExternalPresentationContext) -> AnyView { builder?(context) ?? AnyView(EmptyView()) }
	public func orientationPicker(for presentationID: String) -> some View {
		Picker("External Display Rotation", selection: Binding(get: { self.orientation(for: presentationID) }, set: { self.setOrientation($0, for: presentationID) })) {
			ForEach(ExternalDisplayOrientation.allCases) { value in Text(value.description).tag(value) }
		}
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct ExternalPresentationRoot: View {
	@ObservedObject var manager: ExternalDisplayManager
	var builder: ((ExternalPresentationContext) -> AnyView)?
	var body: some View { ExternalResolvedContent(manager: manager, builder: builder).deviceDisplayContext() }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct ExternalResolvedContent: View {
	@Environment(\.presentation) private var presentation
	@ObservedObject var manager: ExternalDisplayManager
	var builder: ((ExternalPresentationContext) -> AnyView)?
	@State private var registrationOwner = UUID()
	var body: some View {
		GeometryReader { geometry in
			if let presentation {
				let rotation = manager.orientation(for: presentation.id)
				let source = presentation.display.mirroredDisplayID.flatMap { sourceID in DisplayMonitor.shared.presentations.first { $0.display.id == sourceID } }
				let context = ExternalPresentationContext(presentation: presentation, orientation: rotation, mirroredSource: source)
				let bounds = context.contentBounds.size
				let scale = source == nil ? 1 : CGFloat(context.scaleToFit(in: .init(width: Double(geometry.size.width), height: Double(geometry.size.height))))
				(builder?(context) ?? manager.makeContent(context))
					.environment(\.externalPresentationOrientation, rotation)
					.frame(width: source == nil ? (rotation.rotated ? geometry.size.height : geometry.size.width) : CGFloat(bounds.width), height: source == nil ? (rotation.rotated ? geometry.size.width : geometry.size.height) : CGFloat(bounds.height))
					.scaleEffect(scale)
					.rotationEffect(.degrees(rotation.degrees))
					.position(x: geometry.size.width / 2, y: geometry.size.height / 2)
			} else { Text("Waiting for external window") }
		}.edgesIgnoringSafeArea(.all)
		.onAppear { if builder != nil { manager.registerNativePresentation(presentation?.id, owner: registrationOwner) } }
		.backport.onChange(of: presentation?.id) { _, new in if builder != nil { manager.registerNativePresentation(new, owner: registrationOwner) } }
		.onDisappear { if builder != nil { manager.registerNativePresentation(nil, owner: registrationOwner) } }
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension View {
	/// Native scene accessory on verified new SDKs, legacy presentation windows otherwise.
	@ViewBuilder
	func deviceExternalPresentation<External: View>(isEnabled: Binding<Bool> = .constant(true), @ViewBuilder content: @escaping (ExternalPresentationContext) -> External) -> some View {
		#if os(iOS) && !targetEnvironment(macCatalyst) && !DEVICE_DISABLE_DUO_SDK && (DEVICE_HAS_DUO_SDK || canImport(SwiftUI, _version: 8.0.85.29))
		if #available(iOS 27, *) {
			self.sceneAccessory {
				ExternalNonInteractiveAccessory(isEnabled: isEnabled) {
					ExternalPresentationRoot(manager: .shared, builder: { AnyView(content($0)) })
				}
			}
		} else { self.onAppear { if isEnabled.wrappedValue { ExternalDisplayManager.setup(content) } }
			.backport.onChange(of: isEnabled.wrappedValue) { _, enabled in
				if enabled { ExternalDisplayManager.setup(content) } else { ExternalDisplayManager.shared.stop() }
			} }
		#else
		self.onAppear { if isEnabled.wrappedValue { ExternalDisplayManager.setup(content) } }
			.backport.onChange(of: isEnabled.wrappedValue) { _, enabled in
				if enabled { ExternalDisplayManager.setup(content) } else { ExternalDisplayManager.shared.stop() }
			}
		#endif
	}
}

/// Distinct output diagnostics and per-presentation poster-TV rotation control.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct ExternalDisplayDiagnosticsView: View {
	public let context: ExternalPresentationContext
	public init(context: ExternalPresentationContext) { self.context = context }
	public var body: some View {
		VStack {
			Text("External presentation").font(.headline)
			ScreenInfoView(presentation: context.presentation)
			Text("Rotated content: \(context.contentBounds.size.width) × \(context.contentBounds.size.height) points")
			ExternalDisplayManager.shared.orientationPicker(for: context.presentation.id)
		}.padding()
	}
}
#endif
