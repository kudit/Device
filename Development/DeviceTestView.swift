import SwiftUI
#if canImport(Device) // since this is needed in XCode but is unavailable in Playgrounds
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
                .gray
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
                BatteryView(battery: battery)
            } else {
                Text("No Battery")
            }
        }
        .onReceive(timer, perform: { _ in
            //debug("updating \(time)")
            time = Date()
        })
    }
}

struct Placard: View {
    @State var color = Color.gray
    var body: some View {
        if #available(macCatalyst 17.0, iOS 17.0, *) {
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
    @State var visible = true
    @State var color = Color.gray
    var body: some View {
        Placard(color: visible ? color : .clear)
            .overlay {
                Text(label)
                    .font(.caption)
            }
    }
}

public struct DeviceTestView: View {
    public var body: some View {
        VStack {
            Text("Hello, Device world!")
            TimeClockView()
            Text("Current device: \(Device.current.description)")
            Text("Simulator Model Identifier: \(ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "none")")
            Text("Identifier: \(Device.current.identifier)")
            Text("Device Name: \(Device.current.name ?? "nil")")
            Text("System Name: \(Device.current.systemName ?? "nil")")
            Group {
                HStack {
                    TestCard(
                        label: "Preview",
                        visible: Device.current.isPreview,
                        color: .orange)
                    TestCard(
                        label: "Playground",
                        visible: Device.current.isPlayground,
                        color: .pink)
                    TestCard(
                        label: "Simulator",
                        visible: Device.current.isSimulator,
                        color: .blue)
                    TestCard(
                        label: "Real Device",
                        visible: Device.current.isRealDevice,
                        color: .green)
                }
                .frame(height: 44)
                HStack {
                    VStack {
                        ForEach(Device.Idiom.allCases) { idiom in
                            TestCard(label: idiom.description, visible: Device.current.idiom == idiom, color: Device.current.idiom.color)
                        }
                    }
                    VStack {
                        BatteryTestView()
                    }
                }
            }
            .padding()
            Spacer()
        }
    }
}
