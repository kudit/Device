//
//  Screenshot.swift
//  Device
//
//  Created by Ben Ku on 6/4/25.
//

import Compatibility

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#elseif canImport(UIKit) && !os(watchOS)
import UIKit

public extension UIView {
    /// Get a UIImage from the UIView
    /// - parameter opaque:
    /// A Boolean flag indicating whether the image is opaque. Specify true to ignore the alpha channel. Specify false to handle any partially transparent pixels.
    /// - parameter scale:
    /// The scale factor to apply to the image. If you specify a value of 0.0, the scale factor is set to the scale factor of the device’s main screen.
    func renderImage(opaque: Bool = false, scale: CGFloat = 0) -> UIImage? {
        if #available(iOS 10, tvOS 10, *) {
            let format = {
#if os(tvOS)
                if #available(tvOS 11, *) {
                    UIGraphicsImageRendererFormat.preferred()
                } else {
                    UIGraphicsImageRendererFormat.default()
                }
#else
                UIGraphicsImageRendererFormat.default()
#endif
            }()
            format.opaque = opaque
            format.scale = scale
            return UIGraphicsImageRenderer(size: bounds.size, format: format).image { layer.render(in: $0.cgContext) }
        } else {
            // Fallback on earlier versions
            // The following methods will only return a 8-bit per channel context in the DeviceRGB color space.
            // Any new bitmap drawing code is encouraged to use UIGraphicsImageRenderer in lieu of this API.

            //creates new image context with same size as view
            // UIGraphicsBeginImageContextWithOptions (scale=0.0) for high res capture
            UIGraphicsBeginImageContextWithOptions(bounds.size, opaque, scale)
            defer {
                // clean up newly created context
                UIGraphicsEndImageContext()
            }
            // renders the view's layer into the current graphics context
            if let context = UIGraphicsGetCurrentContext() { self.layer.render(in: context) }

            // creates UIImage from what was drawn into graphics context
            return UIGraphicsGetImageFromCurrentImageContext()
        }
    }
}
#endif

#if canImport(SwiftUI)
import SwiftUI
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Application {
    /// Convenience images for app-owned presentations; use captureAppPresentations for IDs/status.
	@MainActor
	func screenshots() -> [Image] { captureAppPresentations().compactMap(\.image) }

	/// Whole-display capture is separate and permission-aware on macOS.
	/// Calling without permission returns an empty result unless requestPermission is true.
	@MainActor
	func captureDesktopDisplays(requestPermission: Bool = false) -> [Image] {
		#if canImport(AppKit) && !targetEnvironment(macCatalyst)
		if !CGPreflightScreenCaptureAccess() {
			guard requestPermission && CGRequestScreenCaptureAccess() else { return [] }
		}
		return legacyDesktopScreenshots()
		#else
		return []
		#endif
	}

	// Retains the original platform capture implementation separately from app captures.
	@MainActor
	private func legacyDesktopScreenshots() -> [Image] {
        var images = [SwiftUI.Image]()
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
//    for window in NSApplication.shared.windows {
//      if let image = window.renderImage() {
//        images.append(Image(nsImage: image))
//      }
//    }
        var displayCount: UInt32 = 0;
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        guard result == CGError.success else {
            debug("Display access error: \(result)", level: .WARNING)
            return images
        }
        guard displayCount > 0 else { return images }
        let allocated = Int(displayCount)
        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
        defer { activeDisplays.deallocate() }
        result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
        guard result == CGError.success else {
            debug("Display access error: \(result)", level: .WARNING)
            return images
        }
        for i in 0..<min(Int(displayCount), allocated) {
            guard let screenShot = CGDisplayCreateImage(activeDisplays[i]) else { continue }
            let image = NSImage(cgImage: screenShot, size: .init(width: CGFloat(screenShot.width), height: CGFloat(screenShot.height)))
            images.append(Image(nsImage: image))
        }
        #elseif canImport(UIKit) && !os(watchOS)
        
         // UIKit applications can own more than one scene, particularly on iPadOS,
        // Mac Catalyst, and visionOS. Walk every connected window scene so capture
        // remains complete without using UIApplication.windows, which is deprecated
        // because it cannot identify which scene owns a returned window.
        let windows = UIApplication.shared.connectedScenes // supported in iOS 13+ so all SwiftUI supported.
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        for window in windows {
            if let image = window.renderImage() {
                images.append(Image(uiImage: image))
            }
            // saving will require a NSPhotoLibraryUsageDescription in your project's Info.plist
            //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        #endif
        return images
    }
}
#endif

#if canImport(SwiftUI)
/// A capture outcome for one app-owned presentation; this never claims a device-wide screenshot.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct AppPresentationCapture: Identifiable {
	public enum Status: String, Sendable { case success, unsupported, incomplete }
	public let id: String
	public let displayID: String?
	public let presentationID: String?
	public let status: Status
	public let image: SwiftUI.Image?
	public let detail: String?
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
public extension Application {
	/// Captures each owned window separately at its display's render scale.
	/// Protected/video content can be absent. CarPlay template scenes without a drawable
	/// app window are explicitly unsupported; no transport or entitlement is inferred.
	func captureAppPresentations() -> [AppPresentationCapture] {
		var results: [AppPresentationCapture] = []
		#if canImport(UIKit) && !os(watchOS)
		func capture(_ window: UIWindow) {
			guard !window.isHidden else { return }
			let snapshot = DisplayMonitor.shared.presentation(for: window)
			guard window.bounds.width > 0 && window.bounds.height > 0 else {
				results.append(.init(id: snapshot.id, displayID: snapshot.display.id, presentationID: snapshot.id, status: .unsupported, image: nil, detail: "The app window has no renderable bounds."))
				return
			}
			let rendered = window.renderImage(scale: CGFloat(snapshot.display.scale ?? 1))
			results.append(.init(id: snapshot.id, displayID: snapshot.display.id, presentationID: snapshot.id, status: rendered == nil ? .unsupported : .incomplete,
				image: rendered.map { SwiftUI.Image(uiImage: $0) }, detail: "App layer capture; protected, video, and system surfaces may be omitted."))
		}
		let scenes = UIApplication.shared.connectedScenes
		for scene in scenes {
			guard let scene = scene as? UIWindowScene else {
				let id = "scene-\(ObjectIdentifier(scene))"
				results.append(.init(id: id, displayID: nil, presentationID: id, status: .unsupported, image: nil, detail: "Scene role \(scene.session.role.rawValue) has no drawable app window (for example, a CarPlay template scene)."))
				continue
			}
			for window in scene.windows { capture(window) }
		}
		#elseif canImport(AppKit)
		for window in (NSApp?.windows ?? []) where window.isVisible {
			guard let snapshot = DisplayMonitor.shared.presentation(for: window), let view = window.contentView else { continue }
			let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds)
			var image: SwiftUI.Image?
			if let bitmap {
				view.cacheDisplay(in: view.bounds, to: bitmap)
				let native = NSImage(size: view.bounds.size); native.addRepresentation(bitmap)
				image = SwiftUI.Image(nsImage: native)
			}
			results.append(.init(id: snapshot.id, displayID: snapshot.display.id, presentationID: snapshot.id, status: image == nil ? .unsupported : .incomplete, image: image, detail: "App content-view capture; independent of permission-based whole-display capture."))
		}
		#endif
		return results
	}
}
#endif
