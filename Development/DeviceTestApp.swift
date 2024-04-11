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
            DeviceTestView()
        }
    }
}
