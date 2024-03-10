//
//  BatteryView.swift
//  BatteryClockWidget
//
//  Created by Ben Ku on 3/9/24.
//

#if canImport(SwiftUI)
import SwiftUI

public struct BatteryView<B: Battery>: View {
    @ObservedObject public var battery: B
    @State public var useSystemColors = false
    @State public var includePercent = true
    
    @State private var percent: Int = -1
    @State private var state: BatteryState = .unplugged

    @Environment(\.colorScheme) var colorScheme
    
    @State private var lastUpdate = Date()
    
    public init(battery: B = DeviceBattery.current, useSystemColors: Bool = false, includePercent: Bool = true) {
        self.battery = battery
        self.useSystemColors = useSystemColors
        self.includePercent = includePercent
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
//        VStack {
            ZStack {
                // add back fill to improve contrast
                Image(systemName: "battery.100percent")
#if os(visionOS)
                    .font(.extraLargeTitle)
#else
                    .font(.largeTitle)
#endif
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        battery.isCharging ? .clear : background,
                        .clear,
                        .pink)
                // Symbol colored
                Image(systemName: battery.symbolName)
#if os(visionOS)
                    .font(.extraLargeTitle)
#else
                    .font(.largeTitle)
#endif
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        battery.isCharging ? .yellow : color,
                        .foreground,
                        color)
                    .shadow(color: background, radius: 1)
                if includePercent {
                    Text("\(battery.currentLevel)%  ")
                        .font(.caption)
                        .bold()
                        .shadow(color: background, radius: 1)
                        .shadow(color: background, radius: 1)
                        .shadow(color: background, radius: 1)
                }
            }
//            Text("LU: \(lastUpdate.formatted(date: .omitted, time: .complete))")
//        }
        .task {
            update()
            battery.add { _ in
                update()
            }
        }
    }
}

public struct BatteryTestView: View {
    public init() {}
    public var body: some View {
        ForEach(MockBattery.mocks) { mock in
            BatteryView(battery: mock)
        }
    }
}

#if os(visionOS)
#Preview("Batteries", windowStyle: .plain) {
    VStack {
        BatteryTestView()
    }
}
#else
#Preview("Batteries") {
    VStack {
        BatteryTestView()
    }
}
#endif

#endif
