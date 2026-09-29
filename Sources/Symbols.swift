//
//  Symbols.swift (for some reason doesn't work in Compatibility due to Bundle.module not being available (possibly because no dependencies?) so need to keep here).
//
//
//  Created by Ben Ku on 7/6/24.
//



import Compatibility

public extension SFSymbol {
    @available(*, deprecated, renamed: "defaultUnknownSymbol")
    static let defaultFallback = defaultUnknownSymbol
}

/// This is a helper to allow main actor isolated code to attempt to conform to SymbolRepresentable and for main actor isolated code to use either those or regular SymbolRepresentable items as sources for their symbol names without forcing all SymbolRepresentable to run on the main thread.
@MainActor
public protocol MainActorSymbolRepresentable {
    var mainActorSymbolName: String { get }
}

public extension SymbolRepresentable {
    @MainActor
    var mainActorSymbolName: String { self.symbolName }
}

#if canImport(SwiftUI)
import SwiftUI
// for switching between asset images and systemImages
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Image {
    /// Create image with a symbol name using system SF symbol or fall back to the symbol asset embedded in Device library.
    init(symbolName: SFSymbol) {
        var symbolName = symbolName
        let legacySymbolName = "\(symbolName).legacy"
        // use the new symbol name for the Xcode 15 symbol assets (should include colors and proper layering)
        if #available(iOS 17.0, watchOS 10.0, macOS 14.0, tvOS 17.0, macCatalyst 17.0, *) { // visionOS 1.0 check unnecessary
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
    init(_ symbolRepresentable: some SymbolRepresentable) {
        self.init(symbolName: symbolRepresentable.symbolName)
    }
    @MainActor
    init(_ symbolRepresentable: some MainActorSymbolRepresentable) {
        self.init(symbolName: symbolRepresentable.mainActorSymbolName)
    }
}

public extension String {
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
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func safeSymbolName(fallback: String = .defaultUnknownSymbol) -> String {
        if !.nativeSymbolCheck(self) {
            // check for asset
            if !.nativeLocalCheck(self) {
                if fallback == .defaultUnknownSymbol {
                    return fallback
                } else {
                    // go through the fallback symbol to make sure it's valid (only time that would be invalid would be if we missed including it in the legacy resources).
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

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension Bool {
    static func nativeSymbolCheck(_ symbolName: SFSymbol) -> Bool {
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
