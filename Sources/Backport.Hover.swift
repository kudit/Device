#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI
import Compatibility

public enum BackportHoverPhase: Equatable { case active(CGPoint), ended }
public enum BackportHoverEffect: Sendable { case automatic, highlight, lift }
/// Native grouping is retained by carrying the real SwiftUI namespace, not by inventing a global group ID.
public struct BackportHoverEffectGroup {
	public enum Behavior { case activatesGroup, followsGroup, ignoresGroup, preservesGroup }
	private let namespaceStorage: Any
	private let id: String?
	private let behavior: Behavior
	@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
	public init(_ namespace: Namespace.ID, behavior: Behavior = .activatesGroup) { self.init(id: nil, in: namespace, behavior: behavior) }
	@available(iOS 14, macOS 11, tvOS 14, watchOS 7, *)
	public init(id: String?, in namespace: Namespace.ID, behavior: Behavior = .activatesGroup) {
		namespaceStorage = namespace; self.id = id; self.behavior = behavior
	}
	#if os(visionOS)
	@available(visionOS 2, *)
	var native: SwiftUI.HoverEffectGroup? {
		guard let namespace = namespaceStorage as? Namespace.ID else { return nil }
		var nativeBehavior: SwiftUI.HoverEffectGroup.Behavior = .activatesGroup
		switch behavior {
		case .activatesGroup: break
		case .followsGroup: nativeBehavior = .followsGroup
		case .ignoresGroup: nativeBehavior = .ignoresGroup
		case .preservesGroup: if #available(visionOS 26, *) { nativeBehavior = .preservesGroup }
		}
		return .init(id: id, in: namespace, behavior: nativeBehavior)
	}
	#endif
}

/// Supported transform values form a real effect description, not a placeholder conformance.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct BackportHoverTransform {
	public var opacity: Double = 1
	public var scale: CGSize = .init(width: 1, height: 1)
	public var anchor: UnitPoint = .center
	public var offset: CGSize = .zero
	public init() {}
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public protocol BackportHoverEffectContent { var transform: BackportHoverTransform { get } }
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct BackportEmptyHoverEffectContent: BackportHoverEffectContent {
	public let transform = BackportHoverTransform()
	public init() {}
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct BackportResolvedHoverEffectContent: BackportHoverEffectContent {
	public var transform: BackportHoverTransform
	public init(transform: BackportHoverTransform) { self.transform = transform }
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension BackportHoverEffectContent {
	func opacity(_ opacity: Double) -> BackportResolvedHoverEffectContent {
		var value = transform; value.opacity *= opacity; return .init(transform: value)
	}
	func scaleEffect(_ scale: CGFloat, anchor: UnitPoint = .center) -> BackportResolvedHoverEffectContent { scaleEffect(x: scale, y: scale, anchor: anchor) }
	func scaleEffect(_ scale: CGSize, anchor: UnitPoint = .center) -> BackportResolvedHoverEffectContent { scaleEffect(x: scale.width, y: scale.height, anchor: anchor) }
	func scaleEffect(x: CGFloat = 1, y: CGFloat = 1, anchor: UnitPoint = .center) -> BackportResolvedHoverEffectContent {
		var value = transform; value.scale.width *= x; value.scale.height *= y; value.anchor = anchor; return .init(transform: value)
	}
	func offset(x: CGFloat = 0, y: CGFloat = 0) -> BackportResolvedHoverEffectContent {
		var value = transform; value.offset.width += x; value.offset.height += y; return .init(transform: value)
	}
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public protocol BackportCustomHoverEffect {
	associatedtype Body: BackportCustomHoverEffect
	typealias Content = BackportEmptyHoverEffect
	func body(content: Content) -> Body
	func resolve(isActive: Bool, geometry: GeometryProxy) -> BackportHoverTransform
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension BackportCustomHoverEffect {
	func resolve(isActive: Bool, geometry: GeometryProxy) -> BackportHoverTransform { body(content: .init()).resolve(isActive: isActive, geometry: geometry) }
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct BackportEmptyHoverEffect: BackportCustomHoverEffect {
	public init() {}
	public func body(content: Self) -> Self { self }
	public func resolve(isActive: Bool, geometry: GeometryProxy) -> BackportHoverTransform { .init() }
	public func hoverEffect<E: BackportHoverEffectContent>(in group: BackportHoverEffectGroup? = nil, isEnabled: Bool = true,
		body: @escaping (BackportEmptyHoverEffectContent, Bool, GeometryProxy) -> E) -> BackportContentHoverEffect {
		.init { active, geometry in body(.init(), active && isEnabled, geometry).transform }
	}
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct BackportContentHoverEffect: BackportCustomHoverEffect {
	let resolver: (Bool, GeometryProxy) -> BackportHoverTransform
	public init(_ resolver: @escaping (Bool, GeometryProxy) -> BackportHoverTransform) { self.resolver = resolver }
	public func body(content: BackportEmptyHoverEffect) -> Self { self }
	public func resolve(isActive: Bool, geometry: GeometryProxy) -> BackportHoverTransform { resolver(isActive, geometry) }
}
public extension Backport where Content == Any {
	typealias HoverPhase = BackportHoverPhase
	typealias HoverEffect = BackportHoverEffect
	typealias HoverEffectGroup = BackportHoverEffectGroup
	@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
	typealias HoverEffectContent = BackportHoverEffectContent
	@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
	typealias EmptyHoverEffectContent = BackportEmptyHoverEffectContent
	@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) typealias CustomHoverEffect = BackportCustomHoverEffect
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
	func onHover(perform action: @escaping (Bool) -> Void) -> some View {
		#if os(macOS) && canImport(AppKit)
		content.background(LegacyHoverProbe { phase in
			if case .active = phase { action(true) } else { action(false) }
		})
		#elseif os(iOS) && canImport(UIKit)
		// UIKit's hover recognizer provides the same pointer signal on iOS 13.4+
		// without putting an iOS 13.4 API branch inside ViewBuilder.
		content.background(LegacyHoverProbe { phase in
			if case .active = phase { action(true) } else { action(false) }
		})
		#elseif os(visionOS)
		visionOSOnHover(action)
		#else
		content
		#endif
	}
	#if os(visionOS)
	@ViewBuilder
	private func visionOSOnHover(_ action: @escaping (Bool) -> Void) -> some View {
		if #available(visionOS 1, *) {
			content.onHover(perform: action)
		} else {
			content
		}
	}
	#endif
	@ViewBuilder
	func onContinuousHover(coordinateSpace: CoordinateSpace = .local, perform action: @escaping (BackportHoverPhase) -> Void) -> some View {
		#if !os(watchOS)
		if #available(iOS 16, macOS 13, tvOS 16, *) {
			content.onContinuousHover(coordinateSpace: coordinateSpace) { phase in
				switch phase { case .active(let point): action(.active(point)); case .ended: action(.ended) }
			}
		} else {
			content.background(LegacyHoverProbe(action: action))
		}
		#else
		content
		#endif
	}
	/// Native system highlight/lift when present; no fake hover event elsewhere.
	@ViewBuilder
	func hoverEffect(_ effect: BackportHoverEffect = .automatic, isEnabled: Bool = true) -> some View {
		#if os(iOS) || os(tvOS) || os(visionOS)
		if #available(iOS 14, tvOS 17, visionOS 1, *), isEnabled {
			content.hoverEffect(effect == .lift ? .lift : effect == .highlight ? .highlight : .automatic)
		} else {
			content
		}
		#else
		content
		#endif
	}
	func hoverEffect<E: BackportCustomHoverEffect>(_ effect: E, in group: BackportHoverEffectGroup? = nil, isEnabled: Bool = true) -> some View {
		content.modifier(BackportCustomHoverModifier(effect: effect, group: group, isEnabled: isEnabled))
	}
	func hoverEffect<E: BackportHoverEffectContent>(in group: BackportHoverEffectGroup? = nil, isEnabled: Bool = true,
		body: @escaping (BackportEmptyHoverEffectContent, Bool, GeometryProxy) -> E) -> some View {
		hoverEffect(BackportContentHoverEffect { active, geometry in body(.init(), active, geometry).transform }, in: group, isEnabled: isEnabled)
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct BackportCustomHoverModifier<E: BackportCustomHoverEffect>: ViewModifier {
	let effect: E
	let group: BackportHoverEffectGroup?
	let isEnabled: Bool
	@State private var hovering = false
	@State private var transform = BackportHoverTransform()
	func body(content: Content) -> some View {
		#if os(visionOS)
		visionOSContent(content)
		#else
		// In-process pointer fallback. This does not pretend to reproduce visionOS gaze effects.
		content.opacity(transform.opacity).scaleEffect(transform.scale, anchor: transform.anchor).offset(transform.offset)
			.background(GeometryReader { geometry in
				Color.clear.onAppear { hovering = false; transform = effect.resolve(isActive: false, geometry: geometry) }
					.onDisappear { hovering = false; transform = effect.resolve(isActive: false, geometry: geometry) }
					.backport.onHover { active in hovering = active; transform = effect.resolve(isActive: active && isEnabled, geometry: geometry) }
					.backport.onChange(of: isEnabled) { _, enabled in transform = effect.resolve(isActive: hovering && enabled, geometry: geometry) }
			})
		#endif
	}
	#if os(visionOS)
	/// Keeps the visionOS-only native effect inside a typed availability branch.
	@ViewBuilder
	private func visionOSContent(_ content: Content) -> some View {
		if #available(visionOS 2, *) {
			content.hoverEffect(in: group?.native, isEnabled: isEnabled) { native, active, geometry in
				let value = effect.resolve(isActive: active, geometry: geometry)
				return native.opacity(value.opacity).scaleEffect(value.scale, anchor: value.anchor).offset(value.offset)
			}
		} else {
			content.opacity(transform.opacity).scaleEffect(transform.scale, anchor: transform.anchor).offset(transform.offset)
		}
	}
	#endif
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
@available(macOS 10.15, *)
private struct LegacyHoverProbe: NSViewRepresentable {
	let action: (BackportHoverPhase) -> Void
	func makeNSView(context: Context) -> Probe { Probe() }
	func updateNSView(_ view: Probe, context: Context) { view.action = action }
	static func dismantleNSView(_ view: Probe, coordinator: ()) { view.action = nil; for area in view.trackingAreas { view.removeTrackingArea(area) } }
	final class Probe: NSView {
		var action: ((BackportHoverPhase) -> Void)?
		override var isFlipped: Bool { true }
		override func updateTrackingAreas() {
			super.updateTrackingAreas(); for area in trackingAreas { removeTrackingArea(area) }
			addTrackingArea(NSTrackingArea(rect: .zero, options: [.activeInKeyWindow, .inVisibleRect, .mouseEnteredAndExited, .mouseMoved], owner: self))
		}
		override func mouseEntered(with event: NSEvent) { action?(.active(convert(event.locationInWindow, from: nil))) }
		override func mouseMoved(with event: NSEvent) { action?(.active(convert(event.locationInWindow, from: nil))) }
		override func mouseExited(with event: NSEvent) { action?(.ended) }
	}
}
#elseif canImport(UIKit) && !os(watchOS) && !os(tvOS)
import UIKit
@available(iOS 13, tvOS 13, *)
private struct LegacyHoverProbe: UIViewRepresentable {
	let action: (BackportHoverPhase) -> Void
	func makeUIView(context: Context) -> Probe { Probe() }
	func updateUIView(_ view: Probe, context: Context) { view.action = action }
	static func dismantleUIView(_ view: Probe, coordinator: ()) { view.action = nil; for gesture in view.gestureRecognizers ?? [] { view.removeGestureRecognizer(gesture) } }
	final class Probe: UIView {
		var action: ((BackportHoverPhase) -> Void)?
		override init(frame: CGRect) {
			super.init(frame: frame)
			if #available(iOS 13.4, *) {
				addGestureRecognizer(UIHoverGestureRecognizer(target: self, action: #selector(hover(_:))))
			}
		}
		required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }
		@available(iOS 13.4, *)
		@objc private func hover(_ recognizer: UIHoverGestureRecognizer) {
			if recognizer.state == .began || recognizer.state == .changed { action?(.active(recognizer.location(in: self))) } else { action?(.ended) }
		}
	}
}
#else
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct LegacyHoverProbe: View {
	let action: (BackportHoverPhase) -> Void
	var body: some View { Color.clear }
}
#endif
#endif
