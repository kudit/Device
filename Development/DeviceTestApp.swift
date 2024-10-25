#if canImport(SwiftUI)
import SwiftUI
#if canImport(Device) // since this is needed in XCode but is unavailable in Playgrounds.
import Device
#endif

@available(iOS 15.0, macOS 12, tvOS 17, watchOS 8, *)
@main
struct DeviceTestApp: App {
    init() {
        Device.current.disableIdleTimerWhenPluggedIn()
    }
    var body: some Scene {
        WindowGroup {
            if #available(watchOS 8.0, tvOS 15.0, macOS 12.0, *) {
                DeviceTestView()
//                    .onAppear {
//                        Device.current.isIdleTimerDisabled = true
//                    }
            } else {
                // Fallback on earlier versions
                Text("UI Tests not available on older platforms.  However, framework code should still work.")
            }
        }
    }
}
#endif
