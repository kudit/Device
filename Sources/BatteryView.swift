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

public struct BatteryView<SomeBattery: Battery>: View {
    @ObservedObject public var battery: SomeBattery

    // Making these state variables means they wouldn't be updated or set by the initializer.
    // These are part of the view which can be set in initializer so they don't need to be public.
    var useSystemColors: Bool
    var includePercent: Bool
    var fontSize: CGFloat
//    /// Include the backing view to improve contrast.
    var includeBacking: Bool

    @Environment(\.colorScheme) var colorScheme
        
    public init(battery: SomeBattery, useSystemColors: Bool = false, includePercent: Bool = true, fontSize: CGFloat = 16, includeBacking: Bool = true) {
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

public struct MonitoredBatteryView: View {
    var battery: (any Battery)?

    var useSystemColors: Bool
    var includePercent: Bool
    var fontSize: CGFloat
    //    /// Include the backing view to improve contrast.
    var includeBacking: Bool
        
    public init(battery: (any Battery)?, useSystemColors: Bool = false, includePercent: Bool = true, fontSize: CGFloat = 16, includeBacking: Bool = true) {
        self.battery = battery
        self.useSystemColors = useSystemColors
        self.includePercent = includePercent
        self.fontSize = fontSize
        self.includeBacking = includeBacking
        #if targetEnvironment(macCatalyst)
        Device.current.enableMonitoring(frequency: 1)
        #endif
    }
    public var body: some View {
        Group {
            if let battery = battery as? MonitoredDeviceBattery {
                BatteryView(battery: battery, useSystemColors: useSystemColors, includePercent: includePercent, fontSize: fontSize, includeBacking: includeBacking)
            } else if let battery = battery as? DeviceBattery {
                BatteryView(battery: battery, useSystemColors: useSystemColors, includePercent: includePercent, fontSize: fontSize, includeBacking: includeBacking)
            } else if let battery = battery as? MockBattery {
                BatteryView(battery: battery, useSystemColors: useSystemColors, includePercent: includePercent, fontSize: fontSize, includeBacking: includeBacking)
            } else {
                EmptyView()
            }
        }
    }
}

public struct BatteryTestsView: View {
    @State public var fontSize: CGFloat
    @State public var lowPowerMode: Bool
    @State public var includeBacking: Bool
    
    public init(fontSize: CGFloat = 45, lowPowerMode: Bool = false, includeBacking: Bool = true) {
        self.fontSize = fontSize
        self.lowPowerMode = lowPowerMode
        self.includeBacking = includeBacking
    }
    
    /// go through and update all mocks so the low power mode is applied
    func updateMocksLowPowerMode() {
        for mock in MockBattery.mocks {
            mock.lowPowerMode = lowPowerMode
        }
    }
    
    public var body: some View {
        List {
            Toggle("Low Power Mode", isOn: $lowPowerMode)
                .backport.onChange(of: lowPowerMode) {
                    updateMocksLowPowerMode()
                }
            Toggle("Include Backing", isOn: $includeBacking)
            ForEach(MockBattery.mocks) { mock in
                HStack {
                    BatteryView(battery: mock, useSystemColors: true, includePercent: true, fontSize: fontSize, includeBacking: includeBacking)
                    BatteryView(battery: mock, useSystemColors: true, includePercent: false, fontSize: fontSize, includeBacking: includeBacking)
                    Spacer()
                    BatteryView(battery: mock, useSystemColors: false, includePercent: false, fontSize: fontSize, includeBacking: includeBacking)
                    BatteryView(battery: mock, useSystemColors: false, includePercent: true, fontSize: fontSize, includeBacking: includeBacking)
                }
            }
        }
        .navigationTitle("Battery Mocks")
    }
}

#Preview("Battery Tests") {
    BatteryTestsView()
}

#endif
