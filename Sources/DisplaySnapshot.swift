import Foundation

/// A size in an explicitly documented coordinate space; never implicitly panel pixels.

public struct DisplaySize: Hashable, Codable, Sendable {
	public let width: Double
	public let height: Double
	public init(width: Double, height: Double) { self.width = width; self.height = height }
	public static let zero = Self(width: 0, height: 0)
}

/// A rectangle whose coordinate convention survives capture and support export.

public struct DisplayRect: Hashable, Codable, Sendable {
	public enum Space: String, Codable, Sendable {
		case display, window, localView, rotatedContent, desktopBottomLeft, desktopTopLeft
	}
	public let x: Double
	public let y: Double
	public let size: DisplaySize
	public let space: Space
	public init(x: Double = 0, y: Double = 0, width: Double, height: Double, space: Space) {
		self.x = x; self.y = y; size = DisplaySize(width: width, height: height); self.space = space
	}
	/// Explicit AppKit-to-top-left desktop conversion, using the desktop's actual top edge.
	public func topLeftDesktop(desktopTop: Double) -> Self {
		guard space == .desktopBottomLeft else { return self }
		return Self(x: x, y: desktopTop - y - size.height, width: size.width, height: size.height, space: .desktopTopLeft)
	}
}

/// Insets in points in the presentation's local coordinate space.

public struct DisplayInsets: Hashable, Codable, Sendable {
	public let top: Double
	public let leading: Double
	public let bottom: Double
	public let trailing: Double
	public init(top: Double = 0, leading: Double = 0, bottom: Double = 0, trailing: Double = 0) {
		self.top = top; self.leading = leading; self.bottom = bottom; self.trailing = trailing
	}
	public static let zero = Self()
}

/// Fixed, immutable output measurements. IDs are process scoped, never persistent monitor IDs.
public struct DisplaySnapshot: Hashable, Codable, Sendable {
    // TODO: Can this be deleted?
	public struct Mode: Hashable, Codable, Sendable {
		/// Render target pixels, which may differ from the physical panel resolution.
		let pixels: DisplaySize
		let refreshRate: Double?
		init(pixels: DisplaySize, refreshRate: Double? = nil) { self.pixels = pixels; self.refreshRate = refreshRate }
	}
    public let id: String
    public let capturedAt: Date
    public let name: String?
    public let bounds: DisplayRect?
    public let scale: Double?
    public let nativePixels: DisplaySize?
    public let mode: Mode?
    public let mirroredDisplayID: String?
    public let maximumFramesPerSecond: Int?
    public let specification: Screen?
    public let brightness: Double?
    public init(
        id: String,
        capturedAt: Date = Date(),
        name: String? = nil,
        bounds: DisplayRect? = nil,
		scale: Double? = nil,
        nativePixels: DisplaySize? = nil,
        mode: Mode? = nil,
		mirroredDisplayID: String? = nil,
        maximumFramesPerSecond: Int? = nil,
		specification: Screen? = nil,
		brightness: Double? = nil) {
		self.id = id; self.capturedAt = capturedAt; self.name = name; self.bounds = bounds
		self.scale = scale; self.nativePixels = nativePixels; self.mode = mode
		self.mirroredDisplayID = mirroredDisplayID; self.maximumFramesPerSecond = maximumFramesPerSecond
		self.specification = specification; self.brightness = brightness
	}
	/// Excludes the capture timestamp so observers can coalesce unchanged measurements.
	func hasSameMeasurements(as other: Self) -> Bool {
		id == other.id && name == other.name && bounds == other.bounds && scale == other.scale
			&& nativePixels == other.nativePixels && mode == other.mode && mirroredDisplayID == other.mirroredDisplayID
			&& maximumFramesPerSecond == other.maximumFramesPerSecond && specification == other.specification
			&& brightness == other.brightness
	}
}

/// App window measurements, separate from the output it occupies and any local view geometry.
public struct PresentationSnapshot: Hashable, Codable, Sendable {
	public enum Activation: String, Codable, Sendable { case foregroundActive, foregroundInactive, background, unattached, unknown }
	public typealias Orientation = Device.LegacyOrientation
	public enum SizeClass: String, Codable, Sendable { case compact, regular, unspecified }
	/// Coarse placement of this app window within its output.
	public enum WindowPlacement: String, Codable, Sendable, CustomStringConvertible {
		case fullScreen, leftSide, rightSide, customSized, unknown
		public var symbolName: String {
			switch self {
			case .fullScreen: return "arrow.up.backward.and.arrow.down.forward.square"
			case .leftSide: return "rectangle.lefthalf.filled"
			case .rightSide: return "rectangle.righthalf.filled"
			case .customSized: return "square.resize"
			case .unknown: return "questionmark.square.dashed"
			}
		}
		public var description: String {
			switch self {
			case .fullScreen:
				"Full Screen"
			case .leftSide:
				"Left Half"
			case .rightSide:
				"Right Half"
			case .customSized:
				"Custom"
			case .unknown:
				"*Unknown*"
			}
		}
	}
	public struct ReservedRegion: Hashable, Codable, Sendable {
		public enum Kind: String, Codable, Sendable { case division, occlusion, unknown }
		public let id: String
		public let kind: Kind
		public let bounds: DisplayRect
		public init(id: String, kind: Kind, bounds: DisplayRect) { self.id = id; self.kind = kind; self.bounds = bounds }
	}
	public let id: String
	public let capturedAt: Date
	let display: DisplaySnapshot
	/// Identifier of the output hosting this presentation, scoped to the running process.
	public var displayID: String { display.id }
	/// Human-readable output name when the platform supplies one.
	public var displayName: String? { display.name }
	/// Fixed hardware specification when this output corresponds to a built-in panel.
	public var screen: Screen? { display.specification }
	public let windowBounds: DisplayRect?
	/// Position and extent on the associated output/desktop, separate from window-local bounds.
	public let windowFrame: DisplayRect?
	public let localBounds: DisplayRect?
	public let safeArea: DisplayInsets?
	public let activation: Activation
	public let interfaceOrientation: Orientation?
	public let horizontalSizeClass: SizeClass?
	public let verticalSizeClass: SizeClass?
	public let reservedRegions: [ReservedRegion]
	public let hinge: Device.Hinge?
	public var windowPlacement: WindowPlacement {
		if let fold = reservedRegions.first(where: { $0.kind == .division && $0.bounds.space == .localView })?.bounds,
		   let localBounds,
		   localBounds.size.width > 0, localBounds.size.height > 0 {
			if fold.size.height >= fold.size.width {
				let position = (fold.x + fold.size.width / 2) / localBounds.size.width
				if position > 0.75 { return .leftSide }
				if position < 0.25 { return .rightSide }
				return .fullScreen
			}
			// The Duo's horizontal division is a top/bottom arrangement, which
			// this left/right placement API does not attempt to label.
			return .customSized
		}
		guard let frame = windowFrame, let bounds = display.bounds else { return windowFrame == nil ? .unknown : .customSized }
		let tolerance = 8.0
		let fullWidth = abs(frame.size.width - bounds.size.width) <= tolerance
		let fullHeight = abs(frame.size.height - bounds.size.height) <= tolerance
		if fullWidth && fullHeight && abs(frame.x - bounds.x) <= tolerance && abs(frame.y - bounds.y) <= tolerance { return .fullScreen }
		return .customSized
	}
	init(id: String, capturedAt: Date = Date(), display: DisplaySnapshot, windowBounds: DisplayRect? = nil, windowFrame: DisplayRect? = nil,
		localBounds: DisplayRect? = nil, safeArea: DisplayInsets? = nil, activation: Activation = .unknown,
		interfaceOrientation: Orientation? = nil, horizontalSizeClass: SizeClass? = nil, verticalSizeClass: SizeClass? = nil,
		reservedRegions: [ReservedRegion] = [], hinge: Device.Hinge? = nil) {
		self.id = id; self.capturedAt = capturedAt; self.display = display; self.windowBounds = windowBounds; self.windowFrame = windowFrame
		self.localBounds = localBounds; self.safeArea = safeArea; self.activation = activation
		self.interfaceOrientation = interfaceOrientation; self.horizontalSizeClass = horizontalSizeClass; self.verticalSizeClass = verticalSizeClass
		self.reservedRegions = reservedRegions; self.hinge = hinge
	}
	/// Creates a stable presentation value for fixtures, diagnostics, and documentation.
	/// Live window geometry is measured by `deviceDisplayContext()` in an application.
	public init(id: String, capturedAt: Date = Date(), displayID: String = "presentation", displayName: String? = nil, screen: Screen? = nil,
		windowBounds: DisplayRect? = nil, windowFrame: DisplayRect? = nil, localBounds: DisplayRect? = nil, safeArea: DisplayInsets? = nil,
		activation: Activation = .unknown, interfaceOrientation: Orientation? = nil, horizontalSizeClass: SizeClass? = nil,
		verticalSizeClass: SizeClass? = nil, reservedRegions: [ReservedRegion] = [], hinge: Device.Hinge? = nil) {
		self.init(id: id, capturedAt: capturedAt, display: DisplaySnapshot(id: displayID, name: displayName, specification: screen),
			windowBounds: windowBounds, windowFrame: windowFrame, localBounds: localBounds, safeArea: safeArea, activation: activation,
			interfaceOrientation: interfaceOrientation, horizontalSizeClass: horizontalSizeClass, verticalSizeClass: verticalSizeClass,
			reservedRegions: reservedRegions, hinge: hinge)
	}
	func hasSameMeasurements(as other: Self) -> Bool {
		id == other.id && display.hasSameMeasurements(as: other.display) && windowBounds == other.windowBounds && windowFrame == other.windowFrame
			&& localBounds == other.localBounds && safeArea == other.safeArea && activation == other.activation
			&& interfaceOrientation == other.interfaceOrientation && horizontalSizeClass == other.horizontalSizeClass
			&& verticalSizeClass == other.verticalSizeClass && reservedRegions == other.reservedRegions && hinge == other.hinge
	}
}

/// Honest coverage of the platform adapter's discovery, rather than a physical-monitor guarantee.
enum DisplayDiscovery: String, Codable, Sendable {
	case unavailable, appScenes, legacyScreenInventory, desktopInventory
}

/// Schema-versioned support export. Stored values are frozen even when the live provider changes.
struct DisplayReport: Codable, Sendable {
	let schemaVersion: Int
	let capturedAt: Date
	let discovery: DisplayDiscovery
	let displays: [DisplaySnapshot]
	let presentations: [PresentationSnapshot]
	init(discovery: DisplayDiscovery, displays: [DisplaySnapshot], presentations: [PresentationSnapshot], capturedAt: Date = Date()) {
		schemaVersion = 1; self.capturedAt = capturedAt; self.discovery = discovery; self.displays = displays; self.presentations = presentations
	}
	/// Human-readable JSON suitable for a support request; IDs have meaning only within this report's process.
	func jsonData() throws -> Data {
		let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; encoder.outputFormatting = [.prettyPrinted]
		if #available(iOS 11, macOS 10.13, tvOS 11, watchOS 4, *) { encoder.outputFormatting.insert(.sortedKeys) }
		return try encoder.encode(self)
	}
	/// A compact one-line summary for logs; use `jsonData()` when detailed measurements are needed.
	var compactDescription: String {
		let outputText = displays.map { display in
			let dimensions = display.bounds.map { "\(Int($0.size.width))×\(Int($0.size.height)) pt" } ?? "size unavailable"
			return "\(display.name ?? display.id): \(dimensions)"
		}.joined(separator: "; ")
		return "Displays[\(discovery.rawValue)]: \(outputText.isEmpty ? "none discovered" : outputText); windows: \(presentations.count)"
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension DisplaySnapshot: Identifiable {}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension PresentationSnapshot: Identifiable {}
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
extension PresentationSnapshot.ReservedRegion: Identifiable {}
