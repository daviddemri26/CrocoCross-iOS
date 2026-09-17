import UIKit
import XCTest

/// Real UI captures from the Release app; no injected scores, riders or scenery.
final class AppStoreCaptureTests: XCTestCase {
    @MainActor func testCaptureStoreScreens() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = UIDevice.current.userInterfaceIdiom == .pad ? .landscapeLeft : .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-audio.muted", "YES", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["startWeekly"].waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 1)
        shot("03-home")
        app.buttons["help"].tap()
        XCTAssertTrue(app.navigationBars["How to play"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)
        shot("04-controls")
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.4)
        shot("06-scoring-guide")
        app.buttons["closePanel"].tap()
        app.buttons["settings"].tap()
        XCTAssertTrue(app.buttons["settings.tab.audio"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.4)
        shot("05-audio")
        app.buttons["closePanel"].tap()
        app.buttons["startWeekly"].tap()
        XCTAssertTrue(app.buttons["throttle"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.3)
        app.buttons["throttle"].press(forDuration: 1.6)
        if app.buttons["resume"].exists { app.buttons["resume"].tap() }
        shot("01-weekly-ride")
        if app.buttons["pause"].isHittable { app.buttons["pause"].tap() }
        XCTAssertTrue(app.buttons["home"].waitForExistence(timeout: 8))
        app.buttons["home"].tap()
        XCTAssertTrue(app.buttons["startEndless"].waitForExistence(timeout: 5))
        app.buttons["startEndless"].tap()
        XCTAssertTrue(app.buttons["throttle"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.3)
        app.buttons["throttle"].press(forDuration: 2.0)
        if app.buttons["resume"].exists { app.buttons["resume"].tap() }
        shot("02-endless-ride")
    }

    @MainActor private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = "appstore-" + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
