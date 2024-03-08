#if canImport(XCTest) && canImport(Device)
@testable import Device
import XCTest

final class DeviceTests: XCTestCase {
    func testDeviceOutput() async throws {
        // TODO: Clearly this needs work.  If someone wants to replace this with good tests, it would be very much appreciated!
        print(Device.current.description)
        XCTAssert(Device.current.description == Device(identifier: "iPad16,2").description, "Device test")
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        if let battery = Device.current.battery {
            XCTAssertEqual(String(describing: battery), String(describing: Battery.current))
        }
    }
}
#endif
