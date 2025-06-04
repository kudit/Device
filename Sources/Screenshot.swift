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
    func screenshots() -> [Image] {
        var images = [Image]()
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
//        for window in NSApplication.shared.windows {
//            if let image = window.renderImage() {
//                images.append(Image(nsImage: image))
//            }
//        }
        var displayCount: UInt32 = 0;
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        guard result == CGError.success else {
            debug("Display access error: \(result)", level: .WARNING)
            return images
        }
        let allocated = Int(displayCount)
        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
        result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
        guard result == CGError.success else {
            debug("Display access error: \(result)", level: .WARNING)
            return images
        }
        for i in 1...displayCount {
            guard let screenShot = CGDisplayCreateImage(activeDisplays[Int(i-1)]) else { continue }
            let image = NSImage(cgImage: screenShot, size: .init(width: CGFloat(screenShot.width), height: CGFloat(screenShot.height)))
            images.append(Image(nsImage: image))
        }
        #elseif canImport(UIKit) && !os(watchOS)
        
//        for scene in UIApplication.shared.connectedScenes {
//            if let sceneDelegate = scene.delegate,
//               let snap = sceneDelegate.window?.snapshotView(afterScreenUpdates: false) {
//                view.addSubview(snap)
//            }
//        }
        // fallback version (but may want to use as primary since scene version may not include menu bar)
        for window in UIApplication.shared.windows {
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
