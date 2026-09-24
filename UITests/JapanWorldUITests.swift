import UIKit
import XCTest

final class JapanWorldUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor func testJapanZeroFrontflipsRemainsLocked() throws {
        let app = launch(frontflips: 0)
        defer { app.terminate() }
        let japan = openJapanCard(in: app)
        XCTAssertFalse(japan.isEnabled)
        XCTAssertEqual(japan.label, "Japan Mountains, Locked")
        XCTAssertEqual(japan.value as? String, requirement(count: 0))
        capture("japan-locked-zero-frontflips")
        app.buttons["closePanel"].tap()
        waitForHome(app)
        XCTAssertEqual(app.buttons["worlds"].label, "World: Canyon")
        XCTAssertEqual(app.buttons["startEndless"].value as? String, "Canyon")
        assertCourseExplanations(app)
        XCTAssertFalse(app.buttons["rideInJapan"].exists)
    }

    @MainActor func testJapanOneFrontflipProgressSurvivesRelaunch() throws {
        let app = launch(frontflips: 1)
        defer { app.terminate() }
        for iteration in 0..<2 {
            let japan = openJapanCard(in: app)
            XCTAssertFalse(japan.isEnabled)
            XCTAssertEqual(japan.value as? String, requirement(count: 1))
            capture("japan-one-frontflip-\(iteration)")
            app.buttons["closePanel"].tap()
            if iteration == 0 { relaunch(app) }
        }
    }

    @MainActor func testJapanRealFrontflipReceptionsAccumulateAcrossModes() throws {
        let app = launch(extraArguments: ["-world-unlock-landing-preview"])
        defer { app.terminate() }
        for (start, count) in [("startWeekly", 1), ("startEndless", 2)] {
            app.buttons[start].tap()
            waitForPlaying(app)
            let notice = app.descendants(matching: .any).matching(identifier: "stuntNotice").firstMatch
            let frontflip = NSPredicate { _, _ in
                notice.exists && notice.label.contains("FRONTFLIP") && !notice.label.contains("BACK")
            }
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: frontflip, object: nil)], timeout: 10),
                           .completed, "A real frontflip must safely land before its progress is inspected")
            capture("japan-real-frontflip-\(count)")
            app.buttons["pause"].tap()
            XCTAssertTrue(app.buttons["resume"].waitForExistence(timeout: 5))
            app.buttons["resume"].tap()
            waitForPlaying(app)
            goHomeFromRide(app)
            let japan = openJapanCard(in: app)
            XCTAssertEqual(japan.value as? String, requirement(count: count))
            XCTAssertEqual(japan.isEnabled, count == 2, "Pause, resume and home must not duplicate one reception")
            capture("japan-received-progress-\(count)")
            app.buttons["closePanel"].tap()
            waitForHome(app)
        }
        relaunch(app)
        let japan = openJapanCard(in: app)
        XCTAssertEqual(japan.label, "Japan Mountains, Ready to unlock")
        XCTAssertEqual(japan.value as? String, requirement(count: 2))
        XCTAssertFalse(app.buttons["rideInJapan"].exists)
        capture("japan-real-receptions-persisted")
        app.buttons["closePanel"].tap()
    }

    @MainActor func testJapanClaimRevealSelectionAndPersistence() throws {
        let app = launch(frontflips: 2)
        defer { app.terminate() }
        XCTAssertEqual(app.buttons["worlds"].label, "World: Canyon")
        XCTAssertFalse(app.buttons["rideInJapan"].exists, "Progress alone must not claim a world")
        let japan = openJapanCard(in: app)
        XCTAssertTrue(japan.isEnabled)
        XCTAssertEqual(japan.label, "Japan Mountains, Ready to unlock")
        XCTAssertEqual(japan.value as? String, requirement(count: 2))
        capture("japan-ready-to-unlock")
        japan.tap()
        XCTAssertTrue(app.staticTexts["japanUnlockTitle"].waitForExistence(timeout: 3))
        let ride = app.buttons["rideInJapan"]
        XCTAssertTrue(ride.waitForExistence(timeout: 6))
        revealAction(ride, in: app)
        XCTAssertEqual(app.staticTexts["japanUnlockTitle"].label, "JAPAN MOUNTAINS UNLOCKED")
        XCTAssertTrue(app.buttons["dismissJapanUnlock"].exists)
        capture("japan-unlocked-reveal")
        ride.tap()
        waitForHome(app)
        assertJapanSelected(app)
        capture("japan-selected-home")
        relaunch(app)
        assertJapanSelected(app)
        let selectedJapan = openJapanCard(in: app)
        XCTAssertTrue(selectedJapan.isEnabled)
        XCTAssertTrue(selectedJapan.isSelected)
        XCTAssertEqual(selectedJapan.label, "Japan Mountains")
        XCTAssertFalse(app.buttons["rideInJapan"].exists, "A claimed world's reveal must not replay")
        capture("japan-selected-after-relaunch")
        selectCanyon(in: app)
    }

    @MainActor func testJapanNotNowKeepsClaimWithoutChangingSelection() throws {
        let app = launch(frontflips: 2)
        defer { app.terminate() }
        openJapanCard(in: app).tap()
        let dismiss = app.buttons["dismissJapanUnlock"]
        XCTAssertTrue(dismiss.waitForExistence(timeout: 6))
        revealAction(dismiss, in: app)
        dismiss.tap()
        // The cover closes back to the world picker, with the claim already persisted.
        let japan = app.buttons["select-japan"]
        XCTAssertTrue(japan.waitForExistence(timeout: 5))
        XCTAssertTrue(japan.isEnabled)
        XCTAssertEqual(japan.label, "Japan Mountains")
        XCTAssertFalse(japan.isSelected)
        app.buttons["closePanel"].tap()
        waitForHome(app)
        XCTAssertEqual(app.buttons["worlds"].label, "World: Canyon")
        relaunch(app)
        let claimedJapan = openJapanCard(in: app)
        XCTAssertEqual(claimedJapan.label, "Japan Mountains")
        XCTAssertTrue(claimedJapan.isEnabled)
        XCTAssertFalse(app.buttons["rideInJapan"].exists)
        capture("japan-claimed-not-selected")
        app.buttons["closePanel"].tap()
    }

    @MainActor func testJapanInterruptedRevealPreservesClaim() throws {
        let app = launch(frontflips: 2)
        defer { app.terminate() }
        openJapanCard(in: app).tap()
        XCTAssertTrue(app.staticTexts["japanUnlockTitle"].waitForExistence(timeout: 3))
        relaunch(app)
        let japan = openJapanCard(in: app)
        XCTAssertTrue(japan.isEnabled)
        XCTAssertEqual(japan.label, "Japan Mountains", "A claim must be saved before its reveal")
        XCTAssertFalse(app.buttons["rideInJapan"].exists)
        capture("japan-claim-survived-interruption")
        app.buttons["closePanel"].tap()
    }

    @MainActor func testSelectedJapanAppliesToEndlessAndWeeklyRemainsCanyon() throws {
        let app = launch(claimed: true)
        defer { app.terminate() }
        let japan = openJapanCard(in: app)
        XCTAssertEqual(japan.label, "Japan Mountains")
        japan.tap()
        waitForHome(app)
        assertJapanSelected(app)
        app.buttons["startEndless"].tap()
        waitForPlaying(app)
        XCTAssertEqual(app.staticTexts["activeWorld"].label, "Japan Mountains")
        XCTAssertTrue(app.staticTexts["ENDLESS"].exists)
        app.buttons["throttle"].press(forDuration: 4)
        capture("japan-endless-first-ride")
        goHomeFromRide(app)
        app.buttons["startWeekly"].tap()
        waitForPlaying(app)
        XCTAssertEqual(app.staticTexts["activeWorld"].label, "Canyon")
        XCTAssertTrue(app.staticTexts["WEEKLY"].exists)
        capture("japan-selection-weekly-canyon")
        goHomeFromRide(app)
        assertJapanSelected(app)
        _ = openJapanCard(in: app)
        selectCanyon(in: app)
    }

    @MainActor func testJapanAndCanyonKeepSeparateLocalEndlessRecords() throws {
        let app = launch(claimed: true, extraArguments: [
            "-bestEndless.box2d-2", "111", "-bestEndless.box2d-2.japan.route-1", "222",
        ])
        defer { app.terminate() }
        assertEndlessRecord(111, world: "Canyon", in: app)
        openJapanCard(in: app).tap()
        waitForHome(app)
        assertEndlessRecord(222, world: "Japan Mountains", in: app)
        _ = openJapanCard(in: app)
        selectCanyon(in: app)
        assertEndlessRecord(111, world: "Canyon", in: app)
    }

    @MainActor private func launch(frontflips: Int? = nil, claimed: Bool = false,
                                  extraArguments: [String] = []) -> XCUIApplication {
        XCUIDevice.shared.orientation = UIDevice.current.userInterfaceIdiom == .pad ? .landscapeLeft : .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-unlock-test-id", UUID().uuidString,
            "-world-unlock-test-id", UUID().uuidString, "-audio.muted", "YES", "-world", "canyon"]
        if let frontflips { app.launchArguments += ["-world-unlock-fixture-frontflips", String(frontflips)] }
        if claimed { app.launchArguments.append("-world-unlock-fixture-claimed") }
        app.launchArguments += extraArguments
        app.launch()
        waitForHome(app)
        return app
    }

    @MainActor private func relaunch(_ app: XCUIApplication) {
        app.terminate()
        // Preserve both progression UUIDs, but let the saved world preference govern this launch.
        if let index = app.launchArguments.firstIndex(of: "-world") {
            app.launchArguments.removeSubrange(index...index + 1)
        }
        app.launch()
        waitForHome(app)
    }

    private func requirement(count: Int) -> String {
        "Land 2 frontflips to unlock Japan Mountains, \(count) / 2"
    }

    @MainActor private func openJapanCard(in app: XCUIApplication) -> XCUIElement {
        app.buttons["worlds"].tap()
        let japan = app.buttons["select-japan"]
        XCTAssertTrue(japan.waitForExistence(timeout: 5))
        revealAction(japan, in: app)
        return japan
    }

    @MainActor private func selectCanyon(in app: XCUIApplication) {
        let canyon = app.buttons["select-canyon"]
        revealAction(canyon, in: app)
        canyon.tap()
        waitForHome(app)
        XCTAssertEqual(app.buttons["worlds"].label, "World: Canyon")
    }

    @MainActor private func assertJapanSelected(_ app: XCUIApplication) {
        XCTAssertEqual(app.buttons["worlds"].label, "World: Japan Mountains")
        XCTAssertEqual(app.buttons["startEndless"].value as? String, "Japan Mountains")
        XCTAssertEqual(app.buttons["startWeekly"].value as? String, "Canyon")
        assertCourseExplanations(app)
    }

    @MainActor private func assertCourseExplanations(_ app: XCUIApplication) {
        XCTAssertEqual(app.staticTexts["weeklyCourseInfo"].label, "Same course for everyone.")
        XCTAssertEqual(app.staticTexts["endlessCourseInfo"].label, "New random course every ride.")
    }

    @MainActor private func assertEndlessRecord(_ score: Int, world: String, in app: XCUIApplication) {
        app.buttons["rankings"].tap()
        XCTAssertTrue(app.buttons["rankings.endlessWorlds"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["rankings.weeklyScore"].exists)
        XCTAssertTrue(app.buttons["rankings.weeklyTime"].exists)
        let rankings = app.descendants(matching: .any).matching(identifier: "rankings.list").firstMatch
        XCTAssertTrue(rankings.exists)
        XCTAssertFalse(rankings.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Canyon")).firstMatch.exists,
                       "Weekly must not be named after a world; the underlying Home is outside this panel")
        app.buttons["rankings.endlessWorlds"].tap()
        XCTAssertTrue(app.buttons["select-canyon"].waitForExistence(timeout: 5))
        for (id, expected) in [("canyon", 111), ("japan", 222)] {
            let record = app.descendants(matching: .any)
                .matching(identifier: "worldRecord-\(id)").firstMatch
            revealAction(record, in: app)
            XCTAssertEqual(record.value as? String, "\(expected) pts")
            let board = app.buttons["worldLeaderboard-\(id)"]
            XCTAssertTrue(board.exists, "Every supported world keeps its comparison link")
            XCTAssertTrue(board.isEnabled, "An unauthenticated player can connect without unlocking or selecting the world")
        }
        XCTAssertFalse(app.buttons["worldLeaderboard-alpine"].exists, "Unavailable future worlds do not invent leaderboards")
        capture("world-records-\(world == "Canyon" ? "canyon" : "japan")-\(score)")
        app.buttons["closePanel"].tap()
        waitForHome(app)
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
