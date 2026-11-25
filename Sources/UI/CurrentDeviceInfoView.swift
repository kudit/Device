//
//  DeviceInfoView.swift
//  DeviceTest
//
//  Created by Ben Ku on 3/29/24.
//

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
import Foundation
import Compatibility

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension ThermalState {
    var color: Color {
        switch self {
        case .nominal:
            return .blue
        case .fair:
            return .yellow
        case .serious:
            return .orange
        case .critical:
            return .red
        }
    }
}

// For adding Expressible conformance
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Capability {
    var color: Color { .green }
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Device.Idiom {
    var color: Color {
        switch self {
        case .unspecified:
                .gray
        case .mac:
                .blue
        case .pod:
                .pink
        case .phone:
                .red
        case .pad:
                .purple
        case .tv:
                .blue
        case .homePod:
                .pink
        case .homeView:
                .orange
        case .watch:
                .red
        case .carPlay:
                .green
        case .vision:
                .yellow
        }
    }
}

//public struct StackedLabelStyle: LabelStyle {
//  public func makeBody(configuration: Configuration) -> some View {
//    VStack {
//      configuration.icon.font(.title2)
//      configuration.title.font(.caption2)
//    }
//  }
//}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
struct SomeCurrentDeviceView<SomeCurrentDevice: CurrentDevice & ObservableObject, Content: View>: View {
    @ObservedObject var currentDevice: SomeCurrentDevice
    private let content: (any CurrentDevice) -> Content
    init(currentDevice: SomeCurrentDevice, @ViewBuilder content: @escaping (any CurrentDevice) -> Content) {
        self.currentDevice = currentDevice
        self.content = content
    }
    var body: some View {
        content(currentDevice)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct MonitoredCurrentDeviceView<Content: View>: View {
    var device: any DeviceType
    private let content: (any CurrentDevice) -> Content
    public init(device: any DeviceType, @ViewBuilder content: @escaping (any CurrentDevice) -> Content) {
        self.device = device
        self.content = content
    }
    public var body: some View {
        Group {
            if let device = device as? ActualHardwareDevice {
                SomeCurrentDeviceView(currentDevice: device) { cd in
                    content(cd)
                }
            } else if let device = device as? MockDevice {
                SomeCurrentDeviceView(currentDevice: device) { cd in
                    content(cd)
                }
            } else {
                EmptyView()
            }
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct CurrentDeviceInfoView<SomeCurrentDevice: CurrentDevice & ObservableObject>: View {
    @ObservedObject var device: SomeCurrentDevice
    @State var includeStorage: Bool
    @State var debug: Bool
    
    public init(device: SomeCurrentDevice, includeStorage: Bool = true, debug: Bool = false) {
        self.device = device
        self.includeStorage = includeStorage
        self.debug = debug
    }

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
				if device.device.screens.count > 1 {
					// The row identifies the Duo hardware itself. Live posture is
					// shown in ScreenInfoView, where it can change independently.
					DevicePoseView(pose: .closed, device: device)
						.backport.foregroundStyle(Color.accentColor)
				} else {
					if device.mainActorSymbolName == "macbook.gen3" {
						if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
							Image(symbolName: device.mainActorSymbolName)
								.symbolRenderingMode(.hierarchical)
								.foregroundStyle(Color.accentColor, .secondary)
						} else {
							Image(symbolName: device.mainActorSymbolName)
								.backport.foregroundStyle(Color.accentColor)
						}
					} else {
						Image(symbolName: device.mainActorSymbolName)
							.backport.foregroundStyle(Color.accentColor)
					}
				}
                Text("\(device.officialName)")
            }.font(.headline)
//        .accentColor(.green)
            Divider()
            if debug {
                // Build environments belong to the running process, not to the displayed
                // hardware model, so use Compatibility's canonical environment checks.
                EnvironmentsView(Build.environments())
            }
            SystemInfoView(device: device)
            if let mock = device as? MockDevice {
				HStack {
					Text("Mock update \(mock.updateCount)")
						.backport.accessibilityIdentifier("AnimatedMockUpdateCount")
						.backport.accessibilityLabel("Mock update \(mock.updateCount)")
					Spacer()
					Text("Brightness \(Int((mock.brightness ?? 0) * 100))%")
				}
				.font(.caption.monospacedDigit())
			}
            if !device.screens.isEmpty && device.idiom != .vision { // visionOS screen doesn't really make sense at least in the current device view.
                if device is ActualHardwareDevice { ScreenInfoView() }
            }
            if includeStorage {
                StorageInfoView(device: device)
            }
        }
        // NavigationLink selection supplies a contrasting foreground through
        // the environment; explicitly anchor this summary text to the primary
        // color so the selected current-device row remains readable.
		.backport.foregroundStyle(.primary)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
public struct DeviceMocksView: View {
    @State public var includeStorage: Bool
    @State public var debug: Bool
    @State public var screenshot: Image?

    public init(includeStorage: Bool = true, debug: Bool = false) {
        self.includeStorage = includeStorage
        self.debug = debug
    }

    public var body: some View {
		List {
			Backport.Section("Screenshot Test") {
                if let screenshot {
                    screenshot
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .backport.draggable(screenshot)
                } else {
                    Text("No Screenshot")
                }
                Button("Screenshot") {
                    screenshot = Application.main.screenshots().first
                }
            }
			ForEach(MockDevice.mocks, id: \.identifier) { mock in
                Section {
                    CurrentDeviceInfoView(device: mock, includeStorage: includeStorage, debug: debug)
					if mock === MockDevice.animated {
						AnimatedMockScreenStateView(device: mock)
					}
				} header: {
					Text(mock.officialName)
                }
            }
        }
        .backport.navigationTitle("Device Mocks")
    }
}

/// Live pose, orientation, brightness, and panel information for the animated Duo mock.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
private struct AnimatedMockScreenStateView: View {
	@ObservedObject var device: MockDevice

	private var orientation: Device.Orientation { device.deviceOrientation }

	var body: some View {
		HStack(spacing: 12) {
			DevicePoseView(pose: device.pose, device: device.device, orientation: orientation)
				.font(.title)
				.backport.accessibilityIdentifier("AnimatedMockPose")
			DeviceOrientationView(orientation: orientation, device: device.device)
				.font(.title)
				.backport.accessibilityIdentifier("AnimatedMockOrientation")
			VStack(alignment: .leading, spacing: 3) {
				Text("Animated screen state").font(.headline)
				Text("Pose: \(device.pose.rawValue)")
					.backport.accessibilityIdentifier("AnimatedMockPoseValue")
				Text("Orientation: \(orientation.accessibilityDescription)")
					.backport.accessibilityIdentifier("AnimatedMockOrientationValue")
				if let brightness = device.brightness {
					Text("Brightness: \(Int(brightness * 100))%")
				}
				if let panel = device.device.screens.first {
					Text("Panel: \(panel.resolution.width) × \(panel.resolution.height) px")
				}
			}
			.font(.caption)
			Spacer(minLength: 0)
		}
		.padding()
	}
}

#if swift(>=5.9)
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Current Device") {
    List {
        Section {
            CurrentDeviceInfoView(device: Device.current, debug: true)
        }
        Divider()
        DeviceMocksView(debug: false)
    }
}
#endif
#endif
