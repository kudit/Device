import Compatibility

#if canImport(SwiftUI)
import SwiftUI
#endif

public protocol DeviceAttributeExpressible: Hashable, SymbolRepresentable, CaseNameConvertible {
    var symbolName: String { get }
    var label: String { get } // description doesn't work since it can cause infinite recursion
#if canImport(SwiftUI)
    @available(iOS 13.0, tvOS 13, watchOS 6, *)
    var color: Color { get }
#endif
    @available(iOS 13, tvOS 13, watchOS 6, *)
    @MainActor
    func test(device: DeviceType) -> Bool
}

// MARK: Capabilities
extension Device {
    public typealias Capabilities = Set<Capability>
}
public typealias Capabilities = Device.Capabilities
public enum Capability: CaseIterable, DeviceAttributeExpressible, Sendable {
    // model attributes
    case pro, air, mini, plus, max
    case macForm(Mac.Form)
    case watchSize(AppleWatch.WatchSize)
    // connections
    case headphoneJack, ethernet, thirtyPin, lightning, usbC, thunderbolt // TODO: Add .sdcReader for SDCard Reader, FireWire 800, HDMI, DisplayPort?, USB-A?
    // power
    case battery
    case wirelessCharging // qi charging
    case magSafe // circular magnetically alligned qi charging (anything that has magSafe should also have wirelessCharging and a battery)
    // notebook magSafe connectors
    case magSafe1, magSafe2, magSafe3
    case biometrics(Biometrics)
    case cameras(Set<Camera>)
    case cellular(Cellular)
    case esim, dualesim
    case applePay // iPhone 6+
    case nfc // iPhone 7+
    // Should we add: wifi (don't all devices have this?  Perhaps wifi version?), bluetooth (do all have this?  bluetooth version?), bluetoothLE, 30pin, AC Power?, ethernet, gigabitEthernet?, 10GBEthernet?, ir receiver, HDMI, SDCard?
    // display
    case screen(Screen)
    case force3DTouch
    case roundedCorners
    case notch // newer macs and original faceID phones.
    case dynamicIsland
    case alwaysOnDisplay
    // TODO: add ProMotion support
    // TODO: add HDR support?
    // TODO: figure out what a Fluid Display is??  Maybe it refers to Liquid Retina XDR display on iPad Pro 12.9-inch (5th and 6th generation). https://support.apple.com/en-us/102255
    // features
    // TODO: Touchbar?
    case ringerSwitch // mini 2, 3, iPad up to 10"? iPhone up to iPhone 15 Pro
    case actionButton // iPhone 15 Pro+, Apple Watch Ultra
    case cameraControl // iPhone 16+
    case pencils(Set<ApplePencil>)
    // sensors
    case compass, lidar, barometer, crashDetection // iPhone 14+
    // software features
    case appleIntelligence
    // TODO: Add Compass!  Works on watch and iPhone.
    // TODO: altimeter, ecg(electricalHeartSensor?), bloodO2, sleepTracking, wristTemp(thermometer?temperatureSensing?), fallDetection, sleepApnea, depthGauge, waterTemperatureSensor, doubleTap,
    
    public static let modelAttributes = [Capability.pro, .air, .mini, .plus, .max]
    public static let connections = [Capability.headphoneJack, .ethernet, .thirtyPin, .lightning, .usbC, .thunderbolt]
    public static let power = [Capability.battery, .wirelessCharging, .magSafe, .magSafe1, .magSafe2, .magSafe3]
    public static let allBiometrics = [Capability.biometrics(.touchID), .biometrics(.faceID), .biometrics(.opticID)]
    public static let wirelessConnections = [Capability.esim, .dualesim, .nfc]
    public static let screenFeatures = [Capability.force3DTouch, .roundedCorners, .notch, .dynamicIsland, .alwaysOnDisplay]
    public static let hardware = [Capability.ringerSwitch, .actionButton, .cameraControl]
    public static let sensors = [Capability.compass, .lidar, .barometer, .crashDetection]
    public static let software = [Capability.applePay, .appleIntelligence]

    /// Lists all non-associated value cases
    /// New capabilities need to be listed here as well as the sorted extension and have a symbolName entry.
    public static let allCases = modelAttributes + connections + power + allBiometrics + wirelessConnections + screenFeatures + hardware + sensors + software

    public var symbolName: String {
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
            return "network" // TODO: Add custom symbol
        case .thirtyPin:
            return "cable.connector.30.pin"
        case .lightning:
            return "cable.connector.lightning"
        case .usbC:
            return "cable.connector.usbc"
        case .thunderbolt:
            return "thunderbolt"
        case .wirelessCharging:
            return "wirelesscharging"
        case .nfc:
            return "wave.3.right.circle"
        case .cellular(_):
            return "antenna.radiowaves.left.and.right"
        case .screen(_):
            return "arrow.up.right.and.arrow.down.left.rectangle"
        case .notch:
            return "notch"
        case .roundedCorners:
            return "roundedcorners"
        case .dynamicIsland:
            return "dynamicisland"
        case .alwaysOnDisplay:
            return "sun.max.fill" // TODO: Create custom icon sun in square?  Lines in square?  Clock badge?
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
            //            return "ellipsis.rectangle.fill"
        case .magSafe2:
            return "magsafe2"
        case .magSafe3:
            return "magsafe3"
        case .crashDetection:
            return "car.side.rear.and.collision.and.car.side.front"
        case .actionButton:
            return "button.horizontal.top.press"
        case .cameraControl:
            return "camera.shutter.button"
        case .pencils(_):
            return "applepencil"
        case .force3DTouch:
            return "hand.tap"
        case .compass:
            return "location.north.circle" // use "location.north.line" for legacy support.  TODO: Backport so we can use "location.north.circle" (SF Symbols 3 required)
        case .lidar:
            return "lidar"
            //            return "circle.hexagongrid.fill"
        case .barometer:
            return "barometer"
        case .biometrics(let biometrics):
            return biometrics.symbolName
        case .cameras(_):
            return "camera"
        case .applePay:
            return "applepay"
            //            return "creditcard"
        case .appleIntelligence:
            return "apple.intelligence" // legacy can use "quote.bubble", requires SF Symbols 6 TODO: Create version for backport
        }
    }
    
    @available(iOS 13.0, tvOS 13, watchOS 6, *)
    public func test(device: DeviceType) -> Bool {
        return device.has(self)
    }
    
    /// caseName string.  Do not use this in a var description: String or it will cause an infinite loop.
    public var label: String { caseName }
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
        if let screen {
            sorted.append(.screen(screen))
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
    /// Wrapper for .screen capability.
    var screen: Screen? {
        get {
            for capability in self {
                if case .screen(let screen) = capability {
                    return screen
                }
            }
            return nil
        }
        set {
            // make sure we're not doubling up on values and if nil, we remove the existing value
            for capability in self {
                if case .screen = capability {
                    self.remove(capability)
                }
            }
            if let newValue {
                self.insert(.screen(newValue))
            }
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
public enum CPU: String, RawRepresentable, Hashable, CaseIterable, CaseNameConvertible, Sendable {
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
    case a10
    case a11 = "Apple A11 Bionic"
    case a12 = "Apple A12 Bionic" // also Apple TV
    case a12x
    case a12z
    case a13
    case a14 = "Apple A14 Bionic"
    case a16 = "Apple A16 Bionic"
    case a17pro
    case a18
    case a18pro
    //  TV
    case intel_pm1 = "Intel Pentium M (1GHz)"
    case a8
    case a10x
    case a15
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
}

// MARK: Biometrics
public enum Biometrics: Hashable, CaseNameConvertible, Sendable {
    case none
    case touchID
    case faceID
    case opticID
    public var symbolName: String {
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
}

// MARK: Camera
public enum Camera: Hashable, CaseIterable, CaseNameConvertible, Sendable { // TODO: Do we want to include the focal length in these?  Perhaps position, focal length, megapixels, field of view?
    case twoMP // original iPhone
    case threeMP // iPhone 3GS
    /// 8mp iPod touch 7th gen/iPhone 6
    case iSight
    case vga // iPad 2 front camera
    case standard
    case wide // ƒ/1.6 aperture 12 MP iPhone 12, ƒ/1.5 aperture iPhone 13 Pro, 26 mm, ƒ/1.5 aperture, iPhone 14 Plus
    case telephoto // ƒ/2.0 aperture 12 MP iPhone 12 Pro, ƒ/2.8 aperture iPhone 13 Pro
    case ultraWide // ƒ/2.4 aperture 12 MP iPhone 12, ƒ/1.8 aperture and 120° field of view iPhone 13 Pro, 13 mm, ƒ/2.4 aperture and 120° field of view iPhone 14 Plus
    /// front facing
    /// mac front facing 720p
    case faceTimeHD720p
    /// mac front facing 1080p
    case faceTimeHD1080p
    case trueDepth // ƒ/2.2 aperture 12 MP iPhone 12 Pro, ƒ/1.9 aperture iPhone 14 Plus
    /// vision pro
    case stereoscopic
    case persona
}
public extension Set<Camera> {
    static let `default`: Set<Camera> = [.wide,.ultraWide,.trueDepth]
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
public enum Cellular: Hashable, Comparable, CaseNameConvertible, Sendable {
    case none // TODO: Take this out?  Do we need it for anything?  This should only be available in iPhone and iPad (protocol CellularCapable)
    case gprs // 1G
    case edge // 2G
    case threeG // 3G
    case lte // 4G LTE
    case fiveG // 5G
}

// MARK: Pencil
public enum ApplePencil: Hashable, CaseIterable, CaseNameConvertible, Sendable {
    case firstGeneration
    case secondGeneration
    case usbC
    case pro
    public var symbolName: String {
        switch self {
        case .firstGeneration:
            "applepencil.gen1"
        case .secondGeneration:
            "applepencil.gen2"
        case .usbC:
            "applepencil"
        case .pro:
            //            if #available(iOS 18, *) {
            //                "applepencilpro"// TODO: iOS 18 will likely add a special symbol
            //            } else {
            "applepencil.gen2"
            //            }
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

// MARK: Material Color
public enum MaterialColor: String, CaseNameConvertible, Sendable {
    // standard colors
    case black = "#000000" // complete black for default color
    case white = "#FFFFFF" // complete white for default white plastic color
    case pink = "#b62c31" // iMac M1—M3
    case orange = "#e86740"
    case yellow = "#e0901a"
    case green = "#10505b"
    case blue = "#26476d"
    case purple = "#353b71"
    case silver = "#c7c8ca"
    case pinkDark = "#de5f7d" // iMac 2024 (goes along with pale versions)
    case orangeDark = "#e3704b"
    case yellowDark = "#edd142"
    case greenDark = "#3e935c"
    case blueDark = "#547eae"
    case purpleDark = "#827eb2"
    case solidSilver = "#e3e4e5" // macbookSilver
    case pinkLight = "#edb9af"
    case orangeLight = "#e9aa95"
    case yellowLight = "#e9ca95"
    case greenLight = "#a3beb4"
    case blueLight = "#a8bed2"
    case purpleLight = "#acaccb"
    case silverLight = "#d9dadb" // Mac Studio 2025
    case pinkPale = "#f3b5c3" // iMac M1—M3
    case orangePale = "#f5c1a7"
    case yellowPale = "#f5E4ae"
    case greenPale = "#a4c2ae"
    case bluePale = "#acbfd8"
    case purplePale = "#b8b2cf"
    case macSpacegray = "#7a7b80"
    case macbookSpacegray = "#7d7e80"
    case macbookGold = "#F9D4C2"
    case macbookSpaceblack = "#2e2c2e"
    case macbookairMidnight = "#2e3642"
    case macbookairStarlight = "#f0e4d3"
    case macbookairSkyblue = "#c8d8e0"

    // iMac
    static let iMac2Ports = [blueLight, greenLight, pinkLight, silverLight]
    static let iMac = [blueLight, greenLight, pinkLight, silverLight, yellowLight, orangeLight, purpleLight]
    static let iMac2024 = [blueDark, purpleDark, pinkDark, orangeDark, yellowDark, greenDark, solidSilver]
    
    // MacBook
    static let legacySilverMacs = [solidSilver]
    case macbookRoseGold = "#E1C3C8"
    
    static let macbookAir2025 = [macbookairSkyblue, solidSilver, macbookairStarlight, macbookairMidnight]
    
    // iPod Touch (5th generation)
    case iPodBlack = "#4d5663", iPodSilver = "#c9cbca", iPodPink = "#fb797e", iPodYellow = "#cace39", iPodBlue = "#26c4e5"
    static let iPodTouch5thGen = [iPodBlack, iPodSilver, iPodPink, iPodYellow, iPodBlue]
    
    // iPod Touch (6th generation)
    case iPodBlack6 = "#68686e", iPodGold6 = "#e3cfb9", iPodSilver6 = "#d0d3d0", iPodPink6 = "#fd4193", iPodBlue6 = "#357ed3"
    static let iPodTouch6thGen = [iPodBlack6, iPodGold6, iPodSilver6, iPodPink6, iPodBlue6]

    // iPod Touch (7th generation)
    case iPodProductRed = "#ed3135"
    static let iPodTouch7thGen = [iPodProductRed, iPodBlack6, iPodGold6, iPodSilver6, iPodPink6, iPodBlue6]

    // iPhone 3GS—5
    static let iPhoneBW = [black, white]
    // iPhone 5c
    case green5c = "#96e264", blue5c = "#41b1eb", yellow5c = "#feef6e", pink5c = "#ff6d6e", white5c = "#f0f0f2"
    static let iPhone5c = [green5c, blue5c, yellow5c, pink5c, white5c]
    // SE 1
    case silverSE = "#e4e4e2", spaceGraySE = "#262529", goldSE = "#fadcc2", roseGoldSE = "#ecc6c1"
    static let iPhoneSE = [silverSE, spaceGraySE, goldSE, roseGoldSE]
    // iPhone 6
    case silver6 = "#e2e3e4", spaceGray6 = "#b1b2b7", gold6 = "#e3ccb4"
    static let iPhone6 = [spaceGray6, silver6, gold6]
    // iPhone 6s
    static let iPhone6s = [silver6, spaceGray6, gold6, roseGoldSE]
    // iPhone 7
    case black7 = "#2e3034"
    static let iPhone7 = [silver6, black7, gold6, roseGoldSE]
    
    // iPhone 8
    case spaceGray8 = "#272729", gold8 = "#f7e8dd"
    static let iPhone8 = [silver6, spaceGray8, gold8]
    
    // iPhone X
    static let iPhoneX = [silverSE, spaceGraySE]
    
    // iPhone Xʀ
    case blueXʀ = "#48aee6", whiteXʀ = "#f3f3f3", yellowXʀ = "#f9d045", coralXʀ = "#ff6e5a", redXʀ = "#b41325"
    static let iPhoneXʀ = [blueXʀ, whiteXʀ, black7, yellowXʀ, coralXʀ, redXʀ]
    
    // iPhone Xs
    static let iPhoneXs = [silverSE, spaceGraySE, goldSE]
    
    // iPhone SE 2
    static let iPhoneSE2 = [spaceGraySE, whiteXʀ, redXʀ]
    
    // iPhone 11
    case purple11 = "#d1cdda", yellow11 = "#ffe681", green11 = "#aee1cd", black11 = "#1f2020", white11 = "#f9f6ef", red11 = "#ba0c2e"
    static let iPhone11 = [purple11, yellow11, green11, black11, white11, red11]
    
    // iPhone 11 Pro
    case midnightGreen = "#4e5851", silver11 = "#ebebe3", spaceGray11 = "#535150", gold11 = "#fad7bd"
    static let iPhone11Pro = [midnightGreen, silver11, spaceGray11, gold11]
    
    // iPhone 12
    case purple12 = "#b7afe6", blue12 = "#023b63", green12 = "#d8efd5", red12 = "#d82e2e", white12 = "#f6f2ef", black12 = "#25212b"
    static let iPhone12 = [purple12, blue12, green12, red12, white12, black12]
    
    // iPhone 12 Pro
    case pacificBlue = "#2d4e5c", gold12 = "#fcebd3", graphite12 = "#52514d", silver12 = "#e3e4df"
    static let iPhone12Pro = [pacificBlue, gold12, graphite12, silver12]
    
    // iPhone 13
    case green13 = "#394c38", pink13 = "#faddd7", blue13 = "#276787", midnight13 = "#232a31", starlight13 = "#faf6f2", productRed13 = "#bf0013"
    static let iPhone13 = [green13, pink13, blue13, midnight13, starlight13, productRed13]
    
    // iPhone 13 Pro
    case alpineGreen = "#576856", gold13 = "#fae7cf", graphite = "#54524f", sierraBlue = "#a7c1d9"
    static let iPhone13Pro = [alpineGreen, starlight13, gold13, graphite, sierraBlue]
    
    // iPhone SE 3
    static let iPhoneSE3 = [midnight13, starlight13, productRed13]

    // iPhone 14
    case blue14 = "#a0b4c7", purple14 = "#e6ddeb", yellow14 = "#f9e479", midnight14 = "#222930", productRed14 = "#fc0324"
    static let iPhone14 = [blue14, purple14, yellow14, midnight14, starlight13, productRed14]

    // iPhone 14 Pro
    case deepPurple14 = "#594f63", gold14 = "#f4e8ce", silver14 = "#f0f2f2", spaceBlack14 = "#403e3d"
    static let iPhone14Pro = [deepPurple14, gold14, silver14, spaceBlack14]

    // iPhone 15
    case pink15 = "#E3C8CA", yellow15 = "#E6E0C1", green15 = "#CAD4C5", blue15 = "#CED5D9", black15 = "#35393B"
    static let iPhone15 = [pink15, yellow15, green15, blue15, black15]

    // iPhone 15 Pro
    case naturalTitanium = "#837f7d", blueTitanium = "#2f4452", whiteTitanium = "#dddddd", blackTitanium = "#1b1b1b"
    static let iPhone15Pro = [naturalTitanium, blueTitanium, whiteTitanium, blackTitanium]

    // iPhone 16
    case ultramarine = "#9aadf6", teal = "#b0d4d2", pink16 = "#f2adda", white16 = "#fafafa", black16 = "#3c4042"
    static let iPhone16 = [ultramarine, teal, pink16, white16, black16]

    // iPhone 16 Pro
    case blackTitanium16 = "#3c3c3d", whiteTitanium16 = "#f2f1ed", naturalTitanium16 = "#c2bcb2", desertTitanium = "#bfa48f"
    static let iPhone16Pro = [blackTitanium16, whiteTitanium16, naturalTitanium16, desertTitanium]
    
    static let iPhone16e = [white16, black16]


    // iPad Air
    static let iPadAir = [spaceGray6, silver6]
    
    // iPad Air 4
    case roseGoldA4 = "#ecc5c1", skyBlueA4 = "#cee3f6", greenA4 = "#ccdfc9"
    
    // iPad Air 5
    case spaceGrayA5 = "#6b696e", starlightA5 = "#e5e0d8", pinkA5 = "#e8d2cf", purpleA5 = "#b9b8d1", blueA5 = "#88aebf"
    
    // iPad Mini 5
    case spaceGrayM5 = "#68696d", goldM5 = "#f6cdb9"
    static let iPadMini5 = [spaceGrayM5, silver6, goldM5]
    
    // iPad 9th gen
    case spaceGray9 = "#68696e"
    
    // iPad 10th gen & A16 2025
    case pink10 = "#de6274", blue10 = "#6480a3", yellow10 = "#f0d95b"
    static let iPad10 = [solidSilver, pink10, blue10, yellow10]
    
    // iPad Air 2024, iPad mini (A17 Pro)
    case starlightAir = "#e3dcd1", purpleAir = "#e3dee9", blueAir = "#d7e5e6"
    static let iPadAirM2 = [spaceGrayA5, blueAir, purpleAir, starlightAir] // also iPadAirM3, original order: [spaceGrayA5, starlightAir, purpleAir, blueAir]

    
    //  Watch Series 0
    case aluminumRoseGold = "#f6d9cd", aluminumSilver = "#e0e0e0", aluminumSpaceGray = "#727272", aluminumGold = "#f3e4d1", stainlessSpaceBlack = "#2e3a36", stainlessSilver = "#e6e6e7", yellowGold = "#dfc386", roseGold = "#e0b496"
    static let watch0 = [aluminumRoseGold, aluminumSilver, aluminumSpaceGray, aluminumGold, stainlessSpaceBlack, stainlessSilver, yellowGold, roseGold]

    //  Watch Series 1
    static let watch1 = [aluminumRoseGold, aluminumSilver, aluminumSpaceGray, aluminumGold]

    //  Watch Series 2
    case ceramicWhite = "#f9f9f7"
    static let watch2 = [aluminumSilver, aluminumSpaceGray, aluminumGold, aluminumRoseGold, stainlessSilver, stainlessGraphite, ceramicWhite]

    //  Watch Series 3
    case aluminumBrushGold = "#f4d4c6", ceramicGray = "#615f5a"
    static let watch3 = [aluminumSpaceGray, aluminumSilver, aluminumBrushGold, stainlessSilver, stainlessSpaceBlack, ceramicWhite, ceramicGray]

    //  Watch Series 4
    case stainlessGold = "#d4bda1"
    static let watch4 = [stainlessGold, aluminumSilver, aluminumSpaceGray, aluminumBrushGold, stainlessSilver, stainlessSpaceBlack]

    //  Watch Series 5
    case titanium = "#dedbd9", titaniumSpaceBlack = "#47433f"
    static let watch5 = [aluminumBrushGold, aluminumSilver, aluminumSpaceGray, stainlessSilver, stainlessSpaceBlack, stainlessGold, titanium, titaniumSpaceBlack, ceramicWhite]

    //  Watch SE
    static let watchSE = [aluminumBrushGold, aluminumSilver, aluminumSpaceGray]

    //  Watch Series 6
    case aluminumBlue = "#6e8eba", aluminumRed = "#c80e2d", stainlessGraphite = "#3e3a36"
    static let watch6 = [aluminumBlue, aluminumSilver, aluminumSpaceGray, aluminumBrushGold, aluminumRed, stainlessSilver, stainlessGraphite, stainlessGold, titanium, titaniumSpaceBlack]
    
    //  Watch Series 7
    case aluminumGreen = "#36382b", aluminumMidnight = "#1a2530", aluminumStarlight = "#ded6d1"
    static let watch7 = [aluminumGreen, aluminumMidnight, aluminumStarlight, aluminumBlue, aluminumRed, stainlessSilver, stainlessGraphite, stainlessGold, titanium, titaniumSpaceBlack]
    
    //  Watch Series 8
    static let watch8 = [aluminumMidnight, aluminumStarlight, aluminumSilver, aluminumRed, stainlessSilver, stainlessGraphite, stainlessGold]

    //  Watch SE 2
    static let watchSE2 = [aluminumMidnight, aluminumStarlight, aluminumSilver]
    
    //  Watch Ultra
    case titaniumNatural = "#ccc4bc"
    static let watchUltra = [titaniumNatural]
    
    //  Watch Series 9
    case aluminumPink = "#fadcde" // new comparison swatch uses consistent aluminumRed color not productRedW9 = "#d61139"
    static let watch9 = [aluminumMidnight, aluminumStarlight, aluminumSilver, aluminumPink, aluminumRed, stainlessSilver, stainlessGraphite, stainlessGold]

    //  Watch Series 10
    case aluminumJetBlack = "#010203", titaniumSlate = "#47423d", titaniumGold = "#f4dec8"
    static let watch10 = [aluminumJetBlack, aluminumRoseGold, aluminumSilver, titaniumSlate, titaniumGold, titaniumNatural]

    //  Watch Ultra 2
    case titaniumBlackU2 = "#0f0e0e"
    static let watchUltra2 = [titaniumBlackU2, titaniumNatural]
    
    
    // HomePod
    case whiteHome = "#f1f1f1", yellowHome = "#ffc953", orangeHome = "#e56645", blueHome = "#25485e", spacegrayHome = "#36373a", midnightHome = "#313236" // midnight is best guess
    // added July 15, 2024: https://www.apple.com/newsroom/2024/07/apple-introduces-homepod-mini-in-midnight/
    case midnightHomeMini = "#222428"
    static let homePod = [whiteHome, midnightHome]
    static let homePodMini = [whiteHome, yellowHome, orangeHome, blueHome, spacegrayHome, midnightHomeMini]
}
public extension [MaterialColor] {
    static let `default` = [MaterialColor.black]
    
    static let iMac = MaterialColor.iMac
    static let iMac2Ports = MaterialColor.iMac2Ports
    static let iMac2024 = MaterialColor.iMac2024
    static let legacySilverMacs = MaterialColor.legacySilverMacs
    static let macbookAir2025 = MaterialColor.macbookAir2025
    static let iPodTouch5thGen = MaterialColor.iPodTouch5thGen
    static let iPodTouch6thGen = MaterialColor.iPodTouch6thGen
    static let iPodTouch7thGen = MaterialColor.iPodTouch7thGen
    static let iPhoneBW = MaterialColor.iPhoneBW
    static let iPhone5c = MaterialColor.iPhone5c
    static let iPhoneSE = MaterialColor.iPhoneSE
    static let iPhone6 = MaterialColor.iPhone6
    static let iPhone6s = MaterialColor.iPhone6s
    static let iPhone7 = MaterialColor.iPhone7
    static let iPhone8 = MaterialColor.iPhone8
    static let iPhoneX = MaterialColor.iPhoneX
    static let iPhoneXʀ = MaterialColor.iPhoneXʀ
    static let iPhoneXs = MaterialColor.iPhoneXs
    static let iPhoneSE2 = MaterialColor.iPhoneSE2
    static let iPhone11 = MaterialColor.iPhone11
    static let iPhone11Pro = MaterialColor.iPhone11Pro
    static let iPhone12 = MaterialColor.iPhone12
    static let iPhone12Pro = MaterialColor.iPhone12Pro
    static let iPhone13 = MaterialColor.iPhone13
    static let iPhone13Pro = MaterialColor.iPhone13Pro
    static let iPhoneSE3 = MaterialColor.iPhoneSE3
    static let iPhone14 = MaterialColor.iPhone14
    static let iPhone14Pro = MaterialColor.iPhone14Pro
    static let iPhone15 = MaterialColor.iPhone15
    static let iPhone15Pro = MaterialColor.iPhone15Pro
    static let iPhone16 = MaterialColor.iPhone16
    static let iPhone16Pro = MaterialColor.iPhone16Pro
    static let iPhone16e = MaterialColor.iPhone16e
    static let iPadAir = MaterialColor.iPadAir
    static let iPad10 = MaterialColor.iPad10
    static let iPadAirM2 = MaterialColor.iPadAirM2
    static let iPadMini5 = MaterialColor.iPadMini5
    static let watch0 = MaterialColor.watch0
    static let watch1 = MaterialColor.watch1
    static let watch2 = MaterialColor.watch2
    static let watch3 = MaterialColor.watch3
    static let watch4 = MaterialColor.watch4
    static let watch5 = MaterialColor.watch5
    static let watchSE = MaterialColor.watchSE
    static let watch6 = MaterialColor.watch6
    static let watch7 = MaterialColor.watch7
    static let watch8 = MaterialColor.watch8
    static let watchSE2 = MaterialColor.watchSE2
    static let watchUltra = MaterialColor.watchUltra
    static let watch9 = MaterialColor.watch9
    static let watch10 = MaterialColor.watch10
    static let watchUltra2 = MaterialColor.watchUltra2
    static let homePod = MaterialColor.homePod
    static let homePodMini = MaterialColor.homePodMini
    
    // TODO: Figure out how to use introspection or definition to get string
    static let colorSets = [
        iMac: "iMac",
        iMac2Ports: "iMac2Ports",
        iMac2024: "iMac2024",
        legacySilverMacs: "legacySilverMacs",
        macbookAir2025: "macbookAir2025",
        iPodTouch5thGen: "iPodTouch5thGen",
        iPodTouch6thGen: "iPodTouch6thGen",
        iPodTouch7thGen: "iPodTouch7thGen",
        iPhoneBW: "iPhoneBW",
        iPhone5c: "iPhone5c",
        iPhoneSE: "iPhoneSE",
        iPhoneSE2: "iPhoneSE2",
        iPhone6: "iPhone6",
        iPhone6s: "iPhone6s",
        iPhone7: "iPhone7",
        iPhone8: "iPhone8",
        iPhoneX: "iPhoneX",
        iPhoneXʀ: "iPhoneXʀ",
        iPhoneXs: "iPhoneXs",
        iPhone11: "iPhone11",
        iPhone11Pro: "iPhone11Pro",
        iPhone12: "iPhone12",
        iPhone12Pro: "iPhone12Pro",
        iPhone13: "iPhone13",
        iPhone13Pro: "iPhone13Pro",
        iPhoneSE3: "iPhoneSE3",
        iPhone14: "iPhone14",
        iPhone14Pro: "iPhone14Pro",
        iPhone15: "iPhone15",
        iPhone15Pro: "iPhone15Pro",
        iPhone16: "iPhone16",
        iPhone16Pro: "iPhone16Pro",
        iPhone16e: "iPhone16e",
        iPadAir: "iPadAir",
        iPad10: "iPad10",
        iPadAirM2: "iPadAirM2",
        iPadMini5: "iPadMini5",
        watch0: "watch0",
        watch1: "watch1",
        watch2: "watch2",
        watch3: "watch3",
        watch4: "watch4",
        watch5: "watch5",
        watchSE: "watchSE",
        watch6: "watch6",
        watch7: "watch7",
        watch8: "watch8",
        watchSE2: "watchSE2",
        watchUltra: "watchUltra",
        watch9: "watch9",
        watch10: "watch10",
        watchUltra2: "watchUltra2",
        homePod: "homePod",
        homePodMini: "homePodMini",
    ]
}
