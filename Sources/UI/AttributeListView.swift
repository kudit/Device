//
//  AttributeListView.swift
//  Device
//
//  Created by Ben Ku on 10/7/24.
//

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
import Compatibility

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct AttributeTestView: View {
    let attribute: any DeviceAttributeExpressible
    let device: DeviceType
    public init(attribute: any DeviceAttributeExpressible, device: DeviceType) {
        self.attribute = attribute
        self.device = device
    }
    public var body: some View {
		let supported = isSupported
		let label = displayLabel
		let symbolName = displaySymbolName
		let row = HStack {
			Image(symbolName: symbolName)
			Text(label)
		}
			.foregroundColor(supported ? .background : .primary)
			.font(.headline)
			.backport.help(label)
			.backport.accessibilityLabel(label)
			.backport.accessibilityIdentifier(accessibilityIdentifier)
		if supported {
			row.listRowBackground(attribute.color)
		} else {
			row
		}
    }

	/// Associated capabilities need value-aware status instead of exact enum equality.
	private var isSupported: Bool {
		guard let capability = attribute as? Capability else { return attribute.test(device: device) }
		switch capability {
		case .biometrics(let biometric):
			return biometric != .none && device.capabilities.contains(capability)
		case .pencils(let pencils):
			return !pencils.isDisjoint(with: device.capabilities.pencils)
		default:
			return attribute.test(device: device)
		}
	}

	/// Names each biometric technology separately and lists concrete Pencil models.
	private var displayLabel: String {
		guard let capability = attribute as? Capability else { return attribute.label }
		switch capability {
		case .biometrics(let biometric):
			return biometric.label
		case .pencils(let pencils): return pencils.sorted.map(\.name).joined(separator: ", ")
		default: return attribute.label
		}
	}

	private var accessibilityIdentifier: String {
		"device-attribute.\(attribute.id)"
	}

	private var displaySymbolName: SFSymbol {
		guard let capability = attribute as? Capability,
			case .biometrics(let biometric) = capability else {
			return attribute.symbolName
		}
			return biometric.symbolName
	}

}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
public struct AttributeListView<T: DeviceAttributeExpressible, Content: View>: View {
    let device: DeviceType
    let header: String
    let attributes: [T]
    var content: (T) -> Content
    public init(device: DeviceType? = nil, header: String, attributes: [T], @ViewBuilder content: @escaping (T) -> Content) {
        self.device = device ?? Device.current
        self.header = header
        self.attributes = attributes
        self.content = content
    }
    public var body: some View {
        Section {
			ForEach(attributes, id: \.id) { attribute in
                content(attribute)
            }
        } header: {
            Text(header)
        }
    }
}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension AttributeListView where Content == AttributeTestView {
    init(device: DeviceType, header: String, attributes: [T]) {
        self.init(device: device, header: header, attributes: attributes) { attribute in
            AttributeTestView(attribute: attribute, device: device)
        }
    }
}

#if swift(>=5.9)
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview {
    List {
        AttributeListView(device: Device(identifier: "iPhone17,2"), header: "Capabilities", attributes: Capability.allCases) {
            attribute in
			Backport.Label(title: {
                Text(attribute.caseName)
            }, icon: {
                Image(symbolName: attribute.symbolName)
            })
        }
    }
}
#endif

#endif
