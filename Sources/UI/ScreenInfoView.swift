#if canImport(SwiftUI) && canImport(Foundation)
import SwiftUI
import Compatibility

public extension Screen.Size {
    /// Conversion of Screen.Size to CGSize
    var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }
}

// TODO: Remove once we're using Compatibility v1.0.19 or later
extension Double {
    var withoutZeros: String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 16 //maximum digits in Double after dot (maximum precision)
        return String(formatter.string(from: number) ?? "")
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
struct ScreenBrightnessView<SomeCurrentDevice: CurrentDevice & ObservableObject>: View {
    @ObservedObject var currentDevice: SomeCurrentDevice
  init(currentDevice: SomeCurrentDevice) {
    self.currentDevice = currentDevice
  }
    var body: some View {
        if let brightness = currentDevice.brightness {
            HStack(spacing: 2) {
				Image(symbolName: brightness < 0.5 ? "sun.min" : "sun.max")
                Text("\(Int(brightness * 100))%")
            }
		} else {
			EmptyView()
		}
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
public struct ScreenInfoView: View {
    public var device: any DeviceType
	@Environment(\.activeDisplay) private var contextualDisplay
	@Environment(\.presentation) private var contextualPresentation
	@Environment(\.windowPlacement) private var contextualWindowPlacement
	@Environment(\.externalPresentationOrientation) private var externalOrientation
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	private var live = false
	private var capturedPresentation: PresentationSnapshot?
	@State private var showCatalogDetails = false
	/// Live diagnostics for the window hosting this card.
	@MainActor public init() { device = Device.current; live = true }
	/// Fixed catalog panels and supported poses; never reads the current machine's sensors.
    public init(device: any DeviceType) { self.device = device }
	/// A fixed runtime capture, unchanged by later OS updates.
	public init(presentation: PresentationSnapshot) { device = Device(identifier: "CAPTURE"); capturedPresentation = presentation }

    var screen: Screen {
        guard let screen = device.screens.first else {
            return .undefined // should never happen
        }
        return screen
    }   
	@MainActor
	var statusFeatures: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 10) {
				#if os(watchOS)
				if let crownSide = Device.current.crownSide {
					WatchCrownSideView(side: crownSide).backport.help(crownSide.accessibilityDescription)
				}
				#elseif !os(macOS) && !os(tvOS) && !os(visionOS)
				if device.screens.count > 1 {
					ForEach(Array(Device.Pose.supported(for: device).enumerated()), id: \.offset) { _, pose in
						DevicePoseView(pose: pose, device: device).backport.help(pose.accessibilityDescription)
					}
				} else {
					ForEach(Array(Device.Orientation.allCases.filter { $0 != .unknown }.enumerated()), id: \.offset) { _, orientation in
						DeviceOrientationView(orientation: orientation, device: device).backport.help(orientation.accessibilityDescription)
					}
				}
				#endif
			}
		}.font(.footnote)
	}
	public var body: some View {
		Group {
			if live {
				if contextualDisplay != nil || contextualPresentation != nil { LiveScreenDiagnostics() }
				else { LiveScreenDiagnostics().deviceDisplayContext() }
			}
			else if let capturedPresentation { InteractiveDisplayCard(display: capturedPresentation.display, presentation: capturedPresentation) }
			else {
				Button { showCatalogDetails = true } label: {
#if os(watchOS)
					VStack(alignment: .leading, spacing: 4) {
						HStack {
							if let crownSide = Device.current.crownSide { WatchCrownSideView(side: crownSide) }
							Text(device.officialName).lineLimit(1).font(.caption)
							Spacer(minLength: 2)
							Image(symbolName: "chevron.right").backport.font(.caption2)
						}
						if let panel = device.screens.first {
							Text("\(panel.resolution.width) × \(panel.resolution.height) px\(panel.diagonal.map { " · \($0.withoutZeros) in" } ?? "")").backport.font(.caption2).lineLimit(1)
						} else {
						Text("Screen specifications").backport.font(.caption2)
						}
						statusFeatures
					}.contentShape(Rectangle())
#else
					if horizontalSizeClass == .compact {
						VStack(alignment: .leading, spacing: 4) {
							HStack { Text(device.officialName).lineLimit(1); Spacer(); Image(symbolName: "chevron.right") }
							if let panel = device.screens.first {
								Text("\(panel.resolution.width) × \(panel.resolution.height) px").font(.caption)
							}
							statusFeatures
						}.contentShape(Rectangle())
					} else {
					VStack(alignment: .leading) {
						HStack { Text("Hardware specification"); Spacer(); Image(symbolName: "chevron.right") }.font(.caption)
						if device.screens.isEmpty {
							Text("No fixed addressable panel specification")
						} else {
							ForEach(Array(device.screens.enumerated()), id: \.offset) { _, panel in catalogBody(for: panel) }
						}
						Text("Supported poses and orientations").font(.caption)
						statusFeatures
					}.contentShape(Rectangle())
					}
#endif
				}
				.buttonStyle(.plain)
				.sheet(isPresented: $showCatalogDetails) {
					VStack {
						ScrollView {
							VStack(alignment: .leading) {
								Text(device.officialName).font(.headline)
								Text("Fixed hardware panels (pixels)").font(.caption)
								ForEach(Array(device.screens.enumerated()), id: \.offset) { _, panel in catalogBody(for: panel) }
								Text("Supported poses").font(.headline)
								statusFeatures
							}
						}
						Button("Done") { showCatalogDetails = false }
					}.padding().frame(idealWidth: 480)
				}
			}
		}
	}
	private func catalogBody(for screen: Screen) -> some View {
        VStack {
            HStack(alignment: .lastTextBaseline, spacing: 0) {
				Image(symbolName: "rectangle.inset.filled.and.person.filled")
                Text(" Screen").font(.headline)
                Spacer()
                if let diagonal = screen.diagonal {
                    Text("\(diagonal.withoutZeros)").font(.headline)
                    Text(" in ").opacity(0.5)
					Image(symbolName: "arrow.down.backward.and.arrow.up.forward").font(.headline).opacity(0.5)
                }
            }
            HStack {
				Image(symbolName: "arrow.left.and.right")
                Text("\(screen.resolution.width)")
				Image(symbolName: "arrow.up.and.down")
                Text("\(screen.resolution.height)")
            }
            CapabilitiesTextView(capabilities: .screenFeatures.intersection(device.capabilities), centered: true)
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                if let ppi = screen.ppi {
                    Text("\(ppi)").font(.headline)
                    Text(" ppi  ").opacity(0.5)
                }
                statusFeatures
                Spacer()
                Text("ratio: ").opacity(0.5)
                Text("\(screen.resolution.ratio.width):\(screen.resolution.ratio.height)").font(.headline)
            }
        }
        .font(.caption)
        .padding()
#if os(visionOS)
        .foregroundStyle(.black) // can do background but doesn't provide enough contrast.
#else
        // NavigationLink selection can inject a white foreground into the
        // current-device card. Its card background is the system background,
        // so explicitly use the primary text color for readable labels.
        // Screen cards intentionally keep their own contrasting text and do
        // not participate in NavigationLink selection coloring.
        // This card deliberately uses the opposite contrast of the outer
        // selection surface: the light-mode card is dark, while dark-mode
        // presentation uses a light card.
        // Difference blending keeps the card readable when a light-mode
        // NavigationLink selection changes its surrounding background from
        // dark to white, while preserving the inverse contrast in dark mode.
		.backport.foregroundStyle(.white)
        .blendMode(.difference)
#endif
		.backport.background {
            RoundedRectangle(cornerRadius: .devicePanelRadius)
        }
    }
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
#Preview("Screens") {
    List {
        Section {
            Text("Current Device")
            ScreenInfoView()
        }
        Section {
            ForEach(MockDevice.mocks, id: \.identifiers) { device in
                Text(device.identifier)
                ScreenInfoView(device: device)
            }
        }
        Section {
            ForEach(Device.all) { device in
                if let panel = device.screens.first, panel != .undefined {
                    Text(device.officialName)
                    ScreenInfoView(device: device)
                }
            }
        }
    }
}
#endif

#if canImport(SwiftUI) && canImport(Foundation)
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct LiveScreenDiagnostics: View {
	@Environment(\.presentation) private var presentation
	@Environment(\.activeDisplay) private var display
	@ObservedObject private var monitor = DisplayMonitor.shared
	private var currentPresentation: PresentationSnapshot? {
		guard let presentation else { return nil }
		return monitor.presentations.first(where: { $0.id == presentation.id }) ?? presentation
	}
	private var currentDisplay: DisplaySnapshot? {
		if let presentation = currentPresentation {
			return monitor.displays.first(where: { $0.id == presentation.displayID }) ?? presentation.display
		}
		guard let display else { return nil }
		return monitor.displays.first(where: { $0.specification == display })
	}
	var body: some View {
		Group {
			if let presentation = currentPresentation, let display = currentDisplay {
				InteractiveDisplayCard(display: display, presentation: presentation, isLive: true)
			}
			else { ScreenInfoView(device: Device.current.device) }
		}
	}
}

/// Compact visual summary. Opening details keeps the original hosting-window context;
/// measuring the sheet itself would report the wrong dimensions for the source window.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct InteractiveDisplayCard: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@Environment(\.activeDisplay) private var contextualScreen
	@Environment(\.windowPlacement) private var contextualWindowPlacement
	@Environment(\.externalPresentationOrientation) private var externalOrientation
	@ObservedObject private var monitor = DisplayMonitor.shared
	let display: DisplaySnapshot
	let presentation: PresentationSnapshot?
	var isLive = false
	var symbol = "rectangle"
	@State private var showDetails = false
	@State private var motionObservationID = UUID()
	private var currentPresentation: PresentationSnapshot? {
		guard isLive, let id = presentation?.id else { return presentation }
		return monitor.presentations.first(where: { $0.id == id }) ?? presentation
	}
	private var dimensions: DisplaySize? { currentPresentation?.windowBounds?.size ?? currentPresentation?.localBounds?.size ?? currentDisplay.bounds?.size }
	private var currentDisplay: DisplaySnapshot {
		guard isLive else { return display }
		return monitor.displays.first(where: { $0.id == display.id }) ?? display
	}
	private var currentHinge: Device.Hinge? {
		guard isDeviceDisplay else { return nil }
		return isLive ? DeviceHingeRegistry.shared.current : currentPresentation?.hinge
	}
	private var isFoldableDevice: Bool { Device.current.device.screens.count > 1 }
	private var isDeviceDisplay: Bool {
		guard isFoldableDevice else { return true }
		if let specification = screenSpecification {
			return Device.current.device.screens.contains(specification)
		}
		return monitor.displays.first?.id == display.id
	}
	private var hingePercent: Double? {
		guard isDeviceDisplay, isFoldableDevice else { return nil }
		return min(max((currentHinge?.angle.degrees ?? 0) / 180 * 100, 0), 100)
	}
	private var showsPoseOrientation: Bool {
#if os(iOS) && !targetEnvironment(macCatalyst) && !os(visionOS)
		return [.pod, .phone, .pad].contains(Device.current.device.idiom)
#else
		return false
#endif
	}
	private var crownSide: Device.CrownSide? {
#if os(watchOS)
		return Device.current.crownSide
#else
		return nil
#endif
	}
	private var pose: Device.Pose? {
		guard isDeviceDisplay else { return nil }
		return isLive ? monitor.pose : Device.Pose.inferred(orientation: Device.current.deviceOrientation,
			hinge: presentation?.hinge, gravityZ: nil, isFoldable: isFoldableDevice)
	}
	private var deviceOrientation: Device.Orientation {
		isLive ? monitor.deviceOrientation : Device.current.deviceOrientation
	}
	private var orientation: Device.LegacyOrientation? {
		if let externalOrientation {
			switch externalOrientation {
			case .upright:
				if let size = presentation?.windowBounds?.size { return size.width >= size.height ? .landscapeLeft : .portrait }
				return .landscapeLeft
			case .bottomAtLeft: return .landscapeLeft
			case .bottomAtRight: return .landscapeRight
			case .upsideDown: return .portraitUpsideDown
			}
		}
		if isLive && isDeviceDisplay {
			// App orientation describes the actual window. A Duo spanning both
			// panels is landscape; a single-panel/split window is portrait even
			// while the physical device pose remains open landscape.
			if isFoldableDevice,
			   let size = (presentation?.localBounds ?? presentation?.windowBounds)?.size,
			   size.width > 0, size.height > 0 {
				return size.width >= size.height ? .landscapeLeft : .portrait
			}
		}
		switch presentation?.interfaceOrientation {
		case .portrait: return .portrait
		case .portraitUpsideDown: return .portraitUpsideDown
		case .landscapeLeft: return .landscapeLeft
		case .landscapeRight: return .landscapeRight
		case .faceUp: return .faceUp
		case .faceDown: return .faceDown
		case .unknown: return .unknown
		case nil: return Device.current.screenOrientation
		}
	}
	private var windowPlacement: PresentationSnapshot.WindowPlacement? {
		if isLive { return contextualWindowPlacement == .unknown ? currentPresentation?.windowPlacement : contextualWindowPlacement }
		return currentPresentation?.windowPlacement
	}
	private var screenSpecification: Screen? {
		// Prefer the panel explicitly associated with this presentation. Older
		// adapters may not provide it, so fall back to native pixel dimensions.
		if let contextualScreen { return contextualScreen }
		if let specification = presentation?.screen ?? display.specification { return specification }
		guard let pixels = display.nativePixels ?? display.mode?.pixels else { return nil }
		return Device.current.device.screens.first { screen in
			let width = Double(screen.resolution.width), height = Double(screen.resolution.height)
			return (width == pixels.width && height == pixels.height) || (width == pixels.height && height == pixels.width)
		}
	}
	var body: some View {
		Button { showDetails = true } label: {
			Group {
#if os(watchOS)
				compactSummary
#else
				if horizontalSizeClass == .compact { compactSummary }
				else {
			HStack(alignment: .center, spacing: 16) {
				VStack(alignment: .leading, spacing: 5) {
					HStack {
					if !isDeviceDisplay, let orientation { Image(symbolName: orientation.symbolName) }
					if showsPoseOrientation, isFoldableDevice, let pose {
						DevicePoseView(pose: pose, device: Device.current.device, orientation: deviceOrientation)
						Text(pose.accessibilityDescription).font(.caption)
						DeviceOrientationView(orientation: deviceOrientation, device: Device.current.device)
							.backport.accessibilityLabel(deviceOrientation.accessibilityDescription)
					} else if showsPoseOrientation, isDeviceDisplay {
						DeviceOrientationView(orientation: deviceOrientation, device: Device.current.device)
						Text(deviceOrientation.accessibilityDescription).font(.caption)
					}
					#if os(watchOS)
					if isDeviceDisplay, let crownSide {
						WatchCrownSideView(side: crownSide)
						Text(crownSide.accessibilityDescription).font(.caption)
					}
					#endif
					}
					if let horizontal = currentPresentation?.horizontalSizeClass { Text("Horizontal: \(horizontal.rawValue)").font(.caption) }
					if let vertical = currentPresentation?.verticalSizeClass { Text("Vertical: \(vertical.rawValue)").font(.caption) }
					if let bounds = currentPresentation?.localBounds ?? currentPresentation?.windowBounds {
						HStack { Image(symbolName: "arrow.up.left.and.arrow.down.right"); Text("\(bounds.size.width.withoutZeros) × \(bounds.size.height.withoutZeros) pt") }.font(.caption).backport.accessibilityIdentifier("ScreenWindowBounds")
					}
					if let frame = currentPresentation?.windowFrame {
						HStack { WindowPositionAxisSymbol().frame(width: 14, height: 14); Text("(\(frame.x.withoutZeros), \(frame.y.withoutZeros)) pt") }.font(.caption)
					}
				}.frame(maxWidth: .infinity, alignment: .leading)
				VStack(spacing: 6) {
					HStack {
						Image(symbolName: "arrow.left.and.right"); Text(dimensions?.width.withoutZeros ?? "—").backport.accessibilityIdentifier("ScreenWindowWidth")
						Image(symbolName: "arrow.up.and.down"); Text(dimensions?.height.withoutZeros ?? "—").backport.accessibilityIdentifier("ScreenWindowHeight")
					}.font(.headline)
					Text(currentPresentation?.windowBounds == nil ? "display points" : "window points").font(.caption)
					CapabilitiesTextView(capabilities: .screenFeatures.intersection(Device.current.device.capabilities), centered: true)
						.font(.caption)
						.multilineTextAlignment(.center)
						.frame(maxWidth: .infinity, alignment: .center)
					HStack(spacing: 8) {
						if let brightness = currentDisplay.brightness {
							DeviceMetricDial(value: brightness * 100, maximum: 100, symbol: brightness < 0.5 ? "sun.min" : "sun.max", label: "Brightness", valueSuffix: "%", diameter: 44, valueInside: false)
						}
						if let hingePercent {
							DeviceMetricDial(value: hingePercent, maximum: 100, symbol: "rectangle.split.2x1", label: "Hinge", valueSuffix: "%", diameter: 44, valueInside: true)
						}
					}
				}.frame(maxWidth: .infinity)
				VStack(alignment: .trailing, spacing: 4) {
					if let spec = screenSpecification {
						Text("\(spec.resolution.width) × \(spec.resolution.height) px").font(.caption)
						if let diagonal = spec.diagonal { Text("\(diagonal.withoutZeros) in").font(.caption) }
						if let ppi = spec.ppi { Text("\(ppi) ppi").font(.caption) }
					}
					if let rate = currentDisplay.mode?.refreshRate { Text("\(rate.withoutZeros) Hz").font(.caption) }
					if let scale = currentDisplay.scale { Text("Scale \(scale.withoutZeros)×").font(.caption) }
					Image(symbolName: "chevron.right").font(.caption)
				}.frame(maxWidth: .infinity, alignment: .trailing)
			}.padding().contentShape(Rectangle())
				}
#endif
			}
				.background(RoundedRectangle(cornerRadius: .devicePanelRadius).fill(Color.gray.opacity(0.12)))
		}
		.buttonStyle(.plain)
		.backport.accessibilityIdentifier("ScreenInfoDetailsButton")
		.onAppear {
			if isLive && isDeviceDisplay { DisplayMonitor.shared.startPoseMonitoring(owner: motionObservationID) }
		}
		.onDisappear { DisplayMonitor.shared.stopPoseMonitoring(owner: motionObservationID) }
		.sheet(isPresented: $showDetails) {
			VStack(spacing: 12) {
				HStack {
					Button { showDetails = false } label: {
						HStack(spacing: 4) { Image(symbolName: "chevron.left"); Text("Back") }
					}
					Spacer()
					Text("Screen State").font(.headline)
					Spacer()
					// Balance the title against the leading back control.
					Color.clear.frame(width: 48, height: 1)
				}
				PoseOrientationTestPanel(
					device: Device.current.device,
					showsPoseOrientation: showsPoseOrientation,
					crownSide: crownSide,
					pose: pose ?? Device.Pose.unknown,
					orientation: deviceOrientation,
					hingePercent: hingePercent,
					windowSize: dimensions,
					horizontalSizeClass: currentPresentation?.horizontalSizeClass?.rawValue,
					verticalSizeClass: currentPresentation?.verticalSizeClass?.rawValue,
					brightness: currentDisplay.brightness,
					screen: screenSpecification,
					scale: currentDisplay.scale,
					refreshRate: currentDisplay.mode?.refreshRate,
					windowPlacement: windowPlacement,
					hinge: currentHinge
				)
				Spacer(minLength: 0)
			}.padding()
			.frame(idealWidth: 480)
		}
	}
	private var compactSummary: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack(spacing: 6) {
				if showsPoseOrientation, isFoldableDevice, isDeviceDisplay {
					DevicePoseView(pose: pose ?? Device.current.pose, device: Device.current.device, orientation: deviceOrientation)
					Text(pose?.accessibilityDescription ?? "Pose unavailable").font(.caption).lineLimit(1)
				} else if showsPoseOrientation, isDeviceDisplay {
					DeviceOrientationView(orientation: deviceOrientation, device: Device.current.device)
					Text(deviceOrientation.accessibilityDescription).font(.caption).lineLimit(1)
				} else if isDeviceDisplay, let crownSide {
					WatchCrownSideView(side: crownSide)
					Text(crownSide.accessibilityDescription).font(.caption).lineLimit(1)
				} else {
					Text(display.name ?? "Display").font(.caption).lineLimit(1)
				}
				Spacer(minLength: 2)
				if let brightness = currentDisplay.brightness {
					DeviceMetricDial(value: brightness * 100, maximum: 100, symbol: brightness < 0.5 ? "sun.min" : "sun.max", label: "Brightness", valueSuffix: "%", diameter: 34, valueInside: false)
				}
				Image(symbolName: "chevron.right").backport.font(.caption2)
			}
			if let dimensions {
				HStack(spacing: 4) {
					Image(symbolName: "arrow.up.left.and.arrow.down.right")
					Text("\(dimensions.width.withoutZeros) × \(dimensions.height.withoutZeros) pt")
				}.font(.caption).backport.accessibilityIdentifier("ScreenWindowBounds")
			}
			if let hingePercent {
				DeviceMetricDial(value: hingePercent, maximum: 100, symbol: "rectangle.split.2x1", label: "Hinge", valueSuffix: "%", diameter: 34, valueInside: true)
			}
			if let spec = screenSpecification {
				Text("\(spec.resolution.width) × \(spec.resolution.height) px\(spec.diagonal.map { " · \($0.withoutZeros) in" } ?? "")\(spec.ppi.map { " · \($0) ppi" } ?? "")")
					.backport.font(.caption2).lineLimit(1)
			}
			CapabilitiesTextView(capabilities: .screenFeatures.intersection(Device.current.device.capabilities), centered: true).backport.font(.caption2)
		}.padding().contentShape(Rectangle())
	}
}

/// Fixed-footprint sensor dashboard. Only the glyphs and readings update; the
/// square frame remains stable while the device or its window changes shape.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct PoseOrientationTestPanel: View {
	@State private var motionObservationID = UUID()
	let device: any DeviceType
	let showsPoseOrientation: Bool
	let crownSide: Device.CrownSide?
	let pose: Device.Pose
	let orientation: Device.Orientation
	let hingePercent: Double?
	let windowSize: DisplaySize?
	let horizontalSizeClass: String?
	let verticalSizeClass: String?
	let brightness: Double?
	let screen: Screen?
	let scale: Double?
	let refreshRate: Double?
	let windowPlacement: PresentationSnapshot.WindowPlacement?
	let hinge: Device.Hinge?
		private let side: CGFloat = 280
	var body: some View {
		VStack(spacing: 6) {
			Text("Pose and Orientation").font(.headline)
			ZStack {
				RoundedRectangle(cornerRadius: 18).fill(Color.gray.opacity(0.12))
				VStack(spacing: 6) {
					if showsPoseOrientation {
					HStack(spacing: 18) {
						if device.screens.count > 1 {
							VStack(spacing: 4) {
								DevicePoseView(pose: pose, device: device, orientation: orientation).font(.system(size: 44)).frame(width: 56, height: 56)
								Text(pose.accessibilityDescription).font(.caption).lineLimit(1)
							}
						}
						VStack(spacing: 4) {
							DeviceOrientationView(orientation: orientation, device: device).font(.system(size: 44))
								.frame(width: 56, height: 56)
							Text(orientation.accessibilityDescription).font(.caption).lineLimit(1)
						}
					}
					}
					if let crownSide {
						HStack(spacing: 6) {
							WatchCrownSideView(side: crownSide).font(.system(size: 44)).frame(width: 56, height: 56)
							Text(crownSide.accessibilityDescription).font(.caption)
						}
					}
					if let hingePercent {
						DeviceMetricDial(value: hingePercent, maximum: 100, symbol: "rectangle.split.2x1", label: "Hinge", valueSuffix: "%", diameter: 38, valueInside: true)
						if let hinge {
							Text("Hinge open: \(hinge.isOpen ? "Yes" : "No") · fully open: \(hinge.isFullyOpen ? "Yes" : "No")")
								.backport.font(.caption2).lineLimit(1)
						}
					}
					if let windowPlacement {
						HStack(spacing: 4) {
							Text("Window: \(windowPlacement.description)")
							Image(symbolName: windowPlacement.symbolName)
						}.backport.font(.caption2).lineLimit(1)
					}
					if let windowSize {
						HStack(spacing: 4) {
							Image(symbolName: "arrow.up.left.and.arrow.down.right")
							Text("\(windowSize.width.withoutZeros) × \(windowSize.height.withoutZeros) pt")
						}.font(.caption).lineLimit(1).minimumScaleFactor(0.75)
					}
					if let horizontalSizeClass, let verticalSizeClass {
						Text("Size class: \(horizontalSizeClass) × \(verticalSizeClass)").backport.font(.caption2).lineLimit(1)
					}
					if let brightness {
						HStack(spacing: 4) {
							Image(symbolName: brightness < 0.5 ? "sun.min" : "sun.max")
							Text("Brightness \(Int(brightness * 100))%")
						}.backport.font(.caption2)
					}
					if let screen {
						Text("\(screen.resolution.width) × \(screen.resolution.height) px\(screen.ppi.map { " · \($0) ppi" } ?? "")").backport.font(.caption2).lineLimit(1)
					}
					HStack(spacing: 8) {
						if let scale { Text("Scale \(scale.withoutZeros)×") }
						if let refreshRate { Text("\(refreshRate.withoutZeros) Hz") }
					}.backport.font(.caption2).lineLimit(1)
				}
				.padding(12)
			}
			.frame(width: side, height: side)
		}
		.frame(maxWidth: .infinity)
		.accessibilityElement(children: .combine)
		.backport.accessibilityIdentifier("PoseOrientationTestPanel")
		#if os(iOS) && !targetEnvironment(macCatalyst) && !os(visionOS)
		.onAppear { if showsPoseOrientation { DisplayMonitor.shared.startPoseMonitoring(owner: motionObservationID) } }
		.onDisappear { DisplayMonitor.shared.stopPoseMonitoring(owner: motionObservationID) }
		#endif
	}
}

@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct WindowPositionAxisSymbol: View {
	var body: some View {
		GeometryReader { geometry in
			Path { path in
				let w = geometry.size.width, h = geometry.size.height
				path.move(to: CGPoint(x: 1, y: 1)); path.addLine(to: CGPoint(x: w - 2, y: 1)); path.addLine(to: CGPoint(x: w - 5, y: 4)); path.move(to: CGPoint(x: w - 2, y: 1)); path.addLine(to: CGPoint(x: w - 5, y: 0))
				path.move(to: CGPoint(x: 1, y: 1)); path.addLine(to: CGPoint(x: 1, y: h - 2)); path.addLine(to: CGPoint(x: 4, y: h - 5)); path.move(to: CGPoint(x: 1, y: h - 2)); path.addLine(to: CGPoint(x: 0, y: h - 5))
			}.stroke(Color.primary, lineWidth: 1.4)
		}.backport.accessibilityHidden(true)
	}
}

/// Reusable fixed diagnostics for support captures and recorded display states.
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
private struct DisplayDiagnosticsCard: View {
	let display: DisplaySnapshot
	let presentation: PresentationSnapshot?
	init(display: DisplaySnapshot, presentation: PresentationSnapshot? = nil) { self.display = display; self.presentation = presentation }
	private func size(_ value: DisplaySize?) -> String {
		guard let value else { return "Unavailable" }
		return "\(value.width.withoutZeros) × \(value.height.withoutZeros)"
	}
	private func rectangle(_ value: DisplayRect?) -> String {
		guard let value else { return "Unavailable" }
		return "\(size(value.size)) at (\(value.x.withoutZeros), \(value.y.withoutZeros)); \(value.space.rawValue)"
	}
	private var capturedPose: Device.Pose? {
		guard Device.current.device.screens.count > 1,
			let specification = display.specification,
			Device.current.device.screens.contains(specification) else { return nil }
		return Device.Pose.inferred(orientation: Device.current.deviceOrientation,
			hinge: presentation?.hinge, gravityZ: nil, isFoldable: Device.current.device.screens.count > 1)
	}
	private func row(_ title: String, _ value: String) -> some View {
		HStack(alignment: .top) { Text(title); Spacer(); Text(value).multilineTextAlignment(.trailing) }
	}
	var body: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(display.name ?? "Display diagnostics").font(.headline)
			row("Display ID (process)", display.id)
			row("Captured", display.capturedAt.description)
			row("Display bounds (points)", rectangle(display.bounds))
			row("Rendering scale", display.scale.map { $0.withoutZeros } ?? "Unavailable")
			row("Native panel pixels", size(display.nativePixels))
			row("Render mode pixels", size(display.mode?.pixels))
			if let rate = display.mode?.refreshRate { row("Mode refresh rate", "\(rate.withoutZeros) Hz") }
			if let maximum = display.maximumFramesPerSecond { row("Maximum frame rate", "\(maximum) fps") }
			if let mirrored = display.mirroredDisplayID { row("Mirrors display", mirrored) }
			if let brightness = display.brightness { row("Captured brightness", "\(Int(brightness * 100))%") }
			if let pose = capturedPose { DevicePoseView(pose: pose, device: Device.current.device); Text(pose.accessibilityDescription) }
			if let presentation {
				Divider()
				row("Presentation ID (process)", presentation.id)
				row("Presentation captured", presentation.capturedAt.description)
				row("Window bounds (points)", rectangle(presentation.windowBounds))
				row("Window frame on output", rectangle(presentation.windowFrame))
				row("Window placement", presentation.windowPlacement.description)
				row("Local view (points)", rectangle(presentation.localBounds))
				row("Activation", presentation.activation.rawValue)
				if let horizontal = presentation.horizontalSizeClass { row("Horizontal size class", horizontal.rawValue) }
				if let vertical = presentation.verticalSizeClass { row("Vertical size class", vertical.rawValue) }
				if let orientation = presentation.interfaceOrientation { row("Interface orientation", orientation.accessibilityDescription) }
				if let safe = presentation.safeArea { row("Safe area T/L/B/R", "\(safe.top)/\(safe.leading)/\(safe.bottom)/\(safe.trailing)") }
				if let hinge = presentation.hinge { row("Hinge", "\(hinge.status.rawValue), \(hinge.angle.degrees.withoutZeros)°") }
				ForEach(presentation.reservedRegions) { region in row("Reserved \(region.kind.rawValue)", rectangle(region.bounds)) }
			}
			if let specification = display.specification { row("Known panel (pixels)", "\(specification.resolution.width) × \(specification.resolution.height)") }
		}
		.font(.caption).padding()
		.background(RoundedRectangle(cornerRadius: .devicePanelRadius).fill(Color.gray.opacity(0.12)))
	}
}
#endif
