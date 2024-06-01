#if canImport(SwiftUI)
import SwiftUI

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
public struct SystemInfoView<SomeCurrentDevice: CurrentDevice>: View {
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
                    Text("*\(device.identifier) running \(device.systemName) \(currentDevice.systemVersion)*")
                }
            }.font(.callout).padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
//            Text("\(device.model)").opacity(0.5) // not necessary
//            Text("\(device.localizedModel)").opacity(0.5) // not necessary
            HStack(alignment: .lastTextBaseline) {
                // perhaps guage?  Otherwise text display with small units?
                MonitoredCurrentDeviceView(device: device) { currentDevice in
                    Image(currentDevice.thermalState).font(.title)
                        .foregroundStyle(currentDevice.thermalState == .nominal ? .primary : currentDevice.thermalState.color, currentDevice.thermalState.color, .secondary)
                    VStack(alignment: .leading) {
                        Text(" thermal state").font(.footnote.smallCaps()).opacity(0.5)
                        Text(" \(String(describing: currentDevice.thermalState))").font(.headline)
                    }
                    Spacer()
                    Text("\(device.cpu.caseName) ").font(.footnote.smallCaps())+Text(
                        Image(symbolName: "cpu"))
                }
                if let battery = device.battery {
                    Spacer()
                    BatteryView(battery: battery, fontSize: 44)
                }
}
            
            //            if let screen = device.screen {
            // TODO: Create Application info view for version, icon, info, previous run versions, etc.
//                if let image = UIApplication.shared.icon {
//                    Image(uiImage: image)
//                }
//                Image("AppIcon", bundle: .module)
//                Image(symbolName: "app")
        }
        .font(.caption)
        .padding()
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: .devicePanelRadius)
                    .fill(.background)
                RoundedRectangle(cornerRadius: .devicePanelRadius)
                    .stroke(.primary)
            }
        }
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("SystemInfo") {
    List {
        SystemInfoView(device: Device.current)
        Divider()
        ForEach(MockDevice.mocks, id: \.id) { device in
            Text(String(describing: device))
            SystemInfoView(device: device)
        }
    }
}
#endif
