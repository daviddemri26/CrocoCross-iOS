import UIKit
import XCTest

final class MiloRiderUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testMiloLockedProgressAndThirdCatalogPosition() throws {
        let app = launch(backflips: 1)
        defer { app.terminate() }
        for iteration in 0..<2 {
            let milo = openMilo(in: app)
            XCTAssertFalse(milo.isEnabled)
            XCTAssertEqual(milo.label, "Milo, Locked")
            XCTAssertEqual(milo.value as? String, "Land 2 backflips to unlock Milo, 1 / 2")
            let kenji = app.buttons["select-shiba"]
            let duke = app.buttons["select-eagle"]
            XCTAssertTrue(kenji.exists && duke.exists, "Existing riders remain in the catalog")
            assertPrecedes(kenji, milo)
            assertPrecedes(milo, duke)
            capture("milo-locked-third-position-\(iteration)")
            app.buttons["closePanel"].tap()
            waitForHome(app)
            XCTAssertEqual(app.buttons["riders"].label, "Rider: Rocco")
            if iteration == 0 { app.terminate(); app.launch(); waitForHome(app) }
        }
    }

    @MainActor func testMiloClaimRevealRideAndPersistence() throws {
        let app = launch(backflips: 2)
        defer { app.terminate() }
        let milo = openMilo(in: app)
        XCTAssertTrue(milo.isEnabled)
        XCTAssertEqual(milo.label, "Milo, Ready to unlock")
        XCTAssertEqual(milo.value as? String, "Land 2 backflips to unlock Milo, 2 / 2")
        capture("milo-ready-to-unlock")
        milo.tap()
        let ride = app.buttons["rideWithMilo"]
        XCTAssertTrue(ride.waitForExistence(timeout: 8))
        revealAction(ride, in: app)
        XCTAssertEqual(app.staticTexts["miloUnlockTitle"].label, "MILO UNLOCKED")
        capture("milo-unlock-reveal")
        ride.tap()
        waitForHome(app)
        XCTAssertEqual(app.buttons["riders"].label, "Rider: Milo")
        capture("milo-selected-home")
        app.buttons["startEndless"].tap()
        waitForPlaying(app)
        app.buttons["throttle"].press(forDuration: 0.4)
        capture("milo-first-ride")
        goHomeFromRide(app)

        app.terminate()
        if let index = app.launchArguments.firstIndex(of: "-rider.box2d-1") {
            app.launchArguments.removeSubrange(index...index + 1)
        }
        app.launch()
        waitForHome(app)
        XCTAssertEqual(app.buttons["riders"].label, "Rider: Milo")
        let saved = openMilo(in: app)
        XCTAssertTrue(saved.isSelected)
        XCTAssertEqual(saved.label, "Milo")
        XCTAssertFalse(app.buttons["rideWithMilo"].exists, "The completed reveal does not replay")
        let kenji = app.buttons["select-shiba"]
        revealAction(kenji, in: app)
        XCTAssertEqual(kenji.label, "Kenji, Ready to unlock", "Milo's claim does not automatically claim Kenji")
        capture("milo-persisted-independent-claim")
        let rocco = app.buttons["select-croco"]
        revealAction(rocco, in: app)
        rocco.tap()
        waitForHome(app)
    }

    @MainActor func testMiloInterruptedRevealPreservesClaim() throws {
        let app = launch(backflips: 2)
        defer { app.terminate() }
        openMilo(in: app).tap()
        XCTAssertTrue(app.staticTexts["miloUnlockTitle"].waitForExistence(timeout: 3))
        app.terminate()
        app.launch()
        waitForHome(app)
        let milo = openMilo(in: app)
        XCTAssertTrue(milo.isEnabled)
        XCTAssertEqual(milo.label, "Milo", "The claim is saved before its animation begins")
        XCTAssertFalse(app.buttons["rideWithMilo"].exists)
        capture("milo-interrupted-reveal-restored")
    }

    @MainActor func testMiloRealBackflipsAccumulateAcrossModes() throws {
        let app = launch(extras: ["-unlock-landing-preview"])
        defer { app.terminate() }
        for (mode, count) in [("startWeekly", 1), ("startEndless", 2)] {
            app.buttons[mode].tap()
            waitForPlaying(app)
            waitForSafeFlip(app)
            app.buttons["pause"].tap()
            XCTAssertTrue(app.buttons["resume"].waitForExistence(timeout: 5))
            app.buttons["resume"].tap()
            waitForPlaying(app)
            goHomeFromRide(app)
            let milo = openMilo(in: app)
            XCTAssertEqual(milo.value as? String, "Land 2 backflips to unlock Milo, \(count) / 2")
            XCTAssertEqual(milo.isEnabled, count == 2, "Pausing and returning home cannot count a reception twice")
            capture("milo-safe-backflip-\(count)")
            app.buttons["closePanel"].tap()
            waitForHome(app)
        }
        app.terminate()
        app.launch()
        waitForHome(app)
        XCTAssertEqual(openMilo(in: app).label, "Milo, Ready to unlock")
    }

    @MainActor func testFrontflipDoesNotAdvanceMilo() throws {
        let app = launch(extras: ["-world-unlock-landing-preview"])
        defer { app.terminate() }
        app.buttons["startEndless"].tap()
        waitForPlaying(app)
        waitForSafeFlip(app)
        goHomeFromRide(app)
        let milo = openMilo(in: app)
        XCTAssertFalse(milo.isEnabled)
        XCTAssertEqual(milo.value as? String, "Land 2 backflips to unlock Milo, 0 / 2")
        capture("milo-frontflip-does-not-count")
    }

    @MainActor func testMiloRidesJunglePlatformsAndWeeklyKeepsRiderOnCanyon() throws {
        let app = launch(backflips: 2, extras: [
            "-milo-unlock-fixture-claimed", "-jungle-unlock-fixture-claimed", "-jungle-course-preview",
            "-scenery-seed", "5"
        ])
        defer { app.terminate() }
        let milo = openMilo(in: app)
        XCTAssertEqual(milo.label, "Milo")
        capture("milo-claimed-catalog")
        milo.tap()
        waitForHome(app)
        XCTAssertEqual(app.buttons["riders"].label, "Rider: Milo")

        app.buttons["worlds"].tap()
        let jungle = app.buttons["select-jungle"]
        XCTAssertTrue(jungle.waitForExistence(timeout: 5))
        revealAction(jungle, in: app)
        XCTAssertEqual(jungle.label, "Tropical Jungle")
        jungle.tap()
        waitForHome(app)
        XCTAssertEqual(app.buttons["riders"].label, "Rider: Milo")
        XCTAssertEqual(app.buttons["worlds"].label, "World: Tropical Jungle")
        capture("milo-jungle-selected-home")

        app.buttons["startEndless"].tap()
        waitForPlaying(app)
        XCTAssertEqual(app.staticTexts["activeWorld"].label, "Tropical Jungle")
        // The fixture reaches the first ledge with real physics, then waits for a pedal press.
        let distanceBefore = Int(app.staticTexts["distance"].label.filter(\.isNumber)) ?? 0
        capture("milo-jungle-first-platform-before-input")
        app.buttons["throttle"].press(forDuration: 0.5)
        let advanced = NSPredicate { _, _ in
            (Int(app.staticTexts["distance"].label.filter(\.isNumber)) ?? 0) > distanceBefore
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: advanced, object: nil)], timeout: 3), .completed,
                       "The pedal releases the fixture and moves Milo through the actual Jungle physics")
        capture("milo-jungle-first-platform-in-motion")
        goHomeFromRide(app)
        XCTAssertEqual(app.buttons["riders"].label, "Rider: Milo")

        app.buttons["startWeekly"].tap()
        waitForPlaying(app)
        XCTAssertEqual(app.staticTexts["activeWorld"].label, "Canyon")
        capture("milo-weekly-keeps-rider-on-canyon")
        goHomeFromRide(app)
        XCTAssertEqual(app.buttons["riders"].label, "Rider: Milo", "Weekly preserves the selected rider")
        XCTAssertEqual(app.buttons["worlds"].label, "World: Tropical Jungle", "Weekly does not replace the selected Endless world")
    }

    @MainActor private func launch(backflips: Int = 0, extras: [String] = []) -> XCUIApplication {
        XCUIDevice.shared.orientation = UIDevice.current.userInterfaceIdiom == .pad ? .landscapeLeft : .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-unlock-test-id", UUID().uuidString,
            "-unlock-fixture-backflips", String(backflips), "-world-unlock-test-id", UUID().uuidString,
            "-weekly-record-test-id", UUID().uuidString, "-audio.muted", "YES",
            "-rider.box2d-1", "croco", "-world", "canyon"] + extras
        app.launch()
        waitForHome(app)
        return app
    }

    @MainActor private func openMilo(in app: XCUIApplication) -> XCUIElement {
        app.buttons["riders"].tap()
        let milo = app.buttons["select-monkey"]
        XCTAssertTrue(milo.waitForExistence(timeout: 5))
        revealAction(milo, in: app)
        return milo
    }

    @MainActor private func assertPrecedes(_ first: XCUIElement, _ second: XCUIElement) {
        XCTAssertLessThanOrEqual(first.frame.minY, second.frame.minY)
        if abs(first.frame.minY - second.frame.minY) < 1 { XCTAssertLessThan(first.frame.minX, second.frame.minX) }
    }

    @MainActor private func waitForHome(_ app: XCUIApplication) {
        let ready = NSPredicate { _, _ in
            app.state == .runningForeground && app.buttons["startWeekly"].exists
                && app.buttons["startWeekly"].isHittable && app.buttons["riders"].isHittable
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: nil)], timeout: 15), .completed)
    }

    @MainActor private func waitForPlaying(_ app: XCUIApplication) {
        let playing = NSPredicate { _, _ in
            app.buttons["throttle"].exists && app.buttons["throttle"].isHittable
                && !app.buttons["resume"].exists && !app.buttons["rideAgain"].exists
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: playing, object: nil)], timeout: 8), .completed)
    }

    @MainActor private func waitForSafeFlip(_ app: XCUIApplication) {
        let landed = NSPredicate { _, _ in
            app.staticTexts["score"].exists && (Int(app.staticTexts["score"].label.filter(\.isNumber)) ?? 0) >= 1_000
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: landed, object: nil)], timeout: 10), .completed,
                       "A real safe reception must receive the core flip score")
    }

    @MainActor private func goHomeFromRide(_ app: XCUIApplication) {
        app.buttons["pause"].tap()
        XCTAssertTrue(app.buttons["resume"].waitForExistence(timeout: 5))
        app.buttons["home"].tap()
        waitForHome(app)
    }

    @MainActor private func revealAction(_ element: XCUIElement, in app: XCUIApplication) {
        let window = app.windows.firstMatch.frame
        let navigation = app.navigationBars.firstMatch
        let top = navigation.exists ? navigation.frame.maxY + 12 : window.minY + 24
        let close = app.buttons["closePanel"]
        let bottom = close.exists ? close.frame.minY - 10 : window.maxY - 24
        let x = navigation.exists ? navigation.frame.minX + 28 : window.midX
        for _ in 0..<12 {
            let frame = element.exists ? element.frame : .zero
            if element.exists && frame.height > 0 && frame.minY >= top && frame.maxY <= bottom { return }
            let down = element.exists && frame.height > 0 && frame.minY < top
            let middle = (top + bottom) / 2
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: x, dy: middle + (down ? -55 : 55)))
            let end = origin.withOffset(CGVector(dx: x, dy: middle + (down ? 55 : -55)))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.05)
        }
        XCTFail("The complete control must be visible: \(element.identifier)")
    }

    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
