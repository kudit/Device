#if os(watchOS)
import WatchKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI // for Color
#endif

// MARK: Battery
public class Battery {
    public static var current = Battery()
    
    /// This enum describes the state of the battery.
    public enum BatteryState: CustomStringConvertible { // automatically conforms to Equatable since no associated/raw value
        /// The battery state for the device can’t be determined.
        case unknown
        /// The device is not plugged into power; the battery is discharging.
        case unplugged
        /// The device is plugged into power and the battery is less than 100% charged.
        case charging
        /// The device is plugged into power and the battery is 100% charged or the device is the iOS Simulator.
        case full
        
        public var description: String {
            switch self {
            case .unknown:
                return "Unknown"
            case .unplugged:
                return "Unplugged"
            case .charging:
                return "Charging"
            case .full:
                return "Full"
            }
        }
    }
    public typealias BatteryMonitor = () -> Void
    private var monitors: [BatteryMonitor] = []
    
    /// Allows fetching or setting whether battery monitoring is enabled.
    public var monitoring: Bool {
        get {
#if os(iOS) || targetEnvironment(macCatalyst) || os(visionOS)
            return UIDevice.current.isBatteryMonitoringEnabled
#elseif os(watchOS)
            return WKInterfaceDevice.current().isBatteryMonitoringEnabled
#else
            return false // If we don't have access to UIDevice or WKInterfaceDevice, just return false
#endif
        }
        set {
#if os(iOS) || targetEnvironment(macCatalyst) || os(visionOS)
            UIDevice.current.isBatteryMonitoringEnabled = newValue
#elseif os(watchOS)
            WKInterfaceDevice.current().isBatteryMonitoringEnabled = newValue
#else
            // If we don't have access to UIDevice or WKInterfaceDevice, this gets ignored
#endif
        }
    }
    
    /// Add a monitor for detecting changes to the battery state
    public func add(monitor: @escaping BatteryMonitor) {
        monitors.append(monitor)
        monitoring = true // enable monitoring from this point forward
        // create an observer for changes
#if os(iOS) || targetEnvironment(macCatalyst) || os(visionOS)
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: OperationQueue.main
        ) { (notification) in
            // Do your work after received notification
            for monitor in self.monitors {
                monitor()
            }
        }
#elseif os(watchOS)
        // Apparently this can't be observed on watchOS :(
#else
        // If we don't have access to UIDevice or WKInterfaceDevice, this will be undefined
#endif
    }
    
    /// Fetch and return the current battery level as a number from 0—100.  Returns -1 if for some reason we are using this on an unknown platform.
    public var currentLevel: Int {
        let currentMonitoring = monitoring // so we can turn back off afterwards if we don't need changes
        monitoring = true
        defer {
            monitoring = currentMonitoring
        }
#if os(iOS) || targetEnvironment(macCatalyst) || os(visionOS)
        return Int(round(UIDevice.current.batteryLevel * 100)) // round() is actually not needed anymore since -[batteryLevel] seems to always return a two-digit precision number
        // but maybe that changes in the future.
#elseif os(watchOS)
        return Int(round(WKInterfaceDevice.current().batteryLevel * 100)) // round() is actually not needed anymore since -[batteryLevel] seems to always return a two-digit precision number
        // but maybe that changes in the future.
#else
        // If we don't have access to UIDevice or WKInterfaceDevice, this will be undefined
        return -1
#endif
    }
    /// Fetch and return the current state of the battery
    public var currentState: BatteryState {
        let currentMonitoring = monitoring // so we can turn back off afterwards if we don't need changes
        monitoring = true
        defer {
            monitoring = currentMonitoring
        }
#if os(iOS) || targetEnvironment(macCatalyst) || os(visionOS)
        switch UIDevice.current.batteryState {
        case .charging: return .charging
        case .full: return .full
        case .unplugged: return .unplugged
        case .unknown: return .unknown // Should never happen since `batteryMonitoring` is enabled.
        @unknown default:
            return .unknown // To cover any future additions for which DeviceKit might not have updated yet.
        }
#elseif os(watchOS)
        switch WKInterfaceDevice.current().batteryState {
        case .charging: return .charging
        case .full: return .full
        case .unplugged: return .unplugged
        case .unknown: return .unknown // Should never happen since `batteryMonitoring` is enabled.
        @unknown default:
            return .unknown // To cover any future additions for which DeviceKit might not have updated yet.
        }
#else
        // If we don't have access to UIDevice or WKInterfaceDevice, this gets ignored
        return .unknown
#endif
    }
    
    /// System Image used to render a symbol representing the current state/charge level
    public var symbolName: String {
        let percent = currentLevel
        if currentState == .charging {
            return "battery.100percent.bolt"
        } else if percent > 87 {
            return "battery.100percent"
        } else if percent > 63 {
            return "battery.75percent"
        } else if percent > 38 {
            return "battery.50percent"
        } else if percent > 10 {
            return "battery.25percent"
        } else {
            return "battery.0percent"
        }
    }
    
#if canImport(SwiftUI)
    /// Color for the battery icon.
    public var color: Color {
        if lowPowerMode {
            return .yellow
        }
        var redLevel = 20
        // for some reason, iPad only warns at 10% (maybe because the battery is larger?)
        if Device.current.idiom == .pad { //  || Device.current.idiom == .mac // do we need to do this for Macs as well?
            redLevel = 10
        }
        if currentLevel <= redLevel {
            return .red // even when charging
        }
        if currentState == .charging {
            return .green
        }
        return .primary // should be black if in light mode and white in dark mode.
    }
#endif
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /// The user enabled Low Power mode
    public var lowPowerMode: Bool {
        return ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    /// Provides a textual representation of the battery state.
    /// Examples:
    /// ```
    /// Battery level: 90%, device is plugged in.
    /// Battery level: 100 % (Full), device is plugged in.
    /// Battery level: \(batteryLevel)%, device is unplugged.
    /// ```
    public var description: String {
        let level = currentLevel
        switch currentState {
        case .charging: return "Battery level: \(level)%, device is charging."
        case .full: return "Battery level: 100 % (Full), device is plugged in."
        case .unplugged: return "Battery level: \(level)%, device is unplugged."
        default: return "Battery is unknown/unsupported."
        }
    }
}
