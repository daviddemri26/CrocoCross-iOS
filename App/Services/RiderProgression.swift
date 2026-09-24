import Foundation
import Observation

/// Local achievements are independent of leaderboards, engine versions and run outcomes.
@MainActor @Observable
final class RiderProgression {
    struct Landing: Codable, Equatable {
        let runID: UUID
        let tick: Int
    }
    struct State: Codable, Equatable {
        var landedBackflips = 0
        var kenjiClaimed = false
        var lastLanding: Landing?
    }

    #if DEBUG
    static let kenjiRequirement = 2
    static let filename = "rider-progression.debug.json"
    #else
    static let kenjiRequirement = 50
    static let filename = "rider-progression.json"
    #endif

    private(set) var state = State()
    private(set) var saveError: String?
    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let filename: String
    @ObservationIgnored private var unreadableSave = false
    @ObservationIgnored private var hasPendingSave = false
    private static let maximumCount = 1_000_000_000

    init(store: LocalStore = LocalStore(), filename: String = RiderProgression.filename) {
        self.store = store
        self.filename = filename
        do {
            if let loaded = try store.load(State.self, from: filename) {
                guard loaded.landedBackflips >= 0, loaded.landedBackflips <= Self.maximumCount,
                      loaded.lastLanding.map({ $0.tick >= 0 }) ?? true else {
                    throw LocalStore.StoreError.corruptedFile(filename)
                }
                state = loaded
            }
        } catch {
            // Preserve damaged/newer data for recovery. Never overwrite it with an empty save.
            unreadableSave = true
            saveError = "Your rider progress could not be read. Restart the game to try again."
        }
    }

    var kenjiAvailability: CatalogAvailability {
        if state.kenjiClaimed { return .available }
        let progress = CatalogProgress(current: state.landedBackflips, target: Self.kenjiRequirement)
        let requirement = "Land \(Self.kenjiRequirement) backflips to unlock Kenji"
        return state.landedBackflips >= Self.kenjiRequirement
            ? .readyToUnlock(requirement: requirement, progress: progress)
            : .locked(requirement: requirement, progress: progress)
    }

    /// Called only for a core .flip event, which follows a validated safe reception.
    /// Persist the event identity with the count so repeated pause/restart callbacks cannot credit it twice.
    func recordLanding(backflips: Int, runID: UUID, tick: Int) {
        guard !unreadableSave, backflips > 0, tick >= 0 else { return }
        if let last = state.lastLanding, last.runID == runID, tick <= last.tick { return }
        state.landedBackflips += min(backflips, Self.maximumCount - state.landedBackflips)
        state.lastLanding = Landing(runID: runID, tick: tick)
        hasPendingSave = true
        flush()
    }

    /// A claim is durable before its animation starts. A failed write leaves the claim retryable.
    @discardableResult func claimKenji() -> Bool {
        guard !unreadableSave, kenjiAvailability.isReadyToUnlock else { return false }
        var claimed = state
        claimed.kenjiClaimed = true
        do {
            try store.save(claimed, to: filename)
            state = claimed
            hasPendingSave = false
            saveError = nil
            return true
        } catch {
            saveError = "Your rider progress could not be saved. Please try again."
            return false
        }
    }

    /// Keep unsaved receptions in memory and retry when leaving a ride or backgrounding.
    func flush() {
        guard !unreadableSave, hasPendingSave else { return }
        do {
            try store.save(state, to: filename)
            hasPendingSave = false
            saveError = nil
        } catch {
            saveError = "Your rider progress could not be saved. Please try again."
        }
    }

    static func forCurrentLaunch() -> RiderProgression {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ui-testing") {
            func argument(_ name: String) -> String? {
                guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
                return arguments[index + 1]
            }
            // Every test launch has an isolated namespace; an explicit UUID permits a persistence relaunch.
            let id = argument("-unlock-test-id").flatMap(UUID.init(uuidString:)) ?? UUID()
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("RiderProgressionUITests", isDirectory: true)
                .appendingPathComponent(id.uuidString, isDirectory: true)
            let store = LocalStore(rootURL: root)
            let hasSave = FileManager.default.fileExists(atPath: root.appendingPathComponent(filename).path)
            let progression = RiderProgression(store: store)
            if !hasSave, let count = argument("-unlock-fixture-backflips").flatMap(Int.init),
               (0...kenjiRequirement).contains(count) {
                progression.recordLanding(backflips: count, runID: UUID(), tick: 0)
            }
            return progression
        }
        #endif
        return RiderProgression()
    }
}
