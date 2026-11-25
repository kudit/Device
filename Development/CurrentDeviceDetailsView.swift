//
//  CurrentDeviceDetailsView.swift
//  Device
//
//  Created by Ben Ku on 10/29/26.
//

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
import Compatibility

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
struct CurrentDeviceDetailsView: View {
    @State var currentDevice: any CurrentDevice = Device.current
    @State var styleView = false
    @State var size: Double = .defaultFontSize
    @State private var symbolName = "battery.slash"

	/// `Capability.allCases` contains a row for each biometric technology;
	/// Pencil is value-associated and therefore needs one additional row.
	private var capabilityRows: [Capability] {
		var seen = Set<Capability>()
		let pencilRows = ApplePencil.allCases.map { Capability.pencils([$0]) }
		return (Capability.allCases + pencilRows).filter { seen.insert($0).inserted }
	}

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
                    Text("\(currentDevice.description)").font(.caption)
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
            TestAttributeListView(device: currentDevice, header: "Environments", attributes: Build.Environment.allCases, styleView: styleView, size: size)
            TestAttributeListView(device: currentDevice,header: "Idioms", attributes: Device.Idiom.allCases, styleView: styleView, size: size)
            TestAttributeListView(device: currentDevice,header: "Capabilities", attributes: capabilityRows, styleView: styleView, size: size)
            if styleView {
                Section {
                    TextField("SF Symbol name", text: $symbolName)
                        .backport.textInputAutocapitalization(.never)
                        .disableSmartQuotes()
						.backport.accessibilityIdentifier("device.symbol-test.name")
                    SymbolStylePreviews(symbolName: symbolName, size: size)
                } header: {
                    Text("Symbol Test")
                }
            }
        }
        .backport.navigationTitle("Hardware")
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("CurrentDeviceDetailsView") {
    CurrentDeviceDetailsView()
}
#endif
