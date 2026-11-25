import Compatibility

public enum BackportDigitalCrownRotationalSensitivity: Sendable { case low, medium, high }
public struct BackportDigitalCrownEvent: Sendable {
	public var offset: Double
	public var velocity: Double
	public init(offset: Double, velocity: Double) { self.offset = offset; self.velocity = velocity }
}
public enum BackportInputVisibility: Sendable { case automatic, visible, hidden }
#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI
public extension Backport where Content == Any {
	typealias DigitalCrownRotationalSensitivity = BackportDigitalCrownRotationalSensitivity
	typealias DigitalCrownEvent = BackportDigitalCrownEvent
	typealias InputVisibility = BackportInputVisibility
}

#if os(watchOS)
@available(watchOS 6, *)
private extension BackportDigitalCrownRotationalSensitivity {
	var native: SwiftUI.DigitalCrownRotationalSensitivity {
		switch self { case .low: return .low; case .medium: return .medium; case .high: return .high }
	}
}
#endif

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
	/// Binding-based rotation is real on watchOS 6+; other platforms produce no Crown events.
	@ViewBuilder
	func digitalCrownRotation<V>(_ binding: Binding<V>, from minValue: V, through maxValue: V, by stride: V.Stride? = nil,
		sensitivity: BackportDigitalCrownRotationalSensitivity = .high, isContinuous: Bool = false, isHapticFeedbackEnabled: Bool = true) -> some View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
		#if os(watchOS)
		content.digitalCrownRotation(binding, from: minValue, through: maxValue, by: stride, sensitivity: sensitivity.native, isContinuous: isContinuous, isHapticFeedbackEnabled: isHapticFeedbackEnabled)
		#else
		content
		#endif
	}
	@ViewBuilder
	func digitalCrownRotation<V>(_ binding: Binding<V>) -> some View where V: BinaryFloatingPoint {
		#if os(watchOS)
		content.digitalCrownRotation(binding)
		#else
		content
		#endif
	}
	/// watchOS 9 events are passed through. Older bindings work without fabricated velocity/idle events.
	@ViewBuilder
	func digitalCrownRotation<V>(_ binding: Binding<V>, from minValue: V, through maxValue: V,
		sensitivity: BackportDigitalCrownRotationalSensitivity = .high, isContinuous: Bool = false, isHapticFeedbackEnabled: Bool = true,
		onChange: @escaping (BackportDigitalCrownEvent) -> Void, onIdle: @escaping () -> Void = {}) -> some View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
		#if os(watchOS)
		if #available(watchOS 9, *) {
			content.digitalCrownRotation(binding, from: minValue, through: maxValue, sensitivity: sensitivity.native, isContinuous: isContinuous, isHapticFeedbackEnabled: isHapticFeedbackEnabled, onChange: { onChange(.init(offset: $0.offset, velocity: $0.velocity)) }, onIdle: onIdle)
		} else { digitalCrownRotation(binding, from: minValue, through: maxValue, sensitivity: sensitivity, isContinuous: isContinuous, isHapticFeedbackEnabled: isHapticFeedbackEnabled) }
		#else
		content
		#endif
	}
	@ViewBuilder
	func digitalCrownRotation<V>(_ binding: Binding<V>, onChange: @escaping (BackportDigitalCrownEvent) -> Void, onIdle: @escaping () -> Void = {}) -> some View where V: BinaryFloatingPoint {
		#if os(watchOS)
		if #available(watchOS 9, *) { content.digitalCrownRotation(binding, onChange: { onChange(.init(offset: $0.offset, velocity: $0.velocity)) }, onIdle: onIdle) }
		else { content.digitalCrownRotation(binding) }
		#else
		content
		#endif
	}
	@ViewBuilder
	func digitalCrownRotation<V>(detent binding: Binding<V>, from minValue: V, through maxValue: V, by stride: V.Stride,
		sensitivity: BackportDigitalCrownRotationalSensitivity = .high, isContinuous: Bool = false, isHapticFeedbackEnabled: Bool = true,
		onChange: @escaping (BackportDigitalCrownEvent) -> Void = { _ in }, onIdle: @escaping () -> Void = {}) -> some View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
		#if os(watchOS)
		if #available(watchOS 9, *) { content.digitalCrownRotation(detent: binding, from: minValue, through: maxValue, by: stride, sensitivity: sensitivity.native, isContinuous: isContinuous, isHapticFeedbackEnabled: isHapticFeedbackEnabled, onChange: { onChange(.init(offset: $0.offset, velocity: $0.velocity)) }, onIdle: onIdle) }
		else { digitalCrownRotation(binding, from: minValue, through: maxValue, by: stride, sensitivity: sensitivity, isContinuous: isContinuous, isHapticFeedbackEnabled: isHapticFeedbackEnabled) }
		#else
		content
		#endif
	}
	@ViewBuilder
	func digitalCrownRotation<V>(detent binding: Binding<V>, from minValue: V, through maxValue: V, by stride: V.Stride,
		sensitivity: BackportDigitalCrownRotationalSensitivity = .high, isContinuous: Bool = false, isHapticFeedbackEnabled: Bool = true,
		onChange: @escaping (BackportDigitalCrownEvent) -> Void = { _ in }, onIdle: @escaping () -> Void = {}) -> some View where V: BinaryInteger, V.Stride: BinaryInteger {
		#if os(watchOS)
		if #available(watchOS 9, *) { content.digitalCrownRotation(detent: binding, from: minValue, through: maxValue, by: stride, sensitivity: sensitivity.native, isContinuous: isContinuous, isHapticFeedbackEnabled: isHapticFeedbackEnabled, onChange: { onChange(.init(offset: $0.offset, velocity: $0.velocity)) }, onIdle: onIdle) }
		else { content.digitalCrownRotation(Binding<Double>(get: { Double(binding.wrappedValue) }, set: { binding.wrappedValue = V($0.rounded()) }), from: Double(minValue), through: Double(maxValue), by: Double(stride), sensitivity: sensitivity.native, isContinuous: isContinuous, isHapticFeedbackEnabled: isHapticFeedbackEnabled) }
		#else
		content
		#endif
	}
	@ViewBuilder
	func digitalCrownAccessory<V: View>(@ViewBuilder content accessory: @escaping () -> V) -> some View {
		#if os(watchOS)
		if #available(watchOS 9, *) { content.digitalCrownAccessory(content: accessory) } else { content }
		#else
		content
		#endif
	}
	@ViewBuilder
	func digitalCrownAccessory(_ visibility: BackportInputVisibility) -> some View {
		#if os(watchOS)
		if #available(watchOS 9, *) { content.digitalCrownAccessory(visibility == .visible ? .visible : visibility == .hidden ? .hidden : .automatic) } else { content }
		#else
		content
		#endif
	}
}
#endif
