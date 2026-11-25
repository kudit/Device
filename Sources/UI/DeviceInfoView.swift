//
//  DeviceInfoView.swift
//  DeviceTest
//
//  Created by Ben Ku on 3/29/24.
//

#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
import Foundation
import Color

public extension CGFloat {
    static let devicePanelRadius: Double = 15
}

/// A reusable shape-like symbol treatment that adds a thin contrast edge while
/// leaving the symbol's interior rendered by its original foreground style.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct OutlinedDeviceSymbol: View {
	let symbol: SymbolRepresentable
    let color: AppleMaterialColor

    public init(symbol: SymbolRepresentable, color: AppleMaterialColor) {
        self.symbol = symbol
        self.color = color
    }

    public var foreground: some View {
        Image(symbolName: symbol.mainActorSymbolName)
            .closure { view in
                if symbol.mainActorSymbolName == "macbook.gen3",
                   #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
                    // The MacBook Gen 3 display is the secondary layer; retain
                    // the device's swatch on the outline while keeping the
                    // screen fill visibly secondary.
                    view.symbolRenderingMode(.hierarchical)
                        .foregroundStyle(color.leftToRightGradient, .secondary)
                } else if #available(iOS 15, macOS 14, tvOS 17, watchOS 10, *) {
                    view.foregroundStyle(color.leftToRightGradient)
                } else if color.swatches.count > 1 {
                    // Gradient foreground styles are newer, but LinearGradient
                    // and mask are available on this view's deployment baseline.
                    // This keeps every tone visible instead of reducing a
                    // multi-tone swatch to its first color on older systems.
                    view.overlay(color.leftToRightGradient).mask(Image(symbolName: symbol.mainActorSymbolName))
                } else { //if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) { // Why can't we check for iOS 14?????  Maybe because this is supported on everything < iOS 15 so no need to check?
                    view.foregroundColor(color.legacyColor)
                    //                } else {
                    //                    // Symbol names are available as text on the oldest supported
                    //                    // SwiftUI versions, so use the complete name for the fallback.
                    //                    Image(symbolName: symbol.mainActorSymbolName)
                }
            }
    }

	public var body: some View {
		foreground.font(.system(size: 18))
	}
}

/// Renders capability symbols, optionally centering the wrapped content.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
public func CapabilitiesTextView(capabilities: Capabilities, centered: Bool = false) -> some View {
	let visibleCapabilities = capabilities.sorted.filter { capability in
			// don't show screen icon since not really helpful
			if case .screens = capability { return false }
			// don't show mac form either since redundant
			else if case .macForm = capability { return false }
			// and cellular doesn't really make sense either unless we want to indicate the type
			else if case .cellular = capability { return false }
			// and cameras don't really make sense either
			else if case .cameras = capability { return false }
			// and we don't really want to flag battery here
			else if case .battery = capability { return false }
			// and watches don't need watch size here
			else if case .watchSize = capability { return false }
			return true
	}
	// Inline images in Text use the platform's line-breaking engine, so this
	// wraps naturally and grows vertically without measuring geometry or fixing
	// the number of rows in advance.
	let content = visibleCapabilities.reduce(Text("")) { result, capability in
		if #available(iOS 14, macOS 11, tvOS 14, watchOS 7, *) {
			return result + Text(Image(symbolName: capability.symbolName)) + Text(" ")
		} else {
			return result + Text("\(capability.label) ")
		}
	}
	let textAlignment: TextAlignment = centered ? .center : .leading
	let frameAlignment: Alignment = centered ? .center : .leading
	return content
		.font(.system(size: 12))
		.backport.foregroundStyle(.secondary)
		.backport.accessibilityLabel(visibleCapabilities.map(\.label).joined(separator: ", "))
		.multilineTextAlignment(textAlignment)
		.fixedSize(horizontal: false, vertical: true)
		.frame(maxWidth: .infinity, alignment: frameAlignment)
		.padding(.vertical, 2)
}

/// Technincally a function but present like a View struct.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
/// Displays one symbol per material color without forcing styled views back
/// into `Text`; gradient foreground styles are views, so an HStack preserves
/// SwiftUI's type system and keeps each symbol independently styled.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct ColorSymbolsView: View {
    let symbol: SymbolRepresentable
    let colors: [AppleMaterialColor]

    public init(symbol: SymbolRepresentable, colors: [AppleMaterialColor]) {
        self.symbol = symbol
        self.colors = colors
    }

    public var body: some View {
        // Leave clear separation between adjacent colored device glyphs; their
        // transparent image bounds can otherwise overlap even at zero spacing.
        HStack(spacing: 4) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                OutlinedDeviceSymbol(symbol: symbol, color: color)
            }
        }
		.shadow(color: .gray, radius: 0.5)
		.fixedSize(horizontal: true, vertical: false)
		.frame(maxWidth: .infinity, alignment: .leading)
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
@MainActor
public struct DeviceInfoView: View {
    public var device: DeviceType

    var includeScreen: Bool
    var includeAttributes: Bool

	/// allCases includes each biometric subtype; Pencil is value-associated
	/// and therefore gets one additional row for the device's supported models.
	fileprivate static let capabilityRows: [Capability] = {
		var seen = Set<Capability>()
		let pencilRows = ApplePencil.allCases.map { Capability.pencils([$0]) }
		return (Capability.allCases + pencilRows).filter { seen.insert($0).inserted }
	}()

    public init(device: any DeviceType, includeScreen: Bool = false, includeAttributes: Bool = false) {
        self.device = device
        self.includeScreen = includeScreen
        self.includeAttributes = includeAttributes
    }

    public var body: some View {
        // Keep the complete device summary in one root container.  SwiftUI's
        // result builder otherwise exposes each conditional below as a sibling
        // row when this view is used as a List/DisclosureGroup label, which
        // produced the three empty rows visible beneath every collapsed device.
        VStack(alignment: .leading, spacing: 0) {
			HStack(alignment: .top, spacing: 10) {
				VStack(alignment: .leading, spacing: 8) {
                    Text(device.officialName)
                        .font(.headline)
					ColorSymbolsView(symbol: device.idiomatic, colors: device.colors)
						.backport.accessibilityLabel(device.colors.map(\.name).joined(separator: ", "))
					CapabilitiesTextView(capabilities: device.capabilities)
				}
				.frame(maxWidth: .infinity, alignment: .leading)
				.layoutPriority(0)
				VStack(alignment: .trailing, spacing: 4) {
					Text(device.supportedOSInfo)
						.font(.caption)
						.foregroundColor(.gray)
						.multilineTextAlignment(.trailing)
						.frame(maxWidth: 120, alignment: .trailing)
						.fixedSize(horizontal: false, vertical: true)
					HStack {
						Text("\(device.cpu.caseName) ").font(.footnote.smallCaps())
						Image(symbolName: "cpu".safe)
							.font(.footnote)
						if let year = device.introductionYear {
							Text(String(year))
								.font(.footnote.smallCaps())
								.padding(.init(top: 0, leading: 4, bottom: 1, trailing: 3))
								.backport.foregroundStyle(.background)
								.backport.background(.gray)
								.clipShape(RoundedRectangle(cornerRadius: 5))
						}
					}
				}
				.fixedSize(horizontal: true, vertical: false)
				.layoutPriority(1)
				if let image = device.image {
                    Group {
                        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
                            SwiftUI.AsyncImage(url: URL(string: image)) { phase in
                                if let loadedImage = phase.image {
                                    loadedImage.resizable().aspectRatio(contentMode: .fit)
                                } else if phase.error != nil {
                                    EmptyView()
                                } else {
                                    ProgressView()
                                }
                            }
                            .frame(width: 48, height: 48)
                        } else {
                            Backport<Any>.AsyncImage(url: URL(string: image))
                                .frame(width: 48, height: 48)
                        }
                    }
					.clipped()
                }
            }
            // TODO: Figure out how to speed this up.
            if includeScreen {
                HStack {
                    Spacer()
					Backport.Link(device.identifiers.joined(separator: ", "), destination: device.supportURL)
                    //          Text(device.identifiers.joined(separator: ", "))
                        .font(.caption)
                        .backport.textSelection(.enabled)
                    Spacer()
                }
                if device.models.count > 0 {
                    HStack {
                        Spacer()
                        Text(device.models.joined(separator: ", "))
                            .font(.caption)
                            .backport.textSelection(.enabled)
                        Spacer()
                    }
                }
            }
            if !device.screens.isEmpty && includeScreen {
                if device is ActualHardwareDevice { ScreenInfoView() }
				else { ScreenInfoView(device: device) }
            }
        if includeAttributes {
            AttributeListView(device: device, header: "Capabilities", attributes: Self.capabilityRows)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        }
        // The demo's List selection can provide a white foreground inherited
        // from the selected row; keep the device summary readable while still
        // allowing explicitly colored capability and icon views to override it.
		.backport.foregroundStyle(.primary)
    }

}

#if swift(>=5.9)
// Focused previews exercise the hard-stop renderer with the swatch counts that
// are easiest to regress when changing gradient construction or ordering.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("AppleMaterialColor swatches") {
    VStack(alignment: .leading, spacing: 12) {
		ColorSymbolsView(symbol: Mac.Form.iMac, colors: .iMac2024)
            .font(.system(size: 48))
		ColorSymbolsView(symbol: Device.Idiom.phone, colors: .iPhone5c)
            .font(.system(size: 48))
		ColorSymbolsView(symbol: Device.Idiom.watch, colors: .watch12)
            .font(.system(size: 48))
    }
    .padding()
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("DeviceInfoView") {
    List {
        DeviceInfoView(device: Device(identifier: "AudioAccessory5,1"))
    }
}
#endif

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct DeviceDetailView: View {
    var device: DeviceType
    public init(device: DeviceType) {
        self.device = device
    }
    public var body: some View {
        List {
            DeviceInfoView(device: device, includeScreen: true)
            AttributeListView(device: device, header: "Capabilities", attributes: DeviceInfoView.capabilityRows)
        }
        .navigationWrapper()
    }
}

#if swift(>=5.9)
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("DeviceDetailView") {
    DeviceDetailView(device: Device.current)
}
#endif
#endif
