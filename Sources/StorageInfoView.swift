//
//  SwiftUIView.swift
//  
//
//  Created by Ben Ku on 4/16/24.
//

#if canImport(SwiftUI)
import SwiftUI

public extension EdgeInsets {
    static var zero = Self.init(top: 0, leading: 0, bottom: 0, trailing: 0)
}

struct BytesView: View {
    public var label: String?
    var bytes: (any BinaryInteger)?
    var font: Font? = .headline
    var countStyle: ByteCountFormatter.CountStyle? = .file
    var round = false
    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 3) {
            if let label {
                Text(label).opacity(0.5) // debugging: "label (\(String(describing: bytes))"
                Spacer()
            }
            if let capacity = bytes {
                let parts = capacity.byteParts(countStyle ?? .file)
                let number = round ? "\(Int(Double(parts.count) ?? -1))" : "\(parts.count)"
                Text(number).font(font)
                if countStyle != nil {
                    Text(parts.units).opacity(0.5)
                }
            }
        }
    }
}

#Preview("Bytes View") {
    BytesView(label: "Test", bytes: 1_000_000, font: .title, countStyle: .memory)
        .padding()
}

struct StorageBytesView: View {
    var label: String?
    var bytes: (any BinaryInteger)?
    var countStyle: ByteCountFormatter.CountStyle? = .file
    var round = false
    var visible = true
    var body: some View {
        if visible {
            BytesView(label: label, bytes: bytes, countStyle: countStyle, round: round)
        } else {
            EmptyView()
        }
    }
}

private struct ViewWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    // TODO: Check that this actually works.  If we rotate, the width will need to grow or shrink.
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
public struct StorageInfoView<SomeCurrentDevice: CurrentDevice>: View {
    @ObservedObject public var device: SomeCurrentDevice
    @State var includeDebugInformation: Bool
    public init(device: SomeCurrentDevice, includeDebugInformation: Bool = false) {
        self.device = device
        self.includeDebugInformation = includeDebugInformation
    }
    
    @State private var width: CGFloat = 0
    
    func width(for capacity: Int64) -> CGFloat {
        let denominator = Double(device.volumeTotalCapacity ?? 1024)
        let percent = Double(capacity) / denominator
        return (1 - percent) * width
    }
    
    @ViewBuilder
    var storageHeader: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Image(symbolName: "internaldrive.fill")
            Text(" Storage").font(.headline)
        }
        .padding()
    }
    
    func backgroundView(color: Color, width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .frame(width: width)
        }
    }
    
    /// Invert the capacity to get the value left on the drive
    func inverted(_ capacity: Int64, _ inverted: Bool) -> Int64 {
        inverted ? (device.volumeTotalCapacity ?? 1024 * 1024 * 1024) - capacity : capacity
    }
    
    @ViewBuilder
    func capacityBar(label: String, bytes capacity: Int64?, inverted: Bool = false, color: Color, @ViewBuilder containedContent: @escaping () -> some View) -> some View {
        if let capacity {
            VStack(spacing: 0) {
                containedContent()
                    .background {
                        backgroundView(color: color, width: width(for: capacity))
                    }
                StorageBytesView(label: label, bytes: self.inverted(capacity, inverted), visible: includeDebugInformation)
                    .padding()
            }
        } else {
            containedContent()
        }
    }
    
    public var body: some View {
        capacityBar(label: "Volume Available Capacity:", bytes: device.volumeAvailableCapacity, color: .green) {
            capacityBar(label: "Available for Opportunistic:", bytes: device.volumeAvailableCapacityForOpportunisticUsage, color: .yellow) {
                capacityBar(label: "Available for Important:", bytes: device.volumeAvailableCapacityForImportantUsage, color: .red) {
                    capacityBar(label: "Used Capacity:", bytes: device.volumeAvailableCapacityForImportantUsage, inverted: true, color: .clear) {
                        HStack(spacing: 0) {
                            storageHeader
                            Spacer()
                            HStack(spacing: 0) {
                                if includeDebugInformation {
                                    StorageBytesView(label: "Total Capacity:", bytes: device.volumeTotalCapacity, visible: true)
                                } else {
                                    BytesView(bytes: device.volumeAvailableCapacity, countStyle: nil, round: true)
                                    Text(" / ").font(.headline)
                                    StorageBytesView(bytes: device.volumeTotalCapacity, round: true)
                                }
                            }.padding()
                        }
                    }
                }
            }
        }
        .background {
            backgroundView(color: .gray, width: width(for: 0))
        }
        .font(.caption)
        .foregroundStyle(.black)
        .overlay(GeometryReader { proxy in
            Color.clear.preference(
                key: ViewWidthPreferenceKey.self,
                value: proxy.size.width
            )
        })
        .onPreferenceChange(ViewWidthPreferenceKey.self) { width in
            self.width = width
        }
        .onTapGesture {
            withAnimation {
                includeDebugInformation.toggle()
            }
        }
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("Storage Info") {
    VStack {
        Spacer().frame(height: 100)
        StorageInfoView(device: Device.current)
        StorageInfoView(device: Device.current, includeDebugInformation: true)
        ForEach(MockDevice.mocks) { mock in
            StorageInfoView(device: mock)
        }
        Spacer()
    }
    .padding()
}
#endif
