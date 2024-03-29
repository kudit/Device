//
//  Migration.swift
//  DeviceTest
//
//  Created by Ben Ku on 3/25/24.
//

import Foundation

extension String {
    var isVowel: Bool {
        let vowels = ["a","e","i","o","u"]
        return vowels.contains(self.lowercased())
    }
}
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
extension Definable {
    var definition: String {
        // for enums
        "." + (Mirror(reflecting: self).children.first?.label ?? "\(String(describing: self))")
    }
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
    static var all = [
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
    static var widescreen = Screen.Size(width: 9, height: 16)
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
            return "." + (Mirror(reflecting: self).children.first?.label ?? "\(String(describing: self))")
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
                print("UNKNOWN NON-DEFINABLE TYPE: \(key): \(value)")
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
        let indentSpace = "        "
        var idiomish = ""
        if idiom.type == Device.self {
            idiomish = "idiom: \(idiom.definition),\n\(indentSpace)"
        }
        var macForm = ""
        if idiom == .mac, let form = capabilities.macForm { // second should never fail if .mac idiom
            macForm = "form: \(form.definition),\n\(indentSpace)"
        }
        // strip out default capabilities
        let control = idiom.type.init(identifier: .base) // create a base model (not the default model!)
        var capabilities = capabilities.subtracting(control.capabilities)
        // remove .macForm from capabilities
        capabilities.macForm = nil // remove so not appears in capabilities list
        var models = "models: \(models.definition),\n\(indentSpace)"
        if self.models.count == 0 { // don't do this if we want to always have models.  Remove once we've gone through and added all models.
            models = ""
        }
        var colors = "colors: \(colors.definition),\n\(indentSpace)"
        if self.colors.count == 0 || self.colors == .default || idiom == .vision { // don't do this if we want to always have models.  Remove once we've gone through and added all models.
            colors = ""
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
        return """
            \(String(describing: idiom.type))(
                \(idiomish)name: \(name.definition),
                identifiers: \(identifiers.definition),
                supportId: \(supportId.definition),
                \(macForm)image: \(image.definition),
                \(overrides)\(models)\(colors)cpu: \(cpu.definition)\(cameras)\(cellular)\(screen)\(pencils)\(watchSize)),
        """
    }
    var deviceKitDefinition: String {
        // assumes run on upgraded device
        // create case name
        var caseName = name.safeDescription
        var name = name
        var isAppleWatch = false
        if caseName.contains("Apple Watch") {
            if let pos = caseName.lastIndex(of: " "), !caseName.contains("Ultra") {
                let mm = caseName[pos..<caseName.endIndex]
                caseName.replaceSubrange(pos..<caseName.index(pos, offsetBy: 1), with: "_")
                name = name.replacingOccurrences(of: mm, with: "")
            }
            caseName = caseName.replacingOccurrences(of: "Apple Watch", with: "apple Watch")
            caseName = caseName.replacingOccurrences(of: "(1st generation)", with: "Series0")
            let end = name.firstIndex(of: ")") ?? name.endIndex
            name = String(name[name.startIndex..<end])
            if name.contains("generation") {
                name += ")"
            }
            isAppleWatch = true
        }
        if name.contains("Apple TV") {
            name = name.replacingOccurrences(of: " (1st generation)", with: "")
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
        
        var description = description
        var safeDescription = safeDescription.replacingOccurrences(of: "Xs", with: "XS")
        
        var support = "Device is a\(String(name[name.startIndex]).isVowel ? "n" : "") [\(name)](https://support.apple.com/kb/\(supportId))"
        support = support.replacingOccurrences(of: " (9.7-inch)", with: " 9.7-inch")
        support = support.replacingOccurrences(of: " (10.5-inch)", with: " 10.5-inch")
        support = support.replacingOccurrences(of: " (11-inch)", with: " 11-inch")
        support = support.replacingOccurrences(of: " (12.9-inch)", with: " 12.9-inch")

        description = description.replacingOccurrences(of: " 11-inch", with: " (11-inch)")
        description = description.replacingOccurrences(of: " 12.9-inch", with: " (12.9-inch)")

        safeDescription = safeDescription.replacingOccurrences(of: " 11-inch", with: " (11-inch)")
        safeDescription = safeDescription.replacingOccurrences(of: " 12.9-inch", with: " (12.9-inch)")

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
        if name.contains("HomePod") {
            diagonal = "-1"
            ppi = -1
        }
        var ratio = "\(screen?.resolution.ratio.deviceKitDefinition ?? "()")"
        if name.contains("Apple TV") {
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
            Device("\(caseName)",\(nameSpace)"\(support)",\(supportSpace)"\(image)",\(imageSpace)\(identifiers),\(identifiersSpace)\(diagonal),\(diagonalSpace)\(ratio),\(ratioSpace)"\(description)", "\(safeDescription)", \(ppi), \(isPlusFormFactor.deviceKitDefinition), \(isPadMiniFormFactor.deviceKitDefinition), \(capabilities.contains(.pro).deviceKitDefinition), \(isXSeries.deviceKitDefinition), \((capabilities.biometrics == .touchID).deviceKitDefinition), \((capabilities.biometrics == .faceID).deviceKitDefinition), \(hasSensorHousing.deviceKitDefinition), \(has(.wirelessCharging).deviceKitDefinition), \(has(.roundedCorners).deviceKitDefinition), \(has(.dynamicIsland).deviceKitDefinition), \(applePencilSupport), \(has(.force3DTouch).deviceKitDefinition), \(camerasNum), \(has(.lidar).deviceKitDefinition), "\(cpu.deviceKitDefinition)", \(has(.usbC).deviceKitDefinition), \((cellular == .fiveG).deviceKitDefinition)),
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
    var name: String
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
        var cpu = CPU.from(nameString: name)
        var capabilities = form.capabilities
        if name.contains("Pro") {
            capabilities.insert(.pro)
        }
        if name.contains("Air") {
            capabilities.insert(.air)
        }
        if name == "iMac Pro" {
            cpu = .xeonE5
        }
        // assume all the ones we're importing are new enough that they have USB-C
        capabilities.insert(.usbC)
        capabilities.subtract(form.capabilities) // will automatically be added by form so no need to double add.
        return Mac(
            name: name,
            identifiers: models.distilled,
            supportId: "UNKNOWN_PLEASE_HELP_REPLACE",
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
        print("Unknown color string: \"\(string)\"")
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
            items += item.split(separator: "; ").map { String($0) }
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

struct Migration {
    static func printAllDevices(printProperty: KeyPath<DeviceType,String>, sortFunc: ((DeviceType, DeviceType) -> Bool)? = nil) {
        var lastIdiom = ""
        var devices = Device.all
        if let sortFunc {
            devices.sort(by: sortFunc)
        }
        for device in devices {
//            device.upgrade()
            let idiom = device.idiom.description
            if idiom != lastIdiom {
                print("        ]\n\n\(idiom)s = [")
                lastIdiom = idiom
            }
            let str = device.idiomatic[keyPath: printProperty]
            if str != "" {// skip blank macs.
                print(str)
            }
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
    static func migrate() {
//        #warning("Remove once tested.  This is for button linkage.")
//        exportDeviceKitDefinitions()
        exportDefinitions()
//        convertMacs()
//        createOrder()
    }
    /// Extract the current order for saving and preserving the DeviceKit order (which isn't in identifier order which is preferable)
    static func createOrder() {
        for var device in iPad.all.sorted(by: { $0.identifierSortKey < $1.identifierSortKey
        }) {
            if !device.has(.usbC) {
                // make sure to add in lighting connector where missing
                device.device.capabilities.insert(.lightning)
            }
            print("\(device.definition)")
        }
    }
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
}

func test() {
    let _ = [
        
        1
    ]
}
