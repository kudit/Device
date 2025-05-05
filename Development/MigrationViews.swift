//
//  MigrationViews.swift
//  Device
//
//  Created by Ben Ku on 4/27/25.
//

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct DeviceComparisons<Bridge: DeviceBridge>: View {
    @State var bridges: [Bridge]
    var body: some View {
        List {
            ForEach(bridges) { bridge in
                VStack {
                    DeviceInfoView(device: bridge.merged)
                        .background(bridge.device.definition == bridge.matched.definition ? .green : (bridge.merged.definition == bridge.matched.definition ? .yellow : .red))
                    if !bridge.exactMatch {
                        DiffView(
                            left: bridge.matched.definition,
                            merged: bridge.merged.definition,
                            right: bridge.device.definition,
                            source: bridge.source.superCollapseWhitespace)
                    }
                    Divider()
                }
            }
        }
        .toolbar {
            Button("Copy Devices") {
                Compatibility.copyToPasteboard(bridges.sorted.map { $0.merged.definition }.joined(separator: "\n"))
            }
            Button("Copy Others") {
                Compatibility.copyToPasteboard(Bridge.generate())
            }
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Device Comparisons") {
    DeviceComparisons(bridges: AppleDevice.fromJSON)
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct ProcessingView: View {
    @State var url: String
    @ObservedObject var pageParser: PageParser
    
    init(url: String) {
        self.url = url
        self.pageParser = PageParser(url: url)
    }
        
    var body: some View {
        Group {
            if pageParser.parsing {
                ProgressView("Parsing…")
            } else {
                DeviceComparisons(bridges: pageParser.items)
            }
        }
        .onAppear {
            Compatibility.background {
                await self.pageParser.parse()
            }
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Processing View") {
    ProcessingView(url: PageParser.identifyPages.first?.value ?? "BAD")
}

#if DEBUG
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct MigrationMenu: View {
    var body: some View {
        List {
            NavigationLink("AppleDevice Comparison") {
                DeviceComparisons(bridges: AppleDevice.fromJSON)
            }
            ForEach(PageParser.identifyPages.sorted(by: >), id: \.key) { (label, page) in
                NavigationLink(label) {
                    ProcessingView(url: page)
                }
            }
            NavigationLink("MobileDevice Hardware") {
                DeviceComparisons(bridges: MobileDevice.devices())
            }
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Migration Menu") {
    MigrationMenu()
}

#endif
#endif
