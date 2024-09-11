//
//  Migration.swift
//  DeviceTest
//
//  Created by Ben Ku on 3/25/24.
//
import Device
import Compatibility

extension String {
    var isVowel: Bool {
        let vowels = ["a","e","i","o","u"]
        return vowels.contains(self.lowercased())
    }
}
// TODO: Use this to help with code generation more globally?  Add to KuditFrameworks/Compatibility?
protocol Definable {
    var definition: String { get }
    var deviceKitDefinition: String { get }
}
extension Collection where Element: Definable {
    var definition: String {
        "[\(self.map { $0.definition }.joined(separator: ", "))]"
    }
}
// TODO:?must manually add collection conformance...
// for enums
extension CaseNameConvertible {
    var definition: String {
        "." + self.caseName
    }
}
extension Definable {
    var deviceKitDefinition: String { definition }
}

extension Bool: Definable {
    var definition: String {
        self ? "true" : "false"
    }
    var deviceKitDefinition: String {
        self ? "True" : "False"
    }
}
// for Int, Double values
extension Double: Definable {
    var definition: String {
        "\(self.description)".replacingOccurrences(of: ".0", with: "")
    }
}
extension Int: Definable {
    var definition: String {
        "\(self.description)"
    }
}
extension String: Definable {
    var definition: String {
        return "\"\(self)\""
    }
}
extension Optional where Wrapped: Definable {
    var definition: String {
        if let unwrapped = self {
            return unwrapped.definition
        }
        return "nil"
    }
}

extension Device.Idiom: Definable {}
extension Mac.Form: Definable {}
extension CPU: Definable {
    var deviceKitDefinition: String {
        var definition = definition
        if definition.contains("a10") {
            definition += "Fusion"
        } else if definition.contains("a17") {
            definition = definition.replacingOccurrences(of: "pro", with: "Pro")
        } else if definition.contains("a1") {
            definition += "Bionic"
        }
        return definition.replacingOccurrences(of: "x", with: "X").replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "z", with: "Z").replacingOccurrences(of: "p", with: "P")
    }
}
extension Biometrics: Definable {}
extension Camera: Definable {}
extension Cellular: Definable {}
extension ApplePencil: Definable {}
extension MaterialColor: Definable {}
extension AppleWatch.WatchSize: Definable {}
extension Screen: Definable {
    static let all = [
        "tv":Screen.tv,
        "p720":.p720,
        "p1080":.p1080,
        "vision":.vision,
        "i35":.i35,
        "i4":.i4,
        "i47":.i47,
        "i54":.i54,
        "i55":.i55,
        "i58":.i58,
        "i65":.i65,
        "i61x828":.i61x828,
        "i61x1125":.i61x1125,
        "i61x1170":.i61x1170,
        "i61x1179":.i61x1179,
        "i67x1284":.i67x1284,
        "i67x1290":.i67x1290,
        "i97x768":.i97x768,
        "i97x1536":.i97x1536,
        "i105":.i105,
        "i102":.i102,
        "i109":.i109,
        "i79x768":.i79x768,
        "i79x1536":.i79x1536,
        "i83":.i83,
        "i129":.i129,
        "i11":.i11,
        "wUnknown":.wUnknown,
        "w38":.w38,
        "w40":.w40,
        "w41":.w41,
        "w42":.w42,
        "w44":.w44,
        "w45":.w45,
        "w49":.w49]
    
    var definition: String {
        // check for one of the defined variables
        for (string,screen) in Screen.all {
            if screen == self {
                return ".\(string)"
            }
        }
        return "Screen(diagonal: \(diagonal.definition), resolution: (\(resolution.width),\(resolution.height)), ppi: \(ppi.definition))"
    }
}
extension Screen.Size: Definable {
    static let widescreen = Screen.Size(width: 9, height: 16)
    var definition: String {
        return "(\(width), \(height))"
    }
    var deviceKitDefinition: String {
        if Int(100 * Double(width) / Double(height)) == 46 {
            return "(9, 19.5)"
        }
        return "(\(ratio.width), \(ratio.height))"
    }
}
extension Capability: Definable {
    var definition: String {
        switch self {
        case .macForm(let macForm):
            return ".macForm(\(macForm.definition))"
        case .watchSize(let watchSize):
            return ".watchSize(\(watchSize.definition))"
        case .cellular(let cellular):
            return ".cellular(\(cellular.definition))"
        case .screen(let screen):
            return ".screen(\(screen.definition))"
        case .pencils(let pencils):
            return ".pencils(\(pencils.sorted.definition))"
        case .biometrics(let biometrics):
            return ".biometrics(\(biometrics.definition))"
        case .cameras(let cameras):
            return ".cameras(\(cameras.sorted.definition))"
        default:
            return "." + caseName
            // why can't we remove duplicate code by doing the following?
//            return (self as Definable).definition
        }
    }
}
extension [String:Any]: Definable {
    var definition: String {
        var strings = [String]()
        for (key,value) in self {
            if let v = value as? Definable {
                strings.append("\"\(key)\": \(v.definition)")
            } else {
                debug("UNKNOWN NON-DEFINABLE TYPE: \(key): \(value)", level: .ERROR)
            }
        }
        return "[\(strings.definition)]"
    }
}

/*
/// Code for facilitating migrating device definitions to new formats.
extension Device {
    mutating func upgrade() {
        if isPro {
            self.capabilities.insert(.pro)
        }
        if let idiomatic = device.idiom.type.init(device: device) as? iPad {
            if idiomatic.isMini {
                self.capabilities.insert(.mini)
            }
            self.capabilities.pencils.formUnion(idiomatic.supportedPencils)
        }
        if let idiomatic = device.idiom.type.init(device: device) as? HomePod {
            if idiomatic.isMini {
                self.capabilities.insert(.mini)
            }
        }
        if let idiomatic = device.idiom.type.init(device: device) as? AppleWatch {
            self.capabilities.insert(.watchSize(idiomatic.watchSize))
        }
        if let idiomatic = device.idiom.type.init(device: device) as? iPhone {
            if idiomatic.isPlusFormFactor {
                if isPro || name.lowercased().contains("max") {
                    self.capabilities.insert(.max)
                } else {
                    self.capabilities.insert(.plus)
                }
            }
        }
        if hasBattery {
            self.capabilities.insert(.battery)
        }
        if cellular == .none && idiom == .pad { // Make sure iPads have cellular generation attached.
            cellular = .threeG
        }
        if cellular != .none {
            self.capabilities.insert(.cellular(cellular))
        }
        if supportsWirelessCharging {
            self.capabilities.insert(.wirelessCharging)
        }
        if biometrics != .none {
            self.capabilities.insert(.biometrics(biometrics))
        }
        if hasForce3dTouchSupport {
            self.capabilities.insert(.force3DTouch)
        }
        // how do we convert cameras to capabilities?
        #warning("Remove this once we've converted everything")
        if cameras > 0 && self.capabilities.cameras.count == 0 { // don't add if we've already manually specified cameras
            var list = Set<Camera>()
            let defaultCameras = [Camera.iSight, .faceTimeHD720p, .wide, .telephoto, .ultraWide]
            for i in 0..<cameras {
                if i >= defaultCameras.count {
                    list.insert(.iSight)
                } else {
                    list.insert(defaultCameras[i]) // should be obvious that it needs replacing?
                }
            }
            list.formUnion(self.capabilities.cameras)
            self.capabilities.cameras = list
        }
        if hasLidarSensor {
            self.capabilities.insert(.lidar)
        }
        if hasUSBCConnectivity {
            self.capabilities.insert(.usbC)
        }
        
        if let screen {
            self.capabilities.insert(.screen(screen))
            if self.capabilities.biometrics == .faceID {
                if name.contains("iPhone 14 Pro") || name.contains("iPhone 15") {
                    self.capabilities.insert(.dynamicIsland)
                } else {
                    self.capabilities.insert(.notch)
                }
                self.capabilities.insert(.roundedCorners)
            }
        }
    }
}
extension DeviceType {
    func upgraded() -> any DeviceType {
        var copy = self.device // if Self is a value type, should return copy
        copy.upgrade()
        return copy
    }
}
 */

/// assign only if the rhs is larger than the original value (if less, don't do assignment)
infix operator =>
func =>(lhs: inout Int, rhs: Int) {
    if rhs > lhs {
        lhs = rhs
    }
}

// MARK: Device string definitions
extension DeviceType {
    var definition: String {
        let indentSpace = "            "
        let idiomish = ""
        // TODO: Fix this based on our needs.  Commented out for now due to internal protection level.  Find a public way to expose what we need rather than using internal types.  Perhaps have an extension that loops through and pulls description or whatever we need.
        /*
        if idiom.type == Device.self {
            idiomish = "idiom: \(idiom.definition),\n\(indentSpace)"
        }

        let control = idiom.type.init(identifier: .base) // create a base model (not the default model!)
         */
        var capabilities = capabilities
        
        var macForm = ""
        if idiom == .mac, let form = capabilities.macForm { // second should never fail if .mac idiom
            macForm = "form: \(form.definition),\n\(indentSpace)"
            // remove default form capabilities like battery
            capabilities.subtract(form.capabilities)
        }
//        capabilities.subtract(control.capabilities) // do after so .macMini form isn't removed which is the default
        // strip out default capabilities
        // add in ringer switch to all non-iPhone 15 pro devices
        if idiom == .phone && !identifiers.first!.contains("iPhone16") {
            capabilities.insert(.ringerSwitch)
        }
        // remove .macForm from capabilities
        capabilities.macForm = nil // remove so not appears in capabilities list
        var models = "models: \(models.definition),\n\(indentSpace)"
        if self.models.count == 0 { // don't do this if we want to always have models.  Remove once we've gone through and added all models.
            models = ""
        }
        
        var colors = "colors: \(colors.definition),\n\(indentSpace)"
        if self.colors.count == 0 || self.colors == .default || idiom == .vision { // don't do this if we want to always have colors.  Remove once we've gone through and added all colors.
            colors = ""
        }
        if let key = [MaterialColor].colorSets[self.colors] {
            colors = "colors: .\(key),\n\(indentSpace)"
        }

        var cameras = ",\n\(indentSpace)cameras: \(capabilities.cameras.sorted.definition)"
        if capabilities.cameras.count == 0 || capabilities.cameras == .default || idiom == .vision {
            cameras = ""
        }
        capabilities.cameras = [] // make sure doesn't appear also in capabilities

        var cellular = ""
        if let c = capabilities.cellular {
            cellular = ",\n\(indentSpace)cellular: \(c.definition)"
        }
        capabilities.cellular = nil // make sure doesn't appear also in capabilities

        var screen = ""
        if let s = capabilities.screen, idiom != .tv, idiom != .homePod, idiom != .watch {
            screen = ",\n\(indentSpace)screen: \(s.definition)"
        }
        capabilities.screen = nil // make sure doesn't appear also in capabilities

        var pencils = ",\n\(indentSpace)pencils: \(capabilities.pencils.sorted.definition)"
        if capabilities.pencils.count == 0 {
            pencils = ""
        }
        capabilities.pencils = [] // make sure doesn't appear also in capabilities

        var watchSize = ""
        if idiom == .watch, let size = capabilities.watchSize {
            capabilities.screen = nil // should be in the watch size
            capabilities.watchSize = nil // remove so not appears in capabilities list
            watchSize = ",\n\(indentSpace)size: \(size.definition)"
        }
        var overrides = "capabilities: \(capabilities.sorted.definition),\n\(indentSpace)"
        if capabilities.count == 0 { // don't do this if we want to always have capabilities
            overrides = ""
        }
        // TODO: Formerly String(describing: idiom.type) but that is internal.  Have a way of exposing type name?  Perhaps have a idiom.typeName extension??
        return """
                \(String(describing: idiom))(
                    \(idiomish)officialName: \(officialName.definition),
                    identifiers: \(identifiers.definition),
                    supportId: \(supportId.definition),
                    \(macForm)image: \(image.definition),
                    \(overrides)\(models)\(colors)cpu: \(cpu.definition)\(cameras)\(cellular)\(screen)\(pencils)\(watchSize)),
        """
    }
    var deviceKitDefinition: String {
        // assumes run on upgraded device
        // create case name
        var caseName = officialName.safeDescription
        var officialName = officialName
        var isAppleWatch = false
        if caseName.contains("Apple Watch") {
            if let pos = caseName.lastIndex(of: " "), !caseName.contains("Ultra") {
                let mm = caseName[pos..<caseName.endIndex]
                caseName.replaceSubrange(pos..<caseName.index(pos, offsetBy: 1), with: "_")
                officialName = officialName.replacingOccurrences(of: mm, with: "")
            }
            caseName = caseName.replacingOccurrences(of: "Apple Watch", with: "apple Watch")
            caseName = caseName.replacingOccurrences(of: "(1st generation)", with: "Series0")
            let end = officialName.firstIndex(of: ")") ?? officialName.endIndex
            officialName = String(officialName[officialName.startIndex..<end])
            if officialName.contains("generation") {
                officialName += ")"
            }
            isAppleWatch = true
        }
        if officialName.contains("Apple TV") {
            officialName = officialName.replacingOccurrences(of: " (1st generation)", with: "")
        }
        caseName = caseName.replacingOccurrences(of: " ", with: "")
        caseName = caseName.replacingOccurrences(of: "Xs", with: "XS")
        caseName = caseName.replacingOccurrences(of: "mini", with: "Mini")
        caseName = caseName.replacingOccurrences(of: "Podtouch", with: "PodTouch")
        caseName = caseName.replacingOccurrences(of: "HomePod", with: "homePod")
        caseName = caseName.replacingOccurrences(of: "AppleTV", with: "appleTV")
        caseName = caseName.replacingOccurrences(of: "1stgeneration)", with: "")
        caseName = caseName.replacingOccurrences(of: "AppleTV", with: "appleTV")
        caseName = caseName.replacingOccurrences(of: ".5", with: "")
        caseName = caseName.replacingOccurrences(of: ".7", with: "")
        caseName = caseName.replacingOccurrences(of: ".9", with: "")
        caseName = caseName.replacingOccurrences(of: "-inch", with: "Inch")
        caseName = caseName.replacingOccurrences(of: "(", with: "")
        caseName = caseName.replacingOccurrences(of: ")", with: "")
        caseName = caseName.replacingOccurrences(of: "ndgeneration", with: "")
        caseName = caseName.replacingOccurrences(of: "rdgeneration", with: "")
        caseName = caseName.replacingOccurrences(of: "thgeneration", with: "")
        
        var safeOfficialName = safeOfficialName.replacingOccurrences(of: "Xs", with: "XS")
        
        var support = "Device is a\(String(officialName[officialName.startIndex]).isVowel ? "n" : "") [\(officialName)](https://support.apple.com/kb/\(supportId))"
        support = support.replacingOccurrences(of: " (9.7-inch)", with: " 9.7-inch")
        support = support.replacingOccurrences(of: " (10.5-inch)", with: " 10.5-inch")
        support = support.replacingOccurrences(of: " (11-inch)", with: " 11-inch")
        support = support.replacingOccurrences(of: " (12.9-inch)", with: " 12.9-inch")

        officialName = officialName.replacingOccurrences(of: " 11-inch", with: " (11-inch)")
        officialName = officialName.replacingOccurrences(of: " 12.9-inch", with: " (12.9-inch)")

        safeOfficialName = safeOfficialName.replacingOccurrences(of: " 11-inch", with: " (11-inch)")
        safeOfficialName = safeOfficialName.replacingOccurrences(of: " 12.9-inch", with: " (12.9-inch)")

//        #warning("REMOVE WHEN Updating DeviceKit")
//        description = description.replacingOccurrences(of: "Ultra 2", with: "Ultra2")
//        safeDescription = safeDescription.replacingOccurrences(of: "Ultra 2", with: "Ultra2")

        var image = "\(image ?? "NO_IMAGE")"
        if caseName == "homePod" {
            image = "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP773/homepod_space_gray_large_2x.jpg" // use different version
        }
        let identifiers = identifiers.definition
        if identifiers.contains("iPad6") || identifiers.contains("iPad7") {
            support = support.replacingOccurrences(of: "12.9-inch", with: "12-inch")
        }
        let screen = capabilities.screen // use capabilities version, not local variable version
        var diagonal = "\(screen?.diagonal?.deviceKitDefinition ?? "0")"
        if diagonal == "11" {
            diagonal = "11.0"
        }
        if diagonal == "2" {
            diagonal = "2.0"
        }
        var ppi = screen?.ppi ?? -1
        if officialName.contains("HomePod") {
            diagonal = "-1"
            ppi = -1
        }
        var ratio = "\(screen?.resolution.ratio.deviceKitDefinition ?? "()")"
        if officialName.contains("Apple TV") {
            ratio = ratio.replacingOccurrences(of: "16, 9", with: "")
        }
        if [8, 13, 14].contains(Int(self.identifierSortKey)) {
            ratio = ratio.replacingOccurrences(of: "3, 4", with: "512, 683")
        }
//        #warning("Remove this when upgrading DeviceKit")
//        if identifiers.contains("iPad8") || identifiers.contains("iPad13") || identifiers.contains("iPad14") {
//            ratio = ratio.replacingOccurrences(of: "(3, 4)", with: "(512, 683)")
//        }

        // sizes should be the whole space including the quotes and comma.  Default should include one space.
        var nameSize = caseName.count + 4
        var supportSize = support.count + 4
        var imageSize = image.count + 4
        var identifiersSize = identifiers.count + 2
        var diagonalSize = diagonal.count + 2
        var ratioSize = ratio.count + 2

        switch idiom {
        case .mac:
            // not in DeviceKit so skip
            return ""
        case .pod:
            nameSize => 18
            supportSize => 82
            imageSize => 114
            identifiersSize => 46
            diagonalSize => 6
            ratioSize => 12
        case .phone:
            nameSize => 18
            supportSize => 82
            imageSize => 125
            identifiersSize => 46
            diagonalSize => 6
            ratioSize => 12
        case .tv:
            nameSize => 18
            supportSize => 105
            imageSize => 117
            identifiersSize => 17
            diagonalSize => 3
            ratioSize => 4
        case .pad:
            nameSize => 18
            supportSize => 90
            imageSize => 115
            identifiersSize => 52
            diagonalSize => 6
            ratioSize => 13
        case .homePod:
            nameSize => 18
            supportSize => 90
            imageSize => 106
            identifiersSize => 46
            diagonalSize => 6
            ratioSize => 12
        default:
            break
        }

        let nameSpace = String(repeating: " ", count: nameSize-caseName.count-3)
        let supportSpace = String(repeating: " ", count: supportSize-support.count-3)
        let imageSpace = String(repeating: " ", count: imageSize-image.count-3) // comma & quotes not included
        let identifiersSpace = String(repeating: " ", count: identifiersSize-identifiers.count-1) // comma not included
        let diagonalSpace = String(repeating: " ", count: diagonalSize-diagonal.count-1) // comma not included
        let ratioSpace = String(repeating: " ", count: ratioSize-ratio.count-1) // comma not included

        let isPlusFormFactor = self.is(.plus) || self.is(.max)
        let isPadMiniFormFactor = self.is(.mini) && idiom == .pad // homepod mini or iPhone mini does not count
        let isXSeries = capabilities.biometrics == .faceID && idiom != .pad // faceID is proxy for "isXSeries"
        let hasSensorHousing = isXSeries
        let pencils = capabilities.pencils
        // this is a bad way of expressing pencil support.
        var applePencilSupport = 0
        if pencils.contains(.firstGeneration) {
            applePencilSupport = 1
        } else if pencils.contains(.secondGeneration) {
            applePencilSupport = 2
        }
        
        // convert sets of cameras to numbers
        let cameras = capabilities.cameras
        let wide = cameras.contains(.wide)
        let telephoto = cameras.contains(.telephoto)
        let ultraWide = cameras.contains(.ultraWide)
        var camerasNum = 0
        if wide && telephoto && ultraWide {
            camerasNum = 123
        } else if telephoto && ultraWide {
            camerasNum = 23
        } else if wide && ultraWide {
            camerasNum = 13
        } else if wide && telephoto {
            camerasNum = 12
        } else if ultraWide {
            camerasNum = 3
        } else if telephoto {
            camerasNum = 2
        } else if wide {
            camerasNum = 1
        } else if cameras.count > 0 {
            camerasNum = 1
        }
        let cellular = capabilities.cellular

        var returnText = """
            Device("\(caseName)",\(nameSpace)"\(support)",\(supportSpace)"\(image)",\(imageSpace)\(identifiers),\(identifiersSpace)\(diagonal),\(diagonalSpace)\(ratio),\(ratioSpace)"\(officialName)", "\(safeOfficialName)", \(ppi), \(isPlusFormFactor.deviceKitDefinition), \(isPadMiniFormFactor.deviceKitDefinition), \(capabilities.contains(.pro).deviceKitDefinition), \(isXSeries.deviceKitDefinition), \((capabilities.biometrics == .touchID).deviceKitDefinition), \((capabilities.biometrics == .faceID).deviceKitDefinition), \(hasSensorHousing.deviceKitDefinition), \(has(.wirelessCharging).deviceKitDefinition), \(has(.roundedCorners).deviceKitDefinition), \(has(.dynamicIsland).deviceKitDefinition), \(applePencilSupport), \(has(.force3DTouch).deviceKitDefinition), \(camerasNum), \(has(.lidar).deviceKitDefinition), "\(cpu.deviceKitDefinition)", \(has(.usbC).deviceKitDefinition), \((cellular == .fiveG).deviceKitDefinition)),
"""
        if isAppleWatch {
            returnText = returnText.replacingOccurrences(of: "(4, 5)", with: "(4,5)")
            returnText = returnText.replacingOccurrences(of: "(4, 5)", with: "(4,5)")
            returnText = returnText.replacingOccurrences(of: "1.65,", with: "1.6,")
            returnText = "\n" + returnText.replacingOccurrences(of: "Device(\"", with: "Device(\n            \"")
            returnText = returnText.replacingOccurrences(of: "\", \"D", with: "\",\n            \"D")
            returnText = returnText.replacingOccurrences(of: ")\",\(supportSpace)\"", with: ")\",\n            \"")
            returnText = returnText.replacingOccurrences(of: "g\", [", with: "g\",\n            [")
        }
        return returnText
    }
}


// MARK: - Migration of JSON format used here: https://github.com/voyager-software/MacLookup/blob/master/Sources/MacLookup/Resources/all-macs.json
struct MacLookup: Codable {
    var models: [String] // identifiers
    var kind: String // form
    var colors: [String] // Convert to MaterialColors
    var officialName: String
    var variant: String // included in name so unused
    var parts: [String] // part numbers MGTF3xx/a
    var asDevice: Mac {
        let form = Mac.Form.create(from: kind)
        // convert colors to MaterialColors
        var materials = [MaterialColor]()
        for color in colors {
            materials.append(MaterialColor.from(string: color, form: form))
        }
        // convert name to cpu
        var cpu = CPU.from(nameString: officialName)
        var capabilities = form.capabilities
        if officialName.contains("Pro") {
            capabilities.insert(.pro)
        }
        if officialName.contains("Air") {
            capabilities.insert(.air)
        }
        if officialName == "iMac Pro" {
            cpu = .xeonE5
        }
        // assume all the ones we're importing are new enough that they have USB-C
        capabilities.insert(.usbC)
        capabilities.subtract(form.capabilities) // will automatically be added by form so no need to double add.
        return Mac(
            officialName: officialName,
            identifiers: models.distilled,
            supportId: "UNKNOWN_PLEASE_HELP_REPLACE",
            launchOSVersion: "0.0.0",
            unsupportedOSVersion: "0.0.0",
            form: form,
            image: nil,
            capabilities: capabilities,
            models: parts.distilled,
            colors: materials,
            cpu: cpu
        )
    }
}
extension MaterialColor {
    static func from(string: String, form: Mac.Form) -> MaterialColor {
        let string = string.lowercased()
        if string.contains("space") && string.contains("gray") {
            if form.hasBattery {
                return .macbookSpacegray
            } else {
                return .macSpacegray
            }
        }
        let map = [
            "silverlight": MaterialColor.silverLight,
            "pinklight": .pinkLight,
            "bluelight": .blueLight,
            "greenlight": .greenLight,
            "rose gold": .macbookRoseGold,
            "gold": .macbookGold,
            "silver": .macbookSilver,
            "starlight": .macbookairStarlight,
            "midnight": .macbookairMidnight,
        ]
        if let mapped = map[string] {
            return mapped
        }
        debug("Unknown color string: \"\(string)\"", level: .WARNING)
        return .macbookSilver
    }
}
extension CPU {
    static func from(nameString: String) -> CPU {
        let nameString = nameString.lowercased()
        for processor in CPU.allCases {
            let str = String(describing: processor) // convert to string for lookup of m1, etc.
            if nameString.contains(str.lowercased()) {
                return processor
            }
        }
//        print("Unable to process string: \(nameString)")
        return .intel
    }
}
extension [String] {
    var distilled: [String] {
        var items = [String]()
        for item in self {
//            items += item.split(separator: "; ").map { String($0) } // using the collection method rather than the string method which isn't available in iOS < 16
            items += item.components(separatedBy: "; ")
        }
        return items
    }
}
extension Mac.Form {
    /// Name (ex: "MacBook Pro", "iMac", "Mac mini")
    static func create(from kindString: String) -> Mac.Form {
        if kindString.hasPrefix("Mac Pro") {
            return .macProGen3
        }
        if kindString.hasPrefix("iMac") {
            return .iMac
        }
        if kindString.hasPrefix("MacBook") {
            return .macBook
        }
        if kindString.hasPrefix("Mac mini") {
            return .macMini
        }
        if kindString.hasPrefix("Mac Studio") {
            return .macStudio
        }
        return .macBook
    }
    var hasBattery: Bool {
        return self == .macBook
    }
    static func capabilities(from kindString: String) -> Capabilities {
        var capabilities = Capabilities()
        if kindString.contains("Pro") {
            capabilities.insert(.pro)
        }
        return capabilities
    }
}

extension DeviceType {
    var identifierSortKey: Double {
        Double(identifiers.first!.replacingOccurrences(of: "iPad", with: "").replacingOccurrences(of: ",", with: ".")) ?? -1
    }
    var deviceKitSortKey: Int {
        Device.deviceKitOrder.firstIndex(of: identifiers.first!) ?? -1
    }
}

public struct Migration {
    static func printAllDevices(printProperty: KeyPath<DeviceType,String>, sortFunc: ((DeviceType, DeviceType) -> Bool)? = nil) {
        var lastIdiom = ""
        var devices = Device.all
        if let sortFunc {
            devices.sort(by: sortFunc)
        }
        for device in devices {
//            device.upgrade()
            let idiom = device.idiom.label
            if idiom != lastIdiom {
                print("        ]\n\n\(idiom)s = [")
                lastIdiom = idiom
            }
            // TODO: See if we have another way since idiomatic is internal.
//            let str = device.idiomatic[keyPath: printProperty]
//            if str != "" {// skip blank macs.
//                print(str)
//            }
        }
    }
    static func exportDeviceKitDefinitions() {
        print("""
        %{
        class Device:
          def __init__(self, caseName, comment, imageURL, identifiers, diagonal, screenRatio, description, safeDescription, ppi, isPlusFormFactor, isPadMiniFormFactor, isPro, isXSeries, hasTouchID, hasFaceID, hasSensorHousing, supportsWirelessCharging, hasRoundedDisplayCorners, hasDynamicIsland, applePencilSupport, hasForce3dTouchSupport, cameras, hasLidarSensor, cpu, hasUSBCConnectivity, has5gSupport):
            self.caseName = caseName
            self.comment = comment
            self.imageURL = imageURL
            self.identifiers = identifiers
            self.diagonal = diagonal
            self.screenRatio = screenRatio
            self.description = description
            self.safeDescription = safeDescription
            self.ppi = ppi
            self.isPlusFormFactor = isPlusFormFactor
            self.isPadMiniFormFactor = isPadMiniFormFactor
            self.isPro = isPro
            self.isXSeries = isXSeries
            self.hasTouchID = hasTouchID
            self.hasFaceID = hasFaceID
            self.hasSensorHousing = hasSensorHousing
            self.supportsWirelessCharging = supportsWirelessCharging
            self.hasRoundedDisplayCorners = hasRoundedDisplayCorners
            self.hasDynamicIsland = hasDynamicIsland
            self.applePencilSupport = applePencilSupport
            self.hasForce3dTouchSupport = hasForce3dTouchSupport
            self.cameras = cameras
            self.hasLidarSensor = hasLidarSensor
            self.cpu = cpu
            self.hasUSBCConnectivity = hasUSBCConnectivity
            self.has5gSupport = has5gSupport

        # iOS
        ignore = [
        """)
        printAllDevices(printProperty: \.deviceKitDefinition, sortFunc: { $0.deviceKitSortKey < $1.deviceKitSortKey })
    }
    static func exportDefinitions() {
        printAllDevices(printProperty: \.definition)
    }
    public static func migrate() {
//        #warning("Remove once tested.  This is for button linkage.")
//        exportDeviceKitDefinitions()
//        exportDefinitions()
        checkIdentifiers()
//        convertMacs()
//        createOrder()
    }
    /// Extract the current order for saving and preserving the DeviceKit order (which isn't in identifier order which is preferable)
//    static func createOrder() {
//        for var device in iPad.all.sorted(by: { $0.identifierSortKey < $1.identifierSortKey
//        }) {
//            if !device.has(.usbC) {
//                // make sure to add in lighting connector where missing
//                device.device.capabilities.insert(.lightning)
//                // TODO: Re-enable above by doing a new device with the additional capability?
//            }
//            print("\(device.definition)")
//        }
//    }
    static func convertMacs() {
        let macsRaw = """
[
    {
        "models" : [
            "iMac21,2"
        ],
        "kind" : "iMac",
        "colors" : [
            "silverLight",
            "pinkLight",
            "blueLight",
            "greenLight"
        ],
        "name" : "iMac (24-inch, M1, 2021)",
        "variant" : "24-inch, M1, 2021",
        "parts" : [
            "MGTF3xx/a",
            "MJV83xx/a",
            "MJV93xx/a",
            "MJVA3xx/a"
        ]
    }
]
"""
        let json = macsRaw.data(using: .utf8)!
        let decoder = JSONDecoder()
        let macs = (try? decoder.decode([MacLookup].self, from: json)) ?? []
        //print(String(describing: macs))
        for mac in macs {
            print(mac.asDevice.definition)
        }
        
    }
    // compare with this: https://gist.github.com/adamawolf/3048717
    static func checkIdentifiers() {
        let types = """
i386 : iPhone Simulator
x86_64 : iPhone Simulator
arm64 : iPhone Simulator
iPhone1,1 : iPhone
iPhone1,2 : iPhone 3G
iPhone2,1 : iPhone 3GS
iPhone3,1 : iPhone 4
iPhone3,2 : iPhone 4 GSM Rev A
iPhone3,3 : iPhone 4 CDMA
iPhone4,1 : iPhone 4S
iPhone5,1 : iPhone 5 (GSM)
iPhone5,2 : iPhone 5 (GSM+CDMA)
iPhone5,3 : iPhone 5C (GSM)
iPhone5,4 : iPhone 5C (Global)
iPhone6,1 : iPhone 5S (GSM)
iPhone6,2 : iPhone 5S (Global)
iPhone7,1 : iPhone 6 Plus
iPhone7,2 : iPhone 6
iPhone8,1 : iPhone 6s
iPhone8,2 : iPhone 6s Plus
iPhone8,4 : iPhone SE (GSM)
iPhone9,1 : iPhone 7
iPhone9,2 : iPhone 7 Plus
iPhone9,3 : iPhone 7
iPhone9,4 : iPhone 7 Plus
iPhone10,1 : iPhone 8
iPhone10,2 : iPhone 8 Plus
iPhone10,3 : iPhone X Global
iPhone10,4 : iPhone 8
iPhone10,5 : iPhone 8 Plus
iPhone10,6 : iPhone X GSM
iPhone11,2 : iPhone XS
iPhone11,4 : iPhone XS Max
iPhone11,6 : iPhone XS Max Global
iPhone11,8 : iPhone XR
iPhone12,1 : iPhone 11
iPhone12,3 : iPhone 11 Pro
iPhone12,5 : iPhone 11 Pro Max
iPhone12,8 : iPhone SE 2nd Gen
iPhone13,1 : iPhone 12 Mini
iPhone13,2 : iPhone 12
iPhone13,3 : iPhone 12 Pro
iPhone13,4 : iPhone 12 Pro Max
iPhone14,2 : iPhone 13 Pro
iPhone14,3 : iPhone 13 Pro Max
iPhone14,4 : iPhone 13 Mini
iPhone14,5 : iPhone 13
iPhone14,6 : iPhone SE 3rd Gen
iPhone14,7 : iPhone 14
iPhone14,8 : iPhone 14 Plus
iPhone15,2 : iPhone 14 Pro
iPhone15,3 : iPhone 14 Pro Max
iPhone15,4 : iPhone 15
iPhone15,5 : iPhone 15 Plus
iPhone16,1 : iPhone 15 Pro
iPhone16,2 : iPhone 15 Pro Max
iPhone17,1 : iPhone 16 Pro
iPhone17,2 : iPhone 16 Pro Max
iPhone17,3 : iPhone 16
iPhone17,4 : iPhone 16 Plus

iPod1,1 : 1st Gen iPod
iPod2,1 : 2nd Gen iPod
iPod3,1 : 3rd Gen iPod
iPod4,1 : 4th Gen iPod
iPod5,1 : 5th Gen iPod
iPod7,1 : 6th Gen iPod
iPod9,1 : 7th Gen iPod

iPad1,1 : iPad
iPad1,2 : iPad 3G
iPad2,1 : 2nd Gen iPad
iPad2,2 : 2nd Gen iPad GSM
iPad2,3 : 2nd Gen iPad CDMA
iPad2,4 : 2nd Gen iPad New Revision
iPad3,1 : 3rd Gen iPad
iPad3,2 : 3rd Gen iPad CDMA
iPad3,3 : 3rd Gen iPad GSM
iPad2,5 : iPad mini
iPad2,6 : iPad mini GSM+LTE
iPad2,7 : iPad mini CDMA+LTE
iPad3,4 : 4th Gen iPad
iPad3,5 : 4th Gen iPad GSM+LTE
iPad3,6 : 4th Gen iPad CDMA+LTE
iPad4,1 : iPad Air (WiFi)
iPad4,2 : iPad Air (GSM+CDMA)
iPad4,3 : 1st Gen iPad Air (China)
iPad4,4 : iPad mini Retina (WiFi)
iPad4,5 : iPad mini Retina (GSM+CDMA)
iPad4,6 : iPad mini Retina (China)
iPad4,7 : iPad mini 3 (WiFi)
iPad4,8 : iPad mini 3 (GSM+CDMA)
iPad4,9 : iPad Mini 3 (China)
iPad5,1 : iPad mini 4 (WiFi)
iPad5,2 : 4th Gen iPad mini (WiFi+Cellular)
iPad5,3 : iPad Air 2 (WiFi)
iPad5,4 : iPad Air 2 (Cellular)
iPad6,3 : iPad Pro (9.7 inch, WiFi)
iPad6,4 : iPad Pro (9.7 inch, WiFi+LTE)
iPad6,7 : iPad Pro (12.9 inch, WiFi)
iPad6,8 : iPad Pro (12.9 inch, WiFi+LTE)
iPad6,11 : iPad (2017)
iPad6,12 : iPad (2017)
iPad7,1 : iPad Pro 2nd Gen (WiFi)
iPad7,2 : iPad Pro 2nd Gen (WiFi+Cellular)
iPad7,3 : iPad Pro 10.5-inch 2nd Gen
iPad7,4 : iPad Pro 10.5-inch 2nd Gen
iPad7,5 : iPad 6th Gen (WiFi)
iPad7,6 : iPad 6th Gen (WiFi+Cellular)
iPad7,11 : iPad 7th Gen 10.2-inch (WiFi)
iPad7,12 : iPad 7th Gen 10.2-inch (WiFi+Cellular)
iPad8,1 : iPad Pro 11 inch 3rd Gen (WiFi)
iPad8,2 : iPad Pro 11 inch 3rd Gen (1TB, WiFi)
iPad8,3 : iPad Pro 11 inch 3rd Gen (WiFi+Cellular)
iPad8,4 : iPad Pro 11 inch 3rd Gen (1TB, WiFi+Cellular)
iPad8,5 : iPad Pro 12.9 inch 3rd Gen (WiFi)
iPad8,6 : iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)
iPad8,7 : iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)
iPad8,8 : iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)
iPad8,9 : iPad Pro 11 inch 4th Gen (WiFi)
iPad8,10 : iPad Pro 11 inch 4th Gen (WiFi+Cellular)
iPad8,11 : iPad Pro 12.9 inch 4th Gen (WiFi)
iPad8,12 : iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)
iPad11,1 : iPad mini 5th Gen (WiFi)
iPad11,2 : iPad mini 5th Gen
iPad11,3 : iPad Air 3rd Gen (WiFi)
iPad11,4 : iPad Air 3rd Gen
iPad11,6 : iPad 8th Gen (WiFi)
iPad11,7 : iPad 8th Gen (WiFi+Cellular)
iPad12,1 : iPad 9th Gen (WiFi)
iPad12,2 : iPad 9th Gen (WiFi+Cellular)
iPad14,1 : iPad mini 6th Gen (WiFi)
iPad14,2 : iPad mini 6th Gen (WiFi+Cellular)
iPad13,1 : iPad Air 4th Gen (WiFi)
iPad13,2 : iPad Air 4th Gen (WiFi+Cellular)
iPad13,4 : iPad Pro 11 inch 5th Gen
iPad13,5 : iPad Pro 11 inch 5th Gen
iPad13,6 : iPad Pro 11 inch 5th Gen
iPad13,7 : iPad Pro 11 inch 5th Gen
iPad13,8 : iPad Pro 12.9 inch 5th Gen
iPad13,9 : iPad Pro 12.9 inch 5th Gen
iPad13,10 : iPad Pro 12.9 inch 5th Gen
iPad13,11 : iPad Pro 12.9 inch 5th Gen
iPad13,16 : iPad Air 5th Gen (WiFi)
iPad13,17 : iPad Air 5th Gen (WiFi+Cellular)
iPad13,18 : iPad 10th Gen
iPad13,19 : iPad 10th Gen
iPad14,3 : iPad Pro 11 inch 4th Gen
iPad14,4 : iPad Pro 11 inch 4th Gen
iPad14,5 : iPad Pro 12.9 inch 6th Gen
iPad14,6 : iPad Pro 12.9 inch 6th Gen
iPad14,8 : iPad Air 6th Gen
iPad14,9 : iPad Air 6th Gen
iPad14,10 : iPad Air 7th Gen
iPad14,11 : iPad Air 7th Gen
iPad16,3 : iPad Pro 11 inch 5th Gen
iPad16,4 : iPad Pro 11 inch 5th Gen
iPad16,5 : iPad Pro 12.9 inch 7th Gen
iPad16,6 : iPad Pro 12.9 inch 7th Gen

Watch1,1 : Apple Watch 38mm case
Watch1,2 : Apple Watch 42mm case
Watch2,6 : Apple Watch Series 1 38mm case
Watch2,7 : Apple Watch Series 1 42mm case
Watch2,3 : Apple Watch Series 2 38mm case
Watch2,4 : Apple Watch Series 2 42mm case
Watch3,1 : Apple Watch Series 3 38mm case (GPS+Cellular)
Watch3,2 : Apple Watch Series 3 42mm case (GPS+Cellular)
Watch3,3 : Apple Watch Series 3 38mm case (GPS)
Watch3,4 : Apple Watch Series 3 42mm case (GPS)
Watch4,1 : Apple Watch Series 4 40mm case (GPS)
Watch4,2 : Apple Watch Series 4 44mm case (GPS)
Watch4,3 : Apple Watch Series 4 40mm case (GPS+Cellular)
Watch4,4 : Apple Watch Series 4 44mm case (GPS+Cellular)
Watch5,1 : Apple Watch Series 5 40mm case (GPS)
Watch5,2 : Apple Watch Series 5 44mm case (GPS)
Watch5,3 : Apple Watch Series 5 40mm case (GPS+Cellular)
Watch5,4 : Apple Watch Series 5 44mm case (GPS+Cellular)
Watch5,9 : Apple Watch SE 40mm case (GPS)
Watch5,10 : Apple Watch SE 44mm case (GPS)
Watch5,11 : Apple Watch SE 40mm case (GPS+Cellular)
Watch5,12 : Apple Watch SE 44mm case (GPS+Cellular)
Watch6,1 : Apple Watch Series 6 40mm case (GPS)
Watch6,2 : Apple Watch Series 6 44mm case (GPS)
Watch6,3 : Apple Watch Series 6 40mm case (GPS+Cellular)
Watch6,4 : Apple Watch Series 6 44mm case (GPS+Cellular)
Watch6,6 : Apple Watch Series 7 41mm case (GPS)
Watch6,7 : Apple Watch Series 7 45mm case (GPS)
Watch6,8 : Apple Watch Series 7 41mm case (GPS+Cellular)
Watch6,9 : Apple Watch Series 7 45mm case (GPS+Cellular)
Watch6,10 : Apple Watch SE 40mm case (GPS)
Watch6,11 : Apple Watch SE 44mm case (GPS)
Watch6,12 : Apple Watch SE 40mm case (GPS+Cellular)
Watch6,13 : Apple Watch SE 44mm case (GPS+Cellular)
Watch6,14 : Apple Watch Series 8 41mm case (GPS)
Watch6,15 : Apple Watch Series 8 45mm case (GPS)
Watch6,16 : Apple Watch Series 8 41mm case (GPS+Cellular)
Watch6,17 : Apple Watch Series 8 45mm case (GPS+Cellular)
Watch6,18 : Apple Watch Ultra
Watch7,1 : Apple Watch Series 9 41mm case (GPS)
Watch7,2 : Apple Watch Series 9 45mm case (GPS)
Watch7,3 : Apple Watch Series 9 41mm case (GPS+Cellular)
Watch7,4 : Apple Watch Series 9 45mm case (GPS+Cellular)
Watch7,5 : Apple Watch Ultra 2
"""
        let lines = types.components(separatedBy: "\n")
        for line in lines {
            guard line.trimmed != "" else {
//                print("skipping blank line")
                continue
            }
            let parts = line.components(separatedBy: " : ")
            guard parts.count == 2 else {
                debug("Unknown part: \(line)", level: .WARNING)
                continue
            }
            let (identifier, description) = (parts[0], parts[1])
            let device = Device(identifier: identifier)
            if device.officialName.contains("Unknown") {
                var definition = device.definition
                //                device.officialName = description (can't do this since can't modify device now that it's sendable so replace the official name definition in the output)
                definition = definition.replacingOccurrences(of: device.officialName.definition, with: description.definition)
                print(definition)
                
            }
        }
    }
}

func test() {
    let _ = [
        
        1
    ]
}
