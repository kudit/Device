//
//  SwiftUIView.swift
//  
//
//  Created by Ben Ku on 4/21/24.
//

#if canImport(SwiftUI)
import SwiftUI

@available(iOS 14, macOS 12, tvOS 15, watchOS 8, *)
public struct EnvironmentsView: View {
    public init() {}
    public var body: some View {
        HStack {
            Spacer()
            ForEach(Device.Environment.allCases, id: \.self) { environment in
                let enabled = environment.test(device: Device.current)
                Image(environment)
                    .opacity(enabled ? 1.0 : 0.2)
                    .foregroundColor(enabled ? environment.color : .primary)
                    .accessibilityLabel((enabled ? "Is" : "Not") + " " + environment.label)
            }
            Spacer()
        }
    }
}

@available(iOS 14, macOS 12, tvOS 15, watchOS 8, *)
#Preview("Environments") {
    EnvironmentsView()
}
#endif
