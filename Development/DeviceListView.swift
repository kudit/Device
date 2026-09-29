//
//  DeviceListView.swift
//  Device
//
//  Created by Ben Ku on 4/8/26.
//

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI

public extension String {
    var asSearchTerm: String {
        // add space after , to make sure that this doesn't count for identifiers which contain a comma
        self.safeDescription.replacingOccurrences(of: [", ","(",")"], with: " ").whitespaceCollapsed.lowercased()
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public struct DeviceListView<Destination: View>: View {
    public var devices: [DeviceType]
    
    @State var searchText = ""
    
    private let destination: (DeviceType) -> Destination
    public init(devices: [any DeviceType], @ViewBuilder destination: @escaping (DeviceType) -> Destination) {
        self.devices = devices
        self.destination = destination
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
            var searchableTerms = device.officialName.components(separatedBy: " ") + [device.cpu.caseName] + device.identifiers + device.models + device.capabilities.map { $0.caseName }
            // TODO: include all os versions so can search for all devices that support iOS15 or macOS16
            if let year = device.introduction?.date?.year {
                searchableTerms += [year.string]
            }
            // normalize
            searchableTerms = searchableTerms.map { $0.asSearchTerm }
            
            let searchText = searchText.asSearchTerm
            var show = true
            if searchText.contains(" ") {
                show = searchableTerms.containsAll(searchText.components(separatedBy: " "))
            } else if searchText != "" {
                show = searchableTerms.joined(separator: " ").contains(searchText)
            }
            
            if show {
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
                            destination(device)
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
@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
public extension DeviceListView where Destination == DeviceDetailView {
    init(devices: [any DeviceType]) {
        self.init(devices: devices) { device in
            DeviceDetailView(device: device)
        }
    }
}

@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
#Preview("All Devices") {
    NavigationView {
        DeviceListView(devices: Device.all) { device in
            List {
                DeviceInfoView(device: device, includeScreen: true, includeAttributes: true)
            }
            .padding()
        }
    }
}
#endif
