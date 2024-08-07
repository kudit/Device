import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

public protocol CaseNameConvertible {
    var caseName: String { get }
}
public extension CaseNameConvertible {
    // exposes the case name for an enum without having to have a string rawValue
    var caseName: String {
        // for enums
        (Mirror(reflecting: self).children.first?.label ?? String(describing: self))
    }
}
public protocol DeviceAttributeExpressible: Hashable, SymbolRepresentable, CaseNameConvertible {
    var symbolName: String { get }
    var label: String { get } // description doesn't work since it can cause infinite recursion
#if canImport(SwiftUI)
    @available(iOS 13.0, tvOS 13, watchOS 6, *)
    var color: Color { get }
#endif
    @available(iOS 13, tvOS 13, watchOS 6, *)
    @MainActor
    func test(device: any CurrentDevice) -> Bool
}

// MARK: Capabilities
public typealias Capabilities = Set<Capability>
public enum Capability: CaseIterable, DeviceAttributeExpressible, Sendable {
    // model attributes
    case pro, air, mini, plus, max
    case macForm(Mac.Form)
    case watchSize(AppleWatch.WatchSize)
    // connections
    case headphoneJack, thirtyPin, lightning, usbC, thunderbolt
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
    // Should we add: wifi, bluetooth, bluetoothLE, 30pin, AC Power?, ethernet, HDMI, SDCard?
    // display
    case screen(Screen)
    case force3DTouch
    case roundedCorners
    case notch // newer macs and original faceID phones.
    case dynamicIsland
    // features
    case ringerSwitch // mini 2, 3, iPad up to 10"? iPhone up to iPhone 15 Pro
    case actionButton // iPhone 15 Pro+, Apple Watch Ultra
    case pencils(Set<ApplePencil>)
    // sensors
    case lidar, barometer, crashDetection // iPhone 14+
    
    /// Lists all non-associated value cases
    /// New capabilities need to be listed here as well as the sorted extension and have a symbolName entry.
    public static let allCases = [Capability.pro, .air, .mini, .plus, .max, .headphoneJack, .thirtyPin, .lightning, .usbC, .thunderbolt, .battery, .wirelessCharging, .magSafe, .magSafe1, .magSafe2, .magSafe3, .esim, .dualesim, .applePay, .nfc, .force3DTouch, .roundedCorners, .notch, .dynamicIsland, .ringerSwitch, .actionButton, .lidar, .barometer, .crashDetection]
    
    static let screenFeatures = [Capability.force3DTouch, .roundedCorners, .notch, .dynamicIsland]
    
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
        case .battery:
            return "battery.100percent"
        case .ringerSwitch:
            return "bell.slash"
        case .esim:
            return "esim.fill"
        case .dualesim:
            return "simcard.2"
        case .applePay:
            return "applepay"
            //            return "creditcard"
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
        case .pencils(_):
            return "applepencil"
        case .force3DTouch:
            return "hand.tap"
        case .lidar:
            return "lidar"
            //            return "circle.hexagongrid.fill"
        case .barometer:
            return "barometer"
        case .biometrics(let biometrics):
            return biometrics.symbolName
        case .cameras(_):
            return "camera"
        }
    }
    
    @available(iOS 13.0, tvOS 13, watchOS 6, *)
    public func test(device: any CurrentDevice) -> Bool {
        return device.has(self)
    }
    
    /// caseName string.  Do not use this in a var description: String or it will cause an infinite loop.
    public var label: String { caseName }
}
// device specific have functions for getting a wrapped capability out.
public extension Capabilities {
    static let screenFeatures = Set(Capability.screenFeatures)

    /// Order them based off of the order in the Capability definition for consistency
    var sorted: [Capability] {
        var sorted = [Capability]()
        // model attributes
        for item in [Capability.pro, .air, .mini, .plus, .max] {
            if self.contains(item) {
                sorted.append(item)
            }
        }
        if let macForm {
            sorted.append(.macForm(macForm))
        }
        if let watchSize {
            sorted.append(.watchSize(watchSize))
        }
        // connections
        for item in [Capability.headphoneJack, .thirtyPin, .lightning, .usbC, .thunderbolt, .battery, .wirelessCharging, .magSafe, .magSafe1, .magSafe2, .magSafe3] {
            if self.contains(item) {
                sorted.append(item)
            }
        }
        if let biometrics {
            sorted.append(.biometrics(biometrics))
        }
        if cameras.count > 0 {
            sorted.append(.cameras(cameras))
        }
        if let cellular {
            sorted.append(.cellular(cellular))
        }
        for item in [Capability.esim, .dualesim, .applePay, .nfc] {
            if self.contains(item) {
                sorted.append(item)
            }
        }
        // display
        if let screen {
            sorted.append(.screen(screen))
        }
        for item in [Capability.force3DTouch, .roundedCorners, .notch, .dynamicIsland, .ringerSwitch, .actionButton] {
            if self.contains(item) {
                sorted.append(item)
            }
        }
        // features
        if pencils.count > 0 {
            sorted.append(.pencils(pencils))
        }
        // sensors
        for item in [Capability.lidar, .barometer, .crashDetection] {
            if self.contains(item) {
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
public enum CPU: Hashable, CaseIterable, CaseNameConvertible, Sendable {
    // Only 2013+ really need to be included since Swift won't run on devices prior to this.
    case unknown
    // Mac/iPad
    case i3
    case xeonE5
    case i5
    case i7
    case intel // for models that have both i5 and i7 variants
    case m1
    case m1pro
    case m1max
    case m1ultra
    case m2 // also  Vision
    case m2pro
    case m2max
    case m2ultra
    case m3
    case m3pro
    case m3max
    case m4
    // iPod/iPhone
    case s5L8900 // Samsung S5L8900 for original iPhone, iPhone 3G, original iPod touch
    case sAPL0298C05 // iPhone 3GS
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
    case a11
    case a12x
    case a12z
    case a13
    case a14
    case a16
    case a17pro
    //  TV
    case a8
    case a10x
    case a12
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
            " Pencil (USB‑C)"
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
    case pink = "#b62c31"
    case orange = "#e86740"
    case yellow = "#e0901a"
    case green = "#10505b"
    case blue = "#26476d"
    case purple = "#353b71"
    case silver = "#c7c8ca"
    case pinkLight = "#edb9af"
    case orangeLight = "#e9aa95"
    case yellowLight = "#e9ca95"
    case greenLight = "#a3beb4"
    case blueLight = "#a8bed2"
    case purpleLight = "#acaccb"
    case silverLight = "#d9dadb"
    case macSpacegray = "#7a7b80"
    case macbookSpacegray = "#7d7e80"
    case macbookSilver = "#e3e4e5"
    case macbookGold = "#F9D4C2"
    case macbookSpaceblack = "#2e2c2e"
    case macbookairMidnight = "#2e3642"
    case macbookairStarlight = "#f0e4d3"
    
    // iMac
    static let iMac = [blueLight, greenLight, pinkLight, silverLight, yellowLight, orangeLight, purpleLight]
    
    // MacBook
    case macbookRoseGold = "#E1C3C8"
    
    // SE 1
    case silverSE = "#e4e4e2", spaceGraySE = "#262529", goldSE = "#fadcc2", roseGoldSE = "#ecc6c1"
    static let se = [silverSE, spaceGraySE, goldSE, roseGoldSE]
    // iPhone 6
    case silver6 = "#e2e3e4", spaceGray6 = "#b1b2b7", gold6 = "#e3ccb4"
    static let iPhone6 = [spaceGray6, silver6, gold6]
    // iPhone 6s
    static let iPhone6s = [silver6, spaceGray6, gold6, roseGoldSE]
    // iPhone 7
    case black7 = "#2e3034"
    static let iPhone7 = [silver6, black7, gold6, roseGoldSE]
        
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
    
    // iPad 10th gen
    case pink10 = "#de6274", blue10 = "#6480a3", yellow10 = "#f0d95b"
    
    // iPad Air 2024
    case starlightAir = "#e3dcd1", purpleAir = "#e3dee9", blueAir = "#d7e5e6"
    static let iPadAirM2 = [spaceGrayA5, starlightAir, purpleAir, blueAir]
    
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
    case titanium = "#837f7d", blueTitanium = "#2f4452", whiteTitanium = "#dddddd", blackTitanium = "#1b1b1b"
    static let iPhone15Pro = [titanium, blueTitanium, whiteTitanium, blackTitanium]

    //  Watch SE
    case midnightW = "#1a2530", starlightW = "#ded6d1", silverW = "#e0e0e0"
    static let watchSE2 = [midnightW, starlightW, silverW]
    //  Watch Series 9
    case pinkW9 = "#fadcde", productRedW9 = "#d61139"
    case graphitePVD = "#3e3a36", silverSS = "#e6e6e7", goldPVD = "#d4bda1"
    static let watch9 = [midnightW, starlightW, silverW, pinkW9, productRedW9, graphitePVD, silverSS, goldPVD]
    //  Watch Ultra 2
    case naturalW = "#ccc4bc"
    static let watchUltra2 = [naturalW]
    
    // HomePod
    case whiteHome = "#f1f1f1", yellowHome = "#ffc953", orangeHome = "#e56645", blueHome = "#25485e", spacegrayHome = "#36373a", midnightHome = "#313236" // midnight is best guess
    static let homePod = [whiteHome, midnightHome]
    static let homePodMini = [whiteHome, yellowHome, orangeHome, blueHome, spacegrayHome]
}
public extension [MaterialColor] {
    static let `default` = [MaterialColor.black]
    
    static let iMac = MaterialColor.iMac
    static let se = MaterialColor.se
    static let iPhone6 = MaterialColor.iPhone6
    static let iPhone7 = MaterialColor.iPhone7
    static let iPhone13 = MaterialColor.iPhone13
    static let iPhone13Pro = MaterialColor.iPhone13Pro
    static let iPhoneSE3 = MaterialColor.iPhoneSE3
    static let iPhone14 = MaterialColor.iPhone14
    static let iPhone14Pro = MaterialColor.iPhone14Pro
    static let iPhone15 = MaterialColor.iPhone15
    static let iPhone15Pro = MaterialColor.iPhone15Pro
    static let iPadAir = MaterialColor.iPadAir
    static let iPadAirM2 = MaterialColor.iPadAirM2
    static let iPadMini5 = MaterialColor.iPadMini5
    static let watchSE2 = MaterialColor.watchSE2
    static let watch9 = MaterialColor.watch9
    static let watchUltra2 = MaterialColor.watchUltra2
    static let homePod = MaterialColor.homePod
    static let homePodMini = MaterialColor.homePodMini
    
    static let colorSets = [
        iMac: "iMac",
        se: "se",
        iPhone6: "iPhone6",
        iPhone7: "iPhone7",
        iPhone13: "iPhone13",
        iPhone13Pro: "iPhone13Pro",
        iPhoneSE3: "iPhoneSE3",
        iPhone14: "iPhone14",
        iPhone14Pro: "iPhone14Pro",
        iPhone15: "iPhone15",
        iPhone15Pro: "iPhone15Pro",
        iPadAir: "iPadAir",
        iPadAirM2: "iPadAirM2",
        iPadMini5: "iPadMini5",
        watchSE2: "watchSE2",
        watch9: "watch9",
        watchUltra2: "watchUltra2",
        homePod: "homePod",
        homePodMini: "homePodMini",
    ]
}
