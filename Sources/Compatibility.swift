//
//  SwiftUIView.swift
//  Code to enable support on older platforms.
//
//  Created by Ben Ku on 4/15/24.
//
/*
 
 For module checks to conditionally compile for versions:
 
 canImport(StoreKit)
     iOS 3.0+
     iPadOS 3.0+
     macOS 10.7+
     Mac Catalyst 13.0+
     tvOS 9.0+
     watchOS 6.2+
     visionOS 1.0+

 2019
 canImport(SwiftUI) || canImport(Combine)
     iOS 13.0+
     iPadOS 13.0+
     macOS 10.15+
     Mac Catalyst 13.0+
     tvOS 13.0+
     watchOS 6.0+
     visionOS 1.0+

 2020
 canImport(AppleArchive)
     iOS 14.0+
     iPadOS 14.0+
     macOS 11.0+
     Mac Catalyst 14.0+
     tvOS 14.0+
     watchOS 7.0+
     visionOS 1.0+
 
 2021
 canImport(GroupActivities)
     iOS 15.0+
     iPadOS 15.0+
     macOS 12.0+
     Mac Catalyst 15.0+
     tvOS 15.0+
    NOTE: NO WATCH OS
     visionOS 1.0+
 
 2022 Swift 5.7 (September)
 canImport(Charts) canImport(AppIntents)
     iOS 16.0+
     iPadOS 16.0+
     macOS 13.0+
     Mac Catalyst 16.0+
     tvOS 16.0+
     watchOS 9.0+
     visionOS 1.0+

 2023 Swift 5.8 (March), Swift 5.9 (September) (added #Preview syntax)
 canImport(SwiftData)
     iOS 17.0+
     iPadOS 17.0+
     macOS 14.0+
     Mac Catalyst 17.0+
     tvOS 17.0+
     watchOS 10.0+
     visionOS 1.0+

2024 Swift 5.10 (March), Swift 6 (September)
    iOS 18+
 
 */

// This has been a godsend! https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/

#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

///// for no associated content issues.  Not a view.
//public struct Compatibility {
//    /// TODO: Have this return true or false based off of dark mode
//    public static var darkMode: Bool {
//        return false
//    }
//    public static var backgroundColor: Color {
//        if darkMode {
//            return .black
//        } else {
//            return .white
//        }
//    }
//    public static var primaryColor: Color {
//        if darkMode {
//            return .white
//        } else {
//            return .black
//        }
//    }
//
//    /// A style that reflects the current tint color.
//    ///
//    /// You can set the tint color with the `tint(_:)` modifier. If no explicit
//    /// tint is set, the tint is derived from the app's accent color.
//    public static var tint: some ShapeStyle {
// if #available(watchOS 8.0, tvOS 15.0, macOS 12.0, *) {
//            return AnyShapeStyle(.tint)
//        } else {
//            // Fallback on earlier versions
//            return AnyShapeStyle(Color.accentColor)
//        }
//    }
//
//    /// The background style in the current context.
//    ///
//    /// Access this value to get the style SwiftUI uses for the background
//    /// in the current context. The specific color that SwiftUI renders depends
//    /// on factors like the platform and whether the user has turned on Dark
//    /// Mode.
//    ///
//    /// For information about how to use shape styles, see ``ShapeStyle``.
//    public static var background: some ShapeStyle {
//        if #available(watchOS 7.0, *) {
//            return AnyShapeStyle(.background)
//        } else {
//            // Fallback on earlier versions
//            return backgroundColor
//        }
//    }
//    
//    // Hierarchical styles
//    /// A shape style that maps to the first level of the current content style.
//    ///
//    /// This hierarchical style maps to the first level of the current
//    /// foreground style, or to the first level of the default foreground style
//    /// if you haven't set a foreground style in the view's environment. You
//    /// typically set a foreground style by supplying a non-hierarchical style
//    /// to the ``View/foregroundStyle(_:)`` modifier.
//    ///
//    /// For information about how to use shape styles, see ``ShapeStyle``.
//    public static var primary: some ShapeStyle {
//        if #available(watchOS 8.0, tvOS 15.0, macOS 12.0, *) {
//            return AnyShapeStyle(.primary)
//        } else {
//            return AnyShapeStyle(primaryColor)
//        }
//    }
//    
//    /// A shape style that maps to the second level of the current content style.
//    ///
//    /// This hierarchical style maps to the second level of the current
//    /// foreground style, or to the second level of the default foreground style
//    /// if you haven't set a foreground style in the view's environment. You
//    /// typically set a foreground style by supplying a non-hierarchical style
//    /// to the ``View/foregroundStyle(_:)`` modifier.
//    ///
//    /// For information about how to use shape styles, see ``ShapeStyle``.
//    public static var secondary: some ShapeStyle {
//        if #available(watchOS 8.0, tvOS 15.0, macOS 12.0, *) {
//            return AnyShapeStyle(.secondary)
//        } else {
//            return AnyShapeStyle(.gray) // TODO: figure out if black or white based off of darkMode?  Have a variable that returns the dark mode for these fallback cases?
//        }
//    }
//    
//    /// A shape style that maps to the third level of the current content
//    /// style.
//    ///
//    /// This hierarchical style maps to the third level of the current
//    /// foreground style, or to the third level of the default foreground style
//    /// if you haven't set a foreground style in the view's environment. You
//    /// typically set a foreground style by supplying a non-hierarchical style
//    /// to the ``View/foregroundStyle(_:)`` modifier.
//    ///
//    /// For information about how to use shape styles, see ``ShapeStyle``.
//    public static var tertiary: some ShapeStyle {
//        if #available(watchOS 8.0, tvOS 15.0, macOS 12.0, *) {
//            return AnyShapeStyle(.tertiary)
//        } else {
//            return AnyShapeStyle(.gray) // TODO: figure out if black or white based off of darkMode?  Have a variable that returns the dark mode for these fallback cases?
//        }
//    }
//    
//    /// A shape style that maps to the fourth level of the current content
//    /// style.
//    ///
//    /// This hierarchical style maps to the fourth level of the current
//    /// foreground style, or to the fourth level of the default foreground style
//    /// if you haven't set a foreground style in the view's environment. You
//    /// typically set a foreground style by supplying a non-hierarchical style
//    /// to the ``View/foregroundStyle(_:)`` modifier.
//    ///
//    /// For information about how to use shape styles, see ``ShapeStyle``.
//    public static var quaternary: some ShapeStyle {
//        if #available(watchOS 8.0, tvOS 15.0, macOS 12.0, *) {
//            return AnyShapeStyle(.quaternary)
//        } else {
//            return AnyShapeStyle(.gray) // TODO: figure out if black or white based off of darkMode?  Have a variable that returns the dark mode for these fallback cases?
//        }
//    }
//    
//}

public struct Backport<Content> {
    public let content: Content

    public init(_ content: Content) {
        self.content = content
    }
}

public extension View {
    var backport: Backport<Self> { Backport(self) }
}

#if os(watchOS)
public extension PickerStyle where Self == DefaultPickerStyle {
    // can't just name segmented because marked as explicitly unavailable
    static var segmentedBackport: DefaultPickerStyle {
        return .automatic
    }
}
#else
public extension PickerStyle where Self == SegmentedPickerStyle {
    // can't just name segmented because marked as explicitly unavailable
    static var segmentedBackport: SegmentedPickerStyle {
        return .segmented
    }
}
#endif

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
public extension Backport where Content: View {
    func onChange<V>(
        of value: V,
        perform action: @escaping () -> Void
    ) -> some View where V : Equatable {
        Group {
            if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
                content.onChange(of: value) {
                    action()
                }
            } else {
                content.onChange(of: value) { _ in
                    action()
                }
            }
        }
    }
    func backgroundStyle(_ style: some ShapeStyle) -> some View {
        Group {
            if #available(watchOS 9.0, tvOS 16.0, macOS 13.0, iOS 16.0, *) {
                content.backgroundStyle(style)
            } else {
                // Fallback on earlier versions
                if let color = style as? Color {
                    content.background(color)
                } else {
                    content // don't apply style if watchOS 6 or 7
                }
            }
        }
    }
}

public protocol ContainerView: View {
    associatedtype Content
    init(content: @escaping () -> Content)
}
public extension ContainerView {
    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.init(content: content)
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
public struct BackportNavigationStack<Content: View>: ContainerView {
    var content: () -> Content

    public init(content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        if #available(macCatalyst 16.0, iOS 16, watchOS 9.0, macOS 13.0, tvOS 16.0, *) {
            NavigationStack(root: content)
        } else {
            // Fallback on earlier versions
            NavigationView(content: content)
        }
    }
}

#endif



// MARK: - Byte string info class (perhaps separate file/include?)
import Foundation
/// Add byte functions to all integer types.
public extension BinaryInteger {
    var bytes: Int64 {
        Int64(self)
    }
    func byteString(_ countStyle: ByteCountFormatter.CountStyle) -> String {
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: countStyle)
    }
    /// Formats this value as a number of bytes (or kB/MB/GB/etc) using the ByteCountFormatter() to get a nice clean string.  Returns a named tuple (count: String, units: String)
    func byteParts(_ countStyle: ByteCountFormatter.CountStyle) -> (count: String, units: String) {
        var parts = byteString(countStyle).components(separatedBy: " ")
        if parts.count == 1 {
            // should not happen!
            return (count: parts[0], units: "ERROR")
        } else if parts.count > 2 {
            let count = parts.removeFirst()
            return (count: count, parts.joined(separator: " "))
        } else {
            return (parts[0], parts[1])
        }
    }
    func byteCount(_ countStyle: ByteCountFormatter.CountStyle) -> Double {
        return Double(byteParts(countStyle).count) ?? 0
    }
}

public protocol SymbolRepresentable {
    /// An SF Symbol name string.
    var symbolName: String { get }
}
