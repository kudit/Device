//
//  DeviceTestUITests.swift
//  DeviceTestUITests
//
//  Created by Ben Ku on 4/12/24.
//

import XCTest

final class DeviceTestUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() async throws {
        // UI tests must launch the application that they test.
        let app = await XCUIApplication()
        await app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let screenshot = await app.screenshot()
        
//        screenshot.quickExport
    }

//    func testLaunchPerformance() throws {
//        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
//            // This measures how long it takes to launch your application.
//            measure(metrics: [XCTApplicationLaunchMetric()]) {
//                await XCUIApplication().launch()
//            }
//        }
//    }
}
