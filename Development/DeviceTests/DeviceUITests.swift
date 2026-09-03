import XCTest

/// Exercises the Device sample app and its DEBUG-only Compatibility test catalog.
final class DeviceUITests: XCTestCase {
    /// Verifies that the shared All Tests screen is reachable from the sample app.
    @MainActor
    func testDeviceDemoAndAllTestsScreen() async throws {
        let app = XCUIApplication()
        // Ignore persisted navigation so the test always begins at the sample app root.
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES"]
        app.launchEnvironment["TESTING"] = "1"
        app.launch()
        // SwiftUI can expose a toolbar button as both an outer and inner accessibility node.
        // Selecting the first match avoids XCTest's single-element tap failure.
        let allTestsButton = app.buttons["All Tests"].firstMatch
        let allTestsButtonIsVisible = await waitForElement(allTestsButton, timeout: 10)
        XCTAssertTrue(allTestsButtonIsVisible, "The DEBUG All Tests button should be visible.")
        allTestsButton.tap()
        // The heading proves the registered Device module catalog rendered successfully.
        let deviceHeading = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@", "Device", "2.13")
        ).firstMatch
        let deviceHeadingIsVisible = await waitForElement(deviceHeading, timeout: 10)
        XCTAssertTrue(deviceHeadingIsVisible, "The All Tests screen should display Device's module heading.")
    }

    /// Polls asynchronously without blocking the UI-test actor.
    @MainActor
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            // Checking existence is sufficient here and avoids nested accessibility
            // interruption exceptions caused by probing SwiftUI's computed hit-testing state.
            if element.exists { return true }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return element.exists
    }
}
