#if canImport(SwiftUI) && canImport(Foundation)
import Foundation
import SwiftUI
#if canImport(WebKit) && os(macOS)
import WebKit
#endif

private extension String {
	func comparisonMatches(pattern: String) -> [[String]] {
		guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
		return expression.matches(in: self, range: NSRange(startIndex..., in: self)).map { match in
			(0..<match.numberOfRanges).compactMap { index in
				guard let range = Range(match.range(at: index), in: self) else { return nil }
				return String(self[range])
			}
		}
	}
}

struct ComparisonImportSource: Identifiable, Hashable {
    let name: String
	let url: URL
	var id: String { name }
	var segmentTitle: String { name == "Apple Watch" ? "Watch" : name }
    static let all = [
        Self(name: "iPhone", url: URL(string: "https://www.apple.com/iphone/compare/")!),
        Self(name: "iPad", url: URL(string: "https://www.apple.com/ipad/compare/")!),
        Self(name: "Mac", url: URL(string: "https://www.apple.com/mac/compare/")!),
        Self(name: "Apple Watch", url: URL(string: "https://www.apple.com/watch/compare/")!),
    ]
}

private struct ImportedColor: Identifiable, Sendable {
    let key: String
    let color: AppleMaterialColor
    var id: String { key + color.name }
}

private struct ComparisonProduct: Sendable {
	let id: String
	let name: String
	let slug: String
}

private struct ComparisonImportOutcome: Sendable {
	let comparisons: [ImportedComparison]
	let skippedProducts: [String]
}

#if canImport(WebKit) && os(macOS)
@MainActor
private final class ComparisonDOMLoader: NSObject, WKNavigationDelegate {
	static let shared = ComparisonDOMLoader()
	private var webView: WKWebView?
	private var continuation: CheckedContinuation<String, Error>?
	private var readinessTask: Task<Void, Never>?
	private var expectedWrapperKeys: Set<String> = []

	func html(for url: URL, expectedSlugs: [String]) async throws -> String {
		let view: WKWebView
		if let webView {
			view = webView
		} else {
			let configuration = WKWebViewConfiguration()
			configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
			view = WKWebView(frame: .zero, configuration: configuration)
			view.navigationDelegate = self
			webView = view
		}
		return try await withCheckedThrowingContinuation { continuation in
			self.continuation = continuation
			expectedWrapperKeys = Set(expectedSlugs.map { $0.lowercased().filter { $0.isLetter || $0.isNumber } })
			var request = URLRequest(url: url)
			request.timeoutInterval = 5
			view.load(request)
		}
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		readinessTask?.cancel()
		readinessTask = Task { @MainActor in
			var previousKeys = Set<String>()
			var stableSnapshots = 0
			var latestObservedKeys: [String] = []
			for _ in 0..<20 {
				if Task.isCancelled { return }
				let script = """
				(() => {
					const wrappers = [...document.querySelectorAll('[class*="colornav-wrapper-"]')];
					const keyed = wrappers.map(element => {
						const name = [...element.classList].find(value => value.startsWith('colornav-wrapper-'));
						const key = name?.slice('colornav-wrapper-'.length).toLowerCase().replace(/[^a-z0-9]/g, '');
						const swatchCount = element.querySelectorAll('.colornav-swatch').length;
						return { key, signature: `${key}:${swatchCount}`, html: element.outerHTML };
					}).filter(value => value.key);
					return JSON.stringify({ observedKeys: keyed.map(value => value.key), matchedSignatures: keyed.map(value => value.signature), html: keyed.map(value => value.html).join('\\n') });
				})()
				"""
				if let result = try? await webView.evaluateJavaScript(script) as? String,
				   let data = result.data(using: .utf8),
				   let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
				   let observedKeys = payload["observedKeys"] as? [String],
				   let matchedSignatures = payload["matchedSignatures"] as? [String],
				   let wrappers = payload["html"] as? String {
					latestObservedKeys = Array(Set(observedKeys)).sorted()
					if !matchedSignatures.isEmpty && !wrappers.isEmpty {
						let currentKeys = Set(matchedSignatures)
						stableSnapshots = currentKeys == previousKeys ? stableSnapshots + 1 : 0
						previousKeys = currentKeys
						// Apple can omit ColorNav for individual products. Wait for a
						// stable, non-empty subset instead of requiring every requested slug.
						if stableSnapshots >= 2 {
							finish(.success(wrappers))
							return
						}
					} else {
						previousKeys = []
						stableSnapshots = 0
					}
				}
				try? await Task.sleep(nanoseconds: 250_000_000)
			}
			debug("ColorNav readiness timed out. Expected wrappers: \(expectedWrapperKeys.sorted()); observed: \(latestObservedKeys)", level: .WARNING)
			finish(.failure(ComparisonDOMLoaderError.pageDidNotRender))
		}
	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping @MainActor @Sendable (WKNavigationResponsePolicy) -> Void) {
		if let response = navigationResponse.response as? HTTPURLResponse, response.statusCode == 429 {
			decisionHandler(.cancel)
			finish(.failure(ComparisonDOMLoaderError.rateLimited))
		} else {
			decisionHandler(.allow)
		}
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
		finish(.failure(error))
	}

	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
		finish(.failure(error))
	}

	private func finish(_ result: Result<String, Error>) {
		readinessTask?.cancel()
		readinessTask = nil
		guard let continuation else { return }
		self.continuation = nil
		continuation.resume(with: result)
	}

	private static func jsonArray(_ values: [String]) -> String {
		guard let data = try? JSONSerialization.data(withJSONObject: values),
			  let string = String(data: data, encoding: .utf8) else { return "[]" }
		return string
	}
}

private enum ComparisonDOMLoaderError: LocalizedError {
	case pageDidNotRender
	case rateLimited

	var errorDescription: String? {
		switch self {
		case .pageDidNotRender: return "Apple’s comparison page did not render ColorNav data within five seconds."
		case .rateLimited: return "Apple rate-limited the comparison request (HTTP 429)."
		}
	}
}
#endif

private struct ComparisonStylesheet: Sendable {
	private struct Rule: Sendable {
		let selector: String
		let swatches: [String]
		let source: String
	}

	private let rulesBySwatch: [String: [Rule]]
	var swatchTokens: [String] { Array(rulesBySwatch.keys) }

	init(_ css: String) {
		let bytes = Array(css.utf8)
		let variables = Self.cssColorVariables(in: bytes)
		var rules: [String: [Rule]] = [:]
		var stack: [(selector: String, start: Int, bodyStart: Int)] = []
		var segmentStart = 0
		var index = 0
		var quote: UInt8?

		while index < bytes.count {
			let byte = bytes[index]
			if let activeQuote = quote {
				if byte == 92 { index += 2; continue }
				if byte == activeQuote { quote = nil }
				index += 1
				continue
			}
			if byte == 47, index + 1 < bytes.count, bytes[index + 1] == 42 {
				index += 2
				while index + 1 < bytes.count && !(bytes[index] == 42 && bytes[index + 1] == 47) { index += 1 }
				index = min(index + 2, bytes.count)
				continue
			}
			if byte == 34 || byte == 39 { quote = byte; index += 1; continue }
			if byte == 123 {
				stack.append(("", segmentStart, index + 1))
				segmentStart = index + 1
			} else if byte == 125 {
				if let frame = stack.popLast() {
					let declarationsRange = frame.bodyStart..<index
					let selectorRange = frame.start..<(frame.bodyStart - 1)
					if Self.containsSwatchMarker(in: bytes, range: selectorRange) {
						let selector = String(decoding: bytes[selectorRange], as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
						let tokens = Self.swatchTokens(in: selector)
						let swatches = Self.backgroundSwatches(in: bytes, range: declarationsRange, variables: variables)
						if !tokens.isEmpty, !swatches.isEmpty {
							let declarations = String(decoding: bytes[declarationsRange], as: UTF8.self)
							let source = "\(selector){\(declarations)}"
							for token in tokens {
								rules[Self.normalizedSwatchToken(token), default: []].append(Rule(selector: selector, swatches: swatches, source: source))
							}
						}
					}
				}
				segmentStart = index + 1
			}
			index += 1
		}
		rulesBySwatch = rules
	}

	func color(for token: String, wrapperKey: String) -> (hexes: [String]?, source: [String]) {
		let candidates = rulesBySwatch[Self.normalizedSwatchToken(token), default: []]
		let scoped = candidates.filter { rule in
			Self.wrapperKeys(in: rule.selector).contains(Self.normalizedSwatchToken(wrapperKey))
		}
		let generic = candidates.filter { !$0.selector.localizedCaseInsensitiveContains(".colornav-wrapper-") }
		let candidateHexes = Set(candidates.map(\.swatches))
		// Some family stylesheets spell wrapper keys differently. If no exact or
		// generic rule exists, accept a family-wide value only when every scoped
		// declaration for this swatch agrees on the same hex.
		let safeFamilyFallback = scoped.isEmpty && generic.isEmpty && candidateHexes.count == 1 ? candidates : []
		// Never borrow a generic `.red` rule for a Product Red swatch when the
		// stylesheet contains product-scoped declarations for that token.
		let preferred = !scoped.isEmpty ? scoped : (!generic.isEmpty && candidates.allSatisfy { !$0.selector.localizedCaseInsensitiveContains(".colornav-wrapper-") } ? generic : safeFamilyFallback)
		// CSS cascade order matters: when equally scoped rules repeat, the last
		// declaration is the one Apple’s page applies.
		let hexes = preferred.last?.swatches
		var source: [String] = []
		for value in preferred.map(\.source) where !source.contains(value) { source.append(value) }
		return (hexes, source)
	}

	private static func normalizedSwatchToken(_ token: String) -> String {
		String(token.lowercased().filter { $0.isLetter || $0.isNumber })
	}

	private static func wrapperKeys(in selector: String) -> [String] {
		guard let expression = try? NSRegularExpression(pattern: #"(?i)\.colornav-wrapper-([A-Za-z0-9_-]+)"#) else { return [] }
		return expression.matches(in: selector, range: NSRange(selector.startIndex..., in: selector)).compactMap { match in
			guard let range = Range(match.range(at: 1), in: selector) else { return nil }
			return normalizedSwatchToken(String(selector[range]))
		}
	}

	private static func backgroundSwatches(in bytes: [UInt8], range: Range<Int>, variables: [String: String]) -> [String] {
		let keys: [[UInt8]] = [Array("background-color".utf8), Array("background".utf8)]
		var index = range.lowerBound
		var best: [String] = []
		while index < range.upperBound {
			guard let key = keys.first(where: { key in
				index + key.count <= range.upperBound && bytes[index..<(index + key.count)].elementsEqual(key.map { $0 >= 65 && $0 <= 90 ? $0 + 32 : $0 })
			}) else { index += 1; continue }
			var valueStart = index + key.count
			while valueStart < range.upperBound && (bytes[valueStart] == 32 || bytes[valueStart] == 9 || bytes[valueStart] == 10 || bytes[valueStart] == 13) { valueStart += 1 }
			guard valueStart < range.upperBound, bytes[valueStart] == 58 else { index += key.count; continue }
			valueStart += 1
			while valueStart < range.upperBound && (bytes[valueStart] == 32 || bytes[valueStart] == 9 || bytes[valueStart] == 10 || bytes[valueStart] == 13) { valueStart += 1 }
			var valueEnd = valueStart
			while valueEnd < range.upperBound && bytes[valueEnd] != 59 { valueEnd += 1 }
			let value = String(decoding: bytes[valueStart..<valueEnd], as: UTF8.self)
			let valueBytes = Array(value.utf8)
			var colors: [String] = []
			var cursor = 0
			while cursor < valueBytes.count {
				if valueBytes[cursor] == 35 {
					var end = cursor + 1
					while end < valueBytes.count && ((48...57).contains(valueBytes[end]) || (65...70).contains(valueBytes[end]) || (97...102).contains(valueBytes[end])) { end += 1 }
					if (4...9).contains(end - cursor) { colors.append(String(decoding: valueBytes[cursor..<end], as: UTF8.self)) }
					cursor = end
				} else if cursor + 6 < valueBytes.count, valueBytes[cursor..<cursor + 6].elementsEqual(Array("var(--".utf8)) {
					var close = cursor + 6
					while close < valueBytes.count && valueBytes[close] != 41 { close += 1 }
					if close < valueBytes.count {
						let name = String(decoding: valueBytes[(cursor + 6)..<close], as: UTF8.self)
						if let hex = variables[name] { colors.append(hex) }
						cursor = close + 1
					} else { cursor += 1 }
				} else { cursor += 1 }
			}
			if !colors.isEmpty {
				var distinctStops: [String] = []
				for color in colors where distinctStops.last != color { distinctStops.append(color) }
				best = distinctStops
			}
			index = valueEnd
		}
		return best
	}

	private static func cssColorVariables(in bytes: [UInt8]) -> [String: String] {
		var result: [String: String] = [:]
		var index = 0
		while index + 3 < bytes.count {
			guard bytes[index] == 45, bytes[index + 1] == 45 else { index += 1; continue }
			let nameStart = index + 2
			var colon = nameStart
			while colon < bytes.count && (bytes[colon] == 45 || bytes[colon] == 95 || (48...57).contains(bytes[colon]) || (65...90).contains(bytes[colon]) || (97...122).contains(bytes[colon])) { colon += 1 }
			guard colon > nameStart else { index += 2; continue }
			var valueStart = colon
			while valueStart < bytes.count && (bytes[valueStart] == 32 || bytes[valueStart] == 9 || bytes[valueStart] == 10 || bytes[valueStart] == 13) { valueStart += 1 }
			guard valueStart < bytes.count, bytes[valueStart] == 58 else { index = colon; continue }
			valueStart += 1
			while valueStart < bytes.count && (bytes[valueStart] == 32 || bytes[valueStart] == 9 || bytes[valueStart] == 10 || bytes[valueStart] == 13) { valueStart += 1 }
			guard valueStart < bytes.count, bytes[valueStart] == 35 else { index = valueStart; continue }
			var valueEnd = valueStart + 1
			while valueEnd < bytes.count && ((48...57).contains(bytes[valueEnd]) || (65...70).contains(bytes[valueEnd]) || (97...102).contains(bytes[valueEnd])) { valueEnd += 1 }
			if (4...9).contains(valueEnd - valueStart) {
				let name = String(decoding: bytes[nameStart..<colon], as: UTF8.self)
				result[name] = String(decoding: bytes[valueStart..<valueEnd], as: UTF8.self)
			}
			index = valueEnd
		}
		return result
	}

	private static func containsSwatchMarker(in bytes: [UInt8], range: Range<Int>) -> Bool {
		let marker = Array(".colornav-swatch-".utf8)
		guard range.count >= marker.count else { return false }
		for start in range.lowerBound...(range.upperBound - marker.count) {
			if bytes[start..<(start + marker.count)].enumerated().allSatisfy({ offset, byte in
				let normalized = byte >= 65 && byte <= 90 ? byte + 32 : byte
				return normalized == marker[offset]
			}) { return true }
		}
		return false
	}

	private static func swatchTokens(in selector: String) -> [String] {
		let marker = ".colornav-swatch-"
		let normalizedSelector = selector.lowercased()
		var tokens: [String] = []
		var searchStart = normalizedSelector.startIndex
		while searchStart < normalizedSelector.endIndex,
			  let markerRange = normalizedSelector.range(of: marker, range: searchStart..<normalizedSelector.endIndex) {
			let start = markerRange.upperBound
			let end = normalizedSelector[start...].firstIndex { character in
				!(character.isLetter || character.isNumber || character == "-" || character == "_")
			} ?? normalizedSelector.endIndex
			if start < end { tokens.append(String(normalizedSelector[start..<end])) }
			searchStart = end < normalizedSelector.endIndex ? normalizedSelector.index(after: end) : end
		}
		return tokens
	}
}

private struct ImportedComparison: Identifiable, Sendable {
    let key: String
	let productName: String
	let stylesheetKey: String
    let rawWrapper: String
    let parsedCSS: String
    let colors: [ImportedColor]
	var id: String { key }
	var setKey: String { key.replacingOccurrences(of: "[^A-Za-z0-9]", with: "", options: .regularExpression) }
	func resolvingColors(in stylesheet: ComparisonStylesheet) -> (comparison: ImportedComparison?, missingKeys: [String]) {
		var missingKeys: [String] = []
		var rulesByKey: [String: [String]] = [:]
		let resolvedColors = colors.compactMap { item -> ImportedColor? in
			let resolved = item.color.cssKeys.map { stylesheet.color(for: $0, wrapperKey: stylesheetKey) }
			guard resolved.allSatisfy({ $0.hexes != nil }) else {
				missingKeys.append(contentsOf: zip(item.color.cssKeys, resolved).compactMap { key, value in value.hexes == nil ? key : nil })
				return nil
			}
			for (cssKey, result) in zip(item.color.cssKeys, resolved) { rulesByKey[cssKey] = result.source }
			let hexes = resolved.compactMap(\.hexes).flatMap { $0 }
			return ImportedColor(key: item.key, color: AppleMaterialColor(swatches: hexes, name: item.color.name, cssKeys: item.color.cssKeys))
		}
		guard missingKeys.isEmpty, resolvedColors.count == colors.count else {
			return (nil, Array(Set(missingKeys)).sorted())
		}
		let rules = Array(Set(resolvedColors.flatMap { $0.color.cssKeys })).sorted().flatMap { rulesByKey[$0] ?? [] }
		return (ImportedComparison(key: key, productName: productName, stylesheetKey: stylesheetKey, rawWrapper: rawWrapper, parsedCSS: rules.joined(separator: "\n\n"), colors: resolvedColors), [])
	}
}

private struct ComparisonDisplay: Identifiable, Sendable {
	let comparison: ImportedComparison
	let device: Device?
	var id: String { comparison.id }

	static func prepare(_ comparisons: [ImportedComparison], devices: [Device], family: String) -> [ComparisonDisplay] {
		let idiom: Device.Idiom
		switch family {
		case "iPhone": idiom = .phone
		case "iPad": idiom = .pad
		case "Mac": idiom = .mac
		case "Apple Watch": idiom = .watch
		default: return comparisons.map { ComparisonDisplay(comparison: $0, device: nil) }
		}
		let familyDevices = devices.filter { $0.idiom == idiom }
		let matchingDevices = family == "Apple Watch" && familyDevices.contains(where: { $0.cellular != nil })
			? familyDevices.filter { $0.cellular != nil }
			: familyDevices
		let normalizedDevices = matchingDevices.map { device in
			(device, canonicalName(device.officialName))
		}
		let linked = comparisons.map { comparison in
			let productName = canonicalName(comparison.productName)
			let exactMatches = normalizedDevices.filter { $0.1 == productName }
			let tokens = comparison.productName.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
			let candidates = exactMatches.isEmpty ? normalizedDevices : exactMatches
			let ranked = candidates.map { candidate in
				(candidate, score(candidate.1, tokens: tokens))
			}.sorted { lhs, rhs in
				if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
				if family == "Apple Watch", (lhs.0.0.cellular != nil) != (rhs.0.0.cellular != nil) {
					return lhs.0.0.cellular != nil
				}
				if lhs.0.0.colors.count != rhs.0.0.colors.count { return lhs.0.0.colors.count > rhs.0.0.colors.count }
				return lhs.0.0.identifiers.sorted().joined() < rhs.0.0.identifiers.sorted().joined()
			}
			let matched: Device?
			if let first = ranked.first, exactMatches.count == 1 {
				matched = first.0.0
			} else if let first = ranked.first, first.1 >= 2 {
				let tied = ranked.filter { $0.1 == first.1 }
				let watchPrefersCellular = family == "Apple Watch"
					&& first.0.0.cellular != nil
					&& tied.dropFirst().allSatisfy { $0.0.0.cellular == nil }
				let watchPrefersCompletePalette = family == "Apple Watch"
					&& tied.count > 1
					&& first.0.0.colors.count > (tied.dropFirst().map { $0.0.0.colors.count }.max() ?? 0)
				// A series-level Apple slug can represent both case sizes. If their
				// cellular palettes agree, a stable representative is safe for validation.
				let watchVariantsSharePalette = family == "Apple Watch" && tied.count > 1
					&& tied.dropFirst().allSatisfy { sameColorPalette(first.0.0.colors, $0.0.0.colors) }
				if (ranked.dropFirst().first.map({ $0.1 < first.1 }) ?? true) || watchPrefersCellular || watchPrefersCompletePalette || watchVariantsSharePalette {
					matched = first.0.0
				} else {
					// If color completeness can identify the watch variant, prefer it;
					// otherwise leave a genuinely ambiguous local match unlinked.
					matched = nil
				}
			} else {
				// An ambiguous fuzzy match is left unlinked rather than suggesting
				// edits to whichever similar model happens to occur first in Device.all.
				matched = nil
			}
			return ComparisonDisplay(comparison: comparison, device: matched)
		}
		var byDevice: [String: ComparisonDisplay] = [:]
		var unmatched: [ComparisonDisplay] = []
		for row in linked {
			guard let device = row.device else {
				unmatched.append(row)
				continue
			}
			let deviceKey = device.identifiers.sorted().joined(separator: ",")
			if let previous = byDevice[deviceKey] {
				if row.comparison.colors.count > previous.comparison.colors.count {
					byDevice[deviceKey] = row
				}
			} else {
				byDevice[deviceKey] = row
			}
		}
		return (Array(byDevice.values) + unmatched).sorted { lhs, rhs in
			let lhsDate = lhs.device?.introduction.map { String(describing: $0) } ?? "9999-99-99"
			let rhsDate = rhs.device?.introduction.map { String(describing: $0) } ?? "9999-99-99"
			return lhsDate == rhsDate
				? lhs.comparison.key.localizedStandardCompare(rhs.comparison.key) == .orderedAscending
				: lhsDate < rhsDate
		}
	}

	private static func score(_ normalizedName: String, tokens: [String]) -> Int {
		tokens.reduce(0) { total, token in
			let normalizedToken = String(token.filter { $0.isLetter || $0.isNumber })
			return total + (normalizedName.contains(normalizedToken) ? 1 : 0)
		}
	}

	private static func canonicalName(_ value: String) -> String {
		let normalized = value.lowercased().replacingOccurrences(of: "ʀ", with: "r")
		let tokens = normalized.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
		// Apple uses both numeric slugs ("6th-gen") and spelled-out model names.
		return tokens.compactMap { token -> String? in
			switch token {
			case "in", "inch": return nil
			case "generation": return "gen"
			case "first": return "1st"
			case "second": return "2nd"
			case "third": return "3rd"
			case "fourth": return "4th"
			case "fifth": return "5th"
			case "sixth": return "6th"
			case "seventh": return "7th"
			case "eighth": return "8th"
			case "ninth": return "9th"
			case "tenth": return "10th"
			default: return token
			}
		}.joined()
	}
}

private struct ColorSignature: Hashable, Sendable {
	let swatches: [String]
	let name: String

	init(_ color: AppleMaterialColor) {
		swatches = color.swatches.map { $0.lowercased() }
		// Finish names are part of the AMC identity, including capitalization.
		let trimmedName = color.name.trimmingCharacters(in: .whitespacesAndNewlines)
		let compactName = String(trimmedName.lowercased().filter { $0.isLetter || $0.isNumber })
		name = compactName == "productred" ? .productRed : trimmedName
	}
}

/// Only the dictionary key is canonicalized; rendered/source palettes retain their order.
private func paletteIdentity(_ values: [ColorSignature]) -> [ColorSignature] {
	let reverse = Array(values.reversed())
	return values.lexicographicallyPrecedes(reverse) { left, right in
		left.name == right.name ? left.swatches.lexicographicallyPrecedes(right.swatches) : left.name < right.name
	} ? values : reverse
}

/// Compare palette identity without relying on global catalog declaration order.
private func sameColorPalette(_ lhs: [AppleMaterialColor], _ rhs: [AppleMaterialColor]) -> Bool {
	// Keep the two source orders visible; equality accepts the photo's reverse direction.
	lhs.matchesPalette(rhs)
}

private struct ParsedColorCatalog: Sendable {
	let colorNames: [ColorSignature: [String]]
	let colorSets: [[ColorSignature]: [String]]
	let colorSetMembers: [String: [String]]
	let colorSignaturesByName: [String: ColorSignature]
	let definedColorNames: Set<String>
	let definedSetNames: Set<String>

	static func parse(_ source: String) -> ParsedColorCatalog? {
		var colors: [ColorSignature: [String]] = [:]
		var signaturesByName: [String: ColorSignature] = [:]
		var allColorNames = Set<String>()
		let colorPattern = #"(?m)^\s*static\s+let\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*AMC\(\s*(\[[^\]]*\]|"[^"]*")\s*,\s*"([^"]*)"\s*\)"#
		if let expression = try? NSRegularExpression(pattern: colorPattern) {
			for match in expression.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
				guard let keyRange = Range(match.range(at: 1), in: source),
					  let valueRange = Range(match.range(at: 2), in: source) else { continue }
				let value = String(source[valueRange])
				guard let hexExpression = try? NSRegularExpression(pattern: #"#[0-9a-fA-F]{3,8}"#) else { continue }
				let swatches = hexExpression.matches(in: value, range: NSRange(value.startIndex..., in: value)).compactMap { item -> String? in
					guard let range = Range(item.range, in: value) else { return nil }
					return String(value[range])
				}
				guard !swatches.isEmpty, let nameRange = Range(match.range(at: 3), in: source) else { continue }
				let name = String(source[nameRange])
				let color = AppleMaterialColor(swatches: swatches, name: name)
				let key = String(source[keyRange])
				let signature = ColorSignature(color)
				allColorNames.insert(key)
				// Preserve duplicate-valued identifiers so a matched Device can choose
				// its own family-specific constant instead of the catalog's first hit.
				if !colors[signature, default: []].contains(key) { colors[signature, default: []].append(key) }
				signaturesByName[key] = signature
			}
		}
		guard !colors.isEmpty else { return nil }

		var sets: [[ColorSignature]: [String]] = [:]
		var setMembers: [String: [String]] = [:]
		var allSetNames = Set<String>()
		let setPattern = #"(?m)^\s*static\s+let\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\[([^\]]*)\]"#
		if let expression = try? NSRegularExpression(pattern: setPattern) {
			for match in expression.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
				guard let nameRange = Range(match.range(at: 1), in: source), let valuesRange = Range(match.range(at: 2), in: source) else { continue }
				allSetNames.insert(String(source[nameRange]))
				let names = source[valuesRange].split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "^\\.", with: "", options: .regularExpression) }
				let signatures = names.compactMap { signaturesByName[$0] }
				guard signatures.count == names.count, !signatures.isEmpty else { continue }
				let setName = String(source[nameRange])
				setMembers[setName] = names
				if !sets[signatures, default: []].contains(setName) { sets[signatures, default: []].append(setName) }
			}
		}
		return ParsedColorCatalog(colorNames: colors, colorSets: sets, colorSetMembers: setMembers, colorSignaturesByName: signaturesByName, definedColorNames: allColorNames, definedSetNames: allSetNames)
}
}

private struct ParsedDeviceColorSource: Sendable {
	let colorsByIdentifier: [String: String]

	static func parse(_ source: String) -> ParsedDeviceColorSource {
		guard let blockExpression = try? NSRegularExpression(pattern: #"(?ms)^[ \t]{8}[A-Za-z][A-Za-z0-9]*\([ \t\r\n]*officialName:\s*\"[^\"]+\".*?^[ \t]{8,}[^\n]*\),[ \t]*$"#),
			  let identifierExpression = try? NSRegularExpression(pattern: #"(?s)identifiers\s*:\s*\[([^\]]+)\]"#),
			  let colorExpression = try? NSRegularExpression(pattern: #"(?s)\bcolors\s*:\s*(\[[^\]]*\]|\.[A-Za-z_][A-Za-z0-9_]*)"#),
			  let quotedExpression = try? NSRegularExpression(pattern: #"\"([^\"]+)\""#) else { return ParsedDeviceColorSource(colorsByIdentifier: [:]) }
		var colorsByIdentifier: [String: String] = [:]
		for match in blockExpression.matches(in: source, range: NSRange(source.startIndex..., in: source)) {
			guard let blockRange = Range(match.range, in: source) else { continue }
			let block = String(source[blockRange])
			let blockNSRange = NSRange(block.startIndex..., in: block)
			guard let identifierMatch = identifierExpression.firstMatch(in: block, range: blockNSRange),
				  let identifierListRange = Range(identifierMatch.range(at: 1), in: block),
				  let colorMatch = colorExpression.firstMatch(in: block, range: blockNSRange),
				  let colorRange = Range(colorMatch.range(at: 1), in: block) else { continue }
			let identifierSource = String(block[identifierListRange])
			let identifiers = quotedExpression.matches(in: identifierSource, range: NSRange(identifierSource.startIndex..., in: identifierSource)).compactMap { item -> String? in
				guard let range = Range(item.range(at: 1), in: identifierSource) else { return nil }
				return String(identifierSource[range])
			}
			for identifier in identifiers { colorsByIdentifier[identifier] = String(block[colorRange]).filter { !$0.isWhitespace } }
		}
		return ParsedDeviceColorSource(colorsByIdentifier: colorsByIdentifier)
	}

	func expression(for device: Device) -> String? {
		device.identifiers.compactMap { colorsByIdentifier[$0] }.first
	}
}

private enum ComparisonImportFetchError: LocalizedError {
	case comparisonPage
	case supplement
	case modelSlugs
	case colorsNotFound
	case stylesheet
	case unresolvedColors([String])

	var errorDescription: String? {
		switch self {
		case .comparisonPage: return "Apple’s comparison page could not be loaded."
		case .supplement: return "Apple’s supplement.json file could not be loaded."
		case .modelSlugs: return "Apple’s product catalog could not be read from the comparison page and supplement data."
		case .colorsNotFound: return "Apple’s comparison batches loaded, but none contained a usable ColorNav swatch list for the listed products."
		case .stylesheet: return "Apple’s comparison stylesheet could not be downloaded."
		case .unresolvedColors(let keys): return "No device swatches could be resolved from Apple’s comparison stylesheet (missing: \(keys.joined(separator: ", "))). No results were opened to avoid showing incorrect hex values."
		}
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
struct ComparisonImportView: View {
    @State private var selectedSource = ComparisonImportSource.all[0]
	@State private var parsed: [ImportedComparison] = []
	@State private var showingResults = false
	@State private var parsing = false
	@State private var fetchError: String?
	@State private var importWarning: String?
	@State private var fetchProgress: Double?
	@State private var fetchStatus = ""
	@State private var colorCatalog: ParsedColorCatalog?
	@State private var deviceColorSource: ParsedDeviceColorSource?

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Picker("Device family", selection: $selectedSource) {
				ForEach(ComparisonImportSource.all) { Text($0.segmentTitle).tag($0) }
			}
			.labelsHidden()
			.backport.pickerStyle(.segmented)
			.disabled(parsing)
			Link("Open \(selectedSource.name) comparison page", destination: selectedSource.url)
			Text("Fetch Apple’s current color data for every model in this family.")
				.font(.caption)
				.foregroundStyle(.secondary)
			if let fetchProgress {
				ProgressView(value: fetchProgress, total: 1) {
					Text(fetchStatus)
				} currentValueLabel: {
					Text("\(Int(fetchProgress * 100))%")
						.font(.caption.monospacedDigit())
				}
			}
			Button(parsing ? "Fetching Apple comparison data…" : "Fetch Apple comparison data") {
					parsing = true
					fetchProgress = 0
					fetchStatus = "Starting import…"
					let cachedCatalog = colorCatalog
					let family = selectedSource
					Compatibility.background {
						let result: Result<ComparisonImportOutcome, ComparisonImportFetchError>
						let loadedCatalog: ParsedColorCatalog?
						let loadedDeviceColorSource: ParsedDeviceColorSource?
						do {
							main {
								fetchProgress = 0.02
								fetchStatus = "Loading the AppleMaterialColor catalog…"
							}
							if let cachedCatalog {
								loadedCatalog = cachedCatalog
							} else if let source = await loadAppleMaterialColorSource() {
								debug("Successfully loaded catalog.")
								loadedCatalog = ParsedColorCatalog.parse(source)
							} else {
								debug("catalog may already be loaded or loading failed")
								loadedCatalog = nil
							}
							if let source = await loadDeviceColorSource(for: family) {
								loadedDeviceColorSource = ParsedDeviceColorSource.parse(source)
								debug("Loaded \(family.name) device color definitions for code validation.")
							} else {
								debug("Could not load \(family.name) model source; generated Device colors lines cannot be checked against the source definition.", level: .WARNING)
								loadedDeviceColorSource = nil
							}
							result = .success(try await fetchAppleComparisons { value, status in
								main {
									fetchProgress = value
									fetchStatus = status
								}
							})
						} catch let error as ComparisonImportFetchError {
							result = .failure(error)
						} catch {
							result = .failure(.comparisonPage)
						}
						let catalogForUI = loadedCatalog
						let deviceColorSourceForUI = loadedDeviceColorSource
						main {
							parsing = false
							colorCatalog = catalogForUI
							deviceColorSource = deviceColorSourceForUI
							fetchProgress = nil
							fetchStatus = ""
							switch result {
							case .success(let outcome):
								parsed = outcome.comparisons
								importWarning = outcome.skippedProducts.isEmpty ? nil : "Apple’s page did not provide usable finish data for: \(outcome.skippedProducts.joined(separator: ", "))."
								showingResults = true
							case .failure(let error):
								fetchError = error.localizedDescription
							}
						}
					}
				}
			.disabled(parsing)
		}
		.padding(20)
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		.navigationTitle("Comparison Import")
		.backport.navigationDestination(isPresented: $showingResults) { ComparisonImportResults(comparisons: parsed, colorCatalog: colorCatalog, deviceColorSource: deviceColorSource, family: selectedSource.name, importWarning: importWarning) }
		.task {
			guard colorCatalog == nil, let source = await loadAppleMaterialColorSource() else { return }
			debug("loaded AppleMaterialColor catalog in view task")
			colorCatalog = ParsedColorCatalog.parse(source)
		}
		.alert("Comparison Import Failed", isPresented: Binding(get: { fetchError != nil }, set: { if !$0 { fetchError = nil } })) {
			Button("OK", role: .cancel) { fetchError = nil }
		} message: {
			Text(fetchError ?? "")
		}
	}

	private func fetchAppleComparisons(progress: (Double, String) -> Void) async throws -> ComparisonImportOutcome {
		progress(0.05, "Fetching family comparison page…")
		guard let page = try? await fetchURL(urlString: selectedSource.url.absoluteString) else { throw ComparisonImportFetchError.comparisonPage }
		progress(0.25, "Fetching model and color names…")
		guard let supplementURL = URL(string: "supplement.json", relativeTo: selectedSource.url)?.absoluteURL,
			  let supplement = try? await fetchURL(urlString: supplementURL.absoluteString) else { throw ComparisonImportFetchError.supplement }
		guard let products = comparisonProducts(in: page, supplement: supplement), !products.isEmpty else { throw ComparisonImportFetchError.modelSlugs }
		progress(0.4, "Fetching family color stylesheet…")
		let cssURLs = stylesheetURLs(in: page)
		guard !cssURLs.isEmpty else { throw ComparisonImportFetchError.stylesheet }
		var stylesheetSources: [String] = []
		for cssURL in cssURLs {
			debug("Fetching Apple comparison stylesheet at \(cssURL.absoluteString)…")
			if let source = try? await fetchURL(urlString: cssURL.absoluteString) { stylesheetSources.append(source) }
		}
		guard !stylesheetSources.isEmpty else { throw ComparisonImportFetchError.stylesheet }
		progress(0.5, "Indexing stylesheet rules…")
		let stylesheet = ComparisonStylesheet(stylesheetSources.joined(separator: "\n"))
		debug("Indexed Apple comparison CSS swatch tokens: \(stylesheet.swatchTokens.sorted().joined(separator: ", "))")
		var resolvedBySlug: [String: ImportedComparison] = [:]
		var unresolvedKeys = Set<String>()
		var remainingProducts = products
		var retryQueue: [ComparisonProduct] = []
		var successfulProducts: [ComparisonProduct] = []
		var attemptsBySlug: [String: Int] = [:]
		var skippedSlugs = Set<String>()
		var batchIndex = 0
		let plannedBatchCount = max(1, (products.count + 2) / 3)
		while !remainingProducts.isEmpty || !retryQueue.isEmpty {
			batchIndex += 1
			var batch: [ComparisonProduct] = []
			while batch.count < 3, !retryQueue.isEmpty {
				let product = retryQueue.removeFirst()
				if !batch.contains(where: { normalizedSlug($0.slug) == normalizedSlug(product.slug) }) {
					batch.append(product)
				}
			}
			while batch.count < 3, !remainingProducts.isEmpty {
				let product = remainingProducts.removeFirst()
				if !batch.contains(where: { normalizedSlug($0.slug) == normalizedSlug(product.slug) }) {
					batch.append(product)
				}
			}
			// At the end, put a known-good product in spare slots. This keeps an
			// omitted model in a three-column request and changes its position on retry.
			for product in successfulProducts where batch.count < 3 {
				if !batch.contains(where: { normalizedSlug($0.slug) == normalizedSlug(product.slug) }) {
					batch.append(product)
				}
			}
			if batch.count == 3, let retry = batch.first(where: { attemptsBySlug[normalizedSlug($0.slug), default: 0] > 0 }) {
				// Rotate retries so a model omitted from a particular column is tested
				// in another position, using successful products as harmless fillers.
				let shift = attemptsBySlug[normalizedSlug(retry.slug), default: 1] % batch.count
				if shift > 0 {
					batch = Array(batch[shift...]) + Array(batch[..<shift])
				}
			}
			guard !batch.isEmpty else { break }
			let fraction = min(0.98, 0.5 + (Double(batchIndex - 1) / Double(max(plannedBatchCount, 1))) * 0.48)
			progress(fraction, "Fetching ColorNav batch \(batchIndex) of about \(plannedBatchCount)…")
			guard let batchURL = comparisonURL(for: batch) else { throw ComparisonImportFetchError.comparisonPage }
			var comparisons: [ImportedComparison] = []
			let batchPage: String?
#if canImport(WebKit) && os(macOS)
			do {
				batchPage = try await ComparisonDOMLoader.shared.html(for: batchURL, expectedSlugs: batch.map(\.slug))
			} catch {
				batchPage = nil
				debug("ColorNav batch \(batchIndex) failed: \(error.localizedDescription)", level: .WARNING)
			}
#else
			do {
				batchPage = try await fetchURL(urlString: batchURL.absoluteString)
			} catch {
				batchPage = nil
				debug("ColorNav batch \(batchIndex) failed: \(error.localizedDescription)", level: .WARNING)
			}
#endif
			if let batchPage { comparisons = comparisonsFromColorNav(in: batchPage, products: batch) }
			let parsedSlugs = Set(comparisons.map { normalizedSlug($0.key) })
			for product in batch where !successfulProducts.contains(where: { normalizedSlug($0.slug) == normalizedSlug(product.slug) }) && parsedSlugs.contains(normalizedSlug(product.slug)) {
				successfulProducts.append(product)
			}
			for product in batch where !parsedSlugs.contains(normalizedSlug(product.slug)) {
				let slug = normalizedSlug(product.slug)
				let attempts = attemptsBySlug[slug, default: 0] + 1
				attemptsBySlug[slug] = attempts
				if attempts < 3, !retryQueue.contains(where: { normalizedSlug($0.slug) == slug }) {
					retryQueue.append(product)
				} else if skippedSlugs.insert(slug).inserted {
					debug("Skipping Apple comparison product without a usable ColorNav wrapper after \(attempts) batched attempts: \(product.name) [\(product.slug)]", level: .WARNING)
				}
			}
			let groupedComparisons = Dictionary(grouping: comparisons, by: { normalizedSlug($0.key) })
			for (slug, candidates) in groupedComparisons {
				var validCandidates: [ImportedComparison] = []
				for comparison in candidates {
					let resolved = comparison.resolvingColors(in: stylesheet)
					guard let value = resolved.comparison else {
						unresolvedKeys.formUnion(resolved.missingKeys)
						debug("Skipping \(comparison.key): stylesheet has no color rule for \(resolved.missingKeys.joined(separator: ", ")); indexed tokens: \(stylesheet.swatchTokens.sorted().joined(separator: ", "))", level: .WARNING)
						continue
					}
					validCandidates.append(value)
				}
				guard let mostComplete = validCandidates.max(by: { $0.colors.count < $1.colors.count }) else { continue }
				let bestCount = mostComplete.colors.count
				let equallyComplete = validCandidates.filter { $0.colors.count == bestCount }
				let signature = mostComplete.colors.map { ColorSignature($0.color) }
				guard equallyComplete.allSatisfy({ $0.colors.map { ColorSignature($0.color) } == signature }) else {
					debug("Skipping ambiguous equally complete ColorNav wrappers for \(mostComplete.key).", level: .WARNING)
					continue
				}
				resolvedBySlug[slug] = mostComplete
			}
		}
		guard !resolvedBySlug.isEmpty else {
			if !unresolvedKeys.isEmpty { throw ComparisonImportFetchError.unresolvedColors(Array(unresolvedKeys).sorted()) }
			throw ComparisonImportFetchError.colorsNotFound
		}
		let uniqueComparisons = products.compactMap { resolvedBySlug[normalizedSlug($0.slug)] }
		let importedSlugs = Set(uniqueComparisons.map { normalizedSlug($0.key) })
		let skippedProducts = products.filter { !importedSlugs.contains(normalizedSlug($0.slug)) }.map(\.name)
		progress(1, skippedProducts.isEmpty
			? "Finished \(uniqueComparisons.count) devices."
			: "Imported \(uniqueComparisons.count) of \(products.count); skipped \(skippedProducts.count).")
		return ComparisonImportOutcome(comparisons: uniqueComparisons, skippedProducts: skippedProducts)
	}

	private func comparisonURL(for products: [ComparisonProduct]) -> URL? {
		guard var components = URLComponents(url: selectedSource.url, resolvingAgainstBaseURL: false) else { return nil }
		var queryItems = components.queryItems ?? []
		queryItems.removeAll { $0.name.caseInsensitiveCompare("modelList") == .orderedSame }
		queryItems.append(URLQueryItem(name: "modelList", value: products.map(\.slug).joined(separator: ",")))
		components.queryItems = queryItems
		return components.url
	}

	private func normalizedSlug(_ value: String) -> String {
		value.lowercased().filter { $0.isLetter || $0.isNumber }
	}

	private func stylesheetURLs(in page: String) -> [URL] {
		// Apple varies the locale segment and asset path between product families;
		// use the compare page's own stylesheet reference instead of guessing `/am/`.
		let linkTags = page.comparisonMatches(pattern: #"(?is)<link\b[^>]*>"#).compactMap(\.first)
		let stylesheetLinks = linkTags.compactMap { tag -> URL? in
			guard let href = tag.comparisonMatches(pattern: #"(?is)\bhref\s*=\s*[\"']([^\"']+\.css(?:\?[^\"']*)?)[\"']"#).first,
				  href.count > 1,
				  href[1].localizedCaseInsensitiveContains("/compare/") else { return nil }
			return URL(string: href[1], relativeTo: selectedSource.url)?.absoluteURL
		}
		var seenLinks = Set<URL>()
		let uniqueLinks = stylesheetLinks.filter { seenLinks.insert($0).inserted }
		var candidates = uniqueLinks
		// Some compare families keep their swatch/gradient rules in the sibling
		// main bundle rather than overview.built.css. Probe that sibling only when
		// Apple linked the overview bundle; a 404 is harmless and logged upstream.
		for url in uniqueLinks where selectedSource.name == "Mac" && url.lastPathComponent.localizedCaseInsensitiveCompare("overview.built.css") == .orderedSame {
			var sibling = url
			sibling.deleteLastPathComponent()
			sibling.appendPathComponent("main.built.css")
			if !candidates.contains(sibling) { candidates.append(sibling) }
		}
		return candidates.sorted { lhs, rhs in
			lhs.lastPathComponent.localizedCaseInsensitiveContains("overview")
				&& !rhs.lastPathComponent.localizedCaseInsensitiveContains("overview")
		}
	}

	private func loadAppleMaterialColorSource() async -> String? {
#if os(macOS)
		if let bundledSource = bundledMigrationSource(path: "AppleMaterialColor.swift") { return bundledSource }
#endif
		let githubURL = URL(string: "https://raw.githubusercontent.com/kudit/Device/main/Sources/AppleMaterialColor.swift")!
		if let source = try? await fetchURL(urlString: githubURL.absoluteString), !source.isEmpty { return source }
#if os(macOS)
		let localPaths = [
			URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Sources/AppleMaterialColor.swift").path,
			URL(fileURLWithPath: "/Users/\(NSUserName())/Documents/Kudit/Kudits/Library/Device.swiftpm/Sources/AppleMaterialColor.swift").path,
			("~/Documents/Kudit/Kudits/Library/Device.swiftpm/Sources/AppleMaterialColor.swift" as NSString).expandingTildeInPath
		]
		for localPath in localPaths where FileManager.default.fileExists(atPath: localPath) {
			debug("Attempting to load AppleMaterialColor.swift from local path: \(localPath)")
			if let source = try? String(contentsOfFile: localPath, encoding: .utf8) { return source }
		}
		return nil
#else
		return nil
#endif
	}

	private func loadDeviceColorSource(for family: ComparisonImportSource) async -> String? {
		let fileName: String
		switch family.name {
		case "iPhone": fileName = "iPhones.swift"
		case "iPad": fileName = "iPads.swift"
		case "Mac": fileName = "Macs.swift"
		case "Apple Watch": fileName = "AppleWatches.swift"
		default: return nil
		}
#if os(macOS)
		if let source = bundledMigrationSource(path: "Models/\(fileName)") { return source }
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

#if os(macOS)
	/// Reads the build-time source snapshot copied into the Debug app bundle.
	private func bundledMigrationSource(path: String) -> String? {
		guard let url = Bundle.main.resourceURL?.appendingPathComponent("MigrationSources").appendingPathComponent(path),
			  let source = try? String(contentsOf: url, encoding: .utf8), !source.isEmpty else { return nil }
		return source
	}
#endif

	private func comparisonProducts(in page: String, supplement json: String) -> [ComparisonProduct]? {
		guard let supplementData = json.data(using: .utf8),
			  let supplementObject = try? JSONSerialization.jsonObject(with: supplementData),
			  let supplement = supplementObject as? [String: Any] else { return nil }
		let pageRange = NSRange(page.startIndex..., in: page)
		let embeddedState = page.comparisonMatches(pattern: #"(?is)<(?:script|div)\b(?=[^>]*\bid=[\"']backport-data[\"'])[^>]*>(.*?)</(?:script|div)\s*>"#)
			.first?.dropFirst().first.flatMap { $0.data(using: .utf8) }
			.flatMap { try? JSONSerialization.jsonObject(with: $0) }
		if let embeddedState, let catalog = productCatalog(in: embeddedState) {
			let products = catalog.products.compactMap { id -> ComparisonProduct? in
				let dataEntry = catalog.data[id] as? [String: Any]
				let supplementEntry = supplement[id] as? [String: Any]
				let slug = localizedValue("en", in: dataEntry) ?? localizedValue("en", in: supplementEntry)
				guard let slug, !slug.isEmpty else { return nil }
				let name = dataEntry?["value"] as? String ?? supplementEntry?["value"] as? String ?? slug
				return ComparisonProduct(id: id, name: name, slug: slug)
			}
			if !products.isEmpty { return uniqueProducts(products) }
		}

		// Keep a fallback for Apple pages that still server-render product columns;
		// their source order is useful for catalog ordering, but swatches are always
		// taken from the selected products' ColorNav wrappers below.
		guard let productTags = try? NSRegularExpression(pattern: #"(?is)<div\b[^>]*\bdata-type=[\"']products[\"'][^>]*>"#),
			  let idExpression = try? NSRegularExpression(pattern: #"\bid=[\"']([^\"']+)[\"']"#) else { return nil }
		let ids = productTags.matches(in: page, range: pageRange).compactMap { match -> String? in
			guard let range = Range(match.range, in: page) else { return nil }
			let tag = String(page[range])
			guard let idMatch = idExpression.firstMatch(in: tag, range: NSRange(tag.startIndex..., in: tag)),
				  let idRange = Range(idMatch.range(at: 1), in: tag) else { return nil }
			return String(tag[idRange])
		}
		let products = ids.compactMap { id -> ComparisonProduct? in
			guard let entry = supplement[id] as? [String: Any], let slug = localizedValue("en", in: entry), !slug.isEmpty else { return nil }
			return ComparisonProduct(id: id, name: entry["value"] as? String ?? slug, slug: slug)
		}
		return products.count == ids.count && !products.isEmpty ? uniqueProducts(products) : nil
	}

	private func productCatalog(in value: Any) -> (products: [String], data: [String: Any])? {
		if let dictionary = value as? [String: Any] {
			if let products = dictionary["products"] as? [String], let data = dictionary["data"] as? [String: Any] {
				return (products, data)
			}
			for child in dictionary.values {
				if let result = productCatalog(in: child) { return result }
			}
		} else if let array = value as? [Any] {
			for child in array {
				if let result = productCatalog(in: child) { return result }
			}
		}
		return nil
	}

	private func localizedValue(_ language: String, in entry: [String: Any]?) -> String? {
		guard let entry else { return nil }
		if let direct = entry[language] as? String { return direct }
		return (entry["editor"] as? [String: Any])?[language] as? String
	}

	private func uniqueProducts(_ products: [ComparisonProduct]) -> [ComparisonProduct] {
		var seen = Set<String>()
		return products.filter { seen.insert(normalizedSlug($0.slug)).inserted }
	}

	private func comparisonsFromColorNav(in page: String, products: [ComparisonProduct]) -> [ImportedComparison] {
		guard let wrapperExpression = try? NSRegularExpression(
			pattern: #"(?is)<div\b[^>]*\bclass=[\"'][^\"']*\bcolornav-wrapper-([^\s\"']+)[^\"']*[\"'][^>]*>"#),
			let itemExpression = try? NSRegularExpression(pattern: #"(?is)<li\b[^>]*>(.*?)</li>"#),
			let swatchExpression = try? NSRegularExpression(pattern: #"colornav-swatch-([A-Za-z0-9_-]+)"#) else { return [] }
		let pageRange = NSRange(page.startIndex..., in: page)
		var parsed: [ImportedComparison] = []
		for match in wrapperExpression.matches(in: page, range: pageRange) {
			guard match.numberOfRanges > 1,
				  let keyRange = Range(match.range(at: 1), in: page),
				  let wrapperRange = balancedDivRange(openingMatch: match, in: page),
				  let wrapperTextRange = Range(wrapperRange, in: page) else { continue }
			let wrapperKey = String(page[keyRange])
			let wrapper = String(page[wrapperTextRange])
			guard let product = comparisonProduct(for: wrapperKey, wrapper: wrapper, products: products) else { continue }
			let wrapperNSRange = NSRange(wrapper.startIndex..., in: wrapper)
			var colors: [ImportedColor] = []
			let listItems = itemExpression.matches(in: wrapper, range: wrapperNSRange)
			// Parse each list item regardless of whether Apple renders its link as
			// a button or a div; mixed markup must not silently drop some finishes.
			for itemMatch in listItems {
				guard itemMatch.numberOfRanges > 1, let itemRange = Range(itemMatch.range(at: 1), in: wrapper) else { continue }
				let itemHTML = String(wrapper[itemRange])
				let itemNSRange = NSRange(itemHTML.startIndex..., in: itemHTML)
				let tokens = swatchExpression.matches(in: itemHTML, range: itemNSRange).compactMap { swatchMatch -> String? in
					guard swatchMatch.numberOfRanges > 1, let range = Range(swatchMatch.range(at: 1), in: itemHTML) else { return nil }
					return String(itemHTML[range])
				}
				guard !tokens.isEmpty else { continue }
				let captionMatches = itemHTML.comparisonMatches(pattern: #"(?is)<figcaption\b[^>]*>(.*?)</figcaption>"#)
				let captionLabel = captionMatches.first.flatMap { $0.count > 1 ? htmlText($0[1]) : nil }
				let rawLabel = colornavLabel(in: itemHTML)
					?? captionLabel.flatMap { $0.isEmpty || $0.caseInsensitiveCompare("Finish") == .orderedSame ? nil : $0 }
					?? tokens.map { displayName(forCSSKey: $0) }.joined(separator: " / ")
				let label = canonicalFinishName(rawLabel)
				let color = AppleMaterialColor(swatches: Array(repeating: "#808080", count: tokens.count), name: label, cssKeys: tokens)
				colors.append(ImportedColor(key: swiftIdentifier(from: tokens.joined(separator: " ")), color: color))
			}
			if !colors.isEmpty {
				parsed.append(ImportedComparison(key: product.slug, productName: product.name, stylesheetKey: wrapperKey, rawWrapper: wrapper, parsedCSS: "", colors: colors))
			}
		}
		return parsed
	}

	private func comparisonProduct(for wrapperKey: String, wrapper: String, products: [ComparisonProduct]) -> ComparisonProduct? {
		if let exact = products.first(where: { normalizedSlug($0.slug) == normalizedSlug(wrapperKey) }) { return exact }
		// Apple sometimes gives a rendered ColorNav wrapper a legacy CSS key that
		// differs from the comparison slug. Its accessible label identifies the
		// actual product, so use that before considering any positional association.
		let label = wrapper.comparisonMatches(pattern: #"(?is)aria-label=[\"']Select a finish for (.*?)[\"']"#).first?.last
		guard let label else { return nil }
		let productName = normalizedProductName(htmlText(label))
		return products.first(where: { normalizedProductName($0.name) == productName })
	}

	private func normalizedProductName(_ value: String) -> String {
		let tokens = value.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
		return tokens.filter { $0 != "in" && $0 != "inch" }.joined()
	}

	private func balancedDivRange(openingMatch: NSTextCheckingResult, in html: String) -> NSRange? {
		// Match a containing div by depth because Finish rows contain nested divs.
		guard let divExpression = try? NSRegularExpression(pattern: #"(?is)</?div\b[^>]*>"#) else { return nil }
		let start = openingMatch.range.location
		let scanRange = NSRange(location: start, length: html.utf16.count - start)
		var depth = 0
		var result: NSRange?
		divExpression.enumerateMatches(in: html, range: scanRange) { match, _, stop in
			guard let match, let range = Range(match.range, in: html) else { return }
			let tag = String(html[range])
			if tag.hasPrefix("</") {
				depth -= 1
			} else if !tag.hasSuffix("/>") {
				depth += 1
			}
			if depth == 0 {
				result = NSRange(location: start, length: NSMaxRange(match.range) - start)
				stop.pointee = true
			}
		}
		return result
	}

	private func htmlText(_ value: String) -> String {
		value.replacingOccurrences(of: #"<[^>]*>"#, with: " ", options: .regularExpression)
			.replacingOccurrences(of: "&nbsp;", with: " ")
			.replacingOccurrences(of: "&#x27;", with: "'")
			.replacingOccurrences(of: "&amp;", with: "&")
			.replacingOccurrences(of: "&quot;", with: "\"")
			.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
			.trimmingCharacters(in: .whitespacesAndNewlines)
	}

	private func swiftIdentifier(from token: String) -> String {
		let parts = token.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
		guard let first = parts.first else { return "swatch" }
		var identifier = String(first).lowercased() + parts.dropFirst().map { $0.prefix(1).uppercased() + String($0.dropFirst()) }.joined()
		if identifier.first?.isNumber == true { identifier = "swatch" + identifier }
		return identifier
	}

	private func displayName(forCSSKey key: String) -> String {
		let known = ["spaceblack": "Space Black", "spacegray": "Space Gray", "rosegold": "Rose Gold", "skyblue": "Sky Blue", "starlight": "Starlight", "midnight": "Midnight", "productred": .productRed, "red": .productRed]
		if let name = known[key.lowercased()] { return name }
		return key.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
			.replacingOccurrences(of: "[-_]", with: " ", options: .regularExpression)
			.capitalized
	}

	private func canonicalFinishName(_ label: String) -> String {
		let normalized = String(label.lowercased().filter { $0.isLetter || $0.isNumber })
		return normalized == "productred" ? .productRed : label
	}

	private func colornavLabel(in row: String) -> String? {
		let pattern = #"(?is)<(?:figcaption|span|div)\b[^>]*class=[\"'][^\"']*\bcolornav-label\b[^\"']*[\"'][^>]*>(.*?)</(?:figcaption|span|div)>"#
		guard let expression = try? NSRegularExpression(pattern: pattern),
			  let match = expression.firstMatch(in: row, range: NSRange(row.startIndex..., in: row)),
			  let labelRange = Range(match.range(at: 1), in: row) else { return nil }
		let label = htmlText(String(row[labelRange]))
		return label.isEmpty || label.caseInsensitiveCompare("Finish") == .orderedSame ? nil : label
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct ComparisonImportResults: View {
    let comparisons: [ImportedComparison]
	let colorCatalog: ParsedColorCatalog?
	let deviceColorSource: ParsedDeviceColorSource?
	let family: String
	let importWarning: String?
	@State private var expanded: Set<String> = []
	@State private var preparedComparisons: [ComparisonDisplay] = []
	private var comparisonRevision: Int {
		var hasher = Hasher()
		for comparison in comparisons {
			hasher.combine(comparison.key)
			hasher.combine(comparison.productName)
			hasher.combine(comparison.rawWrapper)
			hasher.combine(comparison.colors.map { ColorSignature($0.color) })
		}
		return hasher.finalize()
	}
	private var generatedSwift: String {
		var generatedColors: [ColorSignature: String] = [:]
		var generatedSets: [[ColorSignature]: String] = [:]
		var blocks: [String] = []
		var proposalByDevice: [Device: ComparisonDisplay] = [:]
		var unlinkedProposals: [ComparisonDisplay] = []
		for row in preparedComparisons {
			guard let device = row.device else {
				unlinkedProposals.append(row)
				continue
			}
			if let previous = proposalByDevice[device] {
				let rowMatches = colorsMatch(device.colors, row.comparison.colors.map(\.color))
				let previousMatches = colorsMatch(device.colors, previous.comparison.colors.map(\.color))
				if (rowMatches && !previousMatches) || row.comparison.colors.count > previous.comparison.colors.count {
					proposalByDevice[device] = row
				}
			} else {
				proposalByDevice[device] = row
			}
		}
		// Device is the proposal key: duplicate Apple slugs or equally scored
		// wrapper rows cannot emit multiple edits for one local definition.
		let proposalRows = (Array(proposalByDevice.values) + unlinkedProposals).sorted { lhs, rhs in
			let lhsDate = lhs.device?.introduction.map { String(describing: $0) } ?? "9999-99-99"
			let rhsDate = rhs.device?.introduction.map { String(describing: $0) } ?? "9999-99-99"
			return lhsDate == rhsDate
				? lhs.comparison.key.localizedStandardCompare(rhs.comparison.key) == .orderedAscending
				: lhsDate < rhsDate
		}
		let incomingPaletteUseCounts = Dictionary(grouping: proposalRows, by: { paletteIdentity($0.comparison.colors.map { ColorSignature($0.color) }) })
		for row in proposalRows {
			let palette = paletteIdentity(row.comparison.colors.map { ColorSignature($0.color) })
			let block = swiftCode(for: row.comparison, matchedDevice: row.device, incomingPaletteUseCount: incomingPaletteUseCounts[palette]?.count ?? 1, generatedColors: &generatedColors, generatedSets: &generatedSets)
			if !block.isEmpty { blocks.append(block) }
		}
		return blocks.joined(separator: "\n\n")
	}
	var body: some View {
		Group {
			if preparedComparisons.isEmpty {
				ProgressView("Preparing device comparisons…")
			} else {
				GeometryReader { geometry in
				HStack(spacing: 0) {
					ScrollView {
						VStack(alignment: .leading, spacing: 10) {
							if let importWarning {
								Label(importWarning, systemImage: "exclamationmark.triangle.fill")
									.font(.caption)
									.foregroundStyle(.orange)
							}
							if colorCatalog == nil {
								Label("AppleMaterialColor.swift was not loaded; generated names are provisional.", systemImage: "exclamationmark.triangle.fill")
									.font(.caption)
									.foregroundStyle(.orange)
							}
							if deviceColorSource == nil {
								Label("Device model source was not loaded; colors: suggestions are not source-validated.", systemImage: "exclamationmark.triangle.fill")
									.font(.caption)
									.foregroundStyle(.orange)
							}
							Text(generatedSwift)
								.font(.system(size: 14, design: .monospaced))
								.backport.textSelection(.enabled)
								.frame(maxWidth: .infinity, alignment: .leading)
						}
						.padding()
					}
					.frame(width: geometry.size.width * 0.62)
					.frame(maxHeight: .infinity)
					.overlay(alignment: .topLeading) {
						if generatedSwift.isEmpty {
							Text("No code changes needed.")
								.foregroundStyle(.secondary)
								.padding()
						}
					}
					Divider()
					// Apple can repeat wrapper keys; offset identity avoids duplicate
					// SwiftUI outline IDs while preserving the sorted display order.
					List(Array(preparedComparisons.enumerated()), id: \.offset) { entry in
						let row = entry.element
						let comparison = row.comparison
						let localColors = row.device?.colors ?? comparison.colors.compactMap { AppleMaterialColor.namedColors[$0.color.name]?.first }
						let exactMatch = colorsMatch(localColors, comparison.colors.map(\.color))
						Backport.DisclosureGroup(
							isExpanded: Binding(
								get: { expanded.contains(comparison.id) },
								set: { isExpanded in
									if isExpanded { expanded.insert(comparison.id) } else { expanded.remove(comparison.id) }
								})) {
							ColorComparisonList(colors: localColors, title: "Matched local colors")
									Text(comparison.parsedCSS).font(.system(.caption, design: .monospaced)).backport.textSelection(.enabled)
									Text(comparison.rawWrapper).font(.system(.caption2, design: .monospaced)).backport.textSelection(.enabled)
						} label: {
							VStack(alignment: .leading, spacing: 8) {
								if let device = row.device { DeviceInfoView(device: device) } else { Text(comparison.key).font(.headline) }
								ColorComparisonList(colors: comparison.colors.map(\.color), title: "Parsed CSS colors")
									.font(exactMatch ? .caption2 : .title)
							}
						}
					}
					.frame(width: geometry.size.width * 0.38)
					.frame(maxHeight: .infinity)
				}
				}
			}
		}
		.navigationTitle("Imported Comparisons")
		.task(id: comparisonRevision) {
			let revision = comparisonRevision
			preparedComparisons = []
			expanded.removeAll()
			let comparisons = self.comparisons
			let prepared = await Task.detached(priority: .userInitiated) {
			// Device.all is lazily initialized; keep that catalog construction off the UI actor too.
			ComparisonDisplay.prepare(comparisons, devices: Device.all, family: family)
			}.value
			guard !Task.isCancelled, revision == comparisonRevision else { return }
			preparedComparisons = prepared
			for row in prepared {
				let local = row.device?.colors ?? row.comparison.colors.compactMap { AppleMaterialColor.namedColors[$0.color.name]?.first }
				if !colorsMatch(local, row.comparison.colors.map(\.color)) { expanded.insert(row.id) }
			}
		}
    }

    /// Apple wrapper keys use compact slugs such as `ipad-air-11-m4`, while
    /// local definitions use human-readable names such as `iPad Air (11-inch,
    /// M4)`. Score shared normalized tokens so the header shows that exact
    /// local device rather than the first generic family match.
    private func matchedDevice(for key: String) -> Device? {
        let tokens = key.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        return Device.all.max { lhs, rhs in score(lhs, tokens: tokens) < score(rhs, tokens: tokens) }
    }

	private func score(_ device: Device, tokens: [String]) -> Int {
		let normalized = String(device.officialName.lowercased().filter { $0.isLetter || $0.isNumber })
		return tokens.reduce(0) { total, token in
			let normalizedToken = String(token.filter { $0.isLetter || $0.isNumber })
			return total + (normalized.contains(normalizedToken) ? 1 : 0)
		}
	}

	private func colorsMatch(_ local: [AppleMaterialColor], _ parsed: [AppleMaterialColor]) -> Bool {
		if sameColorPalette(local, parsed) { return true }
		// Comparison tables can omit legacy finishes (notably Jet Black and
		// (PRODUCT)RED). Treat a color-accurate ordered subset as validation of the
		// known palette, not as a request to delete colors from the Device record.
		guard parsed.count < local.count else { return false }
		func orderedSubset(_ sequence: [AppleMaterialColor]) -> Bool {
			var nextLocalIndex = 0
			for parsedColor in sequence {
				guard let localIndex = local[nextLocalIndex...].firstIndex(where: { sameColorPalette([$0], [parsedColor]) }) else { return false }
				nextLocalIndex = local.index(after: localIndex)
			}
			return true
		}
		return orderedSubset(parsed) || orderedSubset(Array(parsed.reversed()))
	}
	private func normalizedFinishKey(_ name: String) -> String {
		let normalized = String(name.lowercased().filter { $0.isLetter || $0.isNumber })
		return normalized.contains("productred") ? "productred" : normalized
	}
	private func canonicalFinishName(_ name: String) -> String {
		normalizedFinishKey(name) == "productred" ? .productRed : name
	}
	private var familyDevices: [Device] {
		let idiom: Device.Idiom
		switch family {
		case "iPhone": idiom = .phone
		case "iPad": idiom = .pad
		case "Mac": idiom = .mac
		case "Apple Watch": idiom = .watch
		default: return []
		}
		return Device.all.filter { $0.idiom == idiom }
	}
	private func swiftCode(for comparison: ImportedComparison, matchedDevice matched: Device?, incomingPaletteUseCount: Int, generatedColors: inout [ColorSignature: String], generatedSets: inout [[ColorSignature]: String]) -> String {
		let signatures = comparison.colors.map { ColorSignature($0.color) }
		let generatedSetName = generatedSets[signatures] ?? generatedSets[Array(signatures.reversed())]
		let matchingFamilyDevices = familyDevices.filter { sameColorPalette($0.colors, comparison.colors.map(\.color)) }
		let localDeviceUsageCount = matchingFamilyDevices.count
		let catalogSetNames = (colorCatalog?.colorSets[signatures] ?? []) + (colorCatalog?.colorSets[Array(signatures.reversed())] ?? [])
		let referencedFamilySetNames = matchingFamilyDevices.compactMap { device -> String? in
			guard let expression = deviceColorSource?.expression(for: device),
			      let match = expression.comparisonMatches(pattern: #"^\.([A-Za-z_][A-Za-z0-9_]*)$"#).first,
			      match.count > 1 else { return nil }
			return match[1]
		}
		let existingFamilySetName = referencedFamilySetNames.first(where: { catalogSetNames.contains($0) })
		let importedColors = comparison.colors.map(\.color)
		let currentColorsMatch = matched.map { sameColorPalette($0.colors, importedColors) } == true
		let appleOnlyConfirmsKnownSubset = matched.map { $0.colors.count > importedColors.count && colorsMatch($0.colors, importedColors) } == true
		// A unique set already present on its device is validated; proposing a new
		// named colorset would add code without improving reuse or correctness.
		let additionalIncomingUses = max(0, incomingPaletteUseCount - (currentColorsMatch ? 1 : 0))
		let shouldUseNamedSet = existingFamilySetName != nil || generatedSetName != nil || localDeviceUsageCount + additionalIncomingUses > 1
		// Apple may omit legacy options such as Jet Black and (PRODUCT)RED;
		// that omission is not evidence that the local Device definition is wrong.
		if appleOnlyConfirmsKnownSubset { return "" }
		if currentColorsMatch && !shouldUseNamedSet { return "" }
		let existingSetName = existingFamilySetName ?? generatedSetName
		var colorReferences: [String] = []

		var generatedNames = Set<String>()
		var additionLines: [String] = []
		let localNames = localColorIdentifiers(for: matched)
		for item in comparison.colors {
			let signature = ColorSignature(item.color)
			let preferredLocalName = localNames.first(where: { colorCatalog?.colorSignaturesByName[$0] == signature })
			let existingName = preferredLocalName ?? colorCatalog?.colorNames[signature]?.first ?? generatedColors[signature]
			if let existingName {
				colorReferences.append(existingName)
				continue
			}
			var generatedName = item.key
			var suffix = 1
			while colorCatalog?.definedColorNames.contains(generatedName) == true || generatedColors.values.contains(generatedName) || generatedNames.contains(generatedName) {
				generatedName = suffix == 1 ? "\(item.key)\(comparison.setKey)" : "\(item.key)\(comparison.setKey)\(suffix)"
				suffix += 1
			}
			generatedNames.insert(generatedName)
			colorReferences.append(generatedName)
			generatedColors[signature] = generatedName
			let values = item.color.swatches.count == 1
				? "\"\(item.color.swatches[0])\""
				: "[\(item.color.swatches.map { "\"\($0)\"" }.joined(separator: ", "))]"
			additionLines.append("\tstatic let \(generatedName) = AMC(\(values), \"\(signature.name)\")")
		}
		let additions = additionLines.joined(separator: "\n")
		let setSeed = colorReferences.prefix(2).joined()
		let setBase = setSeed.prefix(1).lowercased() + String(setSeed.dropFirst()) + "Set"
		var setName = existingSetName ?? String(setBase)
		if shouldUseNamedSet && existingSetName == nil && (colorCatalog?.definedSetNames.contains(setName) == true || generatedSets.values.contains(setName)) {
			var suffix = 2
			while colorCatalog?.definedSetNames.contains("\(setBase)\(suffix)") == true || generatedSets.values.contains("\(setBase)\(suffix)") { suffix += 1 }
			setName = "\(setBase)\(suffix)"
		}
		let shouldCreateNamedSet = shouldUseNamedSet && existingFamilySetName == nil && generatedSetName == nil
		let colorAssignment = shouldUseNamedSet ? ".\(setName)" : "[\(colorReferences.map { ".\($0)" }.joined(separator: ", "))]"
		let currentSourceExpression = matched.flatMap { deviceColorSource?.expression(for: $0) }
		let sourceExpressionMatches = currentSourceExpression.map { $0 == colorAssignment.filter { !$0.isWhitespace } }
		let isConfigured = currentColorsMatch && (sourceExpressionMatches == true || (sourceExpressionMatches == nil && deviceColorSource == nil && existingFamilySetName != nil))
		guard !isConfigured else { return "" }
		if shouldCreateNamedSet { generatedSets[signatures] = setName }
        let addColorDefinitions = additions.isEmpty ? "" : "public extension AppleMaterialColor {\n\(additions)\n}\n\n"
		let addSetDefinition = shouldCreateNamedSet ? "public extension AppleMaterialColor {\n\tstatic let \(setName) = [\(colorReferences.joined(separator: ", "))]\n}\n\npublic extension [AppleMaterialColor] {\n\tstatic let \(setName) = AppleMaterialColor.\(setName)\n}\n\n" : ""
        let deviceName = matched?.officialName ?? comparison.key
        let identifier = matched?.identifiers.first ?? "No local identifier match"
		let needsDeviceUpdate = !currentColorsMatch || sourceExpressionMatches == false || (deviceColorSource != nil && sourceExpressionMatches == nil)
		let deviceNote = matched.flatMap { _ in
			guard needsDeviceUpdate else { return nil }
			return "// Update \(deviceName) (\(identifier)) in its Device definition:\n            colors: \(colorAssignment),\n"
		} ?? ""
		let deviceTypeEntry = shouldCreateNamedSet ? "// Add to deviceTypeColorSet:\n\t.\(setName): \"\(setName)\",\n" : ""
		// Suppress a device header when the imported colors already match and no
		// color declarations, shared set, or device update would be generated.
		guard !additions.isEmpty || shouldCreateNamedSet || !deviceNote.isEmpty || !deviceTypeEntry.isEmpty else { return "" }
		return """
// \(deviceName)
// Identifier: \(identifier)
\(addColorDefinitions)\(addSetDefinition)\(deviceNote)
\(deviceTypeEntry)
"""
    }

	private func localColorIdentifiers(for device: Device?) -> [String] {
		guard let device, let expression = deviceColorSource?.expression(for: device) else { return [] }
		let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.first == "." {
			let setName = String(trimmed.dropFirst())
			// Resolve named-set members to retain the exact color constants already
			// selected by this Device definition.
			if let members = colorCatalog?.colorSetMembers[setName] { return members }
		}
		guard let identifierExpression = try? NSRegularExpression(pattern: #"\.?([A-Za-z_][A-Za-z0-9_]*)"#) else { return [] }
		return identifierExpression.matches(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)).compactMap { match in
			guard let range = Range(match.range(at: 1), in: trimmed) else { return nil }
			return String(trimmed[range])
		}
	}

    private func legacySwiftCode(for comparison: ImportedComparison) -> String {
        let matched = matchedDevice(for: comparison.key)
        let matchedName = matched?.officialName ?? comparison.key
        let matchedIdentifier = matched?.identifiers.first ?? "No local identifier match"
        let declarations = comparison.colors.map { item in
            let value = item.color.swatches.count == 1
                ? "\"\(item.color.swatches[0])\""
                : "[\(item.color.swatches.map { "\"\($0)\"" }.joined(separator: ", "))]"
            return "\tstatic let \(item.key) = AMC(\(value), \"\(item.color.name)\")"
        }.joined(separator: "\n")
        let values = comparison.colors.map { $0.key }.joined(separator: ", ")
        return """
// \(matchedName)
// Identifier: \(matchedIdentifier)
public extension AppleMaterialColor {
\(declarations)
\tstatic let \(comparison.setKey) = [\(values)]
}

public extension [AppleMaterialColor] {
\tstatic let \(comparison.setKey) = AppleMaterialColor.\(comparison.setKey)
}

// Add to deviceTypeColorSet:
\t.\(comparison.setKey): \"\(comparison.setKey)\",
"""
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct ColorComparisonList: View {
    let colors: [AppleMaterialColor]
    let title: String
    var body: some View {
		VStack(alignment: .leading) {
			Text(title).font(.headline)
			HStack {
				ForEach(colors) { color in
					VStack { Circle().fill(color.leftToRightGradient).frame(width: 24, height: 24); Text(color.name).font(.caption)
					}
					.help(color.definition)
				}
			}
		}
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct HighlightedColorCode: View {
    let comparison: ImportedComparison
    let localColors: [AppleMaterialColor]
    let code: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Generated Swift").font(.headline)
            ForEach(Array(code.split(separator: "\n", omittingEmptySubsequences: false).enumerated()), id: \.offset) { _, line in
                Text(String(line))
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(lineContainsMismatch(String(line)) ? .red : .primary)
            }
        }
		.backport.textSelection(.enabled)
    }
    private func lineContainsMismatch(_ line: String) -> Bool {
        guard line.contains("static let") else { return false }
        guard let item = comparison.colors.first(where: { line.contains("static let \($0.key)") }) else { return false }
        return !localColors.contains(where: { $0.name == item.color.name && $0.swatches == item.color.swatches })
    }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
#Preview("Comparison Import") { NavigationStack { ComparisonImportView() } }
#endif
