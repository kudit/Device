//
//  DeviceInfoView.swift
//  DeviceTest
//
//  Created by Ben Ku on 3/29/24.
//

#if canImport(SwiftUI)
import SwiftUI
import Foundation

public extension CGFloat {
    static let devicePanelRadius: Double = 15
}

/// Technincally a function but present like a View struct.
@available(iOS 13, tvOS 13, watchOS 6, *)
@MainActor
public func CapabilitiesTextView(capabilities: Capabilities) -> Text {
    var output = Text("")
    for capability in capabilities.sorted {
        // don't show screen icon since not really helpful
        if case .screen = capability {}
        // don't show mac form either since redundant
        else if case .macForm = capability {}
        // and cellular doesn't really make sense either unless we want to indicate the type
        else if case .cellular = capability {}
        // and cameras don't really make sense either
        else if case .cameras = capability {}
        // and we don't really want to flag battery here
        else if case .battery = capability {}
        // and watches don't need watch size
        else if case .watchSize = capability {}
        else {
            if #available(watchOS 7.0, *) {
                // Fallback on earlier versions
                if #available(iOS 14, macOS 11.0, tvOS 14, *) {
                    if #available(iOS 15, macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                        output = output + Text(Image(symbolName: capability.symbolName).symbolRenderingMode(.hierarchical)
                        ) + Text(" ")
                    } else {
                        output = output + Text(Image(capability)
                        ) + Text(" ")
                    }
                } else {
                    // Fallback on earlier versions
                    output = output + Text(capability.caseName)
                    + Text(" ")
                }
            } else {
                // Fallback on earlier versions
                output = output + Text("\(capability.symbolName)") + Text(" ")
            }
        }
    }
    return output
}

@available(iOS 15, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
public struct DeviceInfoView: View {
    public var device: DeviceType
    
    var includeScreen = false
    
    public init(device: any DeviceType, includeScreen: Bool = false) {
        self.device = device
        self.includeScreen = includeScreen
    }
    
    var deviceColors: some View {
        ForEach(device.colors, id: \.self) { color in
            Image(device.idiomatic)
                .foregroundColor(Color(hex: color.rawValue))
                .shadow(color: .gray, radius: 0.5)
        }
}
    
    public var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(device.officialName)
                        .font(.headline)
                    HStack {
                        deviceColors
                        Spacer(minLength: 0)
                        if #available(iOS 14.0, *) {
                            Text("\(device.cpu.caseName) ").font(.footnote.smallCaps())+Text(
                                Image(symbolName: "cpu"))
                        } else {
                            // Fallback on earlier versions
                            Text("\(device.cpu.caseName) ").font(.footnote.smallCaps())+Text("cpu")
                        }
                    }
                    HStack {
                        CapabilitiesTextView(capabilities: device.capabilities)
                    }
                    .font(.caption)
                }
                Spacer()
                if let image = device.image {
                    if #available(iOS 15.0, macOS 12, macCatalyst 15, tvOS 15, watchOS 8, *) {
                        AsyncImage(url: URL(string: image)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 60, height: 60)
                    } else {
                        // Fallback on earlier versions
                        // Don't show the image on devices less than iOS 15
                    }
                }
            }
            if device.screen != nil && includeScreen {
                ScreenInfoView(device: device)
            }
        }
    }
}

@available(iOS 15, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct DeviceListView: View {
    public var devices: [DeviceType]
    
    @State var searchText = ""
    
    public init(devices: [any DeviceType]) {
        self.devices = devices
    }
    
    // TODO: extract this out into KuditFrameworks as a way to section content with a callback for determining the header to group under.
    var sectioned: [(String,[DeviceType])] {
        var sections = [(String,[DeviceType])]()
        var lastIdiom: Device.Idiom?
        var sectionDevices = [DeviceType]()
        for device in devices {
            if device.idiom != lastIdiom {
                if let lastIdiom, sectionDevices.count > 0 {
                    sections.append((lastIdiom.label, sectionDevices))
                    sectionDevices = []
                }
                lastIdiom = device.idiom
            }
            if searchText == "" || "\(device.safeOfficialName) \(device.cpu.caseName) \(device.identifiers.joined(separator: " "))".lowercased().contains(searchText.lowercased()) {
                sectionDevices.append(device)
            }
        }
        if let lastIdiom, sectionDevices.count > 0 {
            sections.append((lastIdiom.label, sectionDevices))
        }
        return sections
    }
    public var body: some View {
        List {
            ForEach(sectioned, id: \.0) { section in
                Section {
                    ForEach(section.1, id: \.device) { device in
                        NavigationLink {
                            VStack {
                                DeviceInfoView(device: device, includeScreen: true)
                                Spacer()
                            }
                            .padding()
                        } label: {
                            DeviceInfoView(device: device, includeScreen: false)
                        }
                    }
                } header: {
                    Text(section.0)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Devices")
    }
}

@available(iOS 15, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
#Preview("All Devices") {
    NavigationView {
        DeviceListView(devices: Device.all)
    }
}
#endif
