import SwiftUI
#if canImport(Device)
import Device
#endif

@main
struct DeviceTestApp: App {
    init() {
        Device.current.disableIdleTimerWhenPluggedIn()
    }
    var body: some Scene {
        WindowGroup {
            if #available(watchOS 8.0, tvOS 15.0, macOS 12.0, *) {
                DeviceTestView()
            } else {
                // Fallback on earlier versions
                Text("UI Tests not available on older platforms.  However, framework code should still work.")
            }
        }
    }
}
