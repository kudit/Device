#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
import Compatibility
#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct ActiveDisplayKey: EnvironmentKey { static let defaultValue: Screen? = nil }
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct PresentationKey: EnvironmentKey { static let defaultValue: PresentationSnapshot? = nil }
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct WindowPlacementKey: EnvironmentKey { static let defaultValue: PresentationSnapshot.WindowPlacement = .unknown }

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension EnvironmentValues {
	/// Fixed hardware specification for the output hosting this view, if it is a built-in panel.
	var activeDisplay: Screen? {
		get { self[ActiveDisplayKey.self] }
		set { self[ActiveDisplayKey.self] = newValue }
	}
	/// Hosting window plus geometry measured at the nearest deviceDisplayContext root.
	var presentation: PresentationSnapshot? {
		get { self[PresentationKey.self] }
		set { self[PresentationKey.self] = newValue }
	}
	/// Position of this window relative to a fold division, when SwiftUI reports one.
	var windowPlacement: PresentationSnapshot.WindowPlacement {
		get { self[WindowPlacementKey.self] }
		set { self[WindowPlacementKey.self] = newValue }
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension View {
	/// Measures the owning window in a background without consuming layout space.
	func deviceDisplayContext() -> some View { modifier(DeviceDisplayContext()) }
	/// Installs a frozen capture or explicit fixture. No live discovery is started.
	func deviceDisplayContext(presentation: PresentationSnapshot) -> some View {
		environment(\.presentation, presentation).environment(\.activeDisplay, presentation.screen)
			.environment(\.windowPlacement, presentation.windowPlacement)
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct DeviceDisplayContext: ViewModifier {
	@State private var snapshot: PresentationSnapshot?
	@State private var hinge: Device.Hinge?
	@State private var reserved: [PresentationSnapshot.ReservedRegion] = []
	@State private var regionBounds: DisplayRect?
	func body(content: Content) -> some View {
		content.environment(\.activeDisplay, snapshot?.screen).environment(\.presentation, snapshot)
			.environment(\.windowPlacement, snapshot?.windowPlacement ?? .unknown)
			.background(WindowContextResolver(hinge: hinge, reserved: reserved, regionBounds: regionBounds) { value in
				if let old = snapshot, let value, old.hasSameMeasurements(as: value) { return }
				if snapshot != value { snapshot = value }
			})
			.background(GeometryReader { geometry in
				Color.clear.preference(key: DisplayRegionsKey.self, value: regions(in: geometry))
			})
			.onPreferenceChange(DisplayRegionsKey.self) { value in reserved = value.regions; regionBounds = value.bounds }
			.backport.onHingeChange { _, new in hinge = new.hinge }
			.onAppear { DisplayMonitor.shared.start() }
	}
	private func regions(in geometry: GeometryProxy) -> DisplayRegionsSnapshot {
		let size = geometry.size
		let localBounds = DisplayRect(width: Double(size.width), height: Double(size.height), space: .localView)
		#if os(iOS) && !targetEnvironment(macCatalyst) && !DEVICE_DISABLE_DUO_SDK && (DEVICE_HAS_DUO_SDK || canImport(SwiftUI, _version: 8.0.85.29))
		if #available(iOS 27.1, macOS 27.1, tvOS 27.1, watchOS 27.1, visionOS 27.1, *) {
			// Keep bounds and reserved frames from this same proxy. The app-view
			// probe is a sibling background and can have a different size.
			let divisions = geometry.reservedRegions(kind: .division, options: [.includeInactive], layoutDirectionBehavior: .fixed)
			let occlusions = geometry.reservedRegions(kind: .occlusion, options: [.includeInactive], layoutDirectionBehavior: .fixed)
			let regions = divisions.map { region in
				.init(id: String(describing: region.id), kind: .division, bounds: .init(region.frame, space: .localView))
			} + occlusions.map { region in
				PresentationSnapshot.ReservedRegion(id: String(describing: region.id), kind: .occlusion, bounds: DisplayRect(region.frame, space: .localView))
			}
			return .init(bounds: localBounds, regions: regions)
		}
		#endif
		return .init(bounds: localBounds)
	}
}

private struct DisplayRegionsSnapshot: Equatable {
	var bounds: DisplayRect?
	var regions: [PresentationSnapshot.ReservedRegion] = []
	init(bounds: DisplayRect? = nil, regions: [PresentationSnapshot.ReservedRegion] = []) { self.bounds = bounds; self.regions = regions }
}

private struct DisplayRegionsKey: PreferenceKey {
	static var defaultValue = DisplayRegionsSnapshot()
	static func reduce(value: inout DisplayRegionsSnapshot, nextValue: () -> DisplayRegionsSnapshot) { value = nextValue() }
}

/// Applies local reserved regions without changing their coordinate-space identity.
private extension PresentationSnapshot {
	func withRegions(_ regions: [ReservedRegion], localBounds: DisplayRect?) -> Self {
		.init(id: id, capturedAt: capturedAt, display: display, windowBounds: windowBounds, windowFrame: windowFrame, localBounds: localBounds,
			safeArea: safeArea, activation: activation, interfaceOrientation: interfaceOrientation,
			horizontalSizeClass: horizontalSizeClass, verticalSizeClass: verticalSizeClass, reservedRegions: regions, hinge: hinge)
	}
}

#if canImport(UIKit) && !os(watchOS)
@available(iOS 13, tvOS 13, *)
private struct WindowContextResolver: UIViewRepresentable {
	let hinge: Device.Hinge?
	let reserved: [PresentationSnapshot.ReservedRegion]
	let regionBounds: DisplayRect?
	let changed: (PresentationSnapshot?) -> Void
	func makeUIView(context: Context) -> HostingProbe { HostingProbe() }
	func updateUIView(_ view: HostingProbe, context: Context) { view.hinge = hinge; view.reserved = reserved; view.regionBounds = regionBounds; view.changed = changed; view.measure() }
	static func dismantleUIView(_ view: HostingProbe, coordinator: ()) { view.changed = nil; view.stop() }
	final class HostingProbe: UIView {
		var hinge: Device.Hinge?
		var reserved: [PresentationSnapshot.ReservedRegion] = []
		var regionBounds: DisplayRect?
		var changed: ((PresentationSnapshot?) -> Void)?
		private var tokens: [NSObjectProtocol] = []
		private var pending = false
		init() {
			super.init(frame: .zero); isUserInteractionEnabled = false; backgroundColor = .clear
			for name in [UIScene.didActivateNotification, UIScene.willDeactivateNotification, UIScene.didEnterBackgroundNotification] {
				tokens.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
					guard let owner = self else { return }
					main { owner.measure() }
				})
			}
		}
		required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }
		override func didMoveToWindow() { super.didMoveToWindow(); measure() }
		override func layoutSubviews() { super.layoutSubviews(); measure() }
		override func safeAreaInsetsDidChange() { super.safeAreaInsetsDidChange(); measure() }
		func measure() {
			guard !pending else { return }; pending = true
			// Deferred state delivery avoids mutating SwiftUI state during its layout pass.
			DispatchQueue.main.async { [weak self] in
				guard let self else { return }; self.pending = false
				DisplayMonitor.shared.refresh()
				let value = self.window.map { window -> PresentationSnapshot in
					var regions = self.reserved
					var bounds = self.regionBounds
					// ScreenInfoView is often a small card inside a pane. Querying its
					// own geometry omits a fold that doesn't intersect the card, so
					// query the window's root view for placement instead.
					#if os(iOS) && !DEVICE_DISABLE_DUO_SDK && (DEVICE_HAS_DUO_SDK || canImport(SwiftUI, _version: 8.0.85.29))
					if #available(iOS 27.1, *), let rootView = window.rootViewController?.view {
						let divisionRegions = rootView.reservedRegions(kind: .division, options: [.includeInactive])
						regions = divisionRegions.map {
							.init(id: String(describing: $0.id), kind: .division, bounds: .init($0.frame, space: .localView))
						}
						bounds = .init(width: Double(rootView.bounds.width), height: Double(rootView.bounds.height), space: .localView)
					}
					#endif
					return DisplayMonitor.shared.presentation(for: window, localBounds: self.bounds, safeArea: self.safeAreaInsets, hinge: self.hinge)
						.withRegions(regions, localBounds: bounds)
				}
				self.changed?(value)
			}
		}
		func stop() { for token in tokens { NotificationCenter.default.removeObserver(token) }; tokens.removeAll() }
		deinit { for token in tokens { NotificationCenter.default.removeObserver(token) } }
	}
}
#elseif canImport(AppKit)
@available(macOS 10.15, *)
private struct WindowContextResolver: NSViewRepresentable {
	let hinge: Device.Hinge?
	let reserved: [PresentationSnapshot.ReservedRegion]
	let regionBounds: DisplayRect?
	let changed: (PresentationSnapshot?) -> Void
	func makeNSView(context: Context) -> HostingProbe { HostingProbe() }
	func updateNSView(_ view: HostingProbe, context: Context) { view.reserved = reserved; view.regionBounds = regionBounds; view.changed = changed; view.measure() }
	static func dismantleNSView(_ view: HostingProbe, coordinator: ()) { view.changed = nil; view.stop() }
	final class HostingProbe: NSView {
		var reserved: [PresentationSnapshot.ReservedRegion] = []
		var regionBounds: DisplayRect?
		var changed: ((PresentationSnapshot?) -> Void)?
		private var tokens: [NSObjectProtocol] = []
		private var pending = false
		override func viewDidMoveToWindow() {
			super.viewDidMoveToWindow(); stop()
			guard window != nil else { measure(); return }
			for name in [NSWindow.didResizeNotification, NSWindow.didMoveNotification, NSWindow.didChangeScreenNotification, NSWindow.didChangeBackingPropertiesNotification] {
				tokens.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
					guard let owner = self else { return }
					main { owner.measure() }
				})
			}
			measure()
		}
		override func layout() { super.layout(); measure() }
		func measure() {
			guard !pending else { return }; pending = true
			DispatchQueue.main.async { [weak self] in
				guard let self else { return }; self.pending = false
				DisplayMonitor.shared.refresh()
				var insets: DisplayInsets?
				if #available(macOS 11, *) { let s = self.safeAreaInsets; insets = .init(top: Double(s.top), leading: Double(s.left), bottom: Double(s.bottom), trailing: Double(s.right)) }
				let value = self.window.flatMap { DisplayMonitor.shared.presentation(for: $0, localBounds: self.bounds, safeArea: insets) }?.withRegions(self.reserved, localBounds: self.regionBounds)
				self.changed?(value)
			}
		}
		func stop() { for token in tokens { NotificationCenter.default.removeObserver(token) }; tokens.removeAll() }
		deinit { for token in tokens { NotificationCenter.default.removeObserver(token) } }
	}
}
#elseif os(watchOS)
@available(watchOS 6, *)
private struct WindowContextResolver: View {
	let hinge: Device.Hinge?
	let reserved: [PresentationSnapshot.ReservedRegion]
	let regionBounds: DisplayRect?
	let changed: (PresentationSnapshot?) -> Void
	var body: some View {
		GeometryReader { geometry in
			Color.clear.onAppear { emit(geometry) }
				.backport.onChange(of: geometry.size) { _, _ in emit(geometry) }
				.backport.onChange(of: geometry.safeAreaInsets) { _, _ in emit(geometry) }
		}
	}
	private func emit(_ geometry: GeometryProxy) {
		DisplayMonitor.shared.start()
		// watchOS exposes a single local output, but no public hosting-window bounds.
		guard let localDisplay = DisplayMonitor.shared.displays.first(where: { $0.id == "watch-local" }) else { changed(nil); return }
		changed(.init(id: "watch-local-presentation", display: localDisplay,
			localBounds: .init(width: Double(geometry.size.width), height: Double(geometry.size.height), space: .localView),
			safeArea: .init(top: Double(geometry.safeAreaInsets.top), leading: Double(geometry.safeAreaInsets.leading), bottom: Double(geometry.safeAreaInsets.bottom), trailing: Double(geometry.safeAreaInsets.trailing))))
	}
}
#else
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct WindowContextResolver: View {
	let hinge: Device.Hinge?
	let reserved: [PresentationSnapshot.ReservedRegion]
	let regionBounds: DisplayRect?
	let changed: (PresentationSnapshot?) -> Void
	var body: some View { Color.clear }
}
#endif
#endif
