import Compatibility
public enum BackportTouchBarItemPresence: Sendable {
	case `default`(String), required(String), optional(String)
}
#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI
public extension Backport where Content == Any { typealias TouchBarItemPresence = BackportTouchBarItemPresence }
/// A cross-platform TouchBar value retaining its customization identifier.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct BackportTouchBar<Bar: View> {
	let id: String?
	let content: Bar
	public init(@ViewBuilder content: () -> Bar) { id = nil; self.content = content() }
	public init(id: String, @ViewBuilder content: () -> Bar) { self.id = id; self.content = content() }
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content == Any { typealias TouchBar<Bar: View> = BackportTouchBar<Bar> }
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
	@ViewBuilder func touchBar<Bar: View>(_ bar: BackportTouchBar<Bar>) -> some View {
		#if os(macOS)
		if let id = bar.id { content.touchBar(SwiftUI.TouchBar(id: id) { bar.content }) }
		else { content.touchBar(SwiftUI.TouchBar { bar.content }) }
		#else
		content
		#endif
	}
	/// Native Touch Bar content on macOS; main content is preserved on other hardware.
	@ViewBuilder func touchBar<V: View>(@ViewBuilder content bar: () -> V) -> some View {
		#if os(macOS)
		content.touchBar(content: bar)
		#else
		content
		#endif
	}
	@ViewBuilder func touchBarItemPrincipal(_ principal: Bool = true) -> some View {
		#if os(macOS)
		content.touchBarItemPrincipal(principal)
		#else
		content
		#endif
	}
	@ViewBuilder func touchBarCustomizationLabel(_ label: Text) -> some View {
		#if os(macOS)
		content.touchBarCustomizationLabel(label)
		#else
		content
		#endif
	}
	@ViewBuilder func touchBarItemPresence(_ presence: BackportTouchBarItemPresence) -> some View {
		#if os(macOS)
		switch presence {
		case .default(let identifier): content.touchBarItemPresence(.default(identifier))
		case .required(let identifier): content.touchBarItemPresence(.required(identifier))
		case .optional(let identifier): content.touchBarItemPresence(.optional(identifier))
		}
		#else
		content
		#endif
	}
}
#endif
