import Foundation

@MainActor private final class FakeAchievementGateway: GameCenterAchievementGateway {
    enum Failure: Error { case offline, rejected }
    var authenticatedPlayerID: String?
    var remote: [String: [String: Double]] = [:]
    var dates: [String: Date] = [:]
    var loadFails = false
    var reportFails = false
    var acceptsBeforeError = false
    var loads: [String] = []
    var reports: [(String, [String: Double])] = []
    var onLoad: (() -> Void)?
    var onReport: (() -> Void)?
    func loadProgress(for playerID: String) async throws -> GameCenterAchievementSnapshot {
        loads.append(playerID)
        let snapshot = GameCenterAchievementSnapshot(progress: remote[playerID] ?? [:], completionDates: dates)
        onLoad?()
        if loadFails { throw Failure.offline }
        return snapshot
    }
    func reportProgress(_ progress: [String: Double], for playerID: String) async throws {
        reports.append((playerID, progress))
        onReport?()
        if !reportFails || acceptsBeforeError {
            for (id, value) in progress { remote[playerID, default: [:]][id] = max(remote[playerID]?[id] ?? 0, value) }
        }
        if reportFails { throw Failure.rejected }
    }
}

@main struct GameCenterAchievementChecks {
    @MainActor static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("CrocoCross-AchievementSync-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let first = "com.daviddemri.crococross.achievement.stunt.backflip.first"
        let total = "com.daviddemri.crococross.achievement.stunt.total.100"
        let allowed: Set<String> = [first, total]
        var checks = 0
        func expect(_ condition: @autoclosure () -> Bool, _ description: String) {
            checks += 1
            precondition(condition(), description)
        }
        func make(_ name: String, gateway: FakeAchievementGateway, enabled: Bool = true) -> GameCenterAchievementSync {
            GameCenterAchievementSync(store: LocalStore(rootURL: root.appendingPathComponent(name)),
                gateway: gateway, allowedIDs: allowed, enabled: enabled)
        }
        let disabledGateway = FakeAchievementGateway()
        disabledGateway.authenticatedPlayerID = "A"
        let disabled = make("disabled", gateway: disabledGateway, enabled: false)
        disabled.setAuthenticatedPlayer("A")
        disabled.enqueue([first: 100], for: "A")
        let disabledResult = await disabled.synchronize()
        expect(disabledResult == .disabled && disabledGateway.loads.isEmpty && disabledGateway.reports.isEmpty,
               "Disabled reporting never calls a gateway")
        expect(!FileManager.default.fileExists(atPath: root.appendingPathComponent("disabled").path),
               "Disabled synchronization never creates an outbox")
        expect(!GameCenterAchievementPolicy.allowsReporting(configurationEnabled: false, onlineEnabled: true),
               "Unconfigured Game Center achievements remain disabled")
        expect(!GameCenterAchievementPolicy.allowsReporting(configurationEnabled: true, onlineEnabled: false),
               "Offline-disabled service cannot report")
        expect(!GameCenterAchievementPolicy.allowsReporting(configurationEnabled: true, onlineEnabled: true, arguments: ["-ui-testing"]),
               "UI fixtures can never report")
        expect(GameCenterAchievementPolicy.allowsReporting(configurationEnabled: true, onlineEnabled: true, arguments: []),
               "Configured normal builds use the same sync policy with or without DEBUG")

        let gateway = FakeAchievementGateway()
        let initial = make("durable", gateway: gateway)
        initial.enqueue([total: 12.8, first: 120, "unknown": 100, "nan": .nan], for: "A")
        initial.enqueue([total: 2], for: "A")
        initial.enqueue([total: 44], for: "B")
        expect(initial.pendingProgress(for: "A") == [total: 12, first: 100], "Offline progress is bounded, allowlisted and monotone")
        let restored = make("durable", gateway: gateway)
        expect(restored.pendingProgress(for: "A") == initial.pendingProgress(for: "A"), "Offline progress survives relaunch")
        gateway.authenticatedPlayerID = "A"
        restored.setAuthenticatedPlayer("A")
        gateway.loadFails = true
        let loadFailure = await restored.synchronize()
        expect(loadFailure == .retry && gateway.reports.isEmpty && restored.pendingProgress(for: "A")[first] == 100,
               "A failed load never reports or clears progress")
        gateway.loadFails = false
        gateway.reportFails = true
        let reportFailure = await restored.synchronize()
        expect(reportFailure == .retry && restored.pendingProgress(for: "A")[total] == 12,
               "A rejected report stays pending")
        gateway.reportFails = false
        let successfulRetry = await restored.synchronize()
        expect(successfulRetry == .synchronized && restored.pendingProgress(for: "A").isEmpty,
               "A successful retry acknowledges only its owner")
        expect(restored.pendingProgress(for: "B")[total] == 44 && gateway.reports.allSatisfy { $0.0 == "A" },
               "A's sign-in cannot transmit B's queue")
        let confirmed = make("durable", gateway: gateway)
        expect(confirmed.confirmedProgress(for: "A")[first] == 100 && confirmed.pendingProgress(for: "A").isEmpty,
               "Confirmed progress survives relaunch without duplicate submission")

        let ambiguousGateway = FakeAchievementGateway()
        ambiguousGateway.authenticatedPlayerID = "A"
        ambiguousGateway.reportFails = true
        ambiguousGateway.acceptsBeforeError = true
        let ambiguous = make("ambiguous", gateway: ambiguousGateway)
        ambiguous.setAuthenticatedPlayer("A")
        ambiguous.enqueue([first: 100], for: "A")
        _ = await ambiguous.synchronize()
        ambiguousGateway.reportFails = false
        var restoredOwner: String?, restoredProgress: [String: Double] = [:]
        ambiguous.onRemoteProgress = { owner, progress, _ in restoredOwner = owner; restoredProgress = progress }
        _ = await ambiguous.synchronize()
        expect(ambiguousGateway.reports.count == 1 && ambiguous.pendingProgress(for: "A").isEmpty,
               "Load-before-retry recognizes a report accepted before a network error")
        expect(restoredOwner == "A" && restoredProgress[first] == 100, "Remote completion is restored to its account only")

        let concurrentGateway = FakeAchievementGateway()
        concurrentGateway.authenticatedPlayerID = "A"
        let concurrent = make("concurrent", gateway: concurrentGateway)
        concurrent.setAuthenticatedPlayer("A")
        concurrent.enqueue([total: 40], for: "A")
        concurrentGateway.onReport = { [weak concurrentGateway] in
            concurrentGateway?.onReport = nil
            concurrent.enqueue([total: 80], for: "A")
        }
        _ = await concurrent.synchronize()
        expect(concurrentGateway.reports.map { $0.1[total]! } == [40, 80],
               "New progress during a report is not removed by the old acknowledgement")

        let switchGateway = FakeAchievementGateway()
        switchGateway.authenticatedPlayerID = "A"
        switchGateway.remote["A"] = [first: 100]
        let switching = make("switch", gateway: switchGateway)
        switching.setAuthenticatedPlayer("A")
        switching.enqueue([total: 50], for: "A")
        switching.enqueue([total: 10], for: "B")
        var callbacks = 0
        switching.onRemoteProgress = { _, _, _ in callbacks += 1 }
        switchGateway.onLoad = {
            switchGateway.onLoad = nil
            switchGateway.authenticatedPlayerID = "B"
            switching.setAuthenticatedPlayer("B")
        }
        let changed = await switching.synchronize()
        expect(changed == .accountChanged && callbacks == 0 && switchGateway.reports.isEmpty,
               "An account change while loading ignores the stale response")
        _ = await switching.synchronize()
        expect(switchGateway.reports.count == 1 && switchGateway.reports[0].0 == "B" &&
               switchGateway.reports[0].1 == [total: 10] && switching.pendingProgress(for: "A")[total] == 50,
               "The new account reports only its own progress")

        let epochGateway = FakeAchievementGateway()
        epochGateway.authenticatedPlayerID = "A"
        let epoch = make("epoch", gateway: epochGateway)
        epoch.setAuthenticatedPlayer("A")
        epoch.enqueue([first: 100], for: "A")
        epochGateway.onLoad = { epoch.setAuthenticatedPlayer(nil); epoch.setAuthenticatedPlayer("A") }
        let staleSameOwner = await epoch.synchronize()
        expect(staleSameOwner == .accountChanged && epochGateway.reports.isEmpty,
               "Sign-out and back into A still invalidates A's earlier request")

        let switchReportGateway = FakeAchievementGateway()
        switchReportGateway.authenticatedPlayerID = "A"
        let switchReport = make("switch-report", gateway: switchReportGateway)
        switchReport.setAuthenticatedPlayer("A")
        switchReport.enqueue([first: 100], for: "A")
        switchReportGateway.onReport = {
            switchReportGateway.onReport = nil
            switchReportGateway.authenticatedPlayerID = "B"
            switchReport.setAuthenticatedPlayer("B")
        }
        let staleReport = await switchReport.synchronize()
        expect(staleReport == .accountChanged && switchReport.pendingProgress(for: "A")[first] == 100 &&
               switchReport.confirmedProgress(for: "B").isEmpty, "Late A acknowledgements cannot change B's state")
        switchReportGateway.authenticatedPlayerID = "A"
        switchReport.setAuthenticatedPlayer("A")
        _ = await switchReport.synchronize()
        expect(switchReportGateway.reports.count == 1 && switchReport.pendingProgress(for: "A").isEmpty,
               "A reconciles the old successful report when it returns")

        let datesGateway = FakeAchievementGateway()
        datesGateway.authenticatedPlayerID = "A"
        datesGateway.remote["A"] = [first: 100, total: 40, "other-game": 100]
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        datesGateway.dates = [first: date, total: date, "other-game": date]
        let datesSync = make("dates", gateway: datesGateway)
        datesSync.setAuthenticatedPlayer("A")
        var observedDates: [String: Date] = [:]
        datesSync.onRemoteProgress = { _, _, dates in observedDates = dates }
        _ = await datesSync.synchronize()
        expect(observedDates == [first: date], "Only complete allowlisted achievements restore a reported completion date")
        expect(datesSync.confirmedProgress(for: "A") == [first: 100, total: 40], "Remote-only progress restores without reports or invented counters")

        for version in [1, 2] {
            let folder = root.appendingPathComponent("unreadable-\(version)")
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent(GameCenterAchievementSync.filename)
            let original = Data("{\"version\":\(version),\"value\":\"invalid\"}".utf8)
            try original.write(to: url)
            let bad = GameCenterAchievementSync(store: LocalStore(rootURL: folder), gateway: gateway,
                                               allowedIDs: allowed, enabled: true)
            bad.enqueue([first: 100], for: "A")
            let preserved = try Data(contentsOf: url)
            expect(preserved == original && bad.storageError != nil,
                   "Malformed or newer saved queues are never silently overwritten")
            expect(bad.pendingProgress(for: "A")[first] == 100, "New progress remains pending in memory after a read failure")
        }
        let blockedFolder = root.appendingPathComponent("blocked")
        try Data("file blocks directory".utf8).write(to: blockedFolder)
        let blocked = GameCenterAchievementSync(store: LocalStore(rootURL: blockedFolder), gateway: gateway,
                                               allowedIDs: allowed, enabled: true)
        blocked.enqueue([total: 60], for: "A")
        expect(blocked.storageError != nil && blocked.pendingProgress(for: "A")[total] == 60,
               "A failed save retains progress and exposes its storage error")
        try FileManager.default.removeItem(at: blockedFolder)
        blocked.enqueue([total: 60], for: "A")
        let afterRecovery = GameCenterAchievementSync(store: LocalStore(rootURL: blockedFolder), gateway: gateway,
                                                     allowedIDs: allowed, enabled: true)
        expect(blocked.storageError == nil && afterRecovery.pendingProgress(for: "A")[total] == 60,
               "An unchanged snapshot retries a previously failed save")
        print("PASS: \(checks) achievement sync checks: durable offline progress, monotone reports, account isolation, late callbacks, reconciliation, shared build policy, UI-test isolation and storage recovery; fake gateway only.")
    }
}
