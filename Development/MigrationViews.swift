//
//  MigrationViews.swift
//  Device
//
//  Created by Ben Ku on 4/27/25.
//

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct DeviceComparisons<Bridge: DeviceBridge, Loader: DeviceBridgeLoader>: View where Loader.Bridge == Bridge {
    var loader: Loader
    @State var bridges: [Bridge] = []
    @State var generating: Bool = false
    @State var message = "Loading devices…"
    
    func generateCopy(generation: @escaping @Sendable () async -> String) {
        generating = true
        Compatibility.background {
            let text = await generation()
            main {
                Compatibility.copyToPasteboard(text)
                generating = false
            }
        }
    }
    
    var body: some View {
         if bridges.count == 0 {
             ProgressView(message)
                 .onAppear {
                     Compatibility.background {
                         do {
                             let bridges = try await loader.devices()
                             main {
                                 self.bridges = bridges
                             }
                         } catch {
                             let message = error.localizedDescription
                             main {
                                 self.message = message
                             }
                         }
                     }
                     //            // generate bridges in the background
                     //            Compatibility.background {
                     //                bridges = loader.devices()
                     //            }
                 }
         } else {
             List {
                 ForEach(bridges) { bridge in
                     VStack {
                         DeviceInfoView(device: bridge.merged)
                             .background(bridge.matchType.color)
//                             .background(bridge.device.definition == bridge.matched.definition ? .green : (bridge.merged.definition == bridge.matched.definition ? .yellow : .red))
                         if bridge.matchType != .identical {
                             DiffSwitcherView(bridge: bridge)
                         }
                         Divider()
                     }
                 }
             }
             .toolbar {
                 if generating {
                     ProgressView("Generating...")
                 } else {
                     Button("Copy Devices code") {
                         generateCopy {
                             return await bridges.sorted.map { $0.merged.definition }.joined(separator: "\n")
                         }
                     }
                 }
             }
         }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Device Comparisons") {
    DeviceComparisons(loader: AppleDeviceLoader())
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Processing View") {
    DeviceComparisons(loader: PageParser(url: PageParser.identifyPages["iPhones"]!))
}

#if DEBUG
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
struct MigrationMenu: View {
    @State var temporaryText: String = "Calculating..."
    var body: some View {
        List {
            NavigationLink("AppleDevice Comparison") {
                DeviceComparisons(loader: AppleDeviceLoader())
            }
            ForEach(PageParser.identifyPages.sorted(by: >), id: \.key) { (label, page) in
                NavigationLink(label) {
                    DeviceComparisons(loader: PageParser(url: page))
                }
            }
            NavigationLink("MobileDevice Hardware") {
                DeviceComparisons(loader: MobileDeviceLoader())
            }
            NavigationLink("MacLookup") {
                DeviceComparisons(loader: MacLookupLoader())
            }
            NavigationLink("DeviceKit Export") {
                DeviceComparisons(loader: DeviceKitLoader())
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
