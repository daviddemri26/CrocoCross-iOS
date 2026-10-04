import UIKit
import XCTest

final class JungleWorldUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testJungleProgressOrderAndClaimPersistence() throws {
        let app = launch(frontflips: 1)
        defer { app.terminate() }
        let jungle = openJungle(in: app)
        XCTAssertFalse(jungle.isEnabled)
        XCTAssertEqual(jungle.value as? String, "Land 2 frontflips to unlock Tropical Jungle, 1 / 2")
        let highway = app.buttons["select-highway"]
        XCTAssertTrue(highway.exists)
        XCTAssertLessThanOrEqual(jungle.frame.minY, highway.frame.minY)
        if jungle.frame.minY == highway.frame.minY { XCTAssertLessThan(jungle.frame.minX, highway.frame.minX) }
        capture("jungle-locked-third-position")
        app.terminate()

        let ready = launch(frontflips: 2)
        defer { ready.terminate() }
        let claim = openJungle(in: ready)
        XCTAssertEqual(claim.label, "Tropical Jungle, Ready to unlock")
        claim.tap()
        let ride = ready.buttons["rideInJungle"]
        XCTAssertTrue(ride.waitForExistence(timeout: 8))
        revealAction(ride, in: ready)
        XCTAssertEqual(ready.staticTexts["jungleUnlockTitle"].label, "TROPICAL JUNGLE UNLOCKED")
        capture("jungle-unlock-reveal")
        ride.tap()
        waitForHome(ready)
        XCTAssertEqual(ready.buttons["worlds"].label, "World: Tropical Jungle")
        ready.terminate()
        if let index = ready.launchArguments.firstIndex(of: "-world") {
            ready.launchArguments.removeSubrange(index...index + 1)
        }
        ready.launch()
        waitForHome(ready)
        XCTAssertEqual(ready.buttons["startEndless"].value as? String, "Tropical Jungle")
        XCTAssertEqual(ready.buttons["startWeekly"].value as? String, "Canyon")
        let saved = openJungle(in: ready)
        XCTAssertTrue(saved.isSelected)
        XCTAssertEqual(saved.label, "Tropical Jungle")
        XCTAssertFalse(ready.buttons["rideInJungle"].exists)
        capture("jungle-claimed-after-relaunch")
    }

    @MainActor func testJunglePlatformsAndWeeklyRemainSeparate() throws {
        let app = launch(claimed: true, extras: ["-jungle-course-preview"])
        defer { app.terminate() }
        openJungle(in: app).tap()
        waitForHome(app)
        XCTAssertEqual(app.staticTexts["weeklyCourseInfo"].label, "Same course for everyone.")
        XCTAssertEqual(app.staticTexts["endlessCourseInfo"].label, "New random course every ride.")
        capture("jungle-home")
        app.buttons["startEndless"].tap()
        waitForPlaying(app)
        XCTAssertEqual(app.staticTexts["activeWorld"].label, "Tropical Jungle")
        capture("jungle-platform-gameplay")
        app.buttons["throttle"].press(forDuration: 0.5)
        capture("jungle-platform-in-motion")
        goHomeFromRide(app)
        app.buttons["startWeekly"].tap()
        waitForPlaying(app)
        XCTAssertEqual(app.staticTexts["activeWorld"].label, "Canyon")
        capture("jungle-selection-weekly-canyon")
    }

    @MainActor func testPauseSoundToggleSharesHomeStateInJungleAndWeekly() throws {
        let app = launch(claimed: true, extras: ["-jungle-course-preview", "-scenery-seed", "5"])
        defer { app.terminate() }
        let jungle = openJungle(in: app)
        // Tap the visible artwork rather than XCUITest's automatic hit point,
        // which can land behind the sticky footer while the sheet settles.
        jungle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()
        waitForHome(app)
        XCTAssertEqual(app.buttons["homeSoundToggle"].value as? String, "Sound off")
        for mode in ["startEndless", "startWeekly"] {
            app.buttons[mode].tap()
            waitForPlaying(app)
            app.buttons["pause"].tap()
            let sound = app.buttons["pauseSoundToggle"]
            XCTAssertTrue(sound.waitForExistence(timeout: 5))
            XCTAssertTrue(sound.isHittable)
            XCTAssertEqual(sound.value as? String, "Sound off")
            let pausedDistance = app.staticTexts["distance"].label
            sound.tap()
            XCTAssertEqual(sound.value as? String, "Sound on")
            XCTAssertEqual(app.staticTexts["distance"].label, pausedDistance)
            XCTAssertTrue(app.buttons["resume"].isHittable, "Changing sound must keep the game paused")
            capture("pause-sound-on-\(mode)")
            app.buttons["resume"].tap()
            waitForPlaying(app)
            app.buttons["pause"].tap()
            XCTAssertTrue(sound.waitForExistence(timeout: 5))
            XCTAssertEqual(sound.value as? String, "Sound on")
            app.buttons["home"].tap()
            waitForHome(app)
            XCTAssertEqual(app.buttons["homeSoundToggle"].value as? String, "Sound on")
            app.buttons["homeSoundToggle"].tap()
            XCTAssertEqual(app.buttons["homeSoundToggle"].value as? String, "Sound off")
        }
    }

    @MainActor func testJungleHasIndependentRecordAndLeaderboardEntry() throws {
        let app = launch(claimed: true, extras: [
            "-bestEndless.box2d-2", "111", "-bestEndless.box2d-2.japan.route-1", "222",
            "-bestEndless.box2d-2.jungle.route-1", "999", "-bestEndless.box2d-2.jungle.route-2", "888",
            "-bestEndless.box2d-2.jungle.route-3", "777", "-bestEndless.box2d-2.jungle.route-4", "666", "-bestEndless.box2d-2.jungle.route-5", "555", "-bestEndless.box2d-2.jungle.route-6", "333"])
        defer { app.terminate() }
        _ = openJungle(in: app)
        for (id, value) in [("canyon", 111), ("japan", 222), ("jungle", 333)] {
            let record = app.descendants(matching: .any).matching(identifier: "worldRecord-\(id)").firstMatch
            revealAction(record, in: app)
            XCTAssertEqual(record.value as? String, "\(value) pts")
            XCTAssertTrue(app.buttons["worldLeaderboard-\(id)"].exists)
        }
        capture("jungle-independent-record")
    }

    @MainActor func testMiloHighJungleJumpKeepsRiderCloseInSupportedOrientations() throws {
        let app = launch(claimed: true, extras: [
            "-milo-unlock-fixture-claimed", "-rider.box2d-1", "monkey", "-jungle-high-jump-preview",
            "-scenery-seed", "5"
        ], orientation: .portrait)
        defer {
            app.terminate()
            XCUIDevice.shared.orientation = UIDevice.current.userInterfaceIdiom == .pad ? .landscapeLeft : .portrait
        }
        XCTAssertEqual(app.buttons["riders"].label, "Rider: Milo")
        openJungle(in: app).tap()
        waitForHome(app)
        app.buttons["startEndless"].tap()
        waitForPlaying(app)
        XCTAssertEqual(app.staticTexts["activeWorld"].label, "Tropical Jungle")
        // The core fixture drives through two landings, then stops at the third
        // real jump's apex. Neither this test nor the fixture alters the bike pose.
        let distance = Int(app.staticTexts["distance"].label.filter(\.isNumber)) ?? 0
        XCTAssertTrue((300..<500).contains(distance), "Capture the third large crossing, beyond the introductory ledge")
        let lives = app.descendants(matching: .any).matching(identifier: "lives").firstMatch
        XCTAssertEqual(lives.value as? String, "3 of 3 remaining")
        XCTAssertLessThan(app.windows.firstMatch.frame.width, app.windows.firstMatch.frame.height)
        capture("milo-jungle-high-jump-portrait")

        // The shipping phone app supports portrait only; iPad also supports
        // rotation. Exercise the same airborne frame in every supported shape.
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        XCUIDevice.shared.orientation = .landscapeLeft
        let rotated = NSPredicate { _, _ in
            app.windows.firstMatch.frame.width > app.windows.firstMatch.frame.height
                && app.buttons["resume"].exists && app.buttons["resume"].isHittable
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: rotated, object: nil)], timeout: 8),
                       .completed, "Rotating the ride pauses it before the landscape capture")
        app.buttons["resume"].tap()
        waitForPlaying(app)
        XCTAssertEqual(Int(app.staticTexts["distance"].label.filter(\.isNumber)), distance,
                       "The same physically reached apex remains frozen until a pedal press")
        XCTAssertEqual(lives.value as? String, "3 of 3 remaining")
        capture("milo-jungle-high-jump-landscape")
    }

    @MainActor private func launch(frontflips: Int = 0, claimed: Bool = false,
                                  extras: [String] = [], orientation: UIDeviceOrientation? = nil) -> XCUIApplication {
        XCUIDevice.shared.orientation = orientation ?? (UIDevice.current.userInterfaceIdiom == .pad ? .landscapeLeft : .portrait)
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-unlock-test-id", UUID().uuidString,
            "-world-unlock-test-id", UUID().uuidString, "-world-unlock-fixture-frontflips", String(claimed ? 2 : frontflips),
            "-audio.muted", "YES", "-world", "canyon"]
        if claimed { app.launchArguments.append("-jungle-unlock-fixture-claimed") }
        app.launchArguments += extras
        app.launch()
        waitForHome(app)
        return app
    }

    @MainActor private func openJungle(in app: XCUIApplication) -> XCUIElement {
        app.buttons["worlds"].tap()
        let jungle = app.buttons["select-jungle"]
        XCTAssertTrue(jungle.waitForExistence(timeout: 5))
        revealAction(jungle, in: app)
        return jungle
    }

    @MainActor private func waitForHome(_ app: XCUIApplication) {
        let ready = NSPredicate { _, _ in
            app.state == .runningForeground && app.buttons["startWeekly"].exists
                && app.buttons["startWeekly"].isHittable && app.buttons["worlds"].isHittable
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: nil)], timeout: 15),
                       .completed, "Home must be ready for interaction")
    }

    @MainActor private func waitForPlaying(_ app: XCUIApplication) {
        let playing = NSPredicate { _, _ in
            app.buttons["throttle"].exists && app.buttons["throttle"].isHittable
                && !app.buttons["resume"].exists && !app.buttons["rideAgain"].exists
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: playing, object: nil)], timeout: 8),
                       .completed, "The selected ride must start")
        XCTAssertTrue(app.staticTexts["activeWorld"].exists)
    }

    @MainActor private func goHomeFromRide(_ app: XCUIApplication) {
        app.buttons["pause"].tap()
        XCTAssertTrue(app.buttons["resume"].waitForExistence(timeout: 5))
        app.buttons["home"].tap()
        waitForHome(app)
    }

    /// A world card can be disabled and still fully visible; do not require hittability to inspect it.
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
