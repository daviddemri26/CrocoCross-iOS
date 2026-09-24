// Run in both Debug (-D DEBUG) and Release (no flag) with:
// xcrun swiftc -swift-version 6 -D DEBUG App/Services/LocalStore.swift App/CatalogAvailability.swift App/Services/WorldProgression.swift scripts/check-world-progression.swift -o /tmp/crococross-world-progression-check
import Foundation

@main struct CheckWorldProgression {
    enum Failure: Error { case expectation(String) }
    static func expect(_ condition: Bool, _ message: String) throws {
        if !condition { throw Failure.expectation(message) }
    }

    @MainActor static func main() throws {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--world-progression-fixture-probe") {
            let progression = WorldProgression.forCurrentLaunch()
            print("\(progression.state.landedFrontflips):\(progression.state.japanClaimed)")
            return
        }
        #endif
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("CrocoCrossWorldProgressionChecks-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalStore(rootURL: root)
        let progress = WorldProgression(store: store)
        let target = WorldProgression.japanRequirement
        #if DEBUG
        try expect(target == 2 && WorldProgression.filename == "world-progression.debug.json", "Debug uses its own two-frontflip save")
        let otherFilename = "world-progression.json"
        #else
        try expect(target == 50 && WorldProgression.filename == "world-progression.json", "Production uses its own fifty-frontflip save")
        let otherFilename = "world-progression.debug.json"
        #endif
        try expect(progress.state.landedFrontflips == 0 && !progress.japanAvailability.isUnlocked, "Fresh Japan progression is locked at zero")
        try expect(!progress.claimJapan(), "Japan cannot be claimed before the threshold")
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
        try expect(afterQuit.state.landedFrontflips == min(3, target), "Double frontflips count up to the threshold and a new run may restart its tick counter")
        let afterAnotherRun = WorldProgression(store: store)
        afterAnotherRun.recordLanding(frontflips: 1, runID: firstRun, tick: 20)
        try expect(afterAnotherRun.state.landedFrontflips == min(3, target), "An earlier run's duplicate is still ignored after a newer run and relaunch")
        afterAnotherRun.recordLanding(frontflips: 1, runID: firstRun, tick: 21)
        try expect(afterAnotherRun.state.landedFrontflips == min(4, target), "A subsequent safe reception in the same run counts until the threshold")
        if target > 4 { afterAnotherRun.recordLanding(frontflips: target - 4, runID: UUID(), tick: 1) }
        try expect(afterAnotherRun.japanAvailability.isReadyToUnlock && !afterAnotherRun.japanAvailability.isUnlocked, "Meeting the requirement enables an explicit claim")
        try expect(afterAnotherRun.japanAvailability.progress?.text == "\(target) / \(target)", "The progress display caps at its requirement")
        let readyState = afterAnotherRun.state
        afterAnotherRun.recordLanding(frontflips: Int.max, runID: UUID(), tick: 1)
        try expect(afterAnotherRun.state == readyState, "Ready progress stops tracking further receptions or run identities")
        try expect(afterAnotherRun.claimJapan(), "A ready claim succeeds")
        try expect(!afterAnotherRun.claimJapan(), "A claim is consumed exactly once")
        let claimedState = afterAnotherRun.state
        afterAnotherRun.recordLanding(frontflips: 1, runID: UUID(), tick: 1)
        try expect(afterAnotherRun.state == claimedState, "Claimed Japan never grows the progress counter or event ledger")
        try expect(WorldProgression(store: store).japanAvailability.isUnlocked, "Japan stays unlocked after an interrupted animation or relaunch")
        try expect(WorldProgression(store: store, filename: otherFilename).state == .init(), "Debug and production progress are isolated")

        let bounded = WorldProgression(store: store, filename: "bounded.json")
        for _ in 0..<(target + 10) { bounded.recordLanding(frontflips: 1, runID: UUID(), tick: 1) }
        try expect(bounded.state.landedFrontflips == target && bounded.state.creditedRunTicks.count == target, "Both the count and saved run ledger remain bounded by the unlock requirement")
        let multiple = WorldProgression(store: store, filename: "multiple.json")
        multiple.recordLanding(frontflips: 2, runID: UUID(), tick: 1)
        try expect(multiple.state.landedFrontflips == 2, "A double frontflip credits two at one reception")

        // Fail both reception persistence and claim, then recover without losing the reception.
        let blockedRoot = root.appendingPathComponent("blocked")
        try Data("file blocks directory".utf8).write(to: blockedRoot)
        let retry = WorldProgression(store: LocalStore(rootURL: blockedRoot))
        let retryRun = UUID()
        retry.recordLanding(frontflips: target, runID: retryRun, tick: 1)
        retry.recordLanding(frontflips: target, runID: retryRun, tick: 1)
        try expect(retry.state.landedFrontflips == target, "A failed write does not duplicate the in-memory reception")
        try expect(retry.saveError != nil && !retry.claimJapan() && !retry.state.japanClaimed, "A failed write cannot grant Japan")
        try FileManager.default.removeItem(at: blockedRoot)
        retry.flush()
        try expect(retry.saveError == nil, "A pending reception can be flushed after storage recovers")
        try expect(WorldProgression(store: LocalStore(rootURL: blockedRoot)).state.landedFrontflips == target, "Retried reception persistence survives relaunch")
        try expect(retry.claimJapan(), "A failed claim can be retried successfully")
        try expect(WorldProgression(store: LocalStore(rootURL: blockedRoot)).japanAvailability.isUnlocked, "The retried claim is durable")

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
            unreadable.recordLanding(frontflips: target, runID: UUID(), tick: 1)
            unreadable.flush()
            try expect(!unreadable.claimJapan() && unreadable.saveError != nil, "Unreadable state cannot be replaced by a claim: \(filename)")
            try expect(try Data(contentsOf: url) == original, "Unreadable data is preserved: \(filename)")
        }

        #if DEBUG
        try checkLaunchFixtures()
        #endif
        print("PASS: \(target)-frontflip threshold, bounded progress and event ledger, safe-reception counts, multiple flips, cross-run/relaunch idempotence, cumulative immediate saves, durable claim, Debug/Release isolation, failure recovery and unreadable-save preservation.")
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
        try expect(try probe(["-world-unlock-fixture-frontflips", "1"]) == "1:false", "A Debug launch can seed frontflip progress")
        try expect(try probe(["-world-unlock-fixture-frontflips", "2", "-world-unlock-fixture-claimed"]) == "1:false", "Relaunch fixtures never overwrite saved progress")
        try FileManager.default.removeItem(at: fixtureRoot)
        try expect(try probe(["-world-unlock-fixture-claimed"]) == "2:true", "A Debug UI test can seed a durably claimed Japan")
        try expect(try probe([]) == "2:true", "A claimed UI fixture survives a relaunch")
    }
    #endif
}
