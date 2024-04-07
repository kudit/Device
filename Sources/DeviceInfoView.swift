//
//  DeviceInfoView.swift
//  DeviceTest
//
//  Created by Ben Ku on 3/29/24.
//

#if canImport(SwiftUI)
import SwiftUI
import Foundation

// Normally would just use KuditFrameworks but just in case that isn't available...
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// for switching between asset images and systemImages
public extension Image {
    init(symbolName: String) {
        let symbolName = symbolName.safeSymbolName()
        if .nativeSymbolCheck(symbolName) {
            self.init(systemName: symbolName)
        } else {
            // get module image asset if possible
            self.init(symbolName, bundle: Bundle.module)
        }
    }
}
/// helper for making sure symbolName: function always returns an actual image and never `nil`.
extension String {
    func safeSymbolName(fallback: String = "questionmark.square.fill") -> String {
        if !.nativeSymbolCheck(self) {
            // check for asset
            if !.nativeLocalCheck(self) {
                return fallback
            }
        }
        return self
    }
}
extension Bool {
    static func nativeSymbolCheck(_ symbolName: String) -> Bool {
#if canImport(UIKit)
        return UIImage(systemName: symbolName) != nil
#elseif canImport(AppKit)
        return NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) != nil
#endif
    }
    static func nativeLocalCheck(_ symbolName: String) -> Bool {
#if canImport(UIKit)
        return UIImage(named: symbolName, in: Bundle.module, with: nil) != nil
#elseif canImport(AppKit)
        if #available(macOS 13, *) {
            return NSImage(symbolName: symbolName, bundle: Bundle.module, variableValue: 1) != nil
        } else {
            // probably won't work in macOS 12
            return NSImage(named: symbolName) != nil
        }
#endif
    }
}

public struct CapabilitiesTextView: View {
    @State public var capabilities: Capabilities
    
    public init(capabilities: Capabilities) {
        self.capabilities = capabilities
    }
    
    public var body: some View {
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
                    output = output + Text(Image(symbolName: capability.symbolName)) + Text(" ")
                } else {
                    // Fallback on earlier versions
                    output = output + Text("\(capability.symbolName)") + Text(" ")
                }
            }
        }
        return output
    }
}

public struct DeviceInfoView: View {
    public var device: DeviceType

    public init(device: any DeviceType) {
        self.device = device
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(device.name)
                    .font(.headline)
                HStack {
                    ForEach(device.colors, id: \.self) { color in
                        Image(symbolName: device.idiomatic.symbolName)
                            .foregroundColor(Color(hex: color.rawValue))
//                            .shadow(color: .primary, radius: 0.5)
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
    }
}

public struct DeviceListView: View {
    public var devices: [DeviceType]
    
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
                    sections.append((lastIdiom.description, sectionDevices))
                    sectionDevices = []
                }
                lastIdiom = device.idiom
            }
            sectionDevices.append(device)
        }
        if let lastIdiom, sectionDevices.count > 0 {
            sections.append((lastIdiom.description, sectionDevices))
        }
        return sections
    }
    public var body: some View {
        List {
            ForEach(sectioned, id: \.0) { section in
                Section {
                    ForEach(section.1, id: \.device) { device in
                        if #available(tvOS 16.0, watchOS 7.0, *) {
                            DeviceInfoView(device: device)
                            // This is only for testing anyways
                                .onTapGesture {
                                    print(device.description)
                                }
                        } else {
                            // Fallback on earlier versions
                            DeviceInfoView(device: device)
                        }
                    }
                } header: {
                    Text(section.0)
                }
            }
        }
    }
}

#Preview("All Devices") {
    DeviceListView(devices: Device.all)
}

#endif
