import SwiftUI
#if canImport(Device)
import Device
#endif

@main
struct DeviceTestApp: App {
    var body: some Scene {
        WindowGroup {
            DeviceTestView()
        }
    }
}
