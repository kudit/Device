//
//  ThreeWayDiffView.swift
//  Device
//
//  Created by Ben Ku on 9/18/25.
//

import SwiftUI

// MARK: - Diff view
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

    @State private var mode: Mode = .combined

    // Custom colors
    private let leftColor = Color.blue
    private let rightColor = Color.magenta
    private let mergedDiffColor = Color.green

    var body: some View {
        Section(header: header) {
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
            Picker("", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
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
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            switch mode {
            case .left:
                valueText(stringify(lVal))
                    .foregroundColor(colorForLeft(left: lVal, merged: mVal, right: rVal) ?? .primary)
            case .right:
                valueText(stringify(rVal))
                    .foregroundColor(colorForRight(left: lVal, merged: mVal, right: rVal) ?? .primary)
            case .merged:
                valueText(stringify(mVal))
                    .foregroundColor(colorForMerged(merged: mVal, left: lVal, right: rVal) ?? .primary)
            case .combined:
                // compute model once, then render declaratively
                let combined = computeCombinedResult(lVal: lVal, mVal: mVal, rVal: rVal)
                combinedView(combined)
            }
        }
        .padding(.vertical, 8)
    }

    // small value styling
    private func valueText(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .multilineTextAlignment(.trailing)
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
    private func computeCombinedResult(lVal: Any?, mVal: Any?, rVal: Any?) -> CombinedResult {
        var entries: [CombinedEntry] = []

        // colors according to rules
        let leftClr = colorForLeft(left: lVal, merged: mVal, right: rVal)
        let mergedClr = colorForMerged(merged: mVal, left: lVal, right: rVal)
        let rightClr = colorForRight(left: lVal, merged: mVal, right: rVal)

        func appendUnique(source: String, val: Any?, color: Color?) {
            // skip nil values entirely in combined view
            guard let val = val else { return }
            // dedupe by logical equality where possible (prefer areEqual), otherwise by string
            if entries.contains(where: { areEqual($0.raw, val) }) { return }
            let s = stringify(val)
            entries.append(CombinedEntry(label: source, value: s, color: color, raw: val))
        }

        appendUnique(source: "L", val: lVal, color: leftClr)
        appendUnique(source: "M", val: mVal, color: mergedClr)
        appendUnique(source: "R", val: rVal, color: rightClr)

        let allEqual = areEqual(lVal, mVal) && areEqual(mVal, rVal)
        // If logically all equal but dedup produced more (unlikely), reduce to a single canonical entry
        if allEqual, let first = entries.first {
            return CombinedResult(entries: [first], allEqual: true)
        }
        return CombinedResult(entries: entries, allEqual: allEqual)
    }

    // MARK: — view-only rendering for combined result (declarative)
    @ViewBuilder
    private func combinedView(_ combined: CombinedResult) -> some View {
        if combined.entries.isEmpty {
            // nothing present
            Text("—")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } else if combined.allEqual, combined.entries.count == 1 {
            Text(combined.entries[0].value)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .backport.textSelection(.enabled)
        } else {
            VStack(alignment: .trailing, spacing: 6) {
                ForEach(combined.entries) { e in
                    HStack(spacing: 8) {
                        Text(e.label)
                            .font(.caption2)
                            .bold()
                            .padding(.vertical, 2)
                            .padding(.horizontal, 6)
                            .background(RoundedRectangle(cornerRadius: 4).strokeBorder(.secondary, lineWidth: 0.5))
                            .foregroundColor(.secondary)
                        Spacer(minLength: 4)
                        Text(e.value)
                            .font(.subheadline)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(e.color ?? .primary)
                            .backport.textSelection(.enabled)
                    }
                }
            }
            .frame(maxWidth: 300)
        }
    }

    // MARK: coloring rules
    private func colorForLeft(left: Any?, merged: Any?, right: Any?) -> Color? {
        if !areEqual(left, merged) || !areEqual(left, right) {
            return leftColor
        }
        return nil
    }

    private func colorForRight(left: Any?, merged: Any?, right: Any?) -> Color? {
        if !areEqual(right, merged) || !areEqual(left, right) {
            return rightColor
        }
        return nil
    }

    private func colorForMerged(merged: Any?, left: Any?, right: Any?) -> Color? {
        if areEqual(merged, left) && !areEqual(merged, right) { return leftColor }
        if areEqual(merged, right) && !areEqual(merged, left) { return rightColor }
        if areEqual(merged, left) && areEqual(merged, right) { return nil }
        return mergedDiffColor
    }

    // MARK: helpers
    private func stringify(_ value: Any?) -> String {
        guard let v = value else { return "—" }
        if let s = v as? String { return "\"\(s)\"" }
        if let arr = v as? [String] { return "[\(arr.map { "\"\($0)\"" }.joined(separator: ", "))]" }
        if let arr = v as? [Any] {
            let mapped = arr.map { item -> String in
                if let s = item as? String { return "\"\(s)\"" }
                if let n = item as? CustomStringConvertible { return n.description }
                return String(describing: item)
            }
            return "[\(mapped.joined(separator: ", "))]"
        }
        if let d = v as? CustomStringConvertible { return d.description }
        return String(describing: v)
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

struct ThreeWayDiffView_Previews: PreviewProvider {
    static var left = TestDevice(name: "iPod Classic", identifiers: ["iPod1,1"], version: 1, flags: ["wifi": false])
    static var right = TestDevice(name: "iPod Classic", identifiers: ["iPod1,2"], version: 2, flags: ["wifi": true])
    static var merged = TestDevice(name: "iPod Classic", identifiers: ["iPod1,1", "iPod1,2"], version: 1, flags: ["wifi": true])

    static var previews: some View {
            List {
                ThreeWayDiffView(left: left, merged: merged, right: right)
                    .navigationTitle("Three-way Diff")
            }.navigationWrapper()
//            .listStyle(.insetGrouped)
    }
}

struct DiffSwitcherView<T: DeviceBridge>: View {
    @State private var bridgeDiff = true

    var bridge: T

    var body: some View {
        VStack {
            HStack {
                Button(bridgeDiff ? "Bridge" : "Device") {
                    bridgeDiff.toggle()
                }
                Button("Copy Device") {
                    Compatibility.copyToPasteboard(bridge.merged.definition)
                }
            }
            if bridgeDiff {
                ThreeWayDiffView(
                    left: bridge.matchedBridge,
                    merged: bridge.mergedBridge,
                    right: bridge)
            } else {
                DiffView(
                    left: bridge.matched.definition,
                    merged: bridge.merged.definition,
                    right: bridge.merged.definition,
                    source: bridge.source.superCollapseWhitespace)
            }
        }
    }
}

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
