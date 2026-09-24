import Foundation
import Observation

/// World achievements count safe receptions independently of mode, score and run outcome.
@MainActor @Observable
final class WorldProgression {
    struct Landing: Codable, Equatable {
        let runID: UUID
        let tick: Int
    }

    struct State: Codable, Equatable {
        var landedFrontflips = 0
        var japanClaimed = false
        var lastLanding: Landing?
        // Retain each contributing run until the threshold; this is bounded to 2/50 entries.
        // An old callback cannot be credited after a new run.
        var creditedRunTicks: [String: Int] = [:]
    }

    #if DEBUG
    static let japanRequirement = 2
    static let filename = "world-progression.debug.json"
    #else
    static let japanRequirement = 50
    static let filename = "world-progression.json"
    #endif

    private(set) var state = State()
    private(set) var saveError: String?
    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let filename: String
    @ObservationIgnored private var unreadableSave = false
    @ObservationIgnored private var hasPendingSave = false
    private static let maximumCount = 1_000_000_000

    init(store: LocalStore = LocalStore(), filename: String = WorldProgression.filename) {
        self.store = store
        self.filename = filename
        do {
            if let loaded = try store.load(State.self, from: filename) {
                guard loaded.landedFrontflips >= 0, loaded.landedFrontflips <= Self.maximumCount,
                      loaded.lastLanding.map({ $0.tick >= 0 }) ?? true,
                      loaded.creditedRunTicks.allSatisfy({ UUID(uuidString: $0.key) != nil && $0.value >= 0 }) else {
                    throw LocalStore.StoreError.corruptedFile(filename)
                }
                state = loaded
            }
        } catch {
            // Preserve damaged/newer data for recovery; never replace it with an empty save.
            unreadableSave = true
            saveError = "Your world progress could not be read. Restart the game to try again."
        }
    }

    var japanAvailability: CatalogAvailability {
        if state.japanClaimed { return .available }
        let progress = CatalogProgress(current: state.landedFrontflips, target: Self.japanRequirement)
        let requirement = "Land \(Self.japanRequirement) frontflips to unlock Japan Mountains"
        return state.landedFrontflips >= Self.japanRequirement
            ? .readyToUnlock(requirement: requirement, progress: progress)
            : .locked(requirement: requirement, progress: progress)
    }

    /// Called only for a core .flip event after a validated safe reception.
    /// Backflips and unfinished rotations are excluded by the caller's frontflip count.
    func recordLanding(frontflips: Int, runID: UUID, tick: Int) {
        guard !unreadableSave, frontflips > 0, tick >= 0,
              state.landedFrontflips < Self.japanRequirement else { return }
        let key = runID.uuidString
        if let previousTick = state.creditedRunTicks[key], tick <= previousTick { return }
        state.landedFrontflips += min(frontflips, Self.japanRequirement - state.landedFrontflips)
        state.lastLanding = Landing(runID: runID, tick: tick)
        state.creditedRunTicks[key] = tick
        hasPendingSave = true
        flush()
    }

    /// Persist the claim before presenting its animation. A failed write leaves it retryable.
    @discardableResult func claimJapan() -> Bool {
        guard !unreadableSave, japanAvailability.isReadyToUnlock else { return false }
        var claimed = state
        claimed.japanClaimed = true
        do {
            try store.save(claimed, to: filename)
            state = claimed
            hasPendingSave = false
            saveError = nil
            return true
        } catch {
            saveError = "Your world progress could not be saved. Please try again."
            return false
        }
    }

    /// Retry any unsaved reception when leaving a ride or moving into the background.
    func flush() {
        guard !unreadableSave, hasPendingSave else { return }
        do {
            try store.save(state, to: filename)
            hasPendingSave = false
            saveError = nil
        } catch {
            saveError = "Your world progress could not be saved. Please try again."
        }
    }

    static func forCurrentLaunch() -> WorldProgression {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ui-testing") {
            func argument(_ name: String) -> String? {
                guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
                return arguments[index + 1]
            }
            // Every UI test launch is isolated; an explicit UUID permits persistence relaunches.
            let id = argument("-world-unlock-test-id").flatMap(UUID.init(uuidString:)) ?? UUID()
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("WorldProgressionUITests", isDirectory: true)
                .appendingPathComponent(id.uuidString, isDirectory: true)
            let store = LocalStore(rootURL: root)
            let hasSave = FileManager.default.fileExists(atPath: root.appendingPathComponent(filename).path)
            let progression = WorldProgression(store: store)
            if !hasSave {
                let shouldClaim = arguments.contains("-world-unlock-fixture-claimed")
                let count = argument("-world-unlock-fixture-frontflips").flatMap(Int.init)
                    ?? (shouldClaim ? japanRequirement : 0)
                if (0...japanRequirement).contains(count) {
                    progression.recordLanding(frontflips: count, runID: UUID(), tick: 0)
                    if shouldClaim { progression.claimJapan() }
                }
            }
            return progression
        }
        #endif
        return WorldProgression()
    }
}
