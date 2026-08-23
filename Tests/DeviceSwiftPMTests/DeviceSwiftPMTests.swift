// MARK: - Swift Package Manager regression tests
// These deterministic tests stay outside the Swift Playgrounds app target so
// Swift Package Index can detect real tests without tying results to the host device.

#if compiler(>=5.9) && canImport(Device) && canImport(Testing)
import CompatibilityTesting
import Device
import Testing

/// Presents Device's reusable Compatibility tests as individually named Swift Testing arguments.
@Suite("Device Tests")
struct DeviceSwiftPMTests {
    /// Runs the same ordered reusable tests used by Compatibility's in-app test UI.
    @Test(
        "Reusable Device test",
        .serialized,
        arguments: await MainActor.run {
            ModuleTestEntry.entries(for: DeviceKit.self, tests: DeviceKit.tests)
        }
    )
    @MainActor
    @available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *)
    func reusableDeviceTest(_ entry: ModuleTestEntry) async throws {
        try await entry.execute()
    }
}
#endif
