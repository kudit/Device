import Compatibility
import Device

extension String {
    var identifierVersion: Version {
        return Version(self.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789,").inverted).replacingOccurrences(of: ",", with: "."))
    }
}


extension Screen.Size: Definable {
    public static let widescreen = Screen.Size(width: 9, height: 16)
    public var definition: String {
        return "(\(width), \(height))"
    }
}
// for CaseNameConvertible
extension BatteryState: Definable {}
extension CPU: Definable {}
extension Biometrics: Definable {}
extension Camera: Definable {}
extension Cellular: Definable {}
extension ApplePencil: Definable {}
extension MaterialColor: Definable {}
extension AppleWatch.WatchSize: Definable {}
extension AppleWatch.WatchSize.BandSize: Definable {}
extension Mac.Form: Definable {}
// for DeviceAttributeExpressible
extension Device.Idiom: Definable {}

extension Screen: Definable {
    public static let all = [
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
        "i65Air":.i65Air,
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
    
    public var definition: String {
        // check for one of the defined variables
        for (string,screen) in Screen.all {
            if screen == self {
                return ".\(string)"
            }
        }
        return "Screen(diagonal: \(diagonal.definition), resolution: (\(resolution.width),\(resolution.height)), ppi: \(ppi.definition))"
    }
}

extension Capability: Definable {
    public var definition: String {
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


// MARK: Device string definitions
extension Device: Definable {}
public extension Device {
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
        
        // remove capabilities inherant to the idiom since they will automatically be added so no need to include in definition.
        capabilities.subtract(idiom.capabilities)
        
        var macForm = ""
        if idiom == .mac, let form = capabilities.macForm { // second should never fail if .mac idiom
            macForm = "form: \(form.definition),\n\(indentSpace)"
            // remove default form capabilities like battery
            capabilities.subtract(form.capabilities)
        }
        //        capabilities.subtract(control.capabilities) // do after so .macMini form isn't removed which is the default
        // strip out default capabilities
        //        // add in ringer switch to all non-iPhone 15 pro devices
        //        if idiom == .phone, let identifier = identifiers.first, !identifier.contains("iPhone16") {
        //            capabilities.insert(.ringerSwitch)
        //        } DONE!
        
        // remove .macForm from capabilities
        capabilities.macForm = nil // remove so not appears in capabilities list
        var models = "models: \(models.definition),\n\(indentSpace)"
        if self.models.count == 0 { // don't do this if we want to always have models.  Remove once we've gone through and added all models.
            models = ""
        }
        
        var colors = "colors: \(colors.definition),\n\(indentSpace)"
//        if self.colors.count == 0 || self.colors == .default || idiom == .vision { // don't do this if we want to always have colors.  Remove once we've gone through and added all colors.
//            colors = ""
//        }
        //        debug("\(colors)") // for figuring out duplicate key crash
        if let key = [MaterialColor].colorSets[self.colors] {
            colors = "colors: .\(key),\n\(indentSpace)"
        }
        
        var cameras = ",\n\(indentSpace)cameras: \(capabilities.cameras.sorted.definition)"
        if capabilities.cameras.count == 0 || capabilities.cameras == .default || idiom == .vision || idiom == .mac {
            cameras = ""
        }
        capabilities.cameras = [] // make sure doesn't appear also in capabilities
        
        var cellular = ""
        if let c = capabilities.cellular {
            cellular = ",\n\(indentSpace)cellular: \(c.definition)"
        }
        capabilities.cellular = nil // make sure doesn't appear also in capabilities
        
        var screen = ""
        if let s = capabilities.screen, s != Screen.undefined, idiom != .tv, idiom != .homePod, idiom != .watch {
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
                \(idiom.constructor)(
                    \(idiomish)officialName: \(officialName.definition),
                    identifiers: \(identifiers.definition),
                    introduction: \(introduction.definition),
                    supportId: \(supportId.definition),
                    launchOSVersion: \(launchOSVersion.definition),
                    unsupportedOSVersion: \(unsupportedOSVersion.definition),
                    \(macForm)image: \(image.definition),
                    \(overrides)\(models)\(colors)cpu: \(cpu.definition)\(cameras)\(cellular)\(screen)\(pencils)\(watchSize)),
        """
    }
}

#if swift(>=6.0)
extension Device: @retroactive PropertyIterable {}
#else
// put here to silence warning
extension Compatibility {
    typealias PropertyIterableType = PropertyIterable
}
extension Device: Compatibility.PropertyIterableType {}
#endif
