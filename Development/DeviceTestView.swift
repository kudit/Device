#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
import Foundation
import Device
import Compatibility

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Capabilities") {
    VStack {
        HStack {
            Image(symbolName: "star")
            Image(symbolName: "dynamicisland")
            Image(symbolName: "bad")
            Image(symbolName: "battery.slash")
        }
        .symbolRenderingMode(.hierarchical)
		Backport.Label("Foo", symbolName: "star.fill")
		Backport.Label("Bar", symbolName: "roundedcorners")
		Backport.Label("Bad", symbolName: "bad")
		Backport.Label("BS", symbolName: "battery.slash")
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

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
struct SymbolStylePreviews: View {
    let symbolName: SFSymbol
    var size: Double = .defaultFontSize
    var showsLabels = false

    private var displaySize: Double {
#if os(watchOS)
        min(size, 30)
#else
        size
#endif
    }

    private func preview<Content: View>(
        _ title: String,
        @ViewBuilder image: () -> Content
    ) -> some View {
        VStack(spacing: 4) {
            if showsLabels {
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            ZStack {
                Color.clear
                image()
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(sourceBadgeColor)
                            .frame(width: 7, height: 7)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1))
							.backport.accessibilityLabel(sourceLabel)
                    }
            }
            .frame(maxWidth: .infinity, minHeight: displaySize + 4)
        }
        .frame(maxWidth: .infinity)
    }

    var body: some View {
        let symbol = Image(symbolName: symbolName)
        HStack(spacing: 0) {
            preview("Default") { symbol }
            preview("Hierarchical") { symbol.symbolRenderingMode(.hierarchical) }
            preview("Palette") {
                symbol
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.red, .green, .blue)
            }
            preview("Multicolor") { symbol.symbolRenderingMode(.multicolor) }
        }
        .font(.system(size: displaySize))
        .accessibilityElement(children: .contain)
    }

    private var source: SymbolImageSource {
        Image.symbolImageSource(for: symbolName)
    }

    private var sourceBadgeColor: Color {
        switch source {
        case .system: .blue
        case .asset: .orange
        case .legacyAsset: .purple
        case .fallback: .gray
        }
    }

    private var sourceLabel: String {
        switch source {
        case .system: "Native SF Symbol"
        case .asset: "Modern custom symbol asset"
        case .legacyAsset: "Legacy custom symbol asset"
        case .fallback: "Symbol fallback"
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
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
                SymbolStylePreviews(symbolName: attribute.symbolName, size: size)
            } else {
                AttributeTestView(attribute: attribute, device: device)
            }
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("TestAttributeListView") {
    TestAttributeListView(device: Device.current, header: "Environments", attributes: Build.Environment.allCases, styleView: true)
}


@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("DeviceList") {
    DeviceListView(devices: Device.all)
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
public struct DeviceTestView: View {    
	@ObservedObject private var externalDisplays = ExternalDisplayManager.shared

    @State var showMigrations = false
	@State private var keyEvents: [KeyboardInputEvent] = []
	@State private var debugModeEnabled = DeviceTestView.initialDebugModeEnabled
	@State private var showsDebugModeSheet = false
	@State private var keystrokeWindow = ""
	private static var initialDebugModeEnabled: Bool {
		if ProcessInfo.processInfo.environment["DEVICE_UI_TESTING"] == "1" { return true }
		guard UserDefaults.standard.object(forKey: "DeviceDebugModeEnabled") != nil else {
#if DEBUG
			return true
#else
			return false
#endif
		}
		return UserDefaults.standard.bool(forKey: "DeviceDebugModeEnabled")
	}
    @ViewBuilder
    var testView: some View {
        List {
            Section {
                NavigationLink(destination: {
                    CurrentDeviceDetailsView()
                }, label: {
                    CurrentDeviceInfoView(device: Device.current)
                })
            } header: {
                Text("Current Device")
            }
            Section("Environment (Swift \(Device.current.swiftVersion), Compatibility v\(Compatibility.version))") {
                // Display the sample app's process environment directly because mock
                // devices no longer carry artificial simulator or preview state.
                EnvironmentsView(Build.environments())
            }
            Section {
                NavigationLink(destination: { BatteryTestsView() }) {
                    BatteryView(fontSize: 80)
                }
				.backport.accessibilityIdentifier("BatteryTestsLink")
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
#if !os(watchOS)
			Section("Keyboard Input") {
				KeyboardDiagnosticsInput(onTextInput: handleSoftwareKeyboardInput) { press in
					guard !press.phase.contains(.up) else { return .handled }
					let phase = press.phase.contains(.repeat) ? "repeat" : "down"
					let characters = press.characters.isEmpty ? String(press.key.character) : press.characters
					addKeyboardEvent("\(phase) [\(characters)]")
					_ = recordKeystroke(characters)
					// The field is an input target only; keep the rolling key window as its display.
					return .handled
				}
				Text("Recent keys: \(keystrokeWindow)")
					.font(.caption.monospaced())
					.backport.accessibilityIdentifier("KeyboardInputWindow")
				if keyEvents.isEmpty { Text("No key events yet").font(.caption).foregroundColor(.secondary) }
				ForEach(keyEvents) { event in
					Text(event.value).font(.caption).backport.accessibilityIdentifier("KeyboardInputEvent")
				}
				.transaction { $0.animation = nil }
			}
#endif
			if !externalDisplays.presentationIDs.isEmpty {
				Section {
					ForEach(externalDisplays.presentationIDs, id: \.self) { id in
						VStack(alignment: .leading) {
							Text("Presentation: \(id)").font(.caption)
							externalDisplays.orientationPicker(for: id)
						}
					}
				} header: { Text("External displays") }
			}
			Section {
				NavigationLink(destination: { DeviceMocksView() }) {
					Text("Open mock device tests")
				}
				.backport.accessibilityIdentifier("DeviceMocksLink")
			} header: {
				Text("Device Mocks")
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
            }, label: {
                Text("All Devices")
                    .font(.headline)
            })
			if debugModeEnabled {
				if #available(iOS 15, macOS 12, tvOS 17, watchOS 8, *) {
                    NavigationLink(destination: { AllTestsListView() }) {
                        Text("All Tests")
                            .font(.headline)
                    }
                    .backport.accessibilityIdentifier("AllTestsLink")
                }
                Button("Migration") {
                    showMigrations = true
                }
                .backport.navigationDestination(isPresented: $showMigrations) {
                    MigrationMenu()
                }
            }
        }
    }

    private func checkDeviceInfoFromBackground() {
        let operation: @Sendable () async -> Void = {
            // Simulator status is process metadata supplied by Compatibility.Build.
            let isSimulator = Build.isSimulator
            let version: Version = await Device.current.systemVersion
            let info = await Device.current.systemInfo
            // Keep these reads as a compile-time/runtime check of Device.current from background work.
            debug("Device \(isSimulator ? "is" : "is not") simulator", level: .SILENT)
            debug("Version: \(version)\nInfo: \(info)", level: .SILENT)
            debug("Test Version: \(Version("10.4").macOSName)", level: .SILENT)
        }
        Task.background(operation)
    }
    
    public var body: some View {
        BackportNavigationStack {
			testView
        }
		.sheet(isPresented: $showsDebugModeSheet) {
			VStack(alignment: .leading, spacing: 20) {
				Toggle("Enable developer options", isOn: Binding(
					get: { debugModeEnabled },
					set: { newValue in
						debugModeEnabled = newValue
						UserDefaults.standard.set(newValue, forKey: "DeviceDebugModeEnabled")
					}
			))
				.backport.accessibilityIdentifier("DeveloperOptionsToggle")
				HStack {
					Spacer()
					Button("Done") { showsDebugModeSheet = false }
						.backport.accessibilityIdentifier("DeveloperOptionsDone")
				}
			}
			.padding()
			.frame(minWidth: 300, minHeight: 120)
		}
        .onAppear(perform: checkDeviceInfoFromBackground)
    }

	private func addKeyboardEvent(_ event: String) {
		keyEvents.insert(KeyboardInputEvent(value: event), at: 0)
		if keyEvents.count > 5 { keyEvents.removeLast(keyEvents.count - 5) }
	}

	private func recordKeystroke(_ characters: String) -> Bool {
		guard !characters.isEmpty else { return false }
		keystrokeWindow += characters
		keystrokeWindow = String(keystrokeWindow.suffix(5))
		if keystrokeWindow.caseInsensitiveCompare("kudit") == .orderedSame {
			keystrokeWindow = ""
			showsDebugModeSheet = true
			return true
		}
		return false
	}

	private func handleSoftwareKeyboardInput(_ characters: String) {
		// Older iOS software keyboards update the text binding rather than sending
		// UIPress.key events. Feed those characters through the same rolling log.
		for character in characters {
			let value = String(character)
			addKeyboardEvent("down [\(value)]")
			if recordKeystroke(value) { break }
		}
	}
}

private struct KeyboardInputEvent: Identifiable {
	let id = UUID()
	let value: String
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct KeyboardDiagnosticsInput: View {
	@State private var text = ""
	var onTextInput: (String) -> Void
	var onKeyPress: (BackportKeyPress) -> BackportKeyPress.Result
	var body: some View {
		TextField("Type or press a key", text: Binding(
			get: { text },
			set: { newValue in
				guard !newValue.isEmpty else { text = ""; return }
				let inserted = newValue.hasPrefix(text) ? String(newValue.dropFirst(text.count)) : newValue
				text = ""
				if !inserted.isEmpty { onTextInput(inserted) }
			}
		))
		.autocorrectionDisabled(true)
		.backport.textInputAutocapitalization(.never)
		.backport.accessibilityIdentifier("KeyboardDiagnosticsInput")
		.backport.keyInputFocused(true)
		.backport.onKeyPress(phases: .all, action: onKeyPress)
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview {
    DeviceTestView()
}
#endif
