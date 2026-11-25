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

/// Supplies readable approximations for battery symbols that are newer than the
/// system symbol library on the oldest supported platforms.
@MainActor
private enum DeviceSymbolTextFallbacks {
    static let install: Void = {
        let fallbacks: [SFSymbol: String] = [
            "battery.0percent": "[ 0% ]∎",
            "battery.25percent": "[25%]∎",
            "battery.50percent": "[50%]∎",
            "battery.75percent": "[75%]∎",
            "battery.100percent": "[100%]∎",
            "battery.100percent.bolt": "[ ⚡️ ]∎",
            "battery.slash": "[ -\\- ]∎",
        ]

        // Keep any custom mappings registered by an app before Device is first used.
        for (symbol, fallback) in fallbacks where SFSymbol.symbolUnicodeMap[symbol] == nil {
            SFSymbol.symbolUnicodeMap[symbol] = fallback
        }
    }()
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

#if canImport(SwiftUI) && canImport(CoreText) && canImport(CoreGraphics)
import SwiftUI
import Foundation
import CoreText
import CoreGraphics
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Identifies which source supplied an image created with `Image(symbolName:)`.
/// This is useful when a system symbol and a package asset share the same name.
public enum SymbolImageSource: String, Sendable {
    case system
    case asset
    case legacyAsset
    case fallback
}

// for switching between asset images and systemImages
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Image {
    /// Reports which source `Image(symbolName:)` will use for this name on the current OS.
    @MainActor
    static func symbolImageSource(for symbolName: SFSymbol, bundle: Bundle? = nil) -> SymbolImageSource {
        _ = DeviceSymbolTextFallbacks.install
        let assetBundle = bundle ?? Bundle.module
        if .nativeSymbolCheck(symbolName) { return .system }

        let symbolFallbacks = Self.symbolFallbacks(startingAt: symbolName)
        var imageCandidates: [SFSymbol] = []
        if #available(iOS 17.0, watchOS 10.0, macOS 14.0, tvOS 17.0, macCatalyst 17.0, *) {
            for fallback in symbolFallbacks {
                imageCandidates.append(fallback)
                imageCandidates.append("\(fallback).legacy")
            }
        } else {
            for fallback in symbolFallbacks {
                imageCandidates.append(fallback)
                imageCandidates.append("\(fallback).legacy")
            }
        }

        if imageCandidates.contains(where: { .nativeSymbolCheck($0) }) { return .system }
        for candidate in imageCandidates where .nativeLocalCheck(candidate, in: assetBundle) {
            return candidate.hasSuffix(".legacy") ? .legacyAsset : .asset
        }
        if symbolFallbacks.contains(where: { $0.unicodeForSymbol != nil }) { return .fallback }
        return .fallback
    }

    /// Creates a symbol image from an SF Symbol, a Device asset, or a rasterized Unicode fallback.
    ///
    /// The Unicode fallback is drawn at high resolution as a transparent template image, so it
    /// remains an `Image` and supports normal image sizing and tinting on older systems. Its
    /// logical size defaults to 32 points. Use `.resizable()` when it should scale with layout.
    /// - Parameters:
    ///   - symbolName: SF Symbol or image asset name.
    ///   - bundle: Bundle containing the image asset. Defaults to Device's resource bundle.
    ///   - fallbackSize: Logical width and height of a rasterized glyph fallback.
    @MainActor
    init(symbolName: SFSymbol, bundle: Bundle? = nil, fallbackSize: CGFloat = 32) {
        _ = DeviceSymbolTextFallbacks.install
        let assetBundle = bundle ?? Bundle.module
        // Prefer the latest system drawing; use the selected bundle only when the OS lacks it.
        if .nativeSymbolCheck(symbolName) {
#if os(macOS) && !targetEnvironment(macCatalyst)
            if #available(macOS 11.0, *) {
                self.init(systemName: symbolName)
                return
            }
#else
            self.init(systemName: symbolName)
            return
#endif
        }
        let symbolFallbacks = Self.symbolFallbacks(startingAt: symbolName)
        var imageCandidates: [SFSymbol] = []
        // use the new symbol name for the Xcode 15 symbol assets (should include colors and proper layering)
        if #available(iOS 17.0, watchOS 10.0, macOS 14.0, tvOS 17.0, macCatalyst 17.0, *) { // visionOS 1.0 check unnecessary
            for fallback in symbolFallbacks {
                imageCandidates.append(fallback)
                imageCandidates.append("\(fallback).legacy")
            }
        } else {
            // if older OS, fallback to compatible symbols.
            for fallback in symbolFallbacks {
                imageCandidates.append(fallback)
                imageCandidates.append("\(fallback).legacy")
            }
        }

        var visitedImages = Set<SFSymbol>()
        for candidate in imageCandidates where visitedImages.insert(candidate).inserted {
            if .nativeSymbolCheck(candidate) {
#if os(macOS) && !targetEnvironment(macCatalyst)
                if #available(macOS 11.0, *) {
                    self.init(systemName: candidate)
                    return
                }
#else
                self.init(systemName: candidate)
                return
#endif
            }
        }

        for candidate in imageCandidates {
            // Preserve authored modern and legacy variants only after checking native aliases.
            if .nativeLocalCheck(candidate, in: assetBundle) {
                self.init(candidate, bundle: assetBundle)
                return
            }
        }

        var unicodeGlyph: String?
        for fallback in symbolFallbacks {
            if let glyph = fallback.unicodeForSymbol {
                unicodeGlyph = glyph
                break
            }
        }
        if let glyph = unicodeGlyph, let cgImage = SymbolFallbackRasterizer.image(for: glyph) {
            self.init(decorative: cgImage, scale: CGFloat(cgImage.width) / max(1, fallbackSize), orientation: .up)
            self = self.renderingMode(.template)
            return
        }

        // Keep the promised Image type even if this platform cannot rasterize a glyph.
        self.init("\(SFSymbol.defaultUnknownSymbol).legacy", bundle: assetBundle)
    }

    /// Creates an image for a `SymbolRepresentable` value.
    @MainActor
    init(_ symbolRepresentable: some SymbolRepresentable) {
        self.init(symbolName: symbolRepresentable.symbolName)
    }
    /// Creates an image for a main-actor isolated symbol value.
    @MainActor
    init(_ symbolRepresentable: some MainActorSymbolRepresentable) {
        self.init(symbolName: symbolRepresentable.mainActorSymbolName)
    }

    /// Follows Compatibility's mutable symbol aliases, guarding against custom-map cycles.
    @MainActor
    private static func symbolFallbacks(startingAt symbolName: SFSymbol) -> [SFSymbol] {
        var candidates: [SFSymbol] = []
        var visited = Set<SFSymbol>()
        var candidate: SFSymbol? = symbolName
        while let current = candidate, visited.insert(current).inserted {
            candidates.append(current)
            candidate = current.fallbackForSymbol
        }
        return candidates
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
#else
        return false
#endif
    }
    static func nativeLocalCheck(_ symbolName: String, in bundle: Bundle = Bundle.module) -> Bool {
#if canImport(UIKit)
        return UIImage(named: symbolName, in: bundle, with: nil) != nil
#elseif canImport(AppKit)
		// Search the package bundle first so SwiftPM/module asset catalogs resolve,
		// then preserve compatibility with symbols registered in the main bundle.
		return bundle.image(forResource: NSImage.Name(symbolName)) != nil
			|| NSImage(named: NSImage.Name(symbolName)) != nil
#else
        return false
#endif
    }
}

/// Renders a Unicode character to a high-resolution transparent monochrome bitmap.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private enum SymbolFallbackRasterizer {
    private static let cache = NSCache<NSString, CGImage>()

    static func image(for glyph: String) -> CGImage? {
        if let cached = cache.object(forKey: glyph as NSString) { return cached }

        let pointSize: CGFloat = 200
        let canvasSize: CGFloat = 240
        let scale: CGFloat = 3
        let pixelSize = Int(canvasSize * scale)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: pixelSize, height: pixelSize,
                                      bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }

        context.scaleBy(x: scale, y: scale)
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        let font = CTFontCreateUIFontForLanguage(.system, pointSize, nil)
            ?? CTFontCreateWithName("HelveticaNeue" as CFString, pointSize, nil)
        let attributes = [NSAttributedString.Key(kCTFontAttributeName as String): font]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: glyph, attributes: attributes))
        let bounds = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds])
        guard !bounds.isNull, !bounds.isEmpty else { return nil }
        context.textPosition = CGPoint(x: (canvasSize - bounds.width) / 2 - bounds.minX,
                                       y: (canvasSize - bounds.height) / 2 - bounds.minY)
        CTLineDraw(line, context)
        guard let image = context.makeImage() else { return nil }
        cache.setObject(image, forKey: glyph as NSString)
        return image
    }
}
#endif
