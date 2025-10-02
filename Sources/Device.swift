//
//  Device.swift
//  
//
//  Created by Ben Ku on 9/26/16.
//  Copyright © 2016 Kudit, LLC. All rights reserved.
//
/**
 Device type and structs.
 
 Model definitions are included here but are not marked public.  If you need these public (rather than just using these for current device lookups), please let us know your use-case.
 A big thank you to all that help update this list!
 
 Contributors:
 - Ben Ku
 - Heath Hall
 - https://github.com/schickling/Device.swift
 */

public extension Device {
    /// The version of the Device Library since cannot get directly from Package.
    static let version: Version = "2.10.3"
}
import Compatibility

#if canImport(UIKit)
import UIKit // for UIUserInterfaceIdiom
#endif

public extension String {
    /// Device.iPhoneXR.description:     iPhone Xʀ
    /// Device.iPhoneXR.safeDescription: iPhone XR
    var safeDescription: String {
        return self
            .replacingOccurrences(of: "ʀ", with: "R")
            .replacingOccurrences(of: "", with: "Apple")
    }
    var asSearchTerm: String {
        self.safeDescription.replacingOccurrences(of: [",","(",")"], with: " ").whitespaceCollapsed.lowercased()
    }
    static let unknown = "Unknown"
    static let unknownSupportId = "UNKNOWN_PLEASE_HELP_REPLACE"
}

// For generating default introduction dates when we only know the year
public extension String {
    var introductionYear: String {
        return "\(self)-01-01"
    }
}
public extension Int {
    var introductionYear: DateString {
        return DateString("\(self)".introductionYear)
    }
}

extension DateString {
    /// Use this only as a placeholder for a newly created Mac Device.  Replace with actual value when possible.
    public static var defaultBlank: DateString {
        return DateString(Date.nowBackport.mysqlDate)
    }
}

/// Type for inheritance of specific idiom structs which use a Device as a backing store but allows for idiom-specific variables and functions and acts like a sub-class of Device but still having value-type backing.
public protocol DeviceType: SymbolRepresentable {
    var device: Device { get }
}
public extension DeviceType {
    var idiom: Device.Idiom { device.idiom }
    var officialName: String { device.officialName }
    var identifiers: [String] { device.identifiers }
    var introduction: DateString? { device.introduction }
//    var year: Int? { device.introduction?.date?.year }
    var supportId: String { device.supportId }
    var supportURL: URL {
        if supportId.isNumeric { // https://support.apple.com/en-us/111344
            return URL(string: "https://support.apple.com/\(supportId)")! // should automatically redirect to appropriate language
        }
        if supportId.uppercased().hasPrefix("SP") { // https://support.apple.com/kb/SP504
            return URL(string: "https://support.apple.com/kb/\(supportId)")!
        }
        if supportId.hasPrefix("http") {
            return URL(string: supportId)!
        }
        var searchTerm = supportId
        if supportId == .unknownSupportId {
            searchTerm = officialName 
        }
        // try https://duckduckgo.com/?q=!ducky+%22Technical+Specifications%22+site%3Asupport.apple.com+%22MacBook+(Retina%2C+12-inch%2C+Early+2015)%22&
        // https://support.apple.com/kb/index?page=search&src=support_docs_serp&locale=en_US&doctype=DOCUMENTATIONS&q=MacBook+(Retina%2C+12-inch%2C+Early+2015)
//        return URL(string: "https://support.apple.com/kb/index?page=search&src=support_docs_serp&locale=en_US&doctype=DOCUMENTATIONS&q=\(searchTerm.urlEncoded)")!
        return URL(string: "https://duckduckgo.com/?q=!ducky+%22Technical+Specifications%22+site%3Asupport.apple.com+%22\(searchTerm.urlEncoded)%22&")!
        //URL(string: "https://support.apple.com/en-us/docs")!
    }
    var launchOSVersion: Version { device.launchOSVersion }
    var unsupportedOSVersion: Version? { device.unsupportedOSVersion }
    var image: String? { device.image }
    
    var capabilities: Capabilities { device.capabilities }
    /// Device part numbers/models like "MGPC3xx/A" or "A2473"
    var models: [String] { device.models }
    var colors: [MaterialColor] { device.colors }
    
    // Hardware Info
    var cpu: CPU { device.cpu }
    
    /// query whether the device has the specified capability.
    /// device.has(.battery)
    func has(_ capability: Capability) -> Bool {
        return capabilities.contains(capability)
    }
    
    /// query whether the device is a kind of the capability.
    /// device.is(.pro)
    /// NOTE: This cannot be called is(.pro) within an extension due to the `is` being a keyword.
    func `is`(_ capability: Capability) -> Bool {
        return has(capability)
    }
    
    // Info
    var biometrics: Biometrics? { device.capabilities.biometrics }
    var cellular: Cellular? { device.capabilities.cellular }
    var screen: Screen? { device.capabilities.screen }

    // The only functions that should stay not deprecated would be ones that don't make sense with a has/is function
    // synthesized convenience functions (should be deprecated)
    @available(*, deprecated, message: "use .is(.pro) instead")
    var isPro: Bool { device.is(.pro) }
    @available(*, deprecated, message: "use .has(.battery) instead")
    var hasBattery: Bool { device.has(.battery) }
    @available(*, deprecated, message: "use .has(.wirelessCharging) instead")
    var supportsWirelessCharging: Bool { device.has(.wirelessCharging) }
    @available(*, deprecated, message: "use .has(.force3DTouch) instead")
    var hasForce3dTouchSupport: Bool { device.has(.force3DTouch) }
//    var cameras: Int { device.cameras }
    /// Returns whether or not the device has a LiDAR sensor.
    @available(*, deprecated, message: "use .has(.lidar) instead")
    var hasLidarSensor: Bool { device.has(.lidar) }
    /// Returns whether or not the device has a USB-C power supply.
    @available(*, deprecated, message: "use .has(.usbC) instead")
    var hasUSBCConnectivity: Bool { device.has(.usbC) }
    /// Does this device support esims (single or dual)?
    var hasEsim: Bool {
        self.has(.esim) || self.has(.dualesim)
    }
    
//    /// A textual representation of the device.
//    var description: String { device.description }
    
    var idiomatic: any IdiomType {
        // convert to idiomatic device so we can reference the correct implementation of symbolName.
        guard let idiomatic = device.idiom.type.init(device: device) else {
            return device // use default if we can't convert for some reason
        }
        return idiomatic
    }
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    @MainActor
    var symbolName: String {
        return idiomatic.symbolName
    }
        
    /// A safe version of `officialName`.
    /// Example:
    /// Device.iPhoneXR.officialName:     iPhone Xʀ
    /// Device.iPhoneXR.safeOfficialName: iPhone XR
    var safeOfficialName: String { device.safeOfficialName }
    
    var supportedOSInfo: String {
        var info = "\(idiom.osName) \(launchOSVersion)"
        if let unsupportedOSVersion {
            info += " < \(unsupportedOSVersion)"
        } else {
            info += "+"
        }
        return info                   
    }
}
extension String {
    static let base = "BASE"
}

protocol HasScreen: DeviceType {}
extension HasScreen {
    public var screen: Screen {
        self.capabilities.screen ?? .wUnknown // should never not have screen
    }
}
protocol HasCameras: DeviceType {}
extension HasCameras {
    public var cameras: Set<Camera> {
        self.capabilities.cameras
    }
}
protocol HasCellular: DeviceType {}
extension HasCellular {
    public var cellular: Cellular {
        self.capabilities.cellular ?? .none // should never not have cellular
    }
}

/// To allow getting device list publicly
public protocol PublicDeviceIdiom {
    /// Get a list of devices for this idiom.
    static var allDevices: [Device] { get }
}

/// Type for generating and iterating over IdiomTypes for convenient initialization in Models file and for iterating over when searching for a model identifier.
/// NOT PUBLIC since we shouldn't be initing off of identifiers outside of this module.  This is for internal device lookups.  If you need something like this external to this module, please let us know.
public protocol IdiomType: DeviceType, Sendable, PublicDeviceIdiom {
    var device: Device { get } // Idioms can set, but external should not be directly setting this.
    init(identifier: String) // make sure to look for .base identifier for base settings vs a .new identifier for things that should be present for unknown new devices.  Set Needed for extension initializer.
    /// Idiomatic list of all of this type.
    static var all: [Self] { get }
    /// For creating idiomatic devices
    init?(device: Device)
    /// For doing actual initialization (needs to be done by the struct itself since device is not settable (which is what we want so this can be Sendable).
    init(knownDevice: Device)
}
public extension IdiomType {
    /// List of all the actual `Device` structs.
    static var allDevices: [Device] {
        all.map { $0.device }
    }
    init?(device: Device) { // only public for conversion testing for DeviceKit
        guard device.idiom.type == Self.self else {
            return nil
        }
//        self.init(identifier: .base) // what is this for?  So we set defaults?  Assume everything is set
        // replace the device created above
        self.init(knownDevice: device)
    }
    // must be included in implementations since we can't assign this in an init
//    public init(knownDevice: Device) {
//        self.device = knownDevice
//    }
}

public struct Device: IdiomType, Hashable, CustomStringConvertible, Identifiable, Codable {
    /// Constants that indicate the interface type for the device or an object that has a trait environment, such as a view and view controller.
    public enum Idiom: CaseIterable, Identifiable, DeviceAttributeExpressible, Sendable, Codable {
        /// An unspecified idiom.  Used for accessories that don't have a UI.
        case unspecified
        /// An interface designed for the Mac.
        case mac
        /// An interface designed for iPhone and iPod touch.
        case pod
        /// An interface designed for iPod touch.
        case phone
        /// An interface designed for iPad.
        case pad
        /// An interface designed for tvOS and Apple TV.
        case tv
        /// An interface designed for an in-car experience.
        case carPlay
        /// An interface designed for Apple Watch
        case watch
        /// An interface designed for Home Pod
        case homePod
        /// An interface designed for visionOS and Apple Vision Pro.
        case vision
        
#if canImport(UIKit) && !os(watchOS)
        public init(_ userInterfaceIdiom: UIUserInterfaceIdiom) {
            for idiom in Self.allCases {
                if idiom.userInterfaceIdiom == userInterfaceIdiom {
                    self = idiom
                    return
                }
            }
            self = .unspecified
        }
        /// Only available on devices that support UIUserInterfaceIdiom.
        /// Returns the UIUserInterfaceIdiom for this device.
        public var userInterfaceIdiom: UIUserInterfaceIdiom {
            switch self {
            case .mac:
                if #available(iOS 14, tvOS 14.0, *) {
                    return .mac
                }
            case .pod:
                fallthrough // iPod Touch is equivalent UI to a phone.
            case .phone:
                return .phone
            case .pad:
                return .pad
            case .tv:
                return .tv
            case .carPlay:
                return .carPlay
            case .vision:
                if #available(iOS 17, macOS 14, macCatalyst 17, tvOS 17, watchOS 10, *) {
                    return .vision
                }
//            default:
            // following cases are not supported by UIUserInterfaceIdiom:
            case .unspecified:
                break
            case .watch:
                break
            case .homePod:
                break
            }
            // Fallback on earlier versions
            return .unspecified
        }
#endif
        
        public var identifier: String {
            switch self {
            case .unspecified:
                return "Unspecified"
            case .mac:
                return "Mac" // legacy models could be any of the folowing: iMac, MacBook, Mac, MacBookAir, MacBookPro, Macmini, MacPro
            case .pod:
                return "iPod"
            case .phone:
                return "iPhone"
            case .pad:
                return "iPad"
            case .tv:
                return "AppleTV"
            case .homePod:
                return "AudioAccessory"
            case .watch:
                return "Watch"
            case .carPlay:
                return "CarPlay" // just guessing since doesn't exist
            case .vision:
                return "RealityDevice"
//            @unknown default:
//                return "UnknownDevice"
            }
        }
        public var id: String { identifier }
        
        /// String Description for device idom
        public var label: String {
            switch self {
            case .unspecified:
                return "Unspecified"
            case .mac:
                return "Mac"
            case .pod:
                return "iPod"
            case .phone:
                return "iPhone"
            case .pad:
                return "iPad"
            case .tv:
                return " TV"
            case .carPlay:
                return "CarPlay"
            case .watch:
                return " Watch"
            case .homePod:
                return "HomePod"
            case .vision:
                return " Vision"
                //            @unknown default:
                //                return "UnknownDevice"
            }
        }
        
        /// String for the constructor class (like "AppleWatch" or "Mac" or "HomePod") which may be needed in migration or for exporting code.
        public var constructor: String {
            return label.replacingOccurrences(of: " ", with: "Apple")
        }
        
        /// Return an idiom-specific kind of device class (for use in generating unknown devices of a particular category when using older version of framework that hasn't been updated yet so there is a reasonable fallback device.)
        var type: IdiomType.Type {
            switch self {
            case .mac:
                return Mac.self
            case .pod:
                return iPod.self
            case .phone:
                return iPhone.self
            case .pad:
                return iPad.self
            case .tv:
                return AppleTV.self
            case .homePod:
                return HomePod.self
            case .watch:
                return AppleWatch.self
            case .vision:
                return AppleVision.self
            case .unspecified:
                fallthrough
            case .carPlay:
                fallthrough // not set up for CarPlay currently
            default:
                return Device.self
            }
        }
        
        /// Return a prototypical symbol for this idiom.
        public var symbolName: String {
            if self == .carPlay {
                return "carplay"
            }
            let prototypical = self.type.init(identifier: .base) // create a dummy version but don't include prefix or it will recursively loop (not sure why).
//            print(String(describing: prototypical))
            return prototypical.symbolName
        }

        /// List of capabilities inherent to all devices of this idiom.
        public var capabilities: Capabilities {
            switch self {
            case .pod:
                return [
                    .headphoneJack,
                    .battery,
                    ]
            case .phone, .pad:
                return [.battery]
            case .tv:
                return [.headphoneJack, .screen(.tv)]
            case .watch:
                return [.battery, .wirelessCharging, .nfc, .applePay, .roundedCorners]
            case .vision:
                return [.battery, .biometrics(.opticID), .lidar, .cameras([.stereoscopic, .persona]), .screen(.p720), .appleIntelligence]
            case .homePod:
                return [.screen(.w38)]
            case .unspecified, .mac, .carPlay:
                fallthrough
            default:
                return []
            }
        }

        
        @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
        @MainActor
        public func test(device: DeviceType) -> Bool {
            return device.idiom == self
        }
        
        public var osName: String {
            switch self {
            case .unspecified:
                "unknownOS"
            case .mac:
                "macOS"
            case .pod:
                "iOS"
            case .phone:
                "iOS"
            case .pad:
                "iPadOS"
            case .tv:
                "tvOS"
            case .carPlay:
                "carOS"
            case .watch:
                "watchOS"
            case .homePod:
                "audioOS"
            case .vision:
                "visionOS"
            }
        }
        
        public var devices: [Device] {
            switch self {
            case .unspecified:
                []
            case .mac:
                Mac.allDevices
            case .pod:
                iPod.allDevices
            case .phone:
                iPhone.allDevices
            case .pad:
                iPad.allDevices
            case .tv:
                AppleTV.allDevices
            case .carPlay:
                []
            case .watch:
                AppleWatch.allDevices
            case .homePod:
                HomePod.allDevices
            case .vision:
                AppleVision.allDevices
            }
        }
    }
    
    // MARK: - Initialization and variables
    // Device info
    public let idiom: Device.Idiom // need to include the Device. namespace for type checking below
    public let officialName: String
    public let identifiers: [String]
    public let introduction: DateString? // TODO: pull off optional once we've fully migrated/populated (needs to stay an optional for ABI stability and compatibility?)
    public let supportId: String
    public let launchOSVersion: Version
    public let unsupportedOSVersion: Version?
    public let image: String?
    
    // All initializers should add these:
    public let capabilities: Capabilities// = []
    /// Device part numbers/models like "MGPC3xx/A" or "A2473"
    public let models: [String]// = []
    public let colors: [MaterialColor]// = [.silverLight]
    
    // Hardware Info
    public let cpu: CPU
    
    public init(knownDevice: Device) {
        self.idiom = knownDevice.idiom
        self.officialName = knownDevice.officialName
        self.identifiers = knownDevice.identifiers
        self.introduction = knownDevice.introduction
        self.supportId = knownDevice.supportId
        self.launchOSVersion = knownDevice.launchOSVersion
        self.unsupportedOSVersion = knownDevice.unsupportedOSVersion
        self.image = knownDevice.image
        self.capabilities = knownDevice.capabilities
        self.models = knownDevice.models
        self.colors = knownDevice.colors
        self.cpu = knownDevice.cpu
    }

    public init(
        idiom: Idiom,
        officialName: String,
        identifiers: [String],
        introduction: DateString? = nil,
        supportId: String,
        launchOSVersion: Version,
        unsupportedOSVersion: Version?,
        image: String? = nil,
        capabilities: Capabilities,
        models: [String] = [],
        colors: [MaterialColor],
        cpu: CPU
    ) {
        self.idiom = idiom
        self.officialName = officialName
        self.identifiers = identifiers
        self.introduction = introduction
        self.supportId = supportId
        self.launchOSVersion = launchOSVersion
        self.unsupportedOSVersion = unsupportedOSVersion
        self.image = image
        self.capabilities = capabilities
        self.models = models
        self.colors = colors
        self.cpu = cpu
    }

    /// Maps an identifier to a Device. If the identifier can not be mapped to an existing device, a placeholder device for the identifier of the correct idiom is created if possible, otherwise, a placeholder device `.unknown` is returned.
    /// - parameter identifier: The device identifier, e.g. "iPhone7,1". Current device identifier can be obtained from `Device.current.identifier`.
    /// - returns: An initialized `Device`.
    public init(identifier: String) {
        let devices = Device.lookup(identifier: identifier)
        if devices.count > 0 {
            self = devices.first!
            return
        }
        // try to parse identifier to figure out what kind of device this is and create an unknown device profile with assumed default features
        for idiom in Idiom.allCases {
            if identifier.hasPrefix(idiom.identifier) {
                let deviceType = idiom.type
                self = deviceType.init(identifier: identifier).device
                return
            }
        }
        // if we get here, assume we're a mac since the identifier might be one of many mac types.  Also, "arm64" identifier is a mac too.  Preview woud likely be mac as well.
        if identifier == "arm64" || identifier.contains("Mac") {
            // TODO: Try to determine form from identifier?
            self = Mac.init(identifier: identifier).device
            return
        }
        // possibly a preview?
        self.init(
            idiom: .unspecified,
            officialName: "Unknown Device",
            identifiers: [identifier],
            introduction: nil,
            supportId: .unknownSupportId,
            launchOSVersion: .zero,
            unsupportedOSVersion: nil,
            image: nil,
            capabilities: [],
            models: [],
            colors: [],
            cpu: .unknown)
    }

    /// Attempts to lookup a Device (or set of devices) matching an identifier, model, or similar to an officialNameHint.  Will order based on matches if hint is provided.  Unforunately none of this is guaranteed to be a unique identifier.
    /// - parameter identifier: The device identifier, e.g. "iPhone7,1". Current device identifier can be obtained from `Device.current.identifier`.
    /// - parameter model: Model for the device, e.g. "A1522".
    /// - parameter supportId: Support ID for the device, e.g. "SP706".
    /// - parameter officialNameHint: Since identifiers may not be unique, can use a hint to try and find a better match.  e.g. "iPhone 6 Plus"
    /// - returns: An list of `Device` structs.
    public static func lookup(identifier: String? = nil, model: String? = nil, supportId: String? = nil, officialNameHint: String? = nil) -> [Device] {
        var matchingDevices: [Device] = []
        if let identifier {
            matchingDevices = Device.all.filter { $0.device.identifiers.contains(identifier) }
        }
        if let model {
            matchingDevices += Device.all.filter { $0.device.models.contains(model) }
        }
        if let supportId {
            matchingDevices += Device.all.filter { $0.device.supportId == supportId }
        }
        // remove duplicates
        matchingDevices = matchingDevices.unique
        // iPads don't have models to lookup and have no identifier on page, so will be searching all to start.  At some point, remove this again so our iPads don't return everything.
        if matchingDevices.isEmpty, let officialNameHint {
            matchingDevices = Device.all.filter { $0.matchScore(officialNameHint) > 0.1 }
        }
        guard matchingDevices.count > 1 else {
            return matchingDevices // no need to sort or anything if we already have exactly one or zero matches
        }
        matchingDevices.sort { $0.matchScore(officialNameHint) > $1.matchScore(officialNameHint) }
//            debug("MATCH RESULTS:\n\(matchingDevices.map { "\($0.matchScore(officialNameHint)): \($0.officialName)" }.joined(separator: "\n"))")
        return matchingDevices
    }

    /// Note: This hash function is not guaranteed to be stable across/between versions.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifiers)
        hasher.combine(introduction)
        hasher.combine(models)
        hasher.combine(officialName)
        hasher.combine(cpu)
    }
    /// Note: This `String` is not guaranteed to be stable across versions!  Use an identifier or model number for persistent lookups.  Or use the officialName (though this is also not guaranteed to be stable).  Identifier + CPU combination should be stable.
    public var id: String {
        return "\(identifiers)|\(introduction?.mysqlDate ?? "?")|\(models)|\(officialName)|\(cpu)"
    }

    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return .symbolUnknownDevice
    }

    /// A list of all known devices (devices with identifiers and descriptions).
    public static let all: [Device] = {
        var allKnownDevices = [Device]()
        
        // Macs
        allKnownDevices += Mac.allDevices
        // iPod Touches
        allKnownDevices += iPod.allDevices
        // iPhones
        allKnownDevices += iPhone.allDevices
        // iPads
        allKnownDevices += iPad.allDevices
        //  Apple TVs
        allKnownDevices += AppleTV.allDevices
        //  Watches
        allKnownDevices += AppleWatch.allDevices
        // HomePods
        allKnownDevices += HomePod.allDevices
        //  Vision devices
        allKnownDevices += AppleVision.allDevices
        
        return allKnownDevices
    }()
    
    public var device: Device {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    
    /// A textual representation of the device.
    @available(*, deprecated, message: "Use self.officialName or self.identifiers or property actually needing.")
    public var description: String {
        return "\(self.officialName) (\(self.identifiers))"
    }
    
    /// A safe version of `officialName`.
    /// Example:
    /// Device.iPhoneXR.officialName:     iPhone Xʀ
    /// Device.iPhoneXR.safeOfficialName: iPhone XR
    public var safeOfficialName: String {
        return officialName.safeDescription
    }
    
    @available(*, deprecated, renamed: "safeOfficialName", message: "Renamed to be clearer and resolve conflicts with CustomStringConvertible.description")
    public var safeDescription: String {
        return officialName.safeDescription
    }
    
    /// Returns a score indicating the quality of the match for identifying specific models.  1.0 is a perfect match.
    public func matchScore(_ officialNameHint: String?) -> Double {
        guard let officialNameHint else {
            return 0 // unable to match since no hint given.
        }
        if self.officialName == officialNameHint {
            return 1
        }
        let officialName = self.officialName.normalized
        let hint = officialNameHint.normalized
        if officialName == hint {
            return 0.9
        }
        if officialName.contains(hint) {
            // check processor appended
            let stripped = officialName.replacingOccurrences(of: hint, with: "").whitespaceCollapsed.replacingCharacters(in: .whitespacesAndNewlines, with: "").trimmed.lowercased()
            if stripped == self.cpu.caseName {
                return 0.7
            }
            return 0.5
        }
        if officialNameHint.contains(officialName) {
            return 0.3
        }
        return 0.1
    }
}

// MARK: - Device Idiom Types (moved to Models files)
