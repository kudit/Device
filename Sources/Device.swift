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
    static let version: Version = "2.7.0"
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
    static let unknown = "Unknown"
    static let unknownSupportId = "UNKNOWN_PLEASE_HELP_REPLACE"
}

/// Type for inheritance of specific idiom structs which use a Device as a backing store but allows for idiom-specific variables and functions and acts like a sub-class of Device but still having value-type backing.
public protocol DeviceType: SymbolRepresentable {
    var device: Device { get }
}
public extension DeviceType {
    var idiom: Device.Idiom { device.idiom }
    var officialName: String { device.officialName }
    var identifiers: [String] { device.identifiers }
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
    
    internal var idiomatic: any IdiomType {
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

/// Type for generating and iterating over IdiomTypes for convenient initialization in Models file and for iterating over when searching for a model identifier.
/// NOT PUBLIC since we shouldn't be initing off of identifiers outside of this module.  This is for internal device lookups.  If you need something like this external to this module, please let us know.
protocol IdiomType: DeviceType, Sendable {
    var device: Device { get } // Idioms can set, but external should not be directly setting this.
    init(identifier: String) // make sure to look for .base identifier for base settings vs a .new identifier for things that should be present for unknown new devices.  Set Needed for extension initializer.
    /// Idiomatic list of all of this type.
    static var all: [Self] { get }
    /// For creating idiomatic devices
    init?(device: Device)
    /// For doing actual initialization (needs to be done by the struct itself since device is not settable (which is what we want so this can be Sendable).
    init(knownDevice: Device)
}
extension IdiomType {
    /// List of all the actual `Device` structs.
    static var allDevices: [Device] {
        all.map { $0.device }
    }
    init?(device: Device) {
        guard device.idiom.type == Self.self else {
            return nil
        }
//        self.init(identifier: .base) // what is this for?  So we set defaults?  Assume everything is set
        // replace the device created above
        self.init(knownDevice: device)
    }
}

public struct Device: IdiomType, Hashable, CustomStringConvertible, Identifiable {
    /// Constants that indicate the interface type for the device or an object that has a trait environment, such as a view and view controller.
    public enum Idiom: CaseIterable, Identifiable, DeviceAttributeExpressible, Sendable {
        /// An unspecified idiom.
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
            let prototypical = self.type.init(identifier: .base) // create a dummy version but don't include prefix or it will recursively loop (not sure why).
//            print(String(describing: prototypical))
            return prototypical.symbolName
        }
        
        @available(iOS 13, tvOS 13, watchOS 6, *)
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
    }
    
    // MARK: - Initialization and variables
    // Device info
    public let idiom: Device.Idiom // need to include the Device. namespace for type checking below
    public let officialName: String
    public let identifiers: [String]
    public let supportId: String
    public let launchOSVersion: Version
    public let unsupportedOSVersion: Version?
    public let image: String?
    
    // All initializers should add these:
    public let capabilities: Capabilities// = []
    public let models: [String]// = []
    public let colors: [MaterialColor]// = [.silverLight]
    
    // Hardware Info
    public let cpu: CPU
    
    public init(knownDevice: Device) {
        self.idiom = knownDevice.idiom
        self.officialName = knownDevice.officialName
        self.identifiers = knownDevice.identifiers
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
            supportId: .unknownSupportId,
            launchOSVersion: "0.0.0",
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

    /// Note: This hash function is not guaranteed to be stable across versions.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifiers)
        hasher.combine(models)
        hasher.combine(officialName)
        hasher.combine(cpu)
    }
    /// Note: This `String` is not guaranteed to be stable across versions!  Use an identifier or model number for persistent lookups.  Or use the officialName (though this is also not guaranteed to be stable).  Identifier + CPU combination should be stable.
    public var id: String {
        return "\(identifiers)|\(models)|\(officialName)|\(cpu)"
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

// MARK: - Device Idiom Types
public struct Mac: IdiomType {
    public enum Form: String, Hashable, CaseIterable, CaseNameConvertible, Sendable {
        case macProGen1 = "macpro.gen1" // original cheese grater
        case macProGen2 = "macpro.gen2" // trash can
        case macProGen3 = "macpro.gen3" // silver handle circles
//        case macProGen3Server = "macpro.gen3.server" // MacPro Rack configuration
        case macBook = "macbook"
        case macBookGen1 = "macbook.gen1" // magSafe 2
        case macBookGen2 = "macbook.gen2" // magSafe 3, notch
        case macMini = "macmini"
        case macStudio = "macstudio"
        case iMac = "desktopcomputer"
        /// Form-specific capabilities
        public var capabilities: Capabilities {
            switch self {
            case .macProGen1:
                [.thunderbolt]
            case .macProGen2:
                [.thunderbolt]
            case .macProGen3:
                [.thunderbolt]
            case .macBook:
                [.battery]
            case .macBookGen1:
                Mac.Form.macBook.capabilities.union([.cameras([.faceTimeHD720p]), .magSafe2])
            case .macBookGen2:
                Mac.Form.macBook.capabilities.union([.usbC, .thunderbolt, .notch, .cameras([.faceTimeHD1080p]), .biometrics(.touchID), .magSafe3])
            case .macMini:
                []
            case .macStudio:
                []
            case .iMac:
                []
            }
        }
        // TODO: func to convert an identifier to a form (Macmini, MacPro, MacBookPro, MacBook, MacBookAir, etc)
        public var hasScreen: Bool {
            switch self {
            case .macProGen1:
                return false
            case .macProGen2:
                return false
            case .macProGen3:
                return false
            case .macBook:
                return true
            case .macBookGen1:
                return true
            case .macBookGen2:
                return true
            case .macMini:
                return false
            case .macStudio:
                return false
            case .iMac:
                return true
            }
        }
    }
    
    public let device: Device
    public init(knownDevice: Device) {
        self.device = knownDevice
    }

    public init(
        officialName: String,
        identifiers: [String],
        supportId: String,
        launchOSVersion: Version,
        unsupportedOSVersion: Version?,
        form: Form, // will indicate if there is a battery or not (only MacBooks have batteries)
        image: String?,
        capabilities: Capabilities = [],
        models: [String] = [],
        colors: [MaterialColor],
        cpu: CPU,
        screen: Screen? = nil
    )
    {
        var capabilities = capabilities.union(form.capabilities).union([
            // assume for all models we are working with here.  If this changes, will remove from defaults.
            .headphoneJack,
            .macForm(form) // will this be problematic with zeroing out defaults or base model?  No because adding the new form should replace old?
        ])
        if let screen {
            capabilities.formUnion([.screen(screen)])
        } else if form.hasScreen {
            capabilities.formUnion([.screen(.undefined)])
        }
        device = Device(idiom: .mac, officialName: officialName, identifiers: identifiers, supportId: supportId, launchOSVersion: launchOSVersion, unsupportedOSVersion: unsupportedOSVersion, image: image, capabilities: capabilities, models: models, colors: colors, cpu: cpu)
    }
    
    init(identifier: String) {
        self.init(
            officialName: "Unknown Mac",
            identifiers: [identifier],
            supportId: .unknownSupportId,
            launchOSVersion: "0.0.0",
            unsupportedOSVersion: nil,
            form: .macMini, // no default battery
            image: nil,
            capabilities: identifier == .base ? [] : [
                // defaults for new unknown devices
                .usbC, .thunderbolt
            ],
            models: [],
            colors: .default,
            cpu: .unknown
        )
    }
    
    /// Mac form enum (unwrapped from capabilities)
    public var form: Form {
        return capabilities.macForm ?? .macStudio // should never be nil but here just in case.
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return self.form.rawValue
    }

    static let all = [
        // TODO: We need a lot more of the macs here!  Please help fill these out via a pull request.
        // Support IDs and images can be found here: https://support.apple.com/en-us/108054

        // MARK: - iMacs
        Mac(
            officialName: "iMac (24-inch, 2024, Four ports)",
            identifiers: ["Mac16,3"],
            supportId: "121557",
            launchOSVersion: "15.0",
            unsupportedOSVersion: nil,
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-24in-2024-four-ports-colors.png",
            models: ["MCR24xx/A", "MD2P4xx/A", "MD2Q4xx/A", "MD2T4xx/A", "MD2U4xx/A", "MD2V4xx/A", "MD2W4xx/A", "MD2X4xx/A", "MD2Y4xx/A", "MD3A4xx/A", "MD3D4xx/A", "MD3E4xx/A", "MD3F4xx/A", "MD3G4xx/A", "MD3H4xx/A", "MWUU3xx/A", "MWUV3xx/A", "MWUW3xx/A", "MWUX3xx/A", "MWUY3xx/A", "MWV03xx/A", "MWV13xx/A", "MWV33xx/A", "MWV43xx/A", "MWV53xx/A", "MWV63xx/A", "MWV73xx/A", "MWV83xx/A", "MWV93xx/A", "MWVA3xx/A", "MWVC3xx/A", "MWVD3xx/A", "MWVE3xx/A", "MWVF3xx/A", "MWVG3xx/A", "MWVH3xx/A", "MWVJ3xx/A", "MWVK3xx/A", "MWVL3xx/A", "MWVN3xx/A", "MWVP3xx/A", "MWVQ3xx/A", "MWVR3xx/A"],
            colors: .iMac2024,
            cpu: .m4),
        Mac(
            officialName: "iMac (24-inch, 2024, Two ports)",
            identifiers: ["Mac16,2"],
            supportId: "121556",
            launchOSVersion: "15.0",
            unsupportedOSVersion: nil,
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-24in-2024-two-ports-colors.png",
            models: ["MWUD3xx/A", "MWUE3xx/A", "MWUF3xx/A", "MWUG3xx/A", "MWUH3xx/A", "MWUJ3xx/A", "MWUK3xx/A", "MWUL3xx/A", "MWUN3xx/A", "MWUPxx/A", "MWUQ3xx/A", "MWUR3xx/A", "MWUT3xx/A"],
            colors: .iMac2024,
            cpu: .m4),
        Mac(
            officialName: "iMac (24-inch, 2023, Four ports)",
            identifiers: ["Mac15,5"],
            supportId: "117734",
            launchOSVersion: "13.5",
            unsupportedOSVersion: nil,
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-24in-2023-four-ports-colors.png",
            models: ["MQRJ3xx/A", "MQRK3xx/A", "MQRL3xx/A", "MQRM3xx/A", "MQRN3xx/A", "MQRP3xx/A", "MQRQ3xx/A", "MQRR3xx/A", "MQRT3xx/A", "MQRU3xx/A", "MQRV3xx/A", "MQRW3xx/A", "MQRX3xx/A", "MQRY3xx/A"],
            colors: .iMac,
            cpu: .m3),
        Mac(
            officialName: "iMac (24-inch, 2023, Two ports)",
            identifiers: ["Mac15,4"],
            supportId: "117733",
            launchOSVersion: "13.5",
            unsupportedOSVersion: nil,
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-24in-2023-two-ports-colors.png",
            models: ["MQR93xx/A", "MQRA3xx/A", "MQRC3xx/A", "MQRD3xx/A"],
            colors: .iMac2Ports,
            cpu: .m3),
        Mac(
            officialName: "iMac (24-inch, M1, 2021)", // four ports
            identifiers: ["iMac21,1"],
            supportId: "111895",
            launchOSVersion: "11.3",
            unsupportedOSVersion: nil,
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/id-imac-24-2021.png",
            models: ["MGPC3xx/A", "MGPD3xx/A", "MGPF3xx/A", "MGPG3xx/A", "MGPH3xx/A", "MGPJ3xx/A", "MGPK3xx/A", "MGPL3xx/A", "MGPM3xx/A", "MGPN3xx/A", "MGPP3xx/A", "MGPQ3xx/A", "MGPR3xx/A", "MGPT3xx/A"],
            colors: .iMac,
            cpu: .m1),
        Mac(
            officialName: "iMac (24-inch, M1, 2021)", // two ports
            identifiers: ["iMac21,2"],
            supportId: "111895", // SP839
            launchOSVersion: "11.3",
            unsupportedOSVersion: nil,
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/id-imac-24-2021-2.png",
            models: ["MGTF3xx/a", "MJV83xx/a", "MJV93xx/a", "MJVA3xx/a"],
            colors: .iMac2Ports,
            cpu: .m1),
        Mac( // TODO: Duplicate??
            officialName: "iMac (Retina 5K, 27-inch, 2020)",
            identifiers: ["iMac20,1", "iMac20,2"],
            supportId: "111913", // SP821
            launchOSVersion: "10.15.6",
            unsupportedOSVersion: nil,
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-27-2020.jpg",
            models: ["MXWT2xx/A", "MXWU2xx/A", "MXWV2xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (Retina 5K, 27-inch, 2019)",
            identifiers: ["iMac19,1"],
            supportId: "111998",
            launchOSVersion: "10.14.4",
            unsupportedOSVersion: nil,
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-27-2019.jpg",
            capabilities: [.usbC],
            models: ["MRQYxx/A", "MRR0xx/A", "MRR1xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (Retina 4K, 21.5-inch, 2019)",
            identifiers: ["iMac19,2"],
            supportId: "111963",
            launchOSVersion: "10.14.4",
            unsupportedOSVersion: nil,
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-21-5-2019.jpg",
            capabilities: [.usbC],
            models: ["MRT3xx/A", "MRT4xx/A", "MHK23xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac Pro (2017)",
            identifiers: ["iMacPro1,1"],
            supportId: "111995",
            launchOSVersion: "10.13.2",
            unsupportedOSVersion: nil,
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-pro-2017.jpg",
            capabilities: [.pro, .usbC],
            models: ["MQ2Y2xx/A", "MHLV3xx/A"],
            colors: [.macSpacegray],
            cpu: .xeonE5),
        Mac(
            officialName: "iMac (Retina 5K, 27-inch, 2017)",
            identifiers: ["iMac18,3"],
            supportId: "111969",
            launchOSVersion: "10.12.4",
            unsupportedOSVersion: "14",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-27-2017.jpg",
            capabilities: [.usbC],
            models: ["MNE92xx/A", "MNEA2xx/A", "MNED2xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (Retina 4K, 21.5-inch, 2017)",
            identifiers: ["iMac18,2"],
            supportId: "112026",
            launchOSVersion: "10.12.4",
            unsupportedOSVersion: "14",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-21-5-2017.jpg",
            capabilities: [.usbC],
            models: ["MNDY2xx/A", "MNE02xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (21.5-inch, 2017)",
            identifiers: ["iMac18,1"],
            supportId: "111921",
            launchOSVersion: "10.12.4",
            unsupportedOSVersion: "14",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-21-5-2017.jpg", // NOTE: Image needs to be unique?  Why is this?
            capabilities: [.usbC],
            models: ["MMQA2xx/A", "MHK03xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (Retina 5K, 27-inch, Late 2015)",
            identifiers: ["iMac17,1"],
            supportId: "112035",
            launchOSVersion: "10.11",
            unsupportedOSVersion: "13",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-27-late-2015.jpg",
            capabilities: [.usbC],
            models: ["MK462xx/A", "MK472xx/A", "MK482xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (Retina 4K, 21.5-inch, Late 2015)",
            identifiers: ["iMac16,2"],
            supportId: "112034",
            launchOSVersion: "10.11",
            unsupportedOSVersion: "13",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-21-5-2015.jpg",
            capabilities: [.usbC],
            models: ["MK452xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (21.5-inch, Late 2015)",
            identifiers: ["iMac16,1"],
            supportId: "112036",
            launchOSVersion: "10.11",
            unsupportedOSVersion: "13",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-21-5-2015.jpg",
            capabilities: [.usbC],
            models: ["MK142xx/A", "MK442xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (Retina 5K, 27-inch, Mid 2015)",
            identifiers: ["iMac15,1"],
            supportId: "112434",
            launchOSVersion: "10.10.2",
            unsupportedOSVersion: "12",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-27-mid-2015.jpg",
            capabilities: [.usbC],
            models: ["MF885xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (Retina 5K, 27-inch, Late 2014)",
            identifiers: ["iMac15,1"],
            supportId: "112436",
            launchOSVersion: "10.10",
            unsupportedOSVersion: "12",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-27-2014.jpg",
            capabilities: [.usbC],
            models: ["MF886xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (21.5-inch, Mid 2014)",
            identifiers: ["iMac14,4"],
            supportId: "112031",
            launchOSVersion: "10.9.3",
            unsupportedOSVersion: "12",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-21-5-2014.jpg",
            capabilities: [.usbC],
            models: ["MF883xx/A", "MG022xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (27-inch, Late 2013)",
            identifiers: ["iMac14,2"],
            supportId: "111970",
            launchOSVersion: "10.8.4",
            unsupportedOSVersion: "11",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-27-2013.jpg",
            capabilities: [.usbC],
            models: ["ME086xx/A", "ME088xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (21.5-inch, Late 2013)",
            identifiers: ["iMac14,1"],
            supportId: "111967",
            launchOSVersion: "10.8.4",
            unsupportedOSVersion: "11",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-21-5-2013.jpg",
            capabilities: [.usbC],
            models: ["ME086xx/A", "ME087xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (27-inch, Late 2012)",
            identifiers: ["iMac13,2"],
            supportId: "112433",
            launchOSVersion: "10.8.2",
            unsupportedOSVersion: "11",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-27-2012.jpg",
            capabilities: [.usbC],
            models: ["MD095xx/A", "MD096xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (21.5-inch, Late 2012)",
            identifiers: ["iMac13,1"],
            supportId: "112435",
            launchOSVersion: "10.8.2",
            unsupportedOSVersion: "11",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-21-5-2012.jpg",
            capabilities: [.usbC],
            models: ["MD093xx/A", "MD094xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (27-inch, Mid 2011)",
            identifiers: ["iMac12,2"],
            supportId: "112569",
            launchOSVersion: "10.6.6",
            unsupportedOSVersion: "10.14",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-27-2011.jpg",
            capabilities: [.usbC],
            models: ["MC813xx/A", "MC814xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (21.5-inch, Mid 2011)",
            identifiers: ["iMac12,1"],
            supportId: "111983",
            launchOSVersion: "10.6.6",
            unsupportedOSVersion: "10.14",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-21-5-2011.jpg",
            capabilities: [.usbC],
            models: ["MC309xx/A", "MC812xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (27-inch, Mid 2010)",
            identifiers: ["iMac11,3"],
            supportId: "112566",
            launchOSVersion: "10.6.3",
            unsupportedOSVersion: "10.14",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-27-2010.jpg",
            capabilities: [.usbC],
            models: ["MC510xx/A", "MC511xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (21.5-inch, Mid 2010)",
            identifiers: ["iMac11,2"],
            supportId: "112567",
            launchOSVersion: "10.6.3",
            unsupportedOSVersion: "10.14",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-21-5-2010.jpg",
            capabilities: [.usbC],
            models: ["MC508xx/A", "MC509xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (27-inch, Late 2009)",
            identifiers: ["iMac10,1"],
            supportId: "112564",
            launchOSVersion: "10.6.1",
            unsupportedOSVersion: "10.14",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-27-2009-late.jpg",
            capabilities: [.usbC],
            models: ["MB952xx/A", "MB953xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (21.5-inch, Late 2009)",
            identifiers: ["iMac10,1"],
            supportId: "112565",
            launchOSVersion: "10.6.1",
            unsupportedOSVersion: "10.14",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-21-5-2009-late.jpg",
            capabilities: [.usbC],
            models: ["MB950xx/A", "MC413xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (24-inch, Early 2009)",
            identifiers: ["iMac9,1"],
            supportId: "112427",
            launchOSVersion: "10.5.6",
            unsupportedOSVersion: "10.12",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-24-2009-early.jpg",
            capabilities: [.usbC],
            models: ["MB418xx/A", "MB419xx/A"],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "iMac (20-inch, Early 2009)",
            identifiers: ["iMac9,1"],
            supportId: "112427",
            launchOSVersion: "10.5.6",
            unsupportedOSVersion: "10.12",
            form: .iMac,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/imac/imac-20-2009-early.jpg",
            capabilities: [.usbC],
            models: ["MB417xx/A", "MC019xx/A"],
            colors: [.silverLight],
            cpu: .intel),

        // MARK: - MacBooks
        Mac(
            officialName: "MacBook (Retina, 12-inch, 2017)",
            identifiers: ["MacBook10,1"],
            supportId: "SP757",
            launchOSVersion: "10.12.5",
            unsupportedOSVersion: "14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook/macbook-2017-device.jpg",
            capabilities: [.usbC],
            models: ["MNYF2XX/A", "MNYG2XX/A", "MNYH2XX/A", "MNYJ2XX/A", "MNYK2XX/A", "MNYL2XX/A", "MNYM2XX/A", "MNYN2XX/A"],
            colors: [.macbookRoseGold, .macbookSpacegray, .macbookGold, .solidSilver],
            cpu: .intel),
        Mac(
            officialName: "MacBook (Retina, 12-inch, Early 2016)",
            identifiers: ["MacBook9,1"],
            supportId: "SP741",
            launchOSVersion: "10.11.4",
            unsupportedOSVersion: "13",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook/macbook-2016-device.jpg",
            capabilities: [.usbC],
            models: ["MLH72xx/A", "MLH82xx/A", "MLHA2xx/A", "MLHC2xx/A", "MLHE2xx/A", "MLHF2xx/A", "MMGL2xx/A", "MMGM2xx/A"],
            colors: [.macbookRoseGold, .macbookSpacegray, .macbookGold, .solidSilver],
            cpu: .intel),
        Mac(
            officialName: "MacBook (Retina, 12-inch, Early 2015)",
            identifiers: ["MacBook8,1"],
            supportId: "SP712",
            launchOSVersion: "10.10.2",
            unsupportedOSVersion: "12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook/macbook-2015-device.jpg",
            capabilities: [.usbC],
            models: ["MF855xx/A", "MF865xx/A", "MJY32xx/A", "MJY42xx/A", "MK4M2xx/A", "MK4N2xx/A"],
            colors: [.macbookSpacegray, .macbookGold, .solidSilver],
            cpu: .intel),
        Mac(
            officialName: "MacBook (13-inch, Mid 2010)",
            identifiers: ["MacBook7,1"],
            supportId: "SP584",
            launchOSVersion: "10.6.3",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook/macbook-late-2009-2010-device.jpg",
            capabilities: [.usbC],
            models: ["MC516xx/A"],
            colors: [.white],
            cpu: .intel),
        Mac(
            officialName: "MacBook (13-inch, Late 2009)",
            identifiers: ["MacBook6,1"],
            supportId: "SP579",
            launchOSVersion: "10.6.1",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook/macbook-late-2009-2010-device.jpg", // need to be unique?
            capabilities: [.usbC],
            models: ["MC207xx/A"],
            colors: [.white],
            cpu: .intel),
        Mac(
            officialName: "MacBook (13-inch, Mid 2009)",
            identifiers: ["MacBook5,2"],
            supportId: "SP512",
            launchOSVersion: "10.5.6",
            unsupportedOSVersion: "10.12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook/macbook-early-mid-2009-device.jpg",
            capabilities: [.usbC],
            models: ["MC240xx/A"],
            colors: [.white],
            cpu: .intel),
        Mac(
            officialName: "MacBook (13-inch, Early 2009)",
            identifiers: ["MacBook5,2"],
            supportId: "SP504",
            launchOSVersion: "10.5.6",
            unsupportedOSVersion: "10.12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook/macbook-early-mid-2009-device.jpg", // need to be unique?
            capabilities: [.usbC],
            models: ["MB881xx/A"],
            colors: [.white],
            cpu: .intel),

        // MARK: - MacBook Airs
        Mac(
            officialName: "MacBook Air (15-inch, M4, 2025)",
            identifiers: ["Mac16,13"],
            supportId: "122210",
            launchOSVersion: "15.3.2", // TODO: Check for 15.3.1?
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/2025-macbook-air-15in-colors.png",
            capabilities: [.air, .usbC, .notch],
            models: ["MC6J4xx/A", "MC6K4xx/A", "MC6L4xx/A", "MC7A4xx/A", "MC7C4xx/A", "MC7D4xx/A", "MDG34xx/A", "MDG84xx/A", "MDG94xx/A", "MW1G3xx/A", "MW1H3xx/A", "MW1J3xx/A", "MW1K3xx/A", "MW1L3xx/A", "MW1M3xx/A"],
            colors: .macbookAir2025,
            cpu: .m4),
        Mac(
            officialName: "MacBook Air (13-inch, M4, 2025)",
            identifiers: ["Mac16,12"],
            supportId: "122209",
            launchOSVersion: "15.3.2", // TODO: Check for 15.3.1?
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/2025-macbook-air-13in-colors.png",
            capabilities: [.air, .usbC, .notch],
            models: ["MC654xx/A", "MC6A4xx/A", "MC6C4xx/A", "MC6T4xx/A", "MC6U4xx/A", "MC6V4xx/A", "MDG24xx/A", "MDG54xx/A", "MDG64xx/A", "MW0W3xx/A", "MW0X3xx/A", "MW0Y3xx/A", "MW103xx/A", "MW123xx/A", "MW133xx/A"],
            colors: .macbookAir2025,
            cpu: .m4),
        Mac(
            officialName: "MacBook Air (15-inch, M3, 2024)",
            identifiers: ["Mac15,13"],
            supportId: "118552", // SP913
            launchOSVersion: "14.4",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/2024-macbook-air-15in-m3-colors.png",
            capabilities: [.air, .usbC, .notch],
            models: ["MRYM3xx/A", "MRYP3xx/A", "MRYR3xx/A", "MRYU3xx/A", "MRYN3xx/A", "MRYQ3xx/A", "MRYT3xx/A", "MRYV3xx/A", "MXD13xx/A", "MXD23xx/A", "MXD33xx/A", "MXD43xx/A"],
            colors: [.solidSilver, .macbookairStarlight, .macbookSpacegray, .macbookairMidnight],
            cpu: .m3),
        Mac(
            officialName: "MacBook Air (13-inch, M3, 2024)",
            identifiers: ["Mac15,12"],
            supportId: "118551", // SP912
            launchOSVersion: "14.4",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/2024-macbook-air-13in-m3-colors.png",
            capabilities: [.air, .usbC, .notch],
            models: ["MRXN3xx/A", "MRXQ3xx/A", "MRXT3xx/A", "MRXV3xx/A", "MRXP3xx/A", "MRXR3xx/A", "MRXU3xx/A", "MRXW3xx/A", "MXCR3xx/A", "MXCT3xx/A", "MXCU3xx/A", "MXCV3xx/A"],
            colors: [.solidSilver, .macbookairStarlight, .macbookSpacegray, .macbookairMidnight],
            cpu: .m3),

        Mac(
            officialName: "MacBook Air (15-inch, M2, 2023)",
            identifiers: ["Mac14,15"],
            supportId: "111346",
            launchOSVersion: "13.4",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/2023-macbook-air-15in-m2-colors.png",
            capabilities: [.air, .usbC, .notch],
            models: ["MQKP3xx/A", "MQKQ3xx/A", "MQKR3xx/A", "MQKT3xx/A", "MQKU3xx/A", "MQKV3xx/A", "MQKW3xx/A", "MQKX3xx/A"],
            colors: [.solidSilver, .macbookairStarlight, .macbookSpacegray, .macbookairMidnight],
            cpu: .m2),
        Mac(
            officialName: "MacBook Air (M2, 2022)",
            identifiers: ["Mac14,2"],
            supportId: "111867",
            launchOSVersion: "12.4",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/2022-macbook-air-m2-colors.png",
            capabilities: [.air, .usbC],
            models: ["MLXW3xx/A", "MLXX3xx/A", "MLXY3xx/A", "MLY03xx/A", "MLY13xx/A", "MLY23xx/A", "MLY33xx/A", "MLY43xx/A"],
            colors: [.solidSilver, .macbookairStarlight, .macbookSpacegray, .macbookairMidnight],
            cpu: .m2),
        Mac(
            officialName: "MacBook Air (M1, 2020)",
            identifiers: ["MacBookAir10,1"],
            supportId: "111883",
            launchOSVersion: "11.0.1",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2020-late-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MGN63xx/A", "MGN93xx/A", "MGND3xx/A", "MGN73xx/A", "MGNA3xx/A", "MGNE3xx/A"],
            colors: [.macbookSpacegray, .macbookGold, .solidSilver],
            cpu: .m1),
        Mac(
            officialName: "MacBook Air (Retina, 13-inch, 2020)",
            identifiers: ["MacBookAir9,1"],
            supportId: "111991",
            launchOSVersion: "10.15.3",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2020-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MVH22xx/A", "MVH42xx/A", "MVH52xx/A", "MWTJ2xx/A", "MWTK2xx/A", "MWTL2xx/A"],
            colors: [.macbookSpacegray, .macbookGold, .solidSilver],
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (Retina, 13-inch, 2019)",
            identifiers: ["MacBookAir8,2"],
            supportId: "111948",
            launchOSVersion: "10.14.5",
            unsupportedOSVersion: "15",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2018-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MVFH2xx/A", "MVFJ2xx/A", "MVFK2xx/A", "MVFL2xx/A", "MVFM2xx/A", "MVFN2xx/A", "MVH62xx/A", "MVH82xx/A"],
            colors: [.macbookSpacegray, .macbookGold, .solidSilver],
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (Retina, 13-inch, 2018)",
            identifiers: ["MacBookAir8,1"],
            supportId: "111933",
            launchOSVersion: "10.14.1",
            unsupportedOSVersion: "15",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2018-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MRE82xx/A", "MREA2xx/A", "MREE2xx/A", "MRE92xx/A", "MREC2xx/A", "MREF2xx/A", "MUQT2xx/A", "MUQU2xx/A", "MUQV2xx/A"],
            colors: [.macbookSpacegray, .macbookGold, .solidSilver],
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (13-inch, 2017)",
            identifiers: ["MacBookAir7,2"],
            supportId: "111924",
            launchOSVersion: "10.10.2",
            unsupportedOSVersion: "13",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2017-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MQD32xx/A", "MQD42xx/A", "MQD52xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (13-inch, Early 2015)",
            identifiers: ["MacBookAir7,2"],
            supportId: "111956",
            launchOSVersion: "10.10.2",
            unsupportedOSVersion: "13",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2015-13in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MJVE2xx/A", "MJVG2xx/A", "MMGF2xx/A", "MMGG2xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (11-inch, Early 2015)",
            identifiers: ["MacBookAir7,1"],
            supportId: "112441",
            launchOSVersion: "10.10.2",
            unsupportedOSVersion: "13",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2015-11in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MJVM2xx/A", "MJVP2xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (13-inch, Early 2014)",
            identifiers: ["MacBookAir6,2"],
            supportId: "111944",
            launchOSVersion: "10.9.2",
            unsupportedOSVersion: "12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2013-2014-13in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MD760xx/B", "MD761xx/B"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (11-inch, Early 2014)",
            identifiers: ["MacBookAir6,1"],
            supportId: "112032",
            launchOSVersion: "10.9.2",
            unsupportedOSVersion: "12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2013-2014-11in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MD711xx/B", "MD712xx/B"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (13-inch, Mid 2013)",
            identifiers: ["MacBookAir6,2"],
            supportId: "111938",
            launchOSVersion: "10.8.4",
            unsupportedOSVersion: "12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2013-2014-13in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MD760xx/A", "MD761xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (11-inch, Mid 2013)",
            identifiers: ["MacBookAir6,1"],
            supportId: "112437",
            launchOSVersion: "10.9.2",
            unsupportedOSVersion: "12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2013-2014-11in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MD711xx/A", "MD712xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (13-inch, Mid 2012)",
            identifiers: ["MacBookAir5,2"],
            supportId: "111966",
            launchOSVersion: "10.8.2",
            unsupportedOSVersion: "11",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2012-13in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MD231xx/A", "MD232xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (11-inch, Mid 2012)",
            identifiers: ["MacBookAir5,1"],
            supportId: "112008",
            launchOSVersion: "10.7.4",
            unsupportedOSVersion: "11",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2012-11in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MD223xx/A", "MD224xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (13-inch, Mid 2011)",
            identifiers: ["MacBookAir4,2"],
            supportId: "112038",
            launchOSVersion: "10.7",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2011-13in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MC965xx/A", "MC966xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (11-inch, Mid 2011)",
            identifiers: ["MacBookAir4,1"],
            supportId: "112439",
            launchOSVersion: "10.7",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2011-11in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MC968xx/A", "MC969xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (13-inch, Late 2010)",
            identifiers: ["MacBookAir3,2"],
            supportId: "112585",
            launchOSVersion: "10.6.4",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2009-2010-13in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MC503xx/A", "MC504xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (11-inch, Late 2010)",
            identifiers: ["MacBookAir3,1"],
            supportId: "112580",
            launchOSVersion: "10.6.4",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2010-11in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MC505xx/A", "MC506xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Air (Mid 2009)",
            identifiers: ["MacBookAir2,1"],
            supportId: "112660",
            launchOSVersion: "10.5.7",
            unsupportedOSVersion: "10.12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-air/macbook-air-2009-2010-13in-device.jpg",
            capabilities: [.air, .usbC],
            models: ["MC505xx/A", "MC233xx/A", "MC234xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        
        // MARK: - MacBook Pros
        Mac(
            officialName: "MacBook Pro (14-inch, 2023)",
            identifiers: ["Mac14,5", "Mac14,9"],
            supportId: "111340", // SP889
            launchOSVersion: "13.2",
            unsupportedOSVersion: nil,
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-14in-2023.png",
            capabilities: [.pro, .usbC],
            models: ["MPHE3xx/A", "MPHF3xx/A", "MPHG3xx/A", "MPHH3xx/A", "MPHJ3xx/A", "MPHK3xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m2pro),
        Mac(
            officialName: "MacBook Pro (16-inch, 2023)",
            identifiers: ["Mac14,6", "Mac14,10"],
            supportId: "111838", // SP890
            launchOSVersion: "13.2",
            unsupportedOSVersion: nil,
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-16in-2023.png",
            capabilities: [.pro],
            models: ["MNWG3xx/A", "MNW93xx/A", "MNWK3xx/A", "MNWD3xx/A", "MNWF3xx/A", "MNW83xx/A", "MNWJ3xx/A", "MNWC3xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m2pro,
            screen: Screen(diagonal: 16.2, resolution: (3456,2234), ppi: 254) // 16.2" 16:10
        ),

        
        Mac(
            officialName: "MacBook Pro (14-inch, Nov 2023) M3",
            identifiers: ["Mac15,3"],
            supportId: "117735", // SP890
            launchOSVersion: "14.1",
            unsupportedOSVersion: nil,
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-14in-m3-nov-2023-silver-space-gray.png",
            capabilities: [.pro],
            models: ["MR7J3xx/A", "MR7K3xx/A", "MRX23xx/A", "MTL73xx/A", "MTL83xx/A", "MTLC3xx/A", "MXE03xx/A", "MXE13xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m3,
            screen: Screen(diagonal: 14.2, resolution: (3024,1964), ppi: 254)
        ),
        Mac(
            officialName: "MacBook Pro (14-inch, Nov 2023) M3 Pro",
            identifiers: ["Mac15,6"],
            supportId: "117736",
            launchOSVersion: "14.1",
            unsupportedOSVersion: nil,
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-14in-m3-pro-m3-max-nov-2023-silver-space-black.png",
            capabilities: [.pro],
            models: ["FRX33xx/A", "FRX43xx/A", "FRX54xx/A", "FRX63xx/A", "FRX73xx/A", "FRX83xx/A", "MRX33xx/A", "MRX43xx/A", "MRX53xx/A", "MRX63xx/A", "MRX73xx/A", "MRX83xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m3pro,
            screen: Screen(diagonal: 14.2, resolution: (3024,1964), ppi: 254)
        ),
        Mac(
            officialName: "MacBook Pro M3 Max (14-inch, Nov 2023)",
            identifiers: ["Mac15,8", "Mac15,10"],
            supportId: "117736#max",
            launchOSVersion: "14.1",
            unsupportedOSVersion: nil,
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-14in-m3-pro-m3-max-nov-2023-silver-space-black.png",
            capabilities: [.pro],
            models: ["FRX33xx/A", "FRX43xx/A", "FRX54xx/A", "FRX63xx/A", "FRX73xx/A", "FRX83xx/A", "MRX33xx/A", "MRX43xx/A", "MRX53xx/A", "MRX63xx/A", "MRX73xx/A", "MRX83xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m3max,
            screen: Screen(diagonal: 14.2, resolution: (3024,1964), ppi: 254)
        ),
        Mac(
            officialName: "MacBook Pro (16-inch, Nov 2023) M3 Pro",
            identifiers: ["Mac15,7"],
            supportId: "117737",
            launchOSVersion: "14.1",
            unsupportedOSVersion: nil,
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-16in-m3-pro-m3-max-nov-2023-silver-space-black.png",
            capabilities: [.pro],
            models: ["FRW13xx/A", "FRW23xx/A", "FRW33xx/A", "FRW43xx/A", "FRW63xx/A", "FRW73xx/A", "FUW63xx/A", "FUW73xx/A", "MRW13xx/A", "MRW23xx/A", "MRW33xx/A", "MRW43xx/A", "MRW63xx/A", "MRW73xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m3pro,
            screen: Screen(diagonal: 16.2, resolution: (3456,2234), ppi: 254)
        ),
        Mac(
            officialName: "MacBook Pro (16-inch, Nov 2023) M3 Max",
            identifiers: ["Mac15,9", "Mac15,11"],
            supportId: "117737#Max",
            launchOSVersion: "14.1",
            unsupportedOSVersion: nil,
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-16in-m3-pro-m3-max-nov-2023-silver-space-black.png?",
            capabilities: [.pro],
            models: ["FRW13xx/A", "FRW23xx/A", "FRW33xx/A", "FRW43xx/A", "FRW63xx/A", "FRW73xx/A", "FUW63xx/A", "FUW73xx/A", "MRW13xx/A", "MRW23xx/A", "MRW33xx/A", "MRW43xx/A", "MRW63xx/A", "MRW73xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m3max,
            screen: Screen(diagonal: 16.2, resolution: (3456,2234), ppi: 254)
        ),

        
        
        

        Mac(
            officialName: "MacBook Pro (14-inch, 2024)",
            identifiers: ["Mac16,1"],
            supportId: "121552",
            launchOSVersion: "15.0",
            unsupportedOSVersion: nil,
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-14in-2024-m4-colors.png",
            capabilities: [.pro],
            models: ["MCX04xx/A", "MCX14xx/A", "MW2U3xx/A", "MW2V3xx/A", "MW2W3xx/A", "MW2X3xx/A", "MXCM3xx/A", "MXCN3xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m4,
            screen: Screen(diagonal: 14.2, resolution: (3024,1964), ppi: 254)
        ),
        Mac(
            officialName: "MacBook Pro (14-inch, 2024) M4 Pro",
            identifiers: ["Mac16,6", "Mac16,8"],
            supportId: "121553",
            launchOSVersion: "15.0",
            unsupportedOSVersion: nil,
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-14in-2024-m4-pro-m4-max-colors.png",
            capabilities: [.pro],
            models: ["MXE63xx/A", "MX2E3xx/A", "MX2F3xx/A", "MX2G3xx/A", "MX2H3xx/A", "MX2J3xx/A", "MX2K3xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m4pro,
            screen: Screen(diagonal: 14.2, resolution: (3024,1964), ppi: 254)
        ),
        Mac(
            officialName: "MacBook Pro (14-inch, 2024) M4 Max",
            identifiers: ["Mac16,8"],
            supportId: "121553",
            launchOSVersion: "15.0",
            unsupportedOSVersion: nil,
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-14in-2024-m4-pro-m4-max-colors.png?",
            capabilities: [.pro],
            models: ["MXE63xx/A", "MX2E3xx/A", "MX2F3xx/A", "MX2G3xx/A", "MX2H3xx/A", "MX2J3xx/A", "MX2K3xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m4max,
            screen: Screen(diagonal: 14.2, resolution: (3024,1964), ppi: 254)
        ),
        Mac(
            officialName: "MacBook Pro (16-inch, 2024) M4 Max",
            identifiers: ["Mac16,7"],
            supportId: "121554",
            launchOSVersion: "15.0",
            unsupportedOSVersion: nil,
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-16in-2024-colors.png",
            capabilities: [.pro],
            models: ["MX2T3xx/A", "MX2U3xx/A", "MX2V3xx/A", "MX2W3xx/A", "MX2X3xx/A", "MX2Y3xx/A", "MX303xx/A", "MX313xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m4max,
            screen: Screen(diagonal: 16.2, resolution: (3456,2234), ppi: 254)
        ),
        Mac(
            officialName: "MacBook Pro (16-inch, 2024) M4 Pro",
            identifiers: ["Mac16,5"],
            supportId: "121554",
            launchOSVersion: "15.0",
            unsupportedOSVersion: nil,
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-16in-2024-colors.png",
            capabilities: [.pro],
            models: ["MX2T3xx/A", "MX2U3xx/A", "MX2V3xx/A", "MX2W3xx/A", "MX2X3xx/A", "MX2Y3xx/A", "MX303xx/A", "MX313xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m4pro,
            screen: Screen(diagonal: 16.2, resolution: (3456,2234), ppi: 254)
        ),

        Mac(
            officialName: "MacBook Pro (13-inch, M2, 2022)",
            identifiers: ["Mac14,7"],
            supportId: "111869",
            launchOSVersion: "12.4",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-13-in-M2-2022.png",
            capabilities: [.pro, .usbC],
            models: ["MNEH3xx/A", "MNEJ3xx/A", "MNEP3xx/A", "MNEQ3xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m2),
        Mac(
            officialName: "MacBook Pro (14-inch, 2021)",
            identifiers: ["MacBookPro18,3", "MacBookPro18,4"],
            supportId: "111902",
            launchOSVersion: "12.0.1",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2021-14in.png",
            capabilities: [.pro, .usbC],
            models: ["MKGP3xx/A", "MKGQ3xx/A", "MKGR3xx/A", "MKGT3xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (16-inch, 2021)",
            identifiers: ["MacBookPro18,1", "MacBookPro18,2"],
            supportId: "111901",
            launchOSVersion: "12.0.1",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2021-16in.png",
            capabilities: [.pro, .usbC],
            models: ["MK183xx/A", "MK193xx/A", "MK1A3xx/A", "MK1E3xx/A", "MK1F3xx/A", "MK1H3xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, M1, 2020)",
            identifiers: ["MacBookPro17,1"],
            supportId: "111893",
            launchOSVersion: "11.0.1",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2020-late-13in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MYD83xx/A", "MYD92xx/A", "MYDA2xx/A", "MYDC2xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .m1),
        Mac(
            officialName: "MacBook Pro (13-inch, 2020, Two Thunderbolt 3 ports)",
            identifiers: ["MacBookPro16,3"],
            supportId: "111981",
            launchOSVersion: "10.15.4",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2020-13in-device-3.jpg",
            capabilities: [.pro, .usbC, .thunderbolt],
            models: ["MXK32xx/A", "MXK52xx/A", "MXK62xx/A", "MXK72xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, 2020, Four Thunderbolt 3 ports)",
            identifiers: ["MacBookPro16,2"],
            supportId: "111339",
            launchOSVersion: "10.15.4",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2020-13in-device-3.jpg",
            capabilities: [.pro, .usbC, .thunderbolt],
            models: ["MWP42xx/A", "MWP52xx/A", "MWP62xx/A", "MWP72xx/A", "MWP82xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (16-inch, 2019)",
            identifiers: ["MacBookPro16,1", "MacBookPro16,4"],
            supportId: "111932",
            launchOSVersion: "10.15.1",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-16in-2019.jpg",
            capabilities: [.pro, .usbC],
            models: ["MVVJ2xx/A", "MVVK2xx/A", "MVVL2xx/A", "MVVM2xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, 2019, Two Thunderbolt 3 ports)",
            identifiers: ["MacBookPro15,4"],
            supportId: "111945", // SP799
            launchOSVersion: "10.14.5",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2018-13in-device.jpg",
            capabilities: [.pro, .usbC, .thunderbolt],
            models: ["MUHN2xx/A", "MUHP2xx/a", "MUHQ2xx/A", "MUHR2xx/A", "MUHR2xx/B"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (15-inch, 2019)",
            identifiers: ["MacBookPro15,1", "MacBookPro15,3"],
            supportId: "111941",
            launchOSVersion: "10.13.6",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2018-15in-device-2.jpg",
            capabilities: [.pro, .usbC],
            models: ["MV902xx/A", "MV912xx/A", "MV922xx/A", "MV932xx/A", "MV942xx/A", "MV952xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, 2019, Four Thunderbolt 3 ports)",
            identifiers: ["MacBookPro15,2"],
            supportId: "111997",
            launchOSVersion: "10.13.6",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2018-13in-device.jpg",
            capabilities: [.pro, .usbC, .thunderbolt],
            models: ["MV962xx/A", "MV972xx/A", "MV982xx/A", "MV992xx/A", "MV9A2xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (15-inch, 2018)",
            identifiers: ["MacBookPro15,1"],
            supportId: "111949",
            launchOSVersion: "10.13.6",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2018-15in-device-2.jpg",
            capabilities: [.pro, .usbC],
            models: ["MR932xx/A", "MR942xx/A", "MR952xx/A", "MR962xx/A", "MR972xx/A", "MUQH2xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, 2018, Four Thunderbolt 3 ports)",
            identifiers: ["MacBookPro15,2"],
            supportId: "111925",
            launchOSVersion: "10.13.6",
            unsupportedOSVersion: nil,
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2018-13in-device.jpg",
            capabilities: [.pro, .usbC, .thunderbolt],
            models: ["MR9Q2xx/A", "MR9R2xx/A", "MR9T2xx/A", "MR9U2xx/A", "MR9V2xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (15-inch, 2017)",
            identifiers: ["MacBookPro14,3"],
            supportId: "111947",
            launchOSVersion: "10.12.5",
            unsupportedOSVersion: "14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2017-15in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MPTR2xx/A", "MPTT2xx/A", "MPTU2xx/A", "MPTV2xx/A", "MPTW2xx/A", "MPTX2xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, 2017, Four Thunderbolt 3 ports)",
            identifiers: ["MacBookPro14,2"],
            supportId: "111972",
            launchOSVersion: "10.12.5",
            unsupportedOSVersion: "14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2017-13in-device.jpg",
            capabilities: [.pro, .usbC, .thunderbolt],
            models: ["MPXV2xx/A", "MPXW2xx/A", "MPXX2xx/A", "MPXY2xx/A", "MQ002xx/A", "MQ012xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, 2017, Two Thunderbolt 3 ports)",
            identifiers: ["MacBookPro14,1"],
            supportId: "111951",
            launchOSVersion: "10.12.5",
            unsupportedOSVersion: "14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2017-13in-device-2thunderbolt-3ports.jpg",
            capabilities: [.pro, .usbC, .thunderbolt],
            models: ["MPXQ2xx/A", "MPXR2xx/A", "MPXT2xx/A", "MPXU2xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (15-inch, 2016)", // Touchbook, macOS 12
            identifiers: ["MacBookPro13,3"],
            supportId: "111975",
            launchOSVersion: "10.12.1",
            unsupportedOSVersion: "13",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2016-15in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MLH32xx/A", "MLH42xx/A", "MLH52xx/A", "MLW72xx/A", "MLW82xx/A", "MLW92xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, 2016, Four Thunderbolt 3 ports)",
            identifiers: ["MacBookPro13,2"],
            supportId: "112003",
            launchOSVersion: "10.12.1",
            unsupportedOSVersion: "13",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2016-13in-device.jpg",
            capabilities: [.pro, .usbC, .thunderbolt],
            models: ["MLH12xx/A", "MLVP2xx/A", "MNQF2xx/A", "MNQG2xx/A", "MPDK2xx/A", "MPDL2xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, 2016, Two Thunderbolt 3 ports)",
            identifiers: ["MacBookPro13,1"],
            supportId: "111999",
            launchOSVersion: "10.12",
            unsupportedOSVersion: "13",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-2016-13in-device.jpg",
            capabilities: [.pro, .usbC, .thunderbolt],
            models: ["MLL42xx/A", "MLUQ2xx/A"],
            colors: [.solidSilver, .macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (Retina, 15-inch, Mid 2015)",
            identifiers: ["MacBookPro11,4", "MacBookPro11,5"],
            supportId: "111955",
            launchOSVersion: "10.10.3",
            unsupportedOSVersion: "13",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-mid-2015-15in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MJLQ2xx/A", "MJLT2xx/A", "MJLU2xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (Retina, 13-inch, Early 2015)",
            identifiers: ["MacBookPro12,1"],
            supportId: "111959",
            launchOSVersion: "10.10.2",
            unsupportedOSVersion: "13",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-early-2015-13in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MF839xx/A", "MF840xx/A", "MF841xx/A", "MF843xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (Retina, 15-inch, Mid 2014)",
            identifiers: ["MacBookPro11,2", "MacBookPro11,3"],
            supportId: "111935",
            launchOSVersion: "10.9",
            unsupportedOSVersion: "12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-mid-2014-15in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MGXC2xx/A", "MGXA2xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (Retina, 13-inch, Mid 2014)",
            identifiers: ["MacBookPro11,1"],
            supportId: "111942",
            launchOSVersion: "10.9",
            unsupportedOSVersion: "12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-mid-2014-13in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MGX72xx/A", "MGX82xx/A", "MGX92xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (Retina, 15-inch, Late 2013)",
            identifiers: ["MacBookPro11,2", "MacBookPro11,3"],
            supportId: "111971",
            launchOSVersion: "10.9",
            unsupportedOSVersion: "12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-late-2013-15in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["ME293xx/A", "ME294xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (Retina, 13-inch, Late 2013)",
            identifiers: ["MacBookPro11,1"],
            supportId: "111946",
            launchOSVersion: "10.9",
            unsupportedOSVersion: "12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-late-2013-13in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["ME864xx/A", "ME865xx/A", "ME866xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (Retina, 15-inch, Early 2013)",
            identifiers: ["MacBookPro10,1"],
            supportId: "118465",
            launchOSVersion: "10.7.4",
            unsupportedOSVersion: "11",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-early-2013-15in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["ME664xx/A", "ME665xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (Retina, 13-inch, Early 2013)",
            identifiers: ["MacBookPro10,2"],
            supportId: "118466",
            launchOSVersion: "10.8.2",
            unsupportedOSVersion: "11",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-early-2013-13in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MD212xx/A", "ME662xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (Retina, 13-inch, Late 2012)",
            identifiers: ["MacBookPro10,2"],
            supportId: "118463",
            launchOSVersion: "10.8.2",
            unsupportedOSVersion: "11",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-late-2012-13in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MD212xx/A", "MD213xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (Retina, 15-inch, Mid 2012)",
            identifiers: ["MacBookPro10,1"],
            supportId: "112576",
            launchOSVersion: "10.7.4",
            unsupportedOSVersion: "11",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-mid-2012-15in-device.jpg",
            capabilities: [.pro, .usbC],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (15-inch, Mid 2012)",
            identifiers: ["MacBookPro9,1"],
            supportId: "112568",
            launchOSVersion: "10.7.3",
            unsupportedOSVersion: "11",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-mid-2012-15in-device2.jpg",
            capabilities: [.pro, .usbC],
            models: ["MD103xx/A", "MD104xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, Mid 2012)",
            identifiers: ["MacBookPro9,2"],
            supportId: "111958",
            launchOSVersion: "10.7.3",
            unsupportedOSVersion: "11",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-mid-2012-13in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MD101xx/A", "MD102xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (17-inch, Late 2011)",
            identifiers: ["MacBookPro8,3"],
            supportId: "112418",
            launchOSVersion: "10.6.6",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-late-2011-17in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MD311xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (15-inch, Late 2011)",
            identifiers: ["MacBookPro8,2"],
            supportId: "112586",
            launchOSVersion: "10.7.2",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-late-2011-15in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MD322xx/A", "MD318xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, Late 2011)",
            identifiers: ["MacBookPro8,1"],
            supportId: "111341",
            launchOSVersion: "10.6.6",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-late-2011-13in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MD314xx/A", "MD313xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (17-inch, Early 2011)",
            identifiers: ["MacBookPro8,3"],
            supportId: "112598",
            launchOSVersion: "10.6.6",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-early-2011-17in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MC725xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (15-inch, Early 2011)",
            identifiers: ["MacBookPro8,2"],
            supportId: "112599",
            launchOSVersion: "10.6.6",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-early-2011-15in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MC723xx/A", "MC721xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, Early 2011)",
            identifiers: ["MacBookPro8,1"],
            supportId: "112600",
            launchOSVersion: "10.6.6",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-early-2011-13in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MC724xx/A", "MC700xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (17-inch, Mid 2010)",
            identifiers: ["MacBookPro6,1"],
            supportId: "112606",
            launchOSVersion: "10.6.3",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-mid-2010-17in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MC024xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (15-inch, Mid 2010)",
            identifiers: ["MacBookPro6,2"],
            supportId: "112605",
            launchOSVersion: "10.6.3",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-mid-2010-15in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MC373xx/A", "MC372xx/A", "MC371xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, Mid 2010)",
            identifiers: ["MacBookPro7,1"],
            supportId: "112604",
            launchOSVersion: "10.6.3",
            unsupportedOSVersion: "10.14",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-mid-2010-13in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MC375xx/A", "MC374xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (17-inch, Mid 2009)",
            identifiers: ["MacBookPro5,2"],
            supportId: "112473",
            launchOSVersion: "10.5.6",
            unsupportedOSVersion: "10.12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-early-mid-2009-17in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MC226xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (15-inch, Mid 2009)",
            identifiers: ["MacBookPro5,3"],
            supportId: "112624",
            launchOSVersion: "10.5.7",
            unsupportedOSVersion: "10.12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-mid-2009-15in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MB985xx/A", "MB986xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (15-inch, 2.53GHz, Mid 2009)",
            identifiers: ["MacBookPro5,3"],
            supportId: "112624",
            launchOSVersion: "10.5.7",
            unsupportedOSVersion: "10.12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-mid-2009-15in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MC118xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (13-inch, Mid 2009)",
            identifiers: ["MacBookPro5,5"],
            supportId: "112474",
            launchOSVersion: "10.5.7",
            unsupportedOSVersion: "10.12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-mid-2009-13in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MB991xx/A", "MB990xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (17-inch, Early 2009)",
            identifiers: ["MacBookPro5,2"],
            supportId: "112526",
            launchOSVersion: "10.5.6",
            unsupportedOSVersion: "10.12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-early-mid-2009-17in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MB604xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (15-inch, Late 2008)",
            identifiers: ["MacBookPro5,1"],
            supportId: .unknownSupportId,
            launchOSVersion: "10.5.5",
            unsupportedOSVersion: "10.12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-late-2008-15in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MB470xx/A", "MB471xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (17-inch, Early 2008)",
            identifiers: ["MacBookPro4,1"],
            supportId: .unknownSupportId,
            launchOSVersion: "10.5.2",
            unsupportedOSVersion: "10.12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-early-2008-17in-device.jpg",
            capabilities: [.pro, .usbC],
            models: ["MB166xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "MacBook Pro (15-inch, Early 2008)",
            identifiers: ["MacBookPro4,1"],
            supportId: .unknownSupportId,
            launchOSVersion: "10.5.2",
            unsupportedOSVersion: "10.12",
            form: .macBook,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/macbook-pro/macbook-pro-early-2008-15in-device.jpg",
            capabilities: [.pro],
            models: ["MB133xx/A", "MB134xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),

        // MARK: - Mac Studios
        Mac(
            officialName: "Mac Studio (2022) M1 Max", // have to be different from next item or will crash
            identifiers: ["Mac13,1"],
            supportId: "111900", // have to be different from next item or will crash?? - not sure why since identifiers and officialName are different
            launchOSVersion: "12.3",
            unsupportedOSVersion: nil,
            form: .macStudio,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-studio/mac-studio-2022-m1-max.png",
            capabilities: [.usbC, .thunderbolt, .headphoneJack], // .hdmi, .sdCardSlot, .ethernet, .usbA, no battery
            models: ["MJMV2xx/a"],
            colors: [.silverLight],
            cpu: .m1max),
        Mac(
            officialName: "Mac Studio (2022) M1 Ultra", // have to be different from next item or will crash
            identifiers: ["Mac13,2"],
            supportId: "111900",
            launchOSVersion: "12.3",
            unsupportedOSVersion: nil,
            form: .macStudio,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-studio/mac-studio-2022-m1-ultra.png",
            capabilities: [.usbC, .thunderbolt, .headphoneJack], // .hdmi, .sdCardSlot, .ethernet, .usbA, no battery
            models: ["MJMW3xx/a"],
            colors: [.silverLight],
            cpu: .m1ultra),
        Mac(
            officialName: "Mac Studio (2023) M2 Max", // have to be different from next item or will crash
            identifiers: ["Mac14,13"],
            supportId: "111835", // have to be different from next item or will crash? - not sure why since identifiers and officialName are different
            launchOSVersion: "13.4",
            unsupportedOSVersion: nil,
            form: .macStudio,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-studio/mac-studio-2023-m2-max.png",
            capabilities: [.usbC, .thunderbolt, .headphoneJack], // .hdmi, .sdCardSlot, .ethernet, .usbA, no battery
            models: ["MQH73xx/A"],
            colors: [.silverLight],
            cpu: .m2max),
        Mac(
            officialName: "Mac Studio (2023) M2 Ultra", // have to be different from next item or will crash
            identifiers: ["Mac14,14"],
            supportId: "111835", // have to be different from next item or will crash?? - not sure why since identifiers and officialName are different
            launchOSVersion: "13.4",
            unsupportedOSVersion: nil,
            form: .macStudio,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-studio/mac-studio-2023-m2-ultra.png",
            capabilities: [.usbC, .thunderbolt, .headphoneJack], // .hdmi, .sdCardSlot, .ethernet, .usbA, no battery
            models: ["MQH63xx/A"],
            colors: [.silverLight],
            cpu: .m2ultra),
        Mac(
            officialName: "Mac Studio (2025) M4 Max", // have to be different from next item or will crash
            identifiers: ["Mac16,9"],
            supportId: "122211",
            launchOSVersion: "15.3.1", // TODO: Check
            unsupportedOSVersion: nil,
            form: .macStudio,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-studio/mac-studio-2025-m4-max.png",
            capabilities: [.usbC, .thunderbolt, .headphoneJack], // .hdmi, .sdCardSlot, .ethernet, .usbA, no battery
            models: ["MU963xx/A"],
            colors: [.silverLight],
            cpu: .m4max),
        Mac(
            officialName: "Mac Studio (2025) M3 Ultra", // have to be different from next item or will crash
            identifiers: ["Mac15,14"],
            supportId: "122211",
            launchOSVersion: "15.3.1", // TODO: Check
            unsupportedOSVersion: nil,
            form: .macStudio,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-studio/mac-studio-2025-m3-ultra.png",
            capabilities: [.usbC, .thunderbolt, .headphoneJack], // .hdmi, .sdCardSlot, .ethernet, .usbA, no battery
            models: ["MU973xx/A"],
            colors: [.silverLight],
            cpu: .m3ultra),

        // MARK: - Mac minis
        Mac(
            officialName: "Mac mini (2024) M4 Pro", // have to be different from next item or will crash
            identifiers: ["Mac16,11"], // "Mac16,15"
            supportId: "121555", // have to be different from next item or will crash? - not sure why since identifiers and officialName are different
            launchOSVersion: "15.0",
            unsupportedOSVersion: nil,
            form: .macMini,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-mini/mac-mini-2024.png", // have to be different from next item or will crash? - not sure why since identifiers and officialName are different
            capabilities: [.headphoneJack, .usbC],
            models: ["MCX44xx/A", "MCYT4xx/A", "MDAP4xx/A", "MDAQ4xx/A", "MDAY4xx/A", "MU9D3xx/A", "MU9E3xx/A"],
            colors: [.silverLight],
            cpu: .m4pro),
        Mac(
            officialName: "Mac mini (2024) M4",
            identifiers: ["Mac16,10"],
            supportId: "121555",
            launchOSVersion: "15.0",
            unsupportedOSVersion: nil,
            form: .macMini,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-mini/mac-mini-2024.png",
            capabilities: [.usbC],
            colors: [.silverLight],
            cpu: .m4),

        Mac(
            officialName: "Mac mini (2023) M2",
            identifiers: ["Mac14,3"],
            supportId: "111837", // SP891
            launchOSVersion: "13.2",
            unsupportedOSVersion: nil,
            form: .macMini,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-mini/mac-mini-2023-m2.png",
            capabilities: [.headphoneJack, .usbC],
            models: ["MMFJ3xx/A", "MMFK3xx/A"],
            colors: .legacySilverMacs,
            cpu: .m2),
        Mac(
            officialName: "Mac mini (2023) M2 Pro",
            identifiers: ["Mac14,12"],
            supportId: "111837",
            launchOSVersion: "13.2",
            unsupportedOSVersion: nil,
            form: .macMini,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-mini/mac-mini-2023-m2-pro.png",
            capabilities: [.usbC],
            models: ["MNH73xx/A"],
            colors: [.solidSilver],
            cpu: .m2pro),
        Mac(
            officialName: "Mac mini (M1, 2020)",
            identifiers: ["Macmini9,1"],
            supportId: "111894",
            launchOSVersion: "11.0.1",
            unsupportedOSVersion: nil,
            form: .macMini,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-mini/mac-mini-2020-m1.png",
            capabilities: [.usbC],
            models: ["MGNR3xx/A", "MGNT3xx/A"],
            colors: [.solidSilver],
            cpu: .m1),
        Mac(
            officialName: "Mac mini (2018)",
            identifiers: ["Macmini8,1"],
            supportId: "111912",
            launchOSVersion: "10.14",
            unsupportedOSVersion: nil,
            form: .macMini,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-mini/mac-mini-2018.png",
            capabilities: [.usbC],
            models: ["MRTR2xx/A", "MRTT2xx/A", "MXNF2xx/A", "MXNG2xx/A"],
            colors: [.macbookSpacegray],
            cpu: .intel),
        Mac(
            officialName: "Mac mini (Late 2014)",
            identifiers: ["Macmini7,1"],
            supportId: "111931",
            launchOSVersion: "10.10",
            unsupportedOSVersion: "13",
            form: .macMini,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-mini/mac-mini-late-2014.png",
            capabilities: [.usbC],
            models: ["MGEM2xx/A", "MGEN2xx/A", "MGEQ2xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "Mac mini (Late 2012)",
            identifiers: ["Macmini6,1", "Macmini6,2"],
            supportId: "111926",
            launchOSVersion: "10.8.1",
            unsupportedOSVersion: "11",
            form: .macMini,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-mini/mac-mini-late-2012.png",
            capabilities: [.usbC],
            models: ["MD387xx/A", "MD388xx/A", "MD389xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "Mac mini (Mid 2011)",
            identifiers: ["Macmini5,1", "Macmini5,2"],
            supportId: "112007",
            launchOSVersion: "10.7",
            unsupportedOSVersion: "10.14",
            form: .macMini,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-mini/mac-mini-mid-2011.png",
            capabilities: [.usbC],
            models: ["MC815xx/A", "MC816xx/A", "MC936xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "Mac mini (Mid 2010)",
            identifiers: ["Macmini4,1"],
            supportId: "112588",
            launchOSVersion: "10.6.4",
            unsupportedOSVersion: "10.14",
            form: .macMini,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-mini/mac-mini-mid-2010.png",
            capabilities: [.usbC],
            models: ["MC438xx/A", "MC270xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "Mac mini (Late 2009)",
            identifiers: ["Macmini3,1"],
            supportId: "112482",
            launchOSVersion: "10.6",
            unsupportedOSVersion: "10.12",
            form: .macMini,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-mini/mac-mini-late-2009.png",
            capabilities: [.usbC],
            models: ["MC238xx/A", "MC239xx/A", "MC408xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "Mac mini (Early 2009)",
            identifiers: ["Macmini3,1"],
            supportId: "111345",
            launchOSVersion: "10.5",
            unsupportedOSVersion: "10.12", // everymac says last supported is 10.11.6
            form: .macMini,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-mini/mac-mini-early-2009.png",
            capabilities: [.usbC],
            models: ["MB464xx/A", "MB463xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        
        // MARK: - Mac Pros
        Mac(
            officialName: "Mac Pro (2023)",
            identifiers: ["Mac14,8"],
            supportId: "111343",
            launchOSVersion: "13.4",
            unsupportedOSVersion: nil,
            form: .macProGen3,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-pro/id-mac-pro-2019.jpg",
            capabilities: [.pro, .usbC],
            colors: [.silverLight],
            cpu: .m2ultra),
        Mac(
            officialName: "Mac Pro (Rack, 2023)",
            identifiers: ["Mac14,8"],
            supportId: "111343",
            launchOSVersion: "13.4",
            unsupportedOSVersion: nil,
            form: .macProGen3,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-pro/id-mac-pro-2019-rack.jpg",
            capabilities: [.pro, .usbC],
            colors: [.silverLight],
            cpu: .m2ultra),
        Mac(
            officialName: "Mac Pro (2019)",
            identifiers: ["MacPro7,1"],
            supportId: "118461",
            launchOSVersion: "10.15.1",
            unsupportedOSVersion: nil,
            form: .macProGen3,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-pro/id-mac-pro-2019.jpg",
            capabilities: [.pro, .usbC],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "Mac Pro (Rack, 2019)",
            identifiers: ["MacPro7,1"],
            supportId: "111907",
            launchOSVersion: "10.15.1",
            unsupportedOSVersion: nil,
            form: .macProGen3,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-pro/id-mac-pro-2019-rack.jpg",
            capabilities: [.pro, .usbC],
            colors: [.silverLight],
            cpu: .intel),
        Mac(
            officialName: "Mac Pro (Late 2013)",
            identifiers: ["MacPro6,1"],
            supportId: "112025",
            launchOSVersion: "10.9.1",
            unsupportedOSVersion: "13",
            form: .macProGen3,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-pro/id-mac-pro-2013.jpg",
            capabilities: [.pro, .thunderbolt],
            models: ["ME253xx/A", "MD878xx/A"],
            colors: [.black], // shiny jet black
            cpu: .intel),
        Mac(
            officialName: "Mac Pro (Mid 2012)",
            identifiers: ["MacPro5,1"],
            supportId: "118464",
            launchOSVersion: "10.6.4",
            unsupportedOSVersion: "10.15",
            form: .macProGen1,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-pro/id-mac-pro-2009-2012.jpg", // TODO: ?&&&
            capabilities: [.pro],
            models: ["MD770xx/A", "MD771xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "Mac Pro Server (Mid 2012)",
            identifiers: ["MacPro5,1"],
            supportId: "118464",
            launchOSVersion: "10.6.4",
            unsupportedOSVersion: "10.15",
            form: .macProGen1,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-pro/id-mac-pro-2009-2012.jpg",
            capabilities: [.pro],
            models: ["MD772xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "Mac Pro (Mid 2010)",
            identifiers: ["MacPro5,1"],
            supportId: "112578",
            launchOSVersion: "10.6.4",
            unsupportedOSVersion: "10.15",
            form: .macProGen1,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-pro/id-mac-pro-2009-2012.jpg",
            capabilities: [.pro],
            models: ["MC250xx/A", "MC560xx/A", "MC561xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "Mac Pro Server (Mid 2010)",
            identifiers: ["MacPro5,1"],
            supportId: "112578",
            launchOSVersion: "10.6.4",
            unsupportedOSVersion: "10.15",
            form: .macProGen1,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-pro/id-mac-pro-2009-2012.jpg",
            capabilities: [.pro],
            models: ["MC915xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
        Mac(
            officialName: "Mac Pro (Early 2009)",
            identifiers: ["MacPro4,1"],
            supportId: "112590",
            launchOSVersion: "10.5.6",
            unsupportedOSVersion: "10.12",
            form: .macProGen1,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/mac-pro/id-mac-pro-2009-2012.jpg",
            capabilities: [.pro], // FireWire 800, USB-A
            models: ["MB871xx/A", "MB535xx/A"],
            colors: .legacySilverMacs,
            cpu: .intel),
    ]
}
    
public struct iPod: IdiomType, HasScreen {
    public let device: Device
    public init(knownDevice: Device) {
        self.device = knownDevice
    }

    public init(
        officialName: String,
        identifiers: [String],
        supportId: String,
        launchOSVersion: Version,
        unsupportedOSVersion: Version?,
        image: String?,
        capabilities: Capabilities = [],
        models: [String] = [],
        colors: [MaterialColor],
        cpu: CPU
    ) {
        device = Device(
            idiom: .pod,
            officialName: officialName,
            identifiers: identifiers,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities.union([
                .headphoneJack,
                .lightning,
                .battery,
                .screen(.i4),
                .cameras([.iSight, .faceTimeHD720p]),
            ]),
            models: models,
            colors: colors,
            cpu: cpu
        )
    }
    
    init(identifier: String) {
        self.init(
            officialName: "Unknown iPod",
            identifiers: [identifier],
            supportId: .unknownSupportId,
            launchOSVersion: "0.0",
            unsupportedOSVersion: "0.0",
            image: nil,
            // capabilities
            // models
            colors: [.white],
            cpu: .unknown)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return "ipodtouch"
    }
    
    static let all = [
    
        iPod(
//            officialName: "iPod touch (1st generation)", // Apple tech specs page seems to have gone back to dropping 1st gen here.
            officialName: "iPod touch",
            identifiers: ["iPod1,1"],
            supportId: "112532",
            launchOSVersion: "1.0",
            unsupportedOSVersion: "4",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-1st-gen.png",
            capabilities: [.headphoneJack, .thirtyPin, .cameras([.twoMP])], // please check specs
            models: ["A1213"],
            colors: [.silver],
            cpu: .s5L8900),
        iPod(
            officialName: "iPod touch (2nd generation)",
            identifiers: ["iPod2,1"],
            supportId: "112319",
            launchOSVersion: "2.1",
            unsupportedOSVersion: "5",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-2nd-gen.png",
            capabilities: [.headphoneJack, .thirtyPin, .cameras([.twoMP])], // please check specs
            models: ["A1288", "A1319"],
            colors: [.silver],
            cpu: .s5L8900),
        iPod(
            officialName: "iPod touch (3rd generation)",
            identifiers: ["iPod3,1"],
            supportId: "pp115",
            launchOSVersion: "3.1.1",
            unsupportedOSVersion: "6",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-3rd-gen.png",
            capabilities: [.headphoneJack, .thirtyPin, .cameras([.threeMP])], // please check specs
            models: ["A1318"],
            colors: [.silver],
            cpu: .s5L8900),
        iPod(
            officialName: "iPod touch (4th generation)",
            identifiers: ["iPod4,1"],
            supportId: "112431",
            launchOSVersion: "4.1",
            unsupportedOSVersion: "7",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-4th-gen.png",
            capabilities: [.headphoneJack, .thirtyPin, .cameras([.iSight, .faceTimeHD720p])], // please check specs
            models: ["A1367"],
            colors: [.white, .black],
            cpu: .a4),
        iPod(
            officialName: "iPod touch (5th generation 16 GB, Mid 2013)",
            identifiers: ["iPod5,1"],
            supportId: "118467",
            launchOSVersion: "6",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-5th-gen.png",
            models: ["A1509"],
            colors: .iPodTouch5thGen,
            cpu: .a5),
        iPod(
            officialName: "iPod touch (5th generation)",
            identifiers: ["iPod5,1"],
            supportId: "SP657",
            launchOSVersion: "6",
            unsupportedOSVersion: "10",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-5th-gen-second-release.png",
            models: ["A1509", "A1421"],
            colors: .iPodTouch5thGen,
            cpu: .a5),
        iPod(
            officialName: "iPod touch (6th generation)",
            identifiers: ["iPod7,1"],
            supportId: "SP720",
            launchOSVersion: "8.4",
            unsupportedOSVersion: "13",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-6th-gen.png",
            models: ["A1574"],
            colors: .iPodTouch6thGen,
            cpu: .a8),
        iPod(
            officialName: "iPod touch (7th generation)",
            identifiers: ["iPod9,1"],
            supportId: "SP796",
            launchOSVersion: "12.3.1",
            unsupportedOSVersion: "16",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipod/ipod-touch/ipod-touch-7th-gen.jpg",
            colors: .iPodTouch7thGen,
            cpu: .a10),
             
    ]
}

public struct iPhone: IdiomType, HasScreen, HasCameras, HasCellular {
    public let device: Device
    public init(knownDevice: Device) {
        self.device = knownDevice
    }

    public init(
        officialName: String,
        identifiers: [String],
        supportId: String,
        launchOSVersion: Version,
        unsupportedOSVersion: Version?,
        image: String?,
        capabilities: Capabilities = [],
        models: [String] = [],
        colors: [MaterialColor],
        cpu: CPU,
        cameras: Set<Camera>, // force setting here
        cellular: Cellular, // force setting here
        screen: Screen // force setting here
    ) {
        var capabilities = capabilities
        capabilities.cameras = cameras
        capabilities.cellular = cellular
        capabilities.screen = screen
        device = Device(
            idiom: .phone,
            officialName: officialName,
            identifiers: identifiers,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities.union([.battery]), // all iPhones have batteries
            models: models,
            colors: colors,
            cpu: cpu
        )
    }
    
    init(identifier: String) {
        self.init(
            officialName: "Unknown iPhone",
            identifiers:[identifier],
            supportId: .unknownSupportId,
            launchOSVersion: "18",
            unsupportedOSVersion: nil,
            image: nil,
            // Assume these capabilities of phones going forward minimum.  Don't include if we're wanting the default set not the one going forward
            capabilities: identifier == .base ? [] : [
                // defaults for new unknown devices
                .wirelessCharging, .magSafe, .roundedCorners, .applePay, .barometer, .nfc, .crashDetection,
                .usbC,
                .biometrics(.faceID),
                .dynamicIsland],
            colors: .default,
            cpu: .unknown,
            cameras: .default, // TODO: Make sure this doesn't cause the base to remove during migration
            cellular: identifier == .base ? .none : .fiveG,
            screen: identifier == .base ? .wUnknown : .i61x828
        )
    }

    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        if #available(iOS 16, macOS 13, macCatalyst 16, tvOS 16, watchOS 9,  *) {
            if has(.dynamicIsland) {
                return "iphone.gen3"
            } else if biometrics == .faceID {
                return "iphone.gen2"
            } else {
                return "iphone.gen1"
            }
        } else {
            if !has(.notch) && !has(.dynamicIsland) {
                return "iphone.homebutton"
            } else {
                return "iphone"
            }
        }
    }
    
    static let all = [

        iPhone(
            officialName: "iPhone",
            identifiers: ["iPhone1,1"],
            supportId: "SP2",
            launchOSVersion: "1",
            unsupportedOSVersion: "4",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-iphone-original-colors.jpg",
            capabilities: [.headphoneJack, .thirtyPin, .ringerSwitch],
            models: ["A1203"],
            colors: [.silver],
            cpu: .s5L8900,
            cameras: [.twoMP],
            cellular: .edge,
            screen: .i35),
        iPhone(
            officialName: "iPhone 3G",
            identifiers: ["iPhone1,2"],
            supportId: "SP495",
            launchOSVersion: "2",
            unsupportedOSVersion: "5",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-iphone3g-colors.jpg",
            capabilities: [.headphoneJack, .thirtyPin, .ringerSwitch],
            models: ["A1324,", "A1241"],
            colors: [.black],
            cpu: .s5L8900,
            cameras: [.twoMP],
            cellular: .threeG,
            screen: .i35),
        iPhone(
            officialName: "iPhone 3GS",
            identifiers: ["iPhone2,1"],
            supportId: "SP565",
            launchOSVersion: "3",
            unsupportedOSVersion: "7",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-iphone3gs-colors.jpg",
            capabilities: [.headphoneJack, .thirtyPin, .ringerSwitch],
            models: ["A1325,", "A1303"],
            colors: .iPhoneBW,
            cpu: .sAPL0298C05,
            cameras: [.threeMP],
            cellular: .threeG,
            screen: .i35),

        iPhone(
            officialName: "iPhone 4",
            identifiers: ["iPhone3,1", "iPhone3,2", "iPhone3,3"],
            supportId: "SP587",
            launchOSVersion: "4",
            unsupportedOSVersion: "8",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-iphone4-colors.jpg",
            capabilities: [.headphoneJack, .thirtyPin, .ringerSwitch],
            models: ["A1349,", "A1332"],
            colors: .iPhoneBW,
            cpu: .a4,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .threeG,
            screen: .i35),
        iPhone(
            officialName: "iPhone 4s",
            identifiers: ["iPhone4,1"],
            supportId: "SP643",
            launchOSVersion: "5",
            unsupportedOSVersion: "10",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-iphone4s-colors.jpg",
            capabilities: [.headphoneJack, .thirtyPin, .ringerSwitch],
            models: ["A1431,", "A1387"],
            colors: .iPhoneBW,
            cpu: .a5,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .threeG,
            screen: .i35),
        iPhone(
            officialName: "iPhone 5",
            identifiers: ["iPhone5,1", "iPhone5,2"],
            supportId: "SP655",
            launchOSVersion: "6",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-iphone5-colors.jpg",
            capabilities: [.headphoneJack, .lightning, .ringerSwitch],
            models: ["A1428,", "A1429,", "A1442"],
            colors: .iPhoneBW,
            cpu: .a6,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i4),
        iPhone(
            officialName: "iPhone 5c",
            identifiers: ["iPhone5,3", "iPhone5,4"],
            supportId: "SP684",
            launchOSVersion: "7",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-iphone5c-colors.jpg",
            capabilities: [.headphoneJack, .lightning, .ringerSwitch],
            models: ["A1456,", "A1507,", "A1516,", "A1529,", "A1532"],
            colors: .iPhone5c,
            cpu: .a6,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i4),
        iPhone(
            officialName: "iPhone 5s",
            identifiers: ["iPhone6,1", "iPhone6,2"],
            supportId: "SP685",
            launchOSVersion: "7",
            unsupportedOSVersion: "13",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-iphone5s-colors.jpg",
            capabilities: [.headphoneJack, .lightning, .biometrics(.touchID), .ringerSwitch],
            models: ["A1453,", "A1457,", "A1518,", "A1528,"],
            colors: .iPhone6,
            cpu: .a7,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i4),
        iPhone(
            officialName: "iPhone 6",
            identifiers: ["iPhone7,2"],
            supportId: "SP705",
            launchOSVersion: "8",
            unsupportedOSVersion: "13",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-iphone6-colors.jpg",
            capabilities: [.headphoneJack, .lightning, .biometrics(.touchID), .applePay, .ringerSwitch, .barometer],
            models: ["A1549,", "A1586,", "A1589"],
            colors: .iPhone6,
            cpu: .a8,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i47),
        iPhone(
            officialName: "iPhone 6 Plus",
            identifiers: ["iPhone7,1"],
            supportId: "SP706",
            launchOSVersion: "8",
            unsupportedOSVersion: "13",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-iphone6plus-colors.jpg",
            capabilities: [.plus, .headphoneJack, .lightning, .biometrics(.touchID), .applePay, .ringerSwitch, .barometer],
            models: ["A1522,", "A1524,", "A1593"],
            colors: .iPhone6,
            cpu: .a8,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i55),
        iPhone(
            officialName: "iPhone 6s",
            identifiers: ["iPhone8,1"],
            supportId: "SP726",
            launchOSVersion: "9.0.1",
            unsupportedOSVersion: "16",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-6s-colors.jpg",
            capabilities: [.headphoneJack, .lightning, .biometrics(.touchID), .applePay, .force3DTouch, .ringerSwitch, .barometer],
            models: ["A1633,", "A1688,", "A1700"],
            colors: .iPhone6s,
            cpu: .a9,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i47),
        iPhone(
            officialName: "iPhone 6s Plus",
            identifiers: ["iPhone8,2"],
            supportId: "SP727",
            launchOSVersion: "9.0.1",
            unsupportedOSVersion: "16",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-6splus-colors.jpg",
            capabilities: [.plus, .headphoneJack, .lightning, .biometrics(.touchID), .applePay, .force3DTouch, .ringerSwitch, .barometer],
            models: ["A1634,", "A1687,", "A1699"],
            colors: .iPhone6s,
            cpu: .a9,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i55),
        iPhone(
            officialName: "iPhone SE (1st generation)",
            identifiers: ["iPhone8,4"],
            supportId: "SP738",
            launchOSVersion: "9.3",
            unsupportedOSVersion: "16",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-se/iphone-se-colors.jpg",
            capabilities: [.headphoneJack, .lightning, .biometrics(.touchID), .applePay, .ringerSwitch],
            models: ["A1723,", "A1662,", "A1724"],
            colors: .iPhoneSE,
            cpu: .a9,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i4),
        iPhone(
            officialName: "iPhone 7",
            identifiers: ["iPhone9,1", "iPhone9,3"],
            supportId: "SP743",
            launchOSVersion: "10",
            unsupportedOSVersion: "16",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-7/iphone7-colors.jpg",
            capabilities: [.lightning, .biometrics(.touchID), .applePay, .nfc, .force3DTouch, .ringerSwitch, .barometer],
            models: ["A1660,", "A1778,", "A1779"],
            colors: .iPhone7,
            cpu: .a10,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i47),
        iPhone(
            officialName: "iPhone 7 Plus",
            identifiers: ["iPhone9,2", "iPhone9,4"],
            supportId: "SP744",
            launchOSVersion: "10",
            unsupportedOSVersion: "16",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-7-plus/iphone7plus-colors.jpg",
            capabilities: [.plus, .lightning, .biometrics(.touchID), .applePay, .nfc, .force3DTouch, .ringerSwitch, .barometer],
            models: ["A1661,", "A1784,", "A1785"],
            colors: .iPhone7,
            cpu: .a10,
            cameras: [.iSight, .wide, .telephoto, .faceTimeHD720p, .faceTimeHD1080p],
            cellular: .lte,
            screen: .i55),
        iPhone(
            officialName: "iPhone 8",
            identifiers: ["iPhone10,1", "iPhone10,4"],
            supportId: "SP767",
            launchOSVersion: "11",
            unsupportedOSVersion: "17",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-8/iphone-8-colors.jpg",
            capabilities: [.lightning, .wirelessCharging, .biometrics(.touchID), .applePay, .nfc, .force3DTouch, .ringerSwitch, .barometer],
            models: ["A1863,", "A1905,", "A1906"],
            colors: .iPhone8,
            cpu: .a11,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i47),
        iPhone(
            officialName: "iPhone 8 Plus",
            identifiers: ["iPhone10,2", "iPhone10,5"],
            supportId: "SP768",
            launchOSVersion: "11",
            unsupportedOSVersion: "17",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-8-plus/iphone-8plus-colors.jpg",
            capabilities: [.plus, .lightning, .wirelessCharging, .biometrics(.touchID), .applePay, .nfc, .force3DTouch, .ringerSwitch, .barometer],
            models: ["A1864,", "A1897,", "A1898"],
            colors: .iPhone8,
            cpu: .a11,
            cameras: [.iSight, .wide, .telephoto, .faceTimeHD720p, .faceTimeHD1080p],
            cellular: .lte,
            screen: .i55),
        iPhone(
            officialName: "iPhone X",
            identifiers: ["iPhone10,3", "iPhone10,6"],
            supportId: "SP770",
            launchOSVersion: "11.1",
            unsupportedOSVersion: "17",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-x-colors.jpg",
            capabilities: [.lightning, .wirelessCharging, .biometrics(.faceID), .esim, .applePay, .nfc, .force3DTouch, .roundedCorners, .notch, .ringerSwitch, .barometer],
            models: ["A1865,", "A1901,", "A1902"],
            colors: .iPhoneX,
            cpu: .a11,
            cameras: [.iSight, .wide, .telephoto, .faceTimeHD720p, .trueDepth],
            cellular: .lte,
            screen: .i58),
        iPhone(
            officialName: "iPhone Xs",
            identifiers: ["iPhone11,2"],
            supportId: "SP779",
            launchOSVersion: "12",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-xs-colors.jpg",
            capabilities: [.lightning, .wirelessCharging, .biometrics(.faceID), .esim, .applePay, .nfc, .force3DTouch, .roundedCorners, .notch, .ringerSwitch, .barometer],
            models: ["A1920,", "A2097,", "A2098", "A2099,", "A2100"],
            colors: .iPhoneXs,
            cpu: .a12,
            cameras: [.iSight, .wide, .telephoto, .faceTimeHD720p, .trueDepth],
            cellular: .lte,
            screen: .i58),
        iPhone(
            officialName: "iPhone Xs Max",
            identifiers: ["iPhone11,4", "iPhone11,6"],
            supportId: "SP780",
            launchOSVersion: "12",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-xs-max-colors.jpg",
            capabilities: [.max, .lightning, .wirelessCharging, .biometrics(.faceID), .esim, .applePay, .nfc, .force3DTouch, .roundedCorners, .notch, .ringerSwitch, .barometer],
            models: ["A1921,", "A2101,", "A2102", "A2103,", "A2104"],
            colors: .iPhoneXs,
            cpu: .a12,
            cameras: [.iSight, .wide, .telephoto, .faceTimeHD720p, .faceTimeHD1080p],
            cellular: .lte,
            screen: .i65),
        iPhone(
            officialName: "iPhone Xʀ",
            identifiers: ["iPhone11,8"],
            supportId: "SP781",
            launchOSVersion: "12",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-xr/identify-iphone-xr-colors.jpg",
            capabilities: [.lightning, .wirelessCharging, .biometrics(.faceID), .esim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .barometer],
            models: ["A1984,", "A2105,", "A2106", "A2107,", "A2108"],
            colors: .iPhoneXʀ,
            cpu: .a12,
            cameras: [.iSight, .wide, .faceTimeHD720p],
            cellular: .lte,
            screen: .i61x828),
        iPhone(
            officialName: "iPhone 11",
            identifiers: ["iPhone12,1"],
            supportId: "SP804",
            launchOSVersion: "13",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/identify-iphone-11-colors.jpg",
            capabilities: [.lightning, .wirelessCharging, .biometrics(.faceID), .esim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .barometer],
            models: ["A2111", "A2223", "A2221"],
            colors: .iPhone11,
            cpu: .a13,
            cameras: [.iSight, .wide, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .lte,
            screen: .i61x828),
        iPhone(
            officialName: "iPhone 11 Pro",
            identifiers: ["iPhone12,3"],
            supportId: "SP805",
            launchOSVersion: "13",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/identify-iphone-11pro.jpg",
            capabilities: [.pro, .lightning, .wirelessCharging, .biometrics(.faceID), .esim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .barometer],
            models: ["A2160", "A2217", "A2215"],
            colors: .iPhone11Pro,
            cpu: .a13,
            cameras: [.iSight, .wide, .telephoto, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .lte,
            screen: .i58),
        iPhone(
            officialName: "iPhone 11 Pro Max",
            identifiers: ["iPhone12,5"],
            supportId: "SP806",
            launchOSVersion: "13",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/identify-iphone-11pro-max.jpg",
            capabilities: [.pro, .max, .lightning, .wirelessCharging, .biometrics(.faceID), .esim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .barometer],
            models: ["A2161", "A2220", "A2218"],
            colors: .iPhone11Pro,
            cpu: .a13,
            cameras: [.iSight, .wide, .telephoto, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .lte,
            screen: .i65),
        iPhone(
            officialName: "iPhone SE (2nd generation)",
            identifiers: ["iPhone12,8"],
            supportId: "SP820",
            launchOSVersion: "13.4.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-se/iphone-se-2nd-gen-colors.jpg",
            capabilities: [.lightning, .wirelessCharging, .biometrics(.touchID), .esim, .applePay, .nfc, .ringerSwitch, .barometer],
            models: ["A2275", "A2298", "A2296"],
            colors: .iPhoneSE2,
            cpu: .a13,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i47),
        iPhone(
            officialName: "iPhone 12",
            identifiers: ["iPhone13,2"],
            supportId: "SP830",
            launchOSVersion: "14.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/2021-iphone12-colors.png",
            capabilities: [.lightning, .wirelessCharging, .magSafe, .biometrics(.faceID), .esim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .barometer],
            models: ["A2172", "A2402", "A2404", "A2403"],
            colors: .iPhone12,
            cpu: .a14,
            cameras: [.iSight, .wide, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i61x1170),
        iPhone(
            officialName: "iPhone 12 mini",
            identifiers: ["iPhone13,1"],
            supportId: "SP829",
            launchOSVersion: "14.2",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/2021-iphone12-mini-colors.png",
            capabilities: [.mini, .lightning, .wirelessCharging, .magSafe, .biometrics(.faceID), .esim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .barometer],
            models: ["A2176", "A2398", "A2400", "A2399"],
            colors: .iPhone12,
            cpu: .a14,
            cameras: [.iSight, .wide, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i54),
        iPhone(
            officialName: "iPhone 12 Pro",
            identifiers: ["iPhone13,3"],
            supportId: "SP831",
            launchOSVersion: "14.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-12-pro/iphone12-pro-colors.jpg",
            capabilities: [.pro, .lightning, .wirelessCharging, .magSafe, .biometrics(.faceID), .esim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .lidar, .barometer],
            models: ["A2341", "A2406", "A2408", "A2407"],
            colors: .iPhone12Pro,
            cpu: .a14,
            cameras: [.iSight, .wide, .telephoto, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i61x1170),
        iPhone(
            officialName: "iPhone 12 Pro Max",
            identifiers: ["iPhone13,4"],
            supportId: "SP832",
            launchOSVersion: "14.2",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-12-pro-max/iphone12-pro-max-colors.jpg",
            capabilities: [.pro, .max, .lightning, .wirelessCharging, .magSafe, .biometrics(.faceID), .esim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .lidar, .barometer],
            models: ["A2342", "A2410", "A2412", "A2411"],
            colors: .iPhone12Pro,
            cpu: .a14,
            cameras: [.iSight, .wide, .telephoto, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i67x1284),
        iPhone(
            officialName: "iPhone 13",
            identifiers: ["iPhone14,5"],
            supportId: "SP851",
            launchOSVersion: "15",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/2022-spring-iphone13-colors.png",
            capabilities: [.lightning, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .barometer],
            models: ["A2482", "A2631", "A2634", "A2635", "A2633"],
            colors: .iPhone13,
            cpu: .a15,
            cameras: [.iSight, .wide, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i61x1170),
        iPhone(
            officialName: "iPhone 13 mini",
            identifiers: ["iPhone14,4"],
            supportId: "SP847",
            launchOSVersion: "15",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/2022-iphone13-mini-colors.png",
            capabilities: [.mini, .lightning, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .barometer],
            models: ["A2481", "A2626", "A2629", "A2630", "A2628"],
            colors: .iPhone13,
            cpu: .a15,
            cameras: [.iSight, .wide, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i54),
        iPhone(
            officialName: "iPhone 13 Pro",
            identifiers: ["iPhone14,2"],
            supportId: "SP852",
            launchOSVersion: "15",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/2022-spring-iphone13-pro-colors.png",
            capabilities: [.pro, .lightning, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .lidar, .barometer],
            models: ["A2483", "A2636", "A2639", "A2640", "A2638"],
            colors: .iPhone13Pro,
            cpu: .a15,
            cameras: [.iSight, .wide, .telephoto, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i61x1170),
        iPhone(
            officialName: "iPhone 13 Pro Max",
            identifiers: ["iPhone14,3"],
            supportId: "SP848",
            launchOSVersion: "15",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/2022-spring-iphone13-pro-max-colors.png",
            capabilities: [.pro, .max, .lightning, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .lidar, .barometer],
            models: ["A2484", "A2641", "A2644", "A2645", "A2643"],
            colors: .iPhone13Pro,
            cpu: .a15,
            cameras: [.iSight, .wide, .telephoto, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i67x1284),
        iPhone(
            officialName: "iPhone SE (3rd generation)",
            identifiers: ["iPhone14,6"],
            supportId: "SP867",
            launchOSVersion: "15.4",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-se-3rd-gen-colors.png",
            capabilities: [.lightning, .wirelessCharging, .magSafe, .biometrics(.touchID), .dualesim, .applePay, .nfc, .ringerSwitch, .barometer],
            models: ["A2595", "A2782", "A2784", "Armenia,", "A2785", "A2783"],
            colors: .iPhoneSE3,
            cpu: .a15,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .fiveG,
            screen: .i47),
        iPhone(
            officialName: "iPhone 14",
            identifiers: ["iPhone14,7"],
            supportId: "SP873",
            launchOSVersion: "16",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-14-colors-spring-2023.png",
            capabilities: [.lightning, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .barometer, .crashDetection],
            models: ["A2649", "A2881", "A2884", "A2883", "A2882"],
            colors: .iPhone14,
            cpu: .a15,
            cameras: [.iSight, .wide, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i61x1170),
        iPhone(
            officialName: "iPhone 14 Plus",
            identifiers: ["iPhone14,8"],
            supportId: "SP874",
            launchOSVersion: "16",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-14-plus-colors-spring-2023.png",
            capabilities: [.plus, .lightning, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .notch, .ringerSwitch, .barometer, .crashDetection],
            models: ["A2632", "A2885", "A2888", "A2887", "A2886"],
            colors: .iPhone14,
            cpu: .a15,
            cameras: [.iSight, .wide, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i67x1284),
        iPhone(
            officialName: "iPhone 14 Pro",
            identifiers: ["iPhone15,2"],
            supportId: "SP875",
            launchOSVersion: "16",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-14-pro-colors.png",
            capabilities: [.pro, .lightning, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .dynamicIsland, .ringerSwitch, .lidar, .barometer, .crashDetection],
            models: ["A2650", "A2889", "A2892", "A2891", "A2890"],
            colors: .iPhone14Pro,
            cpu: .a16,
            cameras: [.iSight, .wide, .telephoto, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i61x1179),
        iPhone(
            officialName: "iPhone 14 Pro Max",
            identifiers: ["iPhone15,3"],
            supportId: "SP876",
            launchOSVersion: "16",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-14-pro-max-colors.png",
            capabilities: [.pro, .max, .lightning, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .dynamicIsland, .ringerSwitch, .lidar, .barometer, .crashDetection],
            models: ["A2651", "A2893", "A2896", "A2895", "A2894"],
            colors: .iPhone14Pro,
            cpu: .a16,
            cameras: [.iSight, .wide, .telephoto, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i67x1290),
        iPhone(
            officialName: "iPhone 15",
            identifiers: ["iPhone15,4"],
            supportId: "SP901",
            launchOSVersion: "17.0.2",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/fall-2023-iphone-colors-iphone-15.png",
            capabilities: [.usbC, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .dynamicIsland, .ringerSwitch, .barometer, .crashDetection],
            models: ["A2846", "A3089", "A3092", "A3090"],
            colors: .iPhone15,
            cpu: .a16,
            cameras: [.iSight, .wide, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i61x1179),
        iPhone(
            officialName: "iPhone 15 Plus",
            identifiers: ["iPhone15,5"],
            supportId: "SP902",
            launchOSVersion: "17.0.2",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/fall-2023-iphone-colors-iphone-15-plus.png",
            capabilities: [.plus, .usbC, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .dynamicIsland, .ringerSwitch, .barometer, .crashDetection],
            models: ["A2847", "A3093", "A3096", "A3094"],
            colors: .iPhone15,
            cpu: .a16,
            cameras: [.iSight, .wide, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i67x1290),
        iPhone(
            officialName: "iPhone 15 Pro",
            identifiers: ["iPhone16,1"],
            supportId: "SP903",
            launchOSVersion: "17.0.2",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/fall-2023-iphone-colors-iphone-15-pro.png",
            capabilities: [.pro, .usbC, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .dynamicIsland, .actionButton, .lidar, .barometer, .crashDetection],
            models: ["A2848", "A3101", "A3104", "A3102"],
            colors: .iPhone15Pro,
            cpu: .a17pro,
            cameras: [.iSight, .wide, .telephoto, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i61x1179),
        iPhone(
            officialName: "iPhone 15 Pro Max",
            identifiers: ["iPhone16,2"],
            supportId: "SP904",
            launchOSVersion: "17.0.2",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/fall-2023-iphone-colors-iphone-15-pro-max.png",
            capabilities: [.pro, .max, .usbC, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .dynamicIsland, .actionButton, .lidar, .barometer, .crashDetection],
            models: ["A2849", "A3105", "A3108", "A3106"],
            colors: .iPhone15Pro,
            cpu: .a17pro,
            cameras: [.iSight, .wide, .telephoto, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i67x1290),

        iPhone(
            officialName: "iPhone 16",
            identifiers: ["iPhone17,3"],
            supportId: "121029",
            launchOSVersion: "18.0",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-16-colors.png",
            capabilities: [.usbC, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .dynamicIsland, .actionButton, .cameraControl, .barometer, .crashDetection],
            models: ["A3081", "A3286,", "A3288", "A3287"],
            colors: .iPhone16,
            cpu: .a18,
            cameras: [.iSight, .wide, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i61x1179),
        iPhone(
            officialName: "iPhone 16 Plus",
            identifiers: ["iPhone17,4"],
            supportId: "121030",
            launchOSVersion: "18.0",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-16-plus-colors.png",
            capabilities: [.plus, .usbC, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .dynamicIsland, .actionButton, .cameraControl, .barometer, .crashDetection],
            models: ["A3082", "A3289,", "A3291", "A3290"],
            colors: .iPhone16,
            cpu: .a18,
            cameras: [.iSight, .wide, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i67x1290),
        iPhone(
            officialName: "iPhone 16 Pro",
            identifiers: ["iPhone17,1"],
            supportId: "121031",
            launchOSVersion: "18.0",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-16-pro-colors.png",
            capabilities: [.pro, .usbC, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .dynamicIsland, .actionButton, .cameraControl, .lidar, .barometer, .crashDetection],
            models: ["A3083", "A3292,", "A3294", "A3293"],
            colors: .iPhone16Pro,
            cpu: .a18pro,
            cameras: [.iSight, .wide, .telephoto, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i63),
        iPhone(
            officialName: "iPhone 16 Pro Max",
            identifiers: ["iPhone17,2"],
            supportId: "121032",
            launchOSVersion: "18.0",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-16-pro-max-colors.png",
            capabilities: [.pro, .max, .usbC, .wirelessCharging, .magSafe, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .dynamicIsland, .actionButton, .cameraControl, .lidar, .barometer, .crashDetection], // .spatialPhotography, .appleIntelligence, .satellite
            models: ["A3084", "A3295", "A3297", "A3296"],
            colors: .iPhone16Pro,
            cpu: .a18pro,
            cameras: [.iSight, .wide, .telephoto, .ultraWide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i69),

        iPhone(
            officialName: "iPhone 16e",
            identifiers: ["iPhone17,5"],
            supportId: "122208",
            launchOSVersion: "18.3.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/iphone/iphone-16e/iphone-16e-colors.png",
            capabilities: [.usbC, .wirelessCharging, .biometrics(.faceID), .dualesim, .applePay, .nfc, .roundedCorners, .notch, .actionButton, .barometer, .crashDetection],
            models: ["A3212", "A3408", "A3410", "A3409"],
            colors: .iPhone16e,
            cpu: .a18,
            cameras: [.iSight, .wide, .faceTimeHD720p, .trueDepth],
            cellular: .fiveG,
            screen: .i61x1170),
        
        // Get images and support links/IDs from: https://support.apple.com/en-us/108044
    ]
}

public struct iPad: IdiomType, HasScreen, HasCameras, HasCellular {
    public let device: Device
    public init(knownDevice: Device) {
        self.device = knownDevice
    }

    public init(
        officialName: String,
        identifiers: [String],
        supportId: String,
        launchOSVersion: Version,
        unsupportedOSVersion: Version?,
        image: String?,
        capabilities: Capabilities = [],
        models: [String] = [],
        colors: [MaterialColor],
        cpu: CPU,
        cameras: Set<Camera>,
        cellular: Cellular,
        screen: Screen,
        pencils: Set<ApplePencil> = []
    )
    {
        var capabilities = capabilities
        capabilities.cameras = cameras
        capabilities.cellular = cellular
        capabilities.screen = screen
        capabilities.pencils = pencils
        device = Device(
            idiom: .pad,
            officialName: officialName,
            identifiers: identifiers,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities.union([.battery]), // things ALL iPads have
            models: models,
            colors: colors,
            cpu: cpu
        )
    }
    
    init(identifier: String) {
        self.init(
            officialName: "Unknown iPad",
            identifiers: [identifier],
            supportId: .unknownSupportId,
            launchOSVersion: "18",
            unsupportedOSVersion: nil,
            image: nil,
            capabilities: identifier == .base ? [] : [
                // defaults for new unknown devices
                .usbC, .roundedCorners, .biometrics(.faceID),
            ],
            colors: .default,
            cpu: .unknown,
            cameras: [.wide, .trueDepth],
            cellular: identifier == .base ? .none : .fiveG,
            screen: identifier == .base ? .wUnknown : .i129,
            pencils: [.usbC])
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        if #available(iOS 16, macOS 13, macCatalyst 16, tvOS 16, watchOS 9,  *) {
            if biometrics == .faceID {
                return "ipad.gen2"
            } else {
                return "ipad.gen1"
            }
        } else {
            if biometrics == .faceID {
                return "ipad"
            } else {
                return "ipad.homebutton"
            }
        }
    }

    /// Returns whether or not the device is compatible with Apple Pencil
    public var isApplePencilCapable: Bool {
        pencils.count > 0
    }
    
    public var pencils: Set<ApplePencil> {
        return capabilities.pencils
    }

    static let all = [
        
        iPad(
            officialName: "iPad",
            identifiers: ["iPad1,1", "iPad1,2"], // 1,2 is 3g model
            supportId: "SP580",
            launchOSVersion: "3.2",
            unsupportedOSVersion: "6",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/identify-ipad.png",
            capabilities: [.headphoneJack, .thirtyPin, .ringerSwitch],
            models: ["A1219", "A1337"],
            colors: [.silver],
            cpu: .a4,
            cameras: [.iSight],
            cellular: .threeG,
            screen: .i97x768),
        iPad(
            officialName: "iPad 2",
            identifiers: ["iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4"],
            supportId: "sp622",
            launchOSVersion: "4.3",
            unsupportedOSVersion: "10",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/identify-ipad-2gen.png",
            capabilities: [.headphoneJack, .thirtyPin, .ringerSwitch],
            models: ["A1395", "A1396", "A1397"],
            colors: [.white, .black],
            cpu: .a5,
            cameras: [.iSight, .vga],
            cellular: .threeG,
            screen: .i97x768),
        iPad(
            officialName: "iPad (3rd generation)",
            identifiers: ["iPad3,1", "iPad3,2", "iPad3,3"],
            supportId: "SP647",
            launchOSVersion: "5.1",
            unsupportedOSVersion: "10",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/identify-ipad-3gen.png",
            capabilities: [.headphoneJack, .thirtyPin, .ringerSwitch],
            models: ["A1416", "A1430", "A1403"],
            colors: [.white, .black],
            cpu: .a5x,
            cameras: [.iSight, .vga], // 5mpx
            cellular: .lte,
            screen: .i97x1536),
        iPad(
            officialName: "iPad Mini",
            identifiers: ["iPad2,5", "iPad2,6", "iPad2,7"],
            supportId: "SP661",
            launchOSVersion: "6",
            unsupportedOSVersion: "10",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/identify-ipad-mini.png",
            capabilities: [.mini, .headphoneJack, .lightning, .ringerSwitch],
            models: ["A1432", "A1454", "A1455"],
            colors: [.white, .black],
            cpu: .a5,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i79x768),
        iPad(
            officialName: "iPad (4th generation)",
            identifiers: ["iPad3,4", "iPad3,5", "iPad3,6"],
            supportId: "SP662",
            launchOSVersion: "6",
            unsupportedOSVersion: "13",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/identify-ipad-4gen.png",
            capabilities: [.headphoneJack, .lightning, .ringerSwitch],
            models: ["A1458", "A1459", "A1460"],
            colors: [.white, .black],
            cpu: .a6x,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i97x1536),
        iPad(
            officialName: "iPad Air",
            identifiers: ["iPad4,1", "iPad4,2", "iPad4,3"],
            supportId: "SP692",
            launchOSVersion: "7.0.3",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/identify-ipad-air.png",
            capabilities: [.headphoneJack, .lightning, .ringerSwitch],
            models: ["A1474", "A1475", "A1476"],
            colors: .iPadAir,
            cpu: .a7,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i97x1536),
        iPad(
            officialName: "iPad Mini 2",
            identifiers: ["iPad4,4", "iPad4,5", "iPad4,6"],
            supportId: "SP693",
            launchOSVersion: "7.0.3",
            unsupportedOSVersion: "13",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/identify-ipad-mini2.png",
            capabilities: [.mini, .headphoneJack, .lightning, .ringerSwitch],
            models: ["A1489", "A1490", "A1491"],
            colors: .iPadAir,
            cpu: .a7,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i79x1536),
        iPad(
            officialName: "iPad Mini 3",
            identifiers: ["iPad4,7", "iPad4,8", "iPad4,9"],
            supportId: "SP709",
            launchOSVersion: "8.1",
            unsupportedOSVersion: "13",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/identify-ipad-mini3.png",
            capabilities: [.mini, .headphoneJack, .lightning, .biometrics(.touchID), .ringerSwitch],
            models: ["A1599", "A1600"],
            colors: .iPhone6,
            cpu: .a7,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i79x1536),
        iPad(
            officialName: "iPad Mini 4",
            identifiers: ["iPad5,1", "iPad5,2"],
            supportId: "SP725",
            launchOSVersion: "9",
            unsupportedOSVersion: "16",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/identify-ipad-mini4.png",
            capabilities: [.mini, .headphoneJack, .lightning, .biometrics(.touchID)],
            models: ["A1538", "A1550"],
            colors: .iPhone6,
            cpu: .a8,
            cameras: [.iSight, .faceTimeHD720p],
            cellular: .lte,
            screen: .i79x1536),
        iPad(
            officialName: "iPad Air 2",
            identifiers: ["iPad5,3", "iPad5,4"],
            supportId: "SP708",
            launchOSVersion: "8.1",
            unsupportedOSVersion: "16",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/identify-ipad-air2.png",
            capabilities: [.lightning, .biometrics(.touchID)],
            models: ["A1566", "A1567"],
            colors: .iPhone6,
            cpu: .a8x,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i97x1536),
        iPad(
            officialName: "iPad (5th generation)",
            identifiers: ["iPad6,11", "iPad6,12"],
            supportId: "SP751",
            launchOSVersion: "10.3",
            unsupportedOSVersion: "17",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ios11-ipad-5gen.png",
            capabilities: [.lightning, .biometrics(.touchID)],
            models: ["A1822", "A1823"], // TODO: Figure out why this had to be added manually and didn't parse.
            colors: .iPhone6,
            cpu: .a9,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i97x1536),
        iPad(
            officialName: "iPad Pro (9.7-inch)",
            identifiers: ["iPad6,3", "iPad6,4"],
            supportId: "SP739",
            launchOSVersion: "9.3",
            unsupportedOSVersion: "17",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/identify-ipad-pro-9-7.png",
            capabilities: [.pro, .lightning, .biometrics(.touchID)],
            models: ["A1673", "A1674", "A1675"],
            colors: [.spaceGray6, .silver6, .gold6, .roseGoldA4],
            cpu: .a9x,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i97x1536,
            pencils: [.firstGeneration]),
        iPad(
            officialName: "iPad Pro (12.9-inch)",
            identifiers: ["iPad6,7", "iPad6,8"],
            supportId: "SP723",
            launchOSVersion: "9.1",
            unsupportedOSVersion: "17",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/identify-ipad-pro.png",
            capabilities: [.pro, .lightning, .biometrics(.touchID)],
            models: ["A1584", "A1652"],
            colors: .iPhone6,
            cpu: .a9x,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i129,
            pencils: [.firstGeneration]),
        iPad(
            officialName: "iPad Pro 12.9-inch (2nd generation)",
            identifiers: ["iPad7,1", "iPad7,2"],
            supportId: "SP761",
            launchOSVersion: "10.3.2",
            unsupportedOSVersion: "18",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ios11-ipad-pro-12-in.png",
            capabilities: [.pro, .lightning, .biometrics(.touchID)],
            models: ["A1670", "A1671", "A1821"],
            colors: .iPhone6,
            cpu: .a10x,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i129,
            pencils: [.firstGeneration]),
        iPad(
            officialName: "iPad Pro (10.5-inch)",
            identifiers: ["iPad7,3", "iPad7,4"],
            supportId: "SP762",
            launchOSVersion: "10.3.2",
            unsupportedOSVersion: "18",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ios11-ipad-pro-10-in.png",
            capabilities: [.pro, .lightning, .biometrics(.touchID)],
            models: ["A1701", "A1709", "A1852"],
            colors: [.spaceGray6, .silver6, .gold6, .roseGoldSE],
            cpu: .a10x,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i105,
            pencils: [.firstGeneration]),
        iPad(
            officialName: "iPad (6th generation)",
            identifiers: ["iPad7,5", "iPad7,6"],
            supportId: "SP774",
            launchOSVersion: "11.4",
            unsupportedOSVersion: "18",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ios11-3-ipad-9-7-in-2018.png",
            capabilities: [.lightning, .biometrics(.touchID)],
            models: ["A1893", "A1954"],
            colors: [.spaceGray6, .silver6, .goldM5],
            cpu: .a10,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i97x1536,
            pencils: [.firstGeneration]),
        iPad(
            officialName: "iPad Pro 11-inch",
            identifiers: ["iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4"],
            supportId: "SP784",
            launchOSVersion: "12.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ios12-ipad-pro-11-in.png",
            capabilities: [.pro, .usbC, .biometrics(.faceID), .esim, .roundedCorners, .notch],
            models: ["A1980", "A2013,", "A1934", "A1979"],
            colors: [.spaceGrayM5, .silver6],
            cpu: .a12x,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i11,
            pencils: [.secondGeneration, .usbC]),
        iPad(
            officialName: "iPad Pro 12.9-inch (3rd generation)",
            identifiers: ["iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8"],
            supportId: "SP785",
            launchOSVersion: "12.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ios12-ipad-pro-12-9-in.png",
            capabilities: [.pro, .usbC, .biometrics(.faceID), .esim, .roundedCorners, .notch, .barometer],
            models: ["A1876", "A2014,", "A1895", "A1983"],
            colors: [.spaceGrayM5, .silver6],
            cpu: .a12x,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i129,
            pencils: [.secondGeneration, .usbC]),
        iPad(
            officialName: "iPad Air (3rd generation)",
            identifiers: ["iPad11,3", "iPad11,4"],
            supportId: "SP787",
            launchOSVersion: "12.2",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ipad-air-3gen.png",
            capabilities: [.lightning, .biometrics(.touchID), .esim],
            models: ["A2152", "A2123,", "A2153", "A2154"],
            colors: .iPadMini5,
            cpu: .a12,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i105,
            pencils: [.firstGeneration]),
        iPad(
            officialName: "iPad Mini (5th generation)",
            identifiers: ["iPad11,1", "iPad11,2"],
            supportId: "SP788",
            launchOSVersion: "12.2",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ipad-mini-5gen.png",
            capabilities: [.mini, .headphoneJack, .lightning, .biometrics(.touchID), .esim],
            models: ["A2133", "A2124,", "A2126", "A2125"],
            colors: .iPadMini5,
            cpu: .a12,
            cameras: [.iSight, .faceTimeHD1080p],
            cellular: .lte,
            screen: .i79x1536,
            pencils: [.firstGeneration]),
        iPad(
            officialName: "iPad (7th generation)",
            identifiers: ["iPad7,11", "iPad7,12"],
            supportId: "SP807",
            launchOSVersion: "13.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ipad-7th-gen.png",
            capabilities: [.lightning, .biometrics(.touchID), .esim],
            models: ["A2197", "A2200,", "A2198"],
            colors: .iPadMini5,
            cpu: .a10,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i102,
            pencils: [.firstGeneration]),
        iPad(
            officialName: "iPad Pro 11-inch (2nd generation)",
            identifiers: ["iPad8,9", "iPad8,10"],
            supportId: "SP814",
            launchOSVersion: "13.4",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ios13-4-ipad-pro-4gen-11-in.png",
            capabilities: [.pro, .usbC, .biometrics(.faceID), .esim, .roundedCorners, .notch, .lidar, .barometer],
            models: ["A2228", "A2068,", "A2230", "A2231"],
            colors: [.spaceGrayM5, .silver6],
            cpu: .a12z,
            cameras: [.iSight, .wide, .ultraWide, .trueDepth],
            cellular: .lte,
            screen: .i11,
            pencils: [.secondGeneration, .usbC]),
        iPad(
            officialName: "iPad Pro 12.9-inch (4th generation)",
            identifiers: ["iPad8,11", "iPad8,12"],
            supportId: "SP815",
            launchOSVersion: "13.4",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ios13-4-ipad-pro-4gen-12-9-in.png",
            capabilities: [.pro, .usbC, .biometrics(.faceID), .esim, .roundedCorners, .notch, .lidar, .barometer],
            models: ["A2229", "A2069,", "A2232", "A2233"],
            colors: [.spaceGrayM5, .silver6],
            cpu: .a12z,
            cameras: [.iSight, .wide, .ultraWide, .trueDepth],
            cellular: .lte,
            screen: .i129,
            pencils: [.secondGeneration, .usbC]),
        iPad(
            officialName: "iPad (8th generation)",
            identifiers: ["iPad11,6", "iPad11,7"],
            supportId: "SP822",
            launchOSVersion: "14",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ipad-8th-gen-colors.png",
            capabilities: [.lightning, .biometrics(.touchID), .esim],
            models: ["A2270", "A2428,", "A2429,", "A2430"],
            colors: .iPadMini5,
            cpu: .a12,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i102,
            pencils: [.firstGeneration]),
        iPad(
            officialName: "iPad (9th generation)",
            identifiers: ["iPad12,1", "iPad12,2"],
            supportId: "SP849",
            launchOSVersion: "15",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ipad-2021-colors.png",
            capabilities: [.lightning, .biometrics(.touchID), .esim],
            models: ["A2602", "A2604", "A2603", "A2605"],
            colors: [.spaceGray9, .silver6],
            cpu: .a13,
            cameras: [.iSight],
            cellular: .lte,
            screen: .i102,
            pencils: [.firstGeneration]),
        iPad(
            officialName: "iPad Air (4th generation)",
            identifiers: ["iPad13,1", "iPad13,2"],
            supportId: "SP828",
            launchOSVersion: "14.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ipad-air-4th-gen-colors.png",
            capabilities: [.usbC, .biometrics(.touchID), .esim, .roundedCorners, .barometer],
            models: ["A2316", "A2324,", "A2325,", "A2072"],
            colors: [.spaceGrayM5, .silver6, .roseGoldA4, .skyBlueA4, .greenA4],
            cpu: .a14,
            cameras: [.iSight, .wide, .faceTimeHD1080p],
            cellular: .lte,
            screen: .i109,
            pencils: [.secondGeneration, .usbC]),
        iPad(
            officialName: "iPad Air (5th generation)",
            identifiers: ["iPad13,16", "iPad13,17"],
            supportId: "SP866",
            launchOSVersion: "15.4",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad-air-5th-gen-colors.png",
            capabilities: [.usbC, .biometrics(.touchID), .esim, .roundedCorners, .barometer],
            models: ["A2588", "A2589,", "A2591"],
            colors: [.spaceGrayA5, .starlightA5, .pinkA5, .purpleA5, .blueA5],
            cpu: .m1,
            cameras: [.iSight, .wide, .faceTimeHD1080p],
            cellular: .fiveG,
            screen: .i109,
            pencils: [.secondGeneration, .usbC]),
        iPad(
            officialName: "iPad (10th generation)",
            identifiers: ["iPad13,18", "iPad13,19"],
            supportId: "SP884",
            launchOSVersion: "16.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/fall-2022-10-gen-ipad.png",
            capabilities: [.usbC, .biometrics(.touchID), .esim, .roundedCorners],
            models: ["A2696", "A2757", "A2777", "A3162"],
            colors: .iPad10,
            cpu: .a14,
            cameras: [.iSight],
            cellular: .fiveG,
            screen: .i109,
            pencils: [.firstGeneration, .usbC]),
        iPad(
            officialName: "iPad Pro 11-inch (3rd generation)",
            identifiers: ["iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7"],
            supportId: "SP843",
            launchOSVersion: "14.5.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/2021-ipad-pro-11-colors.png",
            capabilities: [.pro, .usbC, .thunderbolt, .biometrics(.faceID), .esim, .roundedCorners, .notch, .lidar, .barometer],
            models: ["A2377", "A2459", "A2301", "A2460"],
            colors: [.spaceGrayM5, .silver6],
            cpu: .m1,
            cameras: [.iSight, .wide, .ultraWide, .trueDepth],
            cellular: .fiveG,
            screen: .i11,
            pencils: [.secondGeneration, .usbC]),
        iPad(
            officialName: "iPad Pro 12.9-inch (5th generation)",
            identifiers: ["iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11"],
            supportId: "SP844",
            launchOSVersion: "14.5.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/2021-ipad-pro-12-9-colors.png",
            capabilities: [.pro, .usbC, .thunderbolt, .biometrics(.faceID), .esim, .roundedCorners, .notch, .lidar, .barometer],
            models: ["A2378", "A2461", "A2379"],
            colors: [.spaceGrayM5, .silver6],
            cpu: .m1,
            cameras: [.iSight, .wide, .ultraWide, .trueDepth],
            cellular: .fiveG,
            screen: .i129,
            pencils: [.secondGeneration, .usbC]),
        iPad(
            officialName: "iPad Mini (6th generation)",
            identifiers: ["iPad14,1", "iPad14,2"],
            supportId: "SP850",
            launchOSVersion: "15",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/ipad-mini-2021-colors.png",
            capabilities: [.mini, .usbC, .biometrics(.touchID), .esim, .roundedCorners],
            models: ["A2567", "A2568", "A2569"],
            colors: [.spaceGrayA5, .starlightA5, .pinkA5, .purpleA5],
            cpu: .a15,
            cameras: [.iSight, .wide, .faceTimeHD1080p],
            cellular: .fiveG,
            screen: .i83,
            pencils: [.secondGeneration, .usbC]),
        iPad(
            officialName: "iPad Pro 11-inch (4th generation)",
            identifiers: ["iPad14,3", "iPad14,4"],
            supportId: "SP882",
            launchOSVersion: "16.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/fall-2022-11-inch-4gen-ipad-pro.png",
            capabilities: [.pro, .usbC, .thunderbolt, .biometrics(.faceID), .esim, .roundedCorners, .notch, .lidar, .barometer],
            models: ["A2759", "A2761", "A2435", "A2762"],
            colors: [.spaceGrayM5, .silver6],
            cpu: .m2,
            cameras: [.iSight, .wide, .ultraWide, .trueDepth],
            cellular: .fiveG,
            screen: .i11,
            pencils: [.secondGeneration, .usbC]),
        iPad(
            officialName: "iPad Pro 12.9-inch (6th generation)",
            identifiers: ["iPad14,5", "iPad14,6"],
            supportId: "SP883",
            launchOSVersion: "16.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad/fall-2022-12-9-inch-6gen-ipad-pro.png",
            capabilities: [.pro, .usbC, .thunderbolt, .biometrics(.faceID), .esim, .roundedCorners, .notch, .lidar, .barometer],
            models: ["A2436", "A2437", "A2764", "A2766"],
            colors: [.spaceGrayM5, .silver6],
            cpu: .m2,
            cameras: [.iSight, .wide, .ultraWide, .trueDepth],
            cellular: .fiveG,
            screen: .i129,
            pencils: [.secondGeneration, .usbC]),

        // 2024 Spring models
        iPad(
            officialName: "iPad Air 11-inch (M2)",
            identifiers: ["iPad14,8", "iPad14,9"],
            supportId: "119894",
            launchOSVersion: "17.5",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/spring-2024-4.png",
            capabilities: [.usbC, .biometrics(.touchID), .esim, .roundedCorners, .barometer],
            models: ["A2902", "A2903", "A2904"],
            colors: .iPadAirM2,
            cpu: .m2,
            cameras: [.wide, .faceTimeHD1080p],
            cellular: .fiveG,
            screen: .i109,
            pencils: [.usbC, .pro]),
        iPad(
            officialName: "iPad Air 13-inch (M2)",
            identifiers: ["iPad14,10", "iPad14,11"],
            supportId: "119893",
            launchOSVersion: "17.5",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/spring-2024-3.png",
            capabilities: [.usbC, .biometrics(.touchID), .esim, .roundedCorners, .barometer],
            models: ["A2898", "A2899", "A2900"],
            colors: .iPadAirM2,
            cpu: .m2,
            cameras: [.wide, .faceTimeHD1080p],
            cellular: .fiveG,
            screen: .i129,
            pencils: [.usbC, .pro]),
        iPad(
            officialName: "iPad Pro 11-inch (M4)",
            identifiers: ["iPad16,3", "iPad16,4"],
            supportId: "119892",
            launchOSVersion: "17.5",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/spring-2024-2.png",
            capabilities: [.pro, .usbC, .thunderbolt, .biometrics(.faceID), .esim, .roundedCorners, .notch, .lidar, .barometer],
            models: ["A2836", "A2837", "A3006"],
            colors: [.macbookSpaceblack, .solidSilver],
            cpu: .m4,
            cameras: [.wide, .trueDepth],
            cellular: .fiveG,
            screen: .i11,
            pencils: [.usbC, .pro]),
        iPad(
            officialName: "iPad Pro 13-inch (M4)",
            identifiers: ["iPad16,5", "iPad16,6"],
            supportId: "119891",
            launchOSVersion: "17.5",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/spring-2024-1.png",
            capabilities: [.pro, .usbC, .thunderbolt, .biometrics(.faceID), .esim, .roundedCorners, .notch, .lidar, .barometer],
            models: ["A2925", "A2926", "A3007"],
            colors: [.macbookSpaceblack, .solidSilver],
            cpu: .m4,
            cameras: [.wide, .trueDepth],
            cellular: .fiveG,
            screen: .i13,
            pencils: [.usbC, .pro]),
        iPad(
            officialName: "iPad mini (A17 Pro)",
            identifiers: ["iPad16,1", "iPad16,2"],
            supportId: "121456",
            launchOSVersion: "18", // iPadOS 18 (22A8350)
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/ipad-mini/ipad-mini-2024-colors.png",
            capabilities: [.mini, .usbC, .biometrics(.touchID), .esim, .roundedCorners],
            models: ["A2993", "A2995", "A2996"],
            colors: .iPadAirM2,
            cpu: .a17pro,
            cameras: [.iSight, .wide, .faceTimeHD1080p],
            cellular: .fiveG,
            screen: .i83,
            pencils: [.pro, .usbC]),
        iPad(
            officialName: "iPad Air 13-inch (M3)",
            identifiers: ["iPad15,5", "iPad15,6"],
            supportId: "122242",
            launchOSVersion: "18.2.1", // TODO: Check
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/spring-2025-ipad-air-13.png",
            capabilities: [.usbC, .biometrics(.touchID), .esim, .roundedCorners, .barometer],
            models: ["A3268", "A3269", "A3271"],
            colors: .iPadAirM2,
            cpu: .m3,
            cameras: [.wide, .faceTimeHD1080p],
            cellular: .fiveG,
            screen: .i129,
            pencils: [.usbC, .pro]),
        iPad(
            officialName: "iPad Air 11-inch (M3)",
            identifiers: ["iPad15,3", "iPad15,4"],
            supportId: "122241",
            launchOSVersion: "18.2.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/spring-2025-ipad-air-11.png",
            capabilities: [.usbC, .biometrics(.touchID), .esim, .roundedCorners, .barometer],
            models: ["A3266", "A3267", "A3270"],
            colors: .iPadAirM2,
            cpu: .m3,
            cameras: [.wide, .faceTimeHD1080p],
            cellular: .fiveG,
            screen: .i109,
            pencils: [.usbC, .pro]),
        iPad(
            officialName: "iPad (A16)",
            identifiers: ["iPad15,7", "iPad15,8"],
            supportId: "122240",
            launchOSVersion: "18.2.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/ipad/spring-2025-ipad.png",
            capabilities: [.usbC, .biometrics(.touchID), .esim, .roundedCorners, .barometer],
            models: ["A3354", "A3355", "A3356"],
            colors: .iPad10,
            cpu: .a16,
            cameras: [.wide, .faceTimeHD1080p],
            cellular: .fiveG,
            screen: .i109,
            pencils: [.firstGeneration, .usbC]),
    ]
}

public struct AppleTV: IdiomType {
    public let device: Device
    public init(knownDevice: Device) {
        self.device = knownDevice
    }

    public init(
        officialName: String,
        identifiers: [String],
        supportId: String,
        launchOSVersion: Version,
        unsupportedOSVersion: Version?,
        image: String?,
        capabilities: Capabilities = [],
        models: [String] = [],
        cpu: CPU)
    {
        device = Device(
            idiom: .tv,
            officialName: officialName,
            identifiers: identifiers,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities.union([.headphoneJack, .screen(.tv)]),
            models: models,
            colors: [.black],
            cpu: cpu)
    }

    init(identifier: String) {
        self.init(
            officialName: "Unknown  TV",
            identifiers: [identifier],
            supportId: .unknownSupportId,
            launchOSVersion: "18",
            unsupportedOSVersion: nil,
            image: nil,
            cpu: .unknown)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return "appletv"
    }

    static let all = [ // https://support.apple.com/en-us/101605
        
        AppleTV(
            officialName: "Apple TV 4K (3rd generation) Wi-Fi + Ethernet",
            identifiers: ["AppleTV14,1"],
            supportId: "SP886",
            launchOSVersion: "16.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/fall-2022-apple-tv-w-remote.png",
            models: ["A2843"],
            cpu: .a15),
        AppleTV(
            officialName: "Apple TV 4K (3rd generation) Wi-Fi",
            identifiers: ["AppleTV14,1"],
            supportId: "SP886",
            launchOSVersion: "16.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/fall-2022-apple-tv-w-remote.png",
            models: ["A2737"],
            cpu: .a15),
        AppleTV(
            officialName: "Apple TV 4K (2nd generation)",
            identifiers: ["AppleTV11,1"],
            supportId: "SP845",
            launchOSVersion: "14.5",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-4k-2nd-gen.png",
            models: ["A2169"],
            cpu: .a12),
        AppleTV(
            officialName: "Apple TV 4K (1st generation)",
            identifiers: ["AppleTV6,2"],
            supportId: "SP769",
            launchOSVersion: "11",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-4k.jpg",
            models: ["A1842"],
            cpu: .a10x),
        AppleTV(
            officialName: "Apple TV HD",
            identifiers: ["AppleTV5,3"],
            supportId: "SP724",
            launchOSVersion: "9",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-4gen-hd.jpg",
            capabilities: [.usbC],
            models: ["A1625"],
            cpu: .a8),
        // These models don't support app development but are here since they're in the identification page and are here for reference.
        AppleTV(
            officialName: "Apple TV (3rd generation) rev A",
            identifiers: ["AppleTV3,2"],
            supportId: "SP648",
            launchOSVersion: "6.1",
            unsupportedOSVersion: "8",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-3gen.jpg",
            capabilities: [], // .microUSB
            models: ["A1469"],
            cpu: .a5),
        AppleTV(
            officialName: "Apple TV (3rd generation)",
            identifiers: ["AppleTV3,1"],
            supportId: "SP648",
            launchOSVersion: "5.1",
            unsupportedOSVersion: "8",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-3gen.jpg",
            capabilities: [], // .microUSB
            models: ["A1427"],
            cpu: .a5),
        AppleTV(
            officialName: "Apple TV (2nd generation)",
            identifiers: ["AppleTV2,1"],
            supportId: "SP598",
            launchOSVersion: "4.1", // iOS variant
            unsupportedOSVersion: "7", // max 6.2.1
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-2gen.jpg",
            capabilities: [],
            models: ["A1378"],
            cpu: .a4),
        AppleTV(
            officialName: "Apple TV (1st generation)",
            identifiers: ["AppleTV1,1"],
            supportId: "SP19",
            launchOSVersion: "10.4.7", // stripped down macOS
            unsupportedOSVersion: "10.5", // not updated
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-tv/apple-tv-1gen.jpg",
            capabilities: [], // .ethernet
            models: ["A1218"],
            cpu: .intel),

    ]
}


public struct AppleWatch: IdiomType, HasScreen, HasCellular {
    public let device: Device
    public init(knownDevice: Device) {
        self.device = knownDevice
    }

    public var bandSize: WatchSize.BandSize {
        watchSize.bandSize
    }
    public enum WatchSize: CaseNameConvertible, Sendable {
        case unknown
        case mm38
        case mm40
        case mm41
        case mm42
        case mm42s // 2024 series 10 small version
        case mm44
        case mm45
        case mm46
        case mm49 // ultra
        
        public enum BandSize: CaseNameConvertible, Sendable {
            case small // 38mm, 40mm, 41mm
            case large // 42mm, 44mm, 45mm, 49mm
        }
        public var bandSize: BandSize {
            switch self {
            case .mm38,.mm40, .mm41, .mm42s:
                return .small
            default: // everything else
                return .large
            }
        }
        public var screen: Screen {
            switch self {
            case .unknown: return .wUnknown // placeholder
            case .mm38: return .w38
            case .mm40: return .w40
            case .mm41: return .w41
            case .mm42: return .w42
            case .mm42s: return .w42s
            case .mm44: return .w44
            case .mm45: return .w45
            case .mm46: return .w46
            case .mm49: return .w49
            }
        }
    }
    
    public init(
        officialName: String,
        identifiers: [String],
        supportId: String,
        launchOSVersion: Version,
        unsupportedOSVersion: Version?,
        image: String?,
        capabilities: Capabilities = [],
        models: [String] = [],
        colors: [MaterialColor],
        cpu: CPU, // TODO: Add cellular?
        size: WatchSize
    ) {
        device = Device(
            idiom: .watch,
            officialName: officialName,
            identifiers: identifiers,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities.union([.battery, .wirelessCharging, .nfc, .applePay, .screen(size.screen), .roundedCorners, .watchSize(size)]),
            models: models,
            colors: colors,
            cpu: cpu
        )
    }
    
    init(identifier: String) {
        self.init(
            officialName: "Unknown  Watch",
            identifiers: [identifier],
            supportId: .unknownSupportId,
            launchOSVersion: "11",
            unsupportedOSVersion: nil,
            image: nil,
            colors: .default,
            cpu: .unknown,
            size: .unknown)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return "applewatch"
    }
    
    public var watchSize: WatchSize {
        return capabilities.watchSize ?? .unknown // should always be present
    }

    static let all = [ // since various materials use same identifier, by convention, use the aluminum versions for smaller and most expensive versions for larger body version.

        AppleWatch(
            officialName: "Apple Watch (1st generation) 38mm",
            identifiers: ["Watch1,1"],
            supportId: "SP735",
            launchOSVersion: "1",
            unsupportedOSVersion: "5",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/1st-gen-apple-watch-stainless.png",
            capabilities: [.force3DTouch],
            colors: .watch0,
            cpu: .s1,
            size: .mm38),
        AppleWatch(
            officialName: "Apple Watch (1st generation) 42mm",
            identifiers: ["Watch1,2"],
            supportId: "SP735",
            launchOSVersion: "1",
            unsupportedOSVersion: "5",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/1st-gen-apple-watch-edition-gold.png",
            capabilities: [.force3DTouch],
            colors: .watch0,
            cpu: .s1,
            size: .mm42),
        AppleWatch(
            officialName: "Apple Watch Series 1 38mm",
            identifiers: ["Watch2,6"],
            supportId: "SP745",
            launchOSVersion: "3",
            unsupportedOSVersion: "7",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/watch-series1-aluminum.png",
            capabilities: [.force3DTouch],
            colors: .watch1,
            cpu: .s1p,
            size: .mm38),
        AppleWatch(
            officialName: "Apple Watch Series 1 42mm",
            identifiers: ["Watch2,7"],
            supportId: "SP745",
            launchOSVersion: "3",
            unsupportedOSVersion: "7",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/watch-series1-aluminum.png",
            capabilities: [.force3DTouch],
            colors: .watch1,
            cpu: .s1p,
            size: .mm42),
        AppleWatch(
            officialName: "Apple Watch Series 2 38mm",
            identifiers: ["Watch2,3"],
            supportId: "SP746",
            launchOSVersion: "3",
            unsupportedOSVersion: "7",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/watch-series2-aluminum.png",
            capabilities: [.force3DTouch],
            colors: .watch2,
            cpu: .s2,
            size: .mm38),
        AppleWatch(
            officialName: "Apple Watch Series 2 42mm",
            identifiers: ["Watch2,4"],
            supportId: "SP746",
            launchOSVersion: "3",
            unsupportedOSVersion: "7",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/watch-series2-edition.png",
            capabilities: [.force3DTouch],
            colors: .watch2,
            cpu: .s2,
            size: .mm42),
        AppleWatch(
            officialName: "Apple Watch Series 3 38mm",
            identifiers: ["Watch3,1", "Watch3,3"],
            supportId: "SP766",
            launchOSVersion: "4",
            unsupportedOSVersion: "9",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/series3-apple-watch-gps-aluminum.png",
            capabilities: [.force3DTouch],
            colors: .watch3,
            cpu: .s3,
            size: .mm38),
        AppleWatch(
            officialName: "Apple Watch Series 3 42mm",
            identifiers: ["Watch3,2", "Watch3,4"],
            supportId: "SP766",
            launchOSVersion: "4",
            unsupportedOSVersion: "9",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/series3-apple-watch-cellular-gps-ceramic.png",
            capabilities: [.force3DTouch],
            colors: .watch3,
            cpu: .s3,
            size: .mm42),
        AppleWatch(
            officialName: "Apple Watch Series 4 40mm",
            identifiers: ["Watch4,1", "Watch4,3"],
            supportId: "SP778",
            launchOSVersion: "5",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/series4-apple-watch-aluminum-gps.png",
            capabilities: [.force3DTouch],
            colors: .watch4,
            cpu: .s4,
            size: .mm40),
        AppleWatch(
            officialName: "Apple Watch Series 4 44mm",
            identifiers: ["Watch4,2", "Watch4,4"],
            supportId: "SP778",
            launchOSVersion: "5",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/series4-apple-watch-stainless-gps-cellular.png",
            capabilities: [.force3DTouch],
            colors: .watch4,
            cpu: .s4,
            size: .mm44),
        AppleWatch(
            officialName: "Apple Watch Series 5 40mm",
            identifiers: ["Watch5,1", "Watch5,3"],
            supportId: "SP808",
            launchOSVersion: "6",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/series5-apple-watch-aluminum-gps.png",
            capabilities: [.force3DTouch],
            colors: .watch5,
            cpu: .s5,
            size: .mm40),
        AppleWatch(
            officialName: "Apple Watch Series 5 44mm",
            identifiers: ["Watch5,2", "Watch5,4"],
            supportId: "SP808",
            launchOSVersion: "6",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/series5-apple-watch-titanium-edition.png",
            capabilities: [.force3DTouch],
            colors: .watch5,
            cpu: .s5,
            size: .mm44),
        AppleWatch(
            officialName: "Apple Watch Series 6 40mm",
            identifiers: ["Watch6,1", "Watch6,3"],
            supportId: "SP826",
            launchOSVersion: "7",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series6-aluminum-gps-colors.png",
            colors: .watch6,
            cpu: .s6,
            size: .mm40),
        AppleWatch(
            officialName: "Apple Watch Series 6 44mm",
            identifiers: ["Watch6,2", "Watch6,4"],
            supportId: "SP826",
            launchOSVersion: "7",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series6-titanium-colors.png",
            colors: .watch6,
            cpu: .s6,
            size: .mm44),
        AppleWatch(
            officialName: "Apple Watch SE 40mm",
            identifiers: ["Watch5,9", "Watch5,11"],
            supportId: "SP827",
            launchOSVersion: "7",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series6-000-aluminum-gps-colors.png",
            colors: .watchSE,
            cpu: .s5,
            size: .mm40),
        AppleWatch(
            officialName: "Apple Watch SE 44mm",
            identifiers: ["Watch5,10", "Watch5,12"],
            supportId: "SP827",
            launchOSVersion: "7",
            unsupportedOSVersion: "11",
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series6-000-aluminum-gps-cellular-colors.png",
            colors: .watchSE,
            cpu: .s5,
            size: .mm44),
        AppleWatch(
            officialName: "Apple Watch Series 7 41mm",
            identifiers: ["Watch6,6", "Watch6,8"],
            supportId: "SP860",
            launchOSVersion: "8",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/2021-apple-watch-series7-aluminum-gps.png",
            colors: .watch7,
            cpu: .s7,
            size: .mm41),
        AppleWatch(
            officialName: "Apple Watch Series 7 45mm",
            identifiers: ["Watch6,7", "Watch6,9"],
            supportId: "SP860",
            launchOSVersion: "8",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/2021-apple-watch-series7-titanium-gps-cellular.png",
            colors: .watch7,
            cpu: .s7,
            size: .mm45),
        AppleWatch(
            officialName: "Apple Watch Series 8 41mm",
            identifiers: ["Watch6,14", "Watch6,16"],
            supportId: "SP878",
            launchOSVersion: "9",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/fall-2022-watch-series8-aluminum-gps.png",
            colors: .watch8,
            cpu: .s8,
            size: .mm41),
        AppleWatch(
            officialName: "Apple Watch Series 8 45mm",
            identifiers: ["Watch6,15", "Watch6,17"],
            supportId: "SP878",
            launchOSVersion: "9",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/fall-2022-watch-series8-stainless-gps-cellular.png",
            colors: .watch8,
            cpu: .s8,
            size: .mm45),
        AppleWatch(
            officialName: "Apple Watch SE (2nd generation) 40mm",
            identifiers: ["Watch6,10", "Watch6,12"],
            supportId: "SP877",
            launchOSVersion: "9",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/fall-2022-watch-series8-se-gps.png",
            colors: .watchSE2,
            cpu: .s8,
            size: .mm40),
        AppleWatch(
            officialName: "Apple Watch SE (2nd generation) 44mm",
            identifiers: ["Watch6,11", "Watch6,13"],
            supportId: "SP877",
            launchOSVersion: "9",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/fall-2022-watch-series8-se-gps-cellular.png",
            colors: .watchSE2,
            cpu: .s8,
            size: .mm44),
        AppleWatch(
            officialName: "Apple Watch Ultra",
            identifiers: ["Watch6,18"],
            supportId: "SP879",
            launchOSVersion: "9",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/fall-2022-apple-watch-ultra.png",
            capabilities: [.actionButton],
            colors: .watchUltra,
            cpu: .s8,
            size: .mm49),
        AppleWatch(
            officialName: "Apple Watch Series 9 41mm",
            identifiers: ["Watch7,1", "Watch7,3"],
            supportId: "SP905",
            launchOSVersion: "10.0.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series-9-gps.png",
            capabilities: [.crashDetection],
            colors: .watch9,
            cpu: .s9,
            size: .mm41),
        AppleWatch(
            officialName: "Apple Watch Series 9 45mm",
            identifiers: ["Watch7,2", "Watch7,4"],
            supportId: "SP905",
            launchOSVersion: "10.0.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series-9-stainless-gps-cellular.png",
            capabilities: [.crashDetection],
            colors: .watch9,
            cpu: .s9,
            size: .mm45),
        AppleWatch(
            officialName: "Apple Watch Ultra 2",
            identifiers: ["Watch7,5"],
            supportId: "SP906",
            launchOSVersion: "10.0.1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-ultra-2-colors.png",
            capabilities: [.actionButton, .crashDetection],
            colors: .watchUltra2,
            cpu: .s9,
            size: .mm49),
        AppleWatch(
            officialName: "Apple Watch Series 10 42mm",
            identifiers: ["Watch7,8", "Watch7,10"],
            supportId: "121202",
            launchOSVersion: "11",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series-10-aluminum-gps.png",
            capabilities: [.crashDetection],
            models: ["A2997", "A3001"],
            colors: .watch10,
            cpu: .s10,
            size: .mm42s),
        AppleWatch(
            officialName: "Apple Watch Series 10 46mm",
            identifiers: ["Watch7,9", "Watch7,11"],
            supportId: "121202",
            launchOSVersion: "11",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/apple-watch/apple-watch-series-10-titanium.png",
            capabilities: [.crashDetection],
            colors: .watch10,
            cpu: .s10,
            size: .mm46),
    ]
}


public struct HomePod: IdiomType {
    public let device: Device
    public init(knownDevice: Device) {
        self.device = knownDevice
    }

    public init(
        officialName: String,
        identifiers: [String],
        supportId: String,
        launchOSVersion: Version,
        unsupportedOSVersion: Version?,
        image: String?,
        capabilities: Capabilities = [],
        models: [String] = [],
        colors: [MaterialColor],
        cpu: CPU)
    {
        device = Device(idiom: .homePod, officialName: officialName, identifiers: identifiers, supportId: supportId, launchOSVersion: launchOSVersion, unsupportedOSVersion: unsupportedOSVersion, image: image, capabilities: capabilities.union([.screen(.w38)]), models: models, colors: colors, cpu: cpu)
    }
    
    init(identifier: String) {
        self.init(
            officialName: "Unknown HomePod",
            identifiers: [identifier],
            supportId: .unknownSupportId,
            launchOSVersion: "11",
            unsupportedOSVersion: nil,
            image: nil,
            colors: .default,
            cpu: .unknown
        )
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        if self.is(.mini) {
            return "homepodmini"
        }
        return "homepod"
    }

    static let all = [
        
        HomePod(
            officialName: "HomePod",
            identifiers: ["AudioAccessory1,1"],
            supportId: "SP773",
            launchOSVersion: "1",
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/7WUAS350/images/homepod/2018-homepod-colors.png",
            colors: [.spacegrayHome, .whiteHome],
            cpu: .a8),
        HomePod(
            officialName: "HomePod mini",
            identifiers: ["AudioAccessory5,1"],
            supportId: "SP834",
            launchOSVersion: "14.2", // audioOS
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/SZLF0YNV/images/sp/111914_homepod-mini-colours.png",
            capabilities: [.mini],
            colors: .homePodMini,
            cpu: .s5),
        HomePod(
            officialName: "HomePod (2nd generation)",
            identifiers: ["AudioAccessory6,1"],
            supportId: "SP888",
            launchOSVersion: "16", // audioOS
            unsupportedOSVersion: nil,
            image: "https://cdsassets.apple.com/live/SZLF0YNV/images/sp/111843_homepod-2gen.png",
            colors: .homePod,
            cpu: .s7),
        
    ]
}


public struct AppleVision: IdiomType, HasCameras {
    public let device: Device
    public init(knownDevice: Device) {
        self.device = knownDevice
    }

    public init(
        officialName: String,
        identifiers: [String],
        supportId: String,
        launchOSVersion: Version,
        unsupportedOSVersion: Version?,
        image: String?,
        capabilities: Capabilities = [],
        models: [String] = [],
        cpu: CPU
    ) {
        device = Device(
            idiom: .vision,
            officialName: officialName,
            identifiers: identifiers,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: [.battery, .biometrics(.opticID), .lidar, .cameras([.stereoscopic, .persona]), .screen(.p720)],
            models: models,
            colors: [.silver],
            cpu: cpu
        )
    }
    
    init(identifier: String) {
        self.init(
            officialName: "Unknown  Vision Device",
            identifiers: [identifier],
            supportId: .unknownSupportId,
            launchOSVersion: "2",
            unsupportedOSVersion: nil,
            image: nil,
            cpu: .unknown)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return "visionpro"
    }

    static let all = [

        AppleVision(
            officialName: "Apple Vision Pro",
            identifiers: ["RealityDevice14,1"],
            supportId: "SP911",
            launchOSVersion: "1.0.2",
            unsupportedOSVersion: nil,
            image: "https://help.apple.com/assets/65E610E3F8593B4BE30B127E/65E610E47F977D429402E427/en_US/4609019342a9aa9c2560aaeb92e6c21a.png",
            cpu: .m2),
        
    ]
}
