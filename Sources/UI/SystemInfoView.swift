#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
import Compatibility

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct SystemInfoView<SomeCurrentDevice: CurrentDevice>: View {
    @Environment(\.colorScheme) private var colorScheme
    public var device: SomeCurrentDevice
    public init(device: SomeCurrentDevice) {
        self.device = device
    }
    public var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 0) {
                Text("\"\(device.name)\"")
                Spacer()
                MonitoredCurrentDeviceView(device: device) { currentDevice in
                    Text("*\(device.identifier) running \(device.systemInfo)*")
                }
            }.font(.callout).padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
//      Text("\(device.model)").opacity(0.5) // not necessary
//      Text("\(device.localizedModel)").opacity(0.5) // not necessary
            HStack(alignment: .lastTextBaseline) {
                // perhaps guage?  Otherwise text display with small units?
                MonitoredCurrentDeviceView(device: device) { currentDevice in
                    Image(currentDevice.thermalState).font(.title)
						.closure { view in
							if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
								if currentDevice.thermalState == .nominal {
									view.foregroundStyle(.primary, currentDevice.thermalState.color, .secondary)
								} else {
									view.foregroundStyle(currentDevice.thermalState.color, currentDevice.thermalState.color, .secondary)
								}
							} else {
								view.foregroundColor(currentDevice.thermalState.color)
							}
						}
                    VStack(alignment: .leading) {
                        Text(" thermal state").font(.footnote.smallCaps()).opacity(0.5)
                        Text(" \(String(describing: currentDevice.thermalState))").font(.headline)
                    }
                    Spacer()
					Text("\(device.cpu.caseName) ").font(.footnote.smallCaps()) + Text(symbolName: "cpu")
                }
                if let battery = device.battery {
                    Spacer()
                    BatteryView(battery: battery, fontSize: 44)
                }
}
            
            //      if let screen = device.screen {
            // TODO: Create Application info view for version, icon, info, previous run versions, etc.
//        if let image = UIApplication.shared.icon {
//          Image(uiImage: image)
//        }
//        Image("AppIcon", bundle: .module)
//        Image(symbolName: "app")
        }
        .font(.caption)
        .padding()
        // This panel is drawn on a light card even when its NavigationLink is
        // selected, so it must not inherit the selection's white foreground.
		.backport.foregroundStyle(colorScheme == .dark ? .white : .black)
		.backport.background {
            ZStack {
				RoundedRectangle(cornerRadius: .devicePanelRadius).backport.fill(.background)
				RoundedRectangle(cornerRadius: .devicePanelRadius).backport.stroke(.primary)
            }
        }
    }
}

#if swift(>=5.9)
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("SystemInfo") {
    List {
        SystemInfoView(device: Device.current)
        Divider()
        ForEach(MockDevice.mocks, id: \.identifiers) { device in
            Text(String(describing: device.device))
            SystemInfoView(device: device)
        }
    }
}
#endif
#endif
