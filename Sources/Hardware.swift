// String constants for SF Symbols
public extension String {
    static let symbolUnknownEnvironment = "questionmark.circle"
    static let symbolSimulator = "squareshape.squareshape.dotted"
    static let symbolPlayground = "swift"
    static let symbolPreview = "curlybraces.square"
    static let symbolRealDevice = "square.fill"
    static let symbolDesignedForiPad = "ipad.badge.play"
    static let symbolUnknownDevice = "questionmark.square.dashed"
}

// MARK: Capabilities
public typealias Capabilities = Set<Capability>
public enum Capability: Hashable {
    // model attributes
    case pro, air, mini, plus, max
    case macForm(Mac.Form)
    case watchSize(AppleWatch.WatchSize)
    // connections
    case headphoneJack, lightning, usbC, wirelessCharging, nfc // iPhone 7+
    // Should we add: wifi, bluetooth, bluetoothLE, 30pin, AC Power?, ethernet, HDMI, SDCard?
    case cellular(Cellular)
    // display
    case screen(Screen)
    case notch // newer macs and original faceID phones.
    case roundedCorners
    case dynamicIsland
    // features
    case battery
    case ringerSwitch // mini 2, 3, iPad up to 10"? iPhone up to iPhone 15 Pro
    case applePay // iPhone 6+
    case magSafe // circular qi phone
    // notebook magSafe connectors
    case magSafe1, magSafe2, magSafe3
    case crashDetection // iPhone 14+
    case actionButton // iPhone 15 Pro+, Apple Watch Ultra
    case pencils(Set<ApplePencil>)
    // sensors
    case force3DTouch, lidar, barometer
    case biometrics(Biometrics)
    case cameras(Set<Camera>)
    // TODO: Add static presets for things like .i2024Models which sets defaults on all and then we can add to it.union([
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
        case .lightning:
            return "cable.connector"
        case .usbC:
            return "bolt" // technically symbol for thunderbolt but missing this symbol :(
        case .wirelessCharging:
            return "bolt.brakesignal" // should be more of a wave
        case .nfc:
            return "wave.3.right.circle"
        case .cellular(_):
            return "antenna.radiowaves.left.and.right"
        case .screen(_):
            return "arrow.up.right.and.arrow.down.left.rectangle"
        case .notch:
            return "iphone.gen2"
        case .roundedCorners:
            return "rectangle.inset.filled.and.person.filled"
        case .dynamicIsland:
            return "iphone.gen3"
        case .battery:
            return "battery.100percent"
        case .ringerSwitch:
            return "bell.slash"
        case .applePay:
            return "creditcard"
        case .magSafe:
            return "magsafe.batterypack.fill"
        case .magSafe1:
            return "ellipsis.rectangle.fill"
        case .magSafe2:
            return "ellipsis.rectangle.fill"
        case .magSafe3:
            return "ellipsis.rectangle.fill"
        case .crashDetection:
            return "car.side.rear.and.collision.and.car.side.front"
        case .actionButton:
            return "button.horizontal.top.press"
        case .pencils(_):
            return "applepencil"
        case .force3DTouch:
            return "hand.tap"
        case .lidar:
            return "person.and.background.dotted"
        case .barometer:
            return "barometer"
        case .biometrics(let biometrics):
            return biometrics.symbolName
        case .cameras(_):
            return "camera"
        }
    }
}
// device specific have functions for getting a wrapped capability out.
public extension Capabilities {
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
        for item in [Capability.headphoneJack, .lightning, .usbC, .wirelessCharging, .nfc] {
            if self.contains(item) {
                sorted.append(item)
            }
        }
        if let cellular {
            sorted.append(.cellular(cellular))
        }
        // display
        if let screen {
            sorted.append(.screen(screen))
        }
        for item in [Capability.notch, .roundedCorners, .dynamicIsland, .battery, .ringerSwitch, .applePay, .magSafe, .magSafe1, .magSafe2, .magSafe3, .crashDetection, .actionButton] {
            if self.contains(item) {
                sorted.append(item)
            }
        }
        // features
        if pencils.count > 0 {
            sorted.append(.pencils(pencils))
        }
        // sensors
        for item in [Capability.force3DTouch, .lidar, .barometer] {
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
public enum CPU: Hashable, CaseIterable {
    // Only 2013+ really need to be included since Swift won't run on devices prior to this.
    case unknown
    // Mac
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
    // iPod
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
public enum Biometrics: Hashable {
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
            return "opticid"
        }
    }
}

// MARK: Camera
public enum Camera: Hashable, CaseIterable { // TODO: Do we want to include the focal length in these?  Perhaps position, focal length, megapixels, field of view?
    /// 8mp iPod touch 7th gen/iPhone 6
    case iSight
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
public enum Cellular: Hashable, Comparable {
    case none // TODO: Take this out?  Do we need it for anything?  This should only be available in iPhone and iPad (protocol CellularCapable)
    case gprs // 1G
    case edge // 2G
    case threeG // 3G
    case lte // 4G LTE
    case fiveG // 5G
}

// MARK: Pencil
public enum ApplePencil: Hashable, CaseIterable {
    case firstGeneration
    case secondGeneration
    case usbC
    public var symbolName: String {
        switch self {
        case .firstGeneration:
            "applepencil.gen1"
        case .secondGeneration:
            "applepencil.gen2"
        case .usbC:
            "applepencil"
        }
    }
}
extension Set<ApplePencil> {
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
public enum MaterialColor: String {
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
    static var iMac = [blueLight, greenLight, pinkLight, silverLight, yellowLight, orangeLight, purpleLight]
    
    // MacBook
    case macbookRoseGold = "#E1C3C8"
    
    // SE 1
    case silverSE = "#e4e4e2", spaceGraySE = "#262529", goldSE = "#fadcc2", roseGoldSE = "#ecc6c1"
    static var se = [silverSE, spaceGraySE, goldSE, roseGoldSE]
    // iPhone 6
    case silver6 = "#e2e3e4", spaceGray6 = "#b1b2b7", gold6 = "#e3ccb4"
    static var iPhone6 = [silver6, spaceGray6, gold6]
    // iPhone 6s
    static var iPhone6s = [silver6, spaceGray6, gold6, roseGoldSE]
    // iPhone 7
    case black7 = "#2e3034"
    static var iPhone7 = [silver6, black7, gold6, roseGoldSE]

    // iPhone 13
    case green13 = "#394c38", pink13 = "#faddd7", blue13 = "#276787", midnight13 = "#232a31", starlight13 = "#faf6f2", productRed13 = "#bf0013"
    static var iPhone13 = [green13, pink13, blue13, midnight13, starlight13, productRed13]
    
    // iPhone 13 Pro
    case alpineGreen = "#576856", gold13 = "#fae7cf", graphite = "#54524f", sierraBlue = "#a7c1d9"
    static var iPhone13Pro = [alpineGreen, starlight13, gold13, graphite, sierraBlue]
    
    // iPhone SE 3
    static var iPhoneSE3 = [midnight13, starlight13, productRed13]
    // iPhone 14
    case blue14 = "#a0b4c7", purple14 = "#e6ddeb", yellow14 = "#f9e479", midnight14 = "#222930", productRed14 = "#fc0324"
    static var iPhone14 = [blue14, purple14, yellow14, midnight14, starlight13, productRed14]
    // iPhone 14 Pro
    case deepPurple14 = "#594f63", gold14 = "#f4e8ce", silver14 = "#f0f2f2", spaceBlack14 = "#403e3d"
    static var iPhone14Pro = [deepPurple14, gold14, silver14, spaceBlack14]
    // iPhone 15
    case pink15 = "#E3C8CA", yellow15 = "#E6E0C1", green15 = "#CAD4C5", blue15 = "#CED5D9", black15 = "#35393B"
    static var iPhone15 = [pink15, yellow15, green15, blue15, black15]
    // iPhone 15 Pro
    case titanium = "#837f7d", blueTitanium = "#2f4452", whiteTitanium = "#dddddd", blackTitanium = "#1b1b1b"
    static var iPhone15Pro = [titanium, blueTitanium, whiteTitanium, blackTitanium]

    //  Watch SE
    case midnightW = "#1a2530", starlightW = "#ded6d1", silverW = "#e0e0e0"
    static var watchSE2 = [midnightW, starlightW, silverW]
    //  Watch Series 9
    case pinkW9 = "#fadcde", productRedW9 = "#d61139"
    case graphitePVD = "#3e3a36", silverSS = "#e6e6e7", goldPVD = "#d4bda1"
    static var watch9 = [midnightW, starlightW, silverW, pinkW9, productRedW9, graphitePVD, silverSS, goldPVD]
    //  Watch Ultra 2
    case naturalW = "#ccc4bc"
    static var watchUltra2 = [naturalW]
    
    // HomePod
    case whiteHome = "#f1f1f1", yellowHome = "#ffc953", orangeHome = "#e56645", blueHome = "#25485e", spacegrayHome = "#36373a", midnightHome = "#313236" // midnight is best guess
    static var homePod = [whiteHome, midnightHome]
    static var homePodMini = [whiteHome, yellowHome, orangeHome, blueHome, spacegrayHome]
}
public extension [MaterialColor] {
    static let `default` = [MaterialColor.black]
    
    static var iMac = MaterialColor.iMac
    static var se = MaterialColor.se
    static var iPhone6 = MaterialColor.iPhone6
    static var iPhone7 = MaterialColor.iPhone7
    static var iPhone13 = MaterialColor.iPhone13
    static var iPhone13Pro = MaterialColor.iPhone13Pro
    static var iPhoneSE3 = MaterialColor.iPhoneSE3
    static var iPhone14 = MaterialColor.iPhone14
    static var iPhone14Pro = MaterialColor.iPhone14Pro
    static var iPhone15 = MaterialColor.iPhone15
    static var iPhone15Pro = MaterialColor.iPhone15Pro
    static var watchSE2 = MaterialColor.watchSE2
    static var watch9 = MaterialColor.watch9
    static var watchUltra2 = MaterialColor.watchUltra2
    static var homePod = MaterialColor.homePod
    static var homePodMini = MaterialColor.homePodMini
}
