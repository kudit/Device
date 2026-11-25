// Apple-specific material swatches and grouped product color sets.
import Color

public typealias AMC = AppleMaterialColor

public struct AppleMaterialColor: Sendable, Codable, Hashable {
	public var swatches: [String]
	public var name: String
	/// CSS identifiers in Apple's comparison page, retained so conversion
	/// proposals can produce stable source names instead of losing provenance.
	public var cssKeys: [String]

	public init(swatches: [String], name: String, cssKeys: [String] = []) {
		self.swatches = swatches
		self.name = name
		self.cssKeys = cssKeys
	}
}
extension AppleMaterialColor: Identifiable {
	public var id: String {
		String(describing: self)
	}
}
public extension AppleMaterialColor {
	init(_ swatch: String, _ name: String) {
		self.init(swatches: [swatch], name: name)
	}

	init(_ swatches: [String], _ name: String) {
		self.init(swatches: swatches, name: name)
	}

	static let namedColors = {
		var namedColors = [String: [AppleMaterialColor]]()
		for color in [AppleMaterialColor].all {
			// initialize the entry or append to the existing entry.
			var existing = namedColors[color.name] ?? []
			existing.append(color)
			namedColors[color.name] = existing
		}
		return namedColors
	}()

	/// Attempt to identify the correct color from the name.  Context is provided to aid in determining variant when multiple exist.
	init(named string: String, context: String) {
		let mapped = [AppleMaterialColor].allMatching(string)
		guard !mapped.isEmpty else {
			debug("Unknown color string: \"\(string)\"", level: .ERROR)
			#if DEBUG
            debug("Unmapped Apple color '\(string)' for context '\(context)'. Inspect the caller before applying the Silver fallback.", level: .WARNING)
			#endif
			self = .silverLight
			return
		}
		// Try to pick the correct color for the device based on context
		// This also handles iMac light/dark variants and Silver correctly by
		// intersecting candidates with the matched model's actual color set. The
		// former year-based iMac shortcut selected the first generic Silver entry,
		// which is Apple Watch aluminumSilver rather than Mac solidSilver. Device
		// context must also take precedence when global name lookup has only one
		// candidate, such as iPhone Silver versus Mac solid Silver.
		let matched = Device.lookup(officialNameHint: context)
		var knownColors = [AppleMaterialColor]()
		for device in matched {
			for color in device.colors {
				if mapped.contains(color) {
					self = color
					return
				}
			}
			knownColors += device.colors
		}
		guard mapped.count > 1 else {
			self = mapped.first!
			return
		}
		// unknown color and unable to match the device.  just pick the first
		debug("Could not find color string \"\(string)\" for device context \"\(context)\" (known colors: \(knownColors.map { String(describing: $0.swatches) }.joined(separator: ", "))", level: .ERROR)
		self = mapped.first!
		//    if context.models.containsAny(["MacBook10,1", "MacBook9,1", "MacBook8,1", "Mac16,13", "Mac16,12", "Mac15,13", "Mac15,12", "Mac14,15"]) {
		//      key += "2024" // for solidSilver
		//    }
		//    if key == "Space Black" {
		//      key = "Space Gray"
		//    }
		//    if string == "Space Gray" {
		//      if form.hasBattery {
		//        return .macbookSpacegray
		//      } else {
		//        return .macSpacegray
		//      }
		//    }
	}

	func colors<C: KuColor>() -> [C] {
		swatches.map { C(string: $0, defaultColor: .grayFixed) }
	}
}
#if canImport(SwiftUI)
import SwiftUI
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension AppleMaterialColor {
	var legacyColor: Color { //TODO: This should be refactored to become unnecessary
		return colors().first!
	}
	/// Renders swatches as equal-height vertical bands with hard transitions.
	/// Duplicate stop locations prevent SwiftUI from interpolating between swatches.
	var leftToRightGradient: LinearGradient {
		LinearGradient(stops: hardStops(colors: colors()), startPoint: .leading, endPoint: .trailing)
	}

	/// Builds equal-width hard stops while preserving the catalog's swatch order.
	func hardStops(colors: [Color]) -> [Gradient.Stop] {
		guard colors.count > 1 else {
			return colors.enumerated().map { Gradient.Stop(color: $0.element, location: 0) }
		}
		let width = 1 / Double(colors.count)
		// Duplicate each boundary stop to produce Apple's hard-edged two-tone swatch.
		return colors.enumerated().flatMap { index, color in
			let start = Double(index) * width
			let end = Double(index + 1) * width
			return [
				Gradient.Stop(color: color, location: start),
				Gradient.Stop(color: color, location: end),
			]
		}
	}
}
#endif

public extension String {
	static let productRed = "(PRODUCT)RED" // Red - (PRODUCT)<sup>RED</sup>
}
public extension [AppleMaterialColor] {
	static let `default` = [AppleMaterialColor.black]
}

// standard colors
public extension AppleMaterialColor {
	static let black = AMC("#000000", "Black") // Black/jet black/Space Black") // complete black for default color
	static let jetBlack = AMC("#000000", "Jet Black") // Black/jet black/Space Black") // complete black for default color
	static let blackSet = [black]

	static let white = AMC("#FFFFFF", "White") // complete white for default white plastic color
	static let whiteSet = [white]

	static let solidSilver = AMC("#e3e4e5", "Silver") // macbookSilver
	static let legacySilverMacs = [solidSilver]

	static let spaceblack = AMC("#2e2c2e", "Space Black") // macbook spaceblack

	static let silver = AMC("#c7c8ca", "Silver")
	static let macSpacegray = AMC("#7a7b80", "Space Gray")

	// HomeView
	static let homeStarlight = AMC("#E9E1D6", "Starlight")
	static let homeRosePink = AMC("#E2D5D2", "Rose Pink")
	static let homeSpaceGray = AMC("#B4B4B8", "Space Gray")
}
public extension [AppleMaterialColor] {
	static let blackSet = AMC.blackSet
	static let whiteSet = AMC.whiteSet
	static let legacySilverMacs = AMC.legacySilverMacs
	static let basicColorSets = [
		AMC.blackSet: "blackSet",
		.whiteSet: "whiteSet",
		.legacySilverMacs: "legacySilverMacs",
	]
}

// MARK: - Macs
// MacBook Pro
public extension AppleMaterialColor {
	static let macbookSpaceGraySet = [solidSilver, macbookSpacegray]
    static let mseriesMacbookPros = [solidSilver, spaceblack]
}
public extension [AppleMaterialColor] {
	static let macbookSpaceGraySet = AMC.macbookSpaceGraySet
    static let mseriesMacbookPros = AMC.mseriesMacbookPros
	static let macbookProColorSets = [
        AMC.macbookSpaceGraySet: "macbookSpaceGraySet",
        .mseriesMacbookPros: "mseriesMacbookPros",
	]
}

// iMac
public extension AppleMaterialColor {
	static let silverLight = AMC("#d9dadb", "Silver") // Mac Studio 2025
	static let silverSet = [silverLight]
}
public extension [AppleMaterialColor] {
	static let silverSet = AMC.silverSet
}

public extension AppleMaterialColor {
    // iMac M1—M3
    static let iMacBlue = AMC(["#26476d", "#a8bed2"], "Blue")
	static let iMacGreen = AMC(["#10505b", "#a3beb4"], "Green")
	static let iMacPink = AMC(["#b62c31", "#edb9af"], "Pink")
	static let iMacSilver = AMC(["#c7c8ca", "#d9dadb"], "Silver")
	static let iMacYellow = AMC(["#e0901a", "#e9ca95"], "Yellow")
	static let iMacOrange = AMC(["#e86740", "#e9aa95"], "Orange")
	static let iMacPurple = AMC(["#353b71", "#acaccb"], "Purple")
	static let iMac2Ports = [iMacGreen, iMacPink, iMacBlue, iMacSilver]
	static let iMac = [iMacGreen, iMacYellow, iMacOrange, iMacPink, iMacPurple, iMacBlue, iMacSilver]

    // iMac 2024 (goes along with pale versions)
	static let iMacBlue4 = AMC(["#547eae", "#acbfd8"], "Blue")
	static let iMacPurple4 = AMC(["#827eb2", "#b8b2cf"], "Purple")
	static let iMacPink4 = AMC(["#de5f7d", "#f3b5c3"], "Pink")
	static let iMacOrange4 = AMC(["#e3704b", "#f5c1a7"], "Orange")
	static let iMacYellow4 = AMC(["#edd142", "#f5E4ae"], "Yellow")
	static let iMacGreen4 = AMC(["#3e935c", "#a4c2ae"], "Green")
	static let iMac2024 = [iMacPink4, iMacOrange4, iMacYellow4, iMacGreen4, iMacBlue4, iMacPurple4, solidSilver]
    static let iMac2026 = [iMacBlue4, iMacPurple4, iMacPink4, iMacOrange4, iMacYellow4, iMacGreen4, solidSilver]
}
public extension [AppleMaterialColor] {
	static let iMac2Ports = AMC.iMac2Ports
	static let iMac = AMC.iMac
    static let iMac2024 = AMC.iMac2024
    static let iMac2026 = AMC.iMac2026
}

private extension [AppleMaterialColor] {
	static let iMacColorSets = [
		AMC.silverSet: "silverSet",
		.iMac2Ports: "iMac2Ports",
		.iMac: "iMac",
        .iMac2024: "iMac2024",
        .iMac2026: "iMac2026",
	]
}

// MacBook
public extension AppleMaterialColor {
	static let macbookSpacegray = AMC("#7d7e80", "Space Gray")
	static let macbookGold = AMC("#F9D4C2", "Gold")
	static let macbookRoseGold = AMC("#E1C3C8", "Rose Gold")
	static let macbookGoldSet = [macbookSpacegray, macbookGold, solidSilver]
	static let macbookRoseGoldSet = [macbookRoseGold, macbookSpacegray, macbookGold, solidSilver]
}
public extension [AppleMaterialColor] {
	static let macbookGoldSet = AMC.macbookGoldSet
	static let macbookRoseGoldSet = AMC.macbookRoseGoldSet
}

private extension [AppleMaterialColor] {
	static let macbookColorSets = [
		AMC.macbookGoldSet: "macbookGoldSet",
		.macbookRoseGoldSet: "macbookRoseGoldSet",
	]
}

// MacBook Air
public extension AppleMaterialColor {
	static let macbookairMidnight = AMC("#2e3642", "Midnight")
	static let macbookairStarlight = AMC("#f0e4d3", "Starlight")
	static let macbookAirMidnightSet = [solidSilver, macbookairStarlight, macbookSpacegray, macbookairMidnight]
}
public extension [AppleMaterialColor] {
	static let macbookAirMidnightSet = AMC.macbookAirMidnightSet
}
public extension AppleMaterialColor {
	static let macbookairSkyblue = AMC("#c8d8e0", "Sky Blue")
	static let macbookAirSkyBlueSet = [solidSilver, macbookairStarlight, macbookairSkyblue, macbookairMidnight]
}
public extension [AppleMaterialColor] {
	static let macbookAirSkyBlueSet = AMC.macbookAirSkyBlueSet
}

private extension [AppleMaterialColor] {
	static let macbookAirColorSets = [
		AMC.macbookAirMidnightSet: "macbookAirMidnightSet",
		.macbookAirSkyBlueSet: "macbookAirSkyBlueSet",
	]
}

// MacBook Neo
public extension AppleMaterialColor {
	static let blush = AMC("#e8d0d0", "Blush")
	static let citrus = AMC("#dddc8c", "Citrus")
	static let indigo = AMC("#596680", "Indigo")
	static let macbookNeo = [solidSilver, blush, citrus, indigo]
}
public extension [AppleMaterialColor] {
	static let macbookNeo = AMC.macbookNeo
}

private extension [AppleMaterialColor] {
	static let macColorSets = macbookProColorSets + iMacColorSets + macbookColorSets + macbookAirColorSets + [
		.macbookNeo: "macbookNeo",
	]
}

// MARK: - iPod Touches
// iPod Touch
public extension AMC {
	static let iPodTouch = [silver]
}
public extension [AppleMaterialColor] {
	static let iPodTouch = AMC.iPodTouch
}

// iPod Touch (5th generation)
public extension AppleMaterialColor {
	static let iPodBlack = AMC("#4d5663", "Black")
	static let iPodSilver = AMC("#c9cbca", "Silver")
	static let iPodPink = AMC("#fb797e", "Pink")
	static let iPodYellow = AMC("#cace39", "Yellow")
	static let iPodBlue = AMC("#26c4e5", "Blue")
	static let iPodTouch5thGen = [iPodBlack, iPodSilver, iPodPink, iPodYellow, iPodBlue]
}
public extension [AppleMaterialColor] {
	static let iPodTouch5thGen = AMC.iPodTouch5thGen
}

// iPod Touch (6th generation)
public extension AppleMaterialColor {
	static let iPodBlack6 = AMC("#68686e", "Black")
	static let iPodGold6 = AMC("#e3cfb9", "Gold")
	static let iPodSilver6 = AMC("#d0d3d0", "Silver")
	static let iPodPink6 = AMC("#fd4193", "Pink")
	static let iPodBlue6 = AMC("#357ed3", "Blue")
	static let iPodTouch6thGen = [iPodBlack6, iPodGold6, iPodSilver6, iPodPink6, iPodBlue6]
}
public extension [AppleMaterialColor] {
	static let iPodTouch6thGen = AMC.iPodTouch6thGen
}

// iPod Touch (7th generation)
public extension AppleMaterialColor {
	static let iPodProductRed = AMC("#ed3135", .productRed)
	static let iPodTouch7thGen = [iPodProductRed, iPodBlack6, iPodGold6, iPodSilver6, iPodPink6, iPodBlue6]
}
public extension [AppleMaterialColor] {
	static let iPodTouch7thGen = AMC.iPodTouch7thGen
}

private extension [AppleMaterialColor] {
	static let ipodColorSets = [
		AMC.iPodTouch: "iPodTouch",
		.iPodTouch5thGen: "iPodTouch5thGen",
		.iPodTouch6thGen: "iPodTouch6thGen",
		.iPodTouch7thGen: "iPodTouch7thGen",
	]
}

// MARK: - iPhones
// iPhone 3GS—5
public extension AppleMaterialColor {
	static let iPhoneBW = [black, white]
}
public extension [AppleMaterialColor] {
	static let iPhoneBW = AMC.iPhoneBW
}

// iPhone 5c
public extension AppleMaterialColor {
	static let green5c = AMC("#96e264", "Green")
	static let blue5c = AMC("#41b1eb", "Blue")
	static let yellow5c = AMC("#feef6e", "Yellow")
	static let pink5c = AMC("#ff6d6e", "Pink")
	static let white5c = AMC("#f0f0f2", "White")
	static let iPhone5c = [green5c, blue5c, yellow5c, pink5c, white5c]
}
public extension [AppleMaterialColor] {
	static let iPhone5c = AMC.iPhone5c
}

// SE 1
public extension AppleMaterialColor {
	static let silverSE = AMC("#e4e4e2", "Silver")
	static let spaceGraySE = AMC("#262529", "Space Gray")
	static let blackSE2 = AMC("#262529", "Black")
	static let goldSE = AMC("#fadcc2", "Gold")
	static let roseGoldSE = AMC("#ecc6c1", "Rose Gold")
	static let iPhoneSE = [silverSE, spaceGraySE, goldSE, roseGoldSE]
}
public extension [AppleMaterialColor] {
	static let iPhoneSE = AMC.iPhoneSE
}

// iPhone 6
public extension AppleMaterialColor {
	static let silver6 = AMC("#e2e3e4", "Silver")
	static let spaceGray6 = AMC("#b1b2b7", "Space Gray")
	static let gold6 = AMC("#e3ccb4", "Gold")
	static let iPhone6 = [spaceGray6, silver6, gold6]
}
public extension [AppleMaterialColor] {
	static let iPhone6 = AMC.iPhone6
}

// iPhone 6s
public extension AppleMaterialColor {
	static let iPhone6s = [silver6, spaceGray6, gold6, roseGoldSE]
}
public extension [AppleMaterialColor] {
	static let iPhone6s = AMC.iPhone6s
}

// iPhone 7
public extension AppleMaterialColor {
	static let black7 = AMC("#2e3034", "Black")
	static let iPhone7 = [silver6, black7, gold6, roseGoldSE, jetBlack, iPodProductRed] // included jet black and PRODUCT RED models
}
public extension [AppleMaterialColor] {
	static let iPhone7 = AMC.iPhone7
}

// iPhone 8
public extension AppleMaterialColor {
	static let spaceGray8 = AMC("#272729", "Space Gray")
	static let gold8 = AMC("#f7e8dd", "Gold")
	static let iPhone8 = [silver6, spaceGray8, gold8, redXʀ]
}
public extension [AppleMaterialColor] {
	static let iPhone8 = AMC.iPhone8
}

// iPhone X
public extension AppleMaterialColor {
	static let iPhoneX = [silverSE, spaceGraySE]
}
public extension [AppleMaterialColor] {
	static let iPhoneX = AMC.iPhoneX
}

// iPhone Xʀ
public extension AppleMaterialColor {
	static let blueXʀ = AMC("#48aee6", "Blue")
	static let whiteXʀ = AMC("#f3f3f3", "White")
	static let yellowXʀ = AMC("#f9d045", "Yellow")
	static let coralXʀ = AMC("#ff6e5a", "Coral")
	static let redXʀ = AMC("#b41325", .productRed)
	// Keep every iPhone XR swatch in a named set for generation and registry lookup.  Keep in photo order.
	static let iPhoneXʀ = [blueXʀ, yellowXʀ, coralXʀ, redXʀ, black7, whiteXʀ]
}
public extension [AppleMaterialColor] {
	static let iPhoneXʀ = AMC.iPhoneXʀ
}

// iPhone Xs
public extension AppleMaterialColor {
	static let iPhoneXs = [silverSE, spaceGraySE, goldSE]
}
public extension [AppleMaterialColor] {
	static let iPhoneXs = AMC.iPhoneXs
}

// iPhone SE 2
public extension AppleMaterialColor {
	static let iPhoneSE2 = [blackSE2, whiteXʀ, redXʀ]
}
public extension [AppleMaterialColor] {
	static let iPhoneSE2 = AMC.iPhoneSE2
}

// iPhone 11
public extension AppleMaterialColor {
	static let purple11 = AMC("#d1cdda", "Purple")
	static let yellow11 = AMC("#ffe681", "Yellow")
	static let green11 = AMC("#aee1cd", "Green")
	static let black11 = AMC("#1f2020", "Black")
	static let white11 = AMC("#f9f6ef", "White")
	static let red11 = AMC("#ba0c2e", .productRed)
	static let iPhone11 = [purple11, yellow11, green11, black11, white11, red11]
}
public extension [AppleMaterialColor] {
	static let iPhone11 = AMC.iPhone11
}

// iPhone 11 Pro
public extension AppleMaterialColor {
	static let midnightGreen = AMC("#4e5851", "Midnight Green")
	static let silver11 = AMC("#ebebe3", "Silver")
	static let spaceGray11 = AMC("#535150", "Space Gray")
	static let gold11 = AMC("#fad7bd", "Gold")
	static let iPhone11Pro = [midnightGreen, silver11, spaceGray11, gold11]
}
public extension [AppleMaterialColor] {
	static let iPhone11Pro = AMC.iPhone11Pro
}

// iPhone 12
public extension AppleMaterialColor {
	static let purple12 = AMC("#b7afe6", "Purple")
	static let blue12 = AMC("#023b63", "Blue")
	static let green12 = AMC("#d8efd5", "Green")
	static let red12 = AMC("#d82e2e", .productRed)
	static let white12 = AMC("#f6f2ef", "White")
	static let black12 = AMC("#25212b", "Black")
	static let iPhone12 = [black12, white12, red12, green12, blue12, purple12]
}
public extension [AppleMaterialColor] {
	static let iPhone12 = AMC.iPhone12
}

// iPhone 12 Pro
public extension AppleMaterialColor {
	static let pacificBlue = AMC("#2d4e5c", "Pacific Blue")
	static let gold12 = AMC("#fcebd3", "Gold")
	static let graphite12 = AMC("#52514d", "Graphite")
	static let silver12 = AMC("#e3e4df", "Silver")
	static let iPhone12Pro = [silver12, graphite12, gold12, pacificBlue]
}
public extension [AppleMaterialColor] {
	static let iPhone12Pro = AMC.iPhone12Pro
}

// iPhone 13
public extension AppleMaterialColor {
	static let green13 = AMC("#394c38", "Green")
	static let pink13 = AMC("#faddd7", "Pink")
	static let blue13 = AMC("#276787", "Blue")
	static let midnight13 = AMC("#232a31", "Midnight")
	static let starlight13 = AMC("#faf6f2", "Starlight")
	static let productRed13 = AMC("#bf0013", .productRed)
	static let iPhone13 = [productRed13, starlight13, midnight13, blue13, pink13, green13]
}
public extension [AppleMaterialColor] {
	static let iPhone13 = AMC.iPhone13
}

// iPhone 13 Pro
public extension AppleMaterialColor {
	static let alpineGreen = AMC("#576856", "Alpine Green")
	static let gold13 = AMC("#fae7cf", "Gold")
	static let graphite = AMC("#54524f", "Graphite")
	static let sierraBlue = AMC("#a7c1d9", "Sierra Blue")
	static let silver13 = AMC("#f1f2ed", "Silver")
	static let iPhone13Pro = [sierraBlue, graphite, gold13, silver13, alpineGreen]
}
public extension [AppleMaterialColor] {
	static let iPhone13Pro = AMC.iPhone13Pro
}

// iPhone SE 3
public extension AppleMaterialColor {
	static let iPhoneSE3 = [productRed13, starlight13, midnight13]
}
public extension [AppleMaterialColor] {
	static let iPhoneSE3 = AMC.iPhoneSE3
}

// iPhone 14
public extension AppleMaterialColor {
	static let blue14 = AMC("#a0b4c7", "Blue")
	static let purple14 = AMC("#e6ddeb", "Purple")
	static let yellow14 = AMC("#f9e479", "Yellow")
	static let midnight14 = AMC("#222930", "Midnight")
	static let productRed14 = AMC("#fc0324", .productRed)
	static let iPhone14 = [midnight14, starlight13, productRed14, blue14, purple14, yellow14]
}
public extension [AppleMaterialColor] {
	static let iPhone14 = AMC.iPhone14
}

// iPhone 14 Pro
public extension AppleMaterialColor {
	static let deepPurple14 = AMC("#594f63", "Deep Purple")
	static let gold14 = AMC("#f4e8ce", "Gold")
	static let silver14 = AMC("#f0f2f2", "Silver")
	static let spaceBlack14 = AMC("#403e3d", "Space Black")
	static let iPhone14Pro = [spaceBlack14, silver14, gold14, deepPurple14]
}
public extension [AppleMaterialColor] {
	static let iPhone14Pro = AMC.iPhone14Pro
}

// iPhone 15
public extension AppleMaterialColor {
	static let pink15 = AMC("#E3C8CA", "Pink")
	static let yellow15 = AMC("#E6E0C1", "Yellow")
	static let green15 = AMC("#CAD4C5", "Green")
	static let blue15 = AMC("#CED5D9", "Blue")
	static let black15 = AMC("#35393B", "Black")
	static let iPhone15 = [black15, blue15, green15, yellow15, pink15]
}
public extension [AppleMaterialColor] {
	static let iPhone15 = AMC.iPhone15
}

// iPhone 15 Pro
public extension AppleMaterialColor {
	static let naturalTitanium = AMC("#837f7d", "Natural Titanium")
	static let blueTitanium = AMC("#2f4452", "Blue Titanium")
	static let whiteTitanium = AMC("#dddddd", "White Titanium")
	static let blackTitanium = AMC("#1b1b1b", "Black Titanium")
	static let iPhone15Pro = [blackTitanium, whiteTitanium, blueTitanium, naturalTitanium]
}
public extension [AppleMaterialColor] {
	static let iPhone15Pro = AMC.iPhone15Pro
}

// iPhone 16
public extension AppleMaterialColor {
	static let ultramarine = AMC("#9aadf6", "Ultramarine")
	static let teal = AMC("#b0d4d2", "Teal")
	static let pink16 = AMC("#f2adda", "Pink")
	static let white16 = AMC("#fafafa", "White")
	static let black16 = AMC("#3c4042", "Black")
	static let iPhone16 = [black16, white16, pink16, teal, ultramarine]
}
public extension [AppleMaterialColor] {
	static let iPhone16 = AMC.iPhone16
}

// iPhone 16 Pro
public extension AppleMaterialColor {
	static let desertTitanium = AMC("#bfa48f", "Desert Titanium")
	static let naturalTitanium16 = AMC("#c2bcb2", "Natural Titanium")
	static let whiteTitanium16 = AMC("#f2f1ed", "White Titanium")
	static let blackTitanium16 = AMC("#3c3c3d", "Black Titanium")
	static let iPhone16Pro = [blackTitanium16, whiteTitanium16, naturalTitanium16, desertTitanium]
	static let iPhone16e = [black16, white16]
}
public extension [AppleMaterialColor] {
	static let iPhone16Pro = AMC.iPhone16Pro
}
public extension [AppleMaterialColor] {
	static let iPhone16e = AMC.iPhone16e
}

// iPhone 17
public extension AppleMaterialColor {
	static let lavender = AMC("#dfceea", "Lavender")
	static let sage = AMC("#a9b689", "Sage")
	static let mistBlue = AMC("#96aed1", "Mist Blue")
	static let white17 = AMC("#f5f5f5", "White")
	static let black17 = AMC("#353839", "Black")
	static let iPhone17 = [black17, white17, mistBlue, sage, lavender]
}
public extension [AppleMaterialColor] {
	static let iPhone17 = AMC.iPhone17
}

// iPhone Air
public extension AppleMaterialColor {
	static let skyBlue = AMC("#f0f9ff", "Sky Blue")
	static let lightGold = AMC("#fffcf5", "Light Gold")
	static let cloudWhite = AMC("#fcfcfc", "Cloud White")
	static let spaceblackair = AMC("#000000", "Space Black")
	static let iPhoneAir = [spaceblackair, cloudWhite, lightGold, skyBlue]
}
public extension [AppleMaterialColor] {
	static let iPhoneAir = AMC.iPhoneAir
}

// iPhone 17 Pro
public extension AppleMaterialColor {
	static let cosmicOrange = AMC("#F77E2D", "Cosmic Orange")
	static let deepBlue = AMC("#32374a", "Deep Blue")
	static let silver17 = AMC("#f5f5f5", "Silver")
	static let iPhone17Pro = [silver17, cosmicOrange, deepBlue]
}
public extension [AppleMaterialColor] {
	static let iPhone17Pro = AMC.iPhone17Pro
}

// iPhone 17e
public extension AppleMaterialColor {
	static let softPink = AMC("#fce7e6", "Soft Pink")
	static let iPhone17e = [black16, white16, softPink]
}
public extension [AppleMaterialColor] {
	static let iPhone17e = AMC.iPhone17e
}

// iPhone 18 Pro
public extension AppleMaterialColor {
	static let burgundy = AMC("#4d1821", "Burgundy")
	static let glacier = AMC("#e8f2ff", "Glacier")
	static let silver18 = AMC("#f7f7f7", "Silver")
	static let black18 = AMC("#3c3c3c", "Black")
	static let iPhone18Pro = [black18, silver18, glacier, burgundy]

	static let starWhite = AMC("#fafafa", "Star White")
	static let nightSky = AMC("#3c4042", "Night Sky")
	static let iPhoneDuo = [nightSky, starWhite]
}
public extension [AppleMaterialColor] {
	static let iPhone18Pro = AMC.iPhone18Pro
	static let iPhoneDuo = AMC.iPhoneDuo
}
private extension [AppleMaterialColor] {
	static let iphoneColorSets = [
		AMC.iPhoneBW: "iPhoneBW",
		.iPhone5c: "iPhone5c",
		.iPhone6: "iPhone6",
		.iPhone6s: "iPhone6s",
		.iPhone7: "iPhone7",
		.iPhone8: "iPhone8",
		.iPhoneXʀ: "iPhoneXʀ",
		.iPhoneX: "iPhoneX",
		.iPhoneXs: "iPhoneXs",
		.iPhoneSE2: "iPhoneSE2",
		.iPhone11: "iPhone11",
		.iPhone11Pro: "iPhone11Pro",
		.iPhone12: "iPhone12",
		.iPhone12Pro: "iPhone12Pro",
		.iPhone13: "iPhone13",
		.iPhone13Pro: "iPhone13Pro",
		.iPhoneSE3: "iPhoneSE3",
		.iPhone14: "iPhone14",
		.iPhone14Pro: "iPhone14Pro",
		.iPhone15: "iPhone15",
		.iPhone15Pro: "iPhone15Pro",
		.iPhone16: "iPhone16",
		.iPhone16Pro: "iPhone16Pro",
		.iPhone16e: "iPhone16e",
		.iPhone17: "iPhone17",
		.iPhoneAir: "iPhoneAir",
		.iPhone17Pro: "iPhone17Pro",
		.iPhone17e: "iPhone17e",
		.iPhone18Pro: "iPhone18Pro",
		.iPhoneDuo: "iPhoneDuo",
	]
}

// MARK: - iPads
//


// iPad Air
public extension AppleMaterialColor {
	static let iPadAir = [spaceGray6, silver6]
}
public extension [AppleMaterialColor] {
	static let iPadAir = AMC.iPadAir
}

// iPad Air 4
public extension AppleMaterialColor {
	static let roseGoldA4 = AMC("#ecc5c1", "Rose Gold")
	static let skyBlueA4 = AMC("#cee3f6", "Sky Blue")
	static let greenA4 = AMC("#ccdfc9", "Green")
}

// iPad Air 5
public extension AppleMaterialColor {
	static let spaceGrayA5 = AMC("#6b696e", "Space Gray")
	static let starlightA5 = AMC("#e5e0d8", "Starlight")
	static let pinkA5 = AMC("#e8d2cf", "Pink")
	static let purpleA5 = AMC("#b9b8d1", "Purple")
	static let blueA5 = AMC("#88aebf", "Blue")
}

// iPad mini 5
public extension AppleMaterialColor {
	static let spaceGrayM5 = AMC("#68696d", "Space Gray")
	static let goldM5 = AMC("#f6cdb9", "Gold")
	static let iPadMini5 = [spaceGrayM5, silver6, goldM5]
}
public extension [AppleMaterialColor] {
	static let iPadMini5 = AMC.iPadMini5
}

// iPad mini 6
public extension AppleMaterialColor {
	static let pink6 = AMC("#e8d1cf", "Pink")
}

// iPad 9th gen
public extension AppleMaterialColor {
	static let spaceGray9 = AMC("#68696e", "Space Gray")
}

// iPad 10th gen & A16 2025
public extension AppleMaterialColor {
	static let pink10 = AMC("#de6274", "Pink")
	static let blue10 = AMC("#6480a3", "Blue")
	static let yellow10 = AMC("#f0d95b", "Yellow")
	static let iPad10 = [blue10, pink10, yellow10, solidSilver]
}
public extension [AppleMaterialColor] {
	static let iPad10 = AMC.iPad10
}

// iPad Air M2 2024, iPad mini (A17 Pro), iPad Air M4 2026
public extension AppleMaterialColor {
	static let starlightAir = AMC("#e3dcd1", "Starlight")
	static let purpleAir = AMC("#e3dee9", "Purple")
	static let blueAir = AMC("#d7e5e6", "Blue")
	static let iPadAirM2 = [spaceGrayA5, blueAir, purpleAir, starlightAir] // also iPadAirM3 2025, original order: [spaceGrayA5, starlightAir, purpleAir, blueAir]
}
public extension [AppleMaterialColor] {
	static let iPadAirM2 = AMC.iPadAirM2
}

// iPad Pros
public extension AppleMaterialColor {
	static let iPadsPro = [spaceGrayM5, silver6]
}
public extension [AppleMaterialColor] {
	static let iPadsPro = AMC.iPadsPro
}

// iPads Pro M4/M5, MacBooks Pro M6/M5 Pro/M5 Max
public extension AppleMaterialColor {
	static let blackSilver = [spaceblack, solidSilver]
}
public extension [AppleMaterialColor] {
	static let blackSilver = AMC.blackSilver
}

// iPad Pros M4/M5
public extension AppleMaterialColor {
	static let iPadsProM5 = [spaceblack, silver6]
}
public extension [AppleMaterialColor] {
	static let iPadsProM5 = AMC.iPadsProM5
}


private extension [AppleMaterialColor] {
	static let ipadColorSets = [
		AMC.iPadAir: "iPadAir",
		.iPadMini5: "iPadMini5",
		.iPad10: "iPad10",
		.iPadAirM2: "iPadAirM2",
		.iPadsPro: "iPadsPro",
		.blackSilver: "blackSilver",
		.iPadsProM5: "iPadsProM5",
	]
}

// MARK: -  Watches
// Note: Apple Watch color names always include the material
//  Watch Series 0
public extension AppleMaterialColor {
	static let aluminumRoseGold = AMC("#f6d9cd", "Rose Gold Aluminum")
	static let aluminumSilver = AMC("#e0e0e0", "Silver Aluminum")
	static let aluminumSpaceGray = AMC("#727272", "Space Gray Aluminum")
	static let aluminumGold = AMC("#f3e4d1", "Gold Aluminum")
	static let stainlessSpaceBlack = AMC("#2e3a36", "Space Black Stainless") //Hermes Stainless Space Black/Space Black/Stainless Space Black")
    static let stainlessSilver = AMC("#e6e6e7", "Stainless Steel") // Silver Stainless
	static let yellowGold = AMC("#dfc386", "18-Karat Yellow Gold")
	static let roseGold = AMC("#e0b496", "18-Karat Rose Gold")
	static let watch0 = [stainlessSpaceBlack, stainlessSilver, aluminumSpaceGray, aluminumGold, aluminumRoseGold, aluminumSilver, yellowGold, roseGold]
}
public extension [AppleMaterialColor] {
	static let watch0 = AMC.watch0
}

//  Watch Series 1
public extension AppleMaterialColor {
	static let watch1 = [aluminumSpaceGray, aluminumGold, aluminumRoseGold, aluminumSilver]
}
public extension [AppleMaterialColor] {
	static let watch1 = AMC.watch1
}

//  Watch Series 2
public extension AppleMaterialColor {
	static let ceramicWhite = AMC("#f9f9f7", "White Ceramic")
    static let stainlessSpaceBlack2 = AMC("#3e3a36", "Space Black Stainless") // color is the stainlessGraphite swatch but labelled "space black"
	static let watch2 = watch1 + [stainlessSpaceBlack2, stainlessSilver, ceramicWhite]
}
public extension [AppleMaterialColor] {
	static let watch2 = AMC.watch2
}

//  Watch Series 3
public extension AppleMaterialColor {
	static let aluminumBrushGold = AMC("#f4d4c6", "Gold Aluminum") // Brush Gold in comparison color css, simply Gold in identify list.
	static let ceramicGray = AMC("#615f5a", "Gray Ceramic")

	static let stainlessSteel = AMC("#c2c2c2", "Stainless Steel")
	static let stainlessSpaceBlack3 = AMC("#666768", "Space Black Stainless")
	static let ceramicWhite3 = AMC("#f4f2f1", "White Ceramic")
	static let watch3gps = [aluminumSpaceGray, aluminumBrushGold, aluminumSilver]
	static let watch3 = watch3gps + [stainlessSpaceBlack3, stainlessSilver, ceramicWhite3, ceramicGray]
}
public extension [AppleMaterialColor] {
	static let watch3gps = AMC.watch3gps
}
public extension [AppleMaterialColor] {
	static let watch3 = AMC.watch3
}

//  Watch Series 4
public extension AppleMaterialColor {
	static let stainlessGold = AMC("#d4bda1", "Gold Stainless")
	static let watch4 = watch3gps + [stainlessSilver, stainlessSpaceBlack, stainlessGold] // Image order: [stainlessSpaceBlack, stainlessGold, stainlessSilver]
}
public extension [AppleMaterialColor] {
	static let watch4 = AMC.watch4
}

//  Watch Series 5
public extension AppleMaterialColor {
	static let titanium = AMC("#dedbd9", "Titanium")
	static let titaniumSpaceBlack = AMC("#47433f", "Space Black Titanium") // Dark/Titanium Space Black
	static let watch5 = watch3gps + [stainlessSilver, stainlessSpaceBlack, stainlessGold, titaniumSpaceBlack, titanium, ceramicWhite]
}
public extension [AppleMaterialColor] {
	static let watch5 = AMC.watch5
}

//  Watch SE
// identical to watch5gps
//  static let watchSE = [aluminumBrushGold, aluminumSilver, aluminumSpaceGray]
public extension AppleMaterialColor {
}

//  Watch Series 6
public extension AppleMaterialColor {
	static let aluminumBlue = AMC("#3e4b6c", "Blue Aluminum")
	static let aluminumRed = AMC("#c6464a", .productRed + " Aluminum")
	static let stainlessGraphite = AMC("#3e3a36", "Graphite Stainless")
	static let watch6gps = [aluminumSpaceGray, aluminumBrushGold, aluminumSilver, aluminumRed, aluminumBlue]
	static let watch6 = watch6gps + [stainlessSilver, stainlessGraphite, stainlessGold, titanium, titaniumSpaceBlack]
}
public extension [AppleMaterialColor] {
	static let watch6gps = AMC.watch6gps
}
public extension [AppleMaterialColor] {
	static let watch6 = AMC.watch6
}

//  Watch Series 7
public extension AppleMaterialColor {
	static let aluminumGreen = AMC("#36382b", "Green Aluminum")
	static let aluminumMidnight = AMC("#1a2530", "Midnight Aluminum")
	static let aluminumBlue7 = AMC("#6e8eba", "Blue Aluminum")
	static let aluminumStarlight = AMC("#ded6d1", "Starlight Aluminum")
	static let aluminumRed7 = AMC("#a91e3b", .productRed + " Aluminum")
    static let titaniumNatural7 = AMC("#dedbd9", "Natural Titanium") // Edition
	static let watch7gps = [aluminumMidnight, aluminumStarlight, aluminumGreen, aluminumBlue7, aluminumRed7]
	static let watch7 = watch7gps + [stainlessSilver, stainlessGraphite, stainlessGold, stainlessSpaceBlack /*Hermès*/, titaniumNatural7, titaniumSpaceBlack]
}
public extension [AppleMaterialColor] {
	static let watch7gps = AMC.watch7gps
}
public extension [AppleMaterialColor] {
	static let watch7 = AMC.watch7
}

//  Watch Series 8
public extension AppleMaterialColor {
	static let watch8gps = [aluminumMidnight, aluminumStarlight, aluminumSilver, aluminumRed]
	static let watch8 = watch8gps + [stainlessSilver, stainlessGraphite, stainlessGold, stainlessSpaceBlack] // stainlessSpaceBlack for Hermès
}
public extension [AppleMaterialColor] {
	static let watch8gps = AMC.watch8gps
}
public extension [AppleMaterialColor] {
	static let watch8 = AMC.watch8
}

//  Watch Series 9
public extension AppleMaterialColor {
	static let aluminumPink = AMC("#fadcde", "Pink Aluminum")
	static let aluminumRed9 = AMC("#c80e2d", .productRed + " Aluminum")
	static let watch9gps = [aluminumMidnight, aluminumStarlight, aluminumSilver, aluminumPink, aluminumRed9]
	static let watch9 = watch9gps + [stainlessSilver, stainlessGraphite, stainlessGold, stainlessSpaceBlack] // stainlessSpaceBlack for Hermès
}
public extension [AppleMaterialColor] {
	static let watch9gps = AMC.watch9gps
}
public extension [AppleMaterialColor] {
	static let watch9 = AMC.watch9
}

//  Watch Series 10
public extension AppleMaterialColor {
	static let aluminumJetBlack = AMC("#010203", "Jet Black Aluminum")
	static let aluminumSilver10 = AMC("#f0eff1", "Silver Aluminum")
	static let titaniumNatural10 = AMC("#e3ddd7", "Natural Titanium")
	static let titaniumSlate = AMC("#47423d", "Slate Titanium")
	static let titaniumGold = AMC("#f4dec8", "Gold Titanium")
    static let titaniumSilverHermes = AMC("#e6e6e7", "Silver Titanium")
	static let watch10gps = [aluminumJetBlack, aluminumRoseGold, aluminumSilver10]
	static let watch10 = watch10gps + [titaniumNatural10, titaniumSlate, titaniumGold, titaniumSilverHermes]
}
public extension [AppleMaterialColor] {
	static let watch10gps = AMC.watch10gps
}
public extension [AppleMaterialColor] {
	static let watch10 = AMC.watch10
}

//  Watch Series 11
public extension AppleMaterialColor {
	static let watch11gps = [aluminumSpaceGray, aluminumSilver10, aluminumRoseGold, aluminumJetBlack]
	static let watch11 = watch11gps + [titaniumNatural10, titaniumGold, titaniumSlate, titaniumSilverHermes]
}
public extension [AppleMaterialColor] {
	static let watch11gps = AMC.watch11gps
}
public extension [AppleMaterialColor] {
	static let watch11 = AMC.watch11
}

//  Watch SE 2
public extension AppleMaterialColor {
	static let watchSE2 = [aluminumMidnight, aluminumStarlight, aluminumSilver]
}
public extension [AppleMaterialColor] {
	static let watchSE2 = AMC.watchSE2
}

//  Watch SE 2
public extension AppleMaterialColor {
	static let watchSE3 = [aluminumMidnight, aluminumStarlight]
}
public extension [AppleMaterialColor] {
	static let watchSE3 = AMC.watchSE3
}

//  Watch Ultra
public extension AppleMaterialColor {
	static let titaniumNatural = AMC("#ccc4bc", "Natural Titanium")
	static let watchUltra = [titaniumNatural]
}
public extension [AppleMaterialColor] {
	static let watchUltra = AMC.watchUltra
}

//  Watch Ultra 2
public extension AppleMaterialColor {
	static let titaniumBlackU2 = AMC("#0f0e0e", "Black Titanium")
	static let watchUltra3 = [titaniumNatural, titaniumBlackU2]
}
public extension [AppleMaterialColor] {
	static let watchUltra3 = AMC.watchUltra3
}

//  Watch Series 12
public extension AppleMaterialColor {
	static let aluminumDarkBronze = AMC("#4b372a", "Dark Bronze Aluminum")
	static let aluminumLightGold = AMC("#e3d2ba", "Light Gold Aluminum")
	static let aluminumBlack = AMC("#24211f", "Black Aluminum")
	static let aluminumSpaceGray12 = AMC("#b6b3b2", "Space Gray Aluminum")
	static let watch12gps = [aluminumSpaceGray12, aluminumBlack, aluminumLightGold, aluminumDarkBronze]
	static let titaniumRadiantGold = AMC("#f2e1b6", "Radiant Gold Titanium")
	static let titaniumNatural12 = AMC("#ded8d1", "Natural Titanium")
	static let ceramicPearlWhite = AMC("#f0eae4", "Pearl White Ceramic")
	static let ceramicNightBlue = AMC("#2a3040", "Night Blue Ceramic")
	static let watch12 = watch12gps + [titaniumNatural12, titaniumRadiantGold, ceramicPearlWhite, ceramicNightBlue, titaniumSilverHermes]
}
public extension [AppleMaterialColor] {
	static let watch12gps = AMC.watch12gps
	static let watch12 = AMC.watch12
}

private extension [AppleMaterialColor] {
	static let watchColorSets = [
		AMC.watch0: "watch0",
		.watch1: "watch1",
		.watch2: "watch2",
		.watch3gps: "watch3gps",
		.watch3: "watch3",
		.watch4: "watch4",
		.watch5: "watch5",
		.watch6gps: "watch6gps",
		.watch6: "watch6",
		.watch7gps: "watch7gps",
		.watch7: "watch7",
		.watch8gps: "watch8gps",
		.watch8: "watch8",
		.watch9gps: "watch9gps",
		.watch9: "watch9",
		.watch10gps: "watch10gps",
		.watch10: "watch10",
		.watch11gps: "watch11gps",
		.watch11: "watch11",
		.watchSE2: "watchSE2",
		.watchSE3: "watchSE3",
		.watchUltra: "watchUltra",
		.watchUltra3: "watchUltra3",
		.watch12gps: "watch12gps",
		.watch12: "watch12",
	]
}

// MARK: - HomePod
// HomePod
public extension AppleMaterialColor {
	static let whiteHome = AMC("#f1f1f1", "White")
	static let midnightHome = AMC("#313236", "Midnight")
	static let homePod = [whiteHome, midnightHome]
}
public extension [AppleMaterialColor] {
	static let homePod = AMC.homePod
}

public extension AppleMaterialColor {
	static let yellowHome = AMC("#ffc953", "Yellow")
	static let orangeHome = AMC("#e56645", "Orange")
	static let blueHome = AMC("#25485e", "Blue")
	static let spacegrayHome = AMC("#36373a", "Space Gray")
	// added July 15, 2024: https://www.apple.com/newsroom/2024/07/apple-introduces-homepod-mini-in-midnight/
	static let midnightHomeMini = AMC("#222428", "Midnight")
	static let homePodMini = [whiteHome, yellowHome, orangeHome, blueHome, spacegrayHome, midnightHomeMini]
}
public extension [AppleMaterialColor] {
	static let homePodMini = AMC.homePodMini
}

// HomePod mini 2
public extension AppleMaterialColor {
	static let whiteHomeMini2 = AMC("#f4f4f4", "White")
	static let pinkHomeMini2 = AMC("#dac9cd", "Pink")
	static let blueHomeMini2 = AMC("#557294", "Blue")
	static let greenHomeMini2 = AMC("#567e6a", "Green")
	static let midnightHomeMini2 = AMC("#323538", "Midnight")
	static let homePodMini2 = [whiteHomeMini2, pinkHomeMini2, blueHomeMini2, greenHomeMini2, midnightHomeMini2]
}
public extension [AppleMaterialColor] {
	static let homePodMini2 = AMC.homePodMini2
}

private extension [AppleMaterialColor] {
	static let homepodColorSets = [
		AMC.homePod: "homePod",
		.homePodMini: "homePodMini",
		.homePodMini2: "homePodMini2",
	]
}

// MARK: - Full Color Sets
public extension [AppleMaterialColor] {
	/// All AppleMaterialColors used in Devices (in or out of a colorset)
	static let all: [AppleMaterialColor] = {
		var all: [AppleMaterialColor] = []
		for device in Device.all {
			for color in device.colors {
				if !all.contains(color) {
					all.append(color)
				}
			}
		}
		return all
	}()

	/// Colors that have been used for the given string name.
	static func allMatching(_ string: String) -> [AppleMaterialColor] {
		let normalized = normalizedAppleColorName(string)
		for (key, value) in AppleMaterialColor.namedColors {
			let nkey = normalizedAppleColorName(key)
			if nkey == normalized {
				return value
			}
		}
		return []
	}

	/// Apple uses both a logo label and plain-text variants for the same finish.
	private static func normalizedAppleColorName(_ name: String) -> String {
		let compact = name.lowercased().filter { $0.isLetter || $0.isNumber }
		// Treat Apple's logo spelling as an alias for the unqualified finish
		// only. Material-qualified finishes such as "(PRODUCT)RED Aluminum"
		// must remain distinct so a phone cannot resolve to an Apple Watch color.
		if compact == "productred" { return "productred" }
		// Apple has used both spellings in watch finish labels.
		if compact == "brushgoldaluminum" { return "brushedgoldaluminum" }
		if compact == "steelstainless" || compact == "stainlesssteelstainless" { return "stainlesssteel" }
		return compact
	}

	/// Combined grouped-color registry from color set key to string value
	static let colorSets =
					[AppleMaterialColor].basicColorSets +
					macColorSets +
					ipodColorSets +
					iphoneColorSets +
					ipadColorSets +
					watchColorSets +
					homepodColorSets
}

public extension Array where Element == AppleMaterialColor {
	/// Exact finish comparison, accepting Apple's reversed image/selector ordering.
	/// Name case, material, and the ordering of tones *within* each finish remain significant.
	/// CSS provenance is deliberately excluded from visible finish identity.
	func matchesPalette(_ other: [AppleMaterialColor], acceptingReversedOrder: Bool = true) -> Bool {
		guard count == other.count else { return false }
		func name(_ value: String) -> String {
			let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
			let key = trimmed.lowercased().filter { $0.isLetter || $0.isNumber }
			return key == "productred" ? .productRed : trimmed
		}
		func matches(_ left: AppleMaterialColor, _ right: AppleMaterialColor) -> Bool {
			name(left.name) == name(right.name) && left.swatches.map { $0.lowercased() } == right.swatches.map { $0.lowercased() }
		}
		return zip(self, other).allSatisfy(matches) || acceptingReversedOrder && zip(self, other.reversed()).allSatisfy(matches)
	}
}
