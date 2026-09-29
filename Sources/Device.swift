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

/// Publishes Device's version, dependency graph, diagnostics, and reusable checks through Compatibility.
///
/// Device is a top-level library module: applications should register ``Device`` and let Compatibility
/// recursively register its direct dependencies.
extension Device: Module {
    /// The version of the Device Library since cannot get directly from Package.
    public static let version: Version = "2.15.0"
    
    /// The public source repository used for open-source support and license discovery.
    public static let openSourceRepository: String? = "https://github.com/kudit/Device"
    
    /// Compatibility is the only module Device uses directly for shared build and support behavior.
    public static let dependencies: [Module.Type] = [ColorKit.self,  Compatibility.self]
    
    /// Immediate, portable information that can be displayed without actor isolation or deferred work.
    public static var moduleInfo: [Field] {
        [
            Field("Model", "\(Device.identifier)"),
        ]
    }
    
    /// Loads complete structured information that may require actor isolation, calculation, or deferred work.
    ///
    /// This requirement is separately availability-gated so the rest of ``Module`` remains usable before
    /// Swift concurrency became available on Apple platforms. The default returns ``moduleInfo`` unchanged.
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    public static func loadDetailedModuleInfo() async -> [Field] {
        return await Device.current.info
    }
    
#if compiler(>=5.9)
    /// Ordered checks shared by Compatibility's in-app test UI and external test bridges.
    @MainActor
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    public static let tests: OrderedDictionary<String, [TestCase]> = [
        "Device Lookup": [
            TestCase("Known identifier lookup") {
                let device = Device(identifier: "iPhone16,1")
                try expectEqual(device.idiom, .phone)
                try expect(device.identifiers.contains("iPhone16,1"), "Known identifiers should include the requested identifier")
                try expect(!device.officialName.isEmpty, "Known devices should have an official name")
            },
            TestCase("Unknown identifier fallback") {
                let identifier = "FutureDevice99,1"
                let device = Device(identifier: identifier)
                try expect(device.identifiers.contains(identifier), "Unknown identifiers should remain usable")
                try expectEqual(device.idiom, .unspecified)
            },
        ],
        "Device Capabilities": [
            TestCase("Capability queries") {
                let fiveGPhone = Device(identifier: "iPhone13,2")
                let earlierPhone = Device(identifier: "iPhone12,1")
                try expectEqual(fiveGPhone.cellular, .fiveG)
                try expectNotEqual(earlierPhone.cellular, .fiveG)
                try expect(fiveGPhone.has(.gps), "The iPhone 13 should report GPS support")
            },
            TestCase("Product-family lookup") {
                let matches = Device.lookup(officialNameHint: "Apple Watch Series 10 (GPS + Cellular) 42mm")
                try expect(!matches.isEmpty, "The catalog should contain Apple Watch Series 10")
                try expect(matches.allSatisfy { $0.idiom == .watch }, "Product-family hints should restrict lookup results")
            },
        ],
        "Screens": [
            TestCase("Single and non-addressable screen collections") {
                let phone = Device(identifier: "iPhone13,2")
                try expectEqual(phone.screens, phone.screen.map { [$0] } ?? [])
                for identifier in ["AudioAccessory5,1", "AppleTV6,2", "RealityDevice17,1"] {
                    try expect(Device(identifier: identifier).screens.isEmpty, "No fixed addressable app screens for \(identifier)")
                }
            },
            TestCase("Multiple panels preserve the single-screen API and Codable metadata") {
                let front = Screen(resolution: (1398,2034), ppi: 460)
                let inner = Screen(resolution: (1878,2670), ppi: 430)
                var capabilities = Capabilities()
                capabilities.screens = [front, inner]
                try expectEqual(capabilities.screen, front)
                try expectEqual(capabilities.screens, [front, inner])
                // Updating the primary screen must not discard secondary metadata.
                capabilities.screen = .i63
                try expectEqual(capabilities.screens, [.i63, inner])
                #if canImport(Foundation)
                let decoded = try JSONDecoder().decode(Capabilities.self, from: JSONEncoder().encode(capabilities))
                try expectEqual(decoded.screens, capabilities.screens)
                #endif
                capabilities.screens = []
                try expect(capabilities.screen == nil && capabilities.screens.isEmpty)
            },
            TestCase("Duo draft exposes front and inner panels") {
                // The draft currently shares an identifier with another model;
                // select by exact name without changing the maintainer's placeholder.
                let duo = Device.all.first { $0.officialName == "iPhone Duo" }
                try expectEqual(duo?.screens.count, 2)
                try expectEqual(duo?.screen, duo?.screens.first)
            },
            TestCase("Host identifier validation excludes compatibility and board values") {
                #if os(macOS) || os(iOS)
                try expect(Device.isMacModelIdentifier("Mac14,10"))
                try expect(Device.isMacModelIdentifier("Mac99,999"))
                try expect(Device.isMacModelIdentifier("MacBookPro18,1"))
                for invalid in ["iPad8,6", "arm64", "J414AP", "", "Mac14,10 extra"] {
                    try expect(!Device.isMacModelIdentifier(invalid), "Reject non-product identifier \(invalid)")
                }
                #endif
            },
        ],
        "Legacy Device Tests": [
            TestCase("Capability queries") {
                
                let device = Device(identifier: "Mac14,10")
                
                //    let expectedDevice = Device(identifier: "iPhone16,1")
                let expectedDevice = Device(identifier: "Mac14,10")
                
                try expect(device.officialName == expectedDevice.officialName)
                try expect(device.idiom == .mac)
                try expect(device.idiom == expectedDevice.idiom)
                try expect(device.identifiers.contains("Mac14,10"))
                try expect(expectedDevice.identifiers == device.identifiers)
                try expect(!device.has(.force3DTouch))
                try expect(device.is(.pro))
                try expect(!device.is(.plus))
                try expect(device.has(.battery))
                try expect(device.has(.headphoneJack))
                // Environment checks describe this test process, not the detected hardware model.
//        try expect(!Build.isSimulator)
//        try expect(!Build.isPreview)
//        try expect(Build.isRealDevice)
//        if let battery = Device.current.battery {
//          try expect(battery.currentState == .unplugged)
//          try expect(battery.currentLevel  >= 75)
//          try expect(!battery.lowPowerMode)
//        }
//        try expect(Device.current.device.screenBrightness < 50)
//        try expect(Device.current.volumeAvailableCapacityForOpportunisticUsage ?? 0 > Int64(1_000_000))
//        try expect(Device.current.volumeAvailableCapacityForImportantUsage ?? 0 > Int64(1_000))
            },
            TestCase("GPS Capability Defaults and Exceptions") {
                // GPS is modeled at the idiom level for iPhones and Apple Watches because all
                // known devices in those families include GPS, avoiding repeated per-model flags.
                try expect(Device.Idiom.phone.capabilities.contains(.gps))
                try expect(Device.Idiom.watch.capabilities.contains(.gps))
                
                // Wi-Fi-only iPads and iPods should stay GPS-free; the listed identifiers come
                // from DeviceKit's no-GPS discussion and protect the defaulting logic.
                let noGPSIdentifiers: Set<String> = [
                    "iPad2,1", "iPad2,4", "iPad3,1", "iPad3,4", "iPad6,11", "iPad7,5",
                    "iPad7,11", "iPad11,6", "iPad12,1", "iPad13,18", "iPad4,1", "iPad5,3",
                    "iPad11,3", "iPad13,1", "iPad13,16", "iPad14,8", "iPad14,10", "iPad2,5",
                    "iPad4,4", "iPad4,7", "iPad5,1", "iPad11,1", "iPad14,1", "iPad6,7",
                    "iPad6,3", "iPad7,3", "iPad7,1", "iPad8,1", "iPad8,2", "iPad8,5",
                    "iPad8,6", "iPad8,9", "iPad8,11", "iPad13,4", "iPad13,8", "iPad14,3",
                    "iPad14,5", "iPad16,3", "iPad16,5", "iPod1,1", "iPod2,1", "iPod3,1",
                    "iPod4,1", "iPod5,1", "iPod7,1", "iPod9,1"
                ]
                
                for identifier in noGPSIdentifiers {
                    let device = Device(identifier: identifier)
                    if device.idiom == .pad {
//              if identifier != device.identifiers.first { // could be first and second depending
//              try expect(false, "\(identifier) should not be in the noGPSIdentifiers list")
//              }
                        // Can't really test this.
                    } else {
                        try expect(!Device(identifier: identifier).has(.gps))
                    }
                }
                
                // Walk every known iPad identifier so any model not in the no-GPS exception
                // list must expose GPS, matching the cellular/Wi-Fi split in the model data.
//        for device in iPad.allDevices {
//          for identifier in device.identifiers {
//              if identifier.hasPrefix("iPad") && !noGPSIdentifiers.contains(identifier) {
//              try expect(Device(identifier: identifier).has(.gps))
//              }
//          }
//        }
                // Unable to truly test.
                
                // Cellular iPads get GPS from their cellular generation, while iPhones inherit
                // GPS from the phone idiom default.
//        try expect(Device(identifier: "iPad2,2").has(.gps))
                try expect(Device(identifier: "iPhone1,1").has(.gps))
                try expect(Device(identifier: "Watch1,1").has(.gps))
            },
            
            TestCase("Test 5G Tracks Cellular Generation without duplicate capability") {
                // 5G is represented by the existing cellular enum, which avoids a duplicate
                // capability flag drifting away from the already-maintained model data.
                try expect(Device(identifier: "iPhone13,2").cellular == .fiveG)
                try expect(Device(identifier: "iPad13,17").cellular == .fiveG)
//        try expect(Device(identifier: "iPad13,16").cellular == Cellular.none) // TODO: Have some sort of check for multiple identifiers and depending which identifier, applying cellular or not.
                try expect(Device(identifier: "iPhone12,1").cellular != .fiveG)
            },
            TestCase("Test Apple Watch paired identifiers are split into GPS and cellular definitions") {
                let splitPairs: [(gps: String, cellular: String)] = [
                    ("Watch3,1", "Watch3,3"),
                    ("Watch3,2", "Watch3,4"),
                    ("Watch4,1", "Watch4,3"),
                    ("Watch4,2", "Watch4,4"),
                    ("Watch5,1", "Watch5,3"),
                    ("Watch5,2", "Watch5,4"),
                    ("Watch6,1", "Watch6,3"),
                    ("Watch6,2", "Watch6,4"),
                    ("Watch5,9", "Watch5,11"),
                    ("Watch5,10", "Watch5,12"),
                    ("Watch6,6", "Watch6,8"),
                    ("Watch6,7", "Watch6,9"),
                    ("Watch6,14", "Watch6,16"),
                    ("Watch6,15", "Watch6,17"),
                    ("Watch6,10", "Watch6,12"),
                    ("Watch6,11", "Watch6,13"),
                    ("Watch7,1", "Watch7,3"),
                    ("Watch7,2", "Watch7,4"),
                    ("Watch7,8", "Watch7,10"),
                    ("Watch7,9", "Watch7,11"),
                    ("Watch7,13", "Watch7,15"),
                    ("Watch7,14", "Watch7,16"),
                    ("Watch7,17", "Watch7,19"),
                    ("Watch7,18", "Watch7,20"),
                ]
                
                // Each historical two-identifier watch definition should now live as two
                // adjacent, independently maintained records so adding a future watch still
                // only requires editing AppleWatches.swift data instead of expansion logic.
                for pair in splitPairs {
                    let gpsWatch = Device(identifier: pair.gps)
                    let cellularWatch = Device(identifier: pair.cellular)
                    
                    try expect(gpsWatch.identifiers == [pair.gps])
                    try expect(cellularWatch.identifiers == [pair.cellular])
                    try expect(!gpsWatch.has(.cellular(.lte)))
                    // Older cellular watches use LTE; current catalog entries use 5G.
                    try expect(cellularWatch.has(.cellular(.lte)) || cellularWatch.has(.cellular(.fiveG)))
                    try expect(gpsWatch.officialName.contains("GPS"))
                    try expect(cellularWatch.officialName.contains("GPS + Cellular"))
                }
                
                // This catches any future re-grouping of GPS and cellular watch identifiers
                // into a single definition, which would hide variant-specific data again.
                for watch in AppleWatch.allDevices {
                    try expect(watch.identifiers.count == 1)
                }
            },
            TestCase("Lookup Matches support page year qualified macbook air names") {
                // Apple's Identify pages can include the launch year in the MacBook Air M5
                // name even though the library definition omits it, so lookup must still
                // find the local model for color disambiguation and migration diffs.
                let matches = Device.lookup(officialNameHint: "MacBook Air (15-inch, M5, 2026)")
                
                // Fuzzy lookup may return equally plausible candidates, so verify the
                // uniquely identified M5 15-inch model without depending on sort order.
                try expect(matches.first?.identifiers == ["Mac17,4"])
                try expect(matches.first?.colors == .macbookAir2025)
            },
            TestCase("Lookup filter apple watch name fallback by idiom") {
                // This intentionally uses name-only lookup to exercise the expensive
                // fallback used when an Apple support model number is missing or unknown.
                let matches = Device.lookup(officialNameHint: "Apple Watch Series 10 (GPS + Cellular) 42mm")
                
                try expect(!matches.isEmpty)
                try expect(matches.allSatisfy { $0.idiom == .watch })
            },
            TestCase("Test known identifier lookup") {
                let device = Device(identifier: "iPhone16,1")
                
                try expectEqual(device.idiom, .phone)
                try expect(device.identifiers.contains("iPhone16,1"))
                try expectEqual(device.officialName.isEmpty, false)
            },
            TestCase("Test unknown identifier fallback") {
                /// Verifies unknown identifiers remain usable instead of failing lookup.
                let identifier = "FutureDevice99,1"
                let device = Device(identifier: identifier)
                
                try expect(device.identifiers.contains(identifier))
                try expectEqual(device.idiom, .unspecified)
            },
            TestCase("iPhone compass generation boundary") {
                // The original iPhone and iPhone 3G predate Apple's digital compass;
                // the iPhone 3GS introduced it and all later iPhones retain it.
                try expect(!Device(identifier: "iPhone1,1").has(.compass))
                try expect(!Device(identifier: "iPhone1,2").has(.compass))
                try expect(Device(identifier: "iPhone2,1").has(.compass))
                try expect(Device(identifier: "iPhone16,1").has(.compass))
            },
            TestCase("Capability Queries") {
                /// Verifies capability queries distinguish established hardware generations.
                let fiveGPhone = Device(identifier: "iPhone13,2")
                let earlierPhone = Device(identifier: "iPhone12,1")
                
                try expectEqual(fiveGPhone.cellular, .fiveG)
                try expectNotEqual(earlierPhone.cellular, .fiveG)
                try expect(fiveGPhone.has(.gps))
            },
            TestCase("Lookup filters by product family") {
                /// Verifies fuzzy lookup limits an explicit Apple Watch name to watch models.
                let matches = Device.lookup(
                    officialNameHint: "Apple Watch Series 10 (GPS + Cellular) 42mm"
                )
                
                try expect(!matches.isEmpty)
                try expect(matches.allSatisfy { $0.idiom == .watch })
            },
        ],
    ]
#endif
}
import Compatibility
import Color // for DeviceInfoView and displaying/converting colors from strings.

#if canImport(UIKit)
import UIKit // for UIUserInterfaceIdiom
#endif

public extension String {
    /// Replaces special characters with their ASCII equivalent (such as "iPhone Xʀ" => "iPhone XR" and "" => "Apple"
    var safeDescription: String {
        return self
            .replacingOccurrences(of: "ʀ", with: "R")
            .replacingOccurrences(of: "", with: "Apple")
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
#if canImport(Foundation) && !(os(WASM) || os(WASI)) // not available in WASM?
        return DateString(Date.nowBackport.mysqlDate)
#else
        return DateString("1970-01-01") // clearly wrong but shouldn't practically be needed anyways.
#endif
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
//  var year: Int? { device.introduction?.date?.year }
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
//    return URL(string: "https://support.apple.com/kb/index?page=search&src=support_docs_serp&locale=en_US&doctype=DOCUMENTATIONS&q=\(searchTerm.urlEncoded)")!
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
        // iPads with multiple identifiers have a wifi and cellular model.  Only the cellular model has gps
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
    /// The primary display, preserving the original single-screen API.
    /// Multi-display devices use their front panel when an active panel cannot be determined.
    /// This is catalog metadata, not a runtime window or connected-monitor query.
    var screen: Screen? { device.capabilities.screen }

    /// Fixed, addressable displays in primary/front-first order.
    ///
    /// Single-screen devices return one item. Devices without a fixed addressable
    /// screen return an empty array, including HomePod, Apple TV and visionOS hardware.
    /// Vision Pro's physical panel specification remains available through `screen`
    /// for compatibility, but those panels are not independently addressable app screens.
    /// A count greater than one denotes multiple panels, not necessarily a foldable device.
    var screens: [Screen] {
        guard ![Device.Idiom.homePod, .tv, .vision, .carPlay].contains(idiom) else { return [] }
        // Undefined placeholders are not actual displays. Keep them available to
        // legacy `screen` callers while excluding them from the new collection API.
        return device.capabilities.screens.filter { $0.resolution.width > 0 && $0.resolution.height > 0 }
    }

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
//  var cameras: Int { device.cameras }
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
    
//  /// A textual representation of the device.
//  var description: String { device.description }
    
    var idiomatic: any IdiomType {
        // convert to idiomatic device so we can reference the correct implementation of symbolName.
        guard let idiomatic = device.idiom.type.init(device: device) else {
            return device // use default if we can't convert for some reason
        }
        return idiomatic
    }
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    var symbolName: String {
        return idiomatic.symbolName
    }
        
    /// A safe version of `officialName`.
    /// Example:
    /// Device.iPhoneXR.officialName:   iPhone Xʀ
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
//    self.init(identifier: .base) // what is this for?  So we set defaults?  Assume everything is set
        // replace the device created above
        self.init(knownDevice: device)
    }
    // must be included in implementations since we can't assign this in an init
//  public init(knownDevice: Device) {
//    self.device = knownDevice
//  }
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
        
        public var officialNames: [String] {
            switch self {
            case .mac:
                return ["MacBook", "MacBook Neo", "MacBook Air", "MacBook Pro", "Mac Pro", "Mac Studio", "Mac Mini", "iMac"]
            case .pod:
                return ["iPod"]
            case .phone:
                return ["iPhone"]
            case .pad:
                return ["iPad"]
            case .tv:
                return ["Apple TV"]
            case .carPlay:
                return ["CarPlay"]
            case .watch:
                return ["Apple Watch"]
            case .homePod:
                return ["HomePod"]
            case .vision:
                return ["Apple Vision Pro"]
            case .unspecified:
                fallthrough
            @unknown default:
                return ["Unspecified"]
            }
        }
        
        /// Infers an idiom only from explicit product-family wording in a lookup hint.
        /// Returning `nil` for an ambiguous hint preserves the full fuzzy search.
        public init?(fromNameHint hint: String) {
            let hint = hint.safeDescription.lowercased()
            // Check the more specific portable families before Mac because names such
            // as "MacBook" contain the broader "Mac" token.
            for idiom in Self.allCases {
                if hint.containsAny(idiom.officialNames.map { $0.safeDescription.lowercased() }) {
                    self = idiom
                    return
                }
            }
            return nil
        }
        
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
//      default:
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
//      @unknown default:
//        return "UnknownDevice"
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
            @unknown default:
                return "UnknownDevice"
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
//      print(String(describing: prototypical))
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
            case .phone:
                // Every iPhone generation includes GPS, so keeping this in the idiom default
                // prevents individual phone definitions from drifting as new models are added.
                return [.battery, .gps]
            case .pad:
                return [.battery]
            case .tv:
                return [.headphoneJack, .screens([.tv])]
            case .watch:
                // All Apple Watch model families are GPS-capable, including GPS-only and
                // cellular variants, so this belongs at the idiom default level.
                return [.battery, .wirelessCharging, .nfc, .applePay, .gps]
            case .vision: // All visions are pro for now.  When this is no longer the case, move this to each device.
                return [.pro, .battery, .biometrics(.opticID), .lidar, .cameras([.stereoscopic, .persona]), .screens([.p720]), .appleIntelligence]
            case .homePod:
                return [.screens([.w38])]
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
        // Bridge loaders ask the same lookup questions repeatedly while
        // constructing matched and merged projections. Cache the immutable
        // result so those repeated scans do not walk Device.all again.
        let cacheKey = "\(identifier ?? "\u{2400}")|\(model ?? "\u{2400}")|\(supportId ?? "\u{2400}")|\(officialNameHint ?? "\u{2400}")"
        lookupCacheLock.lock()
        let cached = lookupCache[cacheKey]
        lookupCacheLock.unlock()
        if let cached { return cached }
        var matchingDevices: [Device] = []
        // Normalize the hint once for the entire lookup. The same prepared values
        // are reused by fallback filtering and result ordering instead of being
        // reconstructed for every candidate's `matchScore` invocation.
        let matchHint = officialNameHint.map(MatchHint.init)
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
        // Some support pages do not provide a usable model or identifier, so name
        // matching remains the fallback. When the hint names an unmistakable Apple
        // product family, limit that fallback to the corresponding idiom before
        // doing normalized string work. This prevents an Apple Watch lookup from
        // scoring every iPod, Mac, phone, and other unrelated device definition.
        if matchingDevices.isEmpty, let matchHint {
            let candidates: [Device]
            if let hintedIdiom = Idiom(fromNameHint: matchHint.original) {
                candidates = Device.all.filter { $0.idiom == hintedIdiom }
            } else {
                // Ambiguous names deliberately retain the broad historical search
                // rather than risking a false negative from an inferred category.
                candidates = Device.all
            }
            matchingDevices = candidates.filter { $0.matchScore(matchHint) > 0.1 }
        }
        guard matchingDevices.count > 1 else {
            lookupCacheLock.lock()
            lookupCache[cacheKey] = matchingDevices
            lookupCacheLock.unlock()
            return matchingDevices // no need to sort or anything if we already have exactly one or zero matches
        }
        // Sorting can invoke its comparator many times. Calculate each normalized
        // match score once per candidate so repeated comparisons become dictionary
        // lookups instead of repeating normalization and year-qualifier removal.
        let scores = Dictionary(uniqueKeysWithValues: matchingDevices.map { device in
            (device, device.matchScore(matchHint))
        })
        matchingDevices.sort { scores[$0, default: 0] > scores[$1, default: 0] }
//      debug("MATCH RESULTS:\n\(matchingDevices.map { "\($0.matchScore(officialNameHint)): \($0.officialName)" }.joined(separator: "\n"))")
        lookupCacheLock.lock()
        lookupCache[cacheKey] = matchingDevices
        lookupCacheLock.unlock()
        return matchingDevices
    }

    /// Lookup results are immutable for the lifetime of the process; this
    /// lightweight cache removes repeated fuzzy scans during bridge setup.
    private static var lookupCache: [String: [Device]] = [:]
    private static let lookupCacheLock = NSLock()

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
#if canImport(Foundation) && !(os(WASM) || os(WASI)) // not available in WASM?
        return "\(identifiers)|\(introduction?.mysqlDate ?? "?")|\(models)|\(officialName)|\(cpu)"
#else
        return "\(identifiers)|\(introduction ?? "?")|\(models)|\(officialName)|\(cpu)"
#endif
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
    /// Device.iPhoneXR.officialName:   iPhone Xʀ
    /// Device.iPhoneXR.safeOfficialName: iPhone XR
    public var safeOfficialName: String {
        return officialName.safeDescription
    }
    
    @available(*, deprecated, renamed: "safeOfficialName", message: "Renamed to be clearer and resolve conflicts with CustomStringConvertible.description")
    public var safeDescription: String {
        return officialName.safeDescription
    }

    /// Prepared forms of a known device name used by fuzzy matching. This value is
    /// immutable so the process-wide cache is naturally safe for concurrent reads.
    private struct MatchName {
        let original: String
        let normalized: String
        let yearless: String

        init(_ name: String) {
            original = name
            normalized = name.safeDescription.normalized
            yearless = normalized.removingParentheticalYearQualifiers
        }
    }

    /// Prepared forms of one caller-provided hint. A lookup creates this once and
    /// passes it through every score calculation performed during that lookup.
    private struct MatchHint {
        let original: String
        let normalized: String
        let yearless: String

        init(_ hint: String) {
            original = hint
            normalized = hint.safeDescription.normalized
            // need to normalize AFTER removing parentheticals
            yearless = hint.safeDescription.removingParentheticalYearQualifiers.normalized
        }
    }

    /// Known definitions never change after `Device.all` is initialized, so cache
    /// their normalized and yearless names once for the lifetime of this process.
    /// Dynamically constructed devices still receive an on-demand prepared value.
    private static let matchNameCache: [Device: MatchName] = Dictionary(
        uniqueKeysWithValues: Device.all.map { ($0, MatchName($0.officialName)) })

    private var cachedMatchName: MatchName {
        Device.matchNameCache[self] ?? MatchName(officialName)
    }
    
    /// Returns a score indicating the quality of the match for identifying specific models.  1.0 is a perfect match.
    public func matchScore(_ officialNameHint: String?) -> Double {
        guard let officialNameHint else {
            return 0 // unable to match since no hint given.
        }
        return matchScore(MatchHint(officialNameHint))
    }

    /// Scores against already prepared hint and device-name components so lookup
    /// runs do not repeat normalization or parenthetical-year removal.
    private func matchScore(_ hint: MatchHint?) -> Double {
        guard let hint else {
            return 0
        }
        let officialName = cachedMatchName
        if officialName.original == hint.original {
            return 1
        }
        if officialName.normalized == hint.normalized {
            return 0.9
        }
        if officialName.yearless == hint.yearless {
            // Apple support pages sometimes add a launch year to otherwise stable
            // product names (for example the 2026 M5 MacBook Air pages), while the
            // local definitions may intentionally omit that year.  Treat those as a
            // strong fuzzy match so color and support-page imports keep resolving.
            return 0.85
        }
        if officialName.normalized.contains(hint.normalized) {
            // check processor appended
            let stripped = officialName.normalized.replacingOccurrences(of: hint.normalized, with: "").whitespaceCollapsed.replacingCharacters(in: .whitespacesAndNewlines, with: "").trimmed.lowercased()
            if stripped == self.cpu.caseName {
                return 0.7
            }
            return 0.5
        }
        if hint.original.contains(officialName.normalized) {
            return 0.3
        }
        return 0.1
    }
}

private extension String {
    /// Returns a matching key with a trailing parenthetical four-digit year removed.
    ///
    /// Support pages can publish a year newer than the host application's current
    /// calendar year, so matching must recognize the shape of the qualifier rather
    /// than relying on a fixed range ending at `Date.nowBackport.year`.
    var removingParentheticalYearQualifiers: String {
        let trimmedName = trimmed
        guard trimmedName.last == ")",
              let closingParenthesis = trimmedName.lastIndex(of: ")") else {
            return self
        }

        let contentBeforeClosing = trimmedName[..<closingParenthesis]
        guard let comma = contentBeforeClosing.lastIndex(of: ",") else {
            return self
        }

        let possibleYear = contentBeforeClosing[contentBeforeClosing.index(after: comma)...].trimmed
        guard possibleYear.count == 4,
              possibleYear.allSatisfy(\.isNumber) else {
            return self
        }

        // Remove only the final year segment so chip and screen-size qualifiers remain.
        debug("removing parenthetical year qualifiers from: \(trimmedName)")
        return String(contentBeforeClosing[..<comma].trimmed) + ")"
    }
}

// MARK: - Device Idiom Types (moved to Models files)
