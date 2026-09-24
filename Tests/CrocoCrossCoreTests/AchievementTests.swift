import XCTest
@testable import CrocoCrossCore

final class AchievementTests: XCTestCase {
    private let earned = Date(timeIntervalSince1970: 1_800_000_000)
    private func definition(_ id: String) -> AchievementDefinition {
        AchievementCatalog.standard.first { $0.id == id }!
    }
    private func directory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AchievementTests-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
    @MainActor private func progress(_ service: AchievementProgression, _ id: String) -> AchievementProgress {
        service.state.progress(for: definition(id))
    }

    func testCurrentCatalogHasStableUniqueObtainableAchievementsAndBoundedPoints() {
        let all = AchievementCatalog.standard
        XCTAssertEqual(all.count, 40)
        XCTAssertEqual(Set(all.map(\.id)).count, all.count)
        XCTAssertEqual(Set(all.map(\.gameCenterID)).count, all.count)
        XCTAssertTrue(all.allSatisfy { (1...100).contains($0.points) && $0.target > 0 })
        XCTAssertEqual(all.reduce(0) { $0 + $1.points }, 1_000)
        XCTAssertEqual(all.filter { $0.requirement == .totalRotations }.map(\.target),
                       [10, 50, 100, 250, 500, 1_000, 2_500, 5_000, 10_000])
        XCTAssertEqual(all.filter { $0.category == .distance }.map(\.target),
                       [1_000, 2_000, 3_000, 4_000, 5_000, 6_000, 7_000, 8_000, 9_000, 10_000,
                        11_000, 12_000, 13_000, 14_000, 15_000, 20_000, 25_000, 30_000, 35_000, 40_000, 45_000, 50_000])
        let unlocks = all.filter { $0.category == .collection }
        XCTAssertEqual(Set(unlocks.map(\.id)), ["unlock.rider.shiba", "unlock.world.japan"])
        XCTAssertEqual(AchievementCatalog.riderUnlock(catalogID: "future", name: "Future").gameCenterID,
                       "com.daviddemri.crococross.achievement.unlock.rider.future")
    }

    @MainActor func testEmptyStateStartsAtZeroWithoutHistoricalStatistics() throws {
        let service = AchievementProgression(rootURL: try directory())
        for definition in service.catalog {
            let progress = service.state.progress(for: definition)
            XCTAssertEqual(progress.current, 0)
            XCTAssertEqual(progress.target, definition.target)
            XCTAssertFalse(progress.isCompleted)
            XCTAssertNil(progress.completedAt)
        }
    }

    @MainActor func testSingleJumpsNeverCombineIntoDoubleOrTripleAndMixedComboCountsOneJump() throws {
        let service = AchievementProgression(rootURL: try directory())
        let run = UUID()
        for tick in 1...3 { service.recordSafeLanding(backflips: 1, frontflips: 0, runID: run, tick: tick, at: earned) }
        XCTAssertEqual(progress(service, "stunt.total.10").current, 3)
        XCTAssertEqual(progress(service, "stunt.double.landed").current, 0)
        XCTAssertEqual(progress(service, "stunt.triple.landed").current, 0)
        XCTAssertEqual(progress(service, "stunt.double.landed").target, 1)
        XCTAssertEqual(progress(service, "stunt.triple.landed").target, 1)
        let newly = service.recordSafeLanding(backflips: 1, frontflips: 2, runID: run, tick: 4, at: earned)
        XCTAssertEqual(Set(newly.map(\.id)), ["stunt.frontflip.first", "stunt.double.landed", "stunt.triple.landed"])
        XCTAssertEqual(progress(service, "stunt.total.10").current, 6)
        XCTAssertEqual(progress(service, "stunt.triple.landed").completedAt, earned)
        XCTAssertTrue(service.recordSafeLanding(backflips: 1, frontflips: 2, runID: run, tick: 4).isEmpty)
        XCTAssertEqual(progress(service, "stunt.total.10").current, 6)
    }

    @MainActor func testDoubleAndTripleAreBinaryOneJumpAchievementsInEitherDirection() throws {
        let service = AchievementProgression(rootURL: try directory()), run = UUID()
        service.recordSafeLanding(backflips: 1, frontflips: 0, runID: run, tick: 1)
        service.recordSafeLanding(backflips: 0, frontflips: 1, runID: run, tick: 2)
        for id in ["stunt.double.landed", "stunt.triple.landed"] {
            XCTAssertEqual(progress(service, id).percentComplete, 0)
            XCTAssertEqual(progress(service, id).current, 0)
            XCTAssertEqual(progress(service, id).target, 1)
        }
        let double = service.recordSafeLanding(backflips: 1, frontflips: 1, runID: run, tick: 3)
        XCTAssertEqual(double.map(\.id), ["stunt.double.landed"])
        XCTAssertEqual(progress(service, "stunt.double.landed").current, 1)
        XCTAssertEqual(progress(service, "stunt.triple.landed").current, 0)
        XCTAssertEqual(progress(service, "stunt.total.10").current, 4)
        let triple = service.recordSafeLanding(backflips: 0, frontflips: 3, runID: run, tick: 4)
        XCTAssertEqual(triple.map(\.id), ["stunt.triple.landed"])
        XCTAssertEqual(progress(service, "stunt.triple.landed").current, 1)
        XCTAssertEqual(progress(service, "stunt.total.10").current, 7)
        let fresh = AchievementProgression(rootURL: try directory())
        let freshTriple = fresh.recordSafeLanding(backflips: 3, frontflips: 0, runID: UUID(), tick: 1)
        XCTAssertEqual(Set(freshTriple.map(\.id)), ["stunt.backflip.first", "stunt.double.landed", "stunt.triple.landed"])
        XCTAssertEqual(progress(fresh, "stunt.total.10").current, 3)
    }

    @MainActor func testLegacyFractionalComboProgressIsNotTransferredToBinaryAchievements() throws {
        let root = try directory(), file = root.appendingPathComponent(AchievementProgression.filename)
        let original = AchievementProgression(rootURL: root)
        original.recordWeeklyFinish(runID: UUID())
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        var value = try XCTUnwrap(json["value"] as? [String: Any])
        var local = try XCTUnwrap(value["local"] as? [String: Any])
        var entries = try XCTUnwrap(local["entries"] as? [String: Any])
        entries["stunt.double.first"] = ["current": 1, "target": 2]
        entries["stunt.triple.first"] = ["current": 2, "target": 3]
        local["entries"] = entries; value["local"] = local; json["value"] = value
        try JSONSerialization.data(withJSONObject: json).write(to: file)
        let service = AchievementProgression(rootURL: root)
        XCTAssertNil(service.saveError)
        service.mergeRemoteProgress(["com.daviddemri.crococross.achievement.stunt.double.first": 100,
                                     "com.daviddemri.crococross.achievement.stunt.triple.first": 100,
                                     definition("stunt.double.landed").gameCenterID: 50], playerID: "A")
        XCTAssertEqual(progress(service, "stunt.double.landed").percentComplete, 0)
        XCTAssertEqual(progress(service, "stunt.triple.landed").percentComplete, 0)
        service.recordSafeLanding(backflips: 1, frontflips: 0, runID: UUID(), tick: 1, playerID: "A")
        XCTAssertEqual(progress(service, "stunt.double.landed").percentComplete, 0)
        XCTAssertEqual(progress(service, "stunt.triple.landed").percentComplete, 0)
        service.recordSafeLanding(backflips: 0, frontflips: 2, runID: UUID(), tick: 1, playerID: "A")
        XCTAssertEqual(progress(service, "stunt.double.landed").percentComplete, 100)
        XCTAssertEqual(progress(service, "stunt.triple.landed").percentComplete, 0)
    }

    @MainActor func testLandingDeduplicationSurvivesNewRunRelaunchAndStaleCallbacks() throws {
        let root = try directory(), oldRun = UUID(), newRun = UUID()
        var service = AchievementProgression(rootURL: root)
        service.recordSafeLanding(backflips: 1, frontflips: 0, runID: oldRun, tick: 500, at: earned)
        service.recordSafeLanding(backflips: 0, frontflips: 1, runID: newRun, tick: 5, at: earned)
        service = AchievementProgression(rootURL: root)
        for tick in [499, 500] { XCTAssertTrue(service.recordSafeLanding(backflips: 3, frontflips: 0, runID: oldRun, tick: tick).isEmpty) }
        service.recordSafeLanding(backflips: 1, frontflips: 0, runID: newRun, tick: 6)
        XCTAssertEqual(progress(service, "stunt.total.10").current, 3)
        XCTAssertEqual(progress(service, "stunt.backflip.first").completedAt, earned)
    }

    @MainActor func testCumulativeRotationMilestonesStayBoundedAndCompletionDatesDoNotReplay() throws {
        let root = try directory(), run = UUID()
        var service = AchievementProgression(rootURL: root)
        var completedIDs: [String] = []
        for tick in 1...100 {
            let newlyCompleted = service.recordSafeLanding(backflips: tick % 2, frontflips: (tick + 1) % 2,
                                                            runID: run, tick: tick, at: earned).map(\.id)
            completedIDs += newlyCompleted
            XCTAssertEqual(progress(service, "stunt.total.100").current, Double(tick))
            XCTAssertEqual(progress(service, "stunt.total.100").isCompleted, tick == 100)
            XCTAssertEqual(newlyCompleted.contains("stunt.total.100"), tick == 100)
        }
        for target in [10, 50, 100] {
            let id = "stunt.total.\(target)"
            XCTAssertEqual(completedIDs.filter { $0 == id }.count, 1)
            XCTAssertEqual(progress(service, id).current, Double(target))
            XCTAssertEqual(progress(service, id).completedAt, earned)
        }
        service = AchievementProgression(rootURL: root)
        XCTAssertTrue(service.recordSafeLanding(backflips: 1, frontflips: 0, runID: run, tick: 101).isEmpty)
        XCTAssertEqual(progress(service, "stunt.total.100").current, 100)
        XCTAssertEqual(progress(service, "stunt.total.100").completedAt, earned)
        XCTAssertFalse(progress(service, "stunt.double.landed").isCompleted)
    }

    @MainActor func testExtendedRotationMilestonesCountMixedSinglesDoublesAndTriplesAcrossRelaunch() throws {
        let root = try directory(), run = UUID()
        var service = AchievementProgression(rootURL: root)
        var total = 0, tick = 0
        var completions: [String] = []
        for threshold in [250, 500, 1_000, 2_500, 5_000, 10_000] {
            let id = "stunt.total.\(threshold)"
            while total < threshold {
                XCTAssertFalse(progress(service, id).isCompleted)
                tick += 1
                let rotations = min(tick % 3 + 1, threshold - total)
                let backflips = tick % 3 == 0 ? 0 : tick % 3 == 1 ? rotations : rotations / 2
                let newly = service.recordSafeLanding(backflips: backflips, frontflips: rotations - backflips,
                                                      runID: run, tick: tick, at: earned.addingTimeInterval(Double(tick)))
                total += rotations
                completions += newly.map(\.id)
                XCTAssertEqual(progress(service, "stunt.total.10000").current, Double(total))
                XCTAssertEqual(newly.contains { $0.id == id }, total == threshold)
            }
            XCTAssertEqual(progress(service, id).current, Double(threshold))
            XCTAssertEqual(progress(service, id).completedAt, earned.addingTimeInterval(Double(tick)))
            XCTAssertEqual(completions.filter { $0 == id }.count, 1)
            service = AchievementProgression(rootURL: root)
            XCTAssertEqual(progress(service, "stunt.total.10000").current, Double(total))
            XCTAssertTrue(service.recordSafeLanding(backflips: 3, frontflips: 0, runID: run, tick: tick).isEmpty)
            XCTAssertEqual(progress(service, "stunt.total.10000").current, Double(total))
        }
        XCTAssertTrue(service.recordSafeLanding(backflips: 1, frontflips: 2, runID: run, tick: tick + 1).isEmpty)
        XCTAssertEqual(progress(service, "stunt.total.10000").current, 10_000)
        for id in ["stunt.backflip.first", "stunt.frontflip.first", "stunt.double.landed", "stunt.triple.landed"] {
            XCTAssertTrue(progress(service, id).isCompleted)
        }
        // A future goal must retain rotations beyond today's final 10,000 target.
        let future = AchievementDefinition(id: "stunt.total.20000", title: "Future", description: "Future", symbolName: "star",
                                           category: .stunts, target: 20_000, points: 1, requirement: .totalRotations)
        let expanded = AchievementProgression(rootURL: root, catalog: AchievementCatalog.standard + [future])
        XCTAssertEqual(expanded.state.progress(for: future).current, 10_003)
        XCTAssertEqual(expanded.state.progress(for: future).completedAt, nil)
    }

    @MainActor func testLegacyLifetimeMigrationPreservesKnownBoundsAndAccountOwnership() throws {
        let root = try directory(), guestRun = UUID(), playerBRun = UUID()
        let oldCatalog = AchievementCatalog.standard.filter { $0.requirement != .totalRotations || $0.target <= 100 }
        let original = AchievementProgression(rootURL: root, catalog: oldCatalog)
        for tick in 1...60 {
            original.recordSafeLanding(backflips: 1, frontflips: 1, runID: guestRun, tick: tick, at: earned)
        }
        _ = original.gameCenterProgress(for: "A")
        for tick in 1...10 {
            original.recordSafeLanding(backflips: 0, frontflips: 3, runID: playerBRun, tick: tick, playerID: "B", at: earned)
        }
        let file = root.appendingPathComponent(AchievementProgression.filename)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        var value = try XCTUnwrap(json["value"] as? [String: Any])
        for name in ["local", "guest"] {
            var state = try XCTUnwrap(value[name] as? [String: Any]); state.removeValue(forKey: "lifetimeRotations"); value[name] = state
        }
        var players = try XCTUnwrap(value["players"] as? [String: [String: Any]])
        for id in Array(players.keys) { players[id]?.removeValue(forKey: "lifetimeRotations") }
        value["players"] = players; json["value"] = value
        let legacy = try JSONSerialization.data(withJSONObject: json)
        try legacy.write(to: file)

        let migrated = AchievementProgression(rootURL: root)
        XCTAssertNil(migrated.saveError)
        XCTAssertEqual(migrated.guestAssignedTo, "A")
        for target in [250, 500, 1_000, 2_500, 5_000, 10_000] {
            XCTAssertEqual(progress(migrated, "stunt.total.\(target)").current, 100, "Recover the recorded bound, never infer the discarded 150 rotations")
            XCTAssertNil(progress(migrated, "stunt.total.\(target)").completedAt)
        }
        let newID = definition("stunt.total.250").gameCenterID
        XCTAssertEqual(migrated.gameCenterProgress(for: "A")[newID], 40)
        XCTAssertEqual(migrated.gameCenterProgress(for: "B")[newID], 12)
        XCTAssertEqual(progress(migrated, "stunt.total.100").completedAt, earned)
        XCTAssertNotEqual(try Data(contentsOf: file), legacy, "Migration is durably saved before any new landing")
        XCTAssertTrue(migrated.recordSafeLanding(backflips: 1, frontflips: 1, runID: guestRun, tick: 60).isEmpty)
        migrated.recordSafeLanding(backflips: 1, frontflips: 2, runID: guestRun, tick: 61, playerID: "A")
        migrated.recordSafeLanding(backflips: 0, frontflips: 1, runID: playerBRun, tick: 11, playerID: "B")
        let reloaded = AchievementProgression(rootURL: root)
        XCTAssertEqual(progress(reloaded, "stunt.total.250").current, 104)
        XCTAssertEqual(reloaded.gameCenterProgress(for: "A")[newID]!, 103.0 / 250 * 100, accuracy: 0.000001)
        XCTAssertEqual(reloaded.gameCenterProgress(for: "B")[newID]!, 31.0 / 250 * 100, accuracy: 0.000001)
    }

    @MainActor func testIncompleteLegacyProgressMigratesWithoutCompletingNewGoals() throws {
        let root = try directory()
        let original = AchievementProgression(rootURL: root)
        original.recordSafeLanding(backflips: 1, frontflips: 1, runID: UUID(), tick: 1)
        let file = root.appendingPathComponent(AchievementProgression.filename)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        var value = try XCTUnwrap(json["value"] as? [String: Any])
        for name in ["local", "guest"] {
            var state = try XCTUnwrap(value[name] as? [String: Any])
            state.removeValue(forKey: "lifetimeRotations")
            var entries = try XCTUnwrap(state["entries"] as? [String: Any])
            for target in [250, 500, 1_000, 2_500, 5_000, 10_000] { entries.removeValue(forKey: "stunt.total.\(target)") }
            state["entries"] = entries; value[name] = state
        }
        json["value"] = value
        try JSONSerialization.data(withJSONObject: json).write(to: file)
        let reloaded = AchievementProgression(rootURL: root)
        XCTAssertEqual(progress(reloaded, "stunt.total.250").current, 2)
        XCTAssertFalse(progress(reloaded, "stunt.total.250").isCompleted)
        XCTAssertEqual(progress(reloaded, "stunt.total.10000").current, 2)
        XCTAssertEqual(reloaded.gameCenterProgress(for: "A")[definition("stunt.total.10000").gameCenterID]!, 0.02, accuracy: 0.000001)
    }

    @MainActor func testInvalidLifetimeCounterIsPreservedAsUnreadable() throws {
        let root = try directory()
        let original = AchievementProgression(rootURL: root)
        original.recordSafeLanding(backflips: 1, frontflips: 0, runID: UUID(), tick: 1)
        let file = root.appendingPathComponent(AchievementProgression.filename)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        var value = try XCTUnwrap(json["value"] as? [String: Any])
        var state = try XCTUnwrap(value["local"] as? [String: Any])
        state["lifetimeRotations"] = -1; value["local"] = state; json["value"] = value
        let corrupt = try JSONSerialization.data(withJSONObject: json)
        try corrupt.write(to: file)
        let reloaded = AchievementProgression(rootURL: root)
        XCTAssertNotNil(reloaded.saveError)
        XCTAssertTrue(reloaded.recordSafeLanding(backflips: 1, frontflips: 0, runID: UUID(), tick: 1).isEmpty)
        XCTAssertEqual(try Data(contentsOf: file), corrupt)
    }

    @MainActor func testInvalidLandingInputsCannotGrantProgress() throws {
        let service = AchievementProgression(rootURL: try directory()), run = UUID()
        for (back, front, tick) in [(0, 0, 1), (-1, 1, 2), (1, -1, 3), (1, 0, -1), (Int.max, Int.max, 5)] {
            XCTAssertTrue(service.recordSafeLanding(backflips: back, frontflips: front, runID: run, tick: tick).isEmpty)
        }
        XCTAssertEqual(progress(service, "stunt.total.100").current, 0)
        // Invalid callbacks do not consume a later legitimate event identity.
        service.recordSafeLanding(backflips: 1, frontflips: 0, runID: run, tick: 1)
        XCTAssertEqual(progress(service, "stunt.total.100").current, 1)
    }

    @MainActor func testPendingOrCrashedRotationsNeverReachTheAchievementLedger() throws {
        let service = AchievementProgression(rootURL: try directory()), run = UUID()
        var tracker = StuntTracker()
        for tick in 0..<90 {
            let theta = Double(tick + 1) * .pi * 2 / 90
            let count = tracker.advance(delta: .pi * 2 / 90, orientation: atan2(sin(theta), cos(theta)), airborne: true, safeContact: false)
            if count > 0 { service.recordSafeLanding(backflips: tracker.landedBackflips, frontflips: tracker.landedFrontflips, runID: run, tick: tick) }
        }
        tracker.clear() // The simulation clears pending rotations when the reception crashes.
        for tick in 90..<110 {
            let count = tracker.advance(delta: 0, orientation: 0, airborne: false, safeContact: true)
            if count > 0 { service.recordSafeLanding(backflips: tracker.landedBackflips, frontflips: tracker.landedFrontflips, runID: run, tick: tick) }
        }
        XCTAssertEqual(progress(service, "stunt.total.100").current, 0)
    }

    @MainActor func testDistanceIsOneRunMaximumAndAllThresholdsCompleteAtTheirExactBoundary() throws {
        let service = AchievementProgression(rootURL: try directory()), first = UUID(), second = UUID()
        service.recordEndlessDistance(600, runID: first)
        service.recordEndlessDistance(500, runID: second)
        XCTAssertEqual(progress(service, "endless.distance.1000").current, 600)
        service.recordEndlessDistance(999.999, runID: first)
        XCTAssertFalse(progress(service, "endless.distance.1000").isCompleted)
        XCTAssertEqual(service.recordEndlessDistance(1_000, runID: first, at: earned).map(\.id), ["endless.distance.1000"])
        for definition in service.catalog where definition.category == .distance {
            if definition.target > 1_000 {
                service.recordEndlessDistance(definition.target - 0.001, runID: second, at: earned)
                XCTAssertFalse(service.state.progress(for: definition).isCompleted)
                XCTAssertEqual(service.recordEndlessDistance(definition.target, runID: second, at: earned).map(\.id), [definition.id])
            }
            XCTAssertTrue(service.state.progress(for: definition).isCompleted)
            XCTAssertEqual(service.state.progress(for: definition).completedAt, earned)
        }
        for invalid in [Double.nan, .infinity, -.infinity, -10] { XCTAssertTrue(service.recordEndlessDistance(invalid, runID: UUID()).isEmpty) }
        XCTAssertEqual(progress(service, "endless.distance.50000").current, 50_000)
    }

    @MainActor func testDistanceWritesAreCoalescedAndLifecycleFlushRetainsFractionalProgress() throws {
        let root = try directory(), run = UUID()
        let service = AchievementProgression(rootURL: root)
        service.recordEndlessDistance(10, runID: run)
        let url = root.appendingPathComponent(AchievementProgression.filename)
        let firstSave = try Data(contentsOf: url)
        service.recordEndlessDistance(10.25, runID: run)
        service.recordEndlessDistance(19.75, runID: run)
        XCTAssertEqual(try Data(contentsOf: url), firstSave)
        XCTAssertEqual(progress(service, "endless.distance.1000").current, 19.75, accuracy: 0.00001)
        service.flush()
        XCTAssertNotEqual(try Data(contentsOf: url), firstSave)
        XCTAssertEqual(progress(AchievementProgression(rootURL: root), "endless.distance.1000").current, 19.75, accuracy: 0.00001)
        service.recordEndlessDistance(20, runID: run)
        XCTAssertEqual(progress(AchievementProgression(rootURL: root), "endless.distance.1000").current, 20, accuracy: 0.00001)
    }

    @MainActor func testWeeklyFinishesCountOncePerRunAcrossRelaunch() throws {
        let root = try directory(), run = UUID()
        var service = AchievementProgression(rootURL: root)
        XCTAssertEqual(service.recordWeeklyFinish(runID: run, at: earned).map(\.id), ["weekly.finish.1"])
        service = AchievementProgression(rootURL: root)
        XCTAssertTrue(service.recordWeeklyFinish(runID: run).isEmpty)
        for count in 2...10 {
            let newlyCompleted = service.recordWeeklyFinish(runID: UUID()).map(\.id)
            XCTAssertEqual(progress(service, "weekly.finish.10").current, Double(count))
            XCTAssertEqual(progress(service, "weekly.finish.10").isCompleted, count == 10)
            XCTAssertEqual(newlyCompleted.contains("weekly.finish.10"), count == 10)
        }
        XCTAssertTrue(progress(service, "weekly.finish.10").isCompleted)
        XCTAssertEqual(progress(service, "weekly.finish.1").completedAt, earned)
    }

    @MainActor func testOnlyActualClaimsImportIdempotentlyAndStartersNeverAward() throws {
        let root = try directory()
        var service = AchievementProgression(rootURL: root)
        service.importClaimedUnlocks(riderIDs: ["croco", "shiba", "eagle"], worldIDs: ["canyon", "japan", "paris"], at: earned)
        service = AchievementProgression(rootURL: root)
        service.importClaimedUnlocks(riderIDs: ["shiba"], worldIDs: ["japan"])
        XCTAssertEqual(service.catalog.filter { service.state.progress(for: $0).isCompleted }.map(\.id), ["unlock.rider.shiba", "unlock.world.japan"])
        XCTAssertEqual(progress(service, "unlock.rider.shiba").completedAt, earned)
        XCTAssertEqual(progress(service, "stunt.backflip.first").current, 0)
        XCTAssertEqual(progress(service, "weekly.finish.1").current, 0)
        XCTAssertTrue(service.recordUnlock(kind: .rider, catalogID: "shiba", playerID: "B").isEmpty)
        let custom = AchievementProgression(rootURL: try directory(), catalog: [AchievementCatalog.riderUnlock(catalogID: "future", name: "Future")])
        XCTAssertEqual(custom.recordUnlock(kind: .rider, catalogID: "future").count, 1)
    }

    @MainActor func testGuestAdoptionIsDurableAndNeverTransfersToSecondAccount() throws {
        let root = try directory(), guestRun = UUID()
        var service = AchievementProgression(rootURL: root)
        service.recordSafeLanding(backflips: 2, frontflips: 0, runID: guestRun, tick: 1)
        let id = definition("stunt.total.100").gameCenterID
        XCTAssertEqual(service.gameCenterProgress(for: "A")[id], 2)
        XCTAssertEqual(service.guestAssignedTo, "A")
        service = AchievementProgression(rootURL: root)
        XCTAssertEqual(service.gameCenterProgress(for: "B")[id], 0)
        service.recordSafeLanding(backflips: 1, frontflips: 0, runID: guestRun, tick: 2, playerID: "B")
        XCTAssertEqual(service.gameCenterProgress(for: "A")[id], 3) // A owns the original guest run.
        XCTAssertEqual(service.gameCenterProgress(for: "B")[id], 0)
        service.recordSafeLanding(backflips: 1, frontflips: 0, runID: UUID(), tick: 1, playerID: "B")
        XCTAssertEqual(service.gameCenterProgress(for: "B")[id], 1)
        service.recordSafeLanding(backflips: 1, frontflips: 0, runID: UUID(), tick: 1)
        XCTAssertEqual(service.gameCenterProgress(for: "A")[id], 4) // Later guest play still belongs to the first owner.
        XCTAssertEqual(progress(service, "stunt.total.100").current, 5)
    }

    @MainActor func testRemoteCumulativeBoundsAdvanceWithNewEventsWhileMaximaDoNotAdd() throws {
        let service = AchievementProgression(rootURL: try directory())
        let rotations = definition("stunt.total.100"), weekly = definition("weekly.finish.10")
        let distance = definition("endless.distance.10000"), triple = definition("stunt.triple.landed")
        service.mergeRemoteProgress([rotations.gameCenterID: 10, weekly.gameCenterID: 50,
                                     distance.gameCenterID: 50, triple.gameCenterID: 100 * 2 / 3], playerID: "A")
        let run = UUID()
        service.recordSafeLanding(backflips: 1, frontflips: 0, runID: run, tick: 1, playerID: "A")
        service.recordWeeklyFinish(runID: run, playerID: "A")
        service.recordEndlessDistance(1_000, runID: run, playerID: "A")
        XCTAssertEqual(progress(service, rotations.id).current, 11, accuracy: 0.00001)
        XCTAssertEqual(progress(service, weekly.id).current, 6, accuracy: 0.00001)
        XCTAssertEqual(progress(service, distance.id).current, 5_000, accuracy: 0.00001)
        XCTAssertEqual(progress(service, triple.id).current, 0)
        XCTAssertFalse(progress(service, triple.id).isCompleted)
    }

    @MainActor func testRemoteCompletionIsMonotonicUndatedUnlessKnownAndDoesNotReplay() throws {
        let root = try directory(), back = definition("stunt.backflip.first"), front = definition("stunt.frontflip.first")
        var service = AchievementProgression(rootURL: root)
        service.mergeRemoteProgress([back.gameCenterID: 100, front.gameCenterID: 100], playerID: "A", completionDates: [front.gameCenterID: earned])
        XCTAssertTrue(progress(service, back.id).isCompleted)
        XCTAssertNil(progress(service, back.id).completedAt)
        XCTAssertEqual(progress(service, front.id).completedAt, earned)
        service.mergeRemoteProgress([back.gameCenterID: 0, front.gameCenterID: -1, "unrecognized": 100], playerID: "A")
        service = AchievementProgression(rootURL: root)
        XCTAssertTrue(service.recordSafeLanding(backflips: 1, frontflips: 0, runID: UUID(), tick: 1, playerID: "A").isEmpty)
        XCTAssertNil(progress(service, back.id).completedAt)
        XCTAssertEqual(service.gameCenterProgress(for: "B")[back.gameCenterID], 0)
    }

    @MainActor func testSavingFailureRetainsEventsAndBlocksUndurableGuestAttributionUntilRetry() throws {
        let parent = try directory(), blocked = parent.appendingPathComponent("not-a-directory")
        try Data("blocker".utf8).write(to: blocked)
        let service = AchievementProgression(rootURL: blocked)
        let run = UUID(), id = definition("stunt.total.100").gameCenterID
        service.recordSafeLanding(backflips: 1, frontflips: 0, runID: run, tick: 1)
        XCTAssertNotNil(service.saveError)
        XCTAssertEqual(progress(service, "stunt.total.100").current, 1)
        XCTAssertTrue(service.gameCenterProgress(for: "A").isEmpty)
        try FileManager.default.removeItem(at: blocked)
        service.flush()
        XCTAssertNil(service.saveError)
        let loaded = AchievementProgression(rootURL: blocked)
        XCTAssertEqual(loaded.guestAssignedTo, "A")
        XCTAssertEqual(loaded.gameCenterProgress(for: "A")[id], 1)
        XCTAssertTrue(loaded.recordSafeLanding(backflips: 1, frontflips: 0, runID: run, tick: 1).isEmpty)
    }

    @MainActor func testCorruptAndFutureSavesArePreservedAndNeverOverwritten() throws {
        for bytes in [Data("broken".utf8), Data("{\"version\":999,\"value\":{}}".utf8)] {
            let root = try directory(), file = root.appendingPathComponent(AchievementProgression.filename)
            try bytes.write(to: file)
            let service = AchievementProgression(rootURL: root)
            XCTAssertNotNil(service.saveError)
            XCTAssertTrue(service.recordWeeklyFinish(runID: UUID()).isEmpty)
            service.importClaimedUnlocks(riderIDs: ["shiba"], worldIDs: ["japan"])
            service.mergeRemoteProgress([definition("weekly.finish.1").gameCenterID: 100], playerID: "A")
            service.flush()
            XCTAssertTrue(service.gameCenterProgress(for: "A").isEmpty)
            XCTAssertEqual(try Data(contentsOf: file), bytes)
        }
    }

    @MainActor func testNumericallyCorruptProgressCannotLoadOrBeOverwritten() throws {
        let root = try directory(), file = root.appendingPathComponent(AchievementProgression.filename)
        let service = AchievementProgression(rootURL: root)
        service.recordWeeklyFinish(runID: UUID())
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        var value = try XCTUnwrap(json["value"] as? [String: Any])
        var local = try XCTUnwrap(value["local"] as? [String: Any])
        var entries = try XCTUnwrap(local["entries"] as? [String: Any])
        var weekly = try XCTUnwrap(entries["weekly.finish.10"] as? [String: Any])
        weekly["current"] = -1
        entries["weekly.finish.10"] = weekly; local["entries"] = entries; value["local"] = local; json["value"] = value
        let corrupt = try JSONSerialization.data(withJSONObject: json)
        try corrupt.write(to: file)
        let reloaded = AchievementProgression(rootURL: root)
        XCTAssertNotNil(reloaded.saveError)
        XCTAssertTrue(reloaded.recordWeeklyFinish(runID: UUID()).isEmpty)
        reloaded.flush()
        XCTAssertEqual(try Data(contentsOf: file), corrupt)
    }

    @MainActor func testAutomatedFixtureStorageAndRemoteReportingStayIsolated() throws {
        let root = try directory()
        let fixture = AchievementProgression(rootURL: root.appendingPathComponent("UITests"), remoteReportingEnabled: false)
        fixture.recordSafeLanding(backflips: 1, frontflips: 0, runID: UUID(), tick: 1)
        XCTAssertTrue(fixture.gameCenterProgress(for: "A").isEmpty)
        fixture.mergeRemoteProgress([definition("weekly.finish.1").gameCenterID: 100], playerID: "A")
        XCTAssertFalse(progress(fixture, "weekly.finish.1").isCompleted)
        XCTAssertEqual(AchievementProgression.filename, "achievements.json")
        let normal = AchievementProgression(rootURL: root)
        XCTAssertEqual(progress(normal, "stunt.total.100").current, 0)
        XCTAssertNil(normal.guestAssignedTo)
    }
}
