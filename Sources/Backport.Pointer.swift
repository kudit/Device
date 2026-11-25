import Compatibility

public enum BackportHorizontalDirection: Int8, Sendable {
	case leading, trailing
	public struct Set: OptionSet, Sendable {
		public let rawValue: Int8
		public init(rawValue: Int8) { self.rawValue = rawValue }
		public static let leading = Self(rawValue: 1), trailing = Self(rawValue: 2), all: Self = [.leading, .trailing]
		public init(_ value: BackportHorizontalDirection) { self = value == .leading ? .leading : .trailing }
	}
}
public enum BackportVerticalDirection: Int8, Sendable {
	case up, down
	public struct Set: OptionSet, Sendable {
		public let rawValue: Int8
		public init(rawValue: Int8) { self.rawValue = rawValue }
		public static let up = Self(rawValue: 1), down = Self(rawValue: 2), all: Self = [.up, .down]
		public init(_ value: BackportVerticalDirection) { self = value == .up ? .up : .down }
	}
}
public enum BackportFrameResizePosition: Int8, CaseIterable, Sendable { case top, leading, bottom, trailing, topLeading, topTrailing, bottomLeading, bottomTrailing }
public enum BackportFrameResizeDirection: Int8, Sendable {
	case inward, outward
	public struct Set: OptionSet, Sendable {
		public let rawValue: Int8
		public init(rawValue: Int8) { self.rawValue = rawValue }
		public static let inward = Self(rawValue: 1), outward = Self(rawValue: 2), all: Self = [.inward, .outward]
		public init(_ value: BackportFrameResizeDirection) { self = value == .inward ? .inward : .outward }
	}
}

/// Carries either a portable name or an immutable native PointerStyle. Erasure keeps
/// the stored layout loadable before the native type exists; no view/window is retained.
public struct BackportPointerStyle: @unchecked Sendable {
	private let name: String
	private let nativeStorage: Any?
	private init(_ name: String, native: Any? = nil) { self.name = name; nativeStorage = native }
	public static let `default` = Self("default"), horizontalText = Self("horizontalText"), verticalText = Self("verticalText"), rectSelection = Self("rectSelection"), grabIdle = Self("grabIdle"), grabActive = Self("grabActive"), link = Self("link"), zoomIn = Self("zoomIn"), zoomOut = Self("zoomOut"), columnResize = Self("columnResize"), rowResize = Self("rowResize")
}
public enum BackportHandPointerBehavior: Sendable { case inactive, drawing }
#if canImport(SwiftUI) && compiler(>=5.9)
// Compatibility only defines its generic Backport wrapper when SwiftUI is available.
import SwiftUI
public extension Backport where Content == Any {
	typealias PointerStyle = BackportPointerStyle
	typealias HandPointerBehavior = BackportHandPointerBehavior
	typealias HorizontalDirection = BackportHorizontalDirection
	typealias VerticalDirection = BackportVerticalDirection
	typealias FrameResizePosition = BackportFrameResizePosition
	typealias FrameResizeDirection = BackportFrameResizeDirection
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension BackportPointerStyle {
	static func columnResize(directions: BackportHorizontalDirection.Set) -> Self {
		#if os(macOS)
		if #available(macOS 15, *) {
			var native: SwiftUI.HorizontalDirection.Set = []
			if directions.contains(.leading) { native.insert(.leading) }; if directions.contains(.trailing) { native.insert(.trailing) }
			return Self("columnResize", native: SwiftUI.PointerStyle.columnResize(directions: native))
		}
		#endif
		return .columnResize
	}
	static func rowResize(directions: BackportVerticalDirection.Set) -> Self {
		#if os(macOS)
		if #available(macOS 15, *) {
			var native: SwiftUI.VerticalDirection.Set = []
			if directions.contains(.up) { native.insert(.up) }; if directions.contains(.down) { native.insert(.down) }
			return Self("rowResize", native: SwiftUI.PointerStyle.rowResize(directions: native))
		}
		#endif
		return .rowResize
	}
	static func frameResize(position: BackportFrameResizePosition, directions: BackportFrameResizeDirection.Set = .all) -> Self {
		#if os(macOS)
		if #available(macOS 15, *), let position = SwiftUI.FrameResizePosition(rawValue: position.rawValue) {
			var native: SwiftUI.FrameResizeDirection.Set = []
			if directions.contains(.inward) { native.insert(.inward) }; if directions.contains(.outward) { native.insert(.outward) }
			return Self("frameResize", native: SwiftUI.PointerStyle.frameResize(position: position, directions: native))
		}
		#endif
		return .default
	}
	static func image(_ image: SwiftUI.Image, hotSpot: UnitPoint) -> Self {
		#if os(macOS)
		if #available(macOS 15, *) { return Self("image", native: SwiftUI.PointerStyle.image(image, hotSpot: hotSpot)) }
		#endif
		return .default
	}
	static func shape<S: Shape>(_ shape: S, eoFill: Bool = false, size: CGSize) -> Self {
		#if os(visionOS)
		if #available(visionOS 2, *) { return Self("shape", native: SwiftUI.PointerStyle.shape(shape, eoFill: eoFill, size: size)) }
		#endif
		return .default
	}
}
#if os(macOS) || os(visionOS)
@available(macOS 15, visionOS 2, *)
private extension BackportPointerStyle {
	var native: SwiftUI.PointerStyle? {
		if let stored = nativeStorage as? SwiftUI.PointerStyle { return stored }
		#if os(macOS)
		switch name {
		case "horizontalText": return .horizontalText; case "verticalText": return .verticalText; case "rectSelection": return .rectSelection
		case "grabIdle": return .grabIdle; case "grabActive": return .grabActive; case "link": return .link
		case "zoomIn": return .zoomIn; case "zoomOut": return .zoomOut; case "columnResize": return .columnResize; case "rowResize": return .rowResize
		default: return .default
		}
		#else
		return name == "default" ? .default : nil
		#endif
	}
}
#endif
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
	/// Native pointer styling where supported; unchanged system pointer elsewhere.
	@ViewBuilder func pointerStyle(_ style: BackportPointerStyle?) -> some View {
		#if os(macOS)
		if #available(macOS 15, *) { content.pointerStyle(style?.native) } else { content }
		#elseif os(visionOS)
		if #available(visionOS 2, *) { content.pointerStyle(style?.native) } else { content }
		#else
		content
		#endif
	}
	@ViewBuilder func handPointerBehavior(_ behavior: BackportHandPointerBehavior?) -> some View {
		#if os(visionOS)
		if #available(visionOS 2, *) { content.handPointerBehavior(behavior.map { $0 == .drawing ? .drawing : .inactive }) } else { content }
		#else
		content
		#endif
	}
}
#endif
