import XCTest
import UIKit

final class CrocoCrossUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor private func launch() -> XCUIApplication {
        if UIDevice.current.userInterfaceIdiom == .pad { XCUIDevice.shared.orientation = .landscapeLeft }
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["startWeekly"].waitForExistence(timeout: 15))
        return app
    }

    @MainActor func testWeeklyPauseRestoreAndNavigation() throws {
        let app = launch()
        app.buttons["startWeekly"].tap()
        if app.buttons["Replace saved ride"].waitForExistence(timeout: 1) { app.buttons["Replace saved ride"].tap() }
        waitForPlaying(app)
        app.buttons["throttle"].press(forDuration: 0.4)
        waitForPlaying(app)
        app.buttons["pause"].tap()
        waitForPaused(app)
        capture("weekly-paused")
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["continueRun"].waitForExistence(timeout: 10))
        app.buttons["continueRun"].tap()
        waitForPaused(app)
        app.buttons["resume"].tap()
        waitForPlaying(app)
        app.buttons["pause"].tap()
        waitForPaused(app)
        app.buttons["home"].tap()
        app.buttons["worlds"].tap()
        XCTAssertTrue(app.buttons["select-japan"].waitForExistence(timeout: 5))
        app.buttons["select-japan"].tap()
        capture("world-selection")
        app.buttons["closePanel"].tap()
        app.buttons["riders"].tap()
        XCTAssertTrue(app.buttons["select-shiba"].waitForExistence(timeout: 5))
        app.buttons["select-shiba"].tap()
        app.buttons["closePanel"].tap()
        capture("home-japan")
    }

    @MainActor func testAdaptiveLayoutAndSettings() throws {
        let app = launch()
        capture("home")
        app.buttons["settings"].tap()
        XCTAssertTrue(app.switches["Play music"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.sliders["Music volume"].exists)
        app.sliders["Music volume"].adjust(toNormalizedSliderPosition: 0.25)
        app.buttons["closePanel"].tap()
        app.buttons["startEndless"].tap()
        if app.buttons["Replace saved ride"].waitForExistence(timeout: 1) { app.buttons["Replace saved ride"].tap() }
        waitForPlaying(app)
        let distanceBeforeThrottle = try displayedDistance(app)
        capture("endless-start")
        app.buttons["throttle"].press(forDuration: 1.0)
        waitForPlaying(app)
        waitForDistance(app, greaterThan: distanceBeforeThrottle)
        XCTAssertGreaterThan(try displayedDistance(app), 0)
        waitForPlaying(app)
        capture("endless-ride")
        app.buttons["pause"].tap()
        waitForPaused(app)
    }

    @MainActor func testAudioVolumesSurviveChangesAndRelaunch() throws {
        let app = launch()
        app.buttons["settings"].tap()
        XCTAssertTrue(app.sliders["Music volume"].waitForExistence(timeout: 5))
        var storedValues: [String: String] = [:]
        for (label, value) in [("Music volume", 0.25), ("Engine", 0.5), ("Effects", 0.75)] {
            let slider = app.sliders[label]
            if !slider.isHittable { app.swipeUp() }
            XCTAssertTrue(slider.isHittable, "\(label) must be adjustable")
            slider.adjust(toNormalizedSliderPosition: CGFloat(value))
            storedValues[label] = try XCTUnwrap(slider.value as? String)
            XCTAssertEqual(app.state, .runningForeground, "Changing \(label) must not recurse or crash")
        }
        app.buttons["closePanel"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["startWeekly"].waitForExistence(timeout: 15), "Restoring saved audio settings must not crash startup")
        app.buttons["settings"].tap()
        XCTAssertTrue(app.sliders["Music volume"].waitForExistence(timeout: 5))
        for label in ["Music volume", "Engine", "Effects"] {
            let slider = app.sliders[label]
            if !slider.isHittable { app.swipeUp() }
            XCTAssertEqual(slider.value as? String, storedValues[label], "\(label) should survive relaunch")
        }
        capture("audio-settings-restored")
    }

    @MainActor func testViewportAndBackgroundLifecycle() throws {
        let app = launch()
        app.buttons["startEndless"].tap()
        if app.buttons["Replace saved ride"].waitForExistence(timeout: 1) { app.buttons["Replace saved ride"].tap() }
        waitForPlaying(app)
        app.buttons["throttle"].press(forDuration: 0.4)
        waitForPlaying(app)
        if UIDevice.current.userInterfaceIdiom == .pad {
            for (orientation, label) in [(UIDeviceOrientation.portrait, "portrait"), (.landscapeLeft, "landscape-left")] {
                waitForPlaying(app)
                let before = app.windows.firstMatch.frame
                XCUIDevice.shared.orientation = orientation
                var previousFrame: CGRect?
                let settled = NSPredicate { _, _ in
                    guard XCUIDevice.shared.orientation == orientation,
                          app.state == .runningForeground,
                          app.windows.firstMatch.exists else { return false }
                    let frame = app.windows.firstMatch.frame
                    guard frame.width > 0, frame.height > 0 else { return false }
                    defer { previousFrame = frame }
                    return previousFrame == frame
                }
                XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: settled, object: nil)], timeout: 8), .completed,
                               "The app window must settle after changing device orientation")
                let after = app.windows.firstMatch.frame
                let widthChange = abs(after.width - before.width)
                let heightChange = abs(after.height - before.height)
                let viewportChanged = widthChange > 30 || heightChange > 30
                let dimensions = XCTAttachment(string: "Device orientation: \(label)\nBefore: \(before.width) × \(before.height)\nAfter: \(after.width) × \(after.height)\nDelta: \(widthChange) × \(heightChange)\nActual viewport resize: \(viewportChanged)")
                dimensions.name = "viewport-\(label)-dimensions"
                dimensions.lifetime = .keepAlways
                add(dimensions)
                if viewportChanged {
                    waitForPaused(app)
                    capture("viewport-changed-paused")
                    app.buttons["resume"].tap()
                    waitForPlaying(app)
                } else {
                    waitForPlaying(app)
                    capture("viewport-unchanged-playing")
                }
            }
        }
        waitForPlaying(app)
        XCUIDevice.shared.press(.home)
        app.activate()
        waitForPaused(app)
        capture("paused-after-background")
        app.buttons["resume"].tap()
        waitForPlaying(app)
        app.buttons["pause"].tap()
        waitForPaused(app)
    }

    @MainActor private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }

    /// Gameplay controls remain in the accessibility tree underneath the pause/results overlay.
    /// Existence alone therefore cannot establish that a ride actually started or resumed.
    @MainActor private func waitForPlaying(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate { _, _ in
            let throttle = app.buttons["throttle"]
            return app.state == .runningForeground && throttle.exists && throttle.isHittable &&
                !app.buttons["resume"].exists && !app.buttons["rideAgain"].exists
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 8), .completed,
                       "The ride must be playing with a hittable throttle and no pause/results overlay", file: file, line: line)
        XCTAssertFalse(app.buttons["resume"].exists, file: file, line: line)
        XCTAssertFalse(app.buttons["rideAgain"].exists, file: file, line: line)
    }

    @MainActor private func waitForPaused(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate { _, _ in
            let resume = app.buttons["resume"]
            return resume.exists && resume.isHittable && !app.buttons["throttle"].isHittable
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 8), .completed,
                       "The ride must require explicit resume and its pedals must not be hittable", file: file, line: line)
    }

    @MainActor private func displayedDistance(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) throws -> Int {
        let label = app.staticTexts["distance"].label
        return try XCTUnwrap(Int(label.filter(\.isNumber)), "Distance HUD must expose a numeric value: \(label)", file: file, line: line)
    }

    @MainActor private func waitForDistance(_ app: XCUIApplication, greaterThan previous: Int,
                                          file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate { _, _ in
            let distance = app.staticTexts["distance"]
            guard distance.exists, let metres = Int(distance.label.filter(\.isNumber)) else { return false }
            return metres > previous && !app.buttons["resume"].exists && !app.buttons["rideAgain"].exists
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed,
                       "Holding the throttle must increase distance while the ride is still playing", file: file, line: line)
    }

    @MainActor func testAllRidersAndWorldsRenderAndPlay() throws {
        let app = launch()
        let pairs = [("croco", "canyon"), ("shiba", "japan"), ("eagle", "highway"),
                     ("tiger", "jungle"), ("polar", "arctic"), ("flamingo", "mine"),
                     ("toucan", "sanfrancisco"), ("raccoon", "paris"), ("axolotl", "clouds")]
        for (rider, world) in pairs {
            for (panel, selection) in [("worlds", world), ("riders", rider)] {
                app.buttons[panel].tap()
                let choice = app.buttons["select-\(selection)"]
                for _ in 0..<6 {
                    if choice.isHittable { break }
                    app.swipeUp()
                }
                XCTAssertTrue(choice.isHittable, "Missing selectable \(selection)")
                choice.tap(); app.buttons["closePanel"].tap()
            }
            capture("catalog-\(world)-\(rider)")
            app.buttons["startEndless"].tap()
            if app.buttons["Replace saved ride"].waitForExistence(timeout: 1) { app.buttons["Replace saved ride"].tap() }
            waitForPlaying(app)
            app.buttons["throttle"].press(forDuration: 0.45)
            waitForPlaying(app)
            capture("ride-\(world)-\(rider)")
            app.buttons["pause"].tap()
            waitForPaused(app)
            app.buttons["home"].tap()
        }
    }
}
