#if canImport(SwiftUI)
import SwiftUI

public extension Screen.Size {
    /// Conversion of Screen.Size to CGSize
    var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }
}

// TODO: Remove once we're using Compatibility v1.0.19 or later
extension Double {
    var withoutZeros: String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16 //maximum digits in Double after dot (maximum precision)
        return String(formatter.string(from: number) ?? "")
    }
}

@available(iOS 13.0, tvOS 13, watchOS 6, *)
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

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
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
    @MainActor
    var statusFeatures: some View {
        HStack(spacing: 2) {
            MonitoredCurrentDeviceView(device: device) { currentDevice in
                if let orientation = currentDevice.screenOrientation {
                    if #available(iOS 14.0, *) {
                        Text(Image(orientation))
                    } else {
                        // Fallback on earlier versions
                        Text(orientation.symbolName)
                    }
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
#if os(visionOS)
        .foregroundStyle(.black) // can do background but doesn't provide enough contrast.
#else
        .foregroundStyle(.background)
#endif
        .background {
            RoundedRectangle(cornerRadius: .devicePanelRadius)
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Screens") {
    List {
        Section {
            Text("Current Device")
            ScreenInfoView(device: Device.current)
        }
        Section {
            ForEach(MockDevice.mocks, id: \.identifiers) { device in
                Text(device.identifier)
                ScreenInfoView(device: device)
            }
        }
        Section {
            ForEach(Device.all, id: \.self) { device in
                if device.screen != nil && device.screen != .undefined {
                    Text(device.officialName)
                    ScreenInfoView(device: device)
                }
            }
        }
    }
}
#endif
