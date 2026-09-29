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
    	let wide = self.containsAny([.wide, .main12MP, .main48MP, .fusionMain])
    	let telephoto = self.containsAny([.telephoto, .telephoto2½x, .telephoto3x, .telephoto5x, .fusionTelephoto])
    	let ultraWide = self.containsAny([.ultraWide, .ultraWide48MP, .fusionUltraWide])
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
	static let deviceKitMap: [Int: Set<ApplePencil>] = [
    	1: [.firstGeneration],
    	2: [.secondGeneration],
    	3: [.usbC],
    	4: [.pro],
    	13: [.firstGeneration, .usbC],
    	23: [.secondGeneration, .usbC],
    	234: [.secondGeneration, .usbC, .pro],
    	24: [.secondGeneration, .pro],
    	34: [.usbC, .pro],
	]

	var deviceKitPencilSupport: Int {
    	// this is a bad way of expressing pencil support.
    	if let num = Self.deviceKitMap.firstKey(for: self) {
	    	return num
    	}
    	return 0
	}
	init(deviceKitPencilSupport: Int) {
    	guard let pencils = Self.deviceKitMap[deviceKitPencilSupport] else {
	    	self.init() // empty
	    	return
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
	var comparisonIdentifiers: [String] { identifiers }
	var comparisonCPUs: [CPU] { [CPU(deviceKitString: cpu)] }

	/// Keep the source row whole while comparing each shared-support definition independently.
	func comparison(for member: Device, in group: [Device]) -> Self {
    	var scoped = self
    	scoped.identifiers = identifiers.filter { member.identifiers.contains($0) }
    	scoped.description = sourceGroupName(description, member: member, group: group)
    	scoped.safeDescription = sourceGroupName(safeDescription, member: member, group: group)
    	return scoped
	}
	// https://github.com/devicekit/DeviceKit/blob/581df61650bc457ec00373a592a84be3e7468eb1/Source/Device.swift.gyb
	static var diffIgnoreKeys: [String] {
		["imageURL"] // Images and support artwork are presentation data rather than device identity.
	}

	/// Normalizes DeviceKit presentation details before comparison with Device's canonical values.
	func bridgeValuesEqual(_ key: String, _ left: Any?, _ right: Any?) -> Bool {
    	// ThreeWayDiffView uses an empty key for display-level equality; apply
    	// the same bridge normalization there so consolidated rows do not
    	// reintroduce differences already classified as compatible.
    	if key.isEmpty {
	    	if let l = left as? String, let r = right as? String {
    	    	return normalizedDeviceKitName(l) == normalizedDeviceKitName(r)
	    	    	|| normalizedSupportComment(l) == normalizedSupportComment(r)
	    	}
	    	return areEqual(left, right)
    	}
		if key == "imageURL" { return true } // ignore differences in images
    	if key == "caseName" { return normalizedCaseName(left) == normalizedCaseName(right) }
	    if key == "description" || key == "safeDescription" {
	    	return normalizedDeviceKitName(left) == normalizedDeviceKitName(right)
	    }
	    if key == "screenRatio" {
		return screenRatiosEquivalent(left, right)
	    }
    	if key == "comment", let left = left as? String, let right = right as? String {
	    	return normalizedSupportComment(left) == normalizedSupportComment(right)
    	}
    	return areEqual(left, right)
	}

	func compatibleWhenMergedDiffers(_ key: String, left: Any?, merged: Any?, right: Any?) -> Bool {
	    if key == "screenRatio", right == nil, left != nil { return true }
	    // DeviceKit omits screen metadata for products such as HomePod. Keep the
	    // local screen definition and classify that source omission as yellow.
	    if key == "screen", left != nil, right == nil { return true }
	    // DeviceKit's rounded-corner field is known to be incomplete for several
	    // Apple Watch generations. Preserve Device's value and report the source
	    // omission as yellow while still treating a missing local value as red.
	    if key == "hasRoundedDisplayCorners",
	       left != nil,
	       right != nil { return true }
	    // A missing DeviceKit support identifier is source incompleteness. The
	    // inverse case (Device has unknownSupportId) remains red in DeviceBridge.
	    if key == "supportId",
	       let source = right as? String,
	       source == .unknownSupportId { return true }
	    // DeviceKit has several known display-size errors (especially Apple Watch
	    // entries).  A disagreement is therefore a source warning when both
	    // sources provide a diagonal; a missing local diagonal remains a real
	    // red conflict and is intentionally not covered by this exception.
	    if key == "diagonal",
	       let local = left as? Double,
	       let source = right as? Double,
	       local != 0,
	       source != 0 {
	        return true
	    }
	    guard key == "comment", let l = left as? String, let r = right as? String else { return false }
	    let leftURL = l.extract(from: "(http", to: ")")
	    let rightURL = r.extract(from: "(http", to: ")")
	    // A missing DeviceKit support URL is a source completeness warning. If
	    // both sides have links, normal resolution comparison remains strict.
	    return (leftURL == nil) != (rightURL == nil)
	}

	/// Compares screen ratios independent of portrait/landscape ordering while
	/// retaining enough precision to expose a genuinely incorrect ratio.
	private func screenRatiosEquivalent(_ left: Any?, _ right: Any?) -> Bool {
	    guard let lhs = left as? [Double], let rhs = right as? [Double], lhs.count == 2, rhs.count == 2,
	          lhs[0] != 0, lhs[1] != 0, rhs[0] != 0, rhs[1] != 0 else { return areEqual(left, right) }
	    let l = min(abs(lhs[0] / lhs[1]), abs(lhs[1] / lhs[0]))
	    let r = min(abs(rhs[0] / rhs[1]), abs(rhs[1] / rhs[0]))
	    return abs(l - r) <= 0.02
	}

	/// Applies the case-name spellings used by DeviceKit's generated source.
	private func normalizedCaseName(_ value: Any?) -> String {
    	guard let value = value as? String else { return String(describing: value) }
    	return value
	}

	/// Treats GPS suffixes and parenthetical inch labels as naming presentation differences.
    private func normalizedDeviceKitName(_ value: Any?) -> String {
        guard let value = value as? String else { return String(describing: value) }
			return value
			.replacingOccurrences(of: " (GPS + Cellular)", with: "")
			.replacingOccurrences(of: " (GPS)", with: "")
			.replacingOccurrences(of: "Ultra2", with: "Ultra 2")
			.replacingOccurrences(of: "  ", with: " ")
	    	.trimmed
	}

	/// Removes locale prefixes and equates the SP aliases that redirect to current numeric articles.
	private func normalizedSupportComment(_ value: String) -> String {
    	var result = value.replacingOccurrences(of: "/en-us/", with: "/")
    	// Device adds GPS qualifiers to Watch names while DeviceKit's source omits them so strip out.
    	result = result.replacingOccurrences(of: [
	    	" (GPS + Cellular)",
	    	" (GPS)",
	    	" (GPS",
    	], with: "")
    	let aliases = [
	    	"/kb/SP901": "/111831",
	    	"/kb/SP902": "/111830",
	    	"/kb/SP903": "/111829",
	    	"/kb/SP904": "/111828",
	    	"/kb/SP724": "/111928",
	    	"/kb/SP769": "/111929",
	    	"/kb/SP845": "/111922",
	    	"/kb/SP886": "/111839",
    	]
    	for (alias, numeric) in aliases { result = result.replacingOccurrences(of: alias, with: numeric) }
    	// fix unnecessary addendum from DeviceKit
    	result = result.replacingOccurrences(of: " (Previously Apple TV (4th generation))", with: "")
    	return result
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
	/// DeviceKit's eSIM field maps directly to Device's `.esim` capability.
	var hasEsimSupport: Bool
	/// DeviceKit distinguishes dual-eSIM hardware from devices with only one eSIM slot.
	var hasDualEsimSupport: Bool

	/// Keeps temporary upstream exceptions visible in generated reports while
	/// their source issues remain open and the comparison is intentionally yellow.
	var generateComment: String {
	    var report = deltaReport
	    if identifiers.contains(where: { ["iPad17,1", "iPad17,2", "iPad17,3", "iPad17,4"].contains($0) }) && applePencilSupport == 234 {
	        report += "\n\nDeviceKit Pencil encoding is tracked at https://github.com/devicekit/DeviceKit/issues/504."
	    }
	    if !hasRoundedDisplayCorners && identifiers.contains(where: { $0.hasPrefix("Watch") }) {
	        report += "\n\nDeviceKit rounded-corner metadata is tracked at https://github.com/devicekit/DeviceKit/issues/502."
	    }
	    return report
	}

	init(caseName: String, comment: String, imageURL: String, identifiers: [String], diagonal: Double, screenRatio: [Double]? = nil, description: String, safeDescription: String, ppi: Int, isPlusFormFactor: Bool, isPadMiniFormFactor: Bool, isPro: Bool, isXSeries: Bool, hasTouchID: Bool, hasFaceID: Bool, hasSensorHousing: Bool, supportsWirelessCharging: Bool, hasRoundedDisplayCorners: Bool, hasDynamicIsland: Bool, applePencilSupport: Int, hasForce3dTouchSupport: Bool, cameras: Int, hasLidarSensor: Bool, cpu: String, hasUSBCConnectivity: Bool, has5gSupport: Bool, hasEsimSupport: Bool = false, hasDualEsimSupport: Bool = false) {
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
	    self.hasEsimSupport = hasEsimSupport
	    self.hasDualEsimSupport = hasDualEsimSupport
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
	    // Positional archives predate eSIM support; current named records are
	    // accepted by the parser and retain their explicit value.
	    hasEsimSupport = fields.count > 26 ? (fields[26].boolValue ?? false) : false
	    hasDualEsimSupport = fields.count > 27 ? (fields[27].boolValue ?? false) : false
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
    	// Group-aware callers use mergedDevices; singular callers retain the first complete member.
    	if let member = groupedComparisons.first { return member.merged }
    	// massage values
    	var officialName = description
    	if caseName.contains("Apple Watch") {
	    	if let pos = caseName.lastIndex(of: " "), !caseName.contains("Ultra") {
    	    	let mm = caseName[pos..<caseName.endIndex]
    	    	officialName = officialName.replacingOccurrences(of: mm, with: "")
	    	}
	    	// Preserve the complete GPS/GPS + Cellular qualifier; truncating at the first
	    	// parenthesis produced malformed names such as "Apple Watch Series 3 (GPS".
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
    	if let screenRatio, screenRatio.count == 2, screenRatio[1] != 0 {
	    	let screenRatioValue = screenRatio[0] / screenRatio[1]
	    	let angle = atan(screenRatioValue) // Returns angle in radians
	    	let height = ppi.doubleValue * diagonal * cos(angle) // was sin, cos, but that seemed to be flipped of what we want.  Also forgot to multiply by ppi.
	    	let width = ppi.doubleValue * diagonal * sin(angle)
	    	if angle.isNaN || height.isNaN || width.isNaN {
    	    	// Don't add a screen
	    	} else {
    	    	let width = Int(width)
    	    	let height = Int(height)
    	    	let screen = Screen(diagonal: diagonal, resolution: (width, height), ppi: ppi)
    	    	if width.doubleValue == screenRatio[0] && height.doubleValue == screenRatio[1] {
	    	    	capabilities.screen = matched.screen
    	    	} else {
	    	    	capabilities.screen = screen
    	    	}
	    	}
	    	// TODO: Check the matched device's screen and use that if the ratio and ppi matches or is close enough just use that
    	}
    	if let cameraDevice = matched as? HasCameras {
	    	var cameras: Set<Camera> = []
	    	if cameraDevice.cameras.deviceKitNum == self.cameras {
    	    	cameras = cameraDevice.cameras
	    	} else {
    	    	cameras = .init(deviceKitNum: self.cameras)
	    	}
	    	capabilities.cameras = cameras
    	}

    	if isPlusFormFactor {
	    	if description.contains("Plus") {
    	    	capabilities.insert(.plus)
	    	}
		if description.contains("Max") {
    	    	capabilities.insert(.max)
	    	}
	    	if description.contains("Air") {
    	    	capabilities.insert(.air)
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
		// Apple documents only Apple Pencil (USB-C) and Apple Pencil Pro for
		// M5 iPad Pro. DeviceKit's 234 also adds unsupported Pencil 2 support,
		// so preserve the verified local capability set for this source issue.
		let isM5IPad = identifiers.contains { ["iPad17,1", "iPad17,2", "iPad17,3", "iPad17,4"].contains($0) }
		if matched.idiom == .pad, isM5IPad {
		    capabilities.pencils = matched.capabilities.pencils
		} else {
		    capabilities.pencils = .init(deviceKitPencilSupport: applePencilSupport)
		}
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
	    if hasEsimSupport {
		capabilities.insert(.esim)
	    }
	    if hasDualEsimSupport {
		capabilities.insert(.dualesim)
	    }

		var converted = Device(
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

	    // eSIM support is a hardware fact. Replace the additive merge result so
	    // a bad local eSIM claim is reported as a real mismatch (red).
		var finalCapabilities = converted.capabilities
	    finalCapabilities.remove(.esim)
	    finalCapabilities.remove(.dualesim)
	    if hasEsimSupport { finalCapabilities.insert(.esim) }
	    if hasDualEsimSupport { finalCapabilities.insert(.dualesim) }

	    // Preserve Device's canonical pad/watch screen while retaining DeviceKit's
	    // raw ratio in the bridge row.  DeviceKit's known diagonal/ppi errors are
	    // presentation warnings; the local hardware definition remains canonical.
	    if matched.idiom == .pad || matched.idiom == .watch {
		finalCapabilities.screen = matched.screen
	    }
	    converted = Device(idiom: converted.idiom, officialName: converted.officialName,
		identifiers: converted.identifiers, introduction: converted.introduction,
		supportId: converted.supportId, launchOSVersion: converted.launchOSVersion,
		unsupportedOSVersion: converted.unsupportedOSVersion, image: converted.image,
		capabilities: finalCapabilities, models: converted.models,
		colors: converted.colors, cpu: converted.cpu)

	    return converted
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
    	    	officialName = officialName.replacingOccurrences(of: ["SE 3 (GPS)","SE 3 (GPS + Cellular)"], with: "SE (3rd generation)")
					.replacingOccurrences(of: " SE 2 (GPS)", with: " SE (2nd generation)")
    	    	officialName = officialName.replacingOccurrences(of: [String(mm), " (GPS)"], with: "")
	    	}
	    	caseName = caseName.replacingOccurrences(of: "Apple Watch", with: "apple Watch")
	    	caseName = caseName.replacingOccurrences(of: "(1st generation)", with: "Series0")
	    	// Keep the full GPS qualifier so generated comments remain valid Markdown and names.
    	}
    	if officialName.contains("Apple TV") {
	    	officialName = officialName.replacingOccurrences(of: " (1st generation)", with: "")
    	}
    	if idiom == .watch {
	    	let watch = AppleWatch(knownDevice: device)
	    	officialName += " \(watch.watchSize.mm)"
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
		caseName = caseName.replacingOccurrences(of: "1Inch", with: "1INCH")
		caseName = caseName.replacingOccurrences(of: "2Inch", with: "2INCH")
    	caseName = caseName.replacingOccurrences(of: "-inch", with: "Inch")
    	caseName = caseName.replacingOccurrences(of: "(", with: "")
    	caseName = caseName.replacingOccurrences(of: ")", with: "")
    	caseName = caseName.replacingOccurrences(of: "ndgeneration", with: "")
    	caseName = caseName.replacingOccurrences(of: "rdgeneration", with: "")
    	caseName = caseName.replacingOccurrences(of: "thgeneration", with: "")
    	caseName = caseName.replacingOccurrences(of: "Inch", with: "")
		caseName = caseName.replacingOccurrences(of: "1INCH", with: "1Inch") // 12s and 11s cases do have the Inch word.
		caseName = caseName.replacingOccurrences(of: "2INCH", with: "2Inch")
    	caseName = caseName.replacingOccurrences(of: "GPS+Cellular", with: "")
    	caseName = caseName.replacingOccurrences(of: "GPS_", with: "_")
		caseName = caseName.replacingOccurrences(of: "Wi-Fi+Ethernet", with: "")

    	officialName = officialName.replacingOccurrences(of: " 11-inch", with: " (11-inch)")
    	officialName = officialName.replacingOccurrences(of: " 13-inch", with: " (13-inch)")
	    	officialName = officialName.replacingOccurrences(of: " 12.9-inch", with: " (12.9-inch)")
	    	.replacingOccurrences(of: " Wi-Fi + Ethernet", with: "")
    	if officialName == "iPhone SE (1st generation)" {
	    	officialName = "iPhone SE"
    	}
    	officialName = officialName.replacingOccurrences(of: "Watch SE 2", with: "Watch SE (2nd generation)")

    	var supportName = officialName
    	if device.idiom == .watch {
	    	var parts = officialName.split(separator: " ")
	    	parts.removeLast()
	    	supportName = parts.joined(separator: " ")
	    	if officialName.contains("Ultra") {
    	    	officialName = supportName
	    	}
    	}

    	var comments = "Device is a\(officialName[officialName.startIndex].isVowel() ? "n" : "") [\(supportName)](\(device.supportURL))"
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
    	comments = comments.replacingOccurrences(of: "Ultra 2 (GPS + Cellular)", with: "Ultra2")
    	officialName = officialName.replacingOccurrences(of: "Ultra 2", with: "Ultra2")
    	safeOfficialName = safeOfficialName.replacingOccurrences(of: "Ultra 2", with: "Ultra2")

    	var imageURL = device.image ?? ""
		// we typically want to ignore changes to images since the ones we have are more likely to be right, but that is handled by the compatible check and shouldn't be erased here
		if caseName == "homePod" {
			imageURL = "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/SP773/homepod_space_gray_large_2x.jpg" // use different version
		}


    	let screen = device.screen // use capabilities version, not local variable version
    	var diagonal = screen?.diagonal ?? 0
    	if diagonal == 1.65 {
	    	diagonal = 1.6
    	}
    	var ppi = screen?.ppi ?? -1
    	if idiom == .homePod {
	    	diagonal = -1
	    	ppi = -1
    	}
    	var ratio: [Double]?
    	if let screenRatio = screen?.resolution.ratio {
	    	ratio = [screenRatio.width.doubleValue, screenRatio.height.doubleValue]
    	}
    	if idiom == .tv {
	    	ratio = nil
    	}
    	if [8, 13, 14].contains(Int(device.identifiers.first?.identifierNumber ?? -1)) {
	    	if ratio == [3, 4] {
    	    	ratio = [512, 683]
	    	}
	    	if ratio == [512.0, 683.0] {
    	    	ratio = [41.0, 59.0]
	    	}
    	}
	    // Keep DeviceKit's raw dimensions here; `toDevice` retains the local
	    // canonical screen so this remains a visible compatible source delta.
    	// ignore cameras

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
	    	isPlusFormFactor: device.is(.plus) || device.is(.max) || (device.idiom == .phone && device.is(.air)),
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
		has5gSupport: device.cellular == .fiveG,
		hasEsimSupport: device.has(.esim),
		hasDualEsimSupport: device.has(.dualesim))
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
	    	// Double already prints a decimal point; appending another produced
	    	// invalid Python such as 11.0.0 and broke exported-record round trips.
	    	diagonal = "\(Int(selfDiagonal)).0"
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

    	// Emit keyword-only capabilities and CPU for the current upstream constructor.
    	// Use a quoted safeDescription literal so the exported record can be parsed again.
    	return """
\(prefix)Device(\(preSpace)\(caseName.definition),\(nameSpace)\(comment.definition),\(commentSpace)\(imageURL.definition),\(imageSpace)\(identifiers),\(identifiersSpace)\(diagonal),\(diagonalSpace)\(ratio),\(ratioSpace)\(description.definition), \(safeDescription.definition), \(ppi), isPlusFormFactor=\(isPlusFormFactor.deviceKitDefinition), isPadMiniFormFactor=\(isPadMiniFormFactor.deviceKitDefinition), isPro=\(isPro.deviceKitDefinition), isXSeries=\(isXSeries.deviceKitDefinition), hasTouchID=\(hasTouchID.deviceKitDefinition), hasFaceID=\(hasFaceID.deviceKitDefinition), hasSensorHousing=\(hasSensorHousing.deviceKitDefinition), supportsWirelessCharging=\(supportsWirelessCharging.deviceKitDefinition), hasRoundedDisplayCorners=\(hasRoundedDisplayCorners.deviceKitDefinition), hasDynamicIsland=\(hasDynamicIsland.deviceKitDefinition), applePencilSupport=\(applePencilSupport), hasForce3dTouchSupport=\(hasForce3dTouchSupport.deviceKitDefinition), cameras=\(cameras), hasLidarSensor=\(hasLidarSensor.deviceKitDefinition), cpu=\(cpu.definition), hasUSBCConnectivity=\(hasUSBCConnectivity.deviceKitDefinition), has5gSupport=\(has5gSupport.deviceKitDefinition), hasEsimSupport=\(hasEsimSupport.deviceKitDefinition), hasDualEsimSupport=\(hasDualEsimSupport.deviceKitDefinition)),
"""
	}
}

/// Reads DeviceKit's Python literal records without executing downloaded Python.
/// Both the legacy positional schema and the keyword schema map to the same Codable bridge.
private enum DeviceKitDefinitionParser {
	// Retain the legacy field order so archived definitions can still be compared.
	static let fields = [
    	"caseName", "comment", "imageURL", "identifiers", "diagonal", "screenRatio",
    	"description", "safeDescription", "ppi", "isPlusFormFactor", "isPadMiniFormFactor",
    	"isPro", "isXSeries", "hasTouchID", "hasFaceID", "hasSensorHousing",
    	"supportsWirelessCharging", "hasRoundedDisplayCorners", "hasDynamicIsland",
    	"applePencilSupport", "hasForce3dTouchSupport", "cameras", "hasLidarSensor",
		"cpu", "hasUSBCConnectivity", "has5gSupport", "hasEsimSupport", "hasDualEsimSupport"
	]

	/// Reports schema changes as visible loader errors instead of silently returning an empty catalog.
	struct ParseError: LocalizedError {
    	let reason: String
    	var errorDescription: String? { "DeviceKit definition: \(reason)" }
	}

	static func devices(in code: String) throws -> [DeviceKitDevice] {
    	// Anchor at a record's line start to avoid Swift examples and Python helper calls.
    	let pattern = try NSRegularExpression(pattern: #"(?m)^[ \t]*Device\("#)
    	let matches = pattern.matches(in: code, range: NSRange(code.startIndex..., in: code))
    	guard !matches.isEmpty else { throw ParseError(reason: "No Device records found.") }
    	return try matches.map { match in
	    	let range = Range(match.range, in: code)!
	    	let arguments = try arguments(in: code[range.upperBound...])
	    	do {
    	    	var values = [String: Any]()
    	    	var position = 0
    	    	var hasKeywords = false
    	    	for argument in arguments {
	    	    	let key: String
	    	    	let literal: String
	    	    	// An equals sign inside a quoted URL or comment is data, not a keyword separator.
	    	    	if let equals = argument.firstIndex(of: "="),
	    	    	   argument[..<equals].allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" || $0.isWhitespace }) {
    	    	    	hasKeywords = true
    	    	    	key = String(argument[..<equals]).trimmed
    	    	    	literal = String(argument[argument.index(after: equals)...]).trimmed
	    	    	} else {
    	    	    	guard !hasKeywords, position < fields.count else {
	    	    	    	throw ParseError(reason: "Unexpected positional argument.")
    	    	    	}
    	    	    	key = fields[position]
    	    	    	literal = argument
    	    	    	position += 1
	    	    	}
	    	    	guard fields.contains(key), values[key] == nil else {
    	    	    	throw ParseError(reason: "Unknown or duplicate argument \(key).")
	    	    	}
	    	    	values[key] = try value(literal)
    	    	}
    	    	if hasKeywords {
	    	    	guard position <= 9 else { throw ParseError(reason: "Only the first nine fields may be positional in keyword records.") }
	    	    	// Mirror upstream's documented defaults; required metadata and CPU are never invented.
	    	    	for field in fields.dropFirst(9) where field != "cpu" && values[field] == nil {
    	    	    	values[field] = ["applePencilSupport", "cameras"].contains(field) ? 0 : false
	    	    	}
    	    	}
    	    	guard fields.allSatisfy({ values[$0] != nil }) else {
	    	    	throw ParseError(reason: "Missing required fields: \(fields.filter { values[$0] == nil }.joined(separator: ", ")).")
    	    	}
    	    	let json = try JSONSerialization.data(withJSONObject: values)
    	    	var device = try JSONDecoder().decode(DeviceKitDevice.self, from: json)
    	    	// Preserve the old initializer's no-screen representation. Downstream
    	    	// ratio comparisons index two elements whenever this optional is present.
    	    	if device.screenRatio?.isEmpty == true { device.screenRatio = nil }
    	    	guard device.screenRatio == nil || device.screenRatio?.count == 2 else {
	    	    	throw ParseError(reason: "Screen ratio must be empty or contain two values.")
    	    	}
    	    	return device
	    	} catch {
    	    	throw ParseError(reason: "\(arguments.first ?? "unnamed record"): \(error)")
	    	}
    	}
	}

	/// Splits only top-level commas and stops at the matching closing parenthesis.
	/// Quoted punctuation, escapes, multiline Watch records, tuples, lists and comments remain intact.
	private static func arguments(in source: Substring) throws -> [String] {
    	var arguments = [String]()
    	var token = ""
    	var delimiters = [Character]()
    	var quoted = false
    	var escaped = false
    	var comment = false
    	for character in source {
	    	if comment {
    	    	if character == "\n" { comment = false; token.append(" ") }
    	    	continue
	    	}
	    	if quoted {
    	    	token.append(character)
    	    	if escaped { escaped = false }
    	    	else if character == "\\" { escaped = true }
    	    	else if character == "\"" { quoted = false }
    	    	continue
	    	}
	    	switch character {
	    	case "#": comment = true
	    	case "\"": quoted = true; token.append(character)
	    	case "[", "(": delimiters.append(character); token.append(character)
	    	case "]", ")":
    	    	if character == ")", delimiters.isEmpty {
	    	    	if !token.trimmed.isEmpty { arguments.append(token.trimmed) }
	    	    	return arguments
    	    	}
    	    	guard delimiters.popLast() == (character == "]" ? "[" : "(") else {
	    	    	throw ParseError(reason: "Unbalanced literal delimiters.")
    	    	}
    	    	token.append(character)
	    	case "," where delimiters.isEmpty:
    	    	guard !token.trimmed.isEmpty else { throw ParseError(reason: "Empty argument.") }
    	    	arguments.append(token.trimmed)
    	    	token = ""
	    	default: token.append(character)
	    	}
    	}
    	throw ParseError(reason: "Unterminated Device record.")
	}

	/// Converts the limited Python literals in the catalog to JSON; unsupported expressions fail safely.
	private static func value(_ literal: String) throws -> Any {
    	var json = literal
    	switch literal {
    	case "True": json = "true"
    	case "False": json = "false"
    	case "None": json = "null"
    	default:
	    	if literal.hasPrefix("("), literal.hasSuffix(")") {
    	    	// Screen ratios are Python tuples; the empty TV tuple represents no screen.
    	    	json = "[\(literal.dropFirst().dropLast())]"
	    	}
    	}
    	return try JSONSerialization.jsonObject(with: Data(json.utf8), options: .fragmentsAllowed)
	}
}

struct DeviceKitLoader: DeviceBridgeLoader {
	let sourceURL = "https://raw.githubusercontent.com/devicekit/DeviceKit/refs/heads/master/Source/Device.swift.gyb"
	let name = "DeviceKit"

	func devices() async throws -> [DeviceKitDevice] {
    	let code = try await fetchURL(urlString: sourceURL)
    	return try Self.parse(code)
	}

	/// Parses a downloaded or archived catalog, retaining local GPS/cellular definition boundaries.
	static func parse(_ code: String) throws -> [DeviceKitDevice] {
    	// Preserve upstream grouping and let the common bridge layer resolve its members.
    	try DeviceKitDefinitionParser.devices(in: code)
	}

	// For generating a new file based on our data in case we want to submit a pull request?
//  func generate() async -> String {
//	  return Device.allDevices.map { DeviceKitDevice($0).source }.joined(separator: "\n")
//  }
}

private extension DeviceKitDevice {
	/// Splits a combined DeviceKit row according to existing local definition
	/// boundaries. Source identifier order is retained within and across groups.
	func splitByLocalDefinitions() -> [DeviceKitDevice] {
    	// Historical helper retained as a delegate; grouping policy now lives in
    	// DeviceBridge and requires shared support metadata for every known member.
    	let members = groupedComparisons
    	return members.isEmpty ? [self] : members
	}
}


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
//    	device.upgrade()
	    	let idiom = device.idiom.label
	    	if idiom != lastIdiom {
    	    	deviceList += "	 ]\n\n\(idiom)s = [\n"
    	    	lastIdiom = idiom
	    	}
	    	deviceList += device.idiomatic[keyPath: printProperty] + ",\n"
	    	// TODO: See if we have another way since idiomatic is internal.
//    	let str = device.idiomatic[keyPath: printProperty]
//    	if str != "" {// skip blank macs.
//	    	print(str)
//    	}
    	}
    	return deviceList
	}
	static func exportDeviceKitDefinitions() -> String {
    	var definitionString = """
    	%{
    	class Device:
	  def __init__(self, caseName, comment, imageURL, identifiers, diagonal, screenRatio, description, safeDescription, ppi, isPlusFormFactor, isPadMiniFormFactor, isPro, isXSeries, hasTouchID, hasFaceID, hasSensorHousing, supportsWirelessCharging, hasRoundedDisplayCorners, hasDynamicIsland, applePencilSupport, hasForce3dTouchSupport, cameras, hasLidarSensor, cpu, hasUSBCConnectivity, has5gSupport, hasEsimSupport=False, hasDualEsimSupport=False):
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
			self.hasEsimSupport = hasEsimSupport
			self.hasDualEsimSupport = hasDualEsimSupport

    	# iOS
    	ignore = [
    	"""
    	definitionString += printAllDevices(printProperty: \.deviceKitDefinition, sortFunc: { $0.deviceKitSortKey < $1.deviceKitSortKey })

    	return definitionString
	}
	/// Extract the current order for saving and preserving the DeviceKit order (which isn't in identifier order which is preferable)
//  static func createOrder() {
//	  for var device in iPad.all.sorted(by: { $0.identifierSortKey < $1.identifierSortKey
//	  }) {
//    	if !device.has(.usbC) {
//	    	// make sure to add in lighting connector where missing
//	    	device.device.capabilities.insert(.lightning)
//	    	// TODO: Re-enable above by doing a new device with the additional capability?
//    	}
//    	print("\(device.definition)")
//	  }
//  }




//  static func convertMacs() -> String {
//	  let macsRaw = """
//[
//  {
//	  "models" : [
//    	"iMac21,2"
//	  ],
//	  "kind" : "iMac",
//	  "colors" : [
//    	"silverLight",
//    	"pinkLight",
//    	"blueLight",
//    	"greenLight"
//	  ],
//	  "name" : "iMac (24-inch, M1, 2021)",
//	  "variant" : "24-inch, M1, 2021",
//	  "parts" : [
//    	"MGTF3xx/a",
//    	"MJV83xx/a",
//    	"MJV93xx/a",
//    	"MJVA3xx/a"
//	  ]
//  }
//]
//"""
//	  let json = macsRaw.data(using: .utf8)!
//	  let decoder = JSONDecoder()
//	  let macs = (try? decoder.decode([MacLookup].self, from: json)) ?? []
//	  //print(String(describing: macs))
//	  var outputString = ""
//	  for mac in macs {
////	    	outputString += mac.asMacLookup().device.definition + "\n"
//	  }
//	  return outputString
//  }
}
*/
#endif
