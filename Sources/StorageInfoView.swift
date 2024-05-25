//
//  SwiftUIView.swift
//  
//
//  Created by Ben Ku on 4/16/24.
//

#if canImport(SwiftUI)
import SwiftUI

public struct BytesView: View {
    public var label: String
    public var bytes: (any BinaryInteger)?
    public var countStyle: ByteCountFormatter.CountStyle
    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(label).opacity(0.5) // debugging: "label (\(String(describing: bytes))"
            Spacer()
            if let capacity = bytes {
                let parts = capacity.byteParts(countStyle)
                Text(parts.count).font(.headline)
                Text(parts.units).opacity(0.5)
            }
        }
    }
}

//#Preview("Bytes View") {
//    BytesView(label: "Test", bytes: 1_000_000, countStyle: .memory)
//}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
public struct StorageInfoView: View {
    public var device: any CurrentDevice
    public var body: some View {
        VStack {
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                // Fallback on earlier versions
                Image(symbolName: "internaldrive.fill")
                Text(" Storage").font(.headline)
                Spacer()
            }
            // Storage
            BytesView(label: "Volume Total Capacity:", bytes: device.volumeTotalCapacity, countStyle: .file)
            VStack {
                BytesView(label: "Volume Available Capacity for Important Resources:", bytes: device.volumeAvailableCapacityForImportantUsage, countStyle: .file)
                VStack {
                    BytesView(label: "Volume Available Capacity for Opportunistic Resources:", bytes: device.volumeAvailableCapacityForOpportunisticUsage, countStyle: .file)
                    VStack {
                        BytesView(label: "Volume Available Capacity:", bytes: device.volumeAvailableCapacity, countStyle: .file)
                    }
                    .padding()
                    .background { RoundedRectangle(cornerRadius: 10).fill(.gray) }
                }
                .padding()
                .background { RoundedRectangle(cornerRadius: 10).fill(.green) }
            }
            .padding()
            .background { RoundedRectangle(cornerRadius: 10).fill(.yellow) }
        }
        .font(.caption)
        .padding()
        .foregroundStyle(.black)
        .background {
            RoundedRectangle(cornerRadius: 15)
                .fill(.red)
        }
    }
}

@available(watchOS 8.0, tvOS 15.0, macOS 12.0, *)
#Preview("Storage Info") {
    StorageInfoView(device: Device.current)
}
#endif
