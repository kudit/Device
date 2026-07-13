// MARK: - Swift Package Manager regression tests
// These deterministic XCTest cases stay outside the Swift Playgrounds app target so
// Swift Package Index can detect real tests without tying results to the host device.

import Device
import XCTest

final class DeviceSwiftPMTests: XCTestCase {
    /// Verifies identifier lookup returns stable public model information.
    func testKnownIdentifierLookup() {
        let device = Device(identifier: "iPhone16,1")

        XCTAssertEqual(device.idiom, .phone)
        XCTAssertTrue(device.identifiers.contains("iPhone16,1"))
        XCTAssertFalse(device.officialName.isEmpty)
    }

    /// Verifies unknown identifiers remain usable instead of failing lookup.
    func testUnknownIdentifierFallback() {
        let identifier = "FutureDevice99,1"
        let device = Device(identifier: identifier)

        XCTAssertTrue(device.identifiers.contains(identifier))
        XCTAssertEqual(device.idiom, .unspecified)
    }

    /// Verifies capability queries distinguish established hardware generations.
    func testCapabilityQueries() {
        let fiveGPhone = Device(identifier: "iPhone13,2")
        let earlierPhone = Device(identifier: "iPhone12,1")

        XCTAssertEqual(fiveGPhone.cellular, .fiveG)
        XCTAssertNotEqual(earlierPhone.cellular, .fiveG)
        XCTAssertTrue(fiveGPhone.has(.gps))
    }

    /// Verifies fuzzy lookup limits an explicit Apple Watch name to watch models.
    func testLookupFiltersByProductFamily() {
        let matches = Device.lookup(
            officialNameHint: "Apple Watch Series 10 (GPS + Cellular) 42mm"
        )

        XCTAssertFalse(matches.isEmpty)
        XCTAssertTrue(matches.allSatisfy { $0.idiom == .watch })
    }
}
