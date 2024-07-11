//
//  Symbols.swift (for some reason doesn't work in Compatibility so need to keep here).
//
//
//  Created by Ben Ku on 7/6/24.
//

public protocol SymbolRepresentable {
    /// An SF Symbol name string.
    @MainActor
    var symbolName: String { get }
}

#if canImport(SwiftUI)
import SwiftUI
// for switching between asset images and systemImages
@available(iOS 13.0, tvOS 13, watchOS 6, *)
public extension Image {
    /// Create image with a symbol name using system SF symbol or fall back to the symbol asset embedded in Device library.
    init(symbolName: String) {
        var symbolName = symbolName
        let legacySymbolName = "\(symbolName).legacy"
        // use the new symbol name for the Xcode 15 symbol assets (should include colors and proper layering)
        if #available(iOS 17.0, watchOS 10.0, macOS 14.0, tvOS 17.0, visionOS 1.0, macCatalyst 17.0, *) {
            symbolName = symbolName.safeSymbolName(fallback: legacySymbolName)
        } else {
            // if older OS, fallback to compatible symbols.
            symbolName = legacySymbolName.safeSymbolName(fallback: symbolName)
        }
        if .nativeSymbolCheck(symbolName) {
            if #available(macOS 11.0, *) {
                self.init(systemName: symbolName)
                return
            }
        }
        // fallback
        // get module image asset if possible
        self.init(symbolName, bundle: Bundle.module)
    }
    @MainActor
    init(_ symbolRepresentable: some SymbolRepresentable) {
        self.init(symbolName: symbolRepresentable.symbolName)
    }
}
@available(iOS 13.0, tvOS 13, watchOS 6, *)
extension String {
    public static let defaultFallback = "questionmark.square.fill"
    /*
     Legacy versions for Symbol (iOS = catalyst = tvOS
     Device min: 15, 11, 14, 6 so create 1.0 or 2.0 versions for fallback.  Make note that watchOS 6 doesn’t support new symbols.
     1.0 = iOS 13, macOS 11, watchOS 6 * Check this with Device minimum version for potential fallbacks or put note that symbols only work on iOS 13+
     2.0 = iOS 14, macOS 11, watchOS 7, Xcode 12
     3.0 = iOS 15, macOS 12, watchOS 8, Xcode 13
     4.0 = iOS 16, macOS 13, watchOS 9, Xcode 14
     5.0 = iOS 17, macOS 14, watchOS 10, Xcode 15 * Anything before this, use legacy version.
     */
    /// helper for making sure symbolName: function always returns an actual image and never `nil`.
    public func safeSymbolName(fallback: String = .defaultFallback) -> String {
        if !.nativeSymbolCheck(self) {
            // check for asset
            if !.nativeLocalCheck(self) {
                if fallback == .defaultFallback {
                    return fallback
                } else {
                    // go through the fallback symbol to make sure it's valid (should never really happen)
                    return fallback.safeSymbolName()
                }
            }
        }
        return self
    }
}

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@available(iOS 13.0, tvOS 13, watchOS 6, *)
extension Bool {
    static func nativeSymbolCheck(_ symbolName: String) -> Bool {
#if canImport(UIKit)
        return UIImage(systemName: symbolName) != nil
#elseif canImport(AppKit)
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) != nil
        } else {
            return false
        }
#endif
    }
    static func nativeLocalCheck(_ symbolName: String) -> Bool {
#if canImport(UIKit)
        return UIImage(named: symbolName, in: Bundle.module, with: nil) != nil
#elseif canImport(AppKit)
        if #available(macOS 13, *) {
            return NSImage(symbolName: symbolName, bundle: Bundle.module, variableValue: 1) != nil
        } else {
            // probably won't work in macOS 12
            return NSImage(named: symbolName) != nil
        }
#endif
    }
}
#endif



// To avoid importing Color since has higher requirements and adds another dependency.  But really should probably use that instead...
// Normally would just use Kudit/Color but just in case that isn't available...
#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13, watchOS 6, *)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
#endif
