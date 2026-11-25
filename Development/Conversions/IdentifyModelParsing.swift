//
//  IdentifyModelParsing.swift
//  Device
//
//  For comparing with Apple Identify Your X pages.
//
//  Created by Ben Ku on 3/10/25.
//


#if canImport(Device) // since this is needed in XCode but is unavailable in Playgrounds.
import Device
import Color
import Compatibility
#endif

// For Compatibility
public extension String {
    /// Normalized string removing any whitespace characters.
    var normalizedCollapsedWhitespace: String {
        return self.normalized.replacingCharacters(in: .whitespacesAndNewlines, with: "")
    }
}

private extension String {
    /// Returns capture groups for every match while keeping the parser small
    /// and compatible with the package's older deployment targets.
    func matches(pattern: String) -> [[String]] {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: []) else { return [] }
        return expression.matches(in: self, range: NSRange(startIndex..., in: self)).map { match in
            (0..<match.numberOfRanges).compactMap { index in
                let range = match.range(at: index)
                guard range.location != NSNotFound, let swiftRange = Range(range, in: self) else { return nil }
                return String(self[swiftRange])
            }
        }
    }

    /// Returns the first regular-expression match, including its capture groups.
    func firstMatch(pattern: String) -> [String]? {
        matches(pattern: pattern).first
    }
}
public extension String {
    /// Whitespace collapsed and then replacing occurrances of ` \n` with `\n` and then collapsed again.
    var superCollapseWhitespace: String {
        self.whitespaceCollapsed.replacingOccurrences(of: " \n", with: "\n").whitespaceCollapsed
    }
}

public extension CPU {
    var appleName: String {
        return self.rawValue.replacingOccurrences(of: "Apple ", with: "")
    }
}

public extension Capabilities {
    /// Returns `true` iff the array contains all of the values.
    func containsAll(_ capabilities: Capabilities) -> Bool {
        if capabilities.macForm != self.macForm {
            return false
        }
//    if capabilities.pencils != self.pencils { // may want to check but this breaks if this has pencils and capabilities has none.
//      return false
//    }
        for capability in capabilities {
            if !Capability.allCases.contains(capability) {
                continue // skip non simple capabilities
            }
            if !self.contains(capability) {
                return false
            }
        }
        return true
    }
}

struct ModelSourceCodeComparison: Sendable, Codable, Equatable {
    let actual: String
    let proposed: String
}

struct ParsedItem: DeviceBridge {   
    var comparisonIdentifiers: [String] { identifiers }
    var comparisonCPUs: [CPU] { CPU.sourceChoices(in: officialName) + (cpu == .unknown ? [] : [cpu]) }

    /// Apply the same shared-support grouping policy as JSON and DeviceKit sources.
    func comparison(for member: Device, in group: [Device]) -> Self {
        var scoped = self
        scoped.identifiers = identifiers.filter { member.identifiers.contains($0) }
        scoped.partNumbers = sourceGroupValues(partNumbers, member: member.models, group: group.map { $0.models })
        scoped.colors = sourceGroupValues(colors, member: member.colors, group: group.map { $0.colors })
        scoped.capabilities = Set(sourceGroupValues(Array(capabilities), member: Array(member.capabilities), group: group.map { Array($0.capabilities) }))
        scoped.officialName = sourceGroupName(officialName, member: member, group: group)
        if scoped.officialName != officialName {
            // The source explicitly named the CPU alternatives and the common
            // resolver validated them; narrow the parsed CPU to this member too.
            scoped.cpu = member.cpu
        }
        return scoped
    }
    static var diffIgnoreKeys: [String] {
        ["source", "modelCodeComparison"] // source evidence is shown in dedicated views, not as a catalog-field mismatch
    }

    var officialName: String
    var idiom = Device.Idiom.unspecified
    var identifiers: [String] = []
    var yearIntroduced: Int?
    var supportId = String.unknownSupportId
    var unsupportedOSVersion: Version? = nil
    var image: String? = nil
    var capabilities = Capabilities()
    var partNumbers: [String] = []
    var cpu = CPU.unknown
    var colors: [AppleMaterialColor] = []
    var source: String
    var modelCodeComparison: ModelSourceCodeComparison? = nil

    /// CSS provenance (`cssKeys`) is diagnostic metadata, not part of a finish.
    /// Compare ordered visible names and literal swatches so identical colors
    /// don't turn red just because one source retained different CSS selectors.
    func bridgeValuesEqual(_ key: String, _ left: Any?, _ right: Any?) -> Bool {
        guard key == "colors",
              let lhs = left as? [AppleMaterialColor],
              let rhs = right as? [AppleMaterialColor] else {
            return areEqual(left, right)
        }
		return Self.orderedColorsEqual(lhs, rhs) || Self.orderedColorsEqual(lhs, Array(rhs.reversed()))
    }

	private static func orderedColorsEqual(_ lhs: [AppleMaterialColor], _ rhs: [AppleMaterialColor]) -> Bool {
		guard lhs.count == rhs.count else { return false }
		return zip(lhs, rhs).allSatisfy { local, source in
			normalizedColorName(local.name) == normalizedColorName(source.name)
				&& local.swatches.map(normalizedHex) == source.swatches.map(normalizedHex)
		}
	}

    private static func normalizedColorName(_ name: String) -> String {
        let compact = name.lowercased().filter { $0.isLetter || $0.isNumber }
        return compact == "productred" ? "productred" : compact
    }

    private static func normalizedHex(_ hex: String) -> String {
        hex.trimmed.lowercased().replacingOccurrences(of: "#", with: "")
    }
    
    // since multiple bridges may have the same source, unique ID
    var id: String {
        "\(officialName)\(source)"
    }
    
    var matched: Device {
        Device.forcedLookup(identifier: identifiers.first, model: partNumbers.first, officialNameHint: officialName)
    }

    var merged: Device {
        // A source family yields multiple independent definitions through mergedDevices.
        if let member = groupedComparisons.first { return member.merged }
        // create device for each identifier since we may want to split out
        return Device(
            idiom: idiom,
            officialName: officialName,
            identifiers: identifiers,
            introduction: yearIntroduced?.introductionYear,
            supportId: supportId,
            launchOSVersion: .zero,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities,
            models: partNumbers,
            colors: colors,
            cpu: cpu
        ).merged(from: matched)
    }
    
    func bridge(from device: Device) -> ParsedItem {
        var officialName = device.officialName
        if device.safeOfficialName.lowercased() == self.officialName.lowercased() || device.officialName.contains(self.officialName) { // last case is to capture Mac16,6, Mac16,7, and others that had to be split into two entries for different processors.
            officialName = self.officialName
        }
        // zero out fields/data that aren't available in the parsed item so we match
        var yearIntroduced = device.introduction?.date?.year
        if self.yearIntroduced == nil {
            yearIntroduced = nil // don't bother comparing if we don't have this data
        }
        var supportId = device.supportId
        if self.supportId == .unknownSupportId {
            supportId = .unknownSupportId 
        }
        var unsupportedOSVersion = device.unsupportedOSVersion
        if self.unsupportedOSVersion == nil {
            unsupportedOSVersion = nil
        }
        var capabilities = device.capabilities
        if self.capabilities.isEmpty || capabilities.containsAll(self.capabilities) {
            capabilities = self.capabilities
        }
        var models = device.models
        if models.containsAll(self.partNumbers) || self.partNumbers.containsAll(models) && device.identifiers.containsAny(["Mac16,7"]) { // check for split items
            models = self.partNumbers
        }
        var cpu = device.cpu
        if self.cpu == .unknown {
            cpu = .unknown
        }
        var colors = device.colors
        // Apple identify pages are treated as exact source data. A CSS rounding
        // difference must remain visible instead of being normalized here.
        // Reverse equality changes match status, never the local order shown by the diff.
        if self.colors.isEmpty || Self.orderedColorsEqual(self.colors, colors) {
            colors = self.colors
        }
        return ParsedItem(
            officialName: officialName,
            idiom: device.idiom,
            identifiers: device.identifiers,
            yearIntroduced: yearIntroduced,
            supportId: supportId,
            unsupportedOSVersion: unsupportedOSVersion,
            image: device.image,
            capabilities: capabilities,
            partNumbers: models,
            cpu: cpu,
            colors: colors,
            source: source)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 8, *)
actor PageParser: DeviceBridgeLoader {
    private struct ComparisonColorInfo {
        let colors: [AppleMaterialColor]
        let wrapper: String
        let css: String
    }
    /// Keeps Apple's identify and comparison sources together.  The comparison
    /// source is optional because Apple does not publish a comparison page for
    /// every product family.
    struct ApplePages {
        let identify: String
        let compare: String?
    }

    static let identifyPages: [String: ApplePages] = [
        "MacBook Pros": .init(identify: "https://support.apple.com/en-us/108052", compare: "https://www.apple.com/mac/compare/"),
		"iPods": .init(identify: "https://support.apple.com/en-us/103823", compare: nil),
        "iPads": .init(identify: "https://support.apple.com/en-us/108043", compare: "https://www.apple.com/ipad/compare/"),
        "iPhones": .init(identify: "https://support.apple.com/en-us/108044", compare: "https://www.apple.com/iphone/compare/"),
        "MacBook Air": .init(identify: "https://support.apple.com/en-us/102869", compare: "https://www.apple.com/mac/compare/"),
        "MacBooks": .init(identify: "https://support.apple.com/en-us/103257", compare: "https://www.apple.com/mac/compare/"),
        "iMacs": .init(identify: "https://support.apple.com/en-us/108054", compare: "https://www.apple.com/mac/compare/"),
        "Mac Pros": .init(identify: "https://support.apple.com/en-us/102887", compare: "https://www.apple.com/mac/compare/"),
        "Mac minis": .init(identify: "https://support.apple.com/en-us/102852", compare: "https://www.apple.com/mac/compare/"),
        "Mac Studios": .init(identify: "https://support.apple.com/en-us/102231", compare: "https://www.apple.com/mac/compare/"),
        "Apple TVs": .init(identify: "https://support.apple.com/en-us/101605", compare: nil),
        "Apple Watches": .init(identify: "https://support.apple.com/en-us/108056", compare: "https://www.apple.com/watch/compare/"),
        "Apple Vision Pros": .init(identify: "https://support.apple.com/en-mk/125375", compare: nil),
    ]

    let sourceURL: String
    let name: String
    let comparePages: ApplePages?
    private var comparisonColors: [String: ComparisonColorInfo] = [:]
    private var modelSource = ""
    var content: String?
    var items: [ParsedItem] = []

    init(sourceURL: String) {
        self.sourceURL = sourceURL
        let page = Self.identifyPages.first(where: { $0.value.identify == sourceURL })!
        self.name = " " + page.key
        self.comparePages = page.value
    }

    func devices() async -> [ParsedItem] {
        await devices(progress: nil)
    }

    func devices(progress: (@Sendable (_ completed: Int, _ total: Int, _ message: String) -> Void)?) async -> [ParsedItem] {
        let content = try? await fetchURL(urlString: sourceURL)
        modelSource = await loadModelSource() ?? ""
        // Comparison pages expose the canonical finish names and CSS hex values
        // that the support overview often omits.  Parse them once before the
        // identify sections so every model can reuse the same source snapshot.
        if let compareURL = comparePages?.compare,
           let compareContent = try? await fetchURL(urlString: compareURL) {
            var styles = ""
            if let stylesURL = compareContent.firstMatch(pattern: #"(?i)<link[^>]+href=[\"']([^\"']+\.css[^\"']*)[\"']"#)?[1] {
                // Apple changes versioned CSS paths periodically, so discover
                // the current stylesheet from the comparison document when a
                // stable family URL is not available.
                let absoluteURL = stylesURL.hasPrefix("http") ? stylesURL : "https://www.apple.com" + (stylesURL.hasPrefix("/") ? stylesURL : "/" + stylesURL)
                styles = (try? await fetchURL(urlString: absoluteURL)) ?? ""
            }
            comparisonColors = comparisonColors(in: compareContent, styles: styles)
        }
        var parts = [String]()
        if content?.contains("Identify your Apple Watch") ?? false, let p = content?.components(separatedBy: "<h2 ") {
            // Apple Watch sections are family h2 blocks containing several h3
            // material/connectivity variants.  Parse those blocks directly so the
            // material h3 text stays evidence for models, colors, and images rather
            // than becoming part of the canonical product name.
            parseWatchSections(p.dropFirst(), progress: progress)
            return items
        } else if content?.contains("<h2 class=\"gb-header") ?? false, let p = content?.components(separatedBy: "<h2 class=\"gb-header alignment horizontal-align-left\">"), p.count > 1 {
            // iPod Touch page is sectioned differently and doesn't need to strip parts?
            parts = p
        } else if content?.contains("<h3 class=\"gb-header\">") ?? false, let p = content?.components(separatedBy: "<img class=\"gb-image\" alt=\"") {
            // MacBook page is sectioned differently and doesn't need to strip parts?
            parts = p
        } else if let p = content?.components(separatedBy: "<h2 class=\"gb-header\">") {
            parts = .init(p.dropFirst()) // top header
            if content?.contains("Identify your Apple Vision Pro") ?? false {
                parts = .init(parts.dropFirst()) // drop additional header
            }
        }
        let total = parts.count
        for (index, part) in parts.enumerated() {
            parseItem(source: part)
            // Report section-level progress after each parsed block so large Apple
            // support pages can show a determinate progress bar instead of leaving
            // the comparison view on an indefinite spinner.
            progress?(index + 1, total, "Parsed \(index + 1) of \(total) sections")
        }
        return items
    }

    private func loadModelSource() async -> String? {
        let fileName: String
        if name.contains("iPads") { fileName = "iPads.swift" }
        else if name.contains("iPhones") { fileName = "iPhones.swift" }
        else if name.contains("Apple Watches") { fileName = "AppleWatches.swift" }
        else if name.contains("Apple TVs") { fileName = "AppleTVs.swift" }
        else if name.contains("Apple Vision Pros") { fileName = "AppleVision.swift" }
        else if name.contains("iPods") { fileName = "iPods.swift" }
        else if name.contains("HomePods") { fileName = "HomePods.swift" }
        else if name.contains("Mac") { fileName = "Macs.swift" }
        else { return nil }

#if os(macOS)
        let bundledURL = Bundle.main.resourceURL?
            .appendingPathComponent("MigrationSources/Models")
            .appendingPathComponent(fileName)
        if let bundledURL, let source = try? String(contentsOf: bundledURL, encoding: .utf8), !source.isEmpty {
            return source
        }
#endif

#if os(macOS)
        let localPaths = [
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Sources/Models/\(fileName)").path,
            URL(fileURLWithPath: "/Users/\(NSUserName())/Documents/Kudit/Kudits/Library/Device.swiftpm/Sources/Models/\(fileName)").path,
            ("~/Documents/Kudit/Kudits/Library/Device.swiftpm/Sources/Models/\(fileName)" as NSString).expandingTildeInPath
        ]
        for localPath in localPaths where FileManager.default.fileExists(atPath: localPath) {
            if let source = try? String(contentsOfFile: localPath, encoding: .utf8) { return source }
        }
#endif
        let rawURL = URL(string: "https://raw.githubusercontent.com/kudit/Device/main/Sources/Models/\(fileName)")!
        return try? await fetchURL(urlString: rawURL.absoluteString)
    }

    private func modelCodeComparison(identifiers: [String], appleColors: [AppleMaterialColor]) -> ModelSourceCodeComparison? {
        guard !modelSource.isEmpty, !identifiers.isEmpty,
              let blocks = try? NSRegularExpression(pattern: #"(?ms)^[ \t]{8}[A-Za-z][A-Za-z0-9]*\([ \t\r\n]*officialName:\s*\"[^\"]+\".*?^[ \t]{8,}[^\n]*\),[ \t]*$"#) else { return nil }
        let blockMatches = blocks.matches(in: modelSource, range: NSRange(modelSource.startIndex..., in: modelSource))
        for match in blockMatches {
            guard let range = Range(match.range, in: modelSource) else { continue }
            let block = String(modelSource[range])
            guard let identifierMatch = block.firstMatch(pattern: #"(?s)identifiers\s*:\s*\[([^\]]+)\]"#), identifierMatch.count > 1 else { continue }
            let blockIdentifiers = identifierMatch[1].matches(pattern: #"\"([^\"]+)\""#).compactMap { $0.count > 1 ? $0[1] : nil }
            guard blockIdentifiers.contains(where: identifiers.contains),
                  let colorMatch = block.firstMatch(pattern: #"(?s)\bcolors\s*:\s*(\[[^\]]*\]|\.[A-Za-z_][A-Za-z0-9_]*)"#),
                  colorMatch.count > 1, !appleColors.isEmpty else { continue }

            let targetSignatures = appleColors.map(modelColorSignature)
            let actual = colorMatch[1]
            let matchingSets = [AppleMaterialColor].colorSets.filter { entry in
                entry.key.map(modelColorSignature) == targetSignatures || entry.key.map(modelColorSignature) == Array(targetSignatures.reversed())
            }
            let sourceSetName = actual.first == "." ? String(actual.dropFirst()) : nil
            let setEntry = matchingSets.first(where: { $0.value == sourceSetName })
                ?? matchingSets.sorted { lhs, rhs in
                    lhs.value.count == rhs.value.count
                        ? lhs.value.localizedStandardCompare(rhs.value) == .orderedAscending
                        : lhs.value.count < rhs.value.count
                }.first
            let setName = setEntry?.value ?? generatedColorSetName(for: blockIdentifiers.first ?? identifiers[0])
            let expectedExpression = ".\(setName)"
            guard let expressionRange = block.range(of: actual) else { continue }
            var proposed = block
            proposed.replaceSubrange(expressionRange, with: expectedExpression)
            if setEntry == nil, let range = proposed.range(of: expectedExpression) {
                proposed.replaceSubrange(range, with: expectedExpression + " /* define this named set from Apple comparison colors */")
            }
            return ModelSourceCodeComparison(actual: block.trimmed, proposed: proposed.trimmed)
        }
        return nil
    }

    private func modelColorSignature(_ color: AppleMaterialColor) -> String {
        "\(color.name.trimmingCharacters(in: .whitespacesAndNewlines))|\(color.swatches.map { $0.lowercased() }.joined(separator: ","))"
    }

    private func generatedColorSetName(for identifier: String) -> String {
        let stem = identifier.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: .regularExpression)
        let lowerCamel = String(stem.prefix(1)).lowercased() + String(stem.dropFirst())
        var candidate = lowerCamel.isEmpty ? "deviceColors" : lowerCamel + "Colors"
        let used = Set([AppleMaterialColor].colorSets.values)
        var suffix = 2
        while used.contains(candidate) {
            candidate = "\(lowerCamel)Colors\(suffix)"
            suffix += 1
        }
        return candidate
    }

    /// Extracts comparison-page color entries, retaining CSS class order so
    /// multi-tone products become ordered AppleMaterialColor swatches.
    private func comparisonColors(in html: String, styles: String) -> [String: ComparisonColorInfo] {
        let wrapperPattern = #"(?s)<div[^>]*class="[^"]*colornav-wrapper-([^"]+)"[^>]*>(.*?)</div>\s*</div>"#
        let wrapperMatches = html.matches(pattern: wrapperPattern)
        var result = [String: ComparisonColorInfo]()
        for wrapper in wrapperMatches {
            guard wrapper.count > 2 else { continue }
            let key = wrapper[1]
            let body = wrapper[2]
            var colors = [AppleMaterialColor]()
            for item in body.matches(pattern: #"(?s)<li[^>]*>(.*?)</li>"#) {
                guard item.count > 1 else { continue }
                let section = item[1]
                let tokens = section.matches(pattern: #"colornav-swatch-([A-Za-z0-9_-]+)"#).compactMap { $0.count > 1 ? $0[1] : nil }
                guard !tokens.isEmpty else { continue }
                let parsedLabel = section.extract(from: "<figcaption", to: "</figcaption>")?.tagsStripped.trimmed.whitespaceCollapsed
                let label = parsedLabel.flatMap { $0.caseInsensitiveCompare("Finish") == .orderedSame ? nil : $0 }
                    ?? tokens.map(displayName(forCSSKey:)).joined(separator: " / ")
                let hexes = tokens.map { cssHex(for: $0, wrapperKey: key, in: styles) }
                colors.append(AppleMaterialColor(swatches: hexes, name: label, cssKeys: tokens))
            }
            let css = tokensCSS(for: colors, wrapperKey: key, in: styles)
            result[key] = ComparisonColorInfo(colors: colors, wrapper: wrapper[0], css: css)
        }
        return result
    }

    private func tokensCSS(for colors: [AppleMaterialColor], wrapperKey: String, in styles: String) -> String {
        colors.flatMap(\.cssKeys).compactMap { token in
            let escaped = NSRegularExpression.escapedPattern(for: token)
            let pattern = #"(?is)[^{}]*\.colornav-swatch-"# + escaped + #"[^{}]*\{[^{}]*\}"#
            let matches = styles.matches(pattern: pattern).compactMap(\.first)
            let scoped = matches.filter { $0.contains(".colornav-wrapper-\(wrapperKey)") }
            let generic = matches.filter { !$0.contains(".colornav-wrapper-") }
            return (scoped.isEmpty ? generic : scoped).first
        }.joined(separator: "\n")
    }

    private func cssHex(for token: String, wrapperKey: String, in styles: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: token)
        let pattern = #"(?is)([^{}]*\.colornav-swatch-"# + escaped + #"[^{}]*)\{[^{}]*?(?:background(?:-color)?\s*:\s*)(#[0-9a-f]{3,8})[^{}]*\}"#
        let matches = styles.matches(pattern: pattern)
        let scoped = matches.filter { $0.count > 2 && $0[1].contains(".colornav-wrapper-\(wrapperKey)") }
        let generic = matches.filter { $0.count > 2 && !$0[1].contains(".colornav-wrapper-") }
        return (scoped.isEmpty ? generic : scoped).first.flatMap { $0.count > 2 ? $0[2] : nil } ?? "#808080"
    }

    private func displayName(forCSSKey key: String) -> String {
        let known = ["spaceblack": "Space Black", "spacegray": "Space Gray", "rosegold": "Rose Gold", "skyblue": "Sky Blue", "starlight": "Starlight", "midnight": "Midnight", "productred": "Product Red"]
        if let name = known[key.lowercased()] { return name }
        return key.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "[-_]", with: " ", options: .regularExpression)
            .capitalized
    }

    private func comparisonColors(for officialName: String) -> [AppleMaterialColor] {
        matchingComparisonInfo(for: officialName)?.colors ?? []
    }

    private func comparisonInfo(for officialName: String) -> ComparisonColorInfo? {
        matchingComparisonInfo(for: officialName)
    }

    private func matchingComparisonInfo(for officialName: String) -> ComparisonColorInfo? {
        func normalizedTokens(_ value: String) -> Set<String> {
            let expanded = value.lowercased()
                .replacingOccurrences(of: #"(\d+)(st|nd|rd|th)?gen\b"#, with: "$1$2 generation", options: .regularExpression)
            return Set(expanded.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).compactMap { token in
                switch token {
                case "gen": return "generation"
                case "in", "inch", "inches": return nil
                default: return String(token)
                }
            })
        }
        let target = normalizedTokens(officialName)
        let matches = comparisonColors.compactMap { key, value -> (Set<String>, ComparisonColorInfo)? in
            let candidate = normalizedTokens(key)
            return candidate == target || candidate.isSubset(of: target) || target.isSubset(of: candidate) ? (candidate, value) : nil
        }
        return matches.max { lhs, rhs in
            abs(target.count - lhs.0.count) > abs(target.count - rhs.0.count)
        }?.1
    }

    /// Generates a copy-pasteable proposal for a new or changed comparison
    /// color set. Existing exact swatches are marked for static-key lookup.
    private func colorProposal(for officialName: String, colors: [AppleMaterialColor]) -> String {
        let setKey = officialName.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: .regularExpression)
        let definitions = colors.enumerated().map { index, color in
            let cssKey = color.cssKeys.first ?? color.name.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: .regularExpression)
            let variable = cssKey + (index == 0 ? "" : "\(index)")
            if let existing = AppleMaterialColor.namedColors[color.name]?.first(where: { $0.swatches == color.swatches }) {
                let hex = existing.swatches.first ?? ""
                return "\tlet \(variable) = (.matched(\"\(hex)\")) // use the existing AppleMaterialColor static key"
            }
            let hex = color.swatches.first ?? "#808080"
            return "\tlet \(variable) = AMC(\"\(hex)\", \"\(color.name)\")"
        }.joined(separator: "\n")
        let names = colors.enumerated().map { index, color in
            let cssKey = color.cssKeys.first ?? color.name.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: .regularExpression)
            return cssKey + (index == 0 ? "" : "\(index)")
        }.joined(separator: ", ")
        return """
{
// \(officialName)
//public extension AppleMaterialColor {
\(definitions)
	let \(setKey) = [\(names)]
//}
//public extension [AppleMaterialColor] {
//	static let \(setKey) = AMC.\(setKey)
//}
//		.\(setKey): \"\(setKey)\",
	return \(setKey)
}()
"""
    }

    private enum WatchConnectivity {
        case legacy
        case gps
        case cellular
    }

    private struct WatchGroup {
        /// The Apple-facing product name used as the stable grouping key.
        var productName: String
        /// The visible case size, such as `42mm`; Ultra models intentionally omit
        /// this from the product name while still preserving it for model evidence.
        var size: String
        /// Whether this grouped product represents GPS-only, GPS + Cellular, or a
        /// legacy watch where Apple did not split the page by connectivity.
        var connectivity: WatchConnectivity
        /// Apple model numbers listed for this product group and case size.
        var models: [String] = []
        /// Colors parsed from Apple's visible material/color list for this group.
        var colors: [AppleMaterialColor] = []
        /// The aluminum image used by convention for GPS-only watch variants.
        var aluminumImage: String?
        /// The normal stainless/titanium image used by convention for cellular
        /// variants, excluding rare Edition, Hermes, Nike, ceramic, and gold images.
        var premiumImage: String?
        /// The first marketing image Apple presents for the family. Ultra models
        /// have only one product variant, so Apple's first image is authoritative.
        var firstImage: String?
    }

    private func parseWatchSections(_ sections: ArraySlice<String>, progress: (@Sendable (_ completed: Int, _ total: Int, _ message: String) -> Void)?) {
        let watchSections = sections.filter { section in
            guard let familyName = section.extract(from: ">", to: "</h2>")?.tagsStripped.trimmed.whitespaceCollapsed else {
                return false
            }
            return familyName.contains("Apple Watch")
        }
        let total = watchSections.count
        for (index, section) in watchSections.enumerated() {
            guard let familyName = section.extract(from: ">", to: "</h2>")?.tagsStripped.trimmed.whitespaceCollapsed,
                  familyName.contains("Apple Watch") else {
                continue
            }
            let groups = watchGroups(in: section, familyName: familyName)
            for group in groups {
                appendParsedWatchGroup(group, section: section)
            }
            progress?(index + 1, total, "Parsed \(index + 1) of \(total) Apple Watch sections")
        }
    }

    private func watchGroups(in section: String, familyName: String) -> [WatchGroup] {
        var groups = [String: WatchGroup]()
        let variants = section.components(separatedBy: "<h3 ")
        let variantSections = variants.count > 1 ? variants.dropFirst().map { "<h3 \($0)" } : ["<h2 \(section)"]
        for variant in variantSections {
            let variantName = variant.extract(from: ">", to: "</h3>")?.tagsStripped.trimmed.whitespaceCollapsed ?? familyName
            let connectivity = watchConnectivity(from: variantName, familyName: familyName)
            let image = variant.components(separatedBy: "<img").compactMap { $0.extract(from: "src=\"", to: "\"") }.first
            let material = watchMaterialKind(from: variantName, variant: variant, image: image)
            let colors = watchColors(from: variant, productName: familyName)
            for caseModel in watchCaseModels(from: variant) {
                let productName = watchProductName(familyName: familyName, connectivity: connectivity, size: caseModel.size)
                var group = groups[productName] ?? WatchGroup(productName: productName, size: caseModel.size, connectivity: connectivity)
                // Preserve source order before applying material preferences. This
                // is used by Ultra models, whose single identifier needs no GPS or
                // case-size image convention.
                if group.firstImage == nil {
                    group.firstImage = image
                }
                group.models += caseModel.models
                group.models.removeDuplicates()

                // GPS-only products are represented by aluminum watches.  Cellular
                // products include aluminum colors too, but their comparison image
                // should prefer the normal stainless/titanium marketing photo when
                // Apple lists one in the same family section.
                if connectivity == .gps {
                    if material == .aluminum, image != nil {
                        group.aluminumImage = image
                    }
                } else if connectivity == .cellular {
                    if material == .aluminum, image != nil {
                        group.aluminumImage = image
                    } else if material == .premium, image != nil, group.premiumImage == nil {
                        // For GPS + Cellular watches, use the first normal
                        // non-aluminum, non-Nike/Hermes/Edition marketing image
                        // Apple lists.  That is usually stainless steel and is
                        // titanium for newer Series models.
                        group.premiumImage = image
                    }
                } else {
                    if material == .premium, image != nil, group.premiumImage == nil {
                        group.premiumImage = image
                    } else if material == .aluminum, image != nil {
                        group.aluminumImage = image
                    }
                }
                // Special marketing variants may share this identifier and
                // therefore remain valid color evidence even though their
                // images are not representative of the common GPS model.
                // Edition and Hermes variants use the same cellular identifier,
                // so include their finishes while still excluding their images.
                // Legacy watches also consolidate material editions around the
                // case-size device definition, so retain every listed finish.
                group.colors += colors
                group.colors.removeDuplicates()
                groups[productName] = group
            }
        }
        return groups.values.sorted { $0.productName < $1.productName }
    }

    private enum WatchMaterialKind {
        case aluminum
        case premium
        case special
        case unknown
    }

    private func watchConnectivity(from variantName: String, familyName: String) -> WatchConnectivity {
        let variant = variantName.lowercased()
        if variant.contains("gps + cellular") || familyName.contains("Ultra") {
            return .cellular
        }
        if variant.contains("gps") {
            return .gps
        }
        return .legacy
    }

    private func watchMaterialKind(from variantName: String, variant: String, image: String?) -> WatchMaterialKind {
        let headingAndImage = "\(variantName) \(image ?? "")".lowercased()
        let lower = "\(headingAndImage) \(variant)".lowercased()
        if headingAndImage.containsAny(["herm", "nike", "edition", "ceramic"]) {
            return .special
        }
        if headingAndImage.containsAny(["stainless", "titanium"]) {
            return .premium
        }
        if lower.contains("aluminum") || lower.contains("sport") {
            return .aluminum
        }
        return .unknown
    }

    private func watchProductName(familyName: String, connectivity: WatchConnectivity, size: String) -> String {
        var baseName = familyName
            .replacingOccurrences(of: "(GPS + Cellular)", with: "")
            .replacingOccurrences(of: "(GPS)", with: "")
            .whitespaceCollapsed
            .trimmed
        if baseName.contains("Ultra") {
            // Ultra has one case size and one cellular-only identifier, so the
            // connectivity parenthetical does not distinguish another product.
            return baseName
        }
        switch connectivity {
        case .gps:
            baseName += " (GPS)"
        case .cellular:
            baseName += " (GPS + Cellular)"
        case .legacy:
            break
        }
        return "\(baseName) \(size)".whitespaceCollapsed.trimmed
    }

    private func watchCaseModels(from variant: String) -> [(size: String, models: [String])] {
        var caseModels = [(size: String, models: [String])]()
        let plainWatchSection = variant.tagsStripped.whitespaceCollapsed
        let modelLineParts = plainWatchSection.components(separatedBy: " case (Model:")
        for index in modelLineParts.indices.dropLast() {
            guard let caseSize = watchCaseSize(beforeModelText: modelLineParts[index]),
                  let modelSection = modelLineParts[index + 1].extract(from: nil, to: ")") else {
                continue
            }
            let models = modelNumbers(from: modelSection)
            if !models.isEmpty {
                caseModels.append((caseSize, models.unique))
            }
        }
        return caseModels
    }

    private func watchCaseSize(beforeModelText string: String) -> String? {
        string
            .replacingOccurrences(of: [")", "(", ",", ";"], with: " ")
            .components(separatedBy: " ")
            .map { $0.trimmed }
            .last { token in
                // The text immediately before `case (Model:)` is sometimes a
                // region or model phrase such as `mainland)` or `A1858)`.  Search
                // backward for the actual visible case size instead of trusting
                // the final word in that chunk.
                token.hasSuffix("mm") && token.dropLast(2).allSatisfy { $0.isNumber }
            }
    }

    private func modelNumbers(from string: String) -> [String] {
        string
            .replacingOccurrences(of: [",", ";", "(", ")", " and "], with: " ")
            .components(separatedBy: " ")
            .map { $0.trimmed }
            .filter { token in
                guard token.count == 5, token.first == "A" else {
                    return false
                }
                // Hardware model numbers use `A` plus four digits. Requiring the
                // complete shape avoids both regional words such as "Asia" and
                // chip names such as A17 in "iPad mini (A17 Pro)".
                return token.dropFirst().allSatisfy { $0.isNumber }
            }
    }

    private func watchColors(from variant: String, productName: String) -> [AppleMaterialColor] {
        var colors = [AppleMaterialColor]()
        let colorFragments = variant.components(separatedBy: "</li>")
        for fragment in colorFragments {
            let rawLine = fragment.tagsStripped.whitespaceCollapsed.trimmed
            let line = rawLine.extract(from: nil, to: " with ") ?? rawLine
            guard line.containsAny(["arat", "aluminum", "tainless", "titanium", "ceramic"]),
                  !line.containsAny(["mm case", "Retina display"]) else {
                continue
            }
            let lowercasedLine = line.lowercased()
            let materialName: String?
            if lowercasedLine.contains("aluminum") {
                materialName = "Aluminum"
            } else if lowercasedLine.contains("stainless") {
                materialName = "Stainless"
            } else if lowercasedLine.contains("titanium") {
                materialName = "Titanium"
            } else if lowercasedLine.contains("ceramic") {
                materialName = "Ceramic"
            } else if lowercasedLine.contains("18-karat") {
                materialName = "18-Karat"
            } else {
                materialName = nil
            }
            let colorLine = line
                .replacingOccurrences(of: [" and ", " or "], with: ", ")
                .replacingOccurrences(of: ["18-Karat", "aluminum", "stainless steel", "stainless", "titanium", "ceramic"], with: "")
            for colorName in colorLine.components(separatedBy: ",") {
                let cleanedName = colorName.trimmed
                guard !cleanedName.isEmpty else {
                    continue
                }
                let qualifiedName: String
                if productName.containsAny(["Series 8", "Series 9"]), materialName == "Stainless", cleanedName.lowercased() == "space black" {
                    // Series 8 and 9 list true Space Black in their Hermes block,
                    // while Graphite is already listed by the standard stainless
                    // block. Select the distinct Hermès finish directly.
                    qualifiedName = "Space Black Stainless"
                } else if materialName == "Titanium", cleanedName.lowercased().containsAny(["dark", "space black"]) {
                    // The Identify page calls the dark Series 5 titanium finish
                    // "Dark Titanium"; the device catalog uses Apple's
                    // comparison-page name, "Space Black Titanium".
                    qualifiedName = "Space Black Titanium"
                } else if productName.containsAny(["Series 5", "Series 6", "Series X"]), materialName == "Titanium", cleanedName.lowercased().containsAny(["light", "natural", "titanium"]) {
                    // The light Series 5 titanium finish is the catalog's
                    // unqualified "Titanium" entry.
                    // So is Series 6 unqualified Titanium.
                    qualifiedName = "Titanium"
                } else if productName.containsAny(["Series 6", "Series X"]), materialName == "Stainless", cleanedName.lowercased().containsAny(["space black"]) {
                    // This is Apple Watch Hermès and it really looks the same as graphite so go with that
                    qualifiedName = "Graphite Stainless"
                } else if materialName == "Stainless", cleanedName.lowercased().containsAny(["silver", "steel"]) {
                    qualifiedName = "Stainless Steel"
                } else if materialName == "Aluminum", cleanedName.lowercased().containsAny(["red"]) {
                    qualifiedName = .productRed + " Aluminum"
                } else {
                    // The catalog names finishes as "Color Material" (for
                    // example, "Rose Gold Aluminum"), while the old parser
                    // qualified only a short allowlist and generated the
                    // opposite order for those entries. Keep all material
                    // labels so same-named finishes resolve to the right set.
                    qualifiedName = materialName == "18-Karat"
                        ? "18-Karat \(cleanedName)"
                        : materialName.map { "\(cleanedName) \($0)" } ?? cleanedName
                }
                colors.append(AppleMaterialColor(named: qualifiedName, context: productName))
            }
            if lowercasedLine.contains("stainless steel") {
                // Apple describes the natural stainless finish as just
                // "stainless steel". Resolve that catalog name directly; the
                // unregistered "Silver Stainless" alias fell back to generic
                // Silver and made the parsed watch palette incorrect.
                colors.append(AppleMaterialColor(named: "Stainless Steel", context: productName))
            }
            if lowercasedLine.hasPrefix("titanium ") || lowercasedLine.hasPrefix("titanium or") {
                // A bare Titanium finish has no adjective left after material-word
                // removal, so retain the unqualified light titanium swatch.
                colors.append(AppleMaterialColor(named: "Titanium", context: productName))
            }
        }
        colors.removeDuplicates()
        return colors
    }

    private func appendParsedWatchGroup(_ group: WatchGroup, section: String) {
        var modelsByIdentifier = [String: [String]]()
        for model in group.models {
            if let device = Device.lookup(model: model, officialNameHint: group.productName).first {
                for identifier in device.identifiers {
                    modelsByIdentifier[identifier, default: []].append(model)
                }
            } else {
                debug("Unknown \(group.productName) model: \(model)", level: .WARNING)
            }
        }
        for (identifier, models) in modelsByIdentifier.sorted(by: { $0.key < $1.key }) {
            var capabilities = Capabilities()
            if group.connectivity == .cellular {
                capabilities.insert(.cellular(.lte))
            }
            let preferredImage: String?
            if group.productName.contains("Ultra") {
                // All Ultra entries are one-size cellular products; use the first
                // image exactly as Apple orders it on the identify page.
                preferredImage = group.firstImage
            } else if group.connectivity == .legacy {
                // First generation and Series 2 predate Apple's GPS/cellular page
                // split. Keep the established convention: aluminum for the 38mm
                // entry and ordinary stainless steel for the larger 42mm entry.
                preferredImage = group.size == "38mm"
                    ? (group.aluminumImage ?? group.premiumImage)
                    : (group.premiumImage ?? group.aluminumImage)
            } else {
                preferredImage = group.connectivity == .cellular
                    ? (group.premiumImage ?? group.aluminumImage)
                    : (group.aluminumImage ?? group.premiumImage)
            }
            var parsedItem = ParsedItem(
                officialName: group.productName,
                idiom: .watch,
                identifiers: [identifier],
                supportId: .unknownSupportId,
                image: preferredImage,
                capabilities: capabilities,
                partNumbers: models.unique,
                colors: group.colors,
                source: section)
            parsedItem.modelCodeComparison = modelCodeComparison(identifiers: [identifier], appleColors: group.colors)
            items.append(parsedItem)
        }
    }

    func parseItem(source: String) {
        var idiom = Device.Idiom.unspecified
        var identifiers: [String] = []
        var yearIntroduced: Int? = nil
        var supportId = String.unknownSupportId
        var unsupportedOSVersion: Version? = nil
        var image: String? = nil
        var capabilities = Capabilities()
        var partNumbers: [String] = []
        var colors: [AppleMaterialColor] = []
        var cpu = CPU.unknown
        var parsedIdentifiers = [String: [String]]()

        var string = source.replacingOccurrences(of: "‑", with: "-") // replace non-breaking hyphen with normal hyphen.
        let watchOfficialName = string.contains("Apple Watch") ? (
            string.extract(from: "class=\"gb-header\">", to: "</h2>")
            ?? string.extract(from: "class=\"gb-header\">", to: "</h3>")
        ) : nil

        // Apple TV sections don't have the identifier, just the model number
        guard var officialName = watchOfficialName ?? string.extract(from: nil, to: "</h") ?? string.extract(from: nil, to: "\" src=\"") else { // iPad Air first item has an empty span for the anchor tag.  Name should be in a header anyways.
            debug("Parse could not find a name section in: \(source)", level: .WARNING)
            return // needs a title at least!
        }
        if officialName.contains("src="), let macbookTitle = officialName.extract(from: nil, to: "\"") {
            officialName = macbookTitle
        }
        if officialName.contains("iPod") && !officialName.contains("iPod touch") {
            return // don't include iPods that aren't touches
        }
        if officialName.contains("Apple Vision") {
            idiom = .vision
        }
        // apple tv (becuase this is the same code run for Apple Vision Pro)
        if officialName.contains("Apple TV") {
            idiom = .tv
        }
        if officialName.contains("Apple Watch") {
            // pull off partial start tag
            if officialName.contains("class=\"gb-header\">") {
                guard let trimmed = officialName.extract(from: "class=\"gb-header\">", to: nil) else {
                    debug("Unable to get name for Apple Watch!: \(officialName)", level: .WARNING)
                    return
                }
                officialName = trimmed
            }
            // Apple now nests h3 variant blocks under a family h2; only the
            // explicit watch header text is the product name.  Avoid deriving the
            // name from the larger block because that pulls in duplicated h3 titles
            // and explanatory body copy.
            officialName = officialName.tagsStripped
//      debug("Parsing \(officialName)")
            idiom = .watch
        }
        // Keep explicit CPU alternatives so the shared grouping code can validate and scope them.
        officialName = officialName.tagsStripped.trimmed.whitespaceCollapsed.replacingOccurrences(of: "&nbsp;", with: " ")
        
        // make sure this isn't the header or footer section
        // note: original iphone has "The model number" so M isn't capitalized.
        guard string.contains("Model Identifier") || string.contains("odel number") || string.contains("Model:") else {
            debug("No models in this section so skipping", level: .DEBUG)
            return // don't add any
        }
        // strip out headers that aren't stripped from above.
        if string.contains("<!DOCTYPE html>") || string.contains("Find the model number") || string.contains("Find your Apple TV model number") {
            // bad Apple TV section
            return // don't add
        }
        // strip out additional header
        if string.hasPrefix("Find the model number") {
            string = string.extract(from: "<h2 id=\"ipadpro\" class=\"gb-header\">", to: nil) ?? string
        }

        // get introduction year
        if string.contains("Year introduced"), var yearIntroducedString = string.extract(from: "Year introduced: ", to: "</p>") {
            if yearIntroducedString.contains(" ") { // iPhone 3G and 4 have multple dates.
                yearIntroducedString = yearIntroducedString.replacingOccurrences(of: ",", with: " ").extract(from: nil, to: " ") ?? yearIntroducedString
            }
            yearIntroduced = Int(yearIntroducedString)
        } else {
            // try looking for year in officialName
            for year in 2000...Date.nowBackport.year {
                if officialName.contains("\(year)") {
                    yearIntroduced = Int(year)
                }
            }
        }
        
        if let identifierTag = string.extract(from: "Model Identifier", to: "</p>") {
            // could be multiple!  Pull first one
            // TODO: Possibly branch for multiple devices ParsedItems here?  If there is a pattern, set a flag to not merge?
            identifiers = identifierTag.replacingOccurrences(of: ", ", with: ";").replacingOccurrences(of: [":"," "], with: "").tagsStripped.components(separatedBy: ";").map { $0.trimmed }
//      let device = Device(identifier: self.identifiers!.first!, officialNameHint: self.title)
//      self.device = device
        }

        // get image URL
        let imageTag = string.extract(from: "<img class=\"gb-image\"", to: "/>") ?? string
        if let imageURL = imageTag.extract(from: "src=\"", to: "\"") {
            image = imageURL
        }
        let isiPhone = string.contains("iPhone")
        if isiPhone {
            idiom = .phone
        }
        let modelStartTag = "<ul class=\"list gb-list\"><li class=\"gb-list_item\"><p class=\"gb-paragraph\">"
        if string.contains("iPad") || string.contains("iPod") || isiPhone, var modelNumbers = string.extract(from: "odel number", to: isiPhone ? "</p>" : "</ul>") {
            // ipads (need to add the </p> tag since stripping tags may result in stuff between lines being removed.
            modelNumbers = modelNumbers.replacingOccurrences(of: ["</p>", "back cover", ".", ")", ":", "on", "and", "April", "August", "America", "Air", "Arab", "Armenia", "iPad", "Cellular", "Wi-Fi", ","], with: " ").tagsStripped.whitespaceCollapsed
            partNumbers = self.modelNumbers(from: modelNumbers)
        } else if var modelNumber = string.extract(from: "odel number", to: "</p>") {
            if let model = modelNumber.extract(from: ": ", to: " ") {
                modelNumber = model
                partNumbers = [modelNumber]
            } else {
                debug("Unable to parse model number: \(modelNumber)", level: .WARNING)
            }
        } else if let extractedPartNumbers = string.extract(from: "Part Number", to: "</p>"), let extractedPartNumbers = extractedPartNumbers.extract(from: ">", to: nil)?.replacingOccurrences(of: "&nbsp;", with: " ") {
            // macs
            partNumbers = extractedPartNumbers.replacingOccurrences(of: "; ", with: ", ").components(separatedBy: ", ").map { $0.trimmed }
        } else if let modelNumber = string.extract(from: modelStartTag, to: "</ul>") {
            // get case models (need to return 2 parsed items!) - just pull first case and up to user to copy to second?
            if let caseSize = modelNumber.extract(from: nil, to: " case"), let modelNumber = modelNumber.replacingOccurrences(of: ")", with: " ").extract(from: "Model: ", to: " ") {
                var title = officialName.replacingOccurrences(of: ["(GPS)", "(GPS + Cellular)", "Aluminum", "Stainless Steel"], with: "").trimmed
                // Apple Watch
                if !title.contains("Ultra") {
                    title += " \(caseSize)"
                }
                officialName = title
                partNumbers = [modelNumber]
            }
        } else if let extractedPartNumbers = string.extract(from: "Model: ", to: ")") {
            partNumbers = self.modelNumbers(from: extractedPartNumbers)
        }
        partNumbers.removeDuplicates()
//    partNumbers.sort() // we actually want the order parsed as this may not be alphabetical.
        
        if let newestCompatibleOS = string.extract(from: "Newest compatible operating system", to: "</p>") {
            if let newestCompatibleOS = newestCompatibleOS.extract(from: ">", to: nil)?.trimmed {
                // determine version
                for (version, _) in Version.macOSs {
                    if version.previousMacOS().macOSName == newestCompatibleOS { // can't just increment major version since many macOS 10.X is the version.
                        unsupportedOSVersion = version
                    }
                }
            }
        }
        
        // Get SupportID
        if idiom != .tv, let sid = string.extract(from: "<a href=\"/en-us/", to: "\"") {
            supportId = sid
        } else if idiom == .tv, let sid = string.extract(from: "See the <a href=\"https://support.apple.com/", to: "\"") { // fix since the remote support comes first on Apple TV models so we want to pull the actual support article, not the siri remote support ID.
            supportId = sid
        } else if let sid = string.extract(from: "<a href=\"https://support.apple.com/kb/", to: "\"") {
            supportId = sid
        } else if let sid = string.extract(from: "<a href=\"https://support.apple.com/en-us/", to: "\"") { // if it includes the en-us, ignore since we don't care about the localization since it should work regardless.
            // Apple sometimes returns localized article paths (for example `en-us/108044`) when parsing
            // modern numeric support pages, so remove the language prefix before matching local IDs.
            supportId = sid
        } else if let sid = string.extract(from: "<a href=\"https://support.apple.com/", to: "\"") {
            // iPads don't have the /kb/ part.
            supportId = sid
        }
        // fix since sp622 is lowercase for some reason
        supportId = supportId.uppercased()
        
        // try to parse idiom
        if idiom == .unspecified {
            for i in Device.Idiom.allCases {
                if string.contains(i.identifier) {
                    idiom = i
                    break
                }
            }
        }
                
        // check for string.contains("Thunderbolt") to register capability
        if string.contains("Thunderbolt") {
            capabilities.insert(.thunderbolt)
        }
        if string.contains("USB-C") {
            capabilities.insert(.usbC)
        }
        if string.contains("Headphone") {
            capabilities.insert(.headphoneJack)
        }
        if string.contains("Ethernet") {
            capabilities.insert(.ethernet)
        }
        if string.contains("Action button") {
            capabilities.insert(.actionButton)
        }
        if idiom == .watch && officialName.contains("GPS + Cellular") {
            // Apple Watch cellular support is encoded by separate model identifiers,
            // so preserve that distinction when parsing support-page groups.
            capabilities.insert(.cellular(.lte))
        }
        if string.contains("no SIM tray") && !string.contains("CDMA model has no SIM tray") {
            capabilities.insert(.esim)
        }

        // be sure not to hit on iPad with A17 Pro processor that isn't a pro device.
        if officialName.contains(" Pro") && !officialName.contains(" Pro)") {
            capabilities.insert(.pro)
        }
        if officialName.lowercased().contains(" mini") {
            capabilities.insert(.mini)
        }
        if officialName.contains(" Air") {
            capabilities.insert(.air)
        }
        if officialName.contains(" Plus") {
            capabilities.insert(.plus)
        }
        // On Apple support pages, Max is a device form-factor qualifier except
        // when it is embedded in a Mac processor name such as M5 Max.
        if officialName.contains(" Max") && idiom != .mac {
            capabilities.insert(.max)
        }
        
        // check for Mac form to add
        if idiom == .mac {
            let macForm: Mac.Form
            let year = yearIntroduced ?? Date.nowBackport.year // default to current year since 0 causes wrong models to be picked.
            if officialName.contains(" Pro") && year > 2015
                || officialName.contains(" Air") && year > 2017
                || officialName.contains("iMac") && year > 2020
            {
                if !identifiers.containsAny(["MacBookPro14,1", "MacBookPro13,1"]) { // 13 inch without touchbar
                    capabilities.insert(.biometrics(.touchID))
                }
            }
            if officialName.contains("Mac Pro") && !officialName.contains("iMac") {
                if year < 2013 {
                    macForm = .macProGen1
                } else if year == 2013 {
                    macForm = .macProGen2
                } else {
                    macForm = .macProGen3
                }
            } else if officialName.contains("MacBook") {
                if officialName.contains("PROLED XDR") {
                    // These MacBook Pros use the Dynamic Island and touch display form.
                    macForm = .macBookGen3
                } else if year < 2012 { // June 11, 2012
                    // MagSafe can be found on the MacBook (2006–2011), MacBook Pro (2006 through mid-2012, non-Retina) and MacBook Air (2008–2011) notebook computers.
                    macForm = .macBook
                    capabilities.insert(.magSafe1)
                } else if year < 2016 && officialName.contains(" Pro") || year < 2018 && officialName.contains(" Air") {
                    macForm = .macBookGen1 // MagSafe 2
                } else if year < 2021 || officialName.contains("MacBook Pro (13-inch, M2") {
                    // models with USB-C-only charging:
                    macForm = .macBook
                    capabilities.formUnion([.cameras([.faceTimeHD720p]), .usbC])
                } else { // default for new MacBook Pros
                    macForm = .macBookGen2
                }
            } else if officialName.contains("Mac mini") {
                macForm = .macMini
            } else if officialName.contains("Mac Studio") {
                macForm = .macStudio
            } else if officialName.contains("iMac") {
                macForm = .iMac
            } else {
                debug("Unknown Mac form: \(officialName)", level: .ERROR)
                macForm = .macBook
            }
            capabilities.insert(.macForm(macForm))
        }
        
        // Check for colors
        if string.contains("Colors:"), let parsedColors = string.extract(from: "Colors:", to: "</p>")?.tagsStripped.replacingOccurrences(of: " and ", with: ",").components(separatedBy: ",") {
            for c in parsedColors {
                let parsedColor = AppleMaterialColor(named: c.trimmed, context: officialName)
                colors.append(parsedColor)
            }
        }
		let overviewColors = colors
        // Prefer the comparison page's ordered, CSS-backed colors when the
        // product title can be matched; retain overview colors as a fallback.
        let comparisonColors = comparisonColors(for: officialName)
        if !comparisonColors.isEmpty {
            colors = comparisonColors
        }
        colors.removeDuplicates()
        var parsedSource = source
        if let info = comparisonInfo(for: officialName) {
            let hasExactMatch = !overviewColors.isEmpty && overviewColors.matchesPalette(info.colors)
            let matchStatus = hasExactMatch ? "exact match" : "new or mismatched colors"
            parsedSource += "\n\n<!-- Apple comparison color evidence -->\n\(info.wrapper)\n\n<!-- Parsed CSS -->\n\(info.css)\n\n<!-- Generated proposal (\(matchStatus)) -->\n\(colorProposal(for: officialName, colors: info.colors))"
        }

        // TODO: Check for <chip> section.
        var parsedChip: String?
        if string.contains("""
<p class="gb-paragraph"><b>Chip:
"""), let pc = string.extract(from: "<p class=\"gb-paragraph\"><b>Chip:", to: "</p>")?.tagsStripped.trimmed {
            parsedChip = pc
        } else if string.contains("This model has the"), let pc = string.extract(from: "This model has the", to: "chip")?.tagsStripped.trimmed, !pc.contains(" or ") {
            parsedChip = pc
        }
        if let parsedChip {
			// Apple titles already include their chip on many pages (including
			// "MacBook Pro (14-inch, M6)"); append only chip variants absent from the title.
			let chipChoices = Set(CPU.sourceChoices(in: parsedChip))
			let titleChoices = Set(CPU.sourceChoices(in: officialName))
			let chipAlreadyInTitle = chipChoices.isEmpty
				? officialName.localizedCaseInsensitiveContains(parsedChip)
				: chipChoices.isSubset(of: titleChoices)
			if !chipAlreadyInTitle {
				officialName += " \(parsedChip)"
			}
        }
        
        // A source can name several processors. Keep that ambiguity until the
        // common shared-support projection selects a specific local member.
        let cpuChoices = CPU.sourceChoices(in: parsedChip ?? officialName)
        cpu = cpuChoices.count == 1 ? cpuChoices[0] : .unknown

        // TODO: Determine when this is actually useful
//    if let matched, matched.safeOfficialName.normalizedCollapsedWhitespace.trimming(matched.cpu.caseName) == officialName.normalizedCollapsedWhitespace {
//      officialName = matched.officialName // ignore parsed name and use the matching device name for normalization
//    }
        
        if identifiers.count == 0 {
            // attempt to look up identifier in other ways
            
            // look through part numbers and add any matching identifiers.  May end up with a lot, but that would also hint to us that the part numbers are tied to specific identifiers.
            for partNumber in partNumbers {
                if let matched = Device.lookup(model: partNumber, officialNameHint: officialName).first {
                    identifiers.append(contentsOf: matched.identifiers)
                } else {
                    identifiers.append("UnknownPartNumber:\(partNumber)")
                }
            }
            
            // if we still don't have a matched device at this point, try looking up from the Support ID if available
            if supportId != .unknownSupportId, let matched = Device.lookup(supportId: supportId, officialNameHint: officialName).first {
                identifiers.append(contentsOf: matched.identifiers)
            }
        }
        // map to case name for generic handling of identifiers
        parsedIdentifiers[.unknown] = identifiers
        for (_, identifiers) in parsedIdentifiers {
            // Preserve the source grouping. Shared-support comparison resolves local
            // members without maintaining per-generation identifier/CPU exception maps here.
            var parsedItem = ParsedItem(
                officialName: officialName,
                idiom: idiom,
                identifiers: identifiers.unique,
                yearIntroduced: yearIntroduced,
                supportId: supportId,
                unsupportedOSVersion: unsupportedOSVersion,
                image: image,
                capabilities: capabilities,
                partNumbers: partNumbers,
                cpu: cpu,
                colors: colors,
                source: parsedSource)
            parsedItem.modelCodeComparison = modelCodeComparison(identifiers: identifiers, appleColors: colors)
            items.append(parsedItem)
        }
    }
}
