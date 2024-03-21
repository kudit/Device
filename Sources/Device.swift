/**
 Device type and structs.
 
 Model definitions are included here but are not marked public.  If you need these public (rather than just using these for current device lookups), please let us know your use-case.
 A big thank you to all that help update this list!
 
 Contributors:
 - Ben Ku
 - Heath Hall
 - https://github.com/schickling/Device.swift
 */

#if canImport(UIKit)
import UIKit
#endif

/// Type for inheritance of specific idiom structs which use a Device as a backing store but allows for idiom-specific variables and functions and acts like a sub-class of Device but still having value-type backing.  TODO: Make this private so we don't access DeviceType outside of here?
public protocol DeviceType: CustomStringConvertible {
    var device: Device { get }
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    var symbolName: String { get } // include here so that we use the idiomatic implementation rather than the default implementation below.
}
public extension DeviceType {
    var idiom: Device.Idiom { device.idiom }
    var name: String { device.name }
    var identifiers: [String] { device.identifiers }
    var supportId: String? { device.supportId }
    var image: String? { device.image }
    var isPro: Bool { device.isPro }
    
    // Hardware Info
    var cpu: CPU { device.cpu }
    var hasBattery: Bool { device.hasBattery }
    var cellular: Cellular { device.cellular }
    var supportsWirelessCharging: Bool { device.supportsWirelessCharging }
    var biometrics: Biometrics { device.biometrics }
    var hasForce3dTouchSupport: Bool { device.hasForce3dTouchSupport }
    var cameras: Int { device.cameras }
    var hasLidarSensor: Bool { device.hasLidarSensor }
    var hasUSBCConnectivity: Bool { device.hasUSBCConnectivity }
    
    // Display Info
    var screen: Screen? { device.screen }
    
    /// A textual representation of the device.
    var description: String { device.description }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    var symbolName: String {
        // convert to idiomatic device so we can reference the correct implementation of symbolName.
        guard let idiomatic = device.idiom.type.init(device: device) else {
//            print("Unable to idomatic device. \(device)")
            return device.symbolName // use default if we can't convert for some reason
        }
//        print(idiomatic.symbolName)
        return idiomatic.symbolName
    }
        
    /// A safe version of `description`.
    /// Example:
    /// Device.iPhoneXR.description:     iPhone Xʀ
    /// Device.iPhoneXR.safeDescription: iPhone XR
    var safeDescription: String { device.safeDescription }
}
/// Type for generating and iterating over IdiomTypes for convenient initialization in Models file and for iterating over when searching for a model identifier.
/// NOT PUBLIC since we shouldn't be initing off of identifiers outside of this module.  This is for internal device lookups.  If you need something like this external to this module, please let us know.
protocol IdiomType: DeviceType {
    var device: Device { get set } // Idioms can set, but external should not be directly setting this.
    init(identifier: String)
    static var all: [Self] { get }
    init?(device: Device)
}
extension IdiomType {
    static var allDevices: [Device] {
        all.map { $0.device }
    }
    init?(device: Device) {
        guard device.idiom.type == Self.self else {
            return nil
        }
        self.init(identifier: "OVERWRITE")
        // replace the device created above
        self.device = device
    }
}

public struct Device: CustomStringConvertible, IdiomType {
    /// Constants that indicate the interface type for the device or an object that has a trait environment, such as a view and view controller.
    public enum Idiom: CaseIterable, Identifiable, CustomStringConvertible {
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
        /// An interface designed for Home Pod
        case homePod
        /// An interface designed for Apple Watch
        case watch
        /// An interface designed for an in-car experience.
        case carPlay
        /// An interface designed for visionOS and Apple Vision Pro.
        case vision
        
#if os(iOS) || targetEnvironment(macCatalyst) || os(tvOS) || os(visionOS)
        /// Only available on devices that support UIUserInterfaceIdiom.
        /// Returns the UIUserInterfaceIdiom for this device.
        public var userInterfaceIdiom: UIUserInterfaceIdiom {
            switch self {
            case .mac:
                return .mac
            case .phone:
                return .phone
            case .pad:
                return .pad
            case .tv:
                return .tv
            case .carPlay:
                return .carPlay
            case .vision:
                if #available(iOS 17.0, visionOS 1.0, *) {
                    return .vision
                } else {
                    // Fallback on earlier versions
                    return .unspecified
                }
            default:
                return .unspecified
            }
        }
#endif
        
        public var identifier: String {
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
        public var description: String {
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
            case .homePod:
                return "HomePod"
            case .watch:
                return " Watch"
            case .carPlay:
                return "CarPlay"
            case .vision:
                return " Vision"
                //            @unknown default:
                //                return "UnknownDevice"
            }
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
            let prototypical = self.type.init(identifier: "Prototype") // create a dummy version but don't include prefix or it will recursively loop.
//            print(String(describing: prototypical))
            return prototypical.symbolName
        }
    }
    
    // MARK: - Initialization and variables
    // Device info
    public var idiom: Device.Idiom // need to include the Device. namespace for type checking below
    public var name: String
    public var identifiers: [String]
    public var supportId: String?
    public var image: String?
    public var isPro: Bool
    
    // Hardware Info
    public var cpu: CPU
    public var hasBattery: Bool
    public var cellular: Cellular
    /// Returns whether or not the device supports wireless charging.  TODO: Do we need a property specifically for supporting mag-safe wireless?  Perhaps turn this into an enum for "connectors" listing charging types/connector types including wifi, bluetooth, bluetoothle, etc, lighting, magsafe, magSafe1, magSafe2, magSafe3, USBC, other, 30pin, AppleWatch, AC Power, ethernet, HDMI, SDCard, headphone jack, etc?.  Should have .supportsWirelssCharging and .hasHeadphoneJack, etc functions.
    public var supportsWirelessCharging: Bool
    public var biometrics: Biometrics
    public var hasForce3dTouchSupport: Bool
    /// TODO: Instead, change this to sensors[Sensor] list that indicates the type of camera in megapixels and focal length or lidar and other sensors like barrometers and crash detection and forceTouch and 3dTouch, etc. also actionButton for iPhone 15 pro and Apple Watch Ultra.  And ringer switch as option for older iPhones and some iPads.  Volume controls would be another sensor.  Perhaps we have a separate array for physical buttons?.  Cameras could be queried using special filter.  Have Sensors, Cameras, Pencils, etc and allow searching for various things but this can all be stored in a neat little array that can be added by a simple sensors property.  Could have static presets for model/year groups that can be added to for individual overrides.
    public var cameras: Int
    /// Returns whether or not the device has a LiDAR sensor.
    public var hasLidarSensor: Bool
    /// Returns whether or not the device has a USB-C power supply.
    public var hasUSBCConnectivity: Bool
    
    // Display Info
    public var screen: Screen?
    
    // Idiom-specific properties
    public var idiomProperties = [String:Any]()
    
    public init(
        idiom: Idiom,
        name: String,
        identifiers: [String],
        supportId: String? = nil,
        image: String? = nil,
        isPro: Bool = false,
        cpu: CPU,
        hasBattery: Bool = true, // so that we can try to return a battery for monitoring if we don't know if the battery exists or not.
        cellular: Cellular = .none,
        supportsWirelessCharging: Bool = false,
        biometrics: Biometrics = .none,
        hasForce3dTouchSupport: Bool = false,
        cameras: Int = 0,
        hasLidarSensor: Bool = false,
        hasUSBCConnectivity: Bool = false,
        screen: Screen? = nil,
        idiomProperties: [String:Any] = [:]
    ) {
        self.idiom = idiom
        self.name = name
        self.identifiers = identifiers
        self.supportId = supportId
        self.image = image
        self.isPro = isPro
        self.cpu = cpu
        self.hasBattery = hasBattery
        self.cellular = cellular
        self.supportsWirelessCharging = supportsWirelessCharging
        self.biometrics = biometrics
        self.hasForce3dTouchSupport = hasForce3dTouchSupport
        self.cameras = cameras
        self.hasLidarSensor = hasLidarSensor
        self.hasUSBCConnectivity = hasUSBCConnectivity
        self.screen = screen
        self.idiomProperties = idiomProperties
    }
    
    /// Maps an identifier to a Device. If the identifier can not be mapped to an existing device, a placeholder device for the identifier of the correct idiom is created if possible, otherwise, a placeholder device `.unknown` is returned.
    /// - parameter identifier: The device identifier, e.g. "iPhone7,1". Current device identifier can be obtained from `Device.current.identifier`.
    /// - returns: An initialized `Device`.
    init(identifier: String) {
        for device in Device.all {
            if device.device.identifiers.contains(identifier) {
                self = device.device
                return
            }
        }
        // try to parse identifier to figure out what kind of device this is and create an unknown device profile with assumed default features
        for idiom in Idiom.allCases {
            if identifier.hasPrefix(idiom.identifier) {
                let deviceType = idiom.type
                self = deviceType.init(identifier: identifier).device
                return
            }
        }
        // assume arm64 is a mac
        if identifier == "arm64" {
            self = Mac.init(identifier: identifier).device
            return
        }
        // possibly a preview?
        self.init(
            idiom: .unspecified,
            name: "Unknown Device",
            identifiers: [identifier],
            supportId: "UNKNOWN",
            image: nil,
            cpu: .unknown)
    }

    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return .symbolUnknownDevice
    }

    /// A list of all known devices (devices with identifiers and descriptions).
    public static var all: [Device] = {
        var allKnownDevices = [Device]()
        
        // Macs
        allKnownDevices += Mac.allDevices
        // iPod Touches
        allKnownDevices += iPod.allDevices
        // iPhones
        allKnownDevices += iPhone.allDevices
        //  Apple TVs
        allKnownDevices += AppleTV.allDevices
        // iPads
        allKnownDevices += iPad.allDevices
        // HomePods
        allKnownDevices += HomePod.allDevices
        //  Watches
        allKnownDevices += AppleWatch.allDevices
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
    public var description: String {
        return self.name
    }
    
    /// A safe version of `description`.
    /// Example:
    /// Device.iPhoneXR.description:     iPhone Xʀ
    /// Device.iPhoneXR.safeDescription: iPhone XR
    public var safeDescription: String {
        return description
            .replacingOccurrences(of: "ʀ", with: "R")
            .replacingOccurrences(of: "", with: "Apple")
    }
}

// MARK: - Device Idiom Types
public struct Mac: IdiomType {
    public enum Form: String {
        case macProGen1 = "macpro.gen1"
        case macProGen2 = "macpro.gen2"
        case macProGen3 = "macpro.gen3"
        case macBook = "macbook"
        case macBookGen1 = "macbook.gen1"
        case macBookGen2 = "macbook.gen2"
        case macMini = "macmini"
        case macStudio = "macstudio"
    }
    
    public var device: Device
    static let form = "form"
    public var form: Form {
        device.idiomProperties[Self.form] as! Form
    }

    public init(
        name: String,
        identifiers: [String],
        supportId: String,
        form: Form,
        image: String?,
        cpu: CPU,
        hasBattery: Bool,
        hasUSBCConnectivity: Bool = true
    )
    {
        device = Device(idiom: .mac, name: name, identifiers: identifiers, image: image, cpu: cpu, hasBattery: hasBattery, hasUSBCConnectivity: hasUSBCConnectivity, idiomProperties: [Self.form: form])
    }
    
    init(identifier: String) {
        self.init(
            name: "Unknown Mac",
            identifiers: [identifier],
            supportId: "UNKNOWN",
            form: .macBook,
            image: nil,
            cpu: .unknown,
            hasBattery: true,
            hasUSBCConnectivity: true
        )
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return self.form.rawValue
    }

    static var all = [
        // TODO: We need a lot more of the macs here!  Please help fill these out via a pull request.
        Mac(
            name: "MacBook Pro (14-inch, 2023)",
            identifiers: ["Mac14,9"],
            supportId: "SP889",
            form: .macBookGen2,
            image: "https://cdsassets.apple.com/live/SZLF0YNV/images/sp/111340_macbook-pro-2023-14in.png",
            cpu: .m2pro,
            hasBattery: true,
            hasUSBCConnectivity: true),
        Mac(
            name: "MacBook Pro 16-Inch, M2 Pro, 2023",
            identifiers: ["Mac14,10"],
            supportId: "SP890",
            form: .macBookGen2,
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP890/macbook-pro-2023-16in_2x.png",
            cpu: .m2pro,
            hasBattery: true,
            hasUSBCConnectivity: true),
        Mac(
            name: "Mac mini (2023)",
            identifiers: ["Mac14,3"],
            supportId: "SP891",
            form: .macMini,
            image: "https://cdsassets.apple.com/live/SZLF0YNV/images/sp/111837_mac-mini-2023-m2-pro.png",
            cpu: .m2,
            hasBattery: false,
            hasUSBCConnectivity: true),
    ]
}
    
public struct iPod: IdiomType {
    public var device: Device
    public init(
        name: String,
        identifiers: [String],
        supportId: String,
        image: String?,
        cpu: CPU
    ) {
        device = Device(
            idiom: .pod,
            name: name,
            identifiers: identifiers,
            cpu: cpu,
            hasBattery: true,
            screen: .i4
        )
    }
    
    init(identifier: String) {
        self.init(
            name: "Unknown iPod",
            identifiers: [identifier],
            supportId: "UNKNOWN",
            image: nil,
            cpu: .unknown)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return "ipodtouch"
    }
    
    static var all = [
        iPod(name: "iPod touch (5th generation)",
             identifiers: ["iPod5,1"],
             supportId: "SP657",
             image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP657/sp657_ipod-touch_size.jpg",
             cpu: .a5),
        iPod(name: "iPod touch (6th generation)",
             identifiers: ["iPod7,1"],
             supportId: "SP720",
             image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP720/SP720-ipod-touch-specs-color-sg-2015.jpg",
             cpu: .a8),
        iPod(name: "iPod touch (7th generation)",
             identifiers: ["iPod9,1"],
             supportId: "SP796",
             image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP796/ipod-touch-7th-gen_2x.png",
             cpu: .a10),
    ]
}

public struct iPhone: IdiomType {
    public var device: Device
    // TODO: Should we have isMiniFormFactor?
    static let isPlusFormFactor = "isPlusFormFactor"
    public var isPlusFormFactor: Bool {
        device.idiomProperties[Self.isPlusFormFactor].boolValue
    }
    static let hasDynamicIsland = "hasDynamicIsland"
    /// Returns whether or not the device has the Dynamic Island.
    public var hasDynamicIsland: Bool {
        device.idiomProperties[Self.hasDynamicIsland].boolValue
    }
    
    public init(
        name: String,
        identifiers: [String],
        supportId: String,
        image: String?,
        isPro: Bool = false,
        cpu: CPU,
        cellular: Cellular,
        screen: Screen?,
        supportsWirelessCharging: Bool = false,
        biometrics: Biometrics = .none,
        hasForce3dTouchSupport: Bool = false,
        cameras: Int,
        isPlusFormFactor: Bool = false,
        hasLidarSensor: Bool = false,
        hasDynamicIsland: Bool = false,
        hasUSBCConnectivity: Bool = false
    ) {
        device = Device(
            idiom: .phone,
            name: name,
            identifiers: identifiers,
            supportId: supportId,
            image: image,
            isPro: isPro,
            cpu: cpu,
            hasBattery: true,
            cellular: cellular,
            supportsWirelessCharging: supportsWirelessCharging,
            biometrics: biometrics,
            hasForce3dTouchSupport: hasForce3dTouchSupport,
            cameras: cameras,
            hasLidarSensor: hasLidarSensor,
            hasUSBCConnectivity: hasUSBCConnectivity,
            screen: screen,
            idiomProperties: [
                Self.isPlusFormFactor: isPlusFormFactor,
                Self.hasDynamicIsland: hasDynamicIsland,
            ]
        )
    }
    
    init(identifier: String) {
        self.init(
            name: "Unknown iPhone",
            identifiers:[identifier],
            supportId: "UNKNOWN",
            image: nil,
            cpu: .unknown,
            cellular: .fiveG, // assume new devices are at least 5G
            screen: .i61, // default screen size
            supportsWirelessCharging: true, // assume all phones going forward have MagSafe
            cameras: 3, // front + back 2
            hasUSBCConnectivity: true // assume all phones going forward will have USBCConnectivity
        )
    }

    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        if hasDynamicIsland {
            return "iphone.gen3"
        } else if biometrics == .faceID {
            return "iphone.gen2"
        } else {
            return "iphone.gen1"
        }
    }
    
    static var all = [
        /*
         iPhone(
         name: "iPhone FULL FIELD EXAMPLE",
         identifiers: ["iPhoneX,X"],
         supportId: "SPXXXX",
         image: "https://support.apple.com/XXXXXXXXX.png",
         isPro: false,
         cpu: .unknown,
         cellular: .fiveG,
         screen: .wUnknown,
         supportsWirelessCharging: true,
         biometrics: .faceID,
         hasForce3dTouchSupport: false,
         cameras: 4, // back cameras + front camera
         isPlusFormFactor: false,
         hasLidarSensor: true, // will say on support page
         hasUSBCConnectivity: true), // 15x models should all support USBC
         */
        iPhone(
            name: "iPhone 4",
            identifiers: ["iPhone3,1", "iPhone3,2", "iPhone3,3"],
            supportId: "SP587",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP643/sp643_iphone4s_color_black.jpg",
            cpu: .a4,
            cellular: .threeG,
            screen: .i35,
            cameras: 2
        ),
        iPhone(
            name: "iPhone 4s",
            identifiers: ["iPhone4,1"],
            supportId: "SP643",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP643/sp643_iphone4s_color_black.jpg",
            isPro: false,
            cpu: .a5,
            cellular: .threeG,
            screen: .i35,
            cameras: 2 // dual cameras 8 mp
        ),
        iPhone(
            name: "iPhone 5",
            identifiers: ["iPhone5,1", "iPhone5,2"],
            supportId: "SP655",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP655/sp655_iphone5_color.jpg",
            isPro: false,
            cpu: .a6,
            cellular: .lte,
            screen: .i4,
            cameras: 2 // dual cameras rear 8mp, front 1.2mp
        ),
        iPhone(
            name: "iPhone 5c",
            identifiers: ["iPhone5,3", "iPhone5,4"],
            supportId: "SP684",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP684/SP684-color_yellow.jpg",
            isPro: false,
            cpu: .a6,
            cellular: .lte,
            screen: .i4,
            cameras: 2 // dual cameras rear 8mp, front 1.2mp
        ),
        iPhone(
            name: "iPhone 5s",
            identifiers: ["iPhone6,1", "iPhone6,2"],
            supportId: "SP685",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP685/SP685-color_black.jpg",
            isPro: false,
            cpu: .a7,
            cellular: .lte,
            screen: .i4,
            biometrics: .touchID,
            cameras: 2 // dual cameras rear 8mp, front 1.2mp
        ),
        
        // 4G Below
        
        iPhone(
            name: "iPhone 6",
            identifiers: ["iPhone7,2"],
            supportId: "SP705",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP705/SP705-iphone_6-mul.png",
            isPro: false,
            cpu: .a8,
            cellular: .lte,
            screen: .i47,
            biometrics: .touchID,
            cameras: 2 // dual cameras rear 8mp, front 1.2mp
        ),
        iPhone(
            name: "iPhone 6 Plus",
            identifiers: ["iPhone7,1"],
            supportId: "SP706",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP706/SP706-iphone_6_plus-mul.png",
            isPro: false,
            cpu: .a8,
            cellular: .lte,
            screen: .i55,
            biometrics: .touchID,
            cameras: 2, // dual cameras rear 8mp, front 1.2mp
            isPlusFormFactor: true
        ),
        iPhone(
            name: "iPhone 6s",
            identifiers: ["iPhone8,1"],
            supportId: "SP726",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP726/SP726-iphone6s-gray-select-2015.png",
            isPro: false,
            cpu: .a9,
            cellular: .lte,
            screen: .i47,
            biometrics: .touchID,
            cameras: 2 // dual cameras rear 12mp, front 5mp
        ),
        iPhone(
            name: "iPhone 6s Plus",
            identifiers: ["iPhone8,2"],
            supportId: "SP727",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP727/SP727-iphone6s-plus-gray-select-2015.png",
            isPro: false,
            cpu: .a9,
            cellular: .lte,
            screen: .i55,
            biometrics: .touchID,
            cameras: 2, // dual cameras rear 8mp, front 1.2mp
            isPlusFormFactor: true
        ),
        iPhone(
            name: "iPhone SE",
            identifiers: ["iPhone8,4"],
            supportId: "SP738",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP738/SP738.png",
            isPro: false,
            cpu: .a9,
            cellular: .lte,
            screen: .i4,
            biometrics: .touchID,
            cameras: 2 // dual cameras rear 12mp, front 1.2mp
        ),
        iPhone(
            name: "iPhone 7",
            identifiers: ["iPhone9,1", "iPhone9,3"],
            supportId: "SP743",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP743/iphone7-black.png",
            isPro: false,
            cpu: .a10,
            cellular: .lte,
            screen: .i47,
            biometrics: .touchID,
            cameras: 3 // 3 cameras, dual rear cameras 12mp, front 7mp
        ),
        iPhone(
            name: "iPhone 7 Plus",
            identifiers: ["iPhone9,2", "iPhone9,4"],
            supportId: "SP744",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP744/iphone7-plus-black.png",
            isPro: false,
            cpu: .a10,
            cellular: .lte,
            screen: .i55,
            biometrics: .touchID,
            cameras: 3, // 3 cameras, dual rear cameras 12mp, front 7mp
            isPlusFormFactor: true
        ),
        iPhone(
            name: "iPhone 8",
            identifiers: ["iPhone10,1", "iPhone10,4"],
            supportId: "SP767",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP767/iphone8.png",
            isPro: false,
            cpu: .a11,
            cellular: .lte,
            screen: .i47,
            supportsWirelessCharging: true,
            biometrics: .touchID,
            cameras: 2 // dual cameras rear 12mp, front 7mp
        ),
        iPhone(
            name: "iPhone 8 Plus",
            identifiers: ["iPhone10,2", "iPhone10,5"],
            supportId: "SP768",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP768/iphone8plus.png",
            isPro: false,
            cpu: .a11,
            cellular: .lte,
            screen: .i55,
            supportsWirelessCharging: true,
            biometrics: .touchID,
            cameras: 2, // dual cameras rear 12mp, front 7mp
            isPlusFormFactor: true
        ),
        iPhone(
            name: "iPhone X",
            identifiers: ["iPhone10,3", "iPhone10,6"],
            supportId: "SP770",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP770/iphonex.png",
            isPro: false,
            cpu: .a11,
            cellular: .lte,
            screen: .i58,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 3 // three cameras, two rear 12mp, front 7mp
        ),
        iPhone(
            name: "iPhone Xs",
            identifiers: ["iPhone11,2"],
            supportId: "SP779",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP779/SP779-iphone-xs.jpg",
            isPro: false,
            cpu: .a12,
            cellular: .lte,
            screen: .i58,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 3 // three cameras, two rear 12mp, front 7mp
        ),
        iPhone(
            name: "iPhone Xs Max",
            identifiers: ["iPhone11,4", "iPhone11,6"],
            supportId: "SP780",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP780/SP780-iPhone-Xs-Max.jpg",
            isPro: false,
            cpu: .a12,
            cellular: .lte,
            screen: .i65,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 3, // three cameras, two rear 12mp, front 7mp
            isPlusFormFactor: true
        ),
        iPhone(
            name: "iPhone Xʀ", // TODO: Do we need a "clean" version?  Couldn't we have a function that replaces the ʀ with R?
            identifiers: ["iPhone11,8"],
            supportId: "SP781",
            image:                    "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP781/SP781-iPhone-xr.jpg",
            isPro: false,
            cpu: .a12,
            cellular: .lte,
            screen: .i61,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 3 // three cameras, two rear 12mp, front 7mp
        ),
        iPhone(
            name: "iPhone11Pro",
            identifiers: ["iPhone12,3"],
            supportId: "SP805",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP805/sp805-iphone11pro_2x.png",
            isPro: true,
            cpu: .a12,
            cellular: .lte,
            screen: .i61,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 4 // four cameras, three rear 12mp, front 12mp
        ),
        iPhone(
            name: "iPhone11ProMax",
            identifiers: ["iPhone 11 Pro Max"],
            supportId: "SP806",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP806/sp806-iphone11pro-max_2x.png",
            isPro: true,
            cpu: .a13,
            cellular: .lte,
            screen: .i65,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 4, // four cameras, three rear 12mp, front 12mp,
            isPlusFormFactor: true
        ),
        iPhone(
            name: "iPhone SE2",
            identifiers: ["iPhone SE (2nd generation)", "iPhone SE (2nd generation)"],
            supportId: "SP820",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP820/iphone-se-2nd-gen_2x.png",
            isPro: false,
            cpu: .a13,
            cellular: .lte,
            screen: .i47,
            supportsWirelessCharging: true,
            biometrics: .touchID,
            cameras: 2 // dual camera, rear 7mp, front 12mp,
        ),
        
        iPhone(
            name: "iPhone 12 mini",
            identifiers: ["iPhone13,1"],
            supportId: "SP830",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP830/sp830-iphone12-ios14_2x.png",
            isPro: false,
            cpu: .a14,
            cellular: .fiveG,
            screen: .i61,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 3 // three cameras, two rear 12mp, front 12mp,
        ),
        iPhone(
            name: "iPhone 12",
            identifiers: ["iPhone13,2"],
            supportId: "SP830",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP830/sp830-iphone12-ios14_2x.png",
            isPro: false,
            cpu: .a14,
            cellular: .fiveG,
            screen: .i61,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 3, // three cameras, two rear 12mp, front 12mp,
            isPlusFormFactor: false
        ),
        iPhone(
            name: "iPhone 12 Pro",
            identifiers: ["iPhone13,3"],
            supportId: "SP831",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP831/iphone12pro-ios14_2x.png",
            isPro: true,
            cpu: .a14,
            cellular: .fiveG,
            screen: .i61p,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 4, // four cameras, three rear 12mp, front 12mp,
            isPlusFormFactor: false
        ),
        iPhone(
            name: "iPhone 12 Pro Max",
            identifiers: ["iPhone13,4"],
            supportId: "SP832",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP832/iphone12promax-ios14_2x.png",
            isPro: true,
            cpu: .a14,
            cellular: .fiveG,
            screen: .i67,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 4, // four cameras, three rear 12mp, front 12mp,
            isPlusFormFactor: true
        ),
        
        // 5G below
        
        iPhone(
            name: "iPhone 13",
            identifiers: ["iPhone14,5"],
            supportId: "SP851",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/1000/IM1092/en_US/iphone-13-240.png",
            cpu: .a15,
            cellular: .fiveG,
            screen: .i61p,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 3, // three cameras, two rear 12mp, front 12mp,
            isPlusFormFactor: false
        ),
        iPhone(
            name: "iPhone 13 mini",
            identifiers: ["iPhone14,4"],
            supportId: "SP847",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/1000/IM1091/en_US/iphone-13mini-240.png",
            cpu: .a15,
            cellular: .fiveG,
            screen: .i54,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 3, // three cameras, two rear 12mp, front 12mp,
            isPlusFormFactor: false
        ),
        iPhone(
            name: "iPhone 13 Pro",
            identifiers: ["iPhone14,2"],
            supportId: "SP852",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/1000/IM1093/en_US/iphone-13pro-240.png",
            isPro: true,
            cpu: .a15,
            cellular: .fiveG,
            screen: .i61p,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 4, // four cameras, three rear 12mp, front 12mp,
            isPlusFormFactor: false
        ),
        iPhone(
            name: "iPhone SE (3rd generation)",
            identifiers: ["iPhone14,6"],
            supportId: "SP867",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/1000/IM1136/en_US/iphone-se-3rd-gen-colors-240.png",
            cpu: .a15,
            cellular: .fiveG,
            screen: .i47,
            supportsWirelessCharging: true,
            biometrics: .touchID,
            cameras: 2, // two cameras, rear 12mp, front 7mp,
            isPlusFormFactor: false
        ),
        iPhone(
            name: "iPhone 14",
            identifiers: ["iPhone14,7"],
            supportId: "SP873",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/1000/IM1136/en_US/iphone-se-3rd-gen-colors-240.png",
            cpu: .a15,
            cellular: .fiveG,
            screen: .i61p,
            supportsWirelessCharging: true,
            biometrics: .touchID,
            cameras: 3, // three cameras, two rear 12mp, front 12mp,
            isPlusFormFactor: false
        ),
        iPhone(
            name: "iPhone 14 Plus",
            identifiers: ["iPhone14,8"],
            supportId: "SP874",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP873/iphone-14_1_2x.png",
            cpu: .a15,
            cellular: .fiveG,
            screen: .i67,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 3, // three cameras, two rear 12mp, front 12mp
            isPlusFormFactor: true
        ),
        iPhone(
            name: "iPhone 14 Pro",
            identifiers: ["iPhone15,2"],
            supportId: "SP875",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP875/sp875-sp876-iphone14-pro-promax_2x.png",
            isPro: true,
            cpu: .a16,
            cellular: .fiveG,
            screen: .i61x1179,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 4, // three cameras, three rear 12mp, front 12mp,
            isPlusFormFactor: false,
            hasDynamicIsland: true
        ),
        iPhone(
            name: "iPhone 14 Pro Max",
            identifiers: ["iPhone15,3"],
            supportId: "SP876",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP875/sp875-sp876-iphone14-pro-promax_2x.png",
            isPro: true,
            cpu: .a16,
            cellular: .fiveG,
            screen: .i67x1290,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            cameras: 4, // three cameras, three rear 12mp, front 12mp,
            isPlusFormFactor: false,
            hasDynamicIsland: true
        ),
        
        iPhone(
            name: "iPhone 15",
            identifiers: ["iPhone15,4"],
            supportId: "SP901",
            image: "https://everymac.com/images/ipod_pictures/iphone-15-colors.jpg",
            isPro: false,
            cpu: .a16,
            cellular: .fiveG,
            screen: .i61x1179,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            hasForce3dTouchSupport: false,
            cameras: 3, // 2 back cameras + 1 front camera
            isPlusFormFactor: false,
            hasLidarSensor: false, // will say on support page
            hasDynamicIsland: true,
            hasUSBCConnectivity: true), // 15x models should all support USBC
        iPhone(
            name: "iPhone 15 Plus",
            identifiers: ["iPhone15,5"],
            supportId: "SP902",
            image: "https://everymac.com/images/ipod_pictures/iphone-15-plus-colors.jpg",
            isPro: false,
            cpu: .a16,
            cellular: .fiveG,
            screen: .i67x1290,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            hasForce3dTouchSupport: false,
            cameras: 3, // 2 back cameras + front camera
            isPlusFormFactor: false,
            hasLidarSensor: true, // will say on support page
            hasDynamicIsland: true,
            hasUSBCConnectivity: true), // 15x models should all support USBC
        iPhone(
            name: "iPhone 15 Pro",
            identifiers: ["iPhone16,1"],
            supportId: "SP903",
            image: "https://everymac.com/images/ipod_pictures/iphone-15-pro-colors.jpg",
            isPro: true,
            cpu: .a17pro,
            cellular: .fiveG,
            screen: .i61x1179,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            hasForce3dTouchSupport: false,
            cameras: 4, // 3 back cameras + 1 front camera
            isPlusFormFactor: false,
            hasLidarSensor: true, // will say on support page
            hasDynamicIsland: true,
            hasUSBCConnectivity: true), // 15x models should all support USBC
        iPhone(
            name: "iPhone 15 Pro Max",
            identifiers: ["iPhone16,2"],
            supportId: "SP904",
            image: "https://everymac.com/images/ipod_pictures/iphone-15-pro-max-colors.jpg",
            isPro: true,
            cpu: .a17pro,
            cellular: .fiveG,
            screen: .i67x1290,
            supportsWirelessCharging: true,
            biometrics: .faceID,
            hasForce3dTouchSupport: false,
            cameras: 4, // 3 back cameras + 1 front camera
            isPlusFormFactor: false,
            hasLidarSensor: true, // will say on support page
            hasDynamicIsland: true,
            hasUSBCConnectivity: true), // 15x models should all support USBC
    ]
}

public struct iPad: IdiomType {
    public var device: Device
    // TODO: Do we need to include cellular capability?
    static let supportedPencils = "supportedPencils"
    public var supportedPencils: [ApplePencil] {
        device.idiomProperties[Self.supportedPencils] as! [iPad.ApplePencil]
    }
    static let isMini = "isMini"
    public var isMini: Bool // equivalent to isPadMiniFormFactor
    {
        device.idiomProperties[Self.isMini].boolValue
    }
    
    public enum ApplePencil {
        case firstGeneration
        case secondGeneration
        case usbC
    }
    
    // TODO: Add in cellular technologies?
    public init(
        name: String,
        identifiers: [String],
        supportId: String,
        image: String?,
        cpu: CPU,
        screen: Screen,
        supportedPencils: [ApplePencil] = [],
        isMini: Bool = false
    )
    {
        device = Device(
            idiom: .pad,
            name: name,
            identifiers: identifiers,
            cpu: cpu,
            screen: screen,
            idiomProperties: [
                Self.supportedPencils: supportedPencils,
                Self.isMini: isMini,
            ]
        )
    }
    
    init(identifier: String) {
        self.init(
            name: "Unknown iPad",
            identifiers: [identifier],
            supportId: "UNKNOWN",
            image: nil,
            cpu: .unknown,
            screen: .i97)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        if biometrics == .faceID {
            return "ipad.gen2"
        } else {
            return "ipad.gen1"
        }
    }

    /// Returns whether or not the device is compatible with Apple Pencil
    public var isApplePencilCapable: Bool {
        supportedPencils.count > 0
    }

    static var all = [
        /*
        iPad( // TODO: Remove once below is complete
            name: "iPad FULL FIELD EXAMPLE",
            identifiers: ["iPadX,X"],
            supportId: "SPXXXX",
            image: "https://support.apple.com/XXXXXXXXX.png",
            cpu: .unknown,
            screen: .wUnknown,
            supportedPencils: [.firstGeneration,.secondGeneration,.usbC],
            isMini: false),
         */
        
        iPad(
            name: "iPad (Original/1st Generation)",
            identifiers: ["iPad1,1"],
            supportId: "SP580",
            image: "https://everymac.com/images/ipod_pictures/apple-ipad.jpg",
            cpu: .a4,
            screen: .i97),

        iPad(
            name: "iPad (2nd Generation)",
            identifiers: ["iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4"],
            supportId: "SP622",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP622/SP622_01-ipad2-mul.png",
            cpu: .a5,
            screen: .i97),
        
        iPad(
            name: "iPad (3rd Generation)",
            identifiers: ["iPad3,1", "iPad3,2", "iPad3,3"],
            supportId: "SP647",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP662/sp662_ipad-4th-gen_color.jpg",
            cpu: .a5x,
            screen: .i97,
            supportedPencils: [],
            isMini: false),
        
        iPad(
            name: "iPad (4th generation)",
            identifiers: ["iPad3,4", "iPad3,5", "iPad3,6"],
            supportId: "SP662",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP662/sp662_ipad-4th-gen_color.jpg",
            cpu: .a6x,
            screen: .i97,
            supportedPencils: [],
            isMini: false),
        
        iPad(
            name: "iPad Air",
            identifiers: ["iPad4,1", "iPad4,2", "iPad4,3"],
            supportId: "SP692",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP692/SP692-specs_color-mul.png",
            cpu: .a7,
            screen: .i97,
            supportedPencils: [],
            isMini: false),
        
        iPad(
            name: "iPad Air 2",
            identifiers: ["iPad5,3", "iPad5,4"],
            supportId: "SP708",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP708/SP708-space_gray.jpeg",
            cpu: .a8x,
            screen: .i97),
        
        iPad(
            name: "iPad (5th generation)",
            identifiers: ["iPad6,11", "iPad6,12"],
            supportId: "SP751",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP751/ipad_5th_generation.png",
            cpu: .a9,
            screen: .i97),
        
        iPad(
            name: "iPad (6th generation)",
            identifiers: ["iPad7,5", "iPad7,6"],
            supportId: "SP774",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP774/sp774-ipad-6-gen_2x.png",
            cpu: .a10,
            screen: .i97,
            supportedPencils: [.firstGeneration]),
        
        iPad(
            name: "iPad Air (3rd generation)",
            identifiers: ["iPad11,3", "iPad11,4"],
            supportId: "SP787",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP787/ipad-air-2019.jpg",
            cpu: .a12,
            screen: .i97,
            supportedPencils: [.firstGeneration],
            isMini: false),
        
        iPad(
            name: "iPad (7th generation)",
            identifiers: ["iPad7,11", "iPad7,12"],
            supportId: "SP807",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP807/sp807-ipad-7th-gen_2x.png",
            cpu: .a10,
            screen: .i102,
            supportedPencils: [.firstGeneration],
            isMini: false),
        
        iPad(
            name: "iPad (8th generation)",
            identifiers: ["iPad11,6", "iPad11,7"],
            supportId: "SP822",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP822/sp822-ipad-8gen_2x.png",
            cpu: .a12,
            screen: .i102,
            supportedPencils: [.firstGeneration],
            isMini: false),
        
        iPad(
            name: "iPad (9th generation)",
            identifiers: ["iPad12,1", "iPad12,2"],
            supportId: "SP849",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/1000/IM1096/en_US/ipad-9gen-240.png",
            cpu: .a13,
            screen: .i102,
            supportedPencils: [.firstGeneration],
            isMini: false),
        
        iPad(
            name: "iPad (10th generation)",
            identifiers: ["iPad13,18", "iPad13,19"],
            supportId: "SP884",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP884/sp884-ipad-10gen-960_2x.png",
            cpu: .a14,
            screen: .i109,
            supportedPencils: [.usbC, .firstGeneration],
            isMini: false),
        
        iPad(
            name: "iPad Air (4th generation)",
            identifiers: ["iPad13,1", "iPad13,2"],
            supportId: "SP828",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP828/sp828ipad-air-ipados14-960_2x.png",
            cpu: .a14,
            screen: .i109,
            supportedPencils: [.usbC, .secondGeneration],
            isMini: false),
        
        iPad(
            name: "iPad Air (5th generation)",
            identifiers: ["iPad13,16", "iPad13,17"],
            supportId: "SP866",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP866/sp866-ipad-air-5gen_2x.png",
            cpu: .m1,
            screen: .i109,
            supportedPencils: [.usbC, .secondGeneration],
            isMini: false),
        
        iPad(
            name: "iPad Mini",
            identifiers: ["iPad2,5", "iPad2,6", "iPad2,7"],
            supportId: "SP661",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP661/sp661_ipad_mini_color.jpg",
            cpu: .a5,
            screen: .i79,
            supportedPencils: [],
            isMini: true),
        
        iPad(
            name: "iPad Mini 2",
            identifiers: ["iPad4,4", "iPad4,5", "iPad4,6"],
            supportId: "SP693",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP693/SP693-specs_color-mul.png",
            cpu: .a7,
            screen: .i79,
            isMini: true),
        
        iPad(
            name: "iPad Mini 3",
            identifiers: ["iPad4,7", "iPad4,8", "iPad4,9"],
            supportId: "SP709",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP709/SP709-space_gray.jpeg",
            cpu: .a7,
            screen: .i79,
            isMini: true),
        
        iPad(
            name: "iPad Mini 4",
            identifiers: ["iPad5,1", "iPad5,2"],
            supportId: "SP725",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP725/SP725ipad-mini-4.png",
            cpu: .a8,
            screen: .i79,
            isMini: true),
        
        iPad(
            name: "iPad Mini (5th generation)",
            identifiers: ["iPad11,1", "iPad11,2"],
            supportId: "SP788",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP788/ipad-mini-2019.jpg",
            cpu: .a12,
            screen: .i79,
            supportedPencils: [.firstGeneration],
            isMini: true),
        
        iPad(
            name: "iPad Mini (6th generation)",
            identifiers: ["iPad14,1", "iPad14,2"],
            supportId: "SP850",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/1000/IM1097/en_US/ipad-mini-6gen-240.png",
            cpu: .a15,
            screen: .i83,
            supportedPencils: [.usbC, .secondGeneration],
            isMini: true),
        
        // https://www.apple.com/ipad/compare/?modelList=ipad-pro-9-7,ipad-air-5th-gen,ipad-10th-gen
        
        iPad(
            name: "iPad Pro",
            identifiers: ["iPad6,3", "iPad6,4"],
            supportId: "SP739",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP739/SP739.png",
            cpu: .a9x,
            screen: .i97,
            supportedPencils: [.firstGeneration]),
        
        iPad(
            name: "iPad Pro 9.7-inch",
            identifiers: ["iPad6,3", "iPad6,4"],
            supportId: "SP739",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP739/SP739.png",
            cpu: .a9x,
            screen: .i97,
            supportedPencils: [.firstGeneration]),
        
        iPad(
            name: "iPad Pro 12.9-inch (1st generation)",
            identifiers: ["iPad6,7", "iPad6,8"],
            supportId: "SP723",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP723/SP723-iPad_Pro_2x.png",
            cpu: .a9x,
            screen: .i129,
            supportedPencils: [.firstGeneration]),
        
        iPad(
            name: "iPad Pro 12-inch (2nd generation)",
            identifiers: ["iPad7,1", "iPad7,2"], // 1 is wifi, 2 is cellular model
            supportId: "SP761",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP761/ipad-pro-12in-hero-201706.png",
            cpu: .a10x,
            screen: .i129,
            supportedPencils: [.firstGeneration]),
        
        iPad(
            name: "iPad Pro 10.5-inch",
            identifiers: ["iPad7,3", "iPad7,4"],
            supportId: "SP762",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP761/ipad-pro-10in-hero-201706.png",
            cpu: .a10x,
            screen: .i105,
            supportedPencils: [.firstGeneration]),
        
        iPad(
            name: "iPad Pro 11-inch",
            identifiers: ["iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4"],
            supportId: "SP784",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP761/ipad-pro-10in-hero-201706.png",
            cpu: .a10x,
            screen: .i105,
            supportedPencils: [.firstGeneration, .secondGeneration]),
        
        iPad(
            name: "iPad Pro 12.9-inch (3rd generation)",
            identifiers: ["iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8"], // wifi, wifi 1tb, cellular, cellular 1tb
            supportId: "SP784",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP785/ipad-pro-12-2018_2x.png",
            cpu: .a12x,
            screen: .i129,
            supportedPencils: [.secondGeneration, .usbC]),
        
        iPad(
            name: "iPad Pro 11-inch (2nd generation)",
            identifiers: ["iPad8,9", "iPad8,10"],
            supportId: "SP814",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP814/ipad-pro-11-2020.jpeg",
            cpu: .a12z,
            screen: .i129,
            supportedPencils: [.secondGeneration, .usbC]),
        
        iPad(
            name: "iPad Pro 12.9-inch (4th generation)",
            identifiers: ["iPad8,11", "iPad8,12"],
            supportId: "SP815",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP815/ipad-pro-12-2020.jpeg",
            cpu: .a12z,
            screen: .i129,
            supportedPencils: [.secondGeneration, .usbC]),
        
        iPad(
            name: "iPad Pro 11-inch (3rd generation)",
            identifiers: ["iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7"],
            supportId: "SP843",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP843/ipad-pro-11_2x.png",
            cpu: .m1,
            screen: .i11,
            supportedPencils: [.secondGeneration, .usbC]),
        
        iPad(
            name: "iPad Pro 12.9-inch (5th generation)",
            identifiers: ["iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11"],
            supportId: "SP844",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP844/ipad-pro-12-9_2x.png",
            cpu: .m1,
            screen: .i129,
            supportedPencils: [.secondGeneration, .usbC]),
        
        iPad(
            name: "iPad Pro 11-inch (4th generation)",
            identifiers: ["iPad14,3", "iPad14,4"],
            supportId: "SP882",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP882/ipad-pro-4gen-mainimage_2x.png",
            cpu: .m2,
            screen: .i11,
            supportedPencils: [.secondGeneration, .usbC]),
        
        iPad(
            name: "iPad Pro 12.9-inch (6th generation)",
            identifiers: ["iPad14,5", "iPad14,6"],
            supportId: "SP883",
            image: "https://cdsassets.apple.com/live/SZLF0YNV/images/sp/111841_ipad-pro-4gen-mainimage.png",
            cpu: .m2,
            screen: .i129,
            supportedPencils: [.secondGeneration, .usbC]),
    ]
}

public struct AppleTV: IdiomType {
    public var device: Device
    public init(
        name: String,
        identifiers: [String],
        supportId: String,
        image: String?,
        cpu: CPU)
    {
        device = Device(idiom: .tv, name: name, identifiers: identifiers, cpu: cpu, hasBattery: false, screen: .tv)
    }

    init(identifier: String) {
        self.init(
            name: "Unknown  TV",
            identifiers: [identifier],
            supportId: "UNKNOWN",
            image: nil,
            cpu: .unknown)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return "appletv"
    }

    static var all = [ // https://support.apple.com/en-us/101605
        AppleTV(
            name: "Apple TV HD (4th Generation, Siri)",
            identifiers: ["AppleTV5,3"],
            supportId: "SP724",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP724/apple-tv-hd_2x.png",
            cpu: .a8),
        AppleTV(
            name: "Apple TV 4K (2017, Black Siri Remote)",
            identifiers: ["AppleTV6,2"],
            supportId: "SP769",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP769/appletv4k.png",
            cpu: .a10x),
        AppleTV(
            name: "Apple TV 4K (2nd Gen, 2021)",
            identifiers: ["AppleTV11,1"],
            supportId: "SP845",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP845/sp845-apple-tv-4k-2gen_2x.png",
            cpu: .a12),
        AppleTV(
            name: "Apple TV 4K (3rd Gen, 2022)",
            identifiers: ["AppleTV14,1"],
            supportId: "SP886",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP886/apple-tv-4k-3gen_2x.png",
            cpu: .a15),
    ]
}

public struct HomePod: IdiomType {
    public var device: Device
    static let isMini = "isMini"
    public var isMini: Bool {
        device.idiomProperties[Self.isMini].boolValue
    }

    public init(
        name: String,
        identifiers: [String],
        supportId: String,
        image: String?,
        cpu: CPU,
        isMini: Bool = false)
    {
        device = Device(idiom: .homePod, name: name, identifiers: identifiers, cpu: cpu, hasBattery: false, screen: .w38, idiomProperties: [Self.isMini: isMini])
    }
    
    init(identifier: String) {
        self.init(
            name: "Unknown HomePod",
            identifiers: [identifier],
            supportId: "UNKNOWN",
            image: nil,
            cpu: .unknown
        )
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        if isMini {
            return "homepodmini"
        }
        return "homepod"
    }

    static var all = [
        HomePod(
            name: "HomePod",
            identifiers: ["AudioAccessory1,1"],
            supportId: "SP773",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP773/homepod_space_gray_large_2x.jpg",
            cpu: .a8),
        HomePod(
            name: "HomePod mini",
            identifiers: ["AudioAccessory5,1"],
            supportId: "SP834",
            image: "https://cdsassets.apple.com/live/SZLF0YNV/images/sp/111914_homepod-mini-colours.png",
            cpu: .s5),
        HomePod(
            name: "HomePod (2nd generation)",
            identifiers: ["AudioAccessory6,1"],
            supportId: "SP888",
            image: "https://cdsassets.apple.com/live/SZLF0YNV/images/sp/111843_homepod-2gen.png",
            cpu: .s7),
    ]
}

public struct AppleWatch: IdiomType {
    public var device: Device
    static let watchSize = "watchSize"
    public var watchSize: WatchSize {
        device.idiomProperties[Self.watchSize] as! AppleWatch.WatchSize
    }
    public var bandSize: WatchSize.BandSize {
        watchSize.bandSize
    }
    public enum WatchSize {
        case unknown
        case mm38
        case mm40
        case mm41
        case mm42
        case mm44
        case mm45
        case mm49 // ultra
        
        public enum BandSize {
            case small // 38mm, 40mm, 41mm
            case large // 42mm, 44mm, 45mm, 49mm
        }
        public var bandSize: BandSize {
            switch self {
            case .mm38: fallthrough
            case .mm40: fallthrough
            case .mm41: return .small
            default: return .large
            }
        }
        public var screen: Screen {
            switch self {
            case .unknown: return .wUnknown // placeholder
            case .mm38: return .w38
            case .mm40: return .w40
            case .mm41: return .w41
            case .mm42: return .w42
            case .mm44: return .w44
            case .mm45: return .w45
            case .mm49: return .w49
            }
        }
    }
    
    public init(
        name: String,
        identifiers: [String],
        supportId: String,
        image: String?,
        cpu: CPU,
        size: WatchSize,
        hasForce3dTouchSupport: Bool = false
    ) {
        device = Device(
            idiom: .watch,
            name: name,
            identifiers: identifiers,
            supportId: supportId,
            image: image,
            cpu: cpu,
            hasBattery: true,
            supportsWirelessCharging: true,
            hasForce3dTouchSupport: hasForce3dTouchSupport,
            screen: size.screen,
            idiomProperties: [Self.watchSize: size]
        )
    }
    
    init(identifier: String) {
        self.init(
            name: "Unknown  Watch",
            identifiers: [identifier],
            supportId: "UNKNOWN",
            image: nil,
            cpu: .unknown,
            size: .unknown)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return "applewatch"
    }

    static var all = [
        AppleWatch(
            name: "Apple Watch (1st generation) 38mm",
            identifiers: ["Watch1,1"],
            supportId: "SP735",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/0/IM784/en_US/apple_watch_sport-240.png",
            cpu: .s1,
            size: .mm38,
            hasForce3dTouchSupport: true
        ),
        AppleWatch(
            name: "Apple Watch (1st generation) 42mm",
            identifiers: ["Watch1,2"],
            supportId: "SP735",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/0/IM784/en_US/apple_watch_sport-240.png",
            cpu: .s1,
            size: .mm42,
            hasForce3dTouchSupport: true
        ),
        
        AppleWatch(
            name: "Apple Watch (series 1) 38mm",
            identifiers: ["Watch2,6"],
            supportId: "SP745",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/0/IM784/en_US/apple_watch_sport-240.png",
            cpu: .s1p,
            size: .mm38,
            hasForce3dTouchSupport: true
        ),
        AppleWatch(
            name: "Apple Watch (series 1) 42mm",
            identifiers: ["Watch2,7"],
            supportId: "SP745",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/0/IM784/en_US/apple_watch_sport-240.png",
            cpu: .s1p,
            size: .mm42,
            hasForce3dTouchSupport: true
        ),
        
        AppleWatch(
            name: "Apple Watch (series 2) 38mm",
            identifiers: ["Watch2,3"],
            supportId: "SP746",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/0/IM852/en_US/applewatch-series2-hermes-240.png",
            cpu: .s2,
            size: .mm38,
            hasForce3dTouchSupport: true
        ),
        AppleWatch(
            name: "Apple Watch (series 2) 42mm",
            identifiers: ["Watch2,4"],
            supportId: "SP746",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/0/IM852/en_US/applewatch-series2-hermes-240.png",
            cpu: .s2,
            size: .mm42,
            hasForce3dTouchSupport: true
        ),
        
        AppleWatch(
            name: "Apple Watch (series 3) 38mm",
            identifiers: ["Watch3,1", "Watch3,3"],
            supportId: "SP766",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/0/IM893/en_US/apple-watch-s3-nikeplus-240.png",
            cpu: .s3,
            size: .mm38,
            hasForce3dTouchSupport: true
        ),
        AppleWatch(
            name: "Apple Watch (series 3) 42mm",
            identifiers: ["Watch3,2", "Watch3,4"],
            supportId: "SP766",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/0/IM893/en_US/apple-watch-s3-nikeplus-240.png",
            cpu: .s1p,
            size: .mm42,
            hasForce3dTouchSupport: true
        ),
        
        AppleWatch(
            name: "Apple Watch (series 4) 40mm",
            identifiers: ["Watch4,1", "Watch4,3"],
            supportId: "SP778",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/0/IM893/en_US/apple-watch-s3-nikeplus-240.png",
            cpu: .s4,
            size: .mm40,
            hasForce3dTouchSupport: true
        ),
        AppleWatch(
            name: "Apple Watch (series 4) 44mm",
            identifiers: ["Watch4,2", "Watch4,4"],
            supportId: "SP778",
            image: "https://km.support.apple.com/resources/sites/APPLE/content/live/IMAGES/0/IM893/en_US/apple-watch-s3-nikeplus-240.png",
            cpu: .s4,
            size: .mm44,
            hasForce3dTouchSupport: true
        ),
        
        AppleWatch(
            name: "Apple Watch (series 5) 40mm",
            identifiers: ["Watch5,1", "Watch5,3"],
            supportId: "SP808",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP808/sp808-apple-watch-series-5_2x.png",
            cpu: .s5,
            size: .mm40,
            hasForce3dTouchSupport: true
        ),
        AppleWatch(
            name: "Apple Watch (series 5) 44mm",
            identifiers: ["Watch5,2", "Watch5,4"],
            supportId: "SP808",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP808/sp808-apple-watch-series-5_2x.png",
            cpu: .s5,
            size: .mm44,
            hasForce3dTouchSupport: true
        ),
        
        AppleWatch(
            name: "Apple Watch (series 6) 40mm",
            identifiers: ["Watch6,1", "Watch6,3"],
            supportId: "SP826",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP826/sp826-apple-watch-series6-580_2x.png",
            cpu: .s6,
            size: .mm40),
        AppleWatch(
            name: "Apple Watch (series 6) 44mm",
            identifiers: ["Watch6,2", "Watch6,4"],
            supportId: "SP826",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP826/sp826-apple-watch-series6-580_2x.png",
            cpu: .s6,
            size: .mm44),
        
        AppleWatch(
            name: "Apple Watch SE 40mm",
            identifiers: ["Watch5,9", "Watch5,11"],
            supportId: "SP827",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP827/sp827-apple-watch-se-580_2x.png",
            cpu: .s5,
            size: .mm40),
        AppleWatch(
            name: "Apple Watch SE 44mm",
            identifiers: ["Watch5,10", "Watch5,12"],
            supportId: "SP827",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP827/sp827-apple-watch-se-580_2x.png",
            cpu: .s5,
            size: .mm44),
        
        AppleWatch(
            name: "Apple Watch (series 7) 41mm",
            identifiers: ["Watch6,6", "Watch6,8"],
            supportId: "SP860",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP860/series7-480_2x.png",
            cpu: .s7,
            size: .mm41),
        AppleWatch(
            name: "Apple Watch (series 7) 45mm",
            identifiers: ["Watch6,7", "Watch6,9"],
            supportId: "SP860",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP860/series7-480_2x.png",
            cpu: .s7,
            size: .mm45),
        
        AppleWatch(
            name: "Apple Watch (series 8) 41mm",
            identifiers: ["Watch6,14", "Watch6,16"],
            supportId: "SP878",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP878/apple-watch-series8_2x.png",
            cpu: .s8,
            size: .mm41),
        AppleWatch(
            name: "Apple Watch (series 8) 45mm",
            identifiers: ["Watch6,15", "Watch6,17"],
            supportId: "SP878",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP878/apple-watch-series8_2x.png",
            cpu: .s8,
            size: .mm45),
        
        AppleWatch(
            name: "Apple Watch SE (2nd generation) 40mm",
            identifiers: ["Watch6,10", "Watch6,12"],
            supportId: "SP877",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP877/apple-watch-se-2nd-gen_2x.png",
            cpu: .s8,
            size: .mm40),
        AppleWatch(
            name: "Apple Watch SE (2nd generation) 44mm",
            identifiers: ["Watch6,11", "Watch6,13"],
            supportId: "SP877",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP877/apple-watch-se-2nd-gen_2x.png",
            cpu: .s8,
            size: .mm44),
        
        AppleWatch(
            name: "Apple Watch Ultra",
            identifiers: ["Watch6,18"],
            supportId: "SP879",
            image: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP879/apple-watch-ultra_2x.png",
            cpu: .s8,
            size: .mm49),
        
        AppleWatch(
            name: "Apple Watch (series 9) 41mm",
            identifiers: ["Watch7,3"],
            supportId: "SP905",
            image: "https://support.apple.com/library/content/dam/edam/applecare/images/en_US/applewatch/apple-watch-series-9-gps.png",
            cpu: .s9,
            size: .mm41),
        AppleWatch(
            name: "Apple Watch (series 9) 45mm",
            identifiers: ["Watch7,4"],
            supportId: "SP905",
            image: "https://support.apple.com/library/content/dam/edam/applecare/images/en_US/applewatch/apple-watch-series-9-gps.png",
            cpu: .s9,
            size: .mm45),
        
        AppleWatch(
            name: "Apple Watch Ultra 2",
            identifiers: ["Watch7,5"],
            supportId: "SP906",
            image: "https://support.apple.com/library/content/dam/edam/applecare/images/en_US/applewatch/apple-watch-ultra-2.png",
            cpu: .s9,
            size: .mm49),
    ]
}

public struct AppleVision: IdiomType {
    public var device: Device
    public init(
        name: String,
        identifiers: [String],
        supportId: String,
        image: String?,
        cpu: CPU
    ) {
        device = Device(idiom: .vision, name: name, identifiers: identifiers, supportId: supportId, image: image, isPro: true, cpu: cpu, hasBattery: true, biometrics: .opticID, cameras: 12, hasLidarSensor: true, screen: .p720)
    }
    
    init(identifier: String) {
        self.init(
            name: "Unknown  Vision Device",
            identifiers: [identifier],
            supportId: "UNKNOWN",
            image: nil,
            cpu: .unknown)
    }
    
    /// An SF Symbol name for an icon representing the device.  If no specific variant exists, uses a generic symbol for device idiom.
    public var symbolName: String {
        return "visionpro"
    }

    static var all = [
        AppleVision(
            name: "Apple Vision Pro",
            identifiers: ["RealityDevice14,1"],
            supportId: "SP911",
            image: "https://www.apple.com/newsroom/images/media/Apple-WWCD23-Vision-Pro-glass-230605_big.jpg.large.jpg",
            cpu: .m2),
    ]
}

// support bool value with generic property lists for device structs.  The previous suggestions to test against nil doesn't work if we're defaulting to a `false` value that is not nil.
extension Any? {
    var boolValue: Bool {
        if let bool = self as? Bool {
            return bool
        }
        return false
    }
}
