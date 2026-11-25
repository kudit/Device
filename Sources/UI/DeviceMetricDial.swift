#if canImport(SwiftUI)
import SwiftUI

/// Compact, reusable live metric gauge for device and display diagnostics.
/// The optional value keeps the same footprint while a sensor is unavailable.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
struct DeviceMetricDial: View {
	let value: Double?
	let maximum: Double
	let symbol: String
	let label: String
	let valueSuffix: String
	let diameter: CGFloat
	let valueInside: Bool

	private var progress: Double {
		guard let value, maximum > 0 else { return 0 }
		return min(max(value / maximum, 0), 1)
	}
	private var valueText: String {
		guard let value else { return "—" }
		return "\(Int(value.rounded()))\(valueSuffix)"
	}

	var body: some View {
		VStack(spacing: 2) {
			ZStack {
				Circle().stroke(Color.secondary.opacity(0.18), lineWidth: max(2, diameter * 0.075))
				Circle().trim(from: 0, to: progress)
					.stroke(Color.accentColor, style: StrokeStyle(lineWidth: max(2, diameter * 0.075), lineCap: .round))
					.rotationEffect(.degrees(-90))
				VStack(spacing: 0) {
					Image(symbolName: symbol).font(.system(size: diameter * (valueInside ? 0.24 : 0.36)))
					if valueInside { Text(valueText).font(.system(size: diameter * 0.20, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.65) }
				}
			}
			.frame(width: diameter, height: diameter)
			Text(valueInside ? label : valueText).font(.system(size: max(8, diameter * 0.20), weight: .medium)).lineLimit(1).minimumScaleFactor(0.7)
				.backport.accessibilityLabel("\(label), \(valueText)")
		}
		.backport.animation(.easeInOut(duration: 0.2), value: progress)
	}
}
#endif
