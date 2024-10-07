//
//  AttributeListView.swift
//  Device
//
//  Created by Ben Ku on 10/7/24.
//

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14, macOS 12, tvOS 15, watchOS 8, *)
public struct AttributeTestView: View {
    @State var attribute: any DeviceAttributeExpressible
    @State var device: DeviceType
    public init(attribute: any DeviceAttributeExpressible, device: DeviceType) {
        self.attribute = attribute
        self.device = device
    }
    public var body: some View {
        let label = Label(attribute.label, symbolName: attribute.symbolName)
            .foregroundColor(.primary)
            .font(.headline)
        if attribute.test(device: device) {
            label
                .listRowBackground(attribute.color)
        } else {
            label
        }
    }
}

@available(iOS 14, macOS 12, tvOS 15, watchOS 8, *)
@MainActor
public struct AttributeListView<T: DeviceAttributeExpressible, Content: View>: View {
    @State var device: DeviceType
    @State var header: String
    @State var attributes: [T]
    var content: (T) -> Content
    public init(device: DeviceType? = nil, header: String, attributes: [T], @ViewBuilder content: @escaping (T) -> Content) {
        if let device {
            self.device = device
        } else {
            self.device = Device.current
        }
        self.header = header
        self.attributes = attributes
        self.content = content
    }
    public var body: some View {
        Section {
            ForEach(attributes, id: \.self) { attribute in
                content(attribute)
            }
        } header: {
            Text(header)
        }
    }
}
@available(iOS 14, macOS 12, tvOS 15, watchOS 8, *)
public extension AttributeListView where Content == AttributeTestView {
    init(device: DeviceType, header: String, attributes: [T]) {
        self.init(device: device, header: header, attributes: attributes) { attribute in
            AttributeTestView(attribute: attribute, device: device)
        }
    }
}

@available(iOS 14, macOS 12, tvOS 15, watchOS 8, *)
#Preview {
    List {
        AttributeListView(device: Device(identifier: "iPhone17,2"), header: "Capabilities", attributes: Capability.allCases)
    }
}

#endif
