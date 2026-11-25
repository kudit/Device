//
//  BatteryView.swift
//  BatteryClockWidget
//
//  Created by Ben Ku on 3/9/24.
//

#if canImport(SwiftUI)
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import Compatibility

/// Returns whether this OS can render the symbol from its SF Symbols library.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private func hasNativeSystemSymbol(_ symbol: SFSymbol) -> Bool {
#if os(watchOS)
	// watchOS has no UIKit or AppKit symbol-presence lookup.
	if #available(watchOS 10.0, *) { return true }
	return false
#elseif canImport(UIKit)
	return UIImage(systemName: symbol) != nil
#elseif canImport(AppKit)
	if #available(macOS 11.0, *) {
		return NSImage(systemSymbolName: symbol, accessibilityDescription: nil) != nil
	}
	return false
#else
	return false
#endif
}

/// Uses Apple's rendered symbol when present and keeps the package asset as an older-system fallback.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private func batterySymbolImage(_ symbol: SFSymbol) -> Image {
	// SF Symbols 5 introduced the percent spelling; use the earlier symbol when a platform
	// has the OS version but not that particular symbol (for example, an older symbol library).
	if symbol == "battery.100percent.bolt", !hasNativeSystemSymbol(symbol),
	   hasNativeSystemSymbol("battery.100.bolt") {
		return batterySymbolImage("battery.100.bolt")
	}
	// The package loader chooses the native symbol when available and handles bundled
	// assets and older-platform fallbacks without requiring Image(systemName:) here.
	return Image(symbolName: symbol)
}

// support relative font
// https://malauch.com/posts/auto-resizable-text-size-in-swiftui/
/*
 let font = Font.custom("SF Pro", size: 8, relativeTo: .caption)
 .system(size:) should support relativeTo:
 .font(.system(size: 200))  // 1
 .minimumScaleFactor(0.01)  // 2
 */

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
class PolymorphicBattery: ObservableObject {
    @Published var monitoredDeviceBattery: MonitoredDeviceBattery?
    @Published var deviceBattery: DeviceBattery?
    @Published var mockBattery: MockBattery = .missing // guarantees that this will never be nil and the polymorphic battery will have at least one representation
} 
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct BatteryView: View {
    // ObservedObject can't be used with any.
    @ObservedObject var polymorphicBattery = PolymorphicBattery()
    
    // Making these state variables means they wouldn't be updated or set by the initializer.
    // These are part of the view which can be set in initializer so they don't need to be public.
    var useSystemColors: Bool
    var includePercent: Bool
    var fontSize: Double
    //  /// Include the backing view to improve contrast.
    var includeBacking: Bool
        
    /// Initializer without specifying a battery will assume CurrentDevice.battery, and if that is nil, will use the missing battery mock.
    public init(battery initialBattery: (some Battery)? = MockBattery?.none, useSystemColors: Bool = false, includePercent: Bool = true, fontSize: Double = 16, includeBacking: Bool = true) {
        self.useSystemColors = useSystemColors
        self.includePercent = includePercent
        self.fontSize = fontSize
        self.includeBacking = includeBacking
        let battery: (any Battery)? = initialBattery ?? Device.current.battery
        if let battery = battery as? MonitoredDeviceBattery {
            self.polymorphicBattery.monitoredDeviceBattery = battery
        } else if let battery = battery as? DeviceBattery {
            self.polymorphicBattery.deviceBattery = battery
        } else if let battery = battery as? MockBattery {
            self.polymorphicBattery.mockBattery = battery
        } // poly already initializes to .missing
#if targetEnvironment(macCatalyst)
        Device.current.enableMonitoring(frequency: 1)
#endif
    }
    func batteryView(battery: some Battery & ObservableObject) -> some View {
        SpecificBatteryView(battery: battery, useSystemColors: useSystemColors, includePercent: includePercent, fontSize: fontSize, includeBacking: includeBacking)
    }
    public var body: some View {
        if let battery = polymorphicBattery.monitoredDeviceBattery {
            batteryView(battery: battery)
        } else if let battery = polymorphicBattery.deviceBattery {
            batteryView(battery: battery)
        } else {
            batteryView(battery: polymorphicBattery.mockBattery)
        } 
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct SpecificBatteryView<SomeBattery: Battery & ObservableObject>: View {
    // ObservedObject can't be used with any.
    @ObservedObject public var battery: SomeBattery
    
    // Making these state variables means they wouldn't be updated or set by the initializer.
    // These are part of the view which can be set in initializer so they don't need to be public.
    var useSystemColors: Bool
    var includePercent: Bool
    var fontSize: Double
    //  /// Include the backing view to improve contrast.
    var includeBacking: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    /// Initializer without specifying a battery will assume CurrentDevice.battery, and if that is nil, will use the bad battery mock.
    public init(battery: SomeBattery,
                useSystemColors: Bool = false, includePercent: Bool = true, fontSize: Double = 16, includeBacking: Bool = true) {
        self.battery = battery
        self.useSystemColors = useSystemColors
        self.includePercent = includePercent
        self.fontSize = fontSize
        self.includeBacking = includeBacking
    }
    
    var background: Color {
        if colorScheme == .light {
            return .white
        } else {
            return .black
        }
    }
    
    var color: Color {
        if useSystemColors {
            return battery.systemColor // includes return of yellow on lowPowerMode
        } else {
            return battery.color
        }
    }
    
    var backing: some View {
        Group {
            // when charging the backing isn't needed so will be removed.
            if !battery.isCharging {
                if #available(iOS 15.0, watchOS 8, tvOS 15, macOS 12, *) {
                    batterySymbolImage("battery.100percent")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            background,
                            .clear) // tertiary color unused.
                } else {
                    batterySymbolImage("battery.100percent")
                        .renderingMode(.template)
                        .foregroundColor(background)
                }
            }
        }
    }
    
    var noBattery: some View {
        Group {
            if #available(iOS 15.0, watchOS 8, tvOS 15, macOS 12, *) {
                // Use the uniquely named custom asset so a newer system symbol cannot shadow its annotations.
                Image(symbolName: "battery.slash")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red,
                                     .primary,
                                     .secondary)
            } else {
                // Symbol colored
                Image(symbolName: "battery.slash.legacy")
                    .renderingMode(.template)
                    .foregroundColor(.red)
            }
        }
    }
    
    var shouldShowYellowOutline: Bool {
        !useSystemColors && battery.lowPowerMode
    }


    var coloredBattery: some View {
        Group { // TODO: Is this necessary?
            if battery.currentLevel < 0 { // assume this means a mock signifying we don't have a battery TODO: Have a test to indicate whether this is the nil MockBattery
                noBattery
            } else if #available(iOS 15.0, watchOS 8, tvOS 15, macOS 12, *) {
                let primary: some ShapeStyle = battery.isCharging ? .yellow : color
                let secondary: some ShapeStyle = shouldShowYellowOutline ? .yellow : .primary
                let tertiary: some ShapeStyle = color
				batterySymbolImage(battery.mainActorSymbolName).symbolRenderingMode(.palette)
					.foregroundStyle(primary, secondary, tertiary)
            } else {
                // Symbol colored
                batterySymbolImage(battery.mainActorSymbolName)
                    .renderingMode(.template)
                    .foregroundColor(
                        battery.isCharging ? .yellow : color)
            }         
        }
    }
    
    var percentOverlay: some View {
        Text("\(battery.currentLevel)%  ")
            .font(.system(size: fontSize * 0.3))
            .bold()
            .shadow(color: background, radius: 1)
            .shadow(color: background, radius: 1)
            .shadow(color: background, radius: 1)
    }
    
    public var body: some View {
        ZStack {
            // add back fill to improve contrast
            if includeBacking {
                backing
            }
            // Symbol colored
            coloredBattery
                .shadow(color: background, radius: 1)
            if includePercent && battery.currentLevel >= 0 {
                percentOverlay
            }
        }
        .font(.system(size: fontSize))
		.backport.accessibilityIdentifier("BatteryRendering-level\(battery.currentLevel)-charging\(battery.isCharging)-system\(useSystemColors)-percent\(includePercent)-backing\(includeBacking)")
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct BatteryTestViews<SomeBattery: Battery & ObservableObject>: View {
    public var battery: SomeBattery
    public var fontSize: Double
    public var lowPowerMode: Bool
    public var includeBacking: Bool
    
    public init(battery: SomeBattery, fontSize: Double = 45, lowPowerMode: Bool = false, includeBacking: Bool = true) {
        self.battery = battery
        self.fontSize = fontSize
        self.lowPowerMode = lowPowerMode
        self.includeBacking = includeBacking
    }
    public var body: some View {
        BatteryView(battery: battery, useSystemColors: true, includePercent: true, fontSize: fontSize, includeBacking: includeBacking)
        BatteryView(battery: battery, useSystemColors: true, includePercent: false, fontSize: fontSize, includeBacking: includeBacking)
        Spacer()
        BatteryView(battery: battery, useSystemColors: false, includePercent: false, fontSize: fontSize, includeBacking: includeBacking)
        BatteryView(battery: battery, useSystemColors: false, includePercent: true, fontSize: fontSize, includeBacking: includeBacking)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct BatteryTestsRow<SomeBattery: Battery & ObservableObject>: View {
    public var battery: SomeBattery
    public var fontSize: Double
    public var lowPowerMode: Bool
    public var includeBacking: Bool
    
    public init(battery: SomeBattery, fontSize: Double = 45, lowPowerMode: Bool = false, includeBacking: Bool = true) {
        self.battery = battery
        self.fontSize = fontSize
        self.lowPowerMode = lowPowerMode
        self.includeBacking = includeBacking
    }
    
    public var fullWidthSize: Double {
        #if os(watchOS)
            fontSize * 2
        #else
            fontSize * 5
        #endif
    }
    
    public var body: some View {
        NavigationLink {
            List {
                Text("Description:")
                Text(battery.description)
                Spacer()
                BatteryTestViews(battery: battery, fontSize: fullWidthSize, lowPowerMode: lowPowerMode, includeBacking: includeBacking)
                Spacer()
            }
            .backport.navigationTitle(battery.description)
        } label: {
            HStack {
                BatteryTestViews(battery: battery, fontSize: fontSize, lowPowerMode: lowPowerMode, includeBacking: includeBacking)
            }
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct BatteryTestsView: View {
    @State public var fontSize: Double
    @State public var lowPowerMode: Bool
    @State public var includeBacking: Bool
    
    public init(fontSize: Double = 45, lowPowerMode: Bool = false, includeBacking: Bool = true) {
        self.fontSize = fontSize
        self.lowPowerMode = lowPowerMode
        self.includeBacking = includeBacking
    }
    
    @MainActor
    public var mocks: [MockBattery] {
        MockBattery.mocksFor(lowPowerMode: lowPowerMode)
    }
        
    public var body: some View {
        List {
            Toggle("Low Power Mode", isOn: $lowPowerMode)
            Toggle("Include Backing", isOn: $includeBacking)
            if let battery = Device.current.battery {
                BatteryTestsRow(battery: battery, fontSize: fontSize, lowPowerMode: lowPowerMode, includeBacking: includeBacking)
            }
			ForEach(mocks) { mock in
                BatteryTestsRow(battery: mock, fontSize: fontSize, lowPowerMode: lowPowerMode, includeBacking: includeBacking)
            }
        }
        .backport.navigationTitle("Battery Mocks")
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Battery Tests") {
    BatteryTestsView()
        .navigationWrapper()
}
#endif
