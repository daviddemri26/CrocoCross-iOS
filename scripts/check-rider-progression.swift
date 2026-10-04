// Run in both Debug (-D DEBUG) and Release (no flag) with:
// xcrun swiftc -swift-version 6 -D DEBUG App/Services/LocalStore.swift App/CatalogAvailability.swift App/Services/RiderProgression.swift scripts/check-rider-progression.swift -o /tmp/crococross-rider-progression-check
import Foundation

@main struct CheckRiderProgression {
    enum Failure: Error { case expectation(String) }
    struct KenjiOnlyState: Codable {
        var landedBackflips: Int
        var kenjiClaimed: Bool
        var lastLanding: RiderProgression.Landing?
    }
    static func expect(_ condition: Bool, _ message: String) throws {
        if !condition { throw Failure.expectation(message) }
    }

    @MainActor static func main() throws {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--rider-progression-fixture-probe") {
            let progression = RiderProgression.forCurrentLaunch()
            print("\(progression.state.landedBackflips):\(progression.state.kenjiClaimed):\(progression.state.miloClaimed)")
            return
        }
        #endif
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("CrocoCrossRiderProgressionChecks-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalStore(rootURL: root)
        let progress = RiderProgression(store: store)
        let target = RiderProgression.kenjiRequirement
        let miloTarget = RiderProgression.miloRequirement
        #if DEBUG
        try expect(target == 2 && miloTarget == 2 && RiderProgression.filename == "rider-progression.debug.json", "Debug uses its own two-backflip save for both riders")
        let otherFilename = "rider-progression.json"
        #else
        try expect(target == 50 && miloTarget == 100 && RiderProgression.filename == "rider-progression.json", "Production requires 50 backflips for Kenji and 100 for Milo")
        let otherFilename = "rider-progression.debug.json"
        #endif
        try expect(progress.state.landedBackflips == 0 && !progress.kenjiAvailability.isUnlocked && !progress.miloAvailability.isUnlocked, "Both riders start locked at zero")
        try expect(!progress.claimKenji() && !progress.claimMilo(), "Neither rider can be claimed before its threshold")
        let firstRun = UUID()
        progress.recordLanding(backflips: 0, runID: firstRun, tick: 10)
        progress.recordLanding(backflips: -1, runID: firstRun, tick: 11)
        progress.recordLanding(backflips: 1, runID: firstRun, tick: -1)
        try expect(progress.state.landedBackflips == 0, "Frontflip-only receptions, invalid counts and invalid ticks do not advance")
        progress.recordLanding(backflips: 1, runID: firstRun, tick: 20)
        progress.recordLanding(backflips: 1, runID: firstRun, tick: 20)
        progress.recordLanding(backflips: 1, runID: firstRun, tick: 19)
        try expect(progress.state.landedBackflips == 1, "Duplicate or stale receptions are ignored")
        let afterQuit = RiderProgression(store: store)
        try expect(afterQuit.state.landedBackflips == 1, "A safe reception is durable before run completion")
        afterQuit.recordLanding(backflips: 1, runID: firstRun, tick: 20)
        try expect(afterQuit.state.landedBackflips == 1, "A saved reception is not credited again after relaunch")
        afterQuit.recordLanding(backflips: 2, runID: UUID(), tick: 1)
        try expect(afterQuit.state.landedBackflips == min(3, miloTarget), "Double backflips count up to the highest threshold and a new run may restart its tick counter")
        let afterAnotherRun = RiderProgression(store: store)
        afterAnotherRun.recordLanding(backflips: 1, runID: firstRun, tick: 20)
        try expect(afterAnotherRun.state.landedBackflips == min(3, miloTarget), "An earlier run's duplicate is still ignored after a newer run and relaunch")
        afterAnotherRun.recordLanding(backflips: 1, runID: firstRun, tick: 21)
        try expect(afterAnotherRun.state.landedBackflips == min(4, miloTarget), "A subsequent safe reception in the same run counts until the highest threshold")
        if target > 4 { afterAnotherRun.recordLanding(backflips: target - 4, runID: UUID(), tick: 1) }
        try expect(afterAnotherRun.kenjiAvailability.isReadyToUnlock && !afterAnotherRun.kenjiAvailability.isUnlocked, "Meeting the requirement enables an explicit claim")
        try expect(afterAnotherRun.kenjiAvailability.progress?.text == "\(target) / \(target)", "The progress display caps at its requirement")
        try expect(afterAnotherRun.claimKenji(), "A ready claim succeeds")
        try expect(!afterAnotherRun.claimKenji(), "A claim is consumed exactly once")
        afterAnotherRun.recordLanding(backflips: 1, runID: UUID(), tick: 1)
        try expect(afterAnotherRun.state.landedBackflips == min(target + 1, miloTarget) && afterAnotherRun.state.kenjiClaimed,
                   "The same cumulative counter continues towards Milo after claiming Kenji")
        try expect(RiderProgression(store: store).kenjiAvailability.isUnlocked, "Kenji stays unlocked after an interrupted animation or relaunch")
        try expect(RiderProgression(store: store, filename: otherFilename).state == .init(), "Debug and production progress are isolated")

        if target < miloTarget {
            afterAnotherRun.recordLanding(backflips: miloTarget - afterAnotherRun.state.landedBackflips - 1, runID: UUID(), tick: 1)
            try expect(afterAnotherRun.state.landedBackflips == 99 && !afterAnotherRun.claimMilo(), "99 successful backflips do not unlock Milo in production")
            afterAnotherRun.recordLanding(backflips: 1, runID: UUID(), tick: 1)
        }
        try expect(afterAnotherRun.miloAvailability.isReadyToUnlock && !afterAnotherRun.miloAvailability.isUnlocked,
                   "Milo becomes claimable at its own threshold")
        try expect(afterAnotherRun.miloAvailability.progress?.text == "\(miloTarget) / \(miloTarget)", "Milo displays its own requirement")
        let readyState = afterAnotherRun.state
        afterAnotherRun.recordLanding(backflips: Int.max, runID: UUID(), tick: 1)
        try expect(afterAnotherRun.state == readyState, "Progress and event identities stop growing at the highest requirement")
        try expect(afterAnotherRun.claimMilo() && !afterAnotherRun.claimMilo(), "The Milo claim is consumed exactly once")
        let claimedState = afterAnotherRun.state
        afterAnotherRun.recordLanding(backflips: 1, runID: UUID(), tick: 1)
        try expect(afterAnotherRun.state == claimedState, "Claimed riders never grow the capped progress or event ledger")
        let afterClaims = RiderProgression(store: store)
        try expect(afterClaims.kenjiAvailability.isUnlocked && afterClaims.miloAvailability.isUnlocked, "Both durable claims survive a relaunch")

        let bounded = RiderProgression(store: store, filename: "bounded.json")
        for _ in 0..<(miloTarget + 10) { bounded.recordLanding(backflips: 1, runID: UUID(), tick: 1) }
        try expect(bounded.state.landedBackflips == miloTarget && bounded.state.creditedRunTicks.count == miloTarget, "Both the count and saved run ledger are bounded by the highest requirement")
        try expect(bounded.claimMilo() && !bounded.state.kenjiClaimed, "Milo can be claimed independently without automatically claiming Kenji")
        let multiple = RiderProgression(store: store, filename: "multiple.json")
        multiple.recordLanding(backflips: 2, runID: UUID(), tick: 1)
        try expect(multiple.state.landedBackflips == 2, "A double backflip credits two at one reception")
        let overflow = RiderProgression(store: store, filename: "overflow.json")
        overflow.recordLanding(backflips: Int.max, runID: UUID(), tick: 1)
        try expect(overflow.state.landedBackflips == miloTarget, "An extreme positive count safely saturates at the goal")

        try checkKenjiMigration(store: store, root: root)

        // Fail both reception persistence and claim, then recover without losing the reception.
        let blockedRoot = root.appendingPathComponent("blocked")
        try Data("file blocks directory".utf8).write(to: blockedRoot)
        let retry = RiderProgression(store: LocalStore(rootURL: blockedRoot))
        let retryRun = UUID()
        retry.recordLanding(backflips: miloTarget, runID: retryRun, tick: 1)
        retry.recordLanding(backflips: miloTarget, runID: retryRun, tick: 1)
        try expect(retry.state.landedBackflips == miloTarget, "A failed write does not duplicate the in-memory reception")
        try expect(retry.saveError != nil && !retry.claimKenji() && !retry.claimMilo() && !retry.state.kenjiClaimed && !retry.state.miloClaimed,
                   "A failed write cannot grant either rider")
        try FileManager.default.removeItem(at: blockedRoot)
        retry.flush()
        try expect(retry.saveError == nil, "A pending reception can be flushed after storage recovers")
        try expect(RiderProgression(store: LocalStore(rootURL: blockedRoot)).state.landedBackflips == miloTarget, "Retried reception persistence survives relaunch")
        try expect(retry.claimKenji() && retry.claimMilo(), "Failed claims can be retried successfully")
        let recovered = RiderProgression(store: LocalStore(rootURL: blockedRoot))
        try expect(recovered.kenjiAvailability.isUnlocked && recovered.miloAvailability.isUnlocked, "Both retried claims are durable")

        // Valid JSON with invalid data, malformed JSON, and newer versions must remain untouched.
        let invalidState = RiderProgression.State(landedBackflips: -1)
        try store.save(invalidState, to: "negative.json")
        try store.save(RiderProgression.State(creditedRunTicks: [UUID().uuidString: -1]), to: "invalid-tick.json")
        let inconsistentRun = UUID()
        try store.save(RiderProgression.State(landedBackflips: 1, lastLanding: .init(runID: inconsistentRun, tick: 10),
                                             creditedRunTicks: [inconsistentRun.uuidString: -1]), to: "inconsistent-ledger.json")
        try store.save(RiderProgression.State(), to: "newer.json", version: 2)
        try Data("not json".utf8).write(to: root.appendingPathComponent("corrupt.json"))
        try Data(#"{"version":1,"value":{"landedBackflips":100,"kenjiClaimed":true,"miloClaimed":"true"}}"#.utf8)
            .write(to: root.appendingPathComponent("invalid-claim.json"))
        try Data(#"{"version":1,"value":{"landedBackflips":100,"kenjiClaimed":true,"miloClaimed":null}}"#.utf8)
            .write(to: root.appendingPathComponent("null-claim.json"))
        for filename in ["negative.json", "invalid-tick.json", "inconsistent-ledger.json", "newer.json", "corrupt.json", "invalid-claim.json", "null-claim.json"] {
            let url = root.appendingPathComponent(filename)
            let original = try Data(contentsOf: url)
            let unreadable = RiderProgression(store: store, filename: filename)
            unreadable.recordLanding(backflips: miloTarget, runID: UUID(), tick: 1)
            unreadable.flush()
            try expect(!unreadable.claimKenji() && !unreadable.claimMilo() && unreadable.saveError != nil, "Unreadable state cannot be replaced by either claim: \(filename)")
            try expect(try Data(contentsOf: url) == original, "Unreadable data is preserved: \(filename)")
        }

        #if DEBUG
        try checkLaunchFixtures()
        #endif
        print("PASS: Kenji \(target) / Milo \(miloTarget) backflips, Kenji-save migration, cumulative progress, bounded event ledger, safe-reception counts, multiple flips, cross-run/relaunch idempotence, immediate saves, independent durable claims, Debug/Release isolation, failure recovery and unreadable-save preservation.")
    }

    @MainActor static func checkKenjiMigration(store: LocalStore, root: URL) throws {
        let runID = UUID()
        let target = RiderProgression.kenjiRequirement
        let miloTarget = RiderProgression.miloRequirement
        let old = KenjiOnlyState(landedBackflips: target, kenjiClaimed: true,
                                 lastLanding: .init(runID: runID, tick: 75))
        let filename = "kenji-only.json"
        try store.save(old, to: filename)
        let original = try Data(contentsOf: root.appendingPathComponent(filename))
        let migrated = RiderProgression(store: store, filename: filename)
        try expect(migrated.saveError == nil && migrated.state.landedBackflips == target && migrated.state.kenjiClaimed && !migrated.state.miloClaimed,
                   "An original Kenji save keeps its count and claimed Kenji, with Milo unclaimed")
        try expect(migrated.state.lastLanding == old.lastLanding && migrated.state.creditedRunTicks == [runID.uuidString: 75],
                   "Migration retains reception identity and duplicate protection")
        migrated.recordLanding(backflips: 1, runID: runID, tick: 75)
        migrated.flush()
        try expect(migrated.state.landedBackflips == target && (try Data(contentsOf: root.appendingPathComponent(filename))) == original,
                   "Loading or replaying a saved event does not overwrite the original Kenji save")
        if target < miloTarget {
            try expect(!migrated.claimMilo(), "Previously claimed Kenji does not unlock Milo")
            migrated.recordLanding(backflips: 1, runID: runID, tick: 76)
            try expect(migrated.state.landedBackflips == 51, "Production resumes counting at 51 without losing the original 50")
            migrated.recordLanding(backflips: miloTarget - 51, runID: UUID(), tick: 1)
        }
        try expect(migrated.claimMilo(), "A migrated save may claim Milo after meeting its requirement")
        let restored = RiderProgression(store: store, filename: filename)
        try expect(restored.state.landedBackflips == miloTarget && restored.state.kenjiClaimed && restored.state.miloClaimed,
                   "Both claims and the extended counter survive migration and relaunch")

        let partial = KenjiOnlyState(landedBackflips: 1, kenjiClaimed: false,
                                     lastLanding: .init(runID: runID, tick: 25))
        try store.save(partial, to: "partial-kenji.json")
        let partialMigration = RiderProgression(store: store, filename: "partial-kenji.json")
        try expect(partialMigration.state.landedBackflips == 1 && !partialMigration.state.kenjiClaimed && !partialMigration.state.miloClaimed,
                   "A partial old save retains its exact progress without granting either rider")

        // Kenji previously kept a lifetime count. Do not erase already-earned history above the new goal.
        let high = KenjiOnlyState(landedBackflips: 123, kenjiClaimed: true, lastLanding: old.lastLanding)
        try store.save(high, to: "high-kenji.json")
        let highMigration = RiderProgression(store: store, filename: "high-kenji.json")
        highMigration.recordLanding(backflips: 1, runID: UUID(), tick: 1)
        try expect(highMigration.state.landedBackflips == 123 && highMigration.claimMilo(),
                   "A legacy lifetime count above 100 is preserved, stops increasing and qualifies for Milo")
    }

    #if DEBUG
    @MainActor static func checkLaunchFixtures() throws {
        let id = UUID()
        let fixtureRoot = FileManager.default.temporaryDirectory.appendingPathComponent("RiderProgressionUITests", isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: fixtureRoot) }
        func probe(_ arguments: [String]) throws -> String {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
            process.arguments = ["--rider-progression-fixture-probe", "-ui-testing", "-unlock-test-id", id.uuidString] + arguments
            let output = Pipe()
            process.standardOutput = output
            try process.run()
            process.waitUntilExit()
            try expect(process.terminationStatus == 0, "The isolated fixture process succeeds")
            return String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        try expect(try probe(["-unlock-fixture-backflips", "1"]) == "1:false:false", "A Debug launch can seed backflip progress")
        try expect(try probe(["-unlock-fixture-backflips", "2", "-milo-unlock-fixture-claimed"]) == "1:false:false", "Relaunch fixtures never overwrite saved progress")
        try FileManager.default.removeItem(at: fixtureRoot)
        try expect(try probe(["-unlock-fixture-backflips", "2"]) == "2:false:false", "The existing counter fixture keeps both claims explicit")
        try expect(try probe([]) == "2:false:false", "A ready counter fixture survives a relaunch")
        try FileManager.default.removeItem(at: fixtureRoot)
        try expect(try probe(["-milo-unlock-fixture-claimed"]) == "2:false:true", "The Milo fixture seeds only its durable claim")
        try expect(try probe([]) == "2:false:true", "A claimed Milo fixture survives a relaunch")
        try FileManager.default.removeItem(at: fixtureRoot)
        try expect(try probe(["-unlock-fixture-backflips", "1", "-milo-unlock-fixture-claimed"]) == "1:false:false", "A claim fixture never bypasses an explicitly insufficient counter")
    }
    #endif
}
