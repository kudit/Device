#if canImport(SwiftUI)
import SwiftUI
#if canImport(Device) // since this is needed in XCode but is unavailable in Playgrounds.
import Device
import Compatibility // TODO: Import KuditConnect??
#endif

@available(iOS 15.0, macOS 12, tvOS 17, watchOS 8, *)
@main
struct DeviceTestApp: App {
    init() {
        Device.current.disableIdleTimerWhenPluggedIn()
        Application.track()
        //Application.appleID = "6736626499"
        
        // use this to figure out which items are causing hash conflicts.
//        var dictionary: [Device: String] = [:]
//        for device in Device.all {
//            debug(device.officialName)
//            if dictionary.keys.contains(device) {
//                debug("DUPLICATE KEY ALREADY EXISTS!", level: .ERROR)
//                debug(device)
//                debug(dictionary.keys.first { $0 == device } ?? "NONE existing using == matching")
//            }
//            dictionary[device] = device.officialName
//        }
//        var ids = [String: Device]()
//        for device in Device.all {
//            if let image = device.image {
//                debug(image)
//                if ids.keys.contains(image) {
//                    debug("DUPLICATE KEY ALREADY EXISTS!", level: .ERROR)
//                    debug(device)
//                    debug(ids.keys.first { $0 == image } ?? "NONE existing using == matching")
//                }
//                ids[image] = device
//            }
//        }
//        debug("Done with dictionary \(dictionary.count)")
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
