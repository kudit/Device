#if canImport(XCTest) && canImport(Device)
@testable import Device
import XCTest

final class DeviceTests: XCTestCase {
    func testDeviceOutput() async throws {
        // TODO: Clearly this needs work.  If someone wants to replace this with good tests, it would be very much appreciated!
        print("Current description: \(Device.current.name ?? "Unknown")")
        print("Created description: \(Device(identifier: "iPhone16,1").name)")
        XCTAssert(Device.current.name == Device(identifier: "iPhone16,1").name, "Device test")
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        if let battery = Device.current.battery {
            XCTAssertEqual(String(describing: battery), String(describing: DeviceBattery.current))
        }
    }
}
#endif
