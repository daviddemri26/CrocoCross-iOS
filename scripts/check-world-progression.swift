// Run in both Debug (-D DEBUG) and Release (no flag) with:
// xcrun swiftc -swift-version 6 -D DEBUG App/Services/LocalStore.swift App/CatalogAvailability.swift App/Services/WorldProgression.swift scripts/check-world-progression.swift -o /tmp/crococross-world-progression-check
import Foundation

@main struct CheckWorldProgression {
    enum Failure: Error { case expectation(String) }
    struct JapanOnlyState: Codable {
        var landedFrontflips: Int
        var japanClaimed: Bool
        var lastLanding: WorldProgression.Landing?
        var creditedRunTicks: [String: Int]
    }
    static func expect(_ condition: Bool, _ message: String) throws {
        if !condition { throw Failure.expectation(message) }
    }

    @MainActor static func main() throws {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--world-progression-fixture-probe") {
            let progression = WorldProgression.forCurrentLaunch()
            print("\(progression.state.landedFrontflips):\(progression.state.japanClaimed):\(progression.state.jungleClaimed)")
            return
        }
        #endif
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("CrocoCrossWorldProgressionChecks-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalStore(rootURL: root)
        let progress = WorldProgression(store: store)
        let target = WorldProgression.japanRequirement
        let jungleTarget = WorldProgression.jungleRequirement
        #if DEBUG
        try expect(target == 2 && jungleTarget == 2 && WorldProgression.filename == "world-progression.debug.json", "Debug uses its own two-frontflip save for both worlds")
        let otherFilename = "world-progression.json"
        #else
        try expect(target == 50 && jungleTarget == 100 && WorldProgression.filename == "world-progression.json", "Production requires 50 frontflips for Japan and 100 for Jungle")
        let otherFilename = "world-progression.debug.json"
        #endif
        try expect(progress.state.landedFrontflips == 0 && !progress.japanAvailability.isUnlocked && !progress.jungleAvailability.isUnlocked, "Both worlds start locked at zero")
        try expect(!progress.claimJapan() && !progress.claimJungle(), "Neither world can be claimed before its threshold")
        let firstRun = UUID()
        progress.recordLanding(frontflips: 0, runID: firstRun, tick: 10)
        progress.recordLanding(frontflips: -1, runID: firstRun, tick: 11)
        progress.recordLanding(frontflips: 1, runID: firstRun, tick: -1)
        try expect(progress.state.landedFrontflips == 0, "Backflip-only receptions, invalid counts and invalid ticks do not advance")
        progress.recordLanding(frontflips: 1, runID: firstRun, tick: 20)
        progress.recordLanding(frontflips: 1, runID: firstRun, tick: 20)
        progress.recordLanding(frontflips: 1, runID: firstRun, tick: 19)
        try expect(progress.state.landedFrontflips == 1, "Duplicate or stale receptions are ignored")
        let afterQuit = WorldProgression(store: store)
        try expect(afterQuit.state.landedFrontflips == 1, "A safe reception is durable before run completion")
        afterQuit.recordLanding(frontflips: 1, runID: firstRun, tick: 20)
        try expect(afterQuit.state.landedFrontflips == 1, "A saved reception is not credited again after relaunch")
        afterQuit.recordLanding(frontflips: 2, runID: UUID(), tick: 1)
        try expect(afterQuit.state.landedFrontflips == min(3, jungleTarget), "Double frontflips count up to the highest threshold and a new run may restart its tick counter")
        let afterAnotherRun = WorldProgression(store: store)
        afterAnotherRun.recordLanding(frontflips: 1, runID: firstRun, tick: 20)
        try expect(afterAnotherRun.state.landedFrontflips == min(3, jungleTarget), "An earlier run's duplicate is still ignored after a newer run and relaunch")
        afterAnotherRun.recordLanding(frontflips: 1, runID: firstRun, tick: 21)
        try expect(afterAnotherRun.state.landedFrontflips == min(4, jungleTarget), "A subsequent safe reception in the same run counts until the highest threshold")
        if target > 4 { afterAnotherRun.recordLanding(frontflips: target - 4, runID: UUID(), tick: 1) }
        try expect(afterAnotherRun.japanAvailability.isReadyToUnlock && !afterAnotherRun.japanAvailability.isUnlocked, "Meeting the requirement enables an explicit claim")
        try expect(afterAnotherRun.japanAvailability.progress?.text == "\(target) / \(target)", "The progress display caps at its requirement")
        try expect(afterAnotherRun.claimJapan(), "A ready claim succeeds")
        try expect(!afterAnotherRun.claimJapan(), "A claim is consumed exactly once")
        afterAnotherRun.recordLanding(frontflips: 1, runID: UUID(), tick: 1)
        try expect(afterAnotherRun.state.landedFrontflips == min(target + 1, jungleTarget) && afterAnotherRun.state.japanClaimed,
                   "The same cumulative counter continues towards Jungle after claiming Japan")
        try expect(WorldProgression(store: store).japanAvailability.isUnlocked, "Japan stays unlocked after an interrupted animation or relaunch")
        try expect(WorldProgression(store: store, filename: otherFilename).state == .init(), "Debug and production progress are isolated")

        if target < jungleTarget {
            afterAnotherRun.recordLanding(frontflips: jungleTarget - afterAnotherRun.state.landedFrontflips - 1, runID: UUID(), tick: 1)
            try expect(afterAnotherRun.state.landedFrontflips == 99 && !afterAnotherRun.claimJungle(), "99 successful frontflips do not unlock Jungle in production")
            afterAnotherRun.recordLanding(frontflips: 1, runID: UUID(), tick: 1)
        }
        try expect(afterAnotherRun.jungleAvailability.isReadyToUnlock && !afterAnotherRun.jungleAvailability.isUnlocked,
                   "Jungle becomes claimable at its own threshold")
        try expect(afterAnotherRun.jungleAvailability.progress?.text == "\(jungleTarget) / \(jungleTarget)", "Jungle displays its own requirement")
        let readyState = afterAnotherRun.state
        afterAnotherRun.recordLanding(frontflips: Int.max, runID: UUID(), tick: 1)
        try expect(afterAnotherRun.state == readyState, "Progress and event identities stop growing at the highest requirement")
        try expect(afterAnotherRun.claimJungle() && !afterAnotherRun.claimJungle(), "The Jungle claim is consumed exactly once")
        let claimedState = afterAnotherRun.state
        afterAnotherRun.recordLanding(frontflips: 1, runID: UUID(), tick: 1)
        try expect(afterAnotherRun.state == claimedState, "Claimed worlds never grow the capped progress or event ledger")
        let afterClaims = WorldProgression(store: store)
        try expect(afterClaims.japanAvailability.isUnlocked && afterClaims.jungleAvailability.isUnlocked, "Both durable claims survive a relaunch")

        let bounded = WorldProgression(store: store, filename: "bounded.json")
        for _ in 0..<(jungleTarget + 10) { bounded.recordLanding(frontflips: 1, runID: UUID(), tick: 1) }
        try expect(bounded.state.landedFrontflips == jungleTarget && bounded.state.creditedRunTicks.count == jungleTarget, "Both the count and saved run ledger are bounded by the highest requirement")
        try expect(bounded.claimJungle() && !bounded.state.japanClaimed, "Jungle can be claimed independently without automatically claiming Japan")
        let multiple = WorldProgression(store: store, filename: "multiple.json")
        multiple.recordLanding(frontflips: 2, runID: UUID(), tick: 1)
        try expect(multiple.state.landedFrontflips == 2, "A double frontflip credits two at one reception")
        let overflow = WorldProgression(store: store, filename: "overflow.json")
        overflow.recordLanding(frontflips: Int.max, runID: UUID(), tick: 1)
        try expect(overflow.state.landedFrontflips == jungleTarget, "An extreme positive count safely saturates at the goal")

        try checkJapanMigration(store: store, root: root)

        // Fail both reception persistence and claim, then recover without losing the reception.
        let blockedRoot = root.appendingPathComponent("blocked")
        try Data("file blocks directory".utf8).write(to: blockedRoot)
        let retry = WorldProgression(store: LocalStore(rootURL: blockedRoot))
        let retryRun = UUID()
        retry.recordLanding(frontflips: jungleTarget, runID: retryRun, tick: 1)
        retry.recordLanding(frontflips: jungleTarget, runID: retryRun, tick: 1)
        try expect(retry.state.landedFrontflips == jungleTarget, "A failed write does not duplicate the in-memory reception")
        try expect(retry.saveError != nil && !retry.claimJapan() && !retry.claimJungle() && !retry.state.japanClaimed && !retry.state.jungleClaimed,
                   "A failed write cannot grant either world")
        try FileManager.default.removeItem(at: blockedRoot)
        retry.flush()
        try expect(retry.saveError == nil, "A pending reception can be flushed after storage recovers")
        try expect(WorldProgression(store: LocalStore(rootURL: blockedRoot)).state.landedFrontflips == jungleTarget, "Retried reception persistence survives relaunch")
        try expect(retry.claimJapan() && retry.claimJungle(), "Failed claims can be retried successfully")
        let recovered = WorldProgression(store: LocalStore(rootURL: blockedRoot))
        try expect(recovered.japanAvailability.isUnlocked && recovered.jungleAvailability.isUnlocked, "Both retried claims are durable")

        // Valid JSON with invalid data, malformed JSON, and newer versions must remain untouched.
        let invalidState = WorldProgression.State(landedFrontflips: -1)
        try store.save(invalidState, to: "negative.json")
        try store.save(WorldProgression.State(creditedRunTicks: [UUID().uuidString: -1]), to: "invalid-tick.json")
        try store.save(WorldProgression.State(), to: "newer.json", version: 2)
        try Data("not json".utf8).write(to: root.appendingPathComponent("corrupt.json"))
        for filename in ["negative.json", "invalid-tick.json", "newer.json", "corrupt.json"] {
            let url = root.appendingPathComponent(filename)
            let original = try Data(contentsOf: url)
            let unreadable = WorldProgression(store: store, filename: filename)
            unreadable.recordLanding(frontflips: jungleTarget, runID: UUID(), tick: 1)
            unreadable.flush()
            try expect(!unreadable.claimJapan() && !unreadable.claimJungle() && unreadable.saveError != nil, "Unreadable state cannot be replaced by either claim: \(filename)")
            try expect(try Data(contentsOf: url) == original, "Unreadable data is preserved: \(filename)")
        }

        #if DEBUG
        try checkLaunchFixtures()
        #endif
        print("PASS: Japan \(target) / Jungle \(jungleTarget) frontflips, Japan-save migration, cumulative progress, bounded event ledger, safe-reception counts, multiple flips, cross-run/relaunch idempotence, immediate saves, independent durable claims, Debug/Release isolation, failure recovery and unreadable-save preservation.")
    }

    @MainActor static func checkJapanMigration(store: LocalStore, root: URL) throws {
        let runID = UUID()
        let target = WorldProgression.japanRequirement
        let jungleTarget = WorldProgression.jungleRequirement
        let old = JapanOnlyState(landedFrontflips: target, japanClaimed: true,
                                 lastLanding: .init(runID: runID, tick: 75), creditedRunTicks: [runID.uuidString: 75])
        let filename = "japan-only.json"
        try store.save(old, to: filename)
        let original = try Data(contentsOf: root.appendingPathComponent(filename))
        let migrated = WorldProgression(store: store, filename: filename)
        try expect(migrated.saveError == nil && migrated.state.landedFrontflips == target && migrated.state.japanClaimed && !migrated.state.jungleClaimed,
                   "An original Japan save keeps its count and claimed Japan, with Jungle unclaimed")
        try expect(migrated.state.lastLanding == old.lastLanding && migrated.state.creditedRunTicks == old.creditedRunTicks,
                   "Migration retains reception identity and duplicate protection")
        migrated.recordLanding(frontflips: 1, runID: runID, tick: 75)
        migrated.flush()
        try expect(migrated.state.landedFrontflips == target && (try Data(contentsOf: root.appendingPathComponent(filename))) == original,
                   "Loading or replaying a saved event does not overwrite the original Japan save")
        if target < jungleTarget {
            try expect(!migrated.claimJungle(), "Previously claimed Japan does not unlock Jungle")
            migrated.recordLanding(frontflips: 1, runID: runID, tick: 76)
            try expect(migrated.state.landedFrontflips == 51, "Production resumes counting at 51 without losing the original 50")
            migrated.recordLanding(frontflips: jungleTarget - 51, runID: UUID(), tick: 1)
        }
        try expect(migrated.claimJungle(), "A migrated save may claim Jungle after meeting its requirement")
        let restored = WorldProgression(store: store, filename: filename)
        try expect(restored.state.landedFrontflips == jungleTarget && restored.state.japanClaimed && restored.state.jungleClaimed,
                   "Both claims and the extended counter survive migration and relaunch")

        let partial = JapanOnlyState(landedFrontflips: 1, japanClaimed: false,
                                     lastLanding: .init(runID: runID, tick: 25), creditedRunTicks: [runID.uuidString: 25])
        try store.save(partial, to: "partial-japan.json")
        let partialMigration = WorldProgression(store: store, filename: "partial-japan.json")
        try expect(partialMigration.state.landedFrontflips == 1 && !partialMigration.state.japanClaimed && !partialMigration.state.jungleClaimed,
                   "A partial old save retains its exact progress without granting either world")
    }

    #if DEBUG
    @MainActor static func checkLaunchFixtures() throws {
        let id = UUID()
        let fixtureRoot = FileManager.default.temporaryDirectory.appendingPathComponent("WorldProgressionUITests", isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: fixtureRoot) }
        func probe(_ arguments: [String]) throws -> String {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
            process.arguments = ["--world-progression-fixture-probe", "-ui-testing", "-world-unlock-test-id", id.uuidString] + arguments
            let output = Pipe()
            process.standardOutput = output
            try process.run()
            process.waitUntilExit()
            try expect(process.terminationStatus == 0, "The isolated fixture process succeeds")
            return String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        try expect(try probe(["-world-unlock-fixture-frontflips", "1"]) == "1:false:false", "A Debug launch can seed frontflip progress")
        try expect(try probe(["-world-unlock-fixture-frontflips", "2", "-world-unlock-fixture-claimed", "-jungle-unlock-fixture-claimed"]) == "1:false:false", "Relaunch fixtures never overwrite saved progress")
        try FileManager.default.removeItem(at: fixtureRoot)
        try expect(try probe(["-world-unlock-fixture-claimed"]) == "2:true:false", "The existing Japan fixture keeps its original behavior")
        try expect(try probe([]) == "2:true:false", "A claimed Japan UI fixture survives a relaunch")
        try FileManager.default.removeItem(at: fixtureRoot)
        try expect(try probe(["-jungle-unlock-fixture-claimed"]) == "2:false:true", "The Jungle fixture seeds only its durable claim")
        try expect(try probe([]) == "2:false:true", "A claimed Jungle fixture survives a relaunch")
        try FileManager.default.removeItem(at: fixtureRoot)
        try expect(try probe(["-world-unlock-fixture-claimed", "-jungle-unlock-fixture-claimed"]) == "2:true:true", "Both world fixtures may be seeded together")
    }
    #endif
}
