import Foundation
#if os(watchOS)
import WatchKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(IOKit)
import IOKit
#endif

// String constants for SF Symbols
public extension String {
    static let symbolUnknownEnvironment = "questionmark.circle"
    static let symbolSimulator = "squareshape.squareshape.dotted"
    static let symbolPlayground = "swift"
    static let symbolPreview = "curlybraces.square"
    static let symbolRealDevice = "square.fill"
    static let symbolDesignedForiPad = "ipad.badge.play"
    static let symbolMacCatalyst = "macwindow.on.rectangle"
    static let symbolUnknownDevice = "questionmark.square.dashed"
}

public extension Device {
    /// An object representing the current device this software is running on.
    static var current: any CurrentDevice = ActualHardwareDevice() // singleton representing the current device but separated so that we can replace or mock
    enum Environment: CaseIterable, DeviceAttributeExpressible {
        case realDevice, simulator, playground, preview, designedForiPad, macCatalyst
        
        static public var allCases: [Device.Environment] {
            var cases = [Environment.realDevice, .simulator, .playground, .preview]
            if [.mac, .vision].contains(Device.current.idiom) {
                cases += [.designedForiPad]
                if Device.current.idiom == .mac {
                    cases += [.macCatalyst]
                }
            }
            return cases
        }
        
        public var symbolName: String {
            switch self {
            case .realDevice:
                return .symbolRealDevice
            case .simulator:
                return .symbolSimulator
            case .playground:
                return .symbolPlayground
            case .preview:
                return .symbolPreview
            case .designedForiPad:
                return .symbolDesignedForiPad
            case .macCatalyst:
                return .symbolMacCatalyst
            }
        }
        
        /// String Description for environment
        public var label: String {
            switch self {
            case .realDevice:
                return "Real Device"
            case .simulator:
                return "Simulator"
            case .playground:
                return "Playground"
            case .preview:
                return "Preview"
            case .designedForiPad:
                return "Designed for iPad"
            case .macCatalyst:
                return "Mac Catalyst"
            }
        }
        
        public func test(device: any CurrentDevice) -> Bool {
            switch self {
            case .realDevice:
                return device.isRealDevice
            case .simulator:
                return device.isSimulator
            case .playground:
                return device.isPlayground
            case .preview:
                return device.isPreview
            case .designedForiPad:
                return device.isDesignedForiPad
            case .macCatalyst:
                return device.isMacCatalyst
            }
        }
    }
}

public enum ThermalState: SymbolRepresentable {
    case nominal, fair, serious, critical
    public var symbolName: String {
        switch self {
        case .nominal:
            return "thermometer.medium.slash"
        case .fair:
            return "thermometer.low"
        case .serious:
            return "thermometer.medium"
        case .critical:
            return "thermometer.high"
        }
    }
    var processInfoThermalState: ProcessInfo.ThermalState {
        switch self {
        case .nominal:
            return .nominal
        case .fair:
            return .fair
        case .serious:
            return .serious
        case .critical:
            return .critical
        }
    }
}
public extension ProcessInfo.ThermalState {
    var thermalState: ThermalState {
        switch self {
        case .nominal:
            return .nominal
        case .fair:
            return .fair
        case .serious:
            return .serious
        case .critical:
            return .critical
        @unknown default:
            return .nominal
        }
    }
}

//#if canImport(Observable)
//@Observable
//#endif // TODO: this is only supported in iOS 17+ so wait to implement until we no longer need backwards compatibility
public protocol CurrentDevice: ObservableObject, DeviceType, Identifiable {
    // Environment
    /// Returns `true` if running on the simulator vs actual device.
    var isSimulator: Bool { get }
    /// Returns `true` if running in Swift Playgrounds.
    var isPlayground: Bool { get }
    /// Returns `true` if running in an XCode or Swift Playgrounds #Preview macro.
    var isPreview: Bool { get }
    /// Returns `true` if NOT running in preview, playground, or simulator.
    var isRealDevice: Bool { get }
    /// Returns `true` if Built for iPad mode not a native mode (for macOS and visionOS)
    var isDesignedForiPad: Bool { get }
    /// Returns `true` if is macCatalyst app on macOS
    var isMacCatalyst: Bool { get }
    
    // Description
    /// Gets the identifier from the system, such as "iPhone7,1".
    var identifier: String { get }
    /// The name identifying the device (e.g. "Ben's iPhone").
    /// As of iOS 16, this will return a generic String like "iPhone", unless your app has additional entitlements.
    /// See the follwing link for more information: https://developer.apple.com/documentation/uikit/uidevice/1620015-name
    var name: String { get } // should be automatic since DeviceType defines name property.
    /// The name of the operating system running on the device represented by the receiver (e.g. "iOS" or "tvOS").
    var systemName: String { get }
    /// The current version of the operating system (e.g. 8.4 or 9.2).
    var systemVersion: String { get }
    /// The model of the device (e.g. "iPhone" or "iPod Touch").
    var model: String { get }
    /// The model of the device as a localized string.
    var localizedModel: String { get }
    
    // Screen Properties
    /// Returns if the screen is zoomed in.  `false` if not applicable or no screen.
    var isZoomed: Bool { get }
    /// True when a Guided Access session is currently active; otherwise, false.
    var isGuidedAccessSessionActive: Bool { get }
    /// The brightness level of the screen from 0.0 to 1.0 (can be set)
    var brightness: Double? { get set }
    /// Returns the screen orientation if applicable or `nil`
    var screenOrientation: Screen.Orientation? { get }
    
    // Power and hardware
    /// Returns a battery object that can be monitored or queried for live data if a battery is present on the device.  If not, this will return `nil`.  Needed to be a concrete type for use in BatteryView.
    var battery: (any Battery)? { get } //MonitoredDeviceBattery? { get }
    /// Ability to change/get the idle timeout setting.
    var isIdleTimerDisabled: Bool { get set }
    /// When called, will automatically start monitoring the battery state to disable idle timer when plugged in.
    func disableIdleTimerWhenPluggedIn()
    /// Returns the current thermal state of the system (or nil if could not be determined)
    var thermalState: ThermalState { get }
    
    // Storage Info
    /// The volume’s total capacity in bytes.
    var volumeTotalCapacity: Int64? { get }
    /// The volume’s available capacity in bytes.
    var volumeAvailableCapacity: Int64? { get }
    /// The volume’s available capacity in bytes for storing important resources.
    var volumeAvailableCapacityForImportantUsage: Int64? { get }
    /// The volume’s available capacity in bytes for storing nonessential resources.
    var volumeAvailableCapacityForOpportunisticUsage: Int64? { get }
    
    func enableMonitoring(frequency: TimeInterval)
}
extension ActualHardwareDevice { // Should be CurrentDevice but causes error in Swift Playgrounds.  Perhaps fix this in the future?  Error: "Replaced accessor for 'description' occurs in multiple places"
    /// Description (includes current identifier since device might have multiple).
    public var description: String {
        let environments = Device.Environment.allCases.map {
            if $0 != .realDevice && $0.test(device: self) {
                return " (\($0.label))"
            } else {
                return "" //  H(.\($0.caseName))
            }
        }.joined()
        var description = """
Device: \(officialName)
Name: "\(name)"
Model: \(identifier) running \(systemName) \(systemVersion)\(environments)
Thermal State: \(String(describing: thermalState))

"""
        if let battery {
            description += battery.description + "\n"
        }
        description += """
Volume Total Capacity: \(volumeTotalCapacity?.byteString(.file) ?? "n/a")
Volume Available Capacity for Important Resources: \(volumeAvailableCapacityForImportantUsage?.byteString(.file) ?? "n/a")
Volume Available Capacity for Opportunistic Resources: \(volumeAvailableCapacityForOpportunisticUsage?.byteString(.file) ?? "n/a")
Volume Available Capacity: \(volumeAvailableCapacity?.byteString(.file) ?? "n/a")
Device Framework Version: v\(Device.version)
"""
        return description
    }
}
/*
 Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { timer in
 callback()
 //            timer.invalidate()
 }
 */
public class MockDevice: CurrentDevice {
    public var device: Device = Device(idiom: .unspecified, officialName: "Mock Device", identifiers: ["Mock1,1"], supportId: "n/a", capabilities: [.screen(.undefined)], colors: [.blue], cpu: .unknown)
    
    public func enableMonitoring(frequency: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.objectWillChange.send()
        }
    }
    
    public var cycleAnimation: TimeInterval
    private var brightnessIncreasing = false
    @Published internal var updateCount = 0
    public init(
        device: Device? = nil,
        isSimulator: Bool = false,
        isPlayground: Bool = false,
        isPreview: Bool = false,
        isRealDevice: Bool = false,
        isDesignedForiPad: Bool = false,
        isMacCatalyst: Bool = false,
        
        identifier: String = "MOCK1,1",
        name: String = "Mock's Device",
        systemName: String = "mockOS",
        systemVersion: String = "00.00.00",
        model: String = "iMock",
        localizedModel: String = "iMocké",
        
        isZoomed: Bool = false,
        isGuidedAccessSessionActive: Bool = false,
        brightness: Double? = 0.5,
        screenOrientation: Screen.Orientation? = .landscape,
        
        battery: (any Battery)? = nil,
        isIdleTimerDisabled: Bool = false,
        thermalState: ThermalState = .nominal,
        
        volumeTotalCapacity: Int64? = 1_000_000_000_000, // 1TB
        volumeAvailableCapacity: Int64? = 90_000_000_000,
        volumeAvailableCapacityForImportantUsage: Int64? = 43_500_000_000,
        volumeAvailableCapacityForOpportunisticUsage: Int64? = 31_500_000_000,
        
        cycleAnimation: TimeInterval = 0)
    {
        if let device {
            self.device = device
        }
        self.isSimulator = isSimulator
        self.isPlayground = isPlayground
        self.isPreview = isPreview
        self.isRealDevice = isRealDevice
        self.isDesignedForiPad = isDesignedForiPad
        self.isMacCatalyst = isMacCatalyst
        self.identifier = identifier
        self.name = name
        self.systemName = systemName
        self.systemVersion = systemVersion
        self.model = model
        self.localizedModel = localizedModel
        self.isZoomed = isZoomed
        self.isGuidedAccessSessionActive = isGuidedAccessSessionActive
        self.brightness = brightness
        self.screenOrientation = screenOrientation
        self.battery = battery
        self.isIdleTimerDisabled = isIdleTimerDisabled
        self.thermalState = thermalState
        self.volumeTotalCapacity = volumeTotalCapacity
        self.volumeAvailableCapacity = volumeAvailableCapacity
        self.volumeAvailableCapacityForImportantUsage = volumeAvailableCapacityForImportantUsage
        self.volumeAvailableCapacityForOpportunisticUsage = volumeAvailableCapacityForOpportunisticUsage
        self.cycleAnimation = cycleAnimation
        
        guard cycleAnimation > 0 else {
            return // no need to create timer if no cycle animation
        }
        // create and schedule timer (no need to keep reference)
        Timer.scheduledTimer(withTimeInterval: cycleAnimation, repeats: true) { timer in
            self.update()
        }
    }
    
    public func update() {
        updateCount += 1 // increase
        let dup = Double(updateCount)
        let patch = updateCount % 100
        let minor = Int(dup / 100) % 100
        let major = Int(floor(dup / 10000))
        systemVersion = "\(major).\(minor).\(patch)"
        // brightness (every tick)
        if brightness == nil {
            brightness = 0.5
        }
        guard var brightness else {
            // This should never happen!
            fatalError("Brightness unable to be set!")
            // This really should never happen.  But if it does, go ahead and invalidate the timer.
            //            timer.invalidate()
        }
        if brightnessIncreasing {
            brightness += 0.01
            if brightness > 1 {
                brightness = 1
                brightnessIncreasing = false
            }
        } else {
            brightness -= 0.01
            if brightness < 0 {
                brightness = 0
                brightnessIncreasing = true
            }
        }
        self.brightness = brightness
        //        print("Update \(updateCount), brightness: \(brightness)")
        // zoomed (every 3 ticks)
        if updateCount % 7 == 0 {
            isZoomed = !isZoomed
        }
        // orientation (every 5 ticks)
        if updateCount % 11 == 0 {
            if screenOrientation == .portrait {
                screenOrientation = .landscape
            } else {
                screenOrientation = .portrait
            }
        }
        // guided access mode
        if updateCount % 17 == 0 {
            isGuidedAccessSessionActive = !isGuidedAccessSessionActive
        }
        // thermal state (every 7 ticks)
        if updateCount % 13 == 0 {
            switch thermalState {
            case .nominal:
                thermalState = .fair
            case .fair:
                thermalState = .serious
            case .serious:
                thermalState = .critical
            case .critical:
                thermalState = .nominal
            }
        }
    }
    
    public var isSimulator: Bool
    public var isPlayground: Bool
    public var isPreview: Bool
    public var isRealDevice: Bool
    public var isDesignedForiPad: Bool
    public var isMacCatalyst: Bool
    
    public var identifier: String
    public var name: String
    public var systemName: String
    public var systemVersion: String
    public var model: String
    public var localizedModel: String
    
    @Published public var isZoomed: Bool = false
    public var isGuidedAccessSessionActive: Bool = false
    @Published public var brightness: Double? = 0.5
    @Published public var screenOrientation: Screen.Orientation? = .landscape
    
    public var battery: (any Battery)? = nil
    public var isIdleTimerDisabled: Bool = false
    public func disableIdleTimerWhenPluggedIn() {
        // do nothing (this is Mock)
    }
    @Published public var thermalState: ThermalState = .nominal
    
    public var volumeTotalCapacity: Int64?
    public var volumeAvailableCapacity: Int64?
    public var volumeAvailableCapacityForImportantUsage: Int64?
    public var volumeAvailableCapacityForOpportunisticUsage: Int64?
    
    public var id: String {
        String(describing: self)
    }
    
    public static var mocks = [
        Device.current,
        MockDevice(battery: MockBattery.mocks[0], cycleAnimation: 0.1),
        MockDevice(),
        MockDevice(isSimulator: true, brightness: 0.25, battery: MockBattery.mocks[1], thermalState: .nominal),
        MockDevice(isPlayground: true, isGuidedAccessSessionActive: true, brightness: 0.0, battery: MockBattery.mocks[2], thermalState: .fair),
        MockDevice(isRealDevice: true, brightness: 0.75, battery: MockBattery.mocks[3], thermalState: .serious),
        MockDevice(isDesignedForiPad: true, isZoomed: true, brightness: 1.0, battery: MockBattery.mocks[4], thermalState: .critical),
        MockDevice(isMacCatalyst: true, brightness: 0.8, battery: MockBattery.mocks[5], thermalState: .fair),
    ]
    
}

// this is internal because it shouldn't be directly needed outside the framework.  Everything is exposed via CurrentDevice protocol.
// TODO: should this be a final class?
class ActualHardwareDevice: CurrentDevice {
    var device: Device
    
    public func enableMonitoring(frequency: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.objectWillChange.send()
            //            print("AHD Update \(Date().timeIntervalSinceReferenceDate)")
        }
    }
    
    init() {
        device = Device(identifier: identifier)
        // add screen orientation monitor (only supported by UIDevice which is fine)
#if canImport(UIKit)
#if os(iOS) // technically supported by mac catalyst as well but not sure when it would be ever used       NotificationCenter.default.addObserver(
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: OperationQueue.main
        ) { notification in
            // Do your work after received notification
            self.objectWillChange.send()
        }
#endif
#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
        NotificationCenter.default.addObserver(
            forName: UIScreen.brightnessDidChangeNotification,
            object: nil,
            queue: OperationQueue.main
        ) { notification in
            // Do your work after received notification
            self.objectWillChange.send()
        }
#endif
#endif
    }
    
    /// Returns `true` if running on the simulator vs actual device.
    public var isSimulator: Bool {
#if targetEnvironment(simulator)
        // your simulator code
        return true
#else
        // your real device code
        return false
#endif
    }
    
    // In macOS Playgrounds Preview: swift-playgrounds-dev-previews.swift-playgrounds-app.hdqfptjlmwifrrakcettacbhdkhn.501.KuditFramework
    // In macOS Playgrounds Running: swift-playgrounds-dev-run.swift-playgrounds-app.hdqfptjlmwifrrakcettacbhdkhn.501.KuditFrameworksApp
    // In iPad Playgrounds Preview: swift-playgrounds-dev-previews.swift-playgrounds-app.agxhnwfqkxciovauscbmuhqswxkm.501.KuditFramework
    // In iPad Playgrounds Running: swift-playgrounds-dev-run.swift-playgrounds-app.agxhnwfqkxciovauscbmuhqswxkm.501.KuditFrameworksApp
    // warning: {"message":"This code path does I/O on the main thread underneath that can lead to UI responsiveness issues. Consider ways to optimize this code path","antipattern trigger":"+[NSBundle allBundles]","message type":"suppressable","show in console":"0"}
    /// Returns `true` if running in Swift Playgrounds.
    var isPlayground: Bool {
        //print("Testing inPlayground: Bundles: \(Bundle.allBundles.map { $0.bundleIdentifier }.description)")
        if Bundle.allBundles.contains(where: { ($0.bundleIdentifier ?? "").contains("swift-playgrounds") }) {
            //print("in playground")
            return true
        } else {
            //print("not in playground")
            return false
        }
    }
    
    /// Returns `true` if running in an XCode or Swift Playgrounds #Preview macro.
    var isPreview: Bool {
        // TODO: Verify this works in Swift Playgrounds and not just XCode
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    /// Returns `true` if NOT running in preview, playground, or simulator.
    var isRealDevice: Bool {
        return !isPreview && !isPlayground && !isSimulator
    }
    
    /// Returns `true` if Built for iPad mode not a native mode (for macOS and visionOS)
    var isDesignedForiPad: Bool {
        // Check for mismatch between systemName and expected idiom based on identifier.
        if Device.current.idiom == .vision && Device.current.systemName == "iPadOS" {
            return true
        }
        // Note: this will be "false" under Catalyst which is what we want.
        if #available(watchOS 7.0, *) {
            return ProcessInfo().isiOSAppOnMac
        } else {
            // Fallback on earlier versions
            return false
        }
    }
    
    /// Returns `true` if is macCatalyst app on macOS
    var isMacCatalyst: Bool {
#if targetEnvironment(macCatalyst)
        return true
#else
        return false
#endif
    }
    
    // MARK: - Description Device Strings
    /// Gets the identifier from the system, such as "iPhone7,1".
    var identifier: String = {
#if os(macOS)
        let defaultPort: mach_port_t
        if #available(macOS 12.0, *) {
            defaultPort = kIOMainPortDefault
        } else {
            defaultPort = kIOMasterPortDefault
        }
        // kIOMasterPortDefault => kIOMainPortDefault
        let service = IOServiceGetMatchingService(defaultPort,
                                                  IOServiceMatching("IOPlatformExpertDevice"))
        var modelIdentifier: String?
        if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
            modelIdentifier = String(data: modelData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters)
        }
        
        IOObjectRelease(service)
        return modelIdentifier ?? "UnknownIdentifier"
#elseif targetEnvironment(macCatalyst)
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        
        var modelIdentifier: [CChar] = Array(repeating: 0, count: size)
        sysctlbyname("hw.model", &modelIdentifier, &size, nil, 0)
        
        return String(cString: modelIdentifier)
#else
        //        print(ProcessInfo().environment)
        if let identifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            // machine value is likely just arm64 so return the simulator identifier
            return identifier
        }
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
#endif
    }()
    
    /// The name identifying the device (e.g. "Dennis' iPhone").
    /// As of iOS 16, this will return a generic String like "iPhone", unless your app has additional entitlements.
    /// See the follwing link for more information: https://developer.apple.com/documentation/uikit/uidevice/1620015-name
    var name: String {
#if os(watchOS)
        return WKInterfaceDevice.current().name
#elseif canImport(UIKit)
        return UIDevice.current.name
#else
        return ProcessInfo().hostName
#endif
    }
    
    /// The name of the operating system running on the device represented by the receiver (e.g. "iOS" or "tvOS").
    var systemName: String {
#if os(watchOS)
        return WKInterfaceDevice.current().systemName
#elseif os(iOS)
        let systemName = UIDevice.current.systemName
        if idiom == .pad, #available(iOS 13, *), systemName == "iOS" {
            return "iPadOS"
        } else {
            return systemName
        }
#elseif canImport(UIKit)
        return UIDevice.current.systemName
#else
        return .unknown
#endif
    }
    
    /// The current version of the operating system (e.g. 8.4 or 9.2).
    var systemVersion: String {
#if os(watchOS)
        return WKInterfaceDevice.current().systemVersion
#elseif canImport(UIKit)
        return UIDevice.current.systemVersion
#else
        return "0.0"
#endif
    }
    
    /// The model of the device (e.g. "iPhone" or "iPod Touch").
    var model: String {
#if os(watchOS)
        return WKInterfaceDevice.current().model
#elseif canImport(UIKit)
        return UIDevice.current.model
#else
        return .unknown
#endif
    }
    
    /// The model of the device as a localized string.
    var localizedModel: String {
#if os(watchOS)
        return WKInterfaceDevice.current().localizedModel
#elseif canImport(UIKit)
        return UIDevice.current.localizedModel
#else
        return .unknown
#endif
    }
    
    // MARK: - Screen Properties
    
    /// Returns if the screen is zoomed in.
    public var isZoomed: Bool {
#if os(iOS) && !os(visionOS)
        if Int(UIScreen.main.scale.rounded()) == 3 {
            // Plus-sized
            return UIScreen.main.nativeScale > 2.7 && UIScreen.main.nativeScale < 3
        } else {
            return UIScreen.main.nativeScale > UIScreen.main.scale
        }
#else
        return false
#endif
    }
    
    /// True when a Guided Access session is currently active; otherwise, false.
    public var isGuidedAccessSessionActive: Bool {
#if os(iOS)
#if swift(>=4.2)
        return UIAccessibility.isGuidedAccessEnabled
#else
        return UIAccessibilityIsGuidedAccessEnabled()
#endif
#else
        return false
#endif
    }
    
    /// The brightness level of the screen (between 0.0 and 1.0).  Only supported on iOS and macCatalyst.  Returns nil if not supported.  Wrapper for UIScreen.main.brightness
    public var brightness: Double? {
        get {
            // https://stackoverflow.com/questions/40710544/get-current-screen-brightness
            // https://stackoverflow.com/questions/24264673/adjust-the-main-screen-brightness-using-swift/24264838#24264838
            // https://developer.apple.com/documentation/uikit/uiscreen/1617830-brightness
            
            // for macOS: TODO
            // https://stackoverflow.com/questions/67929644/getting-notified-when-the-screen-brightness-changes-in-macos
            
#if os(iOS) && !targetEnvironment(macCatalyst)
            let b = UIScreen.main.brightness
            if b < 0 {
                return nil
            }
            return b
            //#elseif canImport(IOKit)
            //            // Does not seem to work!
            //            var brightness: Float = 1.0
            //            var service: io_object_t = 1
            //            var iterator: io_iterator_t = 0
            //            let result: kern_return_t = IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"), &iterator)
            //            
            //            if result == kIOReturnSuccess {
            //                
            //                while service != 0 {
            //                    service = IOIteratorNext(iterator)
            //                    IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
            //                    IOObjectRelease(service)
            //                }
            //            }
            //            return Double(brightness)
#else
            return nil
#endif
        }
        set {
            if let newValue {
#if os(iOS) || targetEnvironment(macCatalyst)
                UIScreen.main.brightness = newValue
#elseif canImport(IOKit)
                let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
                IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, Float(newValue))
                IOObjectRelease(service)
#endif
            }
        }
    }
    
    /// Returns the screen orientation if applicable or `nil`
    var screenOrientation: Screen.Orientation? {
#if os(iOS) && !os(visionOS)
        if UIDevice.current.orientation.isPortrait {
            return .portrait
        } else {
            return .landscape
        }
#else
        return nil
#endif
    }
    
    // MARK: - Power & Hardware
    
    /// Returns a battery object that can be monitored or queried for live data if a battery is present on the device.  If not, this will return nil.
    var battery: (any Battery)? {
        if device.has(.battery) {
            return MonitoredDeviceBattery.current
        }
        return nil
    }
    
    @Published private var _isIdleTimerDisabled = false
    /// Ability to change/get the idle timeout setting.
    var isIdleTimerDisabled: Bool {
        get {
            _isIdleTimerDisabled
        }
        set {
            _isIdleTimerDisabled = newValue
            _disableIdleTimer(newValue)
        }
    }
    /// Actually disable the idle timer
    private func _disableIdleTimer(_ disabled: Bool = true) {
        // https://developer.apple.com/documentation/uikit/uiapplication/1623070-isidletimerdisabled
#if canImport(UIKit) && !os(watchOS)
        UIApplication.shared.isIdleTimerDisabled = disabled
#endif
    }
    @Published private var _disableIdleTimerWhenPluggedIn = false
    /// Automatically start monitoring the battery state to disable idle timer when plugged in and re-enable when unplugged.
    func disableIdleTimerWhenPluggedIn() {
        guard !_disableIdleTimerWhenPluggedIn else {
            // atttempting to disable idle timer multiple times.  This should only be set on launch.
            print("WARNING: attempting to disable idle timer when this has already been set.  You should only call this function once (probably at launch or main init).  Set a breakpoint to see why there's a duplicate call.")
            return
        }
        guard let battery = self.battery else {
            // attempting to disable idle timer when plugged in when we don't even have a battery.  Just ignore.
            return
        }
        _disableIdleTimerWhenPluggedIn = true // so we only do this once in case called multiple times.
        if battery.isPluggedIn {
            _disableIdleTimer()
        }
        battery.monitor { battery, changeType in
            // unnecessary when battery level changes, but it shouldn't really be much to repeat.
            if changeType == .state {
                self._disableIdleTimer(battery.isPluggedIn ? true : self._isIdleTimerDisabled)
                // don't disable timer when unplugged unless we've manually set it to always be disabled.  So when unplugged, re-enable idle timer unless we've set it to always disabled.
            }
        }
    }
    
    /// Returns the current thermal state of the system
    public var thermalState: ThermalState {
        return ProcessInfo().thermalState.thermalState
    }
    
    
    // MARK: - Storage Info
    
    /// Return the root url
    ///
    /// - returns: the NSHomeDirectory() url
    private let rootURL = URL(fileURLWithPath: NSHomeDirectory())
    
    /// The volume’s total capacity in bytes.
    public var volumeTotalCapacity: Int64? {
        if let vtc = (try? rootURL.resourceValues(forKeys: [.volumeTotalCapacityKey]))?.volumeTotalCapacity {
            return Int64(vtc)
        } else {
            return nil
        }
    }
    
    /// The volume’s available capacity in bytes.
    public var volumeAvailableCapacity: Int64? {
        if let vtc = (try? rootURL.resourceValues(forKeys: [.volumeAvailableCapacityKey]))?.volumeAvailableCapacity {
            return Int64(vtc)
        } else {
            return nil
        }
    }
    
    /// The volume’s available capacity in bytes for storing important resources.
    public var volumeAvailableCapacityForImportantUsage: Int64? {
#if os(tvOS) || os(watchOS)
        return nil
#else
        if #available(iOS 11.0, *) {
            return (try? rootURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]))?.volumeAvailableCapacityForImportantUsage
        } else {
            return nil
        }
#endif
    }
    
    /// The volume’s available capacity in bytes for storing nonessential resources.
    public var volumeAvailableCapacityForOpportunisticUsage: Int64? {
#if os(tvOS) || os(watchOS)
        return nil
#else
        if #available(iOS 11.0, *) {
            return (try? rootURL.resourceValues(forKeys: [.volumeAvailableCapacityForOpportunisticUsageKey]))?.volumeAvailableCapacityForOpportunisticUsage
        } else {
            return nil
        }
#endif
    }
    
}

#if canImport(SwiftUI)
import SwiftUI
@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("Animated Test") {
    List {
        ForEach(MockDevice.mocks, id: \.id) { mock in
            Section {
                CurrentDeviceInfoView(device: mock, includeStorage: false)
            }
        }
    }
}
#endif

