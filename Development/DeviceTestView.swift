import SwiftUI
#if canImport(Device) // since this is needed in XCode but is unavailable in Playgrounds.
import Device
#endif

extension Device.Idiom {
    var color: Color {
        switch self {
        case .unspecified:
                .gray
        case .mac:
                .blue
        case .pod:
                .mint
        case .phone:
                .red
        case .pad:
                .purple
        case .tv:
                .brown
        case .homePod:
                .pink
        case .watch:
                .red
        case .carPlay:
                .green
        case .vision:
                .yellow
        }
    }
}

struct TimeClockView: View {
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State var time = Date()
    var body: some View {
        VStack {
            Text("Current time: \(time.formatted(date: .long, time: .complete))")
            if let battery = Device.current.battery {
                Text("Battery Info: \(battery.description)")
                HStack {
                    BatteryView(battery: battery, fontSize: 80)
                    Image(systemName: Device.current.symbolName)
                        .font(.system(size: 80))
                }
            } else {
                Text("No Battery")
                Image(systemName: Device.current.symbolName)
                    .font(.system(size: 80))
            }
        }
        .onReceive(timer, perform: { _ in
            //debug("updating \(time)")
            time = Date()
        })
    }
}

struct StackedLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.icon.font(.title2)
            configuration.title.font(.caption2)
        }
    }
}

struct Placard: View {
    @State var color = Color.gray
    var body: some View {
        // if platform missing, this causes crash.  Also, this needs the stroke(_:lineWidth:antialiased version which is only iOS 17+ to work in previews.
        if #available(iOS 17.0, macOS 14.0, macCatalyst 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *) {
            return RoundedRectangle(cornerRadius: 10)
                .stroke(.primary, lineWidth: 3)
                .fill(color)
        } else {
            return RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.primary, lineWidth: 3)
                .background(RoundedRectangle(cornerRadius: 10).fill(color))
        }
    }
}

struct TestCard: View {
    @State var label = "Unknown"
    @State var highlighted = true
    @State var color = Color.gray
    @State var symbolName = String.symbolUnknownEnvironment
    var body: some View {
        Placard(color: highlighted ? color : .clear)
            .overlay {
                Label(label, systemImage: symbolName)
                    .font(.caption)
                    .symbolRenderingMode(highlighted ? .hierarchical : .monochrome)
            }
    }
}

public struct DeviceTestView: View {
    public var version: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"        
    }
    public var idiomList: some View {
        ForEach(Device.Idiom.allCases) { idiom in
            TestCard(
                label: idiom.description,
                highlighted: Device.current.idiom == idiom,
                color: Device.current.idiom.color,
                symbolName: idiom.symbolName)
        }
    }
    
    public var body: some View {
        ScrollView {
            VStack {
                Group { // so not more than 7 items
                    Text("Kudit/Device v\(version)")
                    TimeClockView()
                    Text("Current device: \(Device.current.description)")
                    Text("Identifier: \(Device.current.identifier)")
                    Text("Device Name: \(Device.current.name ?? "nil")")
                    Text("System Name: \(Device.current.systemName ?? "nil")")
                }
                Group {
                    HStack {
                        //                    TestCard(label: "TEST", highlighted: true, color: .yellow, symbolName: "star.fill")
                        TestCard(
                            label: "Preview",
                            highlighted: Device.current.isPreview,
                            color: .orange,
                            symbolName: .symbolPreview
                        )
                        TestCard(
                            label: "Playground",
                            highlighted: Device.current.isPlayground,
                            color: .pink,
                            symbolName: .symbolPlayground)
                        TestCard(
                            label: "Simulator",
                            highlighted: Device.current.isSimulator,
                            color: .blue,
                            symbolName: .symbolSimulator)
                        TestCard(
                            label: "Real Device",
                            highlighted: Device.current.isRealDevice,
                            color: .green,
                            symbolName: .symbolRealDevice)
                        if [.mac, .vision].contains(Device.current.idiom) {
                            TestCard(
                                label: "Designed for iPad",
                                highlighted: Device.current.isDesignedForiPad,
                                color: .purple,
                                symbolName: .symbolDesignedForiPad)
                        }
                    }
                    .labelStyle(StackedLabelStyle())
                    .frame(height: 60)
                    HStack {
                        VStack {
                            BatteryTestView(useSystemColors: true, fontSize: 40)
                        }
                        VStack {
                            idiomList
                        }
                        VStack {
                            BatteryTestView(includePercent: false, fontSize: 40)
                        }
                    }
                }
                .padding()
                Spacer()
            }
        }
    }
}

#Preview {
    DeviceTestView()
}
