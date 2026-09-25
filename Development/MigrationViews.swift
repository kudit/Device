//
//  MigrationViews.swift
//  Device
//
//  Created by Ben Ku on 4/27/25.
//

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
private struct BridgeComparisonSnapshot<B: DeviceBridge>: Sendable {
    let bridge: B
    let matchedDevice: Device
    let matchedBridge: B
    let mergedBridge: B
    let matchType: MatchType
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct DeviceComparisons<Bridge: DeviceBridge, Loader: DeviceBridgeLoader>: View where Loader.Bridge == Bridge {
    private enum Filter: String { case green, yellow, red }
    var loader: Loader
    @State var bridges: [Bridge] = []
    @State var generating: Bool = false
    @State var message = "Comparing devices…"
    @State var completedSections: Int?
    @State var totalSections: Int?
    @State private var filter: Filter?
    @State private var expanded: Set<String> = []
    @State private var cachedComparisons: [String: BridgeComparisonSnapshot<Bridge>] = [:]

    private var counts: (green: Int, yellow: Int, red: Int) {
        (bridges.filter { cachedComparisons[String(describing: $0.id)]?.matchType == .identical }.count,
         bridges.filter { cachedComparisons[String(describing: $0.id)]?.matchType == .compatible }.count,
         bridges.filter { cachedComparisons[String(describing: $0.id)]?.matchType == .mismatched }.count)
    }
    private var visibleBridges: [Bridge] {
        // Preserve every source record. Duplicate records are source data that
        // should be reported and investigated, not silently discarded by the UI.
        guard let filter else { return bridges }
        return bridges.filter {
            switch filter { case .green: cachedComparisons[String(describing: $0.id)]?.matchType == .identical; case .yellow: cachedComparisons[String(describing: $0.id)]?.matchType == .compatible; case .red: cachedComparisons[String(describing: $0.id)]?.matchType == .mismatched }
        }
    }
    private var sectionTitle: String {
        return loader.name
    }
    
    func generateCopy(generation: @escaping @Sendable () async -> String) {
        generating = true
        Compatibility.background {
            let text = await generation()
            main {
                Pasteboard.system.copy(text)
                generating = false
            }
        }
    }
    
    var body: some View {
         if bridges.count == 0 {
             Group {
                 if let completedSections, let totalSections, totalSections > 0 {
                     ProgressView(
                        message,
                        value: Double(completedSections),
                        total: Double(totalSections)
                     )
                 } else {
                     ProgressView(message)
                 }
             }
             .onAppear {
                 Compatibility.background {
                     do {
                         let bridges = try await loader.devices { completed, total, progressMessage in
                             main {
                                 // Page parsers know how many sections they have, so show
                                 // determinate progress while each item is parsed.
                                 self.completedSections = completed
                                 self.totalSections = total
                                 self.message = progressMessage
                             }
                         }
                         // Matching can perform fuzzy Device lookup and grouped
                         // projections, so keep it off the main actor. The UI
                         // receives immutable cached classifications once.
                         Compatibility.background {
                             debug("Migration: classifying \(bridges.count) bridge records for \(loader.name)")
                             // Build one immutable comparison snapshot per source
                             // row. The view never needs to rediscover devices or
                             // recreate bridge projections during disclosure.
                             let snapshots = Dictionary(bridges.enumerated().map { index, bridge in
                                 main {
                                     self.completedSections = index + 1
                                     self.totalSections = bridges.count
                                     self.message = "Matching \(index + 1) of \(bridges.count) devices…"
                                 }
                                 let matchedDevice = bridge.matched
                                 let matchedBridge = bridge.bridge(from: matchedDevice)
                                 let mergedBridge = bridge.bridge(from: bridge.merged)
                                 let snapshot = BridgeComparisonSnapshot(
                                     bridge: bridge,
                                     matchedDevice: matchedDevice,
                                     matchedBridge: matchedBridge,
                                     mergedBridge: mergedBridge,
                                     matchType: bridge.matchType)
                                 return (String(describing: bridge.id), snapshot)
                             }, uniquingKeysWith: { first, _ in first })
                             debug("Migration: classified \(snapshots.count) bridge records for \(loader.name)")
                             main {
                                 self.bridges = bridges
                                 self.cachedComparisons = snapshots
                             }
                         }
                     } catch {
                         let message = error.localizedDescription
                         main {
                             self.message = message
                         }
                     }
                 }
                 //   // generate bridges in the background
                 //   Compatibility.background {
                 //       bridges = loader.devices()
                 //   }
             }
         } else {
             List {
                 ForEach(Array(visibleBridges.enumerated()), id: \.offset) { index, bridge in
                     let rowID = "\(index)-\(bridge.id)"
                     // Disclosure redraws reevaluate its label and content. Read
                     // the classification computed during loading instead of
                     // performing Device lookup and bridge projection again.
                     let snapshot = cachedComparisons[String(describing: bridge.id)]
                     let matchType = snapshot?.matchType ?? .mismatched
                     let matchedDevice = snapshot?.matchedDevice ?? bridge.matched
                    // Every row's open state comes only from the user's toggle;
                    // red severity controls color/visibility, never expansion.
                    DisclosureGroup(isExpanded: Binding(get: { expanded.contains(rowID) }, set: { isExpanded in
                         if isExpanded { expanded.insert(rowID) } else { expanded.remove(rowID) }
                     })) {
                         VStack {
                         // A grouped source represents several independent hardware definitions.
                         // Display every member and acknowledge the relationship without inventing one CPU.
                         if !bridge.groupedDevices.isEmpty {
                             Text("Grouped source: \(bridge.groupedDevices.count) device definitions")
                                 .font(.headline)
                         }
//               .background(bridge.device.definition == bridge.matched.definition ? .green : (bridge.merged.definition == bridge.matched.definition ? .yellow : .red))
                         // Green matches still expose their generated comparison;
                         // only the initial disclosure state differs.
                         DiffSwitcherView(bridge: bridge, matchedBridge: snapshot?.matchedBridge, mergedBridge: snapshot?.mergedBridge)
                         Divider()
                         }
                     } label: {
                         // Keep the compact device information block as the row label;
                         // tapping it expands only the detailed comparison code.
                         DeviceInfoView(device: matchedDevice)
                             .background(matchType.color.opacity(0.18))
                             // Keep text readable when the enclosing List row is selected.
                             .foregroundStyle(.primary)
                             .contentShape(Rectangle())
                             .onTapGesture {
                                 let isExpanded = expanded.contains(rowID)
                                 if isExpanded { expanded.remove(rowID) } else { expanded.insert(rowID) }
                             }
                     }
                 }
             }
             // Keep status filters visible while the comparison list scrolls.
             .safeAreaInset(edge: .top, spacing: 0) {
                 HStack {
                     filterButton("Green", count: counts.green, filter: .green)
                     filterButton("Yellow", count: counts.yellow, filter: .yellow)
                     filterButton("Red", count: counts.red, filter: .red)
                 }
                 .padding(.vertical, 6)
                 .frame(maxWidth: .infinity)
                 .background(.bar)
             }
             .toolbar {
                 if generating {
                     ProgressView("Generating...")
                 } else {
                    Button("Generate Comment") {
                         // Generate an issue-ready comment containing only actionable differences.
                         // Take the small cached-state snapshot while on the main actor;
                         // report formatting then runs in the background using only Sendable bridges.
                         let commentCandidates = bridges.filter {
                             cachedComparisons[String(describing: $0.id)]?.matchType != .identical
                         }
                         generateCopy {
                            // Classification is cached; this closure never reaches back
                            // into actor-isolated SwiftUI state or recalculates match types.
                            return commentCandidates.map { $0.generateComment }.joined(separator: "\n\n")
                         }
                     }
                 }
             }
             .toolbar {
                 ToolbarItem(placement: .principal) {
                     HStack(spacing: 12) {
                         Text(sectionTitle).font(.headline)
                         Link("View Source", destination: loader.source)
                     }
                 }
             }
             .navigationTitle(sectionTitle)
         }
    }

    @ViewBuilder private func filterButton(_ title: String, count: Int, filter value: Filter) -> some View {
        Button("\(title) \(count)") { filter = filter == value ? nil : value }
            .buttonStyle(.borderedProminent)
            .tint(value == .green ? .green : value == .yellow ? .yellow : .red)
    }

}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Device Comparisons") {
    DeviceComparisons(loader: AppleDeviceLoader())
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Processing View") {
    DeviceComparisons(loader: PageParser(sourceURL: PageParser.identifyPages["iPhones"]!))
}

#if DEBUG
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct MigrationMenu: View {
    @State var temporaryText: String = "Calculating..."
    @ViewBuilder
    func navItem<L:DeviceBridgeLoader>(loader: L) -> some View {
        NavigationLink(loader.name) {
            DeviceComparisons(loader: loader)
        }
    }
    var body: some View {
        List {
            navItem(loader: AppleDeviceLoader())
            ForEach(PageParser.identifyPages.sorted(by: >), id: \.key) { (label, page) in
                navItem(loader: PageParser(sourceURL: page))
            }
            navItem(loader: MobileDeviceLoader())
            navItem(loader: MacLookupLoader())
            navItem(loader: DeviceKitLoader())
            navItem(loader: AppleDBLoader())
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Migration Menu") {
    MigrationMenu()
}

#endif
#endif
