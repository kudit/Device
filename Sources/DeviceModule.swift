//
//  DeviceModule.swift
//
//  Shared module metadata and deterministic tests for the Device package.
//

import Color
import Compatibility

/// Package metadata and reusable tests for Device.
///
/// `DeviceKit` keeps module registration separate from the public `Device` value type while allowing
/// Compatibility's in-app test UI and Swift Testing bridge to execute one shared test catalog.
public enum DeviceKit: Module {
    /// Runtime version of the Device package.
    public static var version: Version { Device.version }

    /// Direct package dependencies used by Device.
    public static let dependencies: [Module.Type] = [Compatibility.self, ColorKit.self]

    /// Device currently has no immediately available package-specific diagnostic fields.
    public static let moduleInfo: [Field] = []

    /// Public source repository used for source discovery and opt-in license reporting.
    public static let openSourceRepository: String? = "https://github.com/kudit/Device"

    /// Human-readable package name shown in diagnostics and support reports.
    public static let moduleName = "Device"

    /// Stable identity independent of the marker type name.
    public static let moduleIdentifier = "com.kudit.Device"

#if compiler(>=5.9)
    /// Deterministic Device regression tests shared by every Compatibility test runner.
    @MainActor
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    public static let tests: OrderedDictionary<String, [TestCase]> = [
        "Lookup": [
            TestCase("Known identifiers return stable model information") {
                let device = Device(identifier: "iPhone16,1")

                try expectEqual(device.idiom, .phone)
                try expect(device.identifiers.contains("iPhone16,1"), "Expected the requested identifier to be preserved")
                try expect(!device.officialName.isEmpty, "Expected a known device to have an official name")
            },
            TestCase("Unknown identifiers remain usable") {
                let identifier = "FutureDevice99,1"
                let device = Device(identifier: identifier)

                try expect(device.identifiers.contains(identifier), "Expected an unknown identifier to be preserved")
                try expectEqual(device.idiom, .unspecified)
            },
            TestCase("Fuzzy lookup respects product family") {
                let matches = Device.lookup(
                    officialNameHint: "Apple Watch Series 10 (GPS + Cellular) 42mm"
                )

                try expect(!matches.isEmpty, "Expected the Apple Watch hint to return at least one match")
                try expect(matches.allSatisfy { $0.idiom == .watch }, "Expected an Apple Watch hint to return only watches")
            },
        ],
        "Capabilities": [
            TestCase("Capability queries distinguish hardware generations") {
                let fiveGPhone = Device(identifier: "iPhone13,2")
                let earlierPhone = Device(identifier: "iPhone12,1")

                try expectEqual(fiveGPhone.cellular, .fiveG)
                try expect(earlierPhone.cellular != .fiveG, "Expected the earlier phone not to report 5G")
                try expect(fiveGPhone.has(.gps), "Expected the known 5G phone to include GPS")
            },
        ],
    ]
#endif
}
