//
//  DeviceBridge.swift
//  Device
//
//  Created by Ben Ku on 4/27/25.
//

//@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
/// An object representing a native version of a conversion item for comparison.
protocol DeviceBridge: Identifiable, Equatable, Sendable, Codable, PropertyIterable {
    /// filter out and ignore these paths when calculating exact match - for things like DeviceKit comments or images/support URLs since those may be different and aren't as easily constructed
    static var diffIgnoreKeys: [String] { get }
    /// A string representation of the source (HTML clipping, JSON row, Text row
    var source: String { get }
    /// A specific Device that is the best match for this bridge data.  If multiple potentially match, we should pick the best match for this item (if this may happen, create multiple device bridges which will match with different devices).
    var matched: Device { get }
    /// A Device with updated fields based on this Bridge's values filling the matched device's values only when bridge values are missing.  Should be primarily the bridge's values though in case there is no device match or there is a conflict.
    var merged: Device { get }
    /// Source-format representation used by Bridge comparison tabs.
    /// Concrete bridges can override this with a repository-specific code generator.
    var definition: String { get }
    /// create a bridged version of a Device (will use to create diff views from matched and merged)
    func bridge(from device: Device) -> Self
    /// Compares a field after applying source-specific normalization rules.
    func bridgeValuesEqual(_ key: String, _ left: Any?, _ right: Any?) -> Bool
    /// Allows a source to classify a missing optional field as compatible while
    /// retaining strict comparison when both sources provide different values.
    func compatibleWhenMergedDiffers(_ key: String, left: Any?, merged: Any?, right: Any?) -> Bool
    /// Hardware identifiers explicitly represented by this source row, before any local merge.
    var comparisonIdentifiers: [String] { get }
    /// Explicit source CPU alternatives, when the format provides them.
    var comparisonCPUs: [CPU] { get }
    /// Projects a validated grouped row onto one local definition for comparison, leaving the source row intact.
    func comparison(for member: Device, in group: [Device]) -> Self
}
protocol DeviceBridgeLoader: Sendable {
    /// Every loader produces one concrete bridge record type, which keeps the
    /// generic comparison view type-safe when it accesses bridge properties.
    associatedtype Bridge: DeviceBridge
    /// Get a list of the Bridge device type devices (likely from text that is parsed hence async)
    func devices() async throws -> [Bridge]
    /// Get bridge devices while optionally reporting deterministic progress for loaders
    /// that can count their sections before parsing them.
    func devices(progress: (@Sendable (_ completed: Int, _ total: Int, _ message: String) -> Void)?) async throws -> [Bridge]
    /// URL for use in links to allow viewing the source document easily.
    var sourceURL: String { get }
    /// Name for use in navigation and titles
    var name: String { get }
}
extension DeviceBridgeLoader {
    var source: URL { URL(string: sourceURL)! }
    func devices(progress: (@Sendable (_ completed: Int, _ total: Int, _ message: String) -> Void)?) async throws -> [Bridge] {
        // Most loaders fetch a single decoded payload and do not have meaningful
        // section-level progress; keep their old behavior until they opt in.
        try await devices()
    }
}
import SwiftUI
enum MatchType: Sendable {
    case identical
    case compatible // important fields match
    case mismatched // important fields mismatch
    
    var color: Color {
        switch self {
        case .identical:
            return .green
        case .compatible:
            return .yellow
        case .mismatched:
            return .red
        }
    }
}
struct BridgeFieldDiff {
    let fieldName: String
    let leftValue: String
    let rightValue: String
    let mergedValue: String
    let matchType: MatchType
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension DeviceBridge {
    var definition: String { source }
    // Sources without an identifier collection remain ordinary single-record comparisons.
    var comparisonIdentifiers: [String] { [] }
    var comparisonCPUs: [CPU] { [] }
    func comparison(for member: Device, in group: [Device]) -> Self { self }

    /// Distinct local definitions explicitly covered by a valid source group.
    /// A shared real support ID is evidence of a family relationship, not permission
    /// to combine processors or silently accept unknown identifiers and other errors.
    var groupedDevices: [Device] {
        let group = Device.sourceGroup(identifiers: comparisonIdentifiers)
        let sourceCPUs = Set(comparisonCPUs.filter { $0 != .unknown })
        // A matching support page must not hide a source claiming a different processor family.
        guard sourceCPUs.isSubset(of: Set(group.map { $0.cpu })) else { return [] }
        return group
    }

    /// Source-specific views of each member; each still carries exactly one local CPU/identifier relationship.
    var groupedComparisons: [Self] {
        let group = groupedDevices
        return group.map { comparison(for: $0, in: group) }
    }

    /// All output definitions. Copy/export callers must use this instead of losing all but the first group member.
    var mergedDevices: [Device] {
        let members = groupedComparisons
        return members.isEmpty ? [merged] : members.map { $0.merged }
    }

    // default implementation
    static var diffIgnoreKeys: [String] {
        [] // filter out and ignore these paths when calculating exact match - for things like DeviceKit comments or images/support URLs since we know those may differ
    }
    /// Uses exact reflected values unless a bridge provides a narrower comparison.
    func bridgeValuesEqual(_ key: String, _ left: Any?, _ right: Any?) -> Bool {
        areEqual(left, right)
    }
    func compatibleWhenMergedDiffers(_ key: String, left: Any?, merged: Any?, right: Any?) -> Bool { false }
    var matchType: MatchType {
        let members = groupedComparisons
        if !members.isEmpty {
            // Grouping is acknowledged as compatible, while a real field error in
            // any projected member still makes the complete source row a mismatch.
            // A validated support-ID grouping is an exact match when no projected
            // member differs; the grouping itself is not a warning.
            if members.contains(where: { $0.matchType == .mismatched }) {
                // Shared-support GPS/cellular rows can differ only in the
                // presentation fields used to split the group. That is a
                // compatible source grouping, not a hardware data failure.
                let groupingOnly = members.allSatisfy { member in
                    member.diffs.enumerated().allSatisfy { index, value in
                        value != .mismatched || ["identifiers", "comment", "description", "safeDescription", "caseName"].contains(member.allKeyPaths.keys[index])
                    }
                }
                return groupingOnly ? .compatible : .mismatched
            }
            return .identical
        }
        var overallMatchType: MatchType = .identical
        for diff in diffs {
            if diff == .mismatched {
                return .mismatched
            }
            if diff == .compatible {
                overallMatchType = .compatible
            }
        }
        return overallMatchType
    }
    private var diffs: [MatchType] {
        // This trace is intentionally emitted once per comparison calculation;
        // it identifies the exact field that makes a bridge red and helps find
        // accidental repeated calculations from view rendering.
        debug("🪲 (String(describing: Self.self)): calculating diffs for \(id)")
        var diffs = [MatchType]()
        let matched = matchedBridge
        let merged = mergedBridge
        for (key, path) in self.allKeyPaths {
            var matchType = MatchType.identical
            let left = matched[keyPath: path]
            let right = self[keyPath: path]
            let merged = merged[keyPath: path]
            // A bridge support identifier is actionable when Device has no
            // value. Do not let the merge inherit the source and hide the
            // missing local catalog entry.
            if key == "supportId", let local = left as? String, let source = right as? String,
               local == .unknownSupportId, source != .unknownSupportId {
                diffs.append(.mismatched)
                continue
            }
            if !bridgeValuesEqual(key, left, merged) {
                if compatibleWhenMergedDiffers(key, left: left, merged: merged, right: right) || Self.diffIgnoreKeys.contains(key) {
                    matchType = .compatible
                } else {
                    matchType = .mismatched
                }
            } else if !bridgeValuesEqual(key, left, right) {
                // left and merged are equal so will return as identical, but if left and right aren't equal, consider this a compatible match not identical
                matchType = .compatible
            }
            diffs.append(matchType)
            if matchType == .mismatched {
                debug("🪲 \(String(describing: Self.self)): red field \(key) for \(id)")
            }
        }
        return diffs
    }
    var id: String { source }
    
    var deviceCode: String {
        mergedDevices.map { $0.definition }.joined(separator: "\n")
    }
    
    var matchedBridge: Self {
        self.bridge(from: matched)
    }
    
    var mergedBridge: Self {
        self.bridge(from: merged)
    }

    /// Produces a compact, copyable report containing only meaningful bridge differences.
    ///
    /// The report keeps the matched Device value, source value, and merged result together so a
    /// pasted report is enough to decide whether the correction belongs in Device or upstream.
    var deltaReport: String {
        let members = groupedComparisons
        if !members.isEmpty {
            // Keep a valid grouping out of proposed source corrections; only actual
            // member differences are emitted below the explanatory group heading.
            let heading = "Grouped source: \(members.count) separate Device definitions share support ID \(groupedDevices[0].supportId)."
            return ([heading] + members.filter { $0.matchType == .mismatched }.map { $0.deltaReport }).joined(separator: "\n\n")
        }
        let left = matchedBridge.allProperties
        let right = allProperties
        let combined = mergedBridge.allProperties
        var lines = [String]()
        let label = matched.officialName.isEmpty ? String(describing: id) : matched.officialName
        let identifiers = comparisonIdentifiers.isEmpty ? matched.identifiers : comparisonIdentifiers
        lines.append("\(label) [\(identifiers.joined(separator: ", "))]")

        for key in allKeyPaths.keys where key != "source" {
            if Self.diffIgnoreKeys.contains(key) {
                continue // Source-specific metadata is intentionally excluded from actionable reports.
            }
            guard let leftValue = left[key], let rightValue = right[key] else {
                continue
            }
            let leftValueDefinable = definitionText(leftValue)
            let rightValueDefinable = definitionText(rightValue)
            let combinedValue = combined[key]
            let combinedDefinition = definitionText(combinedValue)
            guard leftValueDefinable != rightValueDefinable || leftValueDefinable != combinedDefinition else {
                continue // Identical fields add noise and make upstream reports harder to review.
            }
            lines.append("\(key) should be \(leftValueDefinable) not \(rightValueDefinable)")
        }
        return lines.joined(separator: "\n")
    }

    /// Formats actionable mismatches as an issue or pull-request comment for the source project.
    /// Known grouped matches remain explanatory and are never proposed as corrections.
    var generateComment: String {
        deltaReport
    }

    /// Unwraps Optional values before generating definitions so equal values do
    /// not produce noisy `Optional(...)` text or false deltas.
    private func definitionText(_ value: Any?) -> String {
        guard let value else { return "nil" }
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            return mirror.children.first.map { definitionText($0.value) } ?? "nil"
        }
        if let definable = value as? Definable { return definable.definition }
        return String(describing: value)
    }
}

/// Partitions values already known to belong to siblings, while retaining unfamiliar source values as discrepancies.
func sourceGroupValues<Value: Hashable>(_ source: [Value], member: [Value], group: [[Value]]) -> [Value] {
    let known = Set(group.flatMap { $0 })
    let local = Set(member)
    return source.filter { local.contains($0) || !known.contains($0) }
}

extension CPU {
    /// Finds explicit CPU names without mistaking the M5 prefix of M5 Pro for a second processor.
    static func sourceChoices(in text: String) -> [CPU] {
        var remainder = text.lowercased()
        var choices = [CPU]()
        let candidates = allCases.filter { $0 != .unknown }.sorted { $0.rawValue.count > $1.rawValue.count }
        for cpu in candidates {
            let name = cpu.rawValue.replacingOccurrences(of: "Apple ", with: "").lowercased()
            let pattern = #"(?<![a-z0-9])"# + NSRegularExpression.escapedPattern(for: name) + #"(?![a-z0-9])"#
            if remainder.range(of: pattern, options: .regularExpression) != nil {
                choices.append(cpu)
                remainder = remainder.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
            }
        }
        return choices
    }
}

/// Narrows an explicit CPU alternative list only when all alternatives belong to the validated group.
/// Other name differences remain available to the source's normal comparison rules.
func sourceGroupName(_ name: String, member: Device, group: [Device]) -> String {
    let choices = CPU.sourceChoices(in: name)
    guard choices.count > 1, choices.contains(member.cpu), Set(choices).isSubset(of: Set(group.map { $0.cpu })) else { return name }
    let alternatives = choices.map {
        NSRegularExpression.escapedPattern(for: $0.rawValue.replacingOccurrences(of: "Apple ", with: ""))
    }.joined(separator: "|")
    let token = "(?:\(alternatives))"
    let pattern = "(?i)\(token)(?:\\s*(?:or|and|/|&|\\+)\\s*\(token))+"
    return name.replacingOccurrences(of: pattern, with: member.cpu.rawValue.replacingOccurrences(of: "Apple ", with: ""), options: .regularExpression)
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension Array where Element: DeviceBridge {
    /// Sorted using the order they appear in Device.all list (order as appears in code).
    var sorted: [Element] {
        let orderedIdentifiers = Device.all.map { $0.identifiers }
        return self.sorted {
            orderedIdentifiers.firstIndex(of: $0.merged.identifiers) ?? 0
            < orderedIdentifiers.firstIndex(of: $1.merged.identifiers) ?? 0 }
    }
}

extension String {
    static let unknownIdentifier = "Unknown0,0" // just in case we don't have an identifier, this is a way to set a dummy identifier.
    
    var deviceNormalized: String {
        return self
            .tagsStripped
            .safeDescription // for Xʀ
            .lowercased()
            .replacingOccurrences(of: "generation", with: "gen")
            .replacingOccurrences(of: "2nd", with: "2")
            .replacingOccurrences(of: ["(", ")"], with: "")
    }
}

extension Device {
    /// Resolves a source's explicit identifier union conservatively using shared support metadata.
    /// Unknown support IDs, unknown identifiers, and ambiguous individual identifiers never validate a group.
    static func sourceGroup(identifiers: [String]) -> [Device] {
        guard Set(identifiers).count > 1 else { return [] }
        var members = [Device]()
        for identifier in identifiers {
            let matches = Device.all.filter { $0.identifiers.contains(identifier) }
            guard matches.count == 1, let match = matches.first else { return [] }
            if !members.contains(match) { members.append(match) }
        }
        guard members.count > 1, let first = members.first,
              !first.supportId.isEmpty, first.supportId != .unknownSupportId,
              members.allSatisfy({ $0.supportId == first.supportId && $0.idiom == first.idiom }) else { return [] }
        return members
    }

    public static func forcedLookup(identifier: String? = nil, model: String? = nil, supportId: String? = nil, officialNameHint: String? = nil) -> Device {
        if let device = Device.lookup(identifier: identifier, model: model, supportId: supportId, officialNameHint: officialNameHint).first {
            return device
        }
        let device = Device(identifier: identifier ?? .unknownIdentifier)
        guard device.idiom == .unspecified else {
            return device
        }
        let models: [String] =
        if let model {
            [model]
        } else {
            []
        }
        let identifiers: [String] = if let identifier {
            [identifier]
        } else {
            [.unknownIdentifier]
        }
        // unknown device
        return self.init(
            idiom: .unspecified,
            officialName: officialNameHint ?? "Unknown Device",
            identifiers: identifiers,
            introduction: nil,
            supportId: .unknownSupportId,
            launchOSVersion: .zero,
            unsupportedOSVersion: nil,
            image: nil,
            capabilities: [],
            models: models,
            colors: [],
            cpu: .unknown)
    }

    /// For checking that this device has good values (and if not, use base values)
    func merged(from base: Device) -> Device {
        var idiom = base.idiom
        if self.idiom != .unspecified {
            idiom = self.idiom
        }
        var officialName = base.officialName
        if !self.officialName.contains("Unknown") {
            // possible change in official name.  Ignore if it's similar
            // ignore Gen vs generation
            if officialName.deviceNormalized != self.officialName.deviceNormalized && !officialName.deviceNormalized.contains(self.officialName.deviceNormalized) {
                officialName = self.officialName
            }
        }
        var identifiers = base.identifiers
        if self.identifiers.count > 0 && !Set(self.identifiers).isSubset(of: Set(identifiers)) {
            identifiers.append(contentsOf: self.identifiers)
            identifiers.removeDuplicates()
            identifiers.sort()
        }
        var introduction = base.introduction
        if let selfIntroduction = self.introduction, selfIntroduction != introduction {
            if let baseIntroduction = introduction {
                // we have some difference in dates.  However if we just have a year and the base already has that, ignore.
                if selfIntroduction.mysqlDate == "\(baseIntroduction.date?.year ?? 0)".introductionYear {
                    // leave the base
                } else {
                    // we have conflicting information
                    introduction = selfIntroduction
                }
            } else {
                // if the base is empty but we are not, just assign
                introduction = selfIntroduction
            }
        }
        var supportId = base.supportId
        if self.supportId != .unknownSupportId {
            supportId = self.supportId
        }
        var launchOSVersion = base.launchOSVersion
        if self.launchOSVersion != .zero {
            launchOSVersion = self.launchOSVersion
        }
        var unsupportedOSVersion = base.unsupportedOSVersion
        if let selfUnsupportedOSVersion = self.unsupportedOSVersion, selfUnsupportedOSVersion != .zero {
            unsupportedOSVersion = selfUnsupportedOSVersion
        }
        var image = base.image
        if let selfImage = self.image {
            image = selfImage
        }
        var capabilities = base.capabilities
        if self.capabilities.count > 0 && !self.capabilities.isSubset(of: capabilities) {
            // add the new capabilities in
            capabilities.formUnion(self.capabilities)
        }
        // A merged definition represents both sides of the comparison. Keep
        // every model number from Device and the bridge while preserving the
        // local order and appending newly discovered source models once.
        var models = base.models
        for model in self.models where !models.contains(model) {
            models.append(model)
        }
        var colors = base.colors
        if self.colors.count > 0 && self.colors != .default && !Set(self.colors).isSubset(of: Set(colors)) {
            colors.append(contentsOf: self.colors)
            colors.removeDuplicates()
            // order matters
        }
        var cpu = base.cpu
        if self.cpu != .unknown {
            cpu = self.cpu
        }
        return Device(
            idiom: idiom,
            officialName: officialName,
            identifiers: identifiers,
            introduction: introduction,
            supportId: supportId,
            launchOSVersion: launchOSVersion,
            unsupportedOSVersion: unsupportedOSVersion,
            image: image,
            capabilities: capabilities,
            models: models,
            colors: colors,
            cpu: cpu)
    }
}
