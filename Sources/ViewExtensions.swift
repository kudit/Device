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
    /// Activates this view as the source of a drag and drop operation.
    ///
    /// Applying the `draggable(_:)` modifier adds the appropriate gestures for
    /// drag and drop to this view. When a drag operation begins, a rendering of
    /// this view is generated and used as the preview image.
    ///
    /// To customize the default preview, apply a
    /// ``View/contentShape(_:_:eoFill:)`` with a
    /// ``ContentShapeKinds/dragPreview`` kind. For example, you can change the
    /// preview's corner radius or use a nested view as the preview.
    ///
    /// - Parameter payload: A closure that returns a single
    /// instance or a value conforming to <doc://com.apple.documentation/documentation/coretransferable/transferable> that
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
#endif
