import XCTest

/// Exercises the development app's keyboard unlock, test navigation, and animated mock in one launch.
final class DeviceUITests: XCTestCase {
	@MainActor
	func testDevelopmentFlowsInSingleAppLaunch() async throws {
		let app = launchApp()

		// Unlock developer options through the five-character keyboard window.
		let input = app.textFields["KeyboardDiagnosticsInput"]
		await scrollIntoView(input, in: app.scrollViews.firstMatch)
		XCTAssertTrue(input.waitForExistence(timeout: 10), "The keyboard diagnostic input should be visible.")
		input.clickOrTap()
		input.typeText("kudit")
		let toggle = app.checkBoxes["DeveloperOptionsToggle"]
		let debugSheetOpened = await waitForElement(toggle, timeout: 5)
		XCTAssertTrue(debugSheetOpened, "Typing the unlock word should show the developer-mode sheet.")
		if !isOn(toggle) {
			toggle.clickOrTap()
			if !isOn(toggle) {
				toggle.typeKey(" ", modifierFlags: [])
			}
		}
		let developerModeEnabled = await waitForValue(toggle, timeout: 3)
		XCTAssertTrue(developerModeEnabled, "The developer-mode toggle should be on before dismissing its sheet.")
		let done = app.buttons["DeveloperOptionsDone"]
		XCTAssertTrue(done.waitForExistence(timeout: 5), "The developer-mode sheet should provide a Done button.")
		done.clickOrTap()
		let debugSheetDismissed = await waitForElementToDisappear(toggle, timeout: 5)
		XCTAssertTrue(debugSheetDismissed, "Done should dismiss the developer-mode sheet.")

		// Dismissing the sheet removes text-field focus on macOS, so reacquire it before typing.
		input.clickOrTap()
		input.typeText("asdf")
		let completeKeyboardWindow = app.staticTexts.matching(
			NSPredicate(format: "identifier == %@ AND value == %@", "KeyboardInputWindow", "Recent keys: asdf")
		).firstMatch
		let capturedAllKeys = await waitForElement(completeKeyboardWindow, timeout: 5)
		XCTAssertTrue(capturedAllKeys, "The keyboard stream should retain all four rapidly typed keys.")
		for character in ["a", "s", "d", "f"] {
			let event = app.staticTexts.matching(
				NSPredicate(format: "identifier == %@ AND value CONTAINS[c] %@", "KeyboardInputEvent", "[\(character)]")
			).firstMatch
			let didReportCharacter = await waitForElement(event, timeout: 2)
			XCTAssertTrue(didReportCharacter, "The keyboard event log should report \(character).")
		}

		let batteryLink = app.buttons["BatteryTestsLink"]
		await scrollIntoView(batteryLink, in: app.scrollViews.firstMatch)
		XCTAssertTrue(batteryLink.waitForExistence(timeout: 10), "The app should show its battery option.")
		batteryLink.clickOrTap()
		let lowPowerMode = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Low Power Mode")).firstMatch
		var batteryGalleryOpened = await waitForElement(lowPowerMode, timeout: 3)
		if !batteryGalleryOpened && batteryLink.exists && batteryLink.isHittable {
			batteryLink.clickOrTap()
			batteryGalleryOpened = await waitForElement(lowPowerMode, timeout: 7)
		}
		XCTAssertTrue(batteryGalleryOpened, "The battery gallery should open from its app link.\n\(app.debugDescription)")
		attachScreenshot(app, named: "Battery palette order and rendering regression")
		let returnedFromBatteryTests = await navigateBack(in: app)
		XCTAssertTrue(returnedFromBatteryTests, "The battery test screen should provide a working back action.")

		let mocksLink = app.buttons["DeviceMocksLink"]
		await scrollIntoView(mocksLink, in: app.scrollViews.firstMatch)
		XCTAssertTrue(mocksLink.waitForExistence(timeout: 10), "The main screen should link to mock device tests.")
		mocksLink.clickOrTap()
		let pose = app.descendants(matching: .any).matching(identifier: "AnimatedMockPoseValue").firstMatch
		let poseAppeared = await waitForElement(pose, timeout: 10)
		XCTAssertTrue(poseAppeared, "The mock test screen should include live pose information.")
		let initialPose = accessibilityText(of: pose)
		let orientation = app.descendants(matching: .any).matching(identifier: "AnimatedMockOrientationValue").firstMatch
		let orientationAppeared = await waitForElement(orientation, timeout: 5)
		XCTAssertTrue(orientationAppeared, "The mock test screen should include live orientation information.")
		let initialOrientation = accessibilityText(of: orientation)
		let poseDeadline = Date().addingTimeInterval(15)
		while Date() < poseDeadline && (accessibilityText(of: pose) == initialPose || accessibilityText(of: orientation) == initialOrientation) {
			try? await Task.sleep(nanoseconds: 100_000_000)
		}
		XCTAssertNotEqual(accessibilityText(of: pose), initialPose, "The mock screen state should animate through pose combinations.")
		XCTAssertNotEqual(accessibilityText(of: orientation), initialOrientation, "The mock screen should animate through matching orientation combinations.")
		let returnedFromMockTests = await navigateBack(in: app)
		XCTAssertTrue(returnedFromMockTests, "The mock test screen should provide a working back action.")

		let allTestsLink = app.descendants(matching: .any).matching(identifier: "AllTestsLink").firstMatch
		await scrollIntoView(allTestsLink, in: app.scrollViews.firstMatch)
		XCTAssertTrue(allTestsLink.waitForExistence(timeout: 10), "Developer mode should expose All Tests.")
		allTestsLink.clickOrTap()
		let deviceHeading = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Device v")).firstMatch
		await scrollIntoView(deviceHeading, in: app.scrollViews.firstMatch)
		let deviceHeadingAppeared = await waitForElement(deviceHeading, timeout: 10)
		XCTAssertTrue(deviceHeadingAppeared, "All Tests should display Device's module heading.\n\(app.debugDescription)")
	}

	@MainActor
	private func launchApp() -> XCUIApplication {
		let app = XCUIApplication()
		app.launchArguments += ["-ApplePersistenceIgnoreState", "YES"]
		app.launchEnvironment["DEVICE_UI_TESTING"] = "1"
		app.launch()
#if os(macOS)
		app.activate()
#endif
		return app
	}

	@MainActor
	private func scrollIntoView(_ element: XCUIElement, in scrollView: XCUIElement) async {
		let deadline = Date().addingTimeInterval(10)
		while Date() < deadline {
			if element.exists && element.isHittable { return }
			if element.exists { scrollView.swipeUp() }
			try? await Task.sleep(nanoseconds: 100_000_000)
		}
	}

	@MainActor
	private func waitForElement(_ element: XCUIElement, timeout: TimeInterval) async -> Bool {
		let deadline = Date().addingTimeInterval(timeout)
		while Date() < deadline {
			if element.exists { return true }
			try? await Task.sleep(nanoseconds: 100_000_000)
		}
		return element.exists
	}

	@MainActor
	private func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval) async -> Bool {
		let deadline = Date().addingTimeInterval(timeout)
		while Date() < deadline {
			if !element.exists { return true }
			try? await Task.sleep(nanoseconds: 100_000_000)
		}
		return !element.exists
	}

	@MainActor
	private func waitForValue(_ element: XCUIElement, timeout: TimeInterval) async -> Bool {
		let deadline = Date().addingTimeInterval(timeout)
		while Date() < deadline {
			if isOn(element) { return true }
			try? await Task.sleep(nanoseconds: 100_000_000)
		}
		return isOn(element)
	}

	@MainActor
	private func isOn(_ element: XCUIElement) -> Bool {
		if let value = element.value as? NSNumber { return value.boolValue }
		let value = (element.value as? String)?.lowercased()
		return value == "1" || value == "on" || value == "yes"
	}

	@MainActor
	private func accessibilityText(of element: XCUIElement) -> String {
		(element.value as? String) ?? element.label
	}

	@MainActor
	private func navigateBack(in app: XCUIApplication) async -> Bool {
		let navigationBarBack = app.navigationBars.buttons.firstMatch
		let labeledBack = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Back")).firstMatch
		let previousScreenButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Device.swift v")).firstMatch
		for button in [navigationBarBack, labeledBack, previousScreenButton] {
			if button.exists && button.isHittable {
				button.clickOrTap()
				return true
			}
		}
		return false
	}

	@MainActor
	private func attachScreenshot(_ app: XCUIApplication, named name: String) {
		let attachment = XCTAttachment(screenshot: app.screenshot())
		attachment.name = name
		attachment.lifetime = .keepAlways
		add(attachment)
	}
}

private extension XCUIElement {
	func clickOrTap() {
#if os(macOS)
		click()
#else
		tap()
#endif
	}
}
