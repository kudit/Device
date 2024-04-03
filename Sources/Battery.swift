#if os(watchOS)
import WatchKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI // for Color
#endif
#if canImport(IOKit.ps)
import IOKit.ps
#endif

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

public protocol Battery: ObservableObject, CustomStringConvertible, Identifiable {
    /// The percentage battery level from 0—100.  If this cannot be determined for some reason, this will return -1.  Unfortunately, on some devices, Apple restricts this to every 5% instead of every % 🙁
    var currentLevel: Int { get }
    /// The current state of the battery.
    var currentState: BatteryState { get }
    /// The user enabled Low Power mode
    var lowPowerMode: Bool { get }
    /// Change Monitoring
    typealias BatteryMonitor = (any Battery) -> Void
    /// Allows fetching or setting whether battery monitoring is enabled.
    var monitoring: Bool { get set }
    func add(monitor: @escaping BatteryMonitor)
}
public extension Battery {
    var isCharging: Bool { currentState == .charging }
    
    /// System Image used to render a symbol representing the current state/charge level
    var symbolName: String {
        let percent = currentLevel
        var percentWord: String
        if #available(iOS 17, macOS 14, macCatalyst 17, tvOS 17, watchOS 10,  *) {
            percentWord = "percent"
        } else {
            percentWord = ""
        }
        if currentState == .charging {
            return "battery.100\(percentWord).bolt"
        } else if percent > 87 {
            return "battery.100\(percentWord)"
        } else if percent > 63 {
            return "battery.75\(percentWord)"
        } else if percent > 38 {
            return "battery.50\(percentWord)"
        } else if percent > 10 {
            return "battery.25\(percentWord)"
        } else {
            return "battery.0\(percentWord)"
        }
    }

#if canImport(SwiftUI)
    /// Color for the battery icon.  Should mirror the system battery icon.
    var systemColor: Color {
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
    
    /// Expanded colors so there is always a background color for contrast.
    var color: Color {
        // since this is just for visionOS, assume no lowPowerMode
        if currentLevel <= 20 {
            return .red
        }
        if currentLevel <= 40 {
            return .orange
        }
        if currentLevel <= 60 {
            return .yellow
        }
        if currentLevel <= 80 {
            // GreenYellow
            return Color(red: 173.0/255, green: 1, blue: 47.0/255)
        }
        return .green
    }
#endif
    
    /// Provides a textual representation of the battery state.
    /// Examples:
    /// ```
    /// Battery level: 90%, device is plugged in.
    /// Battery level: 100 % (Full), device is plugged in.
    /// Battery level: \(batteryLevel)%, device is unplugged.
    /// ```
    var description: String {
        let level = currentLevel
        switch currentState {
        case .charging: return "Battery level: \(level)%, device is charging."
        case .full: return "Battery level: \(level)% (Full), device is plugged in."
        case .unplugged: return "Battery level: \(level)%, device is unplugged."
        default: return "Battery is unknown/unsupported."
        }
    }
    var id: String { description }
}

public class MockBattery: Battery {
    public var currentLevel: Int = 82
    public var currentState: BatteryState = .unplugged
    public var lowPowerMode: Bool = false
    public var monitoring: Bool = false // add observers to trigger changes?
    private var monitors = [BatteryMonitor]()
    public func add(monitor: @escaping BatteryMonitor) {
        monitors.append(monitor)
    }
    
    init(currentLevel: Int = 82, currentState: BatteryState = .unplugged, lowPowerMode: Bool = false) {
        self.currentLevel = currentLevel
        self.currentState = currentState
        self.lowPowerMode = lowPowerMode
    }

    public static var mocks = [
        MockBattery(currentLevel: 2, currentState: .charging),
        MockBattery(currentLevel: 5),
        MockBattery(currentLevel: 15),
        MockBattery(currentLevel: 25),
        MockBattery(currentLevel: 50),
        MockBattery(currentLevel: 75),
        MockBattery(currentState: .charging),
        MockBattery(currentLevel: 100, currentState: .full),
    ]
}

public class DeviceBattery: Battery {
    public static var current = DeviceBattery()
    
    private var monitors: [BatteryMonitor] = []
    
    /// Allows fetching or setting whether battery monitoring is enabled.
    public var monitoring: Bool {
        get {
#if os(watchOS)
            return WKInterfaceDevice.current().isBatteryMonitoringEnabled
#elseif canImport(UIKit) && !os(tvOS)
            return UIDevice.current.isBatteryMonitoringEnabled
#else
            return false // If we don't have access to UIDevice or WKInterfaceDevice, just return false
#endif
        }
        set {
#if os(watchOS)
            WKInterfaceDevice.current().isBatteryMonitoringEnabled = newValue
#elseif canImport(UIKit) && !os(tvOS)
            UIDevice.current.isBatteryMonitoringEnabled = newValue
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
#if os(watchOS)
        // Apparently this can't be observed on watchOS :(
#elseif canImport(UIKit) && !os(tvOS)
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: OperationQueue.main
        ) { (notification) in
            // Do your work after received notification
            for monitor in self.monitors {
                monitor(self)
            }
        }
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
#if os(watchOS)
        return Int(round(WKInterfaceDevice.current().batteryLevel * 100)) // round() is actually not needed anymore since -[batteryLevel] seems to always return a two-digit precision number
        // but maybe that changes in the future.
#elseif os(macOS) || targetEnvironment(macCatalyst)
        // thanks to https://github.com/thebarbican19/BatteryBoi
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                
                if description["Type"] as? String == kIOPSInternalBatteryType {
                    return description[kIOPSCurrentCapacityKey] as? Int ?? -1
                    
                }
                
            }
            
        }
        return 100
#elseif canImport(UIKit) && !os(tvOS)
//        UIDevice.current.isBatteryMonitoringEnabled = true
//        print(UIDevice.current.batteryLevel)
        return Int(round(UIDevice.current.batteryLevel * 100)) // round() is actually not needed anymore since -[batteryLevel] seems to always return a two-digit precision number
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
        // TODO: Figure out why it reports as .full when it's actually .charging and 76%...
#if os(watchOS)
        switch WKInterfaceDevice.current().batteryState {
        case .charging: return .charging
        case .full: return .full
        case .unplugged: return .unplugged
        case .unknown: return .unknown // Should never happen since `batteryMonitoring` is enabled.
        @unknown default:
            return .unknown // To cover any future additions for which DeviceKit might not have updated yet.
        }
#elseif canImport(UIKit) && !os(tvOS)
        switch UIDevice.current.batteryState {
        case .charging: return .charging
        case .full:
#if os(macOS) || targetEnvironment(macCatalyst)
            // for some reason, this reports charging state as full.
            return .charging
#else
            return .full
#endif
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
    
    /// The user enabled Low Power mode
    public var lowPowerMode: Bool {
        return ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}
