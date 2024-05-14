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
    /// Create image with a symbol name using system SF symbol or fall back to the symbol asset embedded in Device library.
    init(symbolName: String) {
        var symbolName = symbolName
        let legacySymbolName = "\(symbolName).legacy"
        // use the new symbol name for the Xcode 15 symbol assets (should include colors and proper layering)
        if #available(iOS 17.0, watchOS 10.0, macOS 14.0, tvOS 17.0, visionOS 1.0, macCatalyst 17.0, *) {
            symbolName = symbolName.safeSymbolName(fallback: legacySymbolName)
        } else {
            // if older OS, fallback to compatible symbols.
            symbolName = legacySymbolName.safeSymbolName(fallback: symbolName)
        }
        if .nativeSymbolCheck(symbolName) {
            self.init(systemName: symbolName)
        } else {
            // get module image asset if possible
            self.init(symbolName, bundle: Bundle.module)
        }
    }
    init(_ symbolRepresentable: some SymbolRepresentable) {
        self.init(symbolName: symbolRepresentable.symbolName)
    }
}
extension String {
    static var defaultFallback = "questionmark.square.fill"
    /*
     Legacy versions for Symbol (iOS = catalyst = tvOS
     Device min: 15, 11, 14, 6 so create 1.0 or 2.0 versions for fallback.  Make note that watchOS 6 doesn’t support new symbols.
     1.0 = iOS 13, macOS 11, watchOS 6 * Check this with Device minimum version for potential fallbacks or put note that symbols only work on iOS 13+
     2.0 = iOS 14, macOS 11, watchOS 7, Xcode 12
     3.0 = iOS 15, macOS 12, watchOS 8, Xcode 13
     4.0 = iOS 16, macOS 13, watchOS 9, Xcode 14
     5.0 = iOS 17, macOS 14, watchOS 10, Xcode 15 * Anything before this, use legacy version.
     */
    /// helper for making sure symbolName: function always returns an actual image and never `nil`.
    func safeSymbolName(fallback: String = .defaultFallback) -> String {
        if !.nativeSymbolCheck(self) {
            // check for asset
            if !.nativeLocalCheck(self) {
                if fallback == .defaultFallback {
                    return fallback
                } else {
                    // go through the fallback symbol to make sure it's valid (should never really happen)
                    return fallback.safeSymbolName()
                }
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

/// Technincally a function but present like a View struct.
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
                if #available(macOS 12.0, watchOS 8.0, tvOS 15.0, *) {
                    output = output + Text(Image(symbolName: capability.symbolName).symbolRenderingMode(.hierarchical)
                    ) + Text(" ")
                } else {
                    // Fallback on earlier versions
                    output = output + Text(Image(capability)
                    ) + Text(" ")
                }
            } else {
                // Fallback on earlier versions
                output = output + Text("\(capability.symbolName)") + Text(" ")
            }
        }
    }
    return output
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
public struct DeviceInfoView: View {
    public var device: DeviceType
    
    @State var includeScreen: Bool
    
    public init(device: any DeviceType, includeScreen: Bool = false) {
        self.device = device
        self.includeScreen = includeScreen
    }
    
    var deviceColors: some View {
        ForEach(device.colors, id: \.self) { color in
            Image(device.idiomatic)
                .foregroundColor(Color(hex: color.rawValue))
            //                            .shadow(color: .primary, radius: 0.5)
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
                        Text("\(device.cpu.caseName) ").font(.footnote.smallCaps())+Text(
                            Image(symbolName: "cpu"))
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

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
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
            if searchText == "" || "\(device.description) \(device.cpu.caseName)".lowercased().contains(searchText.lowercased()) {
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

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("All Devices") {
    NavigationView {
        DeviceListView(devices: Device.all)
    }
}

#endif
