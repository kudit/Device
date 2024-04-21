import SwiftUI

// TODO: Remove?
extension CGSize {
    var transposed: CGSize {
        CGSize(width: height, height: width)
    }
}
// TODO: Remove?
public extension Screen.Size {
    var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }
}

// TODO: Move to KuditFrameworks
extension Double {
    var withoutZeros: String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16 //maximum digits in Double after dot (maximum precision)
        return String(formatter.string(from: number) ?? "")
    }
}

// Unused
extension Text {
    static func +=(lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }
}

struct ScreenBrightnessView<SomeCurrentDevice: CurrentDevice>: View {
    @ObservedObject var currentDevice: SomeCurrentDevice
//    init(currentDevice: SomeCurrentDevice) {
//        self.currentDevice = currentDevice
//    }
    var body: some View {
        if let brightness = currentDevice.brightness {
            HStack(spacing: 2) {
                Image(symbolName: brightness < 0.5 ? "sun.min" : "sun.max")
                Text("\(Int(brightness * 100))%")
            }
//        } else {
//            EmptyView()
        }
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
public struct ScreenInfoView: View {
    public var device: any DeviceType
    public init(device: any DeviceType) {
        self.device = device
    }
    var screen: Screen {
        guard let screen = device.screen else {
            return .undefined // should never happen
        }
        return screen
    }    
    var statusFeatures: some View {
        HStack(spacing: 2) {
            MonitoredCurrentDeviceView(device: device) { currentDevice in
                if let orientation = currentDevice.screenOrientation {
                    Text(Image(orientation))
                }
            }
            MonitoredCurrentDeviceView(device: device) { currentDevice in
                if currentDevice.isZoomed {
                    Text(Image(symbolName: "square.arrowtriangle.4.outward"))
                }
            }
            MonitoredCurrentDeviceView(device: device) { currentDevice in
                if currentDevice.isGuidedAccessSessionActive {
                    Text(Image(symbolName: "lock.square"))
                }
            }
        }
        .font(.footnote)
        .foregroundStyle(.tint)
    }
    public var body: some View {
        VStack {
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Image(symbolName: "rectangle.inset.filled.and.person.filled")
                Text(" Screen").font(.headline)
                Spacer()
                if let diagonal = screen.diagonal {
                    Text("\(diagonal.withoutZeros)").font(.headline)
                    Text(" in ").opacity(0.5)
                    Image(symbolName: "arrow.down.backward.and.arrow.up.forward").font(.headline).opacity(0.5)
                }
            }
            HStack {
                Image(symbolName: "arrow.left.and.right")
                Text("\(screen.resolution.width)")
                Image(symbolName: "arrow.up.and.down")
                Text("\(screen.resolution.height)")
            }
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                if let ppi = screen.ppi {
                    Text("\(ppi)").font(.headline)
                    Text(" ppi  ").opacity(0.5)
                }
                statusFeatures
                Spacer()
                Text("ratio: ").opacity(0.5)
                Text("\(screen.resolution.ratio.width):\(screen.resolution.ratio.height)").font(.headline)
            }
        }
        .overlay {
            VStack {
                CapabilitiesTextView(capabilities: .screenFeatures.intersection(device.capabilities))
                    .font(.footnote)
                    .foregroundStyle(.tint)
                Spacer()
                MonitoredCurrentDeviceView(device: device) { currentDevice in
                    if let brightness = currentDevice.brightness {
                        HStack(spacing: 2) {
                            Image(symbolName: brightness < 0.5 ? "sun.min" : "sun.max")
                            Text("\(Int(brightness * 100))%")
                        }
                    }
                }
            }
        }
        .font(.caption)
        .padding()
        .foregroundStyle(.background)
        .background {
            RoundedRectangle(cornerRadius: 15)
        }
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("Screens") {
    List {
        ForEach(MockDevice.mocks, id: \.id) { device in
            ScreenInfoView(device: device)
        }
        ForEach(Device.all, id: \.self) { device in
            if device.screen != nil && device.screen != .undefined {
                ScreenInfoView(device: device)
            }
        }
    }
}
