// The package test target is intentionally a thin bridge: reusable assertions live
// in Device.tests so Compatibility can run them in apps, while SwiftPM can still
// discover and execute the complete dependency graph from one conventional target.
#if compiler(>=5.9) && canImport(Testing)
import CompatibilityTesting
import Device
import Testing

/// Runs every reusable Device and dependency test through Compatibility's shared adapter.
@Suite
struct DeviceTests {
    @Test("Device Module Tests", arguments: await Device.testEntries())
    @MainActor
    @available(iOS 13, macOS 12, tvOS 13, watchOS 6, *)
    func moduleTests(entry: ModuleTestEntry) async throws {
        try await entry.execute()
    }
}
#endif
