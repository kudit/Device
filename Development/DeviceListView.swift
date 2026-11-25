//
//  DeviceListView.swift
//  Device
//
//  Created by Ben Ku on 4/8/26.
//

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI

private struct SearchableDeviceEntry {
	let device: DeviceType
	let terms: [String]
	let joinedTerms: String

	init(device: DeviceType) {
		self.device = device
		var terms = device.officialName.components(separatedBy: " ") + [device.cpu.caseName] + device.identifiers + device.models + device.capabilities.map { $0.caseName }
		// TODO: include all OS versions so can search for all devices that support iOS15 or macOS16
		if let year = device.introductionYear { terms.append(year.string) }
		self.terms = terms.map(\.asSearchTerm)
		joinedTerms = self.terms.joined(separator: " ")
	}
}

public extension String {
    var asSearchTerm: String {
        // add space after , to make sure that this doesn't count for identifiers which contain a comma
        self.safeDescription.replacingOccurrences(of: [", ","(",")"], with: " ").whitespaceCollapsed.lowercased()
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct DeviceListView<Destination: View>: View {
    public var devices: [DeviceType]
    
    @State var searchText = ""
    private let searchableDevices: [SearchableDeviceEntry]
    
    private let destination: (DeviceType) -> Destination
    public init(devices: [any DeviceType], @ViewBuilder destination: @escaping (DeviceType) -> Destination) {
        self.devices = devices
        searchableDevices = devices.map(SearchableDeviceEntry.init(device:))
        self.destination = destination
    }
    
    // TODO: extract this out into KuditFrameworks as a way to section content with a callback for determining the header to group under.
    var sectioned: [(String,[DeviceType])] {
        var sections = [(String,[DeviceType])]()
        var lastIdiom: Device.Idiom?
        var sectionDevices = [DeviceType]()
        let normalizedSearch = searchText.asSearchTerm
        let searchWords = normalizedSearch.components(separatedBy: " ").filter { !$0.isEmpty }
        for entry in searchableDevices {
            let device = entry.device
            if device.idiom != lastIdiom {
                if let lastIdiom, sectionDevices.count > 0 {
                    sections.append((lastIdiom.label, sectionDevices))
                    sectionDevices = []
                }
                lastIdiom = device.idiom
            }
            var show = true
            if searchWords.count > 1 {
                show = entry.terms.containsAll(searchWords)
            } else if let word = searchWords.first {
                show = entry.joinedTerms.contains(word)
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

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension DeviceListView where Destination == DeviceDetailView {
    init(devices: [any DeviceType]) {
        self.init(devices: devices) { device in
            DeviceDetailView(device: device)
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("All Devices") {
    NavigationView {
		DeviceListView(devices: Device.all)
    }
}
#endif
