import Compatibility

#if canImport(SwiftUI)
import SwiftUI
/// Use SwiftUI's native type directly so both APIs are interchangeable.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public typealias UnitPoint = SwiftUI.UnitPoint
#else
/// Normalized, platform-neutral point for APIs that cannot import SwiftUI.
public struct UnitPoint: Hashable, Codable, Sendable {
	public var x: Double
	public var y: Double

	public init(x: Double, y: Double) {
		self.x = x
		self.y = y
	}

	public static let zero = Self(x: 0, y: 0)
	public static let center = Self(x: 0.5, y: 0.5)
	public static let top = Self(x: 0.5, y: 0)
	public static let bottom = Self(x: 0.5, y: 1)
	public static let leading = Self(x: 0, y: 0.5)
	public static let trailing = Self(x: 1, y: 0.5)
	public static let topLeading = Self(x: 0, y: 0)
	public static let topTrailing = Self(x: 1, y: 0)
	public static let bottomLeading = Self(x: 0, y: 1)
	public static let bottomTrailing = Self(x: 1, y: 1)
}
#endif

#if canImport(SwiftUI)

/// Backports view APIs while preserving modern SwiftUI behavior when available.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
	/// Font styles supplied by this package when an older system lacks them.
	enum BackportFontStyle: Sendable {
		case caption2
	}

	/// Applies the compact caption style where available and falls back to caption.
	@ViewBuilder
	func font(_ style: BackportFontStyle) -> some View {
		switch style {
		case .caption2:
			if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, macCatalyst 14, *) {
				content.font(.caption2)
			} else {
				content.font(.caption)
			}
		}
	}

	/// Animates changes when `value` changes. Older SwiftUI uses its unscoped modifier.
	@ViewBuilder
	func animation<Value: Equatable>(_ animation: Animation?, value: Value) -> some View {
		if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
			content.animation(animation, value: value)
		} else {
			content.animation(animation)
		}
	}
}

/// Uses SwiftUI's native Label where available and a private HStack fallback earlier.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content == Any {
	typealias UnitPoint = SwiftUI.UnitPoint

	/// Uses native Label where available and a small HStack fallback on older systems.
	static func Label<Title: View, Icon: View>(
		@ViewBuilder title: () -> Title,
		@ViewBuilder icon: () -> Icon
	) -> some View {
		BackportLabelView(title: title(), icon: icon())
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct BackportLabelView<Title: View, Icon: View>: View {
	let title: Title
	let icon: Icon

	@ViewBuilder
	var body: some View {
		if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, macCatalyst 14, *) {
			SwiftUI.Label(title: { title }, icon: { icon })
		} else {
			LegacyLabel(title: title, icon: icon)
		}
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct LegacyLabel<Title: View, Icon: View>: View {
	let title: Title
	let icon: Icon

	var body: some View {
		HStack(spacing: 6) {
			icon
			title
		}
		.accessibilityElement(children: .combine)
	}
}
#endif
