#if canImport(SwiftUI)
import SwiftUI
import Device
import Compatibility

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("Capabilities") {
    VStack {
        HStack {
            Image(symbolName: "star")
            Image(symbolName: "dynamicisland")
            Image(symbolName: "bad")
            Image(symbolName: "battery.slash")
        }
        .symbolRenderingMode(.hierarchical)
        Label("Foo", symbolName: "star.fill")
        Label("Bar", symbolName: "roundedcorners")
        Label("Bad", symbolName: "bad")
        Label("BS", symbolName: "battery.slash")
        Divider()
        CapabilitiesTextView(capabilities: Set(Capability.allCases))
    }
    .font(.largeTitle)
    .padding()
    .padding()
    .padding()
    .padding()
    .padding()
}

extension Double {
    static let defaultFontSize: Double = 44
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
struct SymbolTests<T: DeviceAttributeExpressible>: View {
    @State var attribute: T
    var size: Double = .defaultFontSize
    var body: some View {
        HStack {
            ZStack {
                Color.clear
                Image(attribute)
            }
            ZStack {
                Color.clear
                Image(attribute)
                    .symbolRenderingMode(.hierarchical)
            }
            ZStack {
                Color.clear
                Image(attribute)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red, .green, .blue)
            }
            ZStack {
                Color.clear
                Image(attribute)
                    .symbolRenderingMode(.multicolor)
            }
        }
        .font(.system(size: size))
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
@MainActor
struct TestAttributeListView<T: DeviceAttributeExpressible>: View {
    @State var device: DeviceType
    @State var header: String
    @State var attributes: [T]
    var styleView = false
    var size: Double = .defaultFontSize
    var body: some View {
        AttributeListView(device: device, header: header, attributes: attributes) { attribute in
            if styleView {
                SymbolTests(attribute: attribute, size: size)
            } else {
                AttributeTestView(attribute: attribute, device: device)
            }
        }
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
@MainActor
struct CurrentDeviceDetailsView: View {
    @State var currentDevice: any CurrentDevice = Device.current
    @State var styleView = false
    @State var size: Double = .defaultFontSize
    init(currentDevice: (any CurrentDevice)? = nil, styleView: Bool = false, size: Double = .defaultFontSize) {
        if let currentDevice {
            self.currentDevice = currentDevice
        }
        self.styleView = styleView
        self.size = size
    }
    var body: some View {
        List {
            Section {
                DeviceInfoView(device: currentDevice)
            } footer: {
                VStack(alignment: .leading) {
                    // for showing text details in a way that can be copied (not available on tvOS)
#if os(tvOS) || os(watchOS)
                    Text("\(currentDevice)").font(.caption)
#else
                    TextEditor(text: .constant("\(currentDevice.description)"))
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
#endif
                    VStack {
                        Spacer()
                        Divider()
                        Spacer()
                        Picker("View", selection: $styleView) {
                            Text("Names").tag(false)
                            Text("Styles").tag(true)
                        }
                        .pickerStyle(.segmentedBackport)
#if !os(tvOS)
                        if styleView {
                            Slider(
                                value: $size,
                                in: 9...100
                            )
                        }
#endif
                    }
                }
            }
            TestAttributeListView(device: currentDevice, header: "Environments", attributes: Device.Environment.allCases, styleView: styleView, size: size)
            TestAttributeListView(device: currentDevice,header: "Idioms", attributes: Device.Idiom.allCases, styleView: styleView, size: size)
            TestAttributeListView(device: currentDevice,header: "Capabilities", attributes: Capability.allCases, styleView: styleView, size: size)
        }
        .backport.navigationTitle("Hardware")
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("CurrentDeviceDetailsView") {
    CurrentDeviceDetailsView()
}
@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("DeviceList") {
    DeviceListView(devices: Device.all)
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
@MainActor
public struct DeviceTestView: View {    
    @ObservedObject var animatedDevice = MockDevice.mocks.first!

    @State var showListings = false
    
    @ViewBuilder
    var testView: some View {
        List {
            Section {
                NavigationLink {
                    BatteryTestsView()
                } label: {
                    BatteryView(fontSize: 80)
                }
#if os(iOS) // only works on iOS so don't show on other devices.
                // TODO: Change to a picker with a mode: enabled, disabled when plugged in, disabled.
                Toggle("Disable Idle Timer", isOn: Binding(get: {
                    return Device.current.isIdleTimerDisabled
                }, set: { newValue in
                    Device.current.isIdleTimerDisabled = newValue
                }))
#endif
            } header: {
                Text("Battery")
            }
            Section("Environment (Swift \(Device.current.swiftVersion), Compatibility v\(Compatibility.version))") { 
                NavigationLink {
                    List {
                        AttributeListView(device: Device.current, header: "Environments", attributes: Device.Environment.allCases)
                    }
                } label: {
                    HStack {
                        Spacer()
                        EnvironmentsView()
                        Spacer()
                    }
                }
            }
            Section {
                NavigationLink(destination: {
                    CurrentDeviceDetailsView()
                }, label: {
                    CurrentDeviceInfoView(device: Device.current)
                })
            } header: {
                Text("Current Device")
            }
            Section {
                NavigationLink(destination: {
                    List {
                        DeviceMocksView()
                    }
                }, label: {
                    CurrentDeviceInfoView(device: animatedDevice)
                })
            } header: {
                Text("Animated Device")
            } footer: {
                HStack {
                    Spacer()
                    Text(verbatim: "© \(Calendar.current.component(.year, from: Date())) Kudit, LLC")
                }
            }
        }
        .backport.navigationTitle("Device.swift v\(Device.version)")
        .toolbar {
            NavigationLink(destination: {
                DeviceListView(devices: Device.all)
                    .toolbar {
                        if Application.isDebug { // This feature should only be for developers, not in the actual app.
                            Button("Check Listings") {
                                showListings = true
                            }
                            .backport.navigationDestination(isPresented: $showListings) {
                                IdentifyModelParsingView()
                            }
                        }
                    }
            }, label: {
                Text("All Devices")
                    .font(.headline)
            })
        }
    }
    
    public var body: some View {
        BackportNavigationStack {
            testView
        }
        .onAppear { // async test
            Task.detached {
                let isSimulator = await Device.current.isSimulator
                let version: Version = await Device.current.systemVersion
                let info = await Device.current.systemInfo
                if isSimulator == !isSimulator { // don't actually print but we want the let above for testing using Device.current from background tasks. - not saying "false" so we don't get compiler warning that this will never be executed.
                    debug("Device \(isSimulator ? "is" : "is not") simulator", level: .DEBUG)
                    print("Version: \(version)\nInfo: \(info)")
                    print("Test Version: \(Version("10.4").macOSName)")
                }
            }
        }
    }
    
//    /// For testing and migrating code during development.
//    func migrateContent() {
//        Migration.migrate()
//    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview {
    DeviceTestView()
}
#endif
