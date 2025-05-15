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
//            main {
                Device.current.isIdleTimerDisabled = disabled // must be run on the main actor AFTER most of the UI is loaded (so do on a view onAppear and NOT during the app init)
//            }
        }
    }
}

#endif
