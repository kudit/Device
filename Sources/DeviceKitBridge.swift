/**
 For legacy compatibility with DeviceKit implementations.
 Thanks to original project:
 https://github.com/dennisweissmann/DeviceKit
 */

#if canImport(Foundation)
import Foundation
import Compatibility

/**
 Previous implementation for testing for simulator was to lookup in cases.  New version actually tests the bundle to see if we're running in a simulator.
 */

public extension Device {    
    /// Returns diagonal screen length in inches
    var diagonal: Double {
        guard let screen = self.screen else {
            return -1
        }
        return screen.diagonal ?? -1
    }
    
    /// Returns screen ratio as a tuple.  May need to reduce as will return a resolution.
    @available(*, deprecated, message: "Please let us know how you're using this and why this might be necessary vs querying the screen dimensions.")
    var screenRatio: (Int, Int) {
        guard let screen = self.screen else {
            return (-1,-1)
        }
        let resolution = screen.resolution
        let ratio = resolution.ratio
        return (ratio.width, ratio.height)
    }
    
    /// The brightness level of the screen (between 0 and 100).  Only supported on iOS and macCatalyst.  Returns -1 if not supported.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    @MainActor
    var screenBrightness: Int {
        if let brightness = Device.current.brightness {
            return Int(brightness * 100)
        } else {
            return -1
        }
    }
    
    /// allX static functions not included.  If you have a use case that needs any of these rather than testing, please let us know.
    
    /// Returns whether or not the device has Touch ID
    @available(*, deprecated, message: "Check instead for biometrics property.")
    var isTouchIDCapable: Bool {
        return biometrics == .touchID
    }
    
    /// Returns whether or not the device has Face ID
    @available(*, deprecated, message: "Check instead for biometrics property.")
    var isFaceIDCapable: Bool {
        return biometrics == .faceID
    }
    
    /// Returns whether or not the device has any biometric sensor (i.e. Touch ID or Face ID)
    var hasBiometricSensor: Bool {
        if let biometrics, biometrics != .none {
            return true
        }
        return false
    }
    
    /// Returns whether or not the device has a sensor housing.
    @available(*, deprecated, message: "If you need this, please explain the use-case.")
    var hasSensorHousing: Bool {
        return biometrics == .faceID
    }
    /// Returns whether or not the device has a screen with rounded corners.
    @available(*, deprecated, message: "If you need this, please explain the use-case.  If needed, we should probably mark it in the device definitions since this likely isn't available in the system.")
    var hasRoundedDisplayCorners: Bool {
        return biometrics == .faceID
    }
        
    /// Returns whether or not the device has 3D Touch support.
    @available(*, deprecated, renamed: "hasForce3dTouchSupport")
    var has3dTouchSupport: Bool {
        return hasForce3dTouchSupport
    }
    
    /// Returns whether or not the device has 5G support.
    @available(*, deprecated, message: "If you need this, please explain the use-case.  Can test .cellular == .fiveG")
    var has5gSupport: Bool {
        return cellular == .fiveG
    }
    
    /// Returns whether or not the device has Force Touch support.
    @available(*, deprecated, renamed: "hasForce3dTouchSupport")
    var hasForceTouchSupport: Bool {
        return hasForce3dTouchSupport
    }
    
    /// Returns whether the current device is a SwiftUI preview canvas
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    @available(*, deprecated, renamed: "Device.current.isPreview")
    @MainActor
    var isCanvas: Bool? {
        return Device.current.isPreview
    }
    
    /// Returns whether the device is any of the simulator
    /// Useful when there is a need to check and skip running a portion of code (location request or others)
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    @available(*, deprecated, renamed: "Device.current.isSimulator")
    @MainActor
    var isSimulator: Bool {
        return Device.current.isSimulator
    }
    
    /**
     This method saves you in many cases from the need of updating your code with every new device.
     Most uses for an enum like this are the following:
     
     ```
     switch Device.current {
     case .iPodTouch5, .iPodTouch6: callMethodOnIPods()
     case .iPhone4, iPhone4s, .iPhone5, .iPhone5s, .iPhone6, .iPhone6Plus, .iPhone6s, .iPhone6sPlus, .iPhone7, .iPhone7Plus, .iPhoneSE, .iPhone8, .iPhone8Plus, .iPhoneX: callMethodOnIPhones()
     case .iPad2, .iPad3, .iPad4, .iPadAir, .iPadAir2, .iPadMini, .iPadMini2, .iPadMini3, .iPadMini4, .iPadPro: callMethodOnIPads()
     default: break
     }
     ```
     This code can now be replaced with
     
     ```
     let device = Device.current
     if device.isOneOf(Device.allPods) {
     callMethodOnIPods()
     } else if device.isOneOf(Device.allPhones) {
     callMethodOnIPhones()
     } else if device.isOneOf(Device.allPads) {
     callMethodOnIPads()
     }
     ```
     
     Note, the modern way of doing this would be to switch on the device's idiom to do things based off of the idiom.
     
     - parameter devices: An array of devices.
     
     - returns: Returns whether the current device is one of the passed in ones.
     */
    @available(*, deprecated, message: "Check the device's idiom rather than passing a list of devices.")
    func isOneOf(_ devices: [Device]) -> Bool {
        return devices.contains { $0 == self }
    }
    
    /// PPI (Pixels per Inch) on the current device's screen (if applicable). When the device is not applicable this property returns nil.
    var ppi: Int? {
        return screen?.ppi
    }
}

// MARK: Equatable
extension Device: Equatable {
    
    /// Compares two devices.
    ///
    /// - parameter lhs: A device.
    /// - parameter rhs: Another device.
    ///
    /// - returns: `true` iff the underlying identifier is the same.
    public static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.officialName == rhs.officialName // assumes official names are unique?  Identifiers may or may not be the same if current device has one identifier and comparing device with multiple identifiers.  Resulting officialName should be unique though...
        // but go ahead and make sure other fields match
        && lhs.identifiers == rhs.identifiers
        && lhs.models == rhs.models
        && lhs.supportId == rhs.supportId
    }
}

// MARK: Battery
#if os(iOS) || os(watchOS)
@available(iOS 8.0, watchOS 4.0, *)
public extension Device {
    /**
     This enum describes the state of the battery.  This should not be used as there is no unknown or no-battery state.
     
     - Full:      The device is plugged into power and the battery is 100% charged or the device is the iOS Simulator.
     - Charging:  The device is plugged into power and the battery is less than 100% charged.
     - Unplugged: The device is not plugged into power; the battery is discharging.
     */
    enum BatteryState: Equatable, CaseNameConvertible, Sendable { // cannot conform due to @MainActor isolation: CustomStringConvertible, 
        /// The device is plugged into power and the battery is 100% charged or the device is the iOS Simulator.
        case full
        /// The device is plugged into power and the battery is less than 100% charged.
        /// The associated value is in percent (0—100).
        case charging(Int)
        /// The device is not plugged into power; the battery is discharging.
        /// The associated value is in percent (0—100).
        case unplugged(Int)
        
        @available(iOS 13.0, watchOS 6, *)
        @available(*, deprecated, message: "If you need this, please explain the use-case.  Should use Device.current.battery to get state or level or monitor for changes.")
        @MainActor
        fileprivate init() {
            guard let battery = Device.current.battery else {
                self = .full
                return
            }
            let batteryLevel = battery.currentLevel
            let state = battery.currentState
            switch state {
            case .unknown: self = .full // this seems like the wrong behavior which is why this is deprecated.
            case .charging: self = .charging(batteryLevel)
            case .full: self = .full
            case .unplugged: self = .unplugged(batteryLevel)
                //            @unknown default:
                //                self = .unknown // To cover any future additions for which DeviceKit might not have updated yet.
            }
        }
        
        /// The user enabled Low Power mode
        @available(iOS 13.0, watchOS 6, *)
        @MainActor
        public var lowPowerMode: Bool {
            return Device.current.battery?.lowPowerMode ?? false
        }
        
        /// Provides a textual representation of the battery state.
        /// Examples:
        /// ```
        /// Battery level: 90%, device is plugged in.
        /// Battery level: 100 % (Full), device is plugged in.
        /// Battery level: \(batteryLevel)%, device is unplugged.
        /// ```
        @available(iOS 13.0, watchOS 6, *)
        @MainActor
        public var description: String {
            return Device.current.battery?.description ?? "No Battery"
        }
    }
    
    /// The state of the battery
    @available(iOS 13.0, watchOS 6, *)
    @available(*, deprecated, message: "If you need this, please explain the use-case.  Should use Device.current.battery to get state or level or monitor for changes.")
    @MainActor
    var batteryState: BatteryState? {
        return BatteryState()
    }
    
    /// Battery level ranges from 0 (fully discharged) to 100 (100% charged).
    @available(iOS 13.0, watchOS 6, *)
    @available(*, deprecated, message: "If you need this, please explain the use-case.  Should use Device.current.battery to get state or level or monitor for changes.")
    @MainActor
    var batteryLevel: Int? {
        return Device.current.battery?.currentLevel
    }
    
}
#endif

// MARK: Device.Batterystate: Comparable
//#if os(iOS) || os(watchOS) || os(macOS) || targetEnvironment(macCatalyst)
//@available(iOS 8.0, watchOS 4.0, *)
//extension BatteryState: Comparable {
//    /// Tells if two battery states are equal.
//    ///
//    /// - parameter lhs: A battery state.
//    /// - parameter rhs: Another battery state.
//    ///
//    /// - returns: `true` iff they are equal, otherwise `false`
//    public static func == (lhs: Device.BatteryState, rhs: Device.BatteryState) -> Bool {
//        return lhs.description == rhs.description
//    }
//
//    /// Compares two battery states.
//    ///
//    /// - parameter lhs: A battery state.
//    /// - parameter rhs: Another battery state.
//    ///
//    /// - returns: `true` if rhs is `.Full`, `false` when lhs is `.Full` otherwise their battery level is compared.
//    public static func < (lhs: Device.BatteryState, rhs: Device.BatteryState) -> Bool {
//        switch (lhs, rhs) {
//        case (.full, _): return false // return false (even if both are `.Full` -> they are equal)
//        case (_, .full): return true // lhs is *not* `.Full`, rhs is
//        case let (.charging(lhsLevel), .charging(rhsLevel)): return lhsLevel < rhsLevel
//        case let (.charging(lhsLevel), .unplugged(rhsLevel)): return lhsLevel < rhsLevel
//        case let (.unplugged(lhsLevel), .charging(rhsLevel)): return lhsLevel < rhsLevel
//        case let (.unplugged(lhsLevel), .unplugged(rhsLevel)): return lhsLevel < rhsLevel
//        default: return false // compiler won't compile without it, though it cannot happen
//        }
//    }
//}
//#endif

#if os(iOS)
public extension Device {
    // MARK: Orientation
    
    /// Defaults to `landscape` if we do not have a screen or cannot get the orientation.
    @available(iOS 13.0, *)
    @MainActor
    var orientation: Screen.Orientation {
        return Device.current.screenOrientation ?? .unknown
    }
}
#endif

#if os(iOS)
// MARK: Apple Pencil
/// NOTE: This is for compatibility support.  Query the supportedPencils property instead for more complete results.
extension Device {
    /**
     This option set describes the current Apple Pencils
     - firstGeneration:  1st Generation Apple Pencil
     - secondGeneration: 2nd Generation Apple Pencil
     */
    public struct ApplePencilSupport: OptionSet, Sendable {
        
        public let rawValue: UInt
        
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        public static let firstGeneration = ApplePencilSupport(rawValue: 0x01)
        public static let secondGeneration = ApplePencilSupport(rawValue: 0x02)
    }
    
    /// Returns supported version of the Apple Pencil
    @available(*, deprecated, message: "This method is for legacy support and doesn't support newer Apple Pencils.  Cast to iPad and query supported pencils if this matters.")
    public var applePencilSupport: ApplePencilSupport {
        guard let pad = iPad(device: self) else { // will return nil if not an iPad device.
            return []
        }
        if pad.pencils.contains(.secondGeneration) {
            return .secondGeneration
        }
        if pad.pencils.contains(.firstGeneration) {
            return .firstGeneration
        }
        return []
    }
}
#endif

extension Device {
    /// Returns whether or not the current device has a camera
    public var hasCamera: Bool {
        return capabilities.cameras.count > 0
    }
    
}

// MARK: DiskSpace
extension Device {
    /// All volumes capacity information in bytes.
    @available(iOS 11.0, *)
    @available(*, deprecated, message: "If you need this, please let us know why.")
    public static var volumes: [URLResourceKey: Int64]? {
#if os(tvOS) || os(watchOS) || !canImport(Combine)
            return nil
#else
        let rootURL = URL(fileURLWithPath: NSHomeDirectory())
        do {
            let values = try rootURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey,
                                                              .volumeAvailableCapacityKey,
                                                              .volumeAvailableCapacityForOpportunisticUsageKey,
                                                              .volumeTotalCapacityKey
            ])
            return values.allValues.mapValues {
                if let int = $0 as? Int64 {
                    return int
                }
                if let int = $0 as? Int {
                    return Int64(int)
                }
                return 0
            }
        } catch {
            return nil
        }
#endif
    }
}
#endif
