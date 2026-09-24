import Foundation
import Observation

/// Offline-first, device-local achievement journal. Every run keeps one compact deduplication record.
/// The guest ledger can be assigned once; a different Game Center account never inherits it.
@MainActor @Observable
public final class AchievementProgression {
    public static let filename = "achievements.json"

    public let catalog: [AchievementDefinition]
    public var state: AchievementState { journal.local }
    public private(set) var saveError: String?
    public var guestAssignedTo: String? { journal.guestAssignedTo }
    @ObservationIgnored private let fileURL: URL
    @ObservationIgnored private let remoteReportingEnabled: Bool
    @ObservationIgnored private var unreadableSave = false
    @ObservationIgnored private var pendingSave = false
    private var journal = Journal()

    private enum Owner: Codable, Equatable { case guest, player(String) }
    private struct Run: Codable, Equatable {
        var owner: Owner
        var lastLandingTick: Int?
        var bestDistance: Double = 0
        var weeklyFinished = false
    }
    private struct Journal: Codable, Equatable {
        var local = AchievementState()
        var guest = AchievementState()
        var players: [String: AchievementState] = [:]
        var guestAssignedTo: String?
        var runs: [String: Run] = [:]
        var claims: [String: Owner] = [:]
    }
    private struct Envelope: Codable { let version: Int; let value: Journal }
    private struct Header: Decodable { let version: Int }
    private enum SaveFailure: Error { case invalidData }

    public init(rootURL: URL, filename: String = AchievementProgression.filename,
                catalog: [AchievementDefinition] = AchievementCatalog.standard,
                remoteReportingEnabled: Bool = true) {
        precondition(!filename.isEmpty && filename != "." && filename != ".." && !filename.contains("/") && !filename.contains("\\") && !filename.contains("\0"))
        precondition(Set(catalog.map(\.id)).count == catalog.count && catalog.allSatisfy { $0.target.isFinite && $0.target > 0 })
        self.catalog = catalog
        self.fileURL = rootURL.appendingPathComponent(filename)
        self.remoteReportingEnabled = remoteReportingEnabled
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            guard try decoder.decode(Header.self, from: data).version == 1 else { throw SaveFailure.invalidData }
            var loaded = try decoder.decode(Envelope.self, from: data).value
            guard Self.isValid(loaded) else { throw SaveFailure.invalidData }
            let original = loaded
            loaded.local.restoreRotationMilestones(catalog)
            loaded.guest.restoreRotationMilestones(catalog)
            for id in Array(loaded.players.keys) { loaded.players[id]?.restoreRotationMilestones(catalog) }
            journal = loaded
            if loaded != original { pendingSave = true; flush() }
        } catch {
            unreadableSave = true
            saveError = "Your achievements could not be read. Restart the game to try again."
        }
    }

    /// Call only for a validated core .flip event. Crashes, pending rotations and home previews never call this.
    @discardableResult public func recordSafeLanding(backflips: Int, frontflips: Int, runID: UUID, tick: Int,
                                                     playerID: String? = nil, at date: Date = Date()) -> [AchievementDefinition] {
        guard !unreadableSave, date.timeIntervalSince1970.isFinite, tick >= 0,
              (0...10_000).contains(backflips), (0...10_000).contains(frontflips),
              backflips + frontflips > 0 else { return [] }
        let key = runID.uuidString
        if let previous = journal.runs[key]?.lastLandingTick, tick <= previous { return [] }
        let before = journal.local
        let owner = ownerForRun(runID, playerID: playerID)
        journal.runs[key]?.lastLandingTick = tick
        update(owner: owner, at: date, rotations: backflips + frontflips) { definition in
            switch definition.requirement {
            case .firstBackflip: return backflips > 0 ? (1, false) : nil
            case .firstFrontflip: return frontflips > 0 ? (1, false) : nil
            case .rotationsInJump(let minimum): return backflips + frontflips >= minimum ? (1, false) : nil
            case .totalRotations: return (Double(backflips + frontflips), true)
            default: return nil
            }
        }
        return finishChange(before: before)
    }

    /// Absolute distance within this Endless run, never a sum of distances from different runs.
    /// Updates stay exact in memory; disk writes are coalesced to integer percentage crossings.
    /// Lifecycle flushes also save partial percentages when a run pauses, ends or backgrounds.
    @discardableResult public func recordEndlessDistance(_ metres: Double, runID: UUID,
                                                         playerID: String? = nil, at date: Date = Date()) -> [AchievementDefinition] {
        guard !unreadableSave, date.timeIntervalSince1970.isFinite, metres.isFinite, metres > 0 else { return [] }
        let distance = min(catalog.filter { $0.requirement == .endlessMetres }.map(\.target).max() ?? 0, metres)
        let key = runID.uuidString
        guard distance > (journal.runs[key]?.bestDistance ?? 0) else { return [] }
        let before = journal.local
        let owner = ownerForRun(runID, playerID: playerID)
        let previousScoped = scopedState(for: owner)
        journal.runs[key]?.bestDistance = distance
        update(owner: owner, at: date) { $0.requirement == .endlessMetres ? (distance, false) : nil }
        let currentScoped = scopedState(for: owner)
        let crossedPercentage = catalog.contains { definition in
            definition.requirement == .endlessMetres
                && floor(currentScoped.progress(for: definition).percentComplete)
                    > floor(previousScoped.progress(for: definition).percentComplete)
        }
        return finishChange(before: before, persistImmediately: crossedPercentage)
    }

    @discardableResult public func recordWeeklyFinish(runID: UUID, playerID: String? = nil,
                                                      at date: Date = Date()) -> [AchievementDefinition] {
        guard !unreadableSave, date.timeIntervalSince1970.isFinite, journal.runs[runID.uuidString]?.weeklyFinished != true else { return [] }
        let before = journal.local
        let owner = ownerForRun(runID, playerID: playerID)
        journal.runs[runID.uuidString]?.weeklyFinished = true
        update(owner: owner, at: date) { $0.requirement == .weeklyFinishes ? (1, true) : nil }
        return finishChange(before: before)
    }

    @discardableResult public func recordUnlock(kind: AchievementUnlockKind, catalogID: String,
                                               playerID: String? = nil, at date: Date = Date()) -> [AchievementDefinition] {
        guard !unreadableSave, date.timeIntervalSince1970.isFinite,
              !(kind == .rider && catalogID == "croco"), !(kind == .world && catalogID == "canyon") else { return [] }
        let requirement: AchievementRequirement = kind == .rider ? .rider(catalogID) : .world(catalogID)
        guard catalog.contains(where: { $0.requirement == requirement }) else { return [] }
        let key = kind.rawValue + ":" + catalogID
        guard journal.claims[key] == nil else { return [] }
        let before = journal.local
        let owner = currentOwner(playerID: playerID)
        journal.claims[key] = owner
        update(owner: owner, at: date) { $0.requirement == requirement ? (1, false) : nil }
        return finishChange(before: before)
    }

    /// Only real, already-persisted unlock claims are imported. No historical riding statistics are inferred.
    public func importClaimedUnlocks(riderIDs: [String], worldIDs: [String], at date: Date = Date()) {
        for id in riderIDs { recordUnlock(kind: .rider, catalogID: id, at: date) }
        for id in worldIDs { recordUnlock(kind: .world, catalogID: id, at: date) }
    }

    /// Only a durably owned account ledger is eligible for external reporting.
    public func gameCenterProgress(for playerID: String) -> [String: Double] {
        guard remoteReportingEnabled, !unreadableSave, Self.validPlayerID(playerID) else { return [:] }
        identify(playerID)
        flush()
        guard !pendingSave else { return [:] }
        let scoped = journal.players[playerID] ?? AchievementState()
        return Dictionary(uniqueKeysWithValues: catalog.map { ($0.gameCenterID, scoped.progress(for: $0).percentComplete) })
    }

    /// Remote percentages restore certified bounds, without inventing old events or replaying local toasts.
    public func mergeRemoteProgress(_ progress: [String: Double], playerID: String,
                                    completionDates: [String: Date] = [:], at date: Date = Date()) {
        guard remoteReportingEnabled, !unreadableSave, Self.validPlayerID(playerID) else { return }
        identify(playerID)
        let previous = journal
        var scoped = journal.players[playerID] ?? AchievementState()
        for definition in catalog {
            guard let percent = progress[definition.gameCenterID], percent.isFinite, (0...100).contains(percent) else { continue }
            // One successful double/triple is indivisible. Partial remote values cannot represent a landed combo.
            if case .rotationsInJump = definition.requirement, percent < 100 { continue }
            let completion = completionDates[definition.gameCenterID].flatMap { $0.timeIntervalSince1970.isFinite ? $0 : nil }
            scoped.merge(definition, percent: percent, completedAt: completion)
            journal.local.merge(definition, percent: percent, completedAt: completion)
        }
        scoped.restoreRotationMilestones(catalog)
        journal.local.restoreRotationMilestones(catalog)
        journal.players[playerID] = scoped
        if journal != previous { pendingSave = true }
        flush()
    }

    public func flush() {
        guard pendingSave, !unreadableSave else { return }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
            let data = try encoder.encode(Envelope(version: 1, value: journal))
            var options: Data.WritingOptions = [.atomic]
            #if os(iOS)
            options.insert(.completeFileProtectionUntilFirstUserAuthentication)
            #endif
            try data.write(to: fileURL, options: options)
            pendingSave = false; saveError = nil
        } catch {
            saveError = "Your achievements could not be saved. Please try again."
        }
    }

    private func ownerForRun(_ runID: UUID, playerID: String?) -> Owner {
        if let existing = journal.runs[runID.uuidString] { return existing.owner }
        let owner = currentOwner(playerID: playerID)
        journal.runs[runID.uuidString] = Run(owner: owner)
        return owner
    }

    private func currentOwner(playerID: String?) -> Owner {
        if let playerID, Self.validPlayerID(playerID) {
            identify(playerID)
            return .player(playerID)
        }
        return .guest
    }

    private func identify(_ playerID: String) {
        guard journal.guestAssignedTo == nil else { return }
        journal.guestAssignedTo = playerID
        journal.players[playerID] = journal.guest
        journal.guest = AchievementState()
        pendingSave = true
    }

    private func update(owner: Owner, at date: Date, rotations: Int = 0,
                        contribution: (AchievementDefinition) -> (value: Double, cumulative: Bool)?) {
        let player: String?
        switch owner {
        case .guest: player = journal.guestAssignedTo
        case .player(let id): player = id
        }
        var scoped = player.flatMap { journal.players[$0] } ?? journal.guest
        if rotations > 0 {
            journal.local.addLandedRotations(rotations)
            scoped.addLandedRotations(rotations)
        }
        for definition in catalog {
            guard let value = contribution(definition) else { continue }
            journal.local.advance(definition, value: value.value, cumulative: value.cumulative, at: date)
            scoped.advance(definition, value: value.value, cumulative: value.cumulative, at: date)
        }
        if let player { journal.players[player] = scoped } else { journal.guest = scoped }
    }

    private func scopedState(for owner: Owner) -> AchievementState {
        switch owner {
        case .guest: return journal.guestAssignedTo.flatMap { journal.players[$0] } ?? journal.guest
        case .player(let id): return journal.players[id] ?? AchievementState()
        }
    }

    private func finishChange(before: AchievementState, persistImmediately: Bool = true) -> [AchievementDefinition] {
        pendingSave = true
        if persistImmediately { flush() }
        return catalog.filter { !before.progress(for: $0).isCompleted && journal.local.progress(for: $0).isCompleted }
    }

    private static func validPlayerID(_ id: String) -> Bool { !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private static func isValid(_ journal: Journal) -> Bool {
        journal.local.isValid() && journal.guest.isValid()
            && journal.players.allSatisfy { validPlayerID($0.key) && $0.value.isValid() }
            && (journal.guestAssignedTo.map(validPlayerID) ?? true)
            && journal.runs.allSatisfy { key, run in
                UUID(uuidString: key) != nil && (run.lastLandingTick.map { $0 >= 0 } ?? true)
                    && run.bestDistance.isFinite && run.bestDistance >= 0 && validOwner(run.owner)
            }
            && journal.claims.allSatisfy { !$0.key.isEmpty && validOwner($0.value) }
    }
    private static func validOwner(_ owner: Owner) -> Bool {
        if case .player(let id) = owner { return validPlayerID(id) }
        return true
    }
}
