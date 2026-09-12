import XCTest

final class TouchGrassFlowTests: XCTestCase {
    func testGuidedMovementStartsFromToday() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-ui-tests"]
        app.launch()
        XCTAssertTrue(app.buttons["Enable break reminders"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Snooze 10 min"].exists)
        app.buttons["Move indoors"].tap()
        XCTAssertTrue(app.buttons["Start routine"].waitForExistence(timeout: 5))
        app.buttons["Start routine"].tap()
        XCTAssertTrue(app.buttons["Complete break"].exists)
        app.buttons["Complete break"].tap()
        XCTAssertTrue(app.buttons["Step outside"].waitForExistence(timeout: 5))
    }

    func testMultiExerciseRoutineCompletesOnlyAfterLastStep() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-ui-tests"]
        app.launch()
        app.tabBars.buttons["Move"].tap()
        app.staticTexts["Upper Body & Posture"].tap()
        XCTAssertTrue(app.buttons["Start routine"].waitForExistence(timeout: 5))
        app.buttons["Start routine"].tap()
        XCTAssertFalse(app.buttons["Complete break"].exists)
        XCTAssertTrue(app.buttons["End routine"].exists)
        for _ in 0..<3 {
            app.buttons["Next exercise"].tap()
        }
        XCTAssertTrue(app.buttons["Complete break"].exists)
        XCTAssertFalse(app.buttons["Next exercise"].exists)
        app.buttons["Complete break"].tap()
        XCTAssertTrue(app.navigationBars["A little movement"].waitForExistence(timeout: 5))
    }

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
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "1 break")).firstMatch.exists)
        app.tabBars.buttons["Move"].tap()
        XCTAssertTrue(app.navigationBars["A little movement"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.switches["Reminders enabled"].waitForExistence(timeout: 5))
    }
}
