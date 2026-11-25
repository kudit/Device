//
//  Backport.ObservableObject.swift
//  Device
//

import Compatibility

#if canImport(Combine)
import Combine
#endif

/// Adds manually-managed, deployment-safe change publication to a reference type.
///
/// `ObservableObject` and `ObservableObjectPublisher` are only available on newer OS
/// releases. A class that must remain usable on older releases can adopt this protocol
/// without putting Combine types in its stored layout. Store the publisher as `AnyObject?`
/// and use `objectWillChangeBackport()` (or `observeChange(_:_:)`) when state changes.
///
/// This protocol does not itself make a type conform to Combine's `ObservableObject`.
/// Add that conformance in an availability-annotated extension for each concrete class
/// that should be observed on supported OS versions. Swift cannot conditionally add that
/// conformance to every type adopting this protocol while leaving those types available
/// on older deployment targets.
///
/// A typical implementation uses this protocol for stored state and adds the standard
/// conformance separately:
///
///     final class Settings: ObservableObjectBackport {
///         var _objectWillChange: AnyObject?
///         private var _enabled = false
///         var enabled: Bool {
///             get { _enabled }
///             set { observeChange(&_enabled, newValue) }
///         }
///     }
///
///     @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
///     extension Settings: ObservableObject {}
///
/// The concrete class can then be used on older OS versions without Combine observation,
/// while newer-platform clients can observe it through the native `ObservableObject` API.
@MainActor
public protocol ObservableObjectBackport: AnyObject {
	/// Erased storage for a lazily-created `ObservableObjectPublisher`.
	///
	/// Keep this storage optional and type-erased: the publisher type itself is unavailable
	/// on the oldest supported OS versions, even though the adopting class must still compile
	/// and load there. Do not read or assign this property directly except when implementing
	/// custom storage; use `backportObjectWillChange` to get the stable publisher on Combine
	/// platforms.
	var _objectWillChange: AnyObject? { get set }
}

public extension ObservableObjectBackport {
	/// Sends the standard `objectWillChange` publisher when Combine observation is available.
	///
	/// On older OS versions this deliberately does nothing; callers can still mutate their
	/// state and use the non-Combine API. On modern systems the notification is sent before
	/// the caller stores the new value, matching `@Published`'s change ordering.
	nonisolated
	func objectWillChangeBackport() {
#if canImport(Combine)
		if #available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) {
			main {
				self.backportObjectWillChange.send()
			}
		}
#endif
	}

	/// Updates a stored value and sends `objectWillChange` first when it has changed.
	///
	/// Pass the backing storage as `inout`; this keeps a computed setter short and makes
	/// the change comparison, notification, and assignment one operation:
	///
	///     set { observeChange(&_currentLevel, newValue) }
	///
	/// This is a notification convenience, not a replacement for `@Published`: it does not
	/// create a `$property` publisher or retain the property's old/new values. It is suitable
	/// for simple value state whose changes are reported through `objectWillChange`; use
	/// `@Published` when consumers need a publisher for the property's own values.
	func observeChange<Value: Equatable>(_ internalValue: inout Value, _ newValue: Value) {
		guard newValue != internalValue else { return }
		objectWillChangeBackport()
		internalValue = newValue
	}
}

#if canImport(Combine)
public extension ObservableObjectBackport {
	/// A stable cached publisher for implementing `ObservableObject.objectWillChange`.
	///
	/// Use this as the implementation of the public `objectWillChange` property on a class
	/// that adopts both protocols. The distinct name avoids ambiguity with Combine's own
	/// default `objectWillChange` implementation. The publisher is created on first access
	/// and retained in `_objectWillChange`, so repeated reads always return the same instance.
	@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
	var backportObjectWillChange: ObservableObjectPublisher {
		if let publisher = _objectWillChange as? ObservableObjectPublisher { return publisher }
		let publisher = ObservableObjectPublisher()
		_objectWillChange = publisher
		return publisher
	}
}
#endif
