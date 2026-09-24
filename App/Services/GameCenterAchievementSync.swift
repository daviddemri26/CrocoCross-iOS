import Foundation

/// Kept separate from GameKit so account changes, failures and relaunches can be
/// exercised without signing in or writing to Apple's service.
struct GameCenterAchievementSnapshot: Sendable {
    var progress: [String: Double]
    var completionDates: [String: Date] = [:]
}

@MainActor
protocol GameCenterAchievementGateway: AnyObject {
    var authenticatedPlayerID: String? { get }
    func loadProgress(for playerID: String) async throws -> GameCenterAchievementSnapshot
    func reportProgress(_ progress: [String: Double], for playerID: String) async throws
}

enum GameCenterAchievementPolicy {
    static func allowsReporting(configurationEnabled: Bool, onlineEnabled: Bool,
                                arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        configurationEnabled && onlineEnabled && !arguments.contains("-ui-testing")
    }
}

/// Durable monotone outbox. Progress is already attributed by the progression
/// ledger; this layer never adopts guest progress or copies it between accounts.
@MainActor
final class GameCenterAchievementSync {
    enum Result: Equatable { case disabled, idle, synchronized, retry, accountChanged, busy }
    private struct Account: Codable {
        var desired: [String: Double] = [:]
        var confirmed: [String: Double] = [:]
    }
    private struct State: Codable { var accounts: [String: Account] = [:] }
    static let filename = "game-center-achievements-v1.json"

    private let store: LocalStore
    private let gateway: any GameCenterAchievementGateway
    private let allowedIDs: Set<String>
    let enabled: Bool
    private var state = State()
    private var canSave = true
    private var generation: UInt64 = 0
    private var playerID: String?
    private var isSynchronizing = false
    private(set) var storageError: String?
    private(set) var synchronizationError: String?
    var onRemoteProgress: ((String, [String: Double], [String: Date]) -> Void)?

    init(store: LocalStore, gateway: any GameCenterAchievementGateway,
         allowedIDs: Set<String>, enabled: Bool) {
        self.store = store
        self.gateway = gateway
        self.allowedIDs = allowedIDs
        self.enabled = enabled
        guard enabled else { return }
        do {
            let restored = try store.load(State.self, from: Self.filename) ?? State()
            guard restored.accounts.allSatisfy({ owner, account in
                !owner.isEmpty && [account.desired, account.confirmed].allSatisfy { values in
                    values.allSatisfy { !$0.key.isEmpty && $0.value.isFinite && (0...100).contains($0.value) }
                }
            }) else { throw LocalStore.StoreError.corruptedFile(Self.filename) }
            state = restored
        } catch {
            // Preserve unreadable/newer data, as with the score outbox. The
            // independently saved progression ledger can replay current values.
            canSave = false
            storageError = "Saved achievement submissions could not be restored. Progress remains on this device."
        }
    }

    func setAuthenticatedPlayer(_ identifier: String?) {
        let normalized = identifier.flatMap { $0.isEmpty ? nil : $0 }
        guard normalized != playerID else { return }
        playerID = normalized
        generation &+= 1
        synchronizationError = nil
    }

    func enqueue(_ progress: [String: Double], for owner: String) {
        guard enabled, !owner.isEmpty else { return }
        var account = state.accounts[owner] ?? Account()
        var changed = false
        for (identifier, percent) in normalized(progress) where percent > (account.desired[identifier] ?? 0) {
            account.desired[identifier] = percent
            changed = true
        }
        guard changed else {
            if storageError != nil { persist() }
            return
        }
        state.accounts[owner] = account
        persist()
    }

    func pendingProgress(for owner: String) -> [String: Double] {
        guard let account = state.accounts[owner] else { return [:] }
        return account.desired.filter { allowedIDs.contains($0.key) && $0.value > (account.confirmed[$0.key] ?? 0) }
    }

    func confirmedProgress(for owner: String) -> [String: Double] {
        normalized(state.accounts[owner]?.confirmed ?? [:])
    }

    func synchronize() async -> Result {
        guard enabled else { return .disabled }
        guard let owner = playerID, gateway.authenticatedPlayerID == owner else { return .idle }
        guard !isSynchronizing else { return .busy }
        isSynchronizing = true
        defer { isSynchronizing = false }
        let session = generation
        func isCurrent() -> Bool {
            playerID == owner && generation == session && gateway.authenticatedPlayerID == owner
        }
        do {
            // Always reconcile before a report, including retry after an ambiguous
            // error: the previous request may already have reached Game Center.
            let loaded = try await gateway.loadProgress(for: owner)
            guard isCurrent() else { return .accountChanged }
            let remote = normalized(loaded.progress)
            confirm(remote, for: owner)
            let dates = loaded.completionDates.filter {
                remote[$0.key] == 100 && $0.value.timeIntervalSinceReferenceDate.isFinite
            }
            onRemoteProgress?(owner, confirmedProgress(for: owner), dates)
            guard isCurrent() else { return .accountChanged }
            while true {
                let batch = pendingProgress(for: owner)
                guard !batch.isEmpty else { break }
                guard isCurrent() else { return .accountChanged }
                try await gateway.reportProgress(batch, for: owner)
                guard isCurrent() else { return .accountChanged }
                // A newer enqueue during the await stays pending: acknowledge
                // only the immutable values actually sent in this batch.
                confirm(batch, for: owner)
            }
            synchronizationError = nil
            return .synchronized
        } catch {
            guard isCurrent() else { return .accountChanged }
            synchronizationError = "Achievements are saved locally and will sync when Game Center is available."
            return .retry
        }
    }

    private func normalized(_ progress: [String: Double]) -> [String: Double] {
        progress.reduce(into: [:]) { result, item in
            guard allowedIDs.contains(item.key), item.value.isFinite, item.value > 0 else { return }
            // Whole percentages avoid redundant reports for sub-percent changes.
            let percent = min(100, item.value).rounded(.down)
            if percent > 0 { result[item.key] = percent }
        }
    }

    private func confirm(_ progress: [String: Double], for owner: String) {
        var account = state.accounts[owner] ?? Account()
        var changed = false
        for (identifier, percent) in progress where percent > (account.confirmed[identifier] ?? 0) {
            account.confirmed[identifier] = percent
            changed = true
        }
        guard changed else {
            if storageError != nil { persist() }
            return
        }
        state.accounts[owner] = account
        persist()
    }

    private func persist() {
        guard canSave else { return }
        do {
            try store.save(state, to: Self.filename)
            storageError = nil
        } catch {
            storageError = "Achievement submissions could not be saved. Keep the app open to retry."
        }
    }
}
