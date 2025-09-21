//
//  Migration.swift
//  DeviceTest
//
//  Created by Ben Ku on 3/25/24.
//
#if DEBUG
@testable import Device // so we can access all devices and DeviceType

// For converting to deviceKitDefinition format
extension Bool {
    var deviceKitDefinition: String {
        self ? "True" : "False"
    }
}

/// assign only if the rhs is larger than the original value (if less, don't do assignment)
infix operator =>
func =>(lhs: inout Int, rhs: Int) {
    if rhs > lhs {
        lhs = rhs
    }
}

// For conversion from Device
extension CPU {
    init(deviceKitString: String) {
        for item in Self.allCases {
            if item.deviceKitString == deviceKitString {
                self = item
                return
            }
        }
        self = .unknown
    }
    var deviceKitString: String {
        var string = caseName
        if string.contains("a10") {
            string += "Fusion"
        } else if string.contains("a17") || string.contains("a18") || string.contains("a19") {
            string = string.replacingOccurrences(of: "pro", with: "Pro")
        } else if string.contains("a1") {
            string += "Bionic"
        }
        return string.replacingOccurrences(of: "x", with: "X").replacingOccurrences(of: ".", with: "").replacingOccurrences(of: "z", with: "Z").replacingOccurrences(of: "p", with: "P")
    }
}

extension Set<Camera> {
    /// convert sets of cameras to numbers
    var deviceKitNum: Int {
        let wide = self.contains(.wide)
        let telephoto = self.contains(.telephoto)
        let ultraWide = self.contains(.ultraWide)
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
        } else if self.count > 0 {
            camerasNum = 1
        }
        return camerasNum
    }
    init(deviceKitNum: Int) {
        var cameras: Set<Camera> = []
        switch deviceKitNum {
        case 123:
            cameras.insert(.wide)
            cameras.insert(.telephoto)
            cameras.insert(.ultraWide)
        case 23:
            cameras.insert(.telephoto)
            cameras.insert(.ultraWide)
        case 13:
            cameras.insert(.wide)
            cameras.insert(.ultraWide)
        case 12:
            cameras.insert(.wide)
            cameras.insert(.telephoto)
        case 3:
            cameras.insert(.ultraWide)
        case 2:
            cameras.insert(.telephoto)
        case 1:
            cameras.insert(.wide)
        default:
            break
        }
        self = cameras
    }
}

extension Set<ApplePencil> {
    var deviceKitPencilSupport: Int {
        // this is a bad way of expressing pencil support.
        var applePencilSupport = 0
        if self.contains(.firstGeneration) {
            applePencilSupport = 1
        } else if self.contains(.secondGeneration) {
            applePencilSupport = 2
        }
        return applePencilSupport
    }
    init(deviceKitPencilSupport: Int) {
        var pencils: Set<ApplePencil> = []
        switch deviceKitPencilSupport {
        case 1:
            pencils.insert(.firstGeneration)
        case 2:
            pencils.insert(.secondGeneration)
        default:
            break
        }
        self = pencils
    }
}

extension String {
    var identifierNumber: Double {
        let result = self.filter("0123456789,".contains)
        return Double(result.replacingOccurrences(of: ",", with: ".")) ?? -1
    }
    static let parseError = "PARSE_ERROR"
}
extension Bool {
    static let parseError: Bool = false
}
extension Int {
    static let parseError: Int = -1
}
extension Double {
    static let parseError: Double = .nan
}
extension [Int] {
    static let parseError: [Int] = [-1,-1]
}
extension [String] {
    static let parseError: [String] = [.parseError]
}

let deviceKitIndentation = "            "

struct DeviceKitDevice: DeviceBridge {
    // https://github.com/devicekit/DeviceKit/blob/581df61650bc457ec00373a592a84be3e7468eb1/Source/Device.swift.gyb
    static var diffIgnoreKeys: [String] {
        ["imageURL"] // filter out and ignore these paths when calculating exact match - for things like DeviceKit comments or images/support URLs since we know those may differ
    }

    var caseName: String
    var comment: String
    var imageURL: String
    var identifiers: [String]
    var diagonal: Double
    var screenRatio: [Double]? // really a tuple
    var description: String
    var safeDescription: String
    var ppi: Int
    var isPlusFormFactor: Bool
    var isPadMiniFormFactor: Bool
    var isPro: Bool
    var isXSeries: Bool
    var hasTouchID: Bool
    var hasFaceID: Bool
    var hasSensorHousing: Bool
    var supportsWirelessCharging: Bool
    var hasRoundedDisplayCorners: Bool
    var hasDynamicIsland: Bool
    var applePencilSupport: Int
    var hasForce3dTouchSupport: Bool
    var cameras: Int
    var hasLidarSensor: Bool
    var cpu: String
    var hasUSBCConnectivity: Bool
    var has5gSupport: Bool
    
    init(caseName: String, comment: String, imageURL: String, identifiers: [String], diagonal: Double, screenRatio: [Double]? = nil, description: String, safeDescription: String, ppi: Int, isPlusFormFactor: Bool, isPadMiniFormFactor: Bool, isPro: Bool, isXSeries: Bool, hasTouchID: Bool, hasFaceID: Bool, hasSensorHousing: Bool, supportsWirelessCharging: Bool, hasRoundedDisplayCorners: Bool, hasDynamicIsland: Bool, applePencilSupport: Int, hasForce3dTouchSupport: Bool, cameras: Int, hasLidarSensor: Bool, cpu: String, hasUSBCConnectivity: Bool, has5gSupport: Bool) {
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
    }

    init(fields: [MixedTypeField]) {
        caseName = fields[0].stringValue ?? .parseError
        comment = fields[1].stringValue ?? .parseError
        imageURL = fields[2].stringValue ?? .parseError
        identifiers = fields[3].arrayValue?.map { $0?.stringValue ?? .parseError } ?? .parseError
        diagonal = fields[4].doubleValue ?? .parseError
        screenRatio = fields[5].arrayValue?.map { $0?.doubleValue ?? .parseError }
        if screenRatio?.count != 2 { screenRatio = nil } // AppleTV doesn't have a screen ratio.
        description = fields[6].stringValue ?? .parseError
        safeDescription = fields[7].stringValue ?? .parseError
        ppi = fields[8].intValue ?? .parseError
        isPlusFormFactor = fields[9].boolValue ?? .parseError
        isPadMiniFormFactor = fields[10].boolValue ?? .parseError
        isPro = fields[11].boolValue ?? .parseError
        isXSeries = fields[12].boolValue ?? .parseError
        hasTouchID = fields[13].boolValue ?? .parseError
        hasFaceID = fields[14].boolValue ?? .parseError
        hasSensorHousing = fields[15].boolValue ?? .parseError
        supportsWirelessCharging = fields[16].boolValue ?? .parseError
        hasRoundedDisplayCorners = fields[17].boolValue ?? .parseError
        hasDynamicIsland = fields[18].boolValue ?? .parseError
        applePencilSupport = fields[19].intValue ?? .parseError
        hasForce3dTouchSupport = fields[20].boolValue ?? .parseError
        cameras = fields[21].intValue ?? .parseError
        hasLidarSensor = fields[22].boolValue ?? .parseError
        cpu = fields[23].stringValue ?? .parseError
        hasUSBCConnectivity = fields[24].boolValue ?? .parseError
        has5gSupport = fields[25].boolValue ?? .parseError
    }
    
    var supportLink: String? {
        // support link extraction
        if let supportLink = comment.extract(from: "(http", to: ")") {
            return "http" + supportLink
        }
        return nil
    }
    
    var supportId: String? {
        if let id = supportLink?.split(separator: "/").last {
            String(id)
        } else {
            nil
        }
    }
    
    var matched: Device {
        return Device.forcedLookup(identifier: identifiers.first, supportId: supportId, officialNameHint: description)
    }

    var merged: Device {
        // massage values
        var officialName = description
        if caseName.contains("Apple Watch") {
            if let pos = caseName.lastIndex(of: " "), !caseName.contains("Ultra") {
                let mm = caseName[pos..<caseName.endIndex]
                officialName = officialName.replacingOccurrences(of: mm, with: "")
            }
            let end = officialName.firstIndex(of: ")") ?? officialName.endIndex
            officialName = String(officialName[officialName.startIndex..<end])
            if officialName.contains("generation") {
                officialName += ")"
            }
        }
        if officialName.contains("Apple TV") {
            officialName = officialName.replacingOccurrences(of: " (1st generation)", with: "")
        }
        
        officialName = description
            .replacingOccurrences(of: "mini", with: "Mini")
            .replacingOccurrences(of: " inch", with: "-inch")
            .replacingOccurrences(of: ["+", "Rev A", "1st Gen", "1TB", "10.2-inch", "case", "CDMA", "GPS", "GSM", "Cellular", "LTE", "WiFi", "China", "Global", "New Revision", ", ", "()"], with: "")
            .replacingOccurrences(of: "(2017)", with: "(5th generation)")
            .replacingOccurrences(of: "10.5-inch 2nd Gen", with: "(10.5-inch)")
            .replacingOccurrences(of: "XR", with: "Xʀ")
            .trimmed
    
        officialName = officialName.replacingOccurrences(of: " 11-inch", with: " (11-inch)")
        officialName = officialName.replacingOccurrences(of: " 12.9-inch", with: " (12.9-inch)")
        
        // capabilities
        var capabilities = Capabilities()
        if let screenRatio, screenRatio.count == 2 {
            let angle = atan(screenRatio[0] / screenRatio[1]) // Returns angle in radians
            let height = diagonal * sin(angle)
            let width = diagonal * cos(angle)
            if angle.isNaN || height.isNaN || width.isNaN {
                // Don't add a screen
            } else {
                capabilities.screen = Screen(diagonal: diagonal, resolution: (Int(width), Int(height)), ppi: ppi)
            }
        }
        if isPlusFormFactor {
            if description.contains("Plus") {
                capabilities.insert(.plus)
            }
            if description.contains("Max") {
                capabilities.insert(.max)
            }
        }
        if isPadMiniFormFactor {
            capabilities.insert(.mini)
        }
        if isPro {
            capabilities.insert(.pro)
        }
        if hasSensorHousing || hasFaceID {
            capabilities.biometrics = .faceID
        } else if hasTouchID {
            capabilities.biometrics = .touchID
        }
        if supportsWirelessCharging {
            capabilities.insert(.wirelessCharging)
        }
        if hasRoundedDisplayCorners {
            capabilities.insert(.roundedCorners)
        }
        if hasDynamicIsland {
            capabilities.insert(.dynamicIsland)
        }
        capabilities.pencils = .init(deviceKitPencilSupport: applePencilSupport)
        if hasForce3dTouchSupport {
            capabilities.insert(.force3DTouch)
        }
        capabilities.cameras = .init(deviceKitNum: cameras)
        if hasLidarSensor {
            capabilities.insert(.lidar)
        }
        if hasUSBCConnectivity {
            capabilities.insert(.usbC)
        }
        if has5gSupport {
            capabilities.cellular = .fiveG
        }
        
        return Device(
            idiom: .unspecified,
            officialName: officialName,
            identifiers: identifiers,
            introduction: nil,
            supportId: supportId ?? .unknownSupportId,
            launchOSVersion: .zero,
            unsupportedOSVersion: nil,
            image: imageURL,
            capabilities: capabilities,
            models: [],
            colors: [],
            cpu: CPU(deviceKitString: cpu)
        ).merged(from: matched)
    }
    
    func bridge(from device: Device) -> DeviceKitDevice {
        // assumes run on upgraded device
        // create case name
        var caseName = device.officialName.safeDescription
        var officialName = device.officialName
        let idiom = device.idiom
        if idiom == .watch {
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

        officialName = officialName.replacingOccurrences(of: " 11-inch", with: " (11-inch)")
        officialName = officialName.replacingOccurrences(of: " 12.9-inch", with: " (12.9-inch)")
        
        var comments = "Device is a\(officialName[officialName.startIndex].isVowel() ? "n" : "") [\(officialName)](\(device.supportURL))"
        comments = comments.replacingOccurrences(of: " (9.7-inch)", with: " 9.7-inch")
        comments = comments.replacingOccurrences(of: " (10.5-inch)", with: " 10.5-inch")
        comments = comments.replacingOccurrences(of: " (11-inch)", with: " 11-inch")
        comments = comments.replacingOccurrences(of: " (12.9-inch)", with: " 12.9-inch")
        // Break data for bad format
        let identifiersFlat = device.identifiers.definition
        if identifiersFlat.contains("iPad6") || identifiersFlat.contains("iPad7") {
            comments = comments.replacingOccurrences(of: "12.9-inch", with: "12-inch")
        }

        var safeOfficialName = officialName.safeDescription.replacingOccurrences(of: "Xs", with: "XS")
        safeOfficialName = safeOfficialName.replacingOccurrences(of: " 11-inch", with: " (11-inch)")
        safeOfficialName = safeOfficialName.replacingOccurrences(of: " 12.9-inch", with: " (12.9-inch)")
        
        // butcher for bad format
        comments = comments.replacingOccurrences(of: "Ultra 2", with: "Ultra2")
        officialName = officialName.replacingOccurrences(of: "Ultra 2", with: "Ultra2")
        safeOfficialName = safeOfficialName.replacingOccurrences(of: "Ultra 2", with: "Ultra2")

        var imageURL = device.image ?? ""
        if caseName == "homePod" {
            imageURL = "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP773/homepod_space_gray_large_2x.jpg" // use different version
        }

        
        let screen = device.screen // use capabilities version, not local variable version
        var diagonal = screen?.diagonal ?? -1
        if diagonal == 1.65 {
            diagonal = 1.6
        }
        var ppi = screen?.ppi ?? -1
        if idiom == .homePod {
            diagonal = -1
            ppi = -1
        }
        var ratio = [Double]()
        if let screenRatio = screen?.resolution.ratio {
            ratio = [screenRatio.width.doubleValue, screenRatio.height.doubleValue]
        }
        if idiom == .tv {
            ratio = []
        }
        if [8, 13, 14].contains(Int(device.identifiers.first?.identifierNumber ?? -1)) {
            if ratio == [3, 4] {
                ratio = [512, 683]
            }
        }
        
        let isXSeries = device.capabilities.biometrics == .faceID && idiom != .pad // faceID is proxy for "isXSeries"
        
        return DeviceKitDevice(
            caseName: caseName,
            comment: comments,
            imageURL: imageURL,
            identifiers: identifiers,
            diagonal: diagonal,
            screenRatio: ratio,
            description: officialName,
            safeDescription: safeOfficialName,
            ppi: ppi,
            isPlusFormFactor: device.is(.plus) || device.is(.max),
            isPadMiniFormFactor: device.is(.mini) && idiom == .pad, // homepod mini or iPhone mini does not count
            isPro: device.is(.pro),
            isXSeries: isXSeries,
            hasTouchID: device.capabilities.biometrics == .touchID,
            hasFaceID: device.capabilities.biometrics == .faceID,
            hasSensorHousing: isXSeries,
            supportsWirelessCharging: device.has(.wirelessCharging),
            hasRoundedDisplayCorners: device.has(.roundedCorners),
            hasDynamicIsland: device.has(.dynamicIsland),
            applePencilSupport: device.capabilities.pencils.deviceKitPencilSupport,
            hasForce3dTouchSupport: device.has(.force3DTouch),
            cameras: device.capabilities.cameras.deviceKitNum,
            hasLidarSensor: device.has(.lidar),
            cpu: device.cpu.deviceKitString,
            hasUSBCConnectivity: device.has(.usbC),
            has5gSupport: device.cellular == .fiveG)
    }

    func buildRatio(ratioInnerSpace: String) -> String {
        if let screenRatio, screenRatio.count == 2 {
            return "(\(screenRatio[0]),\(ratioInnerSpace)\(screenRatio[1]))"
        } else {
            return "()"
        }
    }

    var source: String {
        let identifiers = identifiers.definition
        var selfDiagonal = self.diagonal
        if self.diagonal.isNaN {
            selfDiagonal = -1
        }
        var diagonal = "\(selfDiagonal)"
        if selfDiagonal != 4 && Int(selfDiagonal).doubleValue == selfDiagonal {
            diagonal = "\(diagonal).0"
        }
        var preSpace = ""
        let space = " "
        var ratio = buildRatio(ratioInnerSpace: space)

        var isAppleWatch = false

        // sizes should be the whole space including the quotes and comma.  Default should include one space.
        var nameSize = caseName.count + 4
        var commentSize = comment.count + 4
        var imageSize = imageURL.count + 4
        var identifiersSize = identifiers.count + 2
        var diagonalSize = diagonal.count + 2
        var ratioSize = ratio.count + 2
        
        switch self.matched.idiom {
        case .pod:
            nameSize => 18
            commentSize => 82
            imageSize => 114
            identifiersSize => 46
            diagonalSize => 6
            ratioSize => 12
        case .phone:
            nameSize => 18
            commentSize => 82
            imageSize => 125
            identifiersSize => 46
            diagonalSize => 6
            ratioSize => 12
        case .tv:
            nameSize => 18
            commentSize => 105
            imageSize => 117
            identifiersSize => 17
            diagonalSize => 3
            ratioSize => 4
        case .pad:
            nameSize => 18
            commentSize => 90
            imageSize => 115
            identifiersSize => 52
            diagonalSize => 6
            ratioSize => 13
        case .homePod:
            nameSize => 18
            commentSize => 90
            imageSize => 106
            identifiersSize => 46
            diagonalSize => 6
            ratioSize => 12
        case .watch:
            isAppleWatch = true
        default:
            break
        }
                
        var nameSpace = String(repeating: " ", count: nameSize-caseName.count-3)
        var commentSpace = String(repeating: " ", count: commentSize-comment.count-3)
        var imageSpace = String(repeating: " ", count: imageSize-imageURL.count-3) // comma & quotes not included
        var identifiersSpace = String(repeating: " ", count: identifiersSize-identifiers.count-1) // comma not included
        var diagonalSpace = String(repeating: " ", count: diagonalSize-diagonal.count-1) // comma not included
        var ratioSpace = String(repeating: " ", count: ratioSize-ratio.count-1) // comma not included
        
        var prefix = deviceKitIndentation
        if isAppleWatch {
            preSpace = "\n\(deviceKitIndentation)"
            prefix = preSpace
            nameSpace = preSpace
            commentSpace = preSpace
            imageSpace = preSpace
            identifiersSpace = space
            diagonalSpace = space
            ratioSpace = space
            ratio = buildRatio(ratioInnerSpace: "")
        }

        return """
\(prefix)Device(\(preSpace)\(caseName.definition),\(nameSpace)\(comment.definition),\(commentSpace)\(imageURL.definition),\(imageSpace)\(identifiers),\(identifiersSpace)\(diagonal),\(diagonalSpace)\(ratio),\(ratioSpace)\(description.definition), \(safeDescription.description), \(ppi), \(isPlusFormFactor.deviceKitDefinition), \(isPadMiniFormFactor.deviceKitDefinition), \(isPro.deviceKitDefinition), \(isXSeries.deviceKitDefinition), \(hasTouchID.deviceKitDefinition), \(hasFaceID.deviceKitDefinition), \(hasSensorHousing.deviceKitDefinition), \(supportsWirelessCharging.deviceKitDefinition), \(hasRoundedDisplayCorners.deviceKitDefinition), \(hasDynamicIsland.deviceKitDefinition), \(applePencilSupport), \(hasForce3dTouchSupport.deviceKitDefinition), \(cameras), \(hasLidarSensor.deviceKitDefinition), \(cpu.definition), \(hasUSBCConnectivity.deviceKitDefinition), \(has5gSupport.deviceKitDefinition)),
"""
    }
}

struct DeviceKitLoader: DeviceBridgeLoader {
    func devices() async throws -> [DeviceKitDevice] {
        var devices = [DeviceKitDevice]()
        let code = try await fetchURL(urlString: "https://raw.githubusercontent.com/devicekit/DeviceKit/refs/heads/master/Source/Device.swift.gyb")
        
        let parts = code.components(separatedBy: " = [")
        for part in parts {
            let deviceKitStrings = part.components(separatedBy: "            Device(")
            for deviceKitString in deviceKitStrings {
                guard !deviceKitString.contains("This source file"), deviceKitString.contains(", "), !deviceKitString.contains("watchOS_cpus") else {
                    continue
                }
                var jsonString = deviceKitString.extract(from: nil, to: "),\n") ?? deviceKitString // make sure not the last item in a group and trim remainder
                jsonString = "[\(jsonString)]" // add brackets
                    .replacingOccurrences(of: ", False", with: ", false") // convert gyb to json
                    .replacingOccurrences(of: ", True", with: ", true") // convert gyb to json
                    // convert tuples to arrays
                    .replacingOccurrences(of: "  (", with: "  [")
                    .replacingOccurrences(of: ", (", with: ", [") // for cases where there is only one space
                    .replacingOccurrences(of: "),", with: "],")
                do {
                    // parse the mixed type array into Swift types
                    let fields = try [MixedTypeField](fromJSON: jsonString)
                    let device = DeviceKitDevice(fields: fields)
                    devices.append(device)
                } catch {
                    debug("Parse error: \(error).  JSON String:\n\(jsonString)", level: .WARNING)
                    continue
                }
            }
        }
        return devices
    }
    
    // For generating a new file based on our data in case we want to submit a pull request?
//    func generate() async -> String {
//        return Device.allDevices.map { DeviceKitDevice($0).source }.joined(separator: "\n")
//    }
}
#endif


// MARK: Legacy code (unused?)
extension DeviceKitLoader {
    /// Ordered list of identifiers in DeviceKit definition file.  Used for migration export.
    /// iOS iPods, iPhones, iPads, HomePods, Apple TV, Apple Watch (doesn't include vision or macs)
    static let deviceKitOrder = [
        "iPod1,1",
        "iPod2,1",
        "iPod3,1",
        "iPod4,1",
        "iPod5,1",
        "iPod7,1",
        "iPod9,1",
        "iPhone1,1",
        "iPhone1,2",
        "iPhone2,1",
        "iPhone3,1","iPhone3,2","iPhone3,3",
        "iPhone4,1",
        "iPhone5,1","iPhone5,2",
        "iPhone5,3","iPhone5,4",
        "iPhone6,1","iPhone6,2",
        "iPhone7,2",
        "iPhone7,1",
        "iPhone8,1",
        "iPhone8,2",
        "iPhone9,1","iPhone9,3",
        "iPhone9,2","iPhone9,4",
        "iPhone8,4",
        "iPhone10,1","iPhone10,4",
        "iPhone10,2","iPhone10,5",
        "iPhone10,3","iPhone10,6",
        "iPhone11,2",
        "iPhone11,4","iPhone11,6",
        "iPhone11,8",
        "iPhone12,1",
        "iPhone12,3",
        "iPhone12,5",
        "iPhone12,8",
        "iPhone13,2",
        "iPhone13,1",
        "iPhone13,3",
        "iPhone13,4",
        "iPhone14,5",
        "iPhone14,4",
        "iPhone14,2",
        "iPhone14,3",
        "iPhone14,6",
        "iPhone14,7",
        "iPhone14,8",
        "iPhone15,2",
        "iPhone15,3",
        "iPhone15,4",
        "iPhone15,5",
        "iPhone16,1",
        "iPhone16,2",
        "iPhone17,3",
        "iPhone17,4",
        "iPhone17,1",
        "iPhone17,2",
        "iPhone17,5",
        "iPhone18,3",
        "iPhone18,1",
        "iPhone18,2",
        "iPhone18,4",
        "iPad1,1",
        "iPad2,1","iPad2,2","iPad2,3","iPad2,4",
        "iPad3,1","iPad3,2","iPad3,3",
        "iPad3,4","iPad3,5","iPad3,6",
        "iPad4,1","iPad4,2","iPad4,3",
        "iPad5,3","iPad5,4",
        "iPad6,11","iPad6,12",
        "iPad7,5","iPad7,6",
        "iPad11,3","iPad11,4",
        "iPad7,11","iPad7,12",
        "iPad11,6","iPad11,7",
        "iPad12,1","iPad12,2",
        "iPad13,18","iPad13,19",
        "iPad13,1","iPad13,2",
        "iPad13,16","iPad13,17",
        "iPad14,8","iPad14,9",
        "iPad14,10","iPad14,11",
        "iPad15,3","iPad15,4",
        "iPad15,5","iPad15,6",
        "iPad2,5","iPad2,6","iPad2,7",
        "iPad4,4","iPad4,5","iPad4,6",
        "iPad4,7","iPad4,8","iPad4,9",
        "iPad5,1","iPad5,2",
        "iPad11,1","iPad11,2",
        "iPad14,1","iPad14,2",
        "iPad16,1","iPad16,2",
        "iPad6,3","iPad6,4",
        "iPad6,7","iPad6,8",
        "iPad7,1","iPad7,2",
        "iPad7,3","iPad7,4",
        "iPad8,1","iPad8,2","iPad8,3","iPad8,4",
        "iPad8,5","iPad8,6","iPad8,7","iPad8,8",
        "iPad8,9","iPad8,10",
        "iPad8,11","iPad8,12",
        "iPad13,4","iPad13,5","iPad13,6","iPad13,7",
        "iPad13,8","iPad13,9","iPad13,10","iPad13,11",
        "iPad14,3","iPad14,4",
        "iPad14,5","iPad14,6",
        "iPad16,3","iPad16,4",
        "iPad16,5","iPad16,6",
        "AudioAccessory1,1",
        "AudioAccessory5,1",
        "AudioAccessory6,1",
        "AppleTV1,1",
        "AppleTV2,1",
        "AppleTV3,1",
        "AppleTV3,2",
        "AppleTV5,3",
        "AppleTV6,2",
        "AppleTV11,1",
        "AppleTV14,1",
        "Watch1,1",
        "Watch1,2",
        "Watch2,6",
        "Watch2,7",
        "Watch2,3",
        "Watch2,4",
        "Watch3,1","Watch3,3",
        "Watch3,2","Watch3,4",
        "Watch4,1","Watch4,3",
        "Watch4,2","Watch4,4",
        "Watch5,1","Watch5,3",
        "Watch5,2","Watch5,4",
        "Watch6,1","Watch6,3",
        "Watch6,2","Watch6,4",
        "Watch5,9","Watch5,11",
        "Watch5,10","Watch5,12",
        "Watch6,6","Watch6,8",
        "Watch6,7","Watch6,9",
        "Watch6,14","Watch6,16",
        "Watch6,15","Watch6,17",
        "Watch6,10","Watch6,12",
        "Watch6,11","Watch6,13",
        "Watch6,18",
        "Watch7,1","Watch7,3",
        "Watch7,2","Watch7,4",
        "Watch7,5",
        "Watch7,8","Watch7,10",
        "Watch7,9","Watch7,11",
        "Watch7,12",
        "Watch7,17","Watch7,19",
        "Watch7,18","Watch7,20",
    ]
}

/*
 extension DeviceType {
     var deviceKitSortKey: Int {
         DeviceKitLoader.deviceKitOrder.firstIndex(of: identifiers.first!) ?? -1
     }
 }
public struct Migration {
    static func printAllDevices(printProperty: KeyPath<DeviceType,String>, sortFunc: ((DeviceType, DeviceType) -> Bool)? = nil) -> String {
        var lastIdiom = ""
        var devices = Device.all
        if let sortFunc {
            devices.sort(by: sortFunc)
        }
        var deviceList = ""
        for device in devices {
//            device.upgrade()
            let idiom = device.idiom.label
            if idiom != lastIdiom {
                deviceList += "        ]\n\n\(idiom)s = [\n"
                lastIdiom = idiom
            }
            deviceList += device.idiomatic[keyPath: printProperty] + ",\n"
            // TODO: See if we have another way since idiomatic is internal.
//            let str = device.idiomatic[keyPath: printProperty]
//            if str != "" {// skip blank macs.
//                print(str)
//            }
        }
        return deviceList
    }
    static func exportDeviceKitDefinitions() -> String {
        var definitionString = """
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
        """
        definitionString += printAllDevices(printProperty: \.deviceKitDefinition, sortFunc: { $0.deviceKitSortKey < $1.deviceKitSortKey })
                
        return definitionString
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
    
    
    
    
//    static func convertMacs() -> String {
//        let macsRaw = """
//[
//    {
//        "models" : [
//            "iMac21,2"
//        ],
//        "kind" : "iMac",
//        "colors" : [
//            "silverLight",
//            "pinkLight",
//            "blueLight",
//            "greenLight"
//        ],
//        "name" : "iMac (24-inch, M1, 2021)",
//        "variant" : "24-inch, M1, 2021",
//        "parts" : [
//            "MGTF3xx/a",
//            "MJV83xx/a",
//            "MJV93xx/a",
//            "MJVA3xx/a"
//        ]
//    }
//]
//"""
//        let json = macsRaw.data(using: .utf8)!
//        let decoder = JSONDecoder()
//        let macs = (try? decoder.decode([MacLookup].self, from: json)) ?? []
//        //print(String(describing: macs))
//        var outputString = ""
//        for mac in macs {
////            outputString += mac.asMacLookup().device.definition + "\n"
//        }
//        return outputString
//    }
}
*/
