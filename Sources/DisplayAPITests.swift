#if compiler(>=5.9)
import Foundation
import Compatibility

/// Shared deterministic tests, also surfaced by Device's in-app module runner.
@MainActor
@available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
enum DisplayAPITests {
	#if compiler(>=6.2)
	@diagnose(DeprecatedDeclaration, as: ignored) // Suppress deprecation warnings so that we can test deprecated code
	#endif
	static let tests: [TestCase] = {
		var tests: [TestCase] = [
		TestCase("Snapshots retain window identity on a shared display") {
			let output = DisplaySnapshot(id: "display", bounds: .init(width: 1920, height: 1080, space: .display))
			let first = PresentationSnapshot(id: "a", display: output, windowBounds: .init(width: 800, height: 600, space: .window))
			let second = PresentationSnapshot(id: "b", display: output, windowBounds: .init(width: 640, height: 480, space: .window))
			try expectEqual(first.display, second.display)
			try expect(first.id != second.id && first.windowBounds != second.windowBounds)
		},
		TestCase("Window movement is distinct from its local bounds and invalidates measurements") {
			let output = DisplaySnapshot(id: "display")
			let bounds = DisplayRect(width: 800, height: 600, space: .window)
			let first = PresentationSnapshot(id: "window", display: output, windowBounds: bounds, windowFrame: .init(x: 20, y: 30, width: 800, height: 600, space: .desktopBottomLeft))
			let moved = PresentationSnapshot(id: "window", display: output, windowBounds: bounds, windowFrame: .init(x: 80, y: 30, width: 800, height: 600, space: .desktopBottomLeft))
			try expectEqual(first.windowBounds, moved.windowBounds)
			try expect(!first.hasSameMeasurements(as: moved))
			let decoded = try JSONDecoder().decode(PresentationSnapshot.self, from: JSONEncoder().encode(moved))
			try expectEqual(decoded.windowFrame, moved.windowFrame)
		},
		TestCase("Duo window placement follows the reserved fold region") {
			let output = DisplaySnapshot(id: "duo", bounds: .init(width: 951, height: 669, space: .display))
			let hinge = Device.Hinge(status: .fullyOpen, angle: .degrees(180))
			let full = PresentationSnapshot(id: "full", display: output,
				windowFrame: .init(width: 951, height: 669, space: .display),
				localBounds: .init(width: 951, height: 669, space: .localView),
				safeArea: .init(leading: 0, trailing: 84),
				reservedRegions: [.init(id: "fold", kind: .division, bounds: .init(x: 455, y: 0, width: 40, height: 669, space: .localView))], hinge: hinge)
			let left = PresentationSnapshot(id: "left", display: output,
				windowFrame: .init(x: 0, y: 0, width: 475.5, height: 669, space: .display),
				localBounds: .init(width: 475.5, height: 669, space: .localView), safeArea: .init(trailing: 84),
				reservedRegions: [.init(id: "fold", kind: .division, bounds: .init(x: 435, y: 0, width: 40, height: 669, space: .localView))], hinge: hinge)
			let right = PresentationSnapshot(id: "right", display: output,
				windowFrame: .init(x: 475.5, y: 0, width: 475.5, height: 669, space: .display),
				localBounds: .init(width: 475.5, height: 669, space: .localView), safeArea: .init(leading: 84),
				reservedRegions: [.init(id: "fold", kind: .division, bounds: .init(x: 0, y: 0, width: 40, height: 669, space: .localView))], hinge: hinge)
			try expectEqual(full.windowPlacement, .fullScreen)
			try expectEqual(left.windowPlacement, .leftSide)
			try expectEqual(right.windowPlacement, .rightSide)
			let custom = PresentationSnapshot(id: "custom", display: output,
				windowFrame: .init(x: 30, y: 20, width: 600, height: 500, space: .display), hinge: hinge)
			try expectEqual(custom.windowPlacement, .customSized)
		},
		TestCase("Module display fields list all windows and omit watch, TV and vision hardware") { @MainActor in
			let display = DisplaySnapshot(id: "display", bounds: .init(width: 1920, height: 1080, space: .display))
			let first = PresentationSnapshot(id: "a", display: display, windowBounds: .init(width: 800, height: 600, space: .window))
			let second = PresentationSnapshot(id: "b", display: display, windowBounds: .init(width: 640, height: 480, space: .window))
			let fields = CurrentDisplayInfo.fields(idiom: .mac, presentations: [first, second], pose: .unknown)
			let sizes = fields.first { $0.label == "Window Sizes" }?.value.description ?? ""
			try expect(sizes.contains("800.0 × 600.0") && sizes.contains("640.0 × 480.0"))
			try expect(!fields.contains { $0.label == "Device Pose" || $0.label == "Device Orientation" })
			let phoneFields = CurrentDisplayInfo.fields(idiom: .phone, presentations: [first], pose: .unknown, orientation: .portrait)
			try expect(phoneFields.contains { $0.label == "Device Orientation" && $0.value.description == "portrait" })
			for idiom in [Device.Idiom.tv, .vision] {
				let fields = CurrentDisplayInfo.fields(idiom: idiom, presentations: [first], pose: .unknown)
				try expect(!fields.contains { $0.label == "Device Pose" || $0.label == "Device Orientation" })
			}
			let watchFields = CurrentDisplayInfo.fields(idiom: .watch, presentations: [first], pose: .unknown)
			try expect(watchFields.contains { $0.label == "Digital Crown Side" })
			try expect(!watchFields.contains { $0.label == "Device Orientation" || $0.label == "Device Pose" })
		},
		TestCase("Support report round trip preserves measurements and frozen timestamps") {
			let capturedAt = Date(timeIntervalSince1970: 8)
			let display = DisplaySnapshot(id: "display", capturedAt: capturedAt, name: "Fixture", bounds: .init(width: 1920, height: 1080, space: .display))
			let presentation = PresentationSnapshot(id: "window", capturedAt: capturedAt, display: display, windowBounds: .init(width: 800, height: 600, space: .window))
			let report = DisplayReport(discovery: .desktopInventory, displays: [display], presentations: [presentation], capturedAt: capturedAt)
			let data = try report.jsonData()
			let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
			let decoded = try decoder.decode(DisplayReport.self, from: data)
			try expectEqual(decoded.schemaVersion, 1)
			try expect(zip(decoded.displays, report.displays).allSatisfy { $0.hasSameMeasurements(as: $1) })
			try expectEqual(decoded.discovery, .desktopInventory)
			try expectEqual(decoded.capturedAt, capturedAt)
		},
		TestCase("Screen records only panel specifications") {
			let data = Data(#"{"resolution":{"width":1170,"height":2532},"ppi":460}"#.utf8)
			let panel = try JSONDecoder().decode(Screen.self, from: data)
			try expectEqual(panel.specification, panel)
		},
		TestCase("iPhone explicit panels override capability defaults") {
			let phone = iPhone(officialName: "Fixture", identifiers: ["Fixture1,1"], supportId: "fixture", launchOSVersion: "1", unsupportedOSVersion: nil, image: nil, capabilities: [.screens([.i4])], colors: [], cpu: .unknown, cameras: [], cellular: .none, screens: [.i63, .id76])
			try expectEqual(phone.screens, [.i63, .id76])
			// Keep the deprecated single-screen accessor stable for v2 callers.
			// code
			try expectEqual(phone.screen, .i63)
		},
		TestCase("Quarter turns swap only content dimensions") {
			let size = DisplaySize(width: 1920, height: 1080)
			try expectEqual(ExternalDisplayOrientation.bottomAtLeft.contentSize(for: size), .init(width: 1080, height: 1920))
			try expectEqual(ExternalDisplayOrientation.bottomAtRight.contentSize(for: size), .init(width: 1080, height: 1920))
			try expectEqual(ExternalDisplayOrientation.upsideDown.contentSize(for: size), size)
		},
		TestCase("Mirroring retains source layout without changing output measurements") {
			let source = PresentationSnapshot(id: "source", display: .init(id: "internal"), windowBounds: .init(width: 390, height: 844, space: .window))
			let target = PresentationSnapshot(id: "target", display: .init(id: "external", bounds: .init(width: 1920, height: 1080, space: .display), mirroredDisplayID: "internal"), windowBounds: .init(width: 1920, height: 1080, space: .window))
			let mirrored = ExternalPresentationContext(presentation: target, orientation: .bottomAtLeft, mirroredSource: source)
			try expectEqual(mirrored.contentBounds.size, .init(width: 844, height: 390))
			try expect(abs(mirrored.scaleToFit(in: .init(width: 1920, height: 1080)) - 1080.0 / 844.0) < 0.00001)
			try expectEqual(mirrored.presentation.display.bounds?.size, .init(width: 1920, height: 1080))
			let extended = ExternalPresentationContext(presentation: target, orientation: .upright)
			try expectEqual(extended.contentBounds.size, .init(width: 1920, height: 1080))
		},
		TestCase("AppKit desktop conversion retains its explicit convention") {
			let rect = DisplayRect(x: -100, y: 100, width: 800, height: 600, space: .desktopBottomLeft)
			let result = rect.topLeftDesktop(desktopTop: 1200)
			try expectEqual(result.y, 500)
			try expectEqual(result.space, .desktopTopLeft)
			try expectEqual(result.x, -100)
		},
		TestCase("Palette reversal matches but permutations and reversed individual tones do not") {
			let first = AppleMaterialColor(["#112233", "#445566"], "Two tone")
			let middle = AppleMaterialColor("#778899", "Middle")
			let last = AppleMaterialColor("#aabbcc", "Last")
			let values = [first, middle, last]
			try expect(values.matchesPalette([last, middle, first]))
			try expect(!values.matchesPalette([last, middle, first], acceptingReversedOrder: false))
			try expect(!values.matchesPalette([middle, first, last]))
			try expect(!values.matchesPalette([AppleMaterialColor(Array(first.swatches.reversed()), first.name), middle, last]))
			try expect(![AppleMaterialColor("#cc0000", "(PRODUCT)RED")].matchesPalette([AppleMaterialColor("#cc0000", "(PRODUCT)RED Aluminum")]))
		},
		TestCase("Biometric capability labels remain distinct") {
			try expectEqual(Biometrics.allCases.map(\.label), ["Touch ID", "Face ID", "Optic ID"])
			let listedBiometrics = Capability.allCases.compactMap { capability -> Biometrics? in
				guard case .biometrics(let biometric) = capability else { return nil }
				return biometric
			}
			try expectEqual(listedBiometrics, Biometrics.allCases, "The capability list must include each biometric exactly once, in order.")
			try expectEqual(listedBiometrics.map(\.label), ["Touch ID", "Face ID", "Optic ID"])
			try expectEqual(Capability.allBiometrics.map(\.label), ["Touch ID", "Face ID", "Optic ID"])
			try expectEqual(Set(listedBiometrics.map(\.symbolName)).count, 3, "Each biometric row must retain its own icon.")
		},
		TestCase("Foldable posture is independent of the open hinge flag") {
			let bent = Device.Hinge(status: .partiallyOpen, angle: .degrees(150))
			let flat = Device.Hinge(status: .fullyOpen, angle: .degrees(180))
			let seated = Device.Pose.inferred(orientation: .cameraTopLeft, hinge: bent, gravityZ: 0, isFoldable: true)
			let level = Device.Pose.inferred(orientation: .cameraTopLeft, hinge: flat, gravityZ: 0, isFoldable: true)
			try expectEqual(seated, .seated)
			try expectEqual(level, .fullyOpen)
			try expect(!bent.isFullyOpen && bent.isOpen)
			try expect(flat.isFullyOpen && flat.isOpen)
		},
		TestCase("Hinge observer teardown preserves other valid samples") { @MainActor in
			let registry = DeviceHingeRegistry()
			let first = UUID(), second = UUID()
			let sample = Device.Hinge(status: .partiallyOpen, angle: .degrees(90))
			registry.update(sample, observer: first); registry.update(sample, observer: second)
			registry.remove(first); try expectEqual(registry.current, sample)
			registry.remove(second); try expect(registry.current == nil)
		},
		TestCase("Native external registrations retain independent output settings") { @MainActor in
			#if canImport(SwiftUI) && canImport(Combine)
			let manager = ExternalDisplayManager()
			let first = UUID(), second = UUID()
			manager.registerNativePresentation("first", owner: first)
			manager.registerNativePresentation("second", owner: second)
			manager.setOrientation(.bottomAtLeft, for: "second")
			manager.registerNativePresentation(nil, owner: first)
			try expect(manager.displayConnected)
			try expectEqual(manager.presentationIDs, ["second"])
			try expectEqual(manager.orientation(for: "second"), .bottomAtLeft)
			manager.stop() // Stopping owned legacy windows must not erase a live OS-owned accessory.
			try expectEqual(manager.presentationIDs, ["second"])
			manager.registerNativePresentation(nil, owner: second)
			try expect(!manager.displayConnected)
			#endif
		},
		TestCase("Portable angles and pose galleries list device postures") {
			try expect(abs(Angle.degrees(180).radians - .pi) < 0.00001)
			let poses = Device.Pose.supported(for: Device(identifier: "iPhone16,1"))
			try expectEqual(poses, [])
		},
		TestCase("Device orientation and legacy aliases preserve the migration contract") {
			let expected: [(Device.LegacyOrientation, Device.Orientation)] = [
				(.unknown, .unknown), (.portrait, .portrait), (.portraitUpsideDown, .cameraBottomLeft),
				(.landscapeLeft, .cameraTopLeft), (.landscapeRight, .cameraBottomRight),
				(.faceUp, .faceUp), (.faceDown, .faceDown)
			]
			for (legacy, orientation) in expected {
				try expectEqual(Device.Orientation(legacy: legacy, idiom: .phone), orientation)
				try expectEqual(orientation.legacyOrientation, legacy)
			}
			try expectEqual(Device.Orientation(legacy: .portrait, idiom: .pad), .cameraTopRight)
			try expectEqual(Device.Orientation(legacy: .portrait, idiom: .phone, isFoldable: true), .cameraTopRight)
			let screenOrientation: Screen.Orientation = .cameraBottomRight
			let screenLegacyOrientation: Screen.LegacyOrientation = .landscapeRight
			try expectEqual(screenOrientation, .cameraBottomRight)
			try expectEqual(screenLegacyOrientation, .landscapeRight)
			for value in Device.Orientation.allCases {
				let data = try JSONEncoder().encode(value)
				try expectEqual(try JSONDecoder().decode(Device.Orientation.self, from: data), value)
			}
		},
		TestCase("Hinge Codable contract retains status and portable angle") {
			let hinge = Device.Hinge(status: .partiallyOpen, angle: .degrees(137.5))
			let data = try JSONEncoder().encode(hinge)
			let decoded = try JSONDecoder().decode(Device.Hinge.self, from: data)
			try expectEqual(decoded.status, .partiallyOpen)
			try expect(abs(decoded.angle.degrees - 137.5) < 0.00001)
			try expect(decoded.isOpen && !decoded.isFullyOpen)
		},
		TestCase("Watch crown side maps to the appropriate rotated icon") {
			try expectEqual(Device.CrownSide.right.rotationDegrees, 0)
			try expectEqual(Device.CrownSide.left.rotationDegrees, 180)
			try expectEqual(Device.CrownSide.left.symbolName, "applewatch.side.right")
		},
		TestCase("Foldable pose follows camera-corner orientation") {
			let partlyUnlatched = Device.Hinge(status: .closed, angle: .degrees(56))
			let bumpResting = Device.Pose.inferred(orientation: .faceUp, hinge: partlyUnlatched, gravityZ: -0.99, isFoldable: true)
			try expectEqual(bumpResting, .seated)
			let rareTent = Device.Pose.inferred(
				orientation: .cameraBottomRight,
				hinge: partlyUnlatched,
				gravityZ: 0.5,
				isFoldable: true
			)
			try expectEqual(rareTent, .tent)
			let rareSeated = Device.Pose.inferred(
				orientation: .cameraBottomRight,
				hinge: partlyUnlatched,
				gravityZ: 0.98,
				isFoldable: true
			)
			try expectEqual(rareSeated, .seated)

			let seatedWhileUnlatched = Device.Pose.inferred(orientation: .cameraTopLeft, hinge: partlyUnlatched, gravityZ: nil, isFoldable: true)
			try expectEqual(seatedWhileUnlatched, .seated)
			try expectEqual(Device.Pose.inferred(orientation: .cameraTopRight, hinge: partlyUnlatched, gravityZ: nil, isFoldable: true), .book)
			try expectEqual(Device.Pose.inferred(orientation: .cameraBottomLeft, hinge: partlyUnlatched, gravityZ: nil, isFoldable: true), .book)

			let partiallyOpen = Device.Hinge(status: .partiallyOpen, angle: .degrees(90))
			try expectEqual(Device.Pose.inferred(orientation: .cameraTopLeft, hinge: partiallyOpen, gravityZ: nil, isFoldable: true), .seated)
			try expectEqual(Device.Pose.inferred(orientation: .cameraTopRight, hinge: partiallyOpen, gravityZ: nil, isFoldable: true), .book)
			try expectEqual(Device.Pose.inferred(orientation: .cameraBottomLeft, hinge: partiallyOpen, gravityZ: nil, isFoldable: true), .book)
			try expectEqual(Device.Pose.inferred(orientation: .cameraBottomRight, hinge: partiallyOpen, gravityZ: nil, isFoldable: true), .tent)
			try expectEqual(Device.Pose.inferred(orientation: .cameraBottomRight, hinge: partiallyOpen, gravityZ: 0.95, isFoldable: true), .seated)

			let fullyClosed = Device.Hinge(status: .closed, angle: .degrees(0))
			let closed = Device.Pose.inferred(
				orientation: .cameraTopLeft,
				hinge: fullyClosed,
				gravityZ: nil,
				isFoldable: true
			)
			try expectEqual(closed, .closed)
		},
		TestCase("Closed foldable glyphs cover both landscape camera corners") {
			let device = Device(identifier: "iPhone19,4")
			try expectEqual(Device.Pose.closed.symbolName(for: device, orientation: .cameraTopLeft), "pose.closed.landscape.left")
			try expectEqual(Device.Pose.closed.symbolName(for: device, orientation: .cameraBottomRight), "pose.closed.landscape.right")
			try expectEqual(Device.Pose.closed.symbolName(for: device, orientation: .cameraBottomLeft), "pose.closed.portrait.upsidedown")
			try expectEqual(Device.Pose.closed.symbolName(for: device, orientation: .cameraTopRight), "pose.closed.portrait")
			try expectEqual(Device.Pose.closed.symbolName(for: device, orientation: .portrait), "pose.closed.portrait")
			try expectEqual(Device.Orientation.cameraTopLeft.cameraCornerRotationDegrees, 180)
			try expectEqual(Device.Orientation.cameraTopRight.cameraCornerRotationDegrees, -90)
			try expectEqual(Device.Orientation.cameraBottomLeft.cameraCornerRotationDegrees, 90)
			try expectEqual(Device.Orientation.cameraBottomRight.cameraCornerRotationDegrees, 0)
		}
		]
#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
		tests.append(TestCase("Camera-corner orientation converts to nearest UIKit direction") {
			try expectEqual(Device.Orientation(uiDeviceOrientation: .landscapeLeft, idiom: .pad), .cameraTopLeft)
			try expectEqual(Device.Orientation(uiDeviceOrientation: .portrait, idiom: .pad), .cameraTopRight)
			try expectEqual(Device.Orientation.cameraBottomRight.uiDeviceOrientation, .landscapeRight)
			try expectEqual(Device.Orientation.faceDown.uiDeviceOrientation, .faceDown)
		})
#endif
#if os(iOS) && !targetEnvironment(macCatalyst)
		tests.append(TestCase("Core Motion landscape gravity maps to UIKit camera sides") {
			try await expectEqual(DisplayMonitor.orientation(gravityX: -1, gravityY: 0, gravityZ: 0), .landscapeLeft)
			try await expectEqual(DisplayMonitor.orientation(gravityX: 1, gravityY: 0, gravityZ: 0), .landscapeRight)
		})
#endif
		return tests
	}()
}
#endif
