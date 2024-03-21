/**
 For legacy compatibility with DeviceKit implementations.
 Thanks to original project:
 https://github.com/dennisweissmann/DeviceKit
 */

import Foundation

/**
 Previous implementation for testing for simulator was to lookup in cases.  New version actually tests the bundle to see if we're running in a simulator.
 */

extension Device {
    /// Gets the identifier from the system, such as "iPhone7,1".
    public static var identifier: String = Device.current.identifier
    
    /// Returns diagonal screen length in inches
    public var diagonal: Double {
        guard let screen = self.screen else {
            return -1
        }
        return screen.diagonal ?? -1
    }
    
    /// Returns screen ratio as a tuple.  May need to reduce as will return a resolution.
    @available(*, deprecated, message: "Please let us know how you're using this and why this might be necessary vs querying the screen dimensions.")
    public var screenRatio: (width: Double, height: Double) {
        guard let screen = self.screen, let resolution = screen.resolution else {
            return (-1,-1)
        }
        return (Double(resolution.0), Double(resolution.1))
    }
    
    /// allX static functions not included.  If you have a use case that needs any of these rather than testing, please let us know.
    
    /// Returns whether or not the device has Touch ID
    @available(*, deprecated, message: "Check instead for biometrics property.")
    public var isTouchIDCapable: Bool {
        return biometrics == .touchID
    }
    
    /// Returns whether or not the device has Face ID
    @available(*, deprecated, message: "Check instead for biometrics property.")
    public var isFaceIDCapable: Bool {
        return biometrics == .faceID
    }
    
    /// Returns whether or not the device has any biometric sensor (i.e. Touch ID or Face ID)
    public var hasBiometricSensor: Bool {
        return biometrics != .none
    }
    
    /// Returns whether or not the device has a sensor housing.
    @available(*, deprecated, message: "If you need this, please explain the use-case.")
    public var hasSensorHousing: Bool {
        return biometrics == .faceID
    }
    /// Returns whether or not the device has a screen with rounded corners.
    @available(*, deprecated, message: "If you need this, please explain the use-case.  If needed, we should probably mark it in the device definitions since this likely isn't available in the system.")
    public var hasRoundedDisplayCorners: Bool {
        return biometrics == .faceID
    }
        
    /// Returns whether or not the device has 3D Touch support.
    @available(*, deprecated, renamed: "hasForce3dTouchSupport")
    public var has3dTouchSupport: Bool {
        return hasForce3dTouchSupport
    }
    
    /// Returns whether or not the device has 5G support.
    @available(*, deprecated, message: "If you need this, please explain the use-case.  Can test .cellular == .fiveG")
    public var has5gSupport: Bool {
        return cellular == .fiveG
    }
    
    /// Returns whether or not the device has Force Touch support.
    @available(*, deprecated, renamed: "hasForce3dTouchSupport")
    public var hasForceTouchSupport: Bool {
        return hasForce3dTouchSupport
    }
    
    /// Returns whether the current device is a SwiftUI preview canvas
    @available(*, deprecated, renamed: "Device.current.isPreview")
    public var isCanvas: Bool? {
        return Device.current.isPreview
    }
    
    /// Returns whether the device is any of the simulator
    /// Useful when there is a need to check and skip running a portion of code (location request or others)
    @available(*, deprecated, renamed: "Device.current.isSimulator")
    public var isSimulator: Bool {
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
    public func isOneOf(_ devices: [Device]) -> Bool {
        return devices.contains { $0 == self }
    }
    
    /// PPI (Pixels per Inch) on the current device's screen (if applicable). When the device is not applicable this property returns nil.
    public var ppi: Int? {
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
    @available(*, deprecated, message: "How is this used?  Is it necessary?")
    public static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.description == rhs.description
    }
}

// MARK: Battery
#if os(iOS) || os(watchOS)
@available(iOS 8.0, watchOS 4.0, *)
extension Device {
    /**
     This enum describes the state of the battery.  This should not be used as there is no unknown or no-battery state.
     
     - Full:      The device is plugged into power and the battery is 100% charged or the device is the iOS Simulator.
     - Charging:  The device is plugged into power and the battery is less than 100% charged.
     - Unplugged: The device is not plugged into power; the battery is discharging.
     */
    public enum BatteryState: CustomStringConvertible, Equatable {
        /// The device is plugged into power and the battery is 100% charged or the device is the iOS Simulator.
        case full
        /// The device is plugged into power and the battery is less than 100% charged.
        /// The associated value is in percent (0—100).
        case charging(Int)
        /// The device is not plugged into power; the battery is discharging.
        /// The associated value is in percent (0—100).
        case unplugged(Int)
        
        @available(*, deprecated, message: "If you need this, please explain the use-case.  Should use Device.current.battery to get state or level or monitor for changes.")
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
        public var description: String {
            switch self {
            case .charging(let batteryLevel): return "Battery level: \(batteryLevel)%, device is plugged in."
            case .full: return "Battery level: 100 % (Full), device is plugged in."
            case .unplugged(let batteryLevel): return "Battery level: \(batteryLevel)%, device is unplugged."
            }
        }
    }
    
    /// The state of the battery
    @available(*, deprecated, message: "If you need this, please explain the use-case.  Should use Device.current.battery to get state or level or monitor for changes.")
    public var batteryState: BatteryState? {
        return BatteryState()
    }
    
    /// Battery level ranges from 0 (fully discharged) to 100 (100% charged).
    @available(*, deprecated, message: "If you need this, please explain the use-case.  Should use Device.current.battery to get state or level or monitor for changes.")
    public var batteryLevel: Int? {
        return Device.current.battery?.currentLevel
    }
    
}
#endif

// MARK: Device.Batterystate: Comparable
#if os(iOS) || os(watchOS)
@available(iOS 8.0, watchOS 4.0, *)
extension Device.BatteryState: Comparable {
    /// Tells if two battery states are equal.
    ///
    /// - parameter lhs: A battery state.
    /// - parameter rhs: Another battery state.
    ///
    /// - returns: `true` iff they are equal, otherwise `false`
    public static func == (lhs: Device.BatteryState, rhs: Device.BatteryState) -> Bool {
        return lhs.description == rhs.description
    }
    
    /// Compares two battery states.
    ///
    /// - parameter lhs: A battery state.
    /// - parameter rhs: Another battery state.
    ///
    /// - returns: `true` if rhs is `.Full`, `false` when lhs is `.Full` otherwise their battery level is compared.
    public static func < (lhs: Device.BatteryState, rhs: Device.BatteryState) -> Bool {
        switch (lhs, rhs) {
        case (.full, _): return false // return false (even if both are `.Full` -> they are equal)
        case (_, .full): return true // lhs is *not* `.Full`, rhs is
        case let (.charging(lhsLevel), .charging(rhsLevel)): return lhsLevel < rhsLevel
        case let (.charging(lhsLevel), .unplugged(rhsLevel)): return lhsLevel < rhsLevel
        case let (.unplugged(lhsLevel), .charging(rhsLevel)): return lhsLevel < rhsLevel
        case let (.unplugged(lhsLevel), .unplugged(rhsLevel)): return lhsLevel < rhsLevel
        default: return false // compiler won't compile without it, though it cannot happen
        }
    }
}
#endif

#if os(iOS)
extension Device {
    // MARK: Orientation
    /**
     This enum describes the state of the orientation.
     - Landscape: The device is in Landscape Orientation
     - Portrait:  The device is in Portrait Orientation
     */
    public enum Orientation {
        case landscape
        case portrait
    }
    
    /// Defaults to true if we do not have a screen or cannot get the orientation.
    public var orientation: Orientation {
        if Device.current.screenOrientation?.isLandscape ?? true {
            return .landscape
        } else {
            return .portrait
        }
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
    public struct ApplePencilSupport: OptionSet {
        
        public var rawValue: UInt
        
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
        if pad.supportedPencils.contains(.secondGeneration) {
            return .secondGeneration
        }
        if pad.supportedPencils.contains(.firstGeneration) {
            return .firstGeneration
        }
        return []
    }
}
#endif

extension Device {
    /// Returns whether or not the current device has a camera
    public var hasCamera: Bool {
        return cameras > 0
    }
    
}

#if os(iOS)
// MARK: DiskSpace
extension Device {
    /// The volume’s total capacity in bytes.
    @available(*, deprecated, renamed: "Device.current.volumeTotalCapacity")
    public static var volumeTotalCapacity: Int? {
        Device.current.volumeTotalCapacity
    }
    
    /// The volume’s available capacity in bytes.
    @available(*, deprecated, renamed: "Device.current.volumeAvailableCapacity")
    public static var volumeAvailableCapacity: Int? {
        Device.current.volumeAvailableCapacity
    }
    
    /// The volume’s available capacity in bytes for storing important resources.
    @available(iOS 11.0, *)
    @available(*, deprecated, renamed: "Device.current.volumeAvailableCapacityForImportantUsage")
    public static var volumeAvailableCapacityForImportantUsage: Int64? {
        Device.current.volumeAvailableCapacityForImportantUsage
    }
    
    /// The volume’s available capacity in bytes for storing nonessential resources.
    @available(iOS 11.0, *)
    @available(*, deprecated, renamed: "Device.current.volumeAvailableCapacityForOpportunisticUsage")
    public static var volumeAvailableCapacityForOpportunisticUsage: Int64? {
        Device.current.volumeAvailableCapacityForOpportunisticUsage
    }
    
    /// All volumes capacity information in bytes.
    @available(iOS 11.0, *)
    @available(*, deprecated, renamed: "Device.current.volumes")
    public static var volumes: [URLResourceKey: Int64]? {
        Device.current.volumes
    }
}
#endif
