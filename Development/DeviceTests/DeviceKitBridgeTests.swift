// The Xcode test target compiles DeviceKitConversion.swift and its small shared
// development dependencies beside these focused bridge contract checks.
@_exported import Compatibility
@_exported import Device

#if canImport(SwiftUI) && canImport(Testing)
import Testing

@Suite
@MainActor
struct DeviceKitBridgeTests {
	/// Older named and positional rows omit the newer flags and must keep false defaults.
	@Test func legacyDeviceKitRecordsDefaultNewFlagsToFalse() throws {
		let named = #"Device("iPodTouch5", "comment", "image", ["iPod5,1"], 4, (9,16), "iPod touch (5th generation)", "iPod touch (5th generation)", 326, cpu="a5", cameras=1)"#
		let legacy = #"Device("iPodTouch5", "comment", "image", ["iPod5,1"], 4, (9,16), "iPod touch (5th generation)", "iPod touch (5th generation)", 326, False, False, False, False, False, False, False, False, False, False, 0, False, 1, False, "a5", False, False)"#
		for record in try DeviceKitLoader.parse(named) + DeviceKitLoader.parse(legacy) {
			#expect(!record.hasEsimSupport)
			#expect(!record.hasDualEsimSupport)
			#expect(!record.isFoldable)
			#expect(try DeviceKitLoader.parse(record.source).first == record)
		}
	}

	/// Named schema flags and every compact Pencil encoding survive parsing and source export.
	@Test func namedFlagsAndPencilEncodingsRoundTrip() throws {
		let source = #"Device("iPhone16", "comment", "image", ["iPhone16,1"], 6.1, (9,19), "iPhone 16 Pro", "iPhone 16 Pro", 460, cpu="a18pro", hasEsimSupport=True, hasDualEsimSupport=True, isFoldable=True)"#
		let parsed = try DeviceKitLoader.parse(source)
		#expect(parsed.count == 1)
		#expect(parsed[0].hasEsimSupport)
		#expect(parsed[0].hasDualEsimSupport)
		#expect(parsed[0].isFoldable)
		#expect(try DeviceKitLoader.parse(parsed[0].source) == parsed)

		for (encoding, pencils) in Set<ApplePencil>.deviceKitMap {
			#expect(Set<ApplePencil>(deviceKitPencilSupport: encoding) == pencils)
			#expect(pencils.deviceKitPencilSupport == encoding)
		}
	}

	/// Device-to-DeviceKit bridging reflects eSIM, dual-eSIM, multi-panel foldable, and Pencil state.
	@Test func deviceCapabilitiesBridgeToDeviceKitFields() throws {
		let template = try DeviceKitLoader.parse(
			#"Device("iPodTouch5", "comment", "image", ["iPod5,1"], 4, (9,16), "iPod touch (5th generation)", "iPod touch (5th generation)", 326, cpu="a5", cameras=1)"#
		).first!
		let phone = Device(identifier: "iPhone16,1")
		let phoneBridge = template.bridge(from: phone)
		#expect(phoneBridge.hasEsimSupport == phone.has(.esim))
		#expect(phoneBridge.hasDualEsimSupport == phone.has(.dualesim))
		#expect(!phoneBridge.isFoldable)
		#expect(try DeviceKitLoader.parse(phoneBridge.source).first == phoneBridge)

		let duo = Device(identifier: "iPhone19,4")
		let duoBridge = template.bridge(from: duo)
		#expect(duoBridge.isFoldable == (duo.screens.count > 1))
		#expect(duoBridge.isFoldable)
		#expect(try DeviceKitLoader.parse(duoBridge.source).first == duoBridge)

		let ipad = Device(identifier: "iPad16,3")
		let pencilBridge = template.bridge(from: ipad)
		#expect(pencilBridge.applePencilSupport == ipad.capabilities.pencils.deviceKitPencilSupport)
		#expect(try DeviceKitLoader.parse(pencilBridge.source).first?.applePencilSupport == pencilBridge.applePencilSupport)
	}
}
#endif
