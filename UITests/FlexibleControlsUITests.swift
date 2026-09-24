import UIKit
import XCTest

final class FlexibleControlsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testFlexibleZonesOutsideRestingArtworkAndLifecycle() throws {
        XCUIDevice.shared.orientation = UIDevice.current.userInterfaceIdiom == .pad ? .landscapeLeft : .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-unlock-test-id", UUID().uuidString,
                               "-audio.muted", "YES", "-world", "canyon"]
        app.launch()
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["startEndless"].waitForExistence(timeout: 15))
        app.buttons["startEndless"].tap()
        let throttle = app.buttons["throttle"], brake = app.buttons["brake"]
        XCTAssertTrue(throttle.waitForExistence(timeout: 5))
        XCTAssertTrue(throttle.isHittable && brake.isHittable)
        let initialThrottle = throttle.frame, initialBrake = brake.frame
        let pause = app.buttons["pause"]
        let viewport = app.windows.firstMatch.frame
        let diameter: CGFloat = viewport.width > viewport.height ? 124 : 112
        for pedal in [throttle, brake] {
            XCTAssertGreaterThanOrEqual(pedal.frame.height, 144)
            XCTAssertGreaterThan(pedal.frame.width * pedal.frame.height, diameter * diameter)
            XCTAssertTrue(viewport.contains(pedal.frame), "Contact zones must stay within the viewport safe layout")
            XCTAssertEqual(pedal.value as? String, "Released")
        }
        XCTAssertLessThan(brake.frame.maxX, pause.frame.minX)
        XCTAssertGreaterThan(throttle.frame.minX, pause.frame.maxX)
        capture("flexible-zones-resting")
        let before = distance(app)
        // This point is well above the resting image, but within the broader right zone.
        let start = throttle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12))
        let end = throttle.coordinate(withNormalizedOffset: CGVector(dx: 0.10, dy: 0.82))
        let firstY = throttle.frame.minY + throttle.frame.height * 0.12
        XCTAssertLessThan(firstY, throttle.frame.maxY - diameter,
                          "The gesture must begin outside the old fixed button")
        start.press(forDuration: 0.45, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0.15)
        XCTAssertEqual(throttle.value as? String, "Released")
        XCTAssertEqual(throttle.frame, initialThrottle, "Only artwork moves; the accessible contact zone stays fixed")
        let advanced = NSPredicate { _, _ in self.distance(app) > before }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: advanced, object: nil)], timeout: 5), .completed)
        brake.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).press(forDuration: 0.25)
        XCTAssertEqual(brake.value as? String, "Released")
        XCTAssertEqual(brake.frame, initialBrake)
        capture("flexible-zones-released")
        pause.tap()
        XCTAssertTrue(app.buttons["resume"].waitForExistence(timeout: 5))
        XCTAssertFalse(throttle.isHittable)
        app.buttons["resume"].tap()
        XCTAssertTrue(throttle.waitForExistence(timeout: 5))
        XCTAssertEqual(throttle.value as? String, "Released")
        XCTAssertEqual(brake.value as? String, "Released")
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["startEndless"].waitForExistence(timeout: 10))
        app.buttons["startEndless"].tap()
        XCTAssertTrue(throttle.waitForExistence(timeout: 5))
        XCTAssertEqual(throttle.value as? String, "Released", "Background must not retain a previous thumb")
        XCTAssertEqual(brake.value as? String, "Released")
    }

    @MainActor private func distance(_ app: XCUIApplication) -> Int {
        Int(app.staticTexts["distance"].label.filter(\.isNumber)) ?? 0
    }

    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
