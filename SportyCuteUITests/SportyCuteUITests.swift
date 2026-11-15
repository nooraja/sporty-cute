import XCTest

@MainActor
final class SportyCuteUITests: XCTestCase {
    func testDemoRacePlaysCheerAndOpensReplay() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["race.start"].exists)
        app.buttons["race.start"].tap()
        app.buttons["race.nextCheckpoint"].tap()
        XCTAssertTrue(app.staticTexts["Playing Mia’s cheer"].waitForExistence(timeout: 3))

        let finish = app.buttons["race.finish"]
        if !finish.isHittable { app.swipeUp() }
        finish.tap()
        app.buttons["Finish and view replay"].tap()
        XCTAssertTrue(app.staticTexts["vault.recap"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["1 reached"].exists)
        XCTAssertTrue(app.staticTexts["1 played"].exists)
    }

    func testTriathlonChangesLegsInOrder() {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Triathlon"].tap()
        app.buttons["race.start"].tap()
        XCTAssertEqual(app.staticTexts["race.currentLeg"].label, "Swim leg")
        app.buttons["race.transition"].tap()
        XCTAssertEqual(app.staticTexts["race.currentLeg"].label, "Bike leg")
        app.buttons["race.transition"].tap()
        XCTAssertEqual(app.staticTexts["race.currentLeg"].label, "Keep it moving.")
        XCTAssertFalse(app.buttons["race.transition"].exists)
    }
}
