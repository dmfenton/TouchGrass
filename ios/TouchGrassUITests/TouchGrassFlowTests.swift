import XCTest

final class TouchGrassFlowTests: XCTestCase {
    func testHydrationAndCompletedBreakPersistAcrossLaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-ui-tests"]
        app.launch()
        XCTAssertTrue(app.buttons["Add a glass"].waitForExistence(timeout: 10))
        app.buttons["Add a glass"].tap()
        XCTAssertTrue(app.staticTexts["1 of 8 glasses"].exists)
        app.buttons["Step outside"].tap()
        XCTAssertTrue(app.buttons["I took a break"].waitForExistence(timeout: 5))
        app.buttons["I took a break"].tap()
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.staticTexts["1 of 8 glasses"].waitForExistence(timeout: 10))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["1 breaks · 1 day streak"].exists)
        app.tabBars.buttons["Move"].tap()
        XCTAssertTrue(app.navigationBars["A little movement"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.switches["Reminders enabled"].waitForExistence(timeout: 5))
    }
}
