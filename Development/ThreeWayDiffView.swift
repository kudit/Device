//
//  ThreeWayDiffView.swift
//  Device
//
//  Created by Ben Ku on 9/18/25.
//
#if canImport(SwiftUI) && canImport(Foundation)

import SwiftUI
import Color

/// A display-only color projection used by bridge comparisons. It intentionally
/// keeps presentation sorting and swatches out of the Device model itself.
struct ColorComparison: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let hex: String // includes #
}

protocol ColorComparable {
	var comparisonColor: ColorComparison { get }
}

extension MaterialColor: ColorComparable {
	var comparisonColor: ColorComparison {
		ColorComparison(id: caseName, name: name, hex: rawValue)
	}
}

private struct ColorComparisonList: View {
    let colors: [ColorComparison]
    var body: some View {
        HStack(spacing: 4) {
            ForEach(colors) { color in
                HStack(spacing: 2) {
					Circle().fill(Color(string: color.hex, defaultColor: .gray), strokeBorder: .foreground, lineWidth: 0.5).frame(width: 10, height: 10)
                    Text(color.name)
						.backport.textSelection(.enabled)
						.font(.subheadline)
				}
				.help(color.hex)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - Diff view
@available(iOS 15, *)
struct ThreeWayDiffView<T: PropertyIterable>: View {
    enum Mode: String, CaseIterable {
        case left = "Left"
        case merged = "Merged"
        case right = "Right"
        case combined = "Combined"
    }

    let left: T
    let merged: T
    let right: T
    var fixedMode: Mode?
    private let equality: (String, Any?, Any?) -> Bool
    private let compatibility: (String, Any?, Any?, Any?) -> Bool

    @State private var mode: Mode = .combined

    init(left: T, merged: T, right: T, fixedMode: Mode? = nil, equality: @escaping (String, Any?, Any?) -> Bool = { _, l, r in areEqual(l, r) }, compatibility: @escaping (String, Any?, Any?, Any?) -> Bool = { _, _, _, _ in false }) {
        self.left = left
        self.merged = merged
        self.right = right
        self.fixedMode = fixedMode
        self.equality = equality
        self.compatibility = compatibility
    }

    // Custom colors
    private let leftColor = Color.blue
    private let rightColor = Color.magenta
    private let mergedDiffColor = Color.green

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if fixedMode == nil { header }
            ForEach(allKeys, id: \.self) { key in
                if key != "source" {
                    row(for: key)
                }
            }
        }
    }

    // MARK: header
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fields")
                .font(.headline)
                .foregroundStyle(.primary)
            if fixedMode == nil {
                Picker("", selection: $mode) {
                    ForEach(Mode.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmentedBackport)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: keys union (preserve first-seen order)
    private var allKeys: [String] {
        let l = Array(left.allProperties.keys)
        let m = Array(merged.allProperties.keys)
        let r = Array(right.allProperties.keys)
        var seen = Set<String>()
        var out: [String] = []
        for arr in [l, m, r] {
            for k in arr where !seen.contains(k) {
                seen.insert(k)
                out.append(k)
            }
        }
        return out
    }

    // MARK: a single row for a field
    @ViewBuilder
    private func row(for key: String) -> some View {
        let lVal = left.allProperties[key]
        let mVal = merged.allProperties[key]
        let rVal = right.allProperties[key]

        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(key)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(typeDescription(of: lVal, mVal, rVal))
                    .font(.caption)
                    // Show comparison status on the type label so value
                    // colors continue to identify Device and bridge sides.
                    .foregroundStyle(typeColor(for: key, left: lVal, merged: mVal, right: rVal))
            }
            Spacer()
            switch fixedMode ?? mode {
            case .left:
                valueText(stringify(lVal), color: colorForLeft(key: key, left: lVal, merged: mVal, right: rVal) ?? .primary)
            case .right:
                valueText(stringify(rVal), color: colorForRight(key: key, left: lVal, merged: mVal, right: rVal) ?? .primary)
            case .merged:
                valueText(stringify(mVal), color: colorForMerged(key: key, merged: mVal, left: lVal, right: rVal) ?? .primary)
            case .combined:
                // compute model once, then render declaratively
                let combined = computeCombinedResult(key: key, lVal: lVal, mVal: mVal, rVal: rVal)
                combinedView(combined, key: key)
            }
        }
        .padding(.vertical, 8)
    }

    // small value styling
    private func valueText(_ text: String, color: Color = .primary) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(color)
            .multilineTextAlignment(.trailing)
            // Selection is applied directly to the label so rows keep their natural
            // SwiftUI layout instead of wrapping each value in a separate selectable
            // view surface.
            .backport.textSelection(.enabled)
    }

    // MARK: — Combined result model (pure data)
    private struct CombinedEntry: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let color: Color?
        let raw: Any?
    }

    private struct CombinedResult {
        let entries: [CombinedEntry]
        let allEqual: Bool
    }

    // MARK: — compute-only (no SwiftUI) logic for combined view
    private func computeCombinedResult(key: String, lVal: Any?, mVal: Any?, rVal: Any?) -> CombinedResult {
        var entries: [CombinedEntry] = []

        // colors according to rules
        let leftClr = colorForLeft(key: key, left: lVal, merged: mVal, right: rVal)
        let mergedClr = colorForMerged(key: key, merged: mVal, left: lVal, right: rVal)
        let rightClr = colorForRight(key: key, left: lVal, merged: mVal, right: rVal)

        func appendUnique(source: String, val: Any?, color: Color?) {
            // skip nil values entirely in combined view
            guard let val = val else { return }
            // dedupe by logical equality where possible (prefer areEqual), otherwise by string
            if entries.contains(where: { equality("", $0.raw, val) }) { return }
            let s = stringify(val)
            entries.append(CombinedEntry(label: source, value: s, color: color, raw: val))
        }

        appendUnique(source: "L", val: lVal, color: leftClr)
        appendUnique(source: "M", val: mVal, color: mergedClr)
        appendUnique(source: "R", val: rVal, color: rightClr)

        let allEqual = equality("", lVal, mVal) && equality("", mVal, rVal)
        // If logically all equal but dedup produced more (unlikely), reduce to a single canonical entry
        if allEqual, let first = entries.first {
            return CombinedResult(entries: [first], allEqual: true)
        }
        return CombinedResult(entries: entries, allEqual: allEqual)
    }

    // MARK: — view-only rendering for combined result (declarative)
    @ViewBuilder
    private func combinedView(_ combined: CombinedResult, key: String) -> some View {
        if combined.entries.isEmpty {
            // nothing present
            Text("—")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else if combined.allEqual, combined.entries.count == 1 {
				if let colors = colorComparisons(combined.entries[0].raw) {
				ColorComparisonList(colors: colors)
			} else {
				Text(combined.entries[0].value)
					.font(.subheadline)
					.multilineTextAlignment(.trailing)
					// Match the other value labels: selectable, but still a plain Text.
					.backport.textSelection(.enabled)
            }
        } else {
            VStack(alignment: .trailing, spacing: 6) {
                ForEach(combined.entries) { e in
                    HStack(spacing: 8) {
							if let colors = colorComparisons(e.raw) {
							ColorComparisonList(colors: colors)
                        } else { Text(e.value)
                            .font(.subheadline)
                            .foregroundColor(e.color ?? .primary)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            // Keep variant values as Text labels while allowing copy
                            // from the combined diff row.
                            .backport.textSelection(.enabled)
                        }
                        Spacer(minLength: 4)
                        Text(e.label)
                            .font(.caption2)
                            .bold()
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(RoundedRectangle(cornerRadius: 4).strokeBorder(.secondary, lineWidth: 0.5))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

	private func colorComparisons(_ value: Any?) -> [ColorComparison]? {
		guard let value else { return nil }
		if let colors = value as? [ColorComparable] {
			return colors.map{ $0.comparisonColor }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        return nil
    }

    // MARK: coloring rules
    private func colorForLeft(key: String, left: Any?, merged: Any?, right: Any?) -> Color? {
        if !equality("", left, merged) || !equality("", left, right) {
            return leftColor
        }
        return nil
    }

    private func colorForRight(key: String, left: Any?, merged: Any?, right: Any?) -> Color? {
        if !equality("", right, merged) || !equality("", left, right) {
            return rightColor
        }
        return nil
    }

    private func colorForMerged(key: String, merged: Any?, left: Any?, right: Any?) -> Color? {
        if equality("", merged, left) && !equality("", merged, right) { return leftColor }
        if equality("", merged, right) && !equality("", merged, left) { return rightColor }
        if equality("", merged, left) && equality("", merged, right) { return nil }
        return mergedDiffColor
    }

    private func typeColor(for key: String, left: Any?, merged: Any?, right: Any?) -> Color {
        if equality(key, left, right) {
            return areEqual(left, right) ? .secondary : .green
        }
        if compatibility(key, left, merged, right) { return .yellow }
        if !equality(key, left, merged) { return .red }
        return .yellow
    }

    // MARK: helpers
    private func stringify(_ value: Any?) -> String {
        guard let value else { return "—" }
        // PropertyIterable exposes optional bridge fields as Optional values;
        // unwrap them before formatting so AppleDB fields use their JSON-like
        // literal instead of `Optional(MixedTypeField.string(...))`.
//    let v: Any
//    let mirror = Mirror(reflecting: value)
//    if mirror.displayStyle == .optional {
//      guard let child = mirror.children.first else { return "—" }
//      v = child.value
//    } else {
//      v = value
//    }
        if let definable = value as? Definable { return definable.definition }
        if let fields = value as? [MixedTypeField] {
            return fields.definition
        }
        if let colors = value as? [AppleDBColor] {
            // Sort only the bridge presentation; Device definitions retain
            // their declared color-set order for source fidelity.
            return "[\(colors.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }.map { $0.definition }.joined(separator: ", "))]"
        }
        // PropertyIterable may hand us an Optional<MixedTypeField> as `Any`;
        // unwrap that container before falling back to its verbose description.
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional,
           let child = mirror.children.first {
            return stringify(child.value)
        }
//    if let s = v as? String { return "\"\(s)\"" }
//    if let arr = v as? [String] { return "[\(arr.map { "\"\($0)\"" }.joined(separator: ", "))]" }
//    if let arr = v as? [Any] {
//      let mapped = arr.map { item -> String in
//        if let s = item as? String { return "\"\(s)\"" }
//        if let n = item as? CustomStringConvertible { return n.description }
//        return String(describing: item)
//      }
//      return "[\(mapped.joined(separator: ", "))]"
//    }
        if let d = value as? CustomStringConvertible { return d.description }
        return String(describing: value)
    }

    private func typeDescription(of l: Any?, _ m: Any?, _ r: Any?) -> String {
        let firstNonNil = l ?? m ?? r
        guard let v = firstNonNil else { return "Optional" }
        let mirror = Mirror(reflecting: v)
        let typeName = String(describing: mirror.subjectType)
        return typeName
    }
}


// MARK: - Example usage with a sample type
struct TestDevice: PropertyIterable {
    var name: String
    var identifiers: [String]
    var version: Int?
    var flags: [String: Bool]
    var versionB: Version?
    var versionC: Version?
    var versionD: Version?
    var versionE: Version?
    var versionF: Version?
    var versionG: Version?
    var versionH: Version?
    var versionI: Version?
    var versionJ: Version?
}

@available(iOS 15, *)
struct ThreeWayDiffView_Previews: PreviewProvider {
    static var left = TestDevice(name: "iPod Classic", identifiers: ["iPod1,1"], version: 1, flags: ["wifi": false])
    static var right = TestDevice(name: "iPod Classic", identifiers: ["iPod1,2"], version: 2, flags: ["wifi": true])
    static var merged = TestDevice(name: "iPod Classic", identifiers: ["iPod1,1", "iPod1,2"], version: 1, flags: ["wifi": true])

    static var previews: some View {
            List {
                ThreeWayDiffView(left: left, merged: merged, right: right)
                    .navigationTitle("Three-way Diff")
            }.navigationWrapper()
//      .listStyle(.insetGrouped)
    }
}

@available(iOS 15, *)
struct DiffSwitcherView<T: DeviceBridge>: View {
    @State private var context: DiffContext = .bridge
    @State private var bridgeMode: BridgeMode = .combined
    @State private var deviceMode: DeviceMode = .merged

    var bridge: T
    /// Loader-time projections; avoiding their recomputation is important
    /// because DisclosureGroup can reevaluate its content repeatedly.
    var matchedBridge: T?
    var mergedBridge: T?
    private enum DiffContext: String, CaseIterable { case bridge = "Bridge", device = "Device" }
    private enum BridgeMode: String, CaseIterable { case combined = "Combined", left = "Left", merged = "Merged", right = "Right", source = "Source" }
    private enum DeviceMode: String, CaseIterable { case left = "Left", merged = "Merged", right = "Right" }

    init(bridge: T, matchedBridge: T? = nil, mergedBridge: T? = nil) {
        self.bridge = bridge
        self.matchedBridge = matchedBridge
        self.mergedBridge = mergedBridge
    }

    var body: some View {
        let leftBridge = matchedBridge ?? bridge.matchedBridge
        let mergedProjection = mergedBridge ?? bridge.mergedBridge
        VStack {
            HStack {
                Picker("Context", selection: $context) {
                    ForEach(DiffContext.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmentedBackport)
                if context == .bridge {
                    Picker("Bridge view", selection: $bridgeMode) { ForEach(BridgeMode.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                        .pickerStyle(.segmentedBackport)
                } else {
                    Picker("Device view", selection: $deviceMode) { ForEach(DeviceMode.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                        .pickerStyle(.segmentedBackport)
                    Link("Support", destination: bridge.matched.supportURL)
                        .font(.caption)
                }
            }
            // A source row has exactly one context controller. Grouped local
            // members are handled by DeviceBridge merge/export logic and are not
            // rendered as duplicate context sections here.
            let member = bridge
            Group {
                if context == .bridge && bridgeMode == .combined {
                    ThreeWayDiffView(left: leftBridge, merged: mergedProjection, right: member, fixedMode: .combined, equality: { key, left, right in
                        member.bridgeValuesEqual(key, left, right)
                    }, compatibility: { key, left, merged, right in
                        member.compatibleWhenMergedDiffers(key, left: left, merged: merged, right: right)
                    })
                } else if context == .bridge {
                    let left = leftBridge.definition
                    let merged = mergedProjection.definition
                    let right = bridgeMode == .source ? member.source.superCollapseWhitespace : member.definition
                    DiffView(
                        left: left,
                        merged: merged,
                        right: right,
                        source: member.source.superCollapseWhitespace,
                        fixedMode: bridgeMode == .left ? .left : bridgeMode == .merged ? .merged : bridgeMode == .right ? .right : .source)
                } else {
                    let left = member.matched.definition
                    let merged = member.merged.definition
                    // Device context uses the synthesized Device definition as the
                    // projected source value; the merged value remains the proposal.
                    let right = member.merged.definition
                    DiffView(
                        left: left,
                        merged: merged,
                        right: right,
                        source: right,
                        fixedMode: deviceMode == .left ? .left : deviceMode == .merged ? .merged : .right)
                }
            }
        }
    }

}

@available(iOS 15, *)
#Preview {
    List {
        DiffSwitcherView(bridge: try! MacLookup(fromJSON: """
  {
    "colors" : [
      "Silver",
      "Pink",
      "Blue",
      "Green",
      "Purple",
      "Orange",
      "Yellow"
    ],
    "notes" : [
      "Front and back of iMac (24-inch, 2024, Four Ports)",
      "Ports: Four Thunderbolt \\/ USB 4 ports"
    ],
    "name" : "iMac (24-inch, 2024, Four ports)",
    "kind" : "iMac",
    "parts" : [
      "MCR24xx\\/A",
      "MD2P4xx\\/A",
      "MD2Q4xx\\/A",
      "MD2T4xx\\/A",
      "MD2U4xx\\/A",
      "MD2V4xx\\/A",
      "MD2W4xx\\/A",
      "MD2X4xx\\/A",
      "MD2Y4xx\\/A",
      "MD3A4xx\\/A",
      "MD3D4xx\\/A",
      "MD3E4xx\\/A",
      "MD3F4xx\\/A",
      "MD3G4xx\\/A",
      "MD3H4xx\\/A",
      "MWUU3xx\\/A",
      "MWUV3xx\\/A",
      "MWUW3xx\\/A",
      "MWUX3xx\\/A",
      "MWUY3xx\\/A",
      "MWV03xx\\/A",
      "MWV13xx\\/A",
      "MWV33xx\\/A",
      "MWV43xx\\/A",
      "MWV53xx\\/A",
      "MWV63xx\\/A",
      "MWV73xx\\/A",
      "MWV83xx\\/A",
      "MWV93xx\\/A",
      "MWVA3xx\\/A",
      "MWVC3xx\\/A",
      "MWVD3xx\\/A",
      "MWVE3xx\\/A",
      "MWVF3xx\\/A",
      "MWVG3xx\\/A",
      "MWVH3xx\\/A",
      "MWVJ3xx\\/A",
      "MWVK3xx\\/A",
      "MWVL3xx\\/A",
      "MWVN3xx\\/A",
      "MWVP3xx\\/A",
      "MWVQ3xx\\/A",
      "MWVR3xx\\/A"
    ],
    "models" : [
      "Mac16,3"
    ],
    "variant" : "24-inch, 2024, Four ports",
    "newestOS" : "macOS Sequoia"
  }
"""))
    }
}
#endif
