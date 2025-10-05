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
public extension Device.Environment {
    // TODO: Pull into extension
    var color: Color {
        switch self {
        case .realDevice:
            return .green
        case .simulator:
            return .blue
        case .playground:
            return .orange
        case .preview:
            return .pink
        case .designedForiPad:
            return .purple
        case .macCatalyst:
            return .purple
        }
    }
}

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
        case .watch:
                .red
        case .carPlay:
                .green
        case .vision:
                .yellow
        }
    }
}

@available(iOS 14, macOS 12, tvOS 15, watchOS 8, *)
public extension Label where Title == Text, Icon == Image {
    /// Creates a label with an icon image and a title generated from a
    /// localized string.
    ///
    /// - Parameters:
    ///    - titleKey: A title generated from a string. // TODO: LocalizeStringKey instead?
    ///    - symbolName: The name of the symbol resource to lookup (either system or custom included asset).
    init(
        _ titleKey: String,
        symbolName: String
    ) {
        self.init(title: {
            Text(titleKey)
        }, icon: {
            var image = Image(symbolName: symbolName)
            if #available(iOS 15, macCatalyst 15, *) {
                image = image.symbolRenderingMode(.hierarchical)
            }
            return image
        })
    }
}

//public struct StackedLabelStyle: LabelStyle {
//    public func makeBody(configuration: Configuration) -> some View {
//        VStack {
//            configuration.icon.font(.title2)
//            configuration.title.font(.caption2)
//        }
//    }
//}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
struct SomeCurrentDeviceView<SomeCurrentDevice: CurrentDevice, Content: View>: View {
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

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public struct CurrentDeviceInfoView<SomeCurrentDevice: CurrentDevice>: View {
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
                Image(device)
                    .backport.foregroundStyle(Color.accentColor)
                Text("\(device.officialName)")
            }.font(.headline)
//                .accentColor(.green)
            Divider()
            if debug {
                EnvironmentsView()
            }
            SystemInfoView(device: device)
            if device.screen != nil && device.idiom != .vision { // visionOS screen doesn't really make sense at least in the current device view.
                ScreenInfoView(device: device)
            }
            if includeStorage {
                StorageInfoView(device: device)
            }
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
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
        VStack {
            Section("Screenshot Test") {
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
                }
            }
        }
        .backport.navigationTitle("Device Mocks")
    }
}

#if swift(>=5.9)
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
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
