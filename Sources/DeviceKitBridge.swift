/**
 For legacy compatibility with DeviceKit implementations.
 Thanks to original project:
 https://github.com/dennisweissmann/DeviceKit
 */

import Foundation

/**
 Previous implementation for testing for simulator was to lookup in cases.  New version actually tests the bundle to see if we're running in a simulator.
 */

public extension Device {
    /// Gets the identifier from the system, such as "iPhone7,1".
    @available(*, deprecated, renamed: "current.identifier")
    @MainActor
    static let identifier: String = Device.current.identifier
    
    /// Ordered list of identifiers in DeviceKit definition file.  Used for migration export.
    /// iOS iPods, iPhones, iPads, HomePods, Apple TV, Apple Watch (doesn't include vision or macs)
    static let deviceKitOrder = [
        "iPod5,1",
        "iPod7,1",
        "iPod9,1",
        "iPhone3,1","iPhone3,2","iPhone3,3",
        "iPhone4,1",
        "iPhone5,1","iPhone5,2",
        "iPhone5,3","iPhone5,4",
        "iPhone6,1","iPhone6,2",
        "iPhone7,2",
        "iPhone7,1",
        "iPhone8,1",
        "iPhone8,2",
        "iPhone9,1","iPhone9,3",
        "iPhone9,2","iPhone9,4",
        "iPhone8,4",
        "iPhone10,1","iPhone10,4",
        "iPhone10,2","iPhone10,5",
        "iPhone10,3","iPhone10,6",
        "iPhone11,2",
        "iPhone11,4","iPhone11,6",
        "iPhone11,8",
        "iPhone12,1",
        "iPhone12,3",
        "iPhone12,5",
        "iPhone12,8",
        "iPhone13,2",
        "iPhone13,1",
        "iPhone13,3",
        "iPhone13,4",
        "iPhone14,5",
        "iPhone14,4",
        "iPhone14,2",
        "iPhone14,3",
        "iPhone14,6",
        "iPhone14,7",
        "iPhone14,8",
        "iPhone15,2",
        "iPhone15,3",
        "iPhone15,4",
        "iPhone15,5",
        "iPhone16,1",
        "iPhone16,2",
        "iPad1,1",
        "iPad2,1","iPad2,2","iPad2,3","iPad2,4",
        "iPad3,1","iPad3,2","iPad3,3",
        "iPad3,4","iPad3,5","iPad3,6",
        "iPad4,1","iPad4,2","iPad4,3",
        "iPad5,3","iPad5,4",
        "iPad6,11","iPad6,12",
        "iPad7,5","iPad7,6",
        "iPad11,3","iPad11,4",
        "iPad7,11","iPad7,12",
        "iPad11,6","iPad11,7",
        "iPad12,1","iPad12,2",
        "iPad13,18","iPad13,19",
        "iPad13,1","iPad13,2",
        "iPad13,16","iPad13,17",
        "iPad2,5","iPad2,6","iPad2,7",
        "iPad4,4","iPad4,5","iPad4,6",
        "iPad4,7","iPad4,8","iPad4,9",
        "iPad5,1","iPad5,2",
        "iPad11,1","iPad11,2",
        "iPad14,1","iPad14,2",
        "iPad6,3","iPad6,4",
        "iPad6,7","iPad6,8",
        "iPad7,1","iPad7,2",
        "iPad7,3","iPad7,4",
        "iPad8,1","iPad8,2","iPad8,3","iPad8,4",
        "iPad8,5","iPad8,6","iPad8,7","iPad8,8",
        "iPad8,9","iPad8,10",
        "iPad8,11","iPad8,12",
        "iPad13,4","iPad13,5","iPad13,6","iPad13,7",
        "iPad13,8","iPad13,9","iPad13,10","iPad13,11",
        "iPad14,3","iPad14,4",
        "iPad14,5","iPad14,6",
        "AudioAccessory1,1",
        "AudioAccessory5,1",
        "AudioAccessory6,1",
        "AppleTV5,3",
        "AppleTV6,2",
        "AppleTV11,1",
        "AppleTV14,1",
        "Watch1,1",
        "Watch1,2",
        "Watch2,6",
        "Watch2,7",
        "Watch2,3",
        "Watch2,4",
        "Watch3,1","Watch3,3",
        "Watch3,2","Watch3,4",
        "Watch4,1","Watch4,3",
        "Watch4,2","Watch4,4",
        "Watch5,1","Watch5,3",
        "Watch5,2","Watch5,4",
        "Watch6,1","Watch6,3",
        "Watch6,2","Watch6,4",
        "Watch5,9","Watch5,11",
        "Watch5,10","Watch5,12",
        "Watch6,6","Watch6,8",
        "Watch6,7","Watch6,9",
        "Watch6,14","Watch6,16",
        "Watch6,15","Watch6,17",
        "Watch6,10","Watch6,12",
        "Watch6,11","Watch6,13",
        "Watch6,18",
        "Watch7,3",
        "Watch7,4",
        "Watch7,5",
    ]
    
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
    @available(*, deprecated, renamed: "Device.current.isPreview")
    @MainActor
    var isCanvas: Bool? {
        return Device.current.isPreview
    }
    
    /// Returns whether the device is any of the simulator
    /// Useful when there is a need to check and skip running a portion of code (location request or others)
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
    @available(*, deprecated, message: "How is this used?  Is it necessary?")
    public static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.officialName == rhs.officialName // assumes official names are unique?  Identifiers may or may not be the same if current device has one identifier and comparing device with multiple identifiers.  Resulting officialName should be the same though...
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
    enum BatteryState: CustomStringConvertible, Equatable, CaseNameConvertible, Sendable {
        /// The device is plugged into power and the battery is 100% charged or the device is the iOS Simulator.
        case full
        /// The device is plugged into power and the battery is less than 100% charged.
        /// The associated value is in percent (0—100).
        case charging(Int)
        /// The device is not plugged into power; the battery is discharging.
        /// The associated value is in percent (0—100).
        case unplugged(Int)
        
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
        @MainActor
        public var description: String {
            return Device.current.battery?.description ?? "No Battery"
        }
    }
    
    /// The state of the battery
    @available(*, deprecated, message: "If you need this, please explain the use-case.  Should use Device.current.battery to get state or level or monitor for changes.")
    @MainActor
    var batteryState: BatteryState? {
        return BatteryState()
    }
    
    /// Battery level ranges from 0 (fully discharged) to 100 (100% charged).
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
    /// The volume’s total capacity in bytes.
    @available(*, deprecated, renamed: "Device.current.volumeTotalCapacity")
    @MainActor
    public static var volumeTotalCapacity: Int64? {
        Device.current.volumeTotalCapacity
    }
    
    /// The volume’s available capacity in bytes.
    @available(*, deprecated, renamed: "Device.current.volumeAvailableCapacity")
    @MainActor
    public static var volumeAvailableCapacity: Int64? {
        Device.current.volumeAvailableCapacity
    }
    
    /// The volume’s available capacity in bytes for storing important resources.
    @available(iOS 11.0, *)
    @available(*, deprecated, renamed: "Device.current.volumeAvailableCapacityForImportantUsage")
    @MainActor
    public static var volumeAvailableCapacityForImportantUsage: Int64? {
        Device.current.volumeAvailableCapacityForImportantUsage
    }
    
    /// The volume’s available capacity in bytes for storing nonessential resources.
    @available(iOS 11.0, *)
    @available(*, deprecated, renamed: "Device.current.volumeAvailableCapacityForOpportunisticUsage")
    @MainActor
    public static var volumeAvailableCapacityForOpportunisticUsage: Int64? {
        Device.current.volumeAvailableCapacityForOpportunisticUsage
    }
    
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
