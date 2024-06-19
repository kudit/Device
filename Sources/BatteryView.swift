//
//  BatteryView.swift
//  BatteryClockWidget
//
//  Created by Ben Ku on 3/9/24.
//

#if canImport(SwiftUI)
import SwiftUI

// support relative font
// https://malauch.com/posts/auto-resizable-text-size-in-swiftui/
/*
 let font = Font.custom("SF Pro", size: 8, relativeTo: .caption2)
 .system(size:) should support relativeTo:
 .font(.system(size: 200))  // 1
 .minimumScaleFactor(0.01)  // 2
 */

@MainActor
class PolymorphicBattery: ObservableObject {
    @Published var monitoredDeviceBattery: MonitoredDeviceBattery?
    @Published var deviceBattery: DeviceBattery?
    @Published var mockBattery: MockBattery = .missing // guarantees that this will never be nil and the polymorphic battery will have at least one representation
} 
public struct BatteryView: View {
    // ObservedObject can't be used with any.
    @ObservedObject var polymorphicBattery = PolymorphicBattery()
    
    // Making these state variables means they wouldn't be updated or set by the initializer.
    // These are part of the view which can be set in initializer so they don't need to be public.
    var useSystemColors: Bool
    var includePercent: Bool
    var fontSize: Double
    //    /// Include the backing view to improve contrast.
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
    func batteryView(battery: some Battery) -> some View {
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

public struct SpecificBatteryView<SomeBattery: Battery>: View {
    // ObservedObject can't be used with any.
    @ObservedObject public var battery: SomeBattery
    
    // Making these state variables means they wouldn't be updated or set by the initializer.
    // These are part of the view which can be set in initializer so they don't need to be public.
    var useSystemColors: Bool
    var includePercent: Bool
    var fontSize: Double
    //    /// Include the backing view to improve contrast.
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
                    Image(symbolName: "battery.100percent")
                        .font(.system(size: fontSize))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(
                            background,
                            .clear) // tertiary color unused.
                } else {
                    Image(symbolName: "battery.100percent")
                        .renderingMode(.template)
                        .font(.system(size: fontSize))
                        .foregroundColor(background)
                }
            }
        }
    }
    
    var noBattery: some View {
        Group {
            // TODO: Re-design symbol to be simpler?
            if #available(iOS 15.0, watchOS 8, tvOS 15, macOS 12, *) {
                // Symbol colored
                Image(symbolName: "battery.slash") // batteryblock.slash
                    .font(.system(size: fontSize))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red,
                                     .foreground,
                                     color)
            } else {
                // Symbol colored
                Image(symbolName: "battery.slash")
                    .renderingMode(.template)
                    .font(.system(size: fontSize))
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
                // Symbol colored
                Image(battery)
                    .font(.system(size: fontSize))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        battery.isCharging ? .yellow : color,
                        !useSystemColors && battery.lowPowerMode ? .yellow : .primary, // outline.  NOTE: .foreground style doesn't work here probably because not a color
                        color)
            } else {
                // Symbol colored
                Image(battery)
                    .renderingMode(.template)
                    .font(.system(size: fontSize))
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
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
public struct BatteryTestsRow<SomeBattery: Battery>: View {
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
        HStack {
            BatteryView(battery: battery, useSystemColors: true, includePercent: true, fontSize: fontSize, includeBacking: includeBacking)
            BatteryView(battery: battery, useSystemColors: true, includePercent: false, fontSize: fontSize, includeBacking: includeBacking)
            Spacer()
            BatteryView(battery: battery, useSystemColors: false, includePercent: false, fontSize: fontSize, includeBacking: includeBacking)
            BatteryView(battery: battery, useSystemColors: false, includePercent: true, fontSize: fontSize, includeBacking: includeBacking)
        }
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
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
        .navigationTitle("Battery Mocks")
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("Battery Tests") {
    BatteryTestsView()
}
#endif
