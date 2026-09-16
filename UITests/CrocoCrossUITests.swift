import UIKit
import XCTest

final class CrocoCrossUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor private func launch(extraArguments: [String] = []) -> XCUIApplication {
        if UIDevice.current.userInterfaceIdiom == .pad { XCUIDevice.shared.orientation = .landscapeLeft }
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"] + extraArguments
        app.launch()
        let ready = app.buttons["startWeekly"].waitForExistence(timeout: 15)
        if !ready {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "missing-launch-accessibility"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            print("HOME ACCESSIBILITY: \(app.debugDescription)")
        }
        XCTAssertTrue(ready)
        assertNoSavedRunPrompt(app)
        return app
    }

    @MainActor func testHomeModesAndSettingsSections() throws {
        let app = launch()
        let weekly = app.buttons["startWeekly"].frame
        let endless = app.buttons["startEndless"].frame
        XCTAssertEqual(weekly.width, weekly.height, accuracy: 2)
        XCTAssertEqual(endless.width, endless.height, accuracy: 2)
        XCTAssertEqual(weekly.width, endless.width, accuracy: 2)
        XCTAssertEqual(weekly.minY, endless.minY, accuracy: 2)
        XCTAssertLessThan(weekly.maxX, endless.minX)
        XCTAssertEqual(app.buttons.matching(identifier: "riders").count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: "worlds").count, 1)
        for title in ["Rider", "World"] {
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", title)).firstMatch.exists)
        }
        let settings = app.buttons["settings"]
        XCTAssertGreaterThan(settings.frame.midY, endless.maxY)
        XCTAssertTrue(settings.isHittable)
        for id in ["rankings", "settings", "help"] {
            let item = app.buttons[id]
            XCTAssertEqual(item.frame.height, settings.frame.height, accuracy: 1)
            XCTAssertEqual(item.frame.width, settings.frame.width, accuracy: 1)
            XCTAssertEqual(item.frame.midY, settings.frame.midY, accuracy: 1)
            XCTAssertFalse(item.isSelected)
        }
        capture("home-square-modes-a")
        Thread.sleep(forTimeInterval: 0.65)
        capture("home-square-modes-b")
        settings.tap()
        assertBottomClose(app)
        let audio = app.buttons["settings.tab.audio"]
        let general = app.buttons["settings.tab.general"]
        let about = app.buttons["settings.tab.about"]
        for tab in [general, audio, about] {
            XCTAssertTrue(tab.waitForExistence(timeout: 5))
            XCTAssertTrue(tab.isHittable)
            XCTAssertEqual(tab.frame.midY, audio.frame.midY, accuracy: 2)
        }
        XCTAssertTrue(general.isSelected)
        XCTAssertTrue(app.switches["Haptic feedback"].exists)
        capture("settings-general")
        audio.tap()
        let tabFrame = audio.frame
        let closeFrame = app.buttons["closePanel"].frame
        XCTAssertEqual(closeFrame.midY, tabFrame.midY, accuracy: 2)
        XCTAssertLessThan(app.buttons["settings.tab.about"].frame.maxX, closeFrame.minX)
        XCTAssertGreaterThan(tabFrame.midY, app.windows.firstMatch.frame.height * 0.70)
        reveal(app.sliders["Effects"], in: app)
        XCTAssertEqual(audio.frame, tabFrame, "Audio scrolling must leave the section tabs fixed")
        XCTAssertEqual(app.buttons["closePanel"].frame, closeFrame, "Close must remain fixed while scrolling")
        reveal(app.buttons["music.track.quarter-in-the-slot"], in: app)
        XCTAssertFalse(app.buttons["music.playPause"].exists)
        XCTAssertFalse(app.buttons["music.next"].exists)
        XCTAssertFalse(app.buttons["music.previous"].exists)
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", "Quarter in the Slot")).count, 1)
        capture("settings-audio")
        for (tab, label) in [(general, "general"), (about, "about")] {
            tab.tap()
            XCTAssertTrue(tab.isSelected)
            XCTAssertEqual(audio.frame, tabFrame, "Section navigation stays at the bottom")
            XCTAssertFalse(app.switches["Play music"].exists)
            capture("settings-\(label)")
        }
        audio.tap()
        XCTAssertTrue(app.switches["Play music"].exists)
        app.buttons["closePanel"].tap()
        app.buttons["rankings"].tap()
        assertBottomClose(app)
        XCTAssertTrue(app.staticTexts["Your best"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["settings.tab.audio"].exists)
        XCTAssertTrue(app.buttons["rankings.connect"].exists || app.buttons["rankings.online"].exists)
        capture("rankings")
        app.buttons["closePanel"].tap()
    }

    @MainActor func testWeeklyPauseAbandonAndNavigation() throws {
        let app = launch()
        app.buttons["startWeekly"].tap()
        try assertFreshRun(app, mode: "WEEKLY")
        app.buttons["throttle"].press(forDuration: 0.4)
        waitForDistance(app, greaterThan: 0)
        app.buttons["pause"].tap()
        waitForPaused(app)
        let pausedDistance = try displayedDistance(app)
        let pausedScore = app.staticTexts["score"].label
        XCTAssertGreaterThan(pausedDistance, 0)
        Thread.sleep(forTimeInterval: 0.25)
        XCTAssertEqual(try displayedDistance(app), pausedDistance, "Manual pause must freeze this ride")
        XCTAssertEqual(app.staticTexts["score"].label, pausedScore)
        capture("weekly-paused")
        app.buttons["resume"].tap()
        waitForPlaying(app)
        XCTAssertGreaterThanOrEqual(try displayedDistance(app), pausedDistance, "Keep riding must resume the same ride")
        XCTAssertEqual(app.buttons["throttle"].value as? String, "Released")
        XCTAssertEqual(app.buttons["brake"].value as? String, "Released")
        app.buttons["pause"].tap()
        waitForPaused(app)
        app.buttons["home"].tap()
        waitForHome(app)
        capture("home-after-abandon")

        app.buttons["startEndless"].tap()
        try assertFreshRun(app, mode: "ENDLESS")
        app.buttons["throttle"].press(forDuration: 0.4)
        waitForDistance(app, greaterThan: 0)
        app.buttons["pause"].tap()
        waitForPaused(app)
        app.buttons["restart"].tap()
        try assertFreshRun(app, mode: "ENDLESS")
        capture("restart-without-confirmation")

        // Terminating during a progressing ride must not create a recoverable run.
        app.buttons["throttle"].press(forDuration: 0.4)
        waitForDistance(app, greaterThan: 0)
        app.terminate()
        app.launch()
        waitForHome(app)
        capture("home-after-relaunch")
        app.buttons["startWeekly"].tap()
        try assertFreshRun(app, mode: "WEEKLY")
        app.buttons["pause"].tap()
        waitForPaused(app)
        app.buttons["home"].tap()
        waitForHome(app)
        app.buttons["worlds"].tap()
        XCTAssertTrue(app.buttons["select-japan"].waitForExistence(timeout: 5))
        let oldFrame = app.buttons["select-japan"].frame
        assertBottomClose(app)
        app.buttons["select-japan"].tap()
        waitForHome(app)
        XCTAssertEqual(app.buttons["worlds"].label, "World: Japan Mountains")
        app.buttons["worlds"].tap()
        XCTAssertTrue(app.buttons["select-japan"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["select-japan"].frame, oldFrame)
        let canyon = app.buttons["select-canyon"].frame
        let japan = app.buttons["select-japan"].frame
        XCTAssertLessThanOrEqual(canyon.maxX, japan.minX, "Terrain artwork must stay inside its own grid column")
        XCTAssertGreaterThanOrEqual(canyon.minX, app.navigationBars.firstMatch.frame.minX)
        Thread.sleep(forTimeInterval: 0.3)
        capture("world-selection")
        app.buttons["closePanel"].tap()
        app.buttons["riders"].tap()
        XCTAssertTrue(app.buttons["select-shiba"].waitForExistence(timeout: 5))
        assertBottomClose(app)
        app.buttons["select-shiba"].tap()
        waitForHome(app)
        XCTAssertEqual(app.buttons["riders"].label, "Rider: Kenji")
        capture("home-japan")
    }

    @MainActor func testAdaptiveLayoutAndSettings() throws {
        let app = launch()
        capture("home")
        app.buttons["settings"].tap()
        app.buttons["settings.tab.audio"].tap()
        XCTAssertTrue(app.switches["Play music"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.sliders["Music volume"].exists)
        reveal(app.sliders["Music volume"], in: app)
        app.sliders["Music volume"].adjust(toNormalizedSliderPosition: 0.25)
        app.buttons["closePanel"].tap()
        app.buttons["startEndless"].tap()
        assertNoSavedRunPrompt(app)
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

    @MainActor func testImageButtonsAndBottomPause() throws {
        let app = launch(extraArguments: ["-audio.muted", "YES", "-world", "paris"])
        defer { app.terminate() }
        app.buttons["startEndless"].tap()
        waitForPlaying(app)
        let throttle = app.buttons["throttle"]
        let brake = app.buttons["brake"]
        let pause = app.buttons["pause"]
        let window = app.windows.firstMatch.frame
        let original = throttle.frame
        for button in [throttle, brake] {
            XCTAssertTrue(button.isHittable)
            XCTAssertGreaterThanOrEqual(button.frame.width, 100)
            XCTAssertLessThanOrEqual(button.frame.width, 130)
            XCTAssertEqual(button.frame.width, button.frame.height, accuracy: 1)
            XCTAssertGreaterThan(button.frame.minY, window.height * 0.65)
            XCTAssertEqual(button.value as? String, "Released")
        }
        XCTAssertLessThan(brake.frame.maxX, pause.frame.minX)
        XCTAssertGreaterThan(throttle.frame.minX, pause.frame.maxX)
        XCTAssertLessThan(abs(pause.frame.midX - window.midX), 5)
        capture("image-buttons-idle")
        let before = try displayedDistance(app)
        let start = throttle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
        let end = throttle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        start.press(forDuration: 0.25, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        XCTAssertEqual(throttle.value as? String, "Released", "A moving thumb must still release on lift")
        XCTAssertEqual(throttle.frame, original, "The image button must remain fixed")
        waitForDistance(app, greaterThan: before)
        brake.press(forDuration: 0.2)
        XCTAssertEqual(brake.value as? String, "Released")
        capture("image-buttons-riding")
        pause.tap()
        waitForPaused(app)
        app.buttons["resume"].tap()
        waitForPlaying(app)
        XCTAssertEqual(throttle.value as? String, "Released", "Resume must not reuse held input")
        XCTAssertEqual(brake.value as? String, "Released")
        capture("image-buttons-resumed")
    }

    @MainActor func testCrashResultsAndRetry() throws {
        let app = launch()
        app.buttons["startWeekly"].tap()
        try assertFreshRun(app, mode: "WEEKLY")
        reachCrashResults(app)
        for id in ["rideAgain", "resultsRankings", "home"] {
            let action = app.buttons[id]
            if !action.isHittable { app.swipeUp() }
            XCTAssertTrue(action.isHittable, "The game-over action \(id) must be accessible")
        }
        capture("game-over-actions")
        app.buttons["resultsRankings"].tap()
        XCTAssertTrue(app.staticTexts["Your best"].waitForExistence(timeout: 5))
        capture("rankings-from-game-over")
        app.buttons["closePanel"].tap()
        XCTAssertTrue(app.buttons["rideAgain"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["GAME OVER"].exists)
        XCTAssertFalse(app.buttons["throttle"].isHittable)
        capture("game-over-footer")
        app.buttons["home"].tap()
        waitForHome(app)
        app.buttons["startWeekly"].tap()
        try assertFreshRun(app, mode: "WEEKLY")

        // A second real crash exercises Ride again independently of leaving for Home.
        reachCrashResults(app)
        app.buttons["rideAgain"].tap()
        try assertFreshRun(app, mode: "WEEKLY")
        app.buttons["pause"].tap()
        waitForPaused(app)
    }

    @MainActor func testMusicModeAndTrackSurviveRelaunch() throws {
        let app = launch()
        app.buttons["settings"].tap()
        app.buttons["settings.tab.audio"].tap()
        let mode = app.segmentedControls["music.playbackMode"]
        XCTAssertTrue(mode.waitForExistence(timeout: 5))
        mode.buttons["One track"].tap()
        let track = app.buttons["music.track.crossing-the-black-river"]
        reveal(track, in: app)
        XCTAssertTrue(track.isHittable)
        track.tap()
        XCTAssertTrue(track.isSelected)
        capture("music-tracks")
        app.buttons["closePanel"].tap()
        app.terminate()
        app.launch()
        waitForHome(app)
        app.buttons["settings"].tap()
        app.buttons["settings.tab.audio"].tap()
        XCTAssertTrue(mode.buttons["One track"].isSelected)
        reveal(track, in: app)
        XCTAssertTrue(track.isSelected)
        app.buttons["closePanel"].tap()
    }

    @MainActor func testAudioVolumesSurviveChangesAndRelaunch() throws {
        let app = launch()
        app.buttons["settings"].tap()
        app.buttons["settings.tab.audio"].tap()
        XCTAssertTrue(app.sliders["Music volume"].waitForExistence(timeout: 5))
        var storedValues: [String: String] = [:]
        for (label, value) in [("Music volume", 0.25), ("Engine", 0.5), ("Effects", 0.75)] {
            let slider = app.sliders[label]
            reveal(slider, in: app)
            XCTAssertTrue(slider.isHittable, "\(label) must be adjustable")
            slider.adjust(toNormalizedSliderPosition: CGFloat(value))
            storedValues[label] = try XCTUnwrap(slider.value as? String)
            XCTAssertEqual(app.state, .runningForeground, "Changing \(label) must not recurse or crash")
        }
        app.buttons["closePanel"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(
            app.buttons["startWeekly"].waitForExistence(timeout: 15),
            "Restoring saved audio settings must not crash startup")
        assertNoSavedRunPrompt(app)
        app.buttons["settings"].tap()
        app.buttons["settings.tab.audio"].tap()
        XCTAssertTrue(app.sliders["Music volume"].waitForExistence(timeout: 5))
        for label in ["Music volume", "Engine", "Effects"] {
            let slider = app.sliders[label]
            reveal(slider, in: app)
            XCTAssertEqual(slider.value as? String, storedValues[label], "\(label) should survive relaunch")
        }
        capture("audio-settings-restored")
    }

    @MainActor func testViewportAndBackgroundLifecycle() throws {
        let app = launch()
        app.buttons["startEndless"].tap()
        assertNoSavedRunPrompt(app)
        waitForPlaying(app)
        app.buttons["throttle"].press(forDuration: 0.4)
        waitForPlaying(app)
        if UIDevice.current.userInterfaceIdiom == .pad {
            for (orientation, label) in [
                (UIDeviceOrientation.portrait, "portrait"), (.landscapeLeft, "landscape-left"),
            ] {
                waitForPlaying(app)
                let before = app.windows.firstMatch.frame
                XCUIDevice.shared.orientation = orientation
                var previousFrame: CGRect?
                let settled = NSPredicate { _, _ in
                    guard XCUIDevice.shared.orientation == orientation,
                        app.state == .runningForeground,
                        app.windows.firstMatch.exists
                    else { return false }
                    let frame = app.windows.firstMatch.frame
                    guard frame.width > 0, frame.height > 0 else { return false }
                    defer { previousFrame = frame }
                    return previousFrame == frame
                }
                XCTAssertEqual(
                    XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: settled, object: nil)], timeout: 8),
                    .completed,
                    "The app window must settle after changing device orientation")
                let after = app.windows.firstMatch.frame
                let widthChange = abs(after.width - before.width)
                let heightChange = abs(after.height - before.height)
                let viewportChanged = widthChange > 30 || heightChange > 30
                let dimensions = XCTAttachment(
                    string:
                        "Device orientation: \(label)\nBefore: \(before.width) × \(before.height)\nAfter: \(after.width) × \(after.height)\nDelta: \(widthChange) × \(heightChange)\nActual viewport resize: \(viewportChanged)"
                )
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
        var wasBackgrounded = false
        let backgrounded = NSPredicate { _, _ in
            let isBackgrounded = app.state == .runningBackground || app.state == .runningBackgroundSuspended
            defer { wasBackgrounded = isBackgrounded }
            return isBackgrounded && wasBackgrounded
        }
        XCTAssertEqual(
            XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: backgrounded, object: nil)], timeout: 5),
            .completed, "The app must reach the background before it is reopened")
        app.activate()
        waitForHome(app)
        capture("home-after-background")
        app.buttons["startEndless"].tap()
        try assertFreshRun(app, mode: "ENDLESS")
        app.buttons["pause"].tap()
        waitForPaused(app)
    }

    @MainActor func testSelectedRiderWheelsVisible() throws {
        let app = launch()
        app.buttons["riders"].tap()
        for rider in ["croco", "shiba", "eagle", "tiger", "polar", "flamingo", "toucan", "raccoon", "axolotl"] {
            let choice = app.buttons["select-\(rider)"]
            reveal(choice, in: app)
            XCTAssertTrue(choice.isHittable)
            choice.tap()
            waitForHome(app)
            app.buttons["riders"].tap()
            reveal(choice, in: app)
            Thread.sleep(forTimeInterval: 0.3)
            capture("picker-\(rider)-a")
            Thread.sleep(forTimeInterval: 0.7)
            capture("picker-\(rider)-b")
        }
        app.buttons["closePanel"].tap()
    }

    @MainActor func testBottomCloseAndImmediateSelections() throws {
        let app = launch()
        for panel in ["rankings", "settings", "help", "riders", "worlds"] {
            app.buttons[panel].tap()
            assertBottomClose(app)
            capture("bottom-close-\(panel)")
            app.buttons["closePanel"].tap()
            waitForHome(app)
        }
        for (panel, selection, label) in [
            ("riders", "croco", "Rider: Rocco"),
            ("riders", "axolotl", "Rider: Bubbles"),
            ("worlds", "canyon", "World: Canyon"),
            ("worlds", "clouds", "World: Cloud Nine"),
        ] {
            app.buttons[panel].tap()
            let choice = app.buttons["select-\(selection)"]
            reveal(choice, in: app)
            choice.tap()
            waitForHome(app)
            XCTAssertFalse(app.buttons["closePanel"].exists)
            XCTAssertEqual(app.buttons[panel].label, label)
        }
        app.terminate()
        app.launch()
        waitForHome(app)
        XCTAssertEqual(app.buttons["riders"].label, "Rider: Bubbles")
        XCTAssertEqual(app.buttons["worlds"].label, "World: Cloud Nine")
        capture("immediate-selection-persisted")
    }

    @MainActor private func assertBottomClose(
        _ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line
    ) {
        let close = app.buttons["closePanel"]
        XCTAssertTrue(close.waitForExistence(timeout: 5), file: file, line: line)
        XCTAssertTrue(close.isHittable, file: file, line: line)
        XCTAssertEqual(app.buttons.matching(identifier: "closePanel").count, 1, file: file, line: line)
        XCTAssertFalse(app.buttons["Done"].exists, file: file, line: line)
        let navigation = app.navigationBars.firstMatch.frame
        XCTAssertGreaterThan(close.frame.midX, navigation.midX, file: file, line: line)
        XCTAssertGreaterThan(close.frame.midY, app.windows.firstMatch.frame.height * 0.70, file: file, line: line)
        XCTAssertGreaterThanOrEqual(close.frame.width, 44, file: file, line: line)
        XCTAssertGreaterThanOrEqual(close.frame.height, 44, file: file, line: line)
    }

    @MainActor private func assertNoSavedRunPrompt(
        _ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertFalse(app.buttons["continueRun"].exists, "Continue must not be offered", file: file, line: line)
        XCTAssertFalse(app.buttons["Continue"].exists, file: file, line: line)
        XCTAssertFalse(
            app.buttons["Replace saved ride"].exists, "Starting a ride must not ask to replace an old run", file: file,
            line: line)
        XCTAssertFalse(app.staticTexts["Start a new ride?"].exists, file: file, line: line)
        XCTAssertFalse(
            app.staticTexts["Restart this ride?"].exists, "Restart must be immediate", file: file, line: line)
    }

    @MainActor private func waitForHome(
        _ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line
    ) {
        let predicate = NSPredicate { _, _ in
            app.state == .runningForeground && app.buttons["startWeekly"].exists
                && app.buttons["startWeekly"].isHittable && app.buttons["settings"].isHittable
        }
        XCTAssertEqual(
            XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)], timeout: 15),
            .completed, "Leaving a ride must return to Home", file: file, line: line)
        XCTAssertFalse(app.buttons["resume"].exists, file: file, line: line)
        XCTAssertFalse(app.buttons["rideAgain"].exists, file: file, line: line)
        assertNoSavedRunPrompt(app, file: file, line: line)
    }

    @MainActor private func assertFreshRun(
        _ app: XCUIApplication, mode: String, file: StaticString = #filePath, line: UInt = #line
    ) throws {
        waitForPlaying(app, file: file, line: line)
        XCTAssertEqual(try displayedDistance(app), 0, "A new ride must start at zero metres", file: file, line: line)
        XCTAssertEqual(app.buttons["throttle"].value as? String, "Released", file: file, line: line)
        XCTAssertEqual(app.buttons["brake"].value as? String, "Released", file: file, line: line)
        XCTAssertTrue(app.staticTexts[mode].exists, "The requested ride mode must be active", file: file, line: line)
        let score = Int(app.staticTexts["score"].label.filter(\.isNumber))
        XCTAssertEqual(score, 0, "A new ride must not inherit points", file: file, line: line)
        assertNoSavedRunPrompt(app, file: file, line: line)
    }

    @MainActor private func reachCrashResults(
        _ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line
    ) {
        for _ in 0..<5 {
            if app.buttons["rideAgain"].exists { break }
            app.buttons["throttle"].press(forDuration: 8)
        }
        XCTAssertTrue(
            app.buttons["rideAgain"].waitForExistence(timeout: 5),
            "Sustained uncontrolled throttle must reach the real crash/result flow", file: file, line: line)
        XCTAssertTrue(app.staticTexts["GAME OVER"].exists, file: file, line: line)
        XCTAssertTrue(app.staticTexts["finalScore"].exists, file: file, line: line)
        XCTAssertFalse(app.buttons["throttle"].isHittable, file: file, line: line)
    }

    /// Short edge drags avoid both overshooting a row and grabbing a volume slider.
    @MainActor private func reveal(
        _ element: XCUIElement, in app: XCUIApplication,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let window = app.windows.firstMatch.frame
        let navigation = app.navigationBars.firstMatch.frame
        let top = navigation.maxY + 12
        let settingsTab = app.buttons["settings.tab.audio"]
        let close = app.buttons["closePanel"]
        let bottom =
            settingsTab.exists
            ? settingsTab.frame.minY - 10
            : (close.exists ? close.frame.minY - 10 : window.maxY - 20)
        // Stay inside the scroll view, left of slider tracks and away from the sheet edge.
        let x = navigation.minX + 28
        for _ in 0..<12 {
            let exists = element.exists
            let frame = exists ? element.frame : .zero
            if exists && element.isHittable && frame.minY >= top && frame.maxY <= bottom { return }
            let down = exists && frame.height > 0 && frame.minY < top
            let middle = (top + bottom) / 2
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: x, dy: middle + (down ? -55 : 55)))
            let end = origin.withOffset(CGVector(dx: x, dy: middle + (down ? 55 : -55)))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.05)
        }
        XCTFail(
            "The complete control must be visible: \(element.identifier), frame \(element.exists ? element.frame : .zero), visible range \(top)...\(bottom), window \(window)",
            file: file, line: line)
    }

    @MainActor private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// Gameplay controls remain in the accessibility tree underneath the pause/results overlay.
    /// Existence alone therefore cannot establish that a ride actually started or resumed.
    @MainActor private func waitForPlaying(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate { _, _ in
            let throttle = app.buttons["throttle"]
            return app.state == .runningForeground && throttle.exists && throttle.isHittable
                && !app.buttons["resume"].exists && !app.buttons["rideAgain"].exists
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 8), .completed,
            "The ride must be playing with a hittable throttle and no pause/results overlay", file: file, line: line)
        XCTAssertFalse(app.buttons["resume"].exists, file: file, line: line)
        XCTAssertFalse(app.buttons["rideAgain"].exists, file: file, line: line)
        assertNoSavedRunPrompt(app, file: file, line: line)
    }

    @MainActor private func waitForPaused(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let predicate = NSPredicate { _, _ in
            let resume = app.buttons["resume"]
            return resume.exists && resume.isHittable && !app.buttons["throttle"].isHittable
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 8), .completed,
            "The ride must require explicit resume and its pedals must not be hittable", file: file, line: line)
    }

    @MainActor private func displayedDistance(
        _ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line
    ) throws -> Int {
        let label = app.staticTexts["distance"].label
        return try XCTUnwrap(
            Int(label.filter(\.isNumber)), "Distance HUD must expose a numeric value: \(label)", file: file, line: line)
    }

    @MainActor private func waitForDistance(
        _ app: XCUIApplication, greaterThan previous: Int,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let predicate = NSPredicate { _, _ in
            let distance = app.staticTexts["distance"]
            guard distance.exists, let metres = Int(distance.label.filter(\.isNumber)) else { return false }
            return metres > previous && !app.buttons["resume"].exists && !app.buttons["rideAgain"].exists
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: 5), .completed,
            "Holding the throttle must increase distance while the ride is still playing", file: file, line: line)
    }

    @MainActor func testReadableLivesPortraitAndRecovery() throws {
        try checkReadableLives(orientation: .portrait, recover: true)
    }

    @MainActor func testReadableLivesLandscape() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("The iPhone app supports portrait; validate landscape on iPad")
        }
        try checkReadableLives(orientation: .landscapeLeft, recover: false)
    }

    @MainActor private func checkReadableLives(orientation: UIDeviceOrientation, recover: Bool) throws {
        XCUIDevice.shared.orientation = orientation
        let app = launch(extraArguments: ["-audio.muted", "YES", "-world", "mine"])
        defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        app.buttons["startEndless"].tap()
        waitForPlaying(app)
        let lives = app.descendants(matching: .any).matching(identifier: "lives").firstMatch
        XCTAssertTrue(lives.waitForExistence(timeout: 5))
        XCTAssertEqual(lives.value as? String, "3 of 3 remaining")
        // Accessibility reports the painted SF Symbol bounds, not its padded frame.
        XCTAssertGreaterThanOrEqual(lives.frame.height, orientation == .portrait ? 17 : 16)
        XCTAssertLessThanOrEqual(lives.frame.height, 22, "Keep the revised hearts compact")
        let viewport = app.windows.firstMatch.frame
        XCTAssertEqual(viewport.width > viewport.height, orientation != .portrait)
        XCTAssertGreaterThan(lives.frame.minY, app.staticTexts["score"].frame.maxY)
        XCTAssertGreaterThan(lives.frame.minY, app.staticTexts["distance"].frame.maxY)
        XCTAssertLessThan(lives.frame.maxY, app.windows.firstMatch.frame.height * 0.42)
        let height = lives.frame.height
        capture(orientation == .portrait ? "readable-lives-portrait" : "readable-lives-landscape")
        if recover {
            for _ in 0..<8 {
                if lives.value as? String != "3 of 3 remaining" { break }
                app.buttons["throttle"].press(forDuration: 3)
            }
            XCTAssertNotEqual(lives.value as? String, "3 of 3 remaining", "Exercise a real lost life")
            XCTAssertFalse(app.buttons["rideAgain"].exists, "A lost life must continue the endless ride")
            for _ in 0..<4 {
                XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'recovering' OR label CONTAINS[c] 'back on track'")).firstMatch.exists)
                Thread.sleep(forTimeInterval: 0.4)
            }
            XCTAssertEqual(lives.frame.height, height, accuracy: 1)
            waitForPlaying(app)
            capture("readable-lives-after-loss")
        }
    }

    @MainActor func testAllRidersAndWorldsRenderAndPlay() throws {
        let app = launch()
        let pairs = [
            ("croco", "canyon"), ("shiba", "japan"), ("eagle", "highway"),
            ("tiger", "jungle"), ("polar", "arctic"), ("flamingo", "mine"),
            ("toucan", "sanfrancisco"), ("raccoon", "paris"), ("axolotl", "clouds"),
        ]
        for (rider, world) in pairs {
            for (panel, selection) in [("worlds", world), ("riders", rider)] {
                app.buttons[panel].tap()
                let choice = app.buttons["select-\(selection)"]
                reveal(choice, in: app)
                XCTAssertTrue(choice.isHittable, "Missing selectable \(selection)")
                choice.tap()
                waitForHome(app)
                app.buttons[panel].tap()
                reveal(choice, in: app)
                if panel == "riders" {
                    Thread.sleep(forTimeInterval: 0.3)
                    capture("picker-\(rider)-a")
                    Thread.sleep(forTimeInterval: 0.7)
                    capture("picker-\(rider)-b")
                }
                app.buttons["closePanel"].tap()
            }
            capture("catalog-\(world)-\(rider)")
            app.buttons["startEndless"].tap()
            assertNoSavedRunPrompt(app)
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
