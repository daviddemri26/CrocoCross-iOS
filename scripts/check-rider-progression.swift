// Run in both Debug (-D DEBUG) and Release (no flag) with:
// xcrun swiftc -swift-version 6 -D DEBUG App/Services/LocalStore.swift App/CatalogAvailability.swift App/Services/RiderProgression.swift scripts/check-rider-progression.swift -o /tmp/crococross-progression-check
import Foundation

@main struct CheckRiderProgression {
    enum Failure: Error { case expectation(String) }
    static func expect(_ condition: Bool, _ message: String) throws {
        if !condition { throw Failure.expectation(message) }
    }

    @MainActor static func main() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("CrocoCrossProgressionChecks-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalStore(rootURL: root)
        let progress = RiderProgression(store: store)
        let target = RiderProgression.kenjiRequirement
        #if DEBUG
        try expect(target == 2 && RiderProgression.filename == "rider-progression.debug.json", "Debug uses its own two-flip save")
        let otherFilename = "rider-progression.json"
        #else
        try expect(target == 50 && RiderProgression.filename == "rider-progression.json", "Production uses its own fifty-flip save")
        let otherFilename = "rider-progression.debug.json"
        #endif
        try expect(progress.state.landedBackflips == 0 && !progress.kenjiAvailability.isUnlocked, "Fresh progression starts locked at zero")
        try expect(!progress.claimKenji(), "A rider cannot be claimed before the threshold")
        let firstRun = UUID()
        progress.recordLanding(backflips: 0, runID: firstRun, tick: 10)
        progress.recordLanding(backflips: -1, runID: firstRun, tick: 11)
        try expect(progress.state.landedBackflips == 0, "Frontflip-only and invalid counts do not advance")
        progress.recordLanding(backflips: 1, runID: firstRun, tick: 20)
        progress.recordLanding(backflips: 1, runID: firstRun, tick: 20)
        progress.recordLanding(backflips: 1, runID: firstRun, tick: 19)
        try expect(progress.state.landedBackflips == 1, "A duplicate or stale landing is ignored")
        let afterQuit = RiderProgression(store: store)
        try expect(afterQuit.state.landedBackflips == 1, "A reception is saved immediately, before run completion")
        afterQuit.recordLanding(backflips: 1, runID: firstRun, tick: 20)
        try expect(afterQuit.state.landedBackflips == 1, "Saved event identity prevents duplicate credit after reinitialization")
        afterQuit.recordLanding(backflips: 2, runID: UUID(), tick: 1)
        try expect(afterQuit.state.landedBackflips == 3, "A double backflip and a new run both count")
        if target > 3 { afterQuit.recordLanding(backflips: target - 3, runID: UUID(), tick: 1) }
        try expect(afterQuit.kenjiAvailability.isReadyToUnlock && !afterQuit.kenjiAvailability.isUnlocked, "The threshold enables a claim, not automatic selection")
        try expect(afterQuit.kenjiAvailability.progress?.text == "\(target) / \(target)", "Progress display is capped at the requirement")
        try expect(afterQuit.claimKenji(), "Ready claim succeeds")
        try expect(!afterQuit.claimKenji(), "A claim is consumed exactly once")
        try expect(RiderProgression(store: store).kenjiAvailability.isUnlocked, "The claim survives interrupted animation/relaunch")
        try expect(RiderProgression(store: store, filename: otherFilename).state == .init(), "Debug and production never share unlock state")

        // Retry a transient save error without losing the in-memory reception or falsely claiming.
        let blockedRoot = root.appendingPathComponent("blocked")
        try Data("file blocks directory".utf8).write(to: blockedRoot)
        let retry = RiderProgression(store: LocalStore(rootURL: blockedRoot))
        retry.recordLanding(backflips: target, runID: UUID(), tick: 1)
        try expect(retry.saveError != nil && !retry.claimKenji() && !retry.state.kenjiClaimed, "Failed persistence never grants a claim")
        try FileManager.default.removeItem(at: blockedRoot)
        retry.flush()
        try expect(retry.saveError == nil && retry.claimKenji(), "Pending receptions and claim recover after a storage failure")

        let corruptName = "corrupt.json"
        let corrupt = Data("not json".utf8)
        try corrupt.write(to: root.appendingPathComponent(corruptName))
        let unreadable = RiderProgression(store: store, filename: corruptName)
        unreadable.recordLanding(backflips: target, runID: UUID(), tick: 1)
        unreadable.flush()
        try expect(!unreadable.claimKenji() && unreadable.saveError != nil, "Unreadable state cannot be replaced by a claim")
        try expect(try Data(contentsOf: root.appendingPathComponent(corruptName)) == corrupt, "Unreadable progression is preserved")
        print("PASS: \(target)-backflip threshold, landing idempotence, double flips, cumulative immediate saves, explicit durable claim, Debug/Release isolation, save retry and corruption preservation.")
    }
}
