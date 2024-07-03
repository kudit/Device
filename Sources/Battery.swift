#if os(watchOS)
import WatchKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI // for Color
#endif
//#if canImport(IOKit.ps) // This doesn't work probably because of the ".ps" part
#if os(macOS) || targetEnvironment(macCatalyst)
import IOKit
import IOKit.ps
#endif
#if !canImport(Combine)
// Add stub here to make sure we can compile
public protocol ObservableObject {
    var objectWillChange: ObjectWillChangePublisher { get }
}
public struct ObjectWillChangePublisher {
    func send() {} // dummy for calls
    static let dummyPublisher = ObjectWillChangePublisher()
}
public extension ObservableObject {
    var objectWillChange: ObjectWillChangePublisher {
        return .dummyPublisher
    }
}
#endif
import Foundation // for Timer

/// This enum describes the state of the battery.
public enum BatteryState: CustomStringConvertible, CaseNameConvertible, Sendable { // automatically conforms to Equatable since no associated/raw value
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

/// Use to indicate the type of change that was present in a monitor update.
public enum BatteryChangeType: Sendable {
    case level, state, lowPowerMode
}

public protocol Battery: ObservableObject, SymbolRepresentable, CustomStringConvertible, Identifiable {
    /// The percentage battery level from 0—100.  If this cannot be determined for some reason, this will return -1.  Unfortunately, on some devices, Apple restricts this to every 5% instead of every % 🙁
    var currentLevel: Int { get }
    /// The current state of the battery.
    var currentState: BatteryState { get }
    /// The user enabled Low Power mode
    var lowPowerMode: Bool { get }
    /// Allows fetching or setting whether battery monitoring is enabled.  Don't necessarily need ot use this directly.  You can just add a monitor by calling `.monitor { battery, changeType in }`.
    var monitoring: Bool { get set }
    /// Change Monitoring (needs to be `any Battery` so that can mix DeviceBattery and MonitoredDeviceBattery
    typealias BatteryMonitor = (any Battery, BatteryChangeType) -> Void
    /// Adds a callback that will be called when the battery state changes.
    /// Callback takes a `battery` parameter and the `BatteryChangeType`
    func monitor(_ monitor: @escaping BatteryMonitor)
}
public extension Battery {
    /// Return true if the device is actively charging.  Equivalent to testing `curerntState == .charging`
    var isCharging: Bool { currentState == .charging }
    /// Return true if the device is plugged in.
    var isPluggedIn: Bool { currentState == .charging || currentState == .full }

    @available(*, deprecated, message: "Use use monitor { battery, type in }")
    func add(monitor: @escaping (any Battery) -> Void) {
        self.monitor { battery, changeType in
            monitor(battery)
        }
    }
    
    /// System Image used to render a symbol representing the current state/charge level
    @MainActor
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
    @MainActor
    var systemColor: Color {
        var redLevel = 20
        // for some reason, iPad only warns at 10% (maybe because the battery is larger?)
        if Device.current.idiom == .pad { //  || Device.current.idiom == .mac // do we need to do this for Macs as well?
            redLevel = 10
        }
        if currentLevel <= redLevel {
            return .red // even when charging or low power mode
        }
        if lowPowerMode {
            return .yellow
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
        let lowPowerMode = lowPowerMode ? " (low power mode)" : ""
        let level = currentLevel
        let batteryLevelString = "Battery level: \(level)%"
        let deviceIsString = "\(lowPowerMode), device is "
        switch currentState {
        case .charging: return "\(batteryLevelString)\(deviceIsString)charging."
        case .full: return "\(batteryLevelString) (Full)\(deviceIsString)plugged in."
        case .unplugged: return "\(batteryLevelString)\(deviceIsString)unplugged."
        default: return "Battery is unknown/unsupported."
        }
    }
    var id: String { description }
}

public struct BatterySnapshot: Sendable {
    public var currentLevel: Int = -1
    public var currentState: BatteryState = .unplugged
    public var lowPowerMode: Bool = false
    public static let missing = BatterySnapshot(currentLevel: -1, currentState: .unknown)
    public static let mocks = [
        BatterySnapshot.missing,
        BatterySnapshot(currentLevel: 0),
        BatterySnapshot(currentLevel: 2, currentState: .charging),
        BatterySnapshot(currentLevel: 15),
        BatterySnapshot(currentLevel: 25),
        BatterySnapshot(currentLevel: 50),
        BatterySnapshot(currentLevel: 75),
        BatterySnapshot(currentLevel: 82, currentState: .charging),
        BatterySnapshot(currentLevel: 100, currentState: .full),
    ]
}

// Mocks are for testing functions that require a battery.  However, this mock doesn't update.  TODO: create a version that publishes changes every second to simulate drain/charging.
public class MockBattery: Battery {
#if canImport(Combine)
    @Published public var currentLevel: Int = -1
    @Published public var currentState: BatteryState = .unplugged
    @Published public var lowPowerMode: Bool = false
#else
    public var currentLevel: Int = -1
    public var currentState: BatteryState = .unplugged
    public var lowPowerMode: Bool = false
#endif
    // save so a similar battery without a cycle level doesn't get merged.
    public var cycleLevelState: TimeInterval
    public var monitoring: Bool = false // add observers to trigger changes?
    public var monitors = [BatteryMonitor]()
    public func monitor(_ monitor: @escaping BatteryMonitor) {
        monitors.append(monitor)
    }
    
    public var description: String {
        "\(currentLevel)\(currentState)\(lowPowerMode)\(cycleLevelState)"
    }
    
    /// Creates a mock Battery object that can be passed to a BatteryView or used for various things.  Will automatically cycle battery to empty and then charge to full and then empty again if `cycleLevelStateSeconds` is greater than 0.  If so, creates a timer that will automatically drain battery to 0 and then charge to 100 and then drain again every cycleLevelStateSeconds.
    public init(currentLevel: Int = -1, currentState: BatteryState = .unplugged, cycleLevelState: TimeInterval = 0, lowPowerMode: Bool = false) {
        self.currentLevel = currentLevel
        self.currentState = currentState
        self.lowPowerMode = lowPowerMode
        self.cycleLevelState = cycleLevelState
        
        guard cycleLevelState > 0 else {
            return // no need to create timer if no cycle level
        }
        // create and schedule timer (no need to keep reference)
        _ = Timer.scheduledTimer(withTimeInterval: cycleLevelState, repeats: true) { timer in
            switch self.currentState {
            case .unknown:
                // This really should never happen.  But if it does, go ahead and invalidate the timer.
                timer.invalidate()
            case .charging:
                self.currentLevel+=1
                if self.currentLevel > 99 {
                    self.currentState = .full
                }
            case .full:
                // Keep in full state for a few seconds
                self.currentLevel+=1
                if self.currentLevel > 104 {
                    self.currentState = .unplugged // start to discharge
                }
            case .unplugged:
                // discharge
                self.currentLevel-=1
                if self.currentLevel < 1 {
                    self.currentState = .charging
                }
            }
        }
    }
    
    public convenience init(snapshot: BatterySnapshot) {
        self.init(currentLevel: snapshot.currentLevel, currentState: snapshot.currentState, lowPowerMode: snapshot.lowPowerMode)
    }
    public var snapshot: BatterySnapshot {
        return BatterySnapshot(currentLevel: currentLevel, currentState: currentState, lowPowerMode: lowPowerMode)
    }
    

    public static let missing = MockBattery(currentLevel: -1, currentState: .unknown)
    public static let animated = MockBattery(currentLevel: 50, cycleLevelState: 0.1)
    public static let mocks = mocksFor(lowPowerMode: false)
    public static func mocksFor(lowPowerMode: Bool) -> [MockBattery] {
        Self.animated.lowPowerMode = lowPowerMode
        var mocks = [Self.animated]
        mocks += BatterySnapshot.mocks.map { mock in
            MockBattery(currentLevel: mock.currentLevel, currentState: mock.currentState, lowPowerMode: lowPowerMode)
        }
        return mocks
    }
}

public class DeviceBattery: Battery {
    public static let current = DeviceBattery() // only time this is initialized typically
        
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
    public func monitor(_ monitor: @escaping BatteryMonitor) {
        monitors.append(monitor)
        monitoring = true // enable monitoring from this point forward regardless of previous state
        // create observers for changes
#if os(watchOS) || os(tvOS)
        // Apparently this can't be observed on watchOS or tvOS (which makes sense) :(
#elseif canImport(UIKit) // only supported on iOS, macCatalyst, and visionOS
        // add observer for both battery level and battery state
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: OperationQueue.main
        ) { notification in
            // Do your work after received notification
            self._triggerBatteryUpdate(.level)
        }
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: OperationQueue.main
        ) { notification in
            // Do your work after received notification
            self._triggerBatteryUpdate(.state)
        }
//#if targetEnvironment(macCatalyst)
//Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
//    self.objectWillChange.send()
//    print("Manual notification Update \(Date().timeIntervalSinceReferenceDate)")
//}
//#endif
#else
        // If we don't have access to UIDevice or WKInterfaceDevice, this will be undefined
#endif
        // This way catalyst which also supports UIKit will also post these notifications
#if os(macOS) || targetEnvironment(macCatalyst)
        // https://stackoverflow.com/questions/51275093/is-there-a-battery-level-did-change-notification-equivalent-for-kiopscurrentcapa
        let loop = IOPSNotificationCreateRunLoopSource({ _ in
            // Perform usual battery status fetching
            // self can't be captured in C function
            DeviceBattery.current._triggerBatteryUpdate(.level)
            // trigger both just in case
            DeviceBattery.current._triggerBatteryUpdate(.state)
//            print("IOPSNotification for level and state")
        }, nil).takeRetainedValue() as CFRunLoopSource
        CFRunLoopAddSource(CFRunLoopGetCurrent(), loop, .defaultMode)
#endif
        // MacOS 11 and Linux are the only systems that wouldn't support this notification
#if canImport(Combine)
        if #available(iOS 9.0, macOS 12.0, macCatalyst 13.1, tvOS 9.0, watchOS 2.0, visionOS 1.0, *) {
            NotificationCenter.default.addObserver(
                forName: Notification.Name.NSProcessInfoPowerStateDidChange,
                object: nil,
                queue: OperationQueue.main
            ) { notification in
                //                print("NSProcessInfoPowerStateDidChange notification")
                // Do your work after received notification
                self._triggerBatteryUpdate(.lowPowerMode)
            }
        }
#endif
    }
    
    private func _triggerBatteryUpdate(_ notificationType: BatteryChangeType) {
        // Do your work after received notification
        for monitor in self.monitors {
            monitor(self, notificationType)
        }
    }
    
#if os(macOS) || targetEnvironment(macCatalyst)
    // TODO: Clean up unnecessary code.  Figure out "best" way.
    private func _levelPluggedIn() -> (level: Int, pluggedIn: Bool) {
//        print("IOKit version")
        // thanks to https://github.com/thebarbican19/BatteryBoi
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        var level = -1
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                
                if description["Type"] as? String == kIOPSInternalBatteryType {
                    let capacity = description[kIOPSCurrentCapacityKey] as? Int ?? -1
                    //print("Current level set: \(capacity)")
                    level = capacity
                    break
                }
            }
        }
        // This works, but below is better for exact state
//        if (!(IOPSCopyExternalPowerAdapterDetails() != nil)) {
//            print("not plugged in")
//        } else {
//            print("plugged in")
//        }
        let psInfo = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let psList = IOPSCopyPowerSourcesList(psInfo).takeRetainedValue() as [CFTypeRef]

        var pluggedIn = true // assume true for macs without battery
        for ps in psList {
//            print(ps)
            if let psDesc = IOPSGetPowerSourceDescription(psInfo, ps).takeUnretainedValue() as? [String: Any] {
                if //let type = psDesc[kIOPSTypeKey] as? String,
                    //                   let isCharging = (psDesc[kIOPSIsChargingKey] as? Bool) {
                    //                   print(type, "is charging:", isCharging)
                    let powerSource = (psDesc[kIOPSPowerSourceStateKey] as? String) {
//                    print("Power Source: \(powerSource)")
                    if powerSource == "AC Power" {
//                        if let capacity = psDesc[kIOPSCurrentCapacityKey] as? Int, capacity == 100 {
//                            print("Capacity: \(capacity), Level: \(level)")
//                            // TODO: Update current level
//                            return .full
//                        }
//                        return .charging
                    } else {
                        pluggedIn = false
                    }
//                    return .unplugged
                }
            }
        }
//        return .unknown
//        if PowerDetail["Power Source State"] == "AC Power" {
//            if PowerDetail["Current Capacity"] == 100 {
//                return .full
//            }
//            return .charging
//        } else {
//            return .unplugged
//        }
        return (level, pluggedIn)
    }
#endif
    
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
        return _levelPluggedIn().level
#elseif canImport(UIKit) && !os(tvOS) // UIDevice support
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
//        print("state monitoring")
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
        //        print("UIDevice version")
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
#elseif canImport(IOKit)
        let (level, pluggedIn) = _levelPluggedIn()
        if pluggedIn {
            if level == 100 {
                return .full
            }
            return .charging
        }
        return .unplugged
#else
        // If we don't have access to UIDevice or WKInterfaceDevice, this gets ignored
        return .unknown
#endif
    }
    
    /// The user enabled Low Power mode
    public var lowPowerMode: Bool {
        if #available(macOS 12.0, *) {
#if canImport(Combine)
            return ProcessInfo.processInfo.isLowPowerModeEnabled
#else
            return false
#endif
        } else {
            // Fallback on earlier versions
            return false
        }
    }
}

#if canImport(Combine)
/// Mirrors the DeviceBattery but automatically updates and monitors for changes rather than pulling staticly.
public class MonitoredDeviceBattery: Battery {
    public static let current = MonitoredDeviceBattery() // only time this is initialized typically
    
    @Published public var currentLevel: Int = -1
    @Published public var currentState: BatteryState = .unplugged
    @Published public var lowPowerMode: Bool = false
    
    private init() {
        // enable monitoring for self
        self.monitor { battery, changeType in
            switch changeType {
            case .level:
                // update local level cache
                self.updateLevel()
            case .state:
                // update local state cache
                self.updateState()
            case .lowPowerMode:
                // update local lowPowerMode cache
                self.updateLowPowerMode()
            }
        }
        // make sure after init we have the current values
        updateLevel()
        updateState()
        updateLowPowerMode()
    }
    
    func updateLevel() {
        currentLevel = DeviceBattery.current.currentLevel
    }
    
    func updateState() {
        currentState = DeviceBattery.current.currentState
    }
    
    func updateLowPowerMode() {
        lowPowerMode = DeviceBattery.current.lowPowerMode
    }
    
    /// Probably not needed directly, but here to wrap DeviceBattery.current.monitoring (which should always be true due to this monitoring)
    public var monitoring: Bool {
        get {
            DeviceBattery.current.monitoring
        }
        set {
            DeviceBattery.current.monitoring = newValue
        }
    }
    
    public func monitor(_ monitor: @escaping BatteryMonitor) {
        DeviceBattery.current.monitor(monitor)
    }
}
#endif
