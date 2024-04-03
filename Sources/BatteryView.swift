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

public struct BatteryView<B: Battery>: View {
    @ObservedObject public var battery: B
    // Making these state variables means they wouldn't be updated or set by the initializer.
    public var useSystemColors = false
    public var includePercent = true
    public var fontSize: CGFloat = 16
    
    @State private var percent: Int = -1
    @State private var state: BatteryState = .unplugged

    /// This allows this view to update when connected.  Not actually used though.
    @State private var lastUpdate = Date()

    @Environment(\.colorScheme) var colorScheme
        
    public init(battery: B = DeviceBattery.current, useSystemColors: Bool = false, includePercent: Bool = true, fontSize: CGFloat = 16) {
        self.battery = battery
        self.useSystemColors = useSystemColors
        self.includePercent = includePercent
        self.fontSize = fontSize
    }
    
    func update() {
        percent = battery.currentLevel
        state = battery.currentState
        lastUpdate = Date()
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
            return battery.systemColor
        } else {
            return battery.color
        }
    }

    public var body: some View {
        if #available(iOS 15.0, watchOS 8, tvOS 15, *) {
            ZStack {
                // add back fill to improve contrast
                Image(symbolName: "battery.100percent")
                    .font(.system(size: fontSize))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        battery.isCharging ? .clear : background,
                        .clear,
                        .pink)
                // Symbol colored
                Image(symbolName: battery.symbolName)
                    .font(.system(size: fontSize))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        battery.isCharging ? .yellow : color,
                        .foreground,
                        color)
                    .shadow(color: background, radius: 1)
                if includePercent {
                    Text("\(battery.currentLevel)%  ")
                        .font(.system(size: fontSize * 0.3))
                        .bold()
                        .shadow(color: background, radius: 1)
                        .shadow(color: background, radius: 1)
                        .shadow(color: background, radius: 1)
                }
            }
            .task {
                update()
                battery.add { _ in
                    // use monitor callback to force UI to update since can't necessarily depend on observable updates
                    update()
                }
            }
        } else {
            // Fallback on earlier versions
            ZStack {
                // add back fill to improve contrast
                Image(symbolName: "battery.100percent")
                    .renderingMode(.template)
                    .font(.system(size: fontSize))
                    .foregroundColor(
                        battery.isCharging ? .clear : background)
                // Symbol colored
                Image(symbolName: battery.symbolName)
                    .renderingMode(.template)
                    .font(.system(size: fontSize))
                    .foregroundColor(
                        battery.isCharging ? .yellow : color)
                    .shadow(color: background, radius: 1)
                if includePercent {
                    Text("\(battery.currentLevel)%  ")
                        .font(.system(size: fontSize * 0.3))
                        .bold()
                        .shadow(color: background, radius: 1)
                        .shadow(color: background, radius: 1)
                        .shadow(color: background, radius: 1)
                }
            }
            .onAppear {
                update()
                battery.add { _ in
                    // use monitor callback to force UI to update since can't necessarily depend on observable updates
                    update()
                }
            }
        }
    }
}

public struct BatteryTestView: View {
    public var useSystemColors = false
    public var includePercent = true
    public var fontSize: CGFloat = 100
    public init(useSystemColors: Bool = false, includePercent: Bool = true, fontSize: CGFloat = 100) {
        self.useSystemColors = useSystemColors
        self.includePercent = includePercent
        self.fontSize = fontSize
    }
    public var body: some View {
        ForEach(MockBattery.mocks) { mock in
            BatteryView(battery: mock, useSystemColors: useSystemColors, includePercent: includePercent, fontSize: fontSize)
        }
    }
}

#Preview("Batteries") {
    HStack {
        VStack {
            BatteryTestView(includePercent: false)
        }
        VStack {
            BatteryTestView(useSystemColors: true)
        }
    }
}

#endif
