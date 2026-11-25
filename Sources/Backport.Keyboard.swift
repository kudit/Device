#if canImport(Foundation)
import Foundation
import Compatibility

/// Portable key equivalent with the native spelling and literal syntax.
public struct BackportKeyEquivalent: Hashable, Sendable, ExpressibleByExtendedGraphemeClusterLiteral {
	public var character: Character
	public init(_ character: Character) { self.character = character }
	public init(extendedGraphemeClusterLiteral value: Character) { character = value }
	public static let upArrow: Self = "\u{f700}", downArrow: Self = "\u{f701}", leftArrow: Self = "\u{f702}", rightArrow: Self = "\u{f703}"
	public static let escape: Self = "\u{1b}", delete: Self = "\u{8}", deleteForward: Self = "\u{f728}"
	public static let home: Self = "\u{f729}", end: Self = "\u{f72b}", pageUp: Self = "\u{f72c}", pageDown: Self = "\u{f72d}"
	public static let clear: Self = "\u{f739}", tab: Self = "\t", space: Self = " ", `return`: Self = "\r"
}
public struct BackportEventModifiers: OptionSet, Hashable, Sendable {
	public let rawValue: Int
	public init(rawValue: Int) { self.rawValue = rawValue }
	public static let capsLock = Self(rawValue: 1), shift = Self(rawValue: 2), control = Self(rawValue: 4), option = Self(rawValue: 8), command = Self(rawValue: 16), numericPad = Self(rawValue: 32)
	public static let all: Self = [.capsLock, .shift, .control, .option, .command, .numericPad]
}
public struct BackportKeyboardShortcut: Sendable {
	public enum Localization: Sendable { case automatic, withoutMirroring, custom }
	public var key: BackportKeyEquivalent
	public var modifiers: BackportEventModifiers
	public var localization: Localization
	public init(_ key: BackportKeyEquivalent, modifiers: BackportEventModifiers = .command, localization: Localization = .automatic) { self.key = key; self.modifiers = modifiers; self.localization = localization }
	public static let defaultAction = Self(.return, modifiers: [])
	public static let cancelAction = Self(.escape, modifiers: [])
}
public struct BackportKeyPress: Sendable {
	public struct Phases: OptionSet, Sendable {
		public let rawValue: Int
		public init(rawValue: Int) { self.rawValue = rawValue }
		public static let down = Self(rawValue: 1), `repeat` = Self(rawValue: 2), up = Self(rawValue: 4)
		public static let all: Self = [.down, .repeat, .up]
	}
	public enum Result: Sendable { case handled, ignored }
	public let phase: Phases
	public let key: BackportKeyEquivalent
	public let characters: String
	public let modifiers: BackportEventModifiers
	public init(phase: Phases, key: BackportKeyEquivalent, characters: String, modifiers: BackportEventModifiers) { self.phase = phase; self.key = key; self.characters = characters; self.modifiers = modifiers }
}
#if canImport(SwiftUI) && compiler(>=5.9)
import SwiftUI
// Compatibility only defines its generic Backport wrapper when SwiftUI is available.
public extension Backport where Content == Any {
	typealias KeyEquivalent = BackportKeyEquivalent
	typealias EventModifiers = BackportEventModifiers
	typealias KeyboardShortcut = BackportKeyboardShortcut
	typealias KeyPress = BackportKeyPress
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct LegacyKeyFocus: EnvironmentKey { static let defaultValue = false }
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private extension EnvironmentValues {
	var legacyKeyFocus: Bool { get { self[LegacyKeyFocus.self] } set { self[LegacyKeyFocus.self] = newValue } }
}
#if !os(watchOS)
@available(iOS 14, macOS 11, tvOS 17, *)
private extension BackportKeyEquivalent {
	var native: SwiftUI.KeyEquivalent {
		switch self {
		case .upArrow: return .upArrow; case .downArrow: return .downArrow; case .leftArrow: return .leftArrow; case .rightArrow: return .rightArrow
		case .escape: return .escape; case .delete: return .delete; case .deleteForward: return .deleteForward
		case .home: return .home; case .end: return .end; case .pageUp: return .pageUp; case .pageDown: return .pageDown; case .clear: return .clear
		default: return SwiftUI.KeyEquivalent(character)
		}
	}
}
#endif
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private extension BackportEventModifiers {
	var native: SwiftUI.EventModifiers {
		var result: SwiftUI.EventModifiers = []
		if contains(.command) { result.insert(.command) }; if contains(.shift) { result.insert(.shift) }; if contains(.control) { result.insert(.control) }
		if contains(.option) { result.insert(.option) }; if contains(.capsLock) { result.insert(.capsLock) }; if contains(.numericPad) { result.insert(.numericPad) }
		return result
	}
	init(_ native: SwiftUI.EventModifiers) {
		self = []
		if native.contains(.command) { insert(.command) }; if native.contains(.shift) { insert(.shift) }; if native.contains(.control) { insert(.control) }
		if native.contains(.option) { insert(.option) }; if native.contains(.capsLock) { insert(.capsLock) }; if native.contains(.numericPad) { insert(.numericPad) }
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public extension Backport where Content: View {
	/// Explicit opt-in for the legacy responder. Never steals focus from editors by default.
	func keyInputFocused(_ focused: Bool) -> some View { content.environment(\.legacyKeyFocus, focused) }
	@ViewBuilder func keyboardShortcut(_ key: BackportKeyEquivalent, modifiers: BackportEventModifiers = .command, localization: BackportKeyboardShortcut.Localization = .automatic) -> some View {
		#if !os(tvOS) && !os(watchOS)
		// Establish the basic API first; only the enhanced overload needs the newer check.
		if #available(iOS 14, macOS 11, *) {
			if #available(iOS 15, macOS 12, *) {
				content.keyboardShortcut(key.native, modifiers: modifiers.native, localization: localization == .custom ? .custom : localization == .withoutMirroring ? .withoutMirroring : .automatic)
			} else { content.keyboardShortcut(key.native, modifiers: modifiers.native) }
		}
		else { content }
		#else
		content
		#endif
	}
	@ViewBuilder func keyboardShortcut(_ shortcut: BackportKeyboardShortcut?) -> some View {
		if let shortcut { keyboardShortcut(shortcut.key, modifiers: shortcut.modifiers, localization: shortcut.localization) } else { content }
	}
	func onKeyPress(_ key: BackportKeyEquivalent, action: @escaping () -> BackportKeyPress.Result) -> some View {
		onKeyPress(keys: [key]) { _ in action() }
	}
	func onKeyPress(_ key: BackportKeyEquivalent, phases: BackportKeyPress.Phases, action: @escaping (BackportKeyPress) -> BackportKeyPress.Result) -> some View { onKeyPress(keys: [key], phases: phases, action: action) }
	func onKeyPress(keys: Set<BackportKeyEquivalent>, phases: BackportKeyPress.Phases = [.down, .repeat], action: @escaping (BackportKeyPress) -> BackportKeyPress.Result) -> some View {
		onKeyPress(phases: phases) { keys.contains($0.key) ? action($0) : .ignored }
	}
	func onKeyPress(characters: CharacterSet, phases: BackportKeyPress.Phases = [.down, .repeat], action: @escaping (BackportKeyPress) -> BackportKeyPress.Result) -> some View {
		onKeyPress(phases: phases) { $0.characters.unicodeScalars.contains(where: characters.contains) ? action($0) : .ignored }
	}
	@ViewBuilder func onKeyPress(phases: BackportKeyPress.Phases = [.down, .repeat], action: @escaping (BackportKeyPress) -> BackportKeyPress.Result) -> some View {
		#if !os(watchOS)
		if #available(iOS 17, macOS 14, tvOS 17, *) {
			let requested: SwiftUI.KeyPress.Phases = [phases.contains(.down) ? .down : [], phases.contains(.repeat) ? .repeat : [], phases.contains(.up) ? .up : []]
			content.onKeyPress(phases: requested) { event in
				action(.init(phase: event.phase == .up ? .up : event.phase == .repeat ? .repeat : .down, key: .init(event.key.character), characters: event.characters, modifiers: .init(event.modifiers))) == .handled ? .handled : .ignored
			}
		} else { content.background(LegacyKeyboardResponder(phases: phases, action: action)) }
		#else
		content
		#endif
	}
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
@available(macOS 10.15, *)
private struct LegacyKeyboardResponder: NSViewRepresentable {
	@Environment(\.legacyKeyFocus) private var focused
	@Environment(\.isEnabled) private var enabled
	let phases: BackportKeyPress.Phases
	let action: (BackportKeyPress) -> BackportKeyPress.Result
	func makeNSView(context: Context) -> KeyView { KeyView() }
	func updateNSView(_ view: KeyView, context: Context) { view.action = action; view.phases = phases; view.wantsKeyFocus = focused && enabled; view.updateFocus() }
	static func dismantleNSView(_ view: KeyView, coordinator: ()) { if view.window?.firstResponder === view { view.window?.makeFirstResponder(nil) }; view.action = nil }
	final class KeyView: NSView {
		var action: ((BackportKeyPress) -> BackportKeyPress.Result)?
		var phases: BackportKeyPress.Phases = []
		var wantsKeyFocus = false
		private var requestedFocus = false
		override var acceptsFirstResponder: Bool { wantsKeyFocus }
		override func viewDidMoveToWindow() { super.viewDidMoveToWindow(); updateFocus() }
		func updateFocus() {
			guard window != nil else { requestedFocus = false; return }
			if wantsKeyFocus && !requestedFocus { window?.makeFirstResponder(self); requestedFocus = true }
			else if !wantsKeyFocus { if window?.firstResponder === self { window?.makeFirstResponder(nil) }; requestedFocus = false }
		}
		override func keyDown(with event: NSEvent) { if !handle(event, phase: event.isARepeat ? .repeat : .down) { super.keyDown(with: event) } }
		override func keyUp(with event: NSEvent) { if !handle(event, phase: .up) { super.keyUp(with: event) } }
		private func handle(_ event: NSEvent, phase: BackportKeyPress.Phases) -> Bool {
			guard wantsKeyFocus, window?.firstResponder === self, phases.contains(phase), let character = event.charactersIgnoringModifiers?.first else { return false }
			var modifiers: BackportEventModifiers = []
			if event.modifierFlags.contains(.command) { modifiers.insert(.command) }; if event.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
			if event.modifierFlags.contains(.control) { modifiers.insert(.control) }; if event.modifierFlags.contains(.option) { modifiers.insert(.option) }
			if event.modifierFlags.contains(.capsLock) { modifiers.insert(.capsLock) }; if event.modifierFlags.contains(.numericPad) { modifiers.insert(.numericPad) }
			return action?(.init(phase: phase, key: .init(character), characters: event.characters ?? "", modifiers: modifiers)) == .handled
		}
	}
}
#elseif canImport(UIKit) && !os(watchOS)
import UIKit
@available(iOS 13, tvOS 13, *)
private struct LegacyKeyboardResponder: UIViewRepresentable {
	@Environment(\.legacyKeyFocus) private var focused
	@Environment(\.isEnabled) private var enabled
	let phases: BackportKeyPress.Phases
	let action: (BackportKeyPress) -> BackportKeyPress.Result
	func makeUIView(context: Context) -> KeyView { KeyView() }
	func updateUIView(_ view: KeyView, context: Context) { view.action = action; view.phases = phases; view.wantsKeyFocus = focused && enabled; view.updateFocus() }
	static func dismantleUIView(_ view: KeyView, coordinator: ()) { _ = view.resignFirstResponder(); view.action = nil }
	final class KeyView: UIView {
		var action: ((BackportKeyPress) -> BackportKeyPress.Result)?
		var phases: BackportKeyPress.Phases = []
		var wantsKeyFocus = false
		private var requestedFocus = false
		override var canBecomeFirstResponder: Bool { wantsKeyFocus }
		override func didMoveToWindow() { super.didMoveToWindow(); updateFocus() }
		func updateFocus() {
			guard window != nil else { requestedFocus = false; return }
			if wantsKeyFocus && !requestedFocus { requestedFocus = becomeFirstResponder() }
			else if !wantsKeyFocus { if isFirstResponder { _ = resignFirstResponder() }; requestedFocus = false }
		}
		private var pressedKeys = Set<Int>()
		override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
			let unhandled = Set(presses.filter { !handle($0, phase: .down) })
			if !unhandled.isEmpty { super.pressesBegan(unhandled, with: event) }
		}
		override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
			let unhandled = Set(presses.filter { !handle($0, phase: .up) })
			if !unhandled.isEmpty { super.pressesEnded(unhandled, with: event) }
		}
		override func resignFirstResponder() -> Bool {
			let resigned = super.resignFirstResponder()
			if resigned { pressedKeys.removeAll() }
			return resigned
		}
		override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
			pressedKeys.removeAll(); super.pressesCancelled(presses, with: event)
		}
		private func handle(_ press: UIPress, phase: BackportKeyPress.Phases) -> Bool {
			if #available(iOS 13.4, tvOS 13.4, *) {
				guard let key = press.key, let character = key.charactersIgnoringModifiers.first else { return false }
				let code = key.keyCode.rawValue
				let actualPhase: BackportKeyPress.Phases = phase == .down && pressedKeys.contains(code) ? .repeat : phase
				if phase == .up { pressedKeys.remove(code) } else { pressedKeys.insert(code) }
				guard wantsKeyFocus, isFirstResponder, phases.contains(actualPhase) else { return false }
				var modifiers: BackportEventModifiers = []
				if key.modifierFlags.contains(.command) { modifiers.insert(.command) }; if key.modifierFlags.contains(.shift) { modifiers.insert(.shift) }
				if key.modifierFlags.contains(.control) { modifiers.insert(.control) }; if key.modifierFlags.contains(.alternate) { modifiers.insert(.option) }
				if key.modifierFlags.contains(.alphaShift) { modifiers.insert(.capsLock) }; if key.modifierFlags.contains(.numericPad) { modifiers.insert(.numericPad) }
				return action?(.init(phase: actualPhase, key: .init(character), characters: key.characters, modifiers: modifiers)) == .handled
			}
			return false
		}
	}
}
#else
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct LegacyKeyboardResponder: View {
	let phases: BackportKeyPress.Phases
	let action: (BackportKeyPress) -> BackportKeyPress.Result
	var body: some View { Color.clear }
}
#endif
#endif
#endif
