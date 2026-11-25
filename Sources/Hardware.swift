import Compatibility
import Color

#if canImport(SwiftUI)
import SwiftUI
#endif

public protocol DeviceAttributeExpressible: Hashable, SymbolRepresentable, CaseNameConvertible {
    var symbolName: SFSymbol { get }
    var label: String { get } // description doesn't work since it can cause infinite recursion
#if canImport(SwiftUI) && canImport(Foundation)
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    var color: Color { get }
#endif
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    @MainActor
    func test(device: DeviceType) -> Bool
}

/// Can't do Identifiable because not supported on older devices.
public extension DeviceAttributeExpressible {
	/// Stable, value-aware identity for lists and accessibility hooks. Reflection
	/// includes associated values, so each biometric and capability variant is unique.
	var id: String { String(reflecting: self) }
}

// MARK: Capabilities
extension Device {
    public typealias Capabilities = Set<Capability>
}
public typealias Capabilities = Device.Capabilities
public enum Capability: CaseIterable, DeviceAttributeExpressible, Sendable, Codable {
    // model attributes
    case pro, air, mini, plus, max
    case macForm(Mac.Form)
    case watchSize(AppleWatch.WatchSize)
    // connections
    case headphoneJack, ethernet, fireWire, miniDisplayPort, thirtyPin, lightning, usbC, thunderbolt // TODO: Add .cardReader for SDCard Reader, .hdmi for HDMI, .usbA for USB-A?, .irReceiver, add Apple Pencil Hover feature??
    // power
    case battery
    case wirelessCharging // qi charging
    case fastCharge // fast charge support
    case magSafe // circular magnetically alligned qi charging (anything that has magSafe should also have wirelessCharging and a battery)
    // notebook magSafe connectors
    case magSafe1, magSafe2, magSafe3
    case biometrics(Biometrics)
    case cameras(Set<Camera>)
    case cellular(Cellular)
    case esim, dualesim
    case nfc // iPhone 7+
    // Should we add: wifi (don't all devices have this?  Perhaps wifi version?), bluetooth (do all have this?  bluetooth version?), bluetoothLE, 30pin, AC Power?, ethernet, gigabitEthernet?, 10GBEthernet?, ir receiver, HDMI, SDCard?
    // display
    /// Fixed displays in catalog order; the first item is the compatibility `screen` value.
    case screens([Screen])
    case force3DTouch
    case roundedCorners
    case notch // newer macs and faceID phones without Dynamic Island.
    case dynamicIsland
    case alwaysOnDisplay
    /// A touch-sensitive built-in display. This is distinct from touch input
    /// supplied by a trackpad, pointer, or connected display.  Mainly for the new MacBook Pros with Proled display.
    case touchDisplay
    // TODO: add ProMotion support
    // TODO: add HDR support?
    // TODO: figure out what a Fluid Display is??  Maybe it refers to Liquid Retina XDR display on iPad Pro 12.9-inch (5th and 6th generation). https://support.apple.com/en-us/102255
    // hardware features
    // TODO: Touchbar?  Home Button?
    case ringerSwitch // mini 2, 3, iPad up to 10"? iPhone up to iPhone 15 Pro
    case actionButton // iPhone 15 Pro+, Apple Watch Ultra
    case cameraControl // iPhone 16+
    /// A camera lens whose physical aperture can change between supported f-stops.
    case variableAperture // iPhone 18 Pro and iPhone 18 Pro Max
    case pencils(Set<ApplePencil>)
    // sensors
    case gps, compass, lidar, barometer, fallDetection, electrocardiogram, oxygenSensor /* capability - this may be disabled in newer devices in the US */, crashDetection // iPhone 14+
    // software features
    case targetDisplayMode
    case applePay // iPhone 6+
    case appleIntelligence
    /// On-device audio intelligence features, distinct from the broader Apple Intelligence suite.
    case audioIntelligence
    // TODO: altimeter, sleepTracking, wristTemp(thermometer?temperatureSensing?), sleepApnea, depthGauge, waterTemperatureSensor, doubleTap, siren, wristFlick (The wrist flick gesture is available on Apple Watch Series 9 and later and Apple Watch Ultra 2. Not available on Apple Watch SE.)
    // .spatialPhotography, .satellite (watch ultra 3+)
    
    public static let modelAttributes = [Capability.pro, .air, .mini, .plus, .max]
    public static let connections = [Capability.headphoneJack, .ethernet, .fireWire, .miniDisplayPort, .thirtyPin, .lightning, .usbC, .thunderbolt]
    public static let power = [Capability.battery, .wirelessCharging, .fastCharge, .magSafe, .magSafe1, .magSafe2, .magSafe3]
    public static let allBiometrics = Biometrics.allCases.map { Capability.biometrics($0) }
    public static let wirelessConnections = [Capability.esim, .dualesim, .nfc]
    public static let screenFeatures = [Capability.force3DTouch, .roundedCorners, .notch, .dynamicIsland, .alwaysOnDisplay, .touchDisplay]
    public static let hardware = [Capability.ringerSwitch, .actionButton, .cameraControl, .variableAperture]
    public static let sensors = [Capability.gps, .compass, .lidar, .barometer, .fallDetection, .electrocardiogram, .oxygenSensor, .crashDetection]
    public static let software = [Capability.targetDisplayMode, .applePay, .appleIntelligence, .audioIntelligence]

    /// Lists all non-associated value cases
    /// New capabilities need to be listed here as well as the sorted extension and have a symbolName entry.
    public static let allCases = modelAttributes + connections + power + allBiometrics + wirelessConnections + screenFeatures + hardware + sensors + software

    public var symbolName: SFSymbol {
        switch self {
        case .pro:
            return "gearshape"
        case .air:
            return "wind"
        case .mini:
            return "squareshape.squareshape.dotted"
        case .plus:
            return "plus.rectangle.portrait"
        case .max:
            return "squareshape.dotted.squareshape"
        case .macForm(let form):
            return form.rawValue
        case .watchSize(_):
            return "applewatch.side.right"
        case .headphoneJack:
            return "headphones"
        case .ethernet:
            return "ethernet"
        case .fireWire:
            return "firewire"
        case .miniDisplayPort:
            return "minidisplayport"
        case .thirtyPin:
            return "thirtyPin"
        case .lightning:
            return "lightning" // "bolt.fill" // "cable.connector.lightning"
        case .usbC:
            return "cable.connector.usbc"
        case .thunderbolt:
            return "thunderbolt"
        case .wirelessCharging:
            return "wirelesscharging"
        case .fastCharge:
            return "fast.bolt.battery"
        case .nfc:
            return "wave.3.right.circle"
        case .cellular(_):
            return "antenna.radiowaves.left.and.right"
        case .screens(_):
            return "arrow.up.right.and.arrow.down.left.rectangle"
        case .notch:
            return "notch"
        case .roundedCorners:
            return "roundedcorners"
        case .dynamicIsland:
            return "dynamicisland"
        case .alwaysOnDisplay:
            return "alwaysondisplay"
        case .touchDisplay:
            return "hand.point.up.left"
        case .battery:
            return "battery.100percent"
        case .ringerSwitch:
            return "bell.slash"
        case .esim:
            return "esim.fill"
        case .dualesim:
            return "simcard.2"
        case .magSafe:
            return "magsafe"
        case .magSafe1:
            return "magsafe1"
        case .magSafe2:
            return "magsafe2"
        case .magSafe3:
            return "magsafe3"
        case .actionButton:
            return "button.horizontal.top.press"
        case .cameraControl:
            return "camera.shutter.button"
        case .variableAperture:
            return "camera.aperture"
        case .pencils(_):
            return "applepencil"
        case .force3DTouch:
            return "hand.tap"
        case .gps:
            return "globe"
        case .compass:
            return "location.north.circle"
        case .lidar:
            return "lidar"
        case .barometer:
            return "barometer"
        case .fallDetection:
            return "figure.fall"
        case .electrocardiogram:
            return "waveform.path.ecg"
        case .oxygenSensor:
            return "lungs.fill"
        case .crashDetection:
            return "car.side.rear.and.collision.and.car.side.front"
        case .audioIntelligence:
            return "waveform.and.mic"
        case .biometrics(let biometrics):
            return biometrics.symbolName
        case .cameras(_):
            return "camera"
        case .targetDisplayMode:
            return "display"
        case .applePay:
            return "applepay"
        case .appleIntelligence:
            return "apple.intelligence"
        @unknown default:
            return .defaultUnknownSymbol
        }
    }
    
    public func test(device: DeviceType) -> Bool {
        return device.has(self)
    }
    
    public var isBiometric: Bool {
        if case .biometrics(_) = self {
            return true
        }
        return false
    }
    
    /// caseName string.  Do not use this in a var description: String or it will cause an infinite loop.
    public var label: String {
        switch self {
        case .gps:
            return "GPS"
        case .touchDisplay:
            return "Touch Display"
		case .biometrics(let biometric):
			return biometric.label
        default:
            return caseName
        }
    }
}
// device specific have functions for getting a wrapped capability out.
public extension Capabilities {
    static let modelAttributes = Set(Capability.screenFeatures)
    static let connections = Set(Capability.connections)
    static let allBiometrics = Set(Capability.allBiometrics)
    static let wirelessConnections = Set(Capability.wirelessConnections)
    static let screenFeatures = Set(Capability.screenFeatures)
    static let hardware = Set(Capability.hardware)
    static let sensors = Set(Capability.sensors)
    static let software = Set(Capability.software)

    internal func check(orderedCapabilities: [Capability], sorted: inout [Capability], skipped: inout [Capability]) {
        for item in orderedCapabilities {
            if self.contains(item) {
                sorted.append(item)
            } else {
                skipped.append(item)
            }
        }
    }

    /// Order them based off of the order in the Capability definition for consistency
    var sorted: [Capability] {
        var sorted = [Capability]()
        var skipped = [Capability]()
        // model attributes
        check(orderedCapabilities: Capability.modelAttributes, sorted: &sorted, skipped: &skipped)
        if let macForm {
            sorted.append(.macForm(macForm))
        }
        if let watchSize {
            sorted.append(.watchSize(watchSize))
        }
        // connections
        check(orderedCapabilities: Capability.connections + Capability.power + Capability.allBiometrics, sorted: &sorted, skipped: &skipped)
        if cameras.count > 0 {
            sorted.append(.cameras(cameras))
        }
        if let cellular {
            sorted.append(.cellular(cellular))
        }
        check(orderedCapabilities: Capability.wirelessConnections, sorted: &sorted, skipped: &skipped)
        // display
        if !screens.isEmpty {
            sorted.append(.screens(screens))
        }
        check(orderedCapabilities: Capability.screenFeatures + Capability.hardware, sorted: &sorted, skipped: &skipped)
        if pencils.count > 0 {
            sorted.append(.pencils(pencils))
        }
        // sensors
        check(orderedCapabilities: Capability.sensors + Capability.software, sorted: &sorted, skipped: &skipped)

        // check for missing!
        for item in Capability.allCases {
            if !sorted.contains(item) && !skipped.contains(item) {
                debug("Found missing capability: \(item)!  Please make sure the capability is included in the sort.", level: .ERROR)
                sorted.append(item)
            }
        }
        return sorted
    }
    /// Wrapper for .macForm capability.
    var macForm: Mac.Form? {
        get {
            for capability in self {
                if case .macForm(let macForm) = capability {
                    return macForm
                }
            }
            return nil
        }
        set {
            // make sure we're not doubling up on values and if nil, we remove the existing value
            for capability in self {
                if case .macForm = capability {
                    self.remove(capability)
                }
            }
            if let newValue {
                self.insert(.macForm(newValue))
            }
        }
    }
    /// Wrapper for .watchSize capability.
    var watchSize: AppleWatch.WatchSize? {
        get {
            for capability in self {
                if case .watchSize(let watchSize) = capability {
                    return watchSize
                }
            }
            return nil
        }
        set {
            // make sure we're not doubling up on values and if nil, we remove the existing value
            for capability in self {
                if case .watchSize = capability {
                    self.remove(capability)
                }
            }
            if let newValue {
                self.insert(.watchSize(newValue))
            }
        }
    }
    /// Wrapper for .cellular capability.
    var cellular: Cellular? {
        get {
            for capability in self {
                if case .cellular(let cellular) = capability {
                    return cellular
                }
            }
            return nil
        }
        set {
            // make sure we're not doubling up on values and if nil, we remove the existing value
            for capability in self {
                if case .cellular = capability {
                    self.remove(capability)
                }
            }
            if let newValue {
                self.insert(.cellular(newValue))
            }
        }
    }
    /// Compatibility wrapper exposing the first display.
	@available(*, deprecated, message: "Read screens.first, or assign screens to replace hardware panels.")
    var screen: Screen? {
        get {
            for capability in self {
                if case .screens(let screens) = capability {
                    return screens.first
                }
            }
            return nil
        }
        set {
            // make sure we're not doubling up on values and if nil, we remove the existing value
            let existing = screens
            for capability in self { if case .screens = capability { self.remove(capability) } }
            if let newValue { self.insert(.screens(existing.dropFirst().isEmpty ? [newValue] : [newValue] + Array(existing.dropFirst()))) }
        }
    }
    /// Fixed screen metadata in primary/front-first order.
    var screens: [Screen] {
        get {
            for case .screens(let screens) in self { return screens }
            return []
        }
        set {
            for capability in self {
                if case .screens = capability { remove(capability) }
            }
            if !newValue.isEmpty { insert(.screens(newValue)) }
        }
    }

    /// Wrapper for .cameras capability.  Note, if we set this value, it will replace any existing .cameras value.
    var cameras: Set<Camera> {
        get {
            for capability in self {
                if case .cameras(let cameras) = capability {
                    return cameras
                }
            }
            return []
        }
        set {
            for capability in self {
                if case .cameras = capability {
                    self.remove(capability)
                }
            }
            // don't add if empty list
            if newValue.count > 0 {
                self.insert(.cameras(newValue))
            }
        }
    }
    /// Wrapper for .pencils capability.  Note, if we set this value, it will replace any existing .pencils value.
    var pencils: Set<ApplePencil> {
        get {
            for capability in self {
                if case .pencils(let pencils) = capability {
                    return pencils
                }
            }
            return []
        }
        set {
            for capability in self {
                if case .pencils = capability {
                    self.remove(capability)
                }
            }
            // don't add if empty list
            if newValue.count > 0 {
                self.insert(.pencils(newValue))
            }
        }
    }
    /// Wrapper for .biometrics capability.
    var biometrics: Biometrics? {
        get {
            for capability in self {
                if case .biometrics(let biometrics) = capability {
                    return biometrics
                }
            }
            return nil
        }
        set {
            // make sure we're not doubling up on values and if nil, we remove the existing value
            for capability in self {
                if case .biometrics = capability {
                    self.remove(capability)
                }
            }
            if let newValue {
                self.insert(.biometrics(newValue))
            }
        }
    }
}

// MARK: CPU
// https://en.wikipedia.org/wiki/List_of_Mac_models_grouped_by_CPU_type
public enum CPU: String, RawRepresentable, Hashable, CaseIterable, CaseNameConvertible, Sendable, Codable {
    // Only 2013+ really need to be included since Swift won't run on devices prior to this.
    case unknown = "Unknown"
    // accessories
    case u1 = "Apple U1"
    /// AirPods
    case h1 = "Apple H1"
    /// AirPods Pro
    case h2 = "Apple H2"
    // Mac/iPad
    case i3
    case xeonE5
    case i5
    case i7 = "Intel Core i7"
    /// for models that have both i5 and i7 variants
    case intel
    case m1 = "Apple M1"
    case m1pro = "Apple M1 Pro"
    case m1max = "Apple M1 Max"
    case m1ultra = "Apple M1 Ultra"
    /// also  Vision
    case m2 = "Apple M2"
    case m2pro = "Apple M2 Pro"
    case m2max = "Apple M2 Max"
    case m2ultra = "Apple M2 Ultra"
    case m3 = "Apple M3"
    case m3pro = "Apple M3 Pro"
    case m3max = "Apple M3 Max"
    case m3ultra = "Apple M3 Ultra"
    case m4 = "Apple M4"
    case m4pro = "Apple M4 Pro"
    case m4max = "Apple M4 Max"
    case m5 = "Apple M5"
    case m5pro = "Apple M5 Pro"
    case m5max = "Apple M5 Max"
	case m5ultra = "Apple M5 Ultra"
	case m6 = "Apple M6"
//	case m6pro = "Apple M6 Pro" // guessing
//	case m6max = "Apple M6 Max" // guessing
    // NO M4 Ultra version
    // iPod/iPhone
    /// Samsung S5L8900 for original iPhone, iPhone 3G, original iPod touch (ARM 8900B and APL0098) (max iOS 4.2.1)/
    case s5L8900 = "Samsung S5L8900"
    /// iPod touch 2nd generation/
    case s5L8720 = "Samsung S5L8720"
    /// iPod touch 3rd generation/
    case s5L8922 = "Samsung S5L8922"
    /// iPhone 3GS (S5L8920)/
    case s5L8920 = "Samsung S5L8920"
    case a4
    case a5
    case a5x
    case a6
    case a6x
    case a7
    // iPhone
    // iPad
    case a8x
    case a9
    case a9x
    case a10 // fusion
    case a11 = "Apple A11 Bionic"
    case a12 = "Apple A12 Bionic" // also Apple TV
    case a12x
    case a12z
    case a13
    case a14 = "Apple A14 Bionic"
    case a16 = "Apple A16 Bionic"
    case a17pro = "Apple A17 Pro"
    case a18 = "Apple A18"
    case a18pro = "Apple A18 Pro"
    case a19 = "Apple A19"
    case a19pro = "Apple A19 Pro"
    case a20pro = "Apple A20 Pro"
    //  TV
    case intel_pm1 = "Intel Pentium M (1GHz)"
    case a8
    case a10x = "Apple A10X Fusion"
    case a15 // Bionic
    //  Watch
    case s1
    case s1p
    case s2
    case s3
    case s4
    case s5
    case s6
    case s7
    case s8
    case s9
    case s10
    case s11
}

// MARK: Biometrics
public enum Biometrics: Hashable, CaseNameConvertible, CaseIterable, Sendable, Codable {
    case none
    case touchID
    case faceID
    case opticID
    public var symbolName: SFSymbol {
        switch self {
        case .none:
            return "number"
        case .touchID:
            return "touchid"
        case .faceID:
            return "faceid"
        case .opticID:
            if #available(iOS 17, macOS 14, macCatalyst 17, tvOS 17, watchOS 10,  *) {
                return "opticid" // unavailable before iOS 17
            } else {
                return "eye"
            }
        }
    }
    public static var allCases: [Biometrics] {
        return [.touchID, .faceID, .opticID]
    }

    /// Display name for this biometric technology in capability lists.
    public var label: String {
        switch self {
        case .none: return "Biometrics"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        }
    }
}

// MARK: Camera
public enum Camera: Hashable, CaseIterable, CaseNameConvertible, Sendable, Codable { // TODO: Do we want to include the focal length in these?  Perhaps position, focal length, megapixels, field of view?
    /// original iPhone
    case twoMP
    /// iPhone 3GS
    case threeMP
    /// 8mp iPod touch 7th gen/iPhone 6
    case iSight
    /// iPad 2 front camera
    case vga
    /// 12MP ƒ/1.6 aperture iPhone 12, ƒ/1.5 aperture iPhone 13 Pro, 26 mm, ƒ/1.5 aperture, iPhone 14 Plus
    case wide
    /// 2x 12MP ƒ/2.0 aperture 12 MP iPhone 12 Pro, ƒ/2.8 aperture iPhone 13 Pro
    case telephoto
    /// 12MP iPhone 12 Pro Max
    case telephoto2½x
    /// 12MP iPhone 13 Pro
    case telephoto3x
    /// 12MP iPhone 15 Pro Max
    case telephoto5x
    /// 12MP ƒ/2.4 aperture 12 MP iPhone 12, ƒ/1.8 aperture and 120° field of view iPhone 13 Pro, 13 mm, ƒ/2.4 aperture and 120° field of view iPhone 14 Plus
    case ultraWide
    case ultraWide48MP
    case main12MP
    case main48MP
    /// 48 MP
    case fusionMain
    /// 48 MP
    case fusionUltraWide
    /// 48 MP 8x
    case fusionTelephoto
    // MARK: - front facing
    /// mac front facing 720p 7MP
    case faceTimeHD720p
    /// mac front facing 1080p 7MP
    case faceTimeHD1080p
    case trueDepth7MP
    /// ƒ/2.2 aperture 12 MP iPhone 12 Pro, ƒ/1.9 aperture iPhone 14 Plus
    case trueDepth12MP
    /// 18MP Center Stage front camera in iPhone 17+
    case centerStage
    /// vision pro
    case stereoscopic
    case persona
}
public extension Set<Camera> {
    static let `default`: Set<Camera> = [.wide,.ultraWide,.trueDepth7MP]
    /// Order them based off of the order in the definition for consistency
    var sorted: [Camera] {
        var sorted = [Camera]()
        // model attributes
        for item in Camera.allCases {
            if self.contains(item) {
                sorted.append(item)
            }
        }
        return sorted
    }
}

// MARK: Cellular
public enum Cellular: Hashable, Comparable, CaseNameConvertible, Sendable, Codable {
    case none // TODO: Take this out?  Do we need it for anything?  This should only be available in iPhone and iPad (protocol CellularCapable)
    case gprs // 1G
    case edge // 2G
    case threeG // 3G
    case lte // 4G LTE
    case fiveG // 5G
}

// MARK: Pencil
public enum ApplePencil: Hashable, CaseIterable, CaseNameConvertible, Sendable, Codable, DeviceAttributeExpressible {
    case firstGeneration // Awkward charging one
    case secondGeneration // magnetic attachment/charging
    case usbC // Apple Pencil (USB‑C)
    case pro // Apple Pencil Pro (different magnets attachment)
    public var symbolName: SFSymbol {
        switch self {
        case .firstGeneration:
            "applepencil.gen1"
        case .secondGeneration:
            "applepencil.gen2"
        case .usbC:
            "applepencil" // Apple doesn't have a special symbol for this unfortunately
        case .pro:
            "applepencil" // Apple doesn't have a special symbol for this unfortunately
        }
    }
    public var name: String {
        switch self {
        case .firstGeneration:
            " Pencil (1st generation)"
        case .secondGeneration:
            " Pencil (2nd generation)"
        case .usbC:
            " Pencil (USB-C)"
        case .pro:
            " Pencil Pro"
        }
    }
    // for DeviceAttributeExpressible conformance
    public var label: String { name }
	@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
	public var color: Color { .pink }
    public func test(device: any DeviceType) -> Bool {
        device.capabilities.pencils.contains(self)
    }
}
public extension Set<ApplePencil> {
    /// Order them based off of the order in the definition for consistency
    var sorted: [ApplePencil] {
        var sorted = [ApplePencil]()
        // model attributes
        for item in ApplePencil.allCases {
            if self.contains(item) {
                sorted.append(item)
            }
        }
        return sorted
    }
}
