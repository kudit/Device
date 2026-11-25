//
//  ViewExtensions.swift
//  Device
//
//  Created by Ben Ku on 5/14/25.
//

#if canImport(SwiftUI)
import SwiftUI
import Compatibility

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension View {
    func disableIdleTimer(_ disabled: Bool = true) -> some View {
        onAppear {
            main {
                Device.current.isIdleTimerDisabled = disabled // must be run on the main actor AFTER most of the UI is loaded (so do on a view onAppear and NOT during the app init)
            }
        }
    }
}


@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
	/// Picker styles with platform-specific SwiftUI availability handled by Device backports.
	enum BackportPickerStyle: Sendable {
		case segmented
	}
	/// Applies a segmented picker style where it exists; on watchOS, leaves the
	/// platform's native picker presentation unchanged.
	@ViewBuilder
	func pickerStyle(_ style: BackportPickerStyle) -> some View {
		switch style {
		case .segmented:
#if os(watchOS)
			content
#else
			content.pickerStyle(.segmented)
#endif
		}
	}

	/// Background styles with platform-specific SwiftUI availability handled by Device backports.
	// TODO: Move to Compatibility and add the bar case to the BackgroundStyle.
	enum BackportBarBackgroundStyle: Sendable {
		case bar
	}
	/// Applies the system bar background on platforms that provide it, with a
	/// subtle adaptive fill elsewhere (including tvOS and watchOS).
	@ViewBuilder
	func background(_ style: BackportBarBackgroundStyle) -> some View {
		switch style {
		case .bar:
#if os(tvOS) || os(watchOS)
			content.background(Color.primary.opacity(0.08))
#else
			if #available(iOS 15, macOS 12, *) {
				content.background(.bar)
			} else {
				content.background(Color.primary.opacity(0.08))
			}
#endif
		}
	}

	/// Foreground styles supplied by this package when the native modifier is unavailable.
	enum BackportForegroundStyle: Sendable {
		case tint
	}
	/// Applies the tint color on modern systems and the accent color on older SwiftUI releases.
	/// - Parameter style: Currently `.tint`.
	@ViewBuilder
	func foregroundStyle(_ style: BackportForegroundStyle) -> some View {
		switch style {
		case .tint:
			if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
				content.foregroundStyle(.tint)
			} else {
				content.foregroundColor(.accentColor)
			}
		}
	}

	/// Shows a platform help tooltip where SwiftUI supports it, and retains the
	/// same explanation as an accessibility hint on earlier OS versions.
	@ViewBuilder
	func help(_ text: String) -> some View {
		if #available(iOS 15, macOS 11, tvOS 15, watchOS 7, *) {
			content.help(text)
		} else {
			content.backport.accessibilityHint(Text(text))
		}
	}

	/// Shows a platform help tooltip where SwiftUI supports it, and retains the
	/// same explanation as an accessibility hint on earlier OS versions.
	@ViewBuilder
	func accessibilityHint(_ text: Text) -> some View {
		if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
			content.accessibilityHint(text)
		} else {
			content // ignore
		}
	}

	/// Semantic styles supported by Device's shape helpers on every supported SwiftUI OS.
	enum BackportShapeStyle: Sendable {
		case background
		case primary
	}

	/// Keeps environment lookup inside a view so legacy shape-style fallbacks follow light/dark mode.
	private struct AdaptiveShapeStyle<ShapeContent: Shape>: View {
		@Environment(\.colorScheme) private var colorScheme
		let shape: ShapeContent
		let style: BackportShapeStyle
		let lineWidth: CGFloat

		var body: some View {
			switch style {
			case .background:
				if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
					AnyView(shape.fill(.background))
				} else {
					AnyView(shape.fill(colorScheme == .dark ? Color.black : Color.white))
				}
			case .primary:
				if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
					AnyView(shape.stroke(.primary, lineWidth: lineWidth))
				} else {
					AnyView(shape.stroke(colorScheme == .dark ? Color.white : Color.black, lineWidth: lineWidth))
				}
			}
		}
	}

	/// Fills a shape using the adaptive background style, with a scheme-aware legacy color.
	/// - Parameter style: Use `.background` to select the adaptive system background.
	@ViewBuilder
	func fill(_ style: BackportShapeStyle) -> some View where Content: Shape {
		AdaptiveShapeStyle(shape: content, style: style, lineWidth: 0)
	}

	/// Strokes a shape using the adaptive primary style, with a scheme-aware legacy color.
	/// - Parameters:
	///   - style: Use `.primary` to select the adaptive primary foreground.
	///   - lineWidth: The stroke width in points.
	@ViewBuilder
	func stroke(_ style: BackportShapeStyle, lineWidth: CGFloat = 1) -> some View where Content: Shape {
		AdaptiveShapeStyle(shape: content, style: style, lineWidth: lineWidth)
	}

	/// Activates this view as the source of a drag and drop operation.
    ///
    /// Applying the `draggable(_:)` modifier adds the appropriate gestures for
    /// drag and drop to this view. When a drag operation begins, a rendering of
    /// this view is generated and used as the preview image.
    ///
    /// To customize the default preview, apply a
    /// SwiftUI `View.contentShape` modifier with a `ContentShapeKinds.dragPreview`
    /// kind. For example, you can change the
    /// preview's corner radius or use a nested view as the preview.
    ///
    /// - Parameter payload: A closure that returns a single
    /// instance or a value conforming to Core Transferable's `Transferable` protocol that
    /// represents the draggable data from this view.
    ///
    /// - Returns: A view that activates this view as the source of a drag and
    ///   drop operation, beginning with user gesture input.
    func draggable(_ payload: @autoclosure @escaping () -> Image) -> some View {
#if !os(tvOS) && !os(watchOS)
        if #available(iOS 16, macOS 13, *) {
            return content.draggable(payload())
        }
#endif
        return content // .border(.red, width: 5) // TODO: convert to a button where clicking will allow saving/sharing/copying
    }
}


/// Creates a Text that uses an inline image where Text(Image) is available, and its symbol name otherwise.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Text {
	/// Creates inline symbol text from a symbol-name string.
	@MainActor
	init(symbolName: SFSymbol) {
		if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
			self.init(SwiftUI.Image(symbolName: symbolName))
		} else {
			self.init(symbolName)
		}
	}

	/// Creates inline symbol text from any package symbol representation.
	@MainActor
	init(_ symbolRepresentable: some SymbolRepresentable) {
		if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
			self.init(SwiftUI.Image(symbolName: symbolRepresentable.mainActorSymbolName))
		} else {
			self.init(symbolRepresentable.symbolName)
		}
	}
}

/// Adds a label backport that uses native Label where available and an image/text row otherwise.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content == Any {
	/// Creates an availability-safe label with a system or package symbol image.
	/// - Parameters:
	///   - title: The label's title.
	///   - symbolName: The symbol name used for its icon.
	@MainActor
	static func Label(_ title: String, symbolName: SFSymbol) -> some View {
		if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
			return AnyView(SwiftUI.Label(title, systemImage: symbolName))
		} else {
				return AnyView(
					HStack {
						SwiftUI.Image(symbolName: symbolName)
						Text(title)
					}
				)
			}
		}
	}
#endif
