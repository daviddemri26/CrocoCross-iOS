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
        var miloClaimed = false
        var lastLanding: Landing?
        // Each new contributing run accounts for at least one backflip, up to the 2/100 goal.
        var creditedRunTicks: [String: Int] = [:]

        enum CodingKeys: String, CodingKey {
            case landedBackflips, kenjiClaimed, miloClaimed, lastLanding, creditedRunTicks
        }
    }

    #if DEBUG
    static let kenjiRequirement = 2
    static let miloRequirement = 2
    static let filename = "rider-progression.debug.json"
    #else
    static let kenjiRequirement = 50
    static let miloRequirement = 100
    static let filename = "rider-progression.json"
    #endif

    private(set) var state = State()
    private(set) var saveError: String?
    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let filename: String
    @ObservationIgnored private var unreadableSave = false
    @ObservationIgnored private var hasPendingSave = false
    private static let maximumCount = 1_000_000_000
    private static let backflipGoal = max(kenjiRequirement, miloRequirement)

    init(store: LocalStore = LocalStore(), filename: String = RiderProgression.filename) {
        self.store = store
        self.filename = filename
        do {
            if let loaded = try store.load(State.self, from: filename) {
                guard loaded.landedBackflips >= 0, loaded.landedBackflips <= Self.maximumCount,
                      loaded.lastLanding.map({ $0.tick >= 0 && (loaded.creditedRunTicks[$0.runID.uuidString] ?? -1) >= $0.tick }) ?? true,
                      loaded.creditedRunTicks.allSatisfy({ UUID(uuidString: $0.key) != nil && $0.value >= 0 }) else {
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

    var miloAvailability: CatalogAvailability {
        if state.miloClaimed { return .available }
        let progress = CatalogProgress(current: state.landedBackflips, target: Self.miloRequirement)
        let requirement = "Land \(Self.miloRequirement) backflips to unlock Milo"
        return state.landedBackflips >= Self.miloRequirement
            ? .readyToUnlock(requirement: requirement, progress: progress)
            : .locked(requirement: requirement, progress: progress)
    }

    /// Called only for a core .flip event, which follows a validated safe reception.
    /// Persist the event identity with the count so repeated pause/restart callbacks cannot credit it twice.
    func recordLanding(backflips: Int, runID: UUID, tick: Int) {
        guard !unreadableSave, backflips > 0, tick >= 0, state.landedBackflips < Self.backflipGoal else { return }
        let key = runID.uuidString
        if let previousTick = state.creditedRunTicks[key], tick <= previousTick { return }
        state.landedBackflips += min(backflips, Self.backflipGoal - state.landedBackflips)
        state.lastLanding = Landing(runID: runID, tick: tick)
        state.creditedRunTicks[key] = tick
        hasPendingSave = true
        flush()
    }

    /// A claim is durable before its animation starts. A failed write leaves the claim retryable.
    @discardableResult func claimKenji() -> Bool {
        guard !unreadableSave, kenjiAvailability.isReadyToUnlock else { return false }
        var claimed = state
        claimed.kenjiClaimed = true
        return saveClaim(claimed)
    }

    @discardableResult func claimMilo() -> Bool {
        guard !unreadableSave, miloAvailability.isReadyToUnlock else { return false }
        var claimed = state
        claimed.miloClaimed = true
        return saveClaim(claimed)
    }

    private func saveClaim(_ claimed: State) -> Bool {
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
            if !hasSave {
                let shouldClaimMilo = arguments.contains("-milo-unlock-fixture-claimed")
                let count = argument("-unlock-fixture-backflips").flatMap(Int.init) ?? (shouldClaimMilo ? miloRequirement : 0)
                if (0...backflipGoal).contains(count) {
                    progression.recordLanding(backflips: count, runID: UUID(), tick: 0)
                    if shouldClaimMilo { progression.claimMilo() }
                }
            }
            return progression
        }
        #endif
        return RiderProgression()
    }
}

extension RiderProgression.State {
    /// Read original Kenji saves without resetting either their count or their durable claim.
    /// Only fields introduced with Milo default; malformed existing fields stay a recoverable error.
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        landedBackflips = try values.decode(Int.self, forKey: .landedBackflips)
        kenjiClaimed = try values.decode(Bool.self, forKey: .kenjiClaimed)
        miloClaimed = values.contains(.miloClaimed) ? try values.decode(Bool.self, forKey: .miloClaimed) : false
        lastLanding = try values.decodeIfPresent(RiderProgression.Landing.self, forKey: .lastLanding)
        if values.contains(.creditedRunTicks) {
            creditedRunTicks = try values.decode([String: Int].self, forKey: .creditedRunTicks)
        } else if let lastLanding {
            creditedRunTicks = [lastLanding.runID.uuidString: lastLanding.tick]
        } else { creditedRunTicks = [:] }
    }
}
