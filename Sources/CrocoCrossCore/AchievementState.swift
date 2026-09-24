import Foundation

public enum AchievementUnlockKind: String, Codable, Sendable { case rider, world }

public struct AchievementProgress: Codable, Equatable, Sendable {
    public let current: Double
    public let target: Double
    public let completedAt: Date?
    public var percentComplete: Double { min(100, max(0, current / target * 100)) }
    public var isCompleted: Bool { current >= target }

    init(current: Double, target: Double, completedAt: Date? = nil) {
        self.current = current; self.target = target; self.completedAt = completedAt
    }
}

/// These are monotonic achievement bounds, not reconstructed historical gameplay statistics.
/// A restored cumulative bound advances immediately with the next newly observed event.
public struct AchievementState: Codable, Equatable, Sendable {
    private var entries: [String: AchievementProgress] = [:]
    // A durable count/bound independent of catalog targets. Old saves can establish only their recorded maximum.
    private var lifetimeRotations: Double = 0
    private var needsLifetimeMigration = false
    private enum CodingKeys: String, CodingKey { case entries, lifetimeRotations }
    public init() {}

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        entries = try values.decode([String: AchievementProgress].self, forKey: .entries)
        needsLifetimeMigration = !values.contains(.lifetimeRotations)
        if !needsLifetimeMigration {
            let saved = try values.decode(Double.self, forKey: .lifetimeRotations)
            guard saved.isFinite && saved >= 0 else {
                throw DecodingError.dataCorruptedError(forKey: .lifetimeRotations, in: values, debugDescription: "Invalid lifetime rotation count")
            }
            lifetimeRotations = saved
        }
        lifetimeRotations = max(lifetimeRotations, recordedRotationBound)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(entries, forKey: .entries)
        try values.encode(lifetimeRotations, forKey: .lifetimeRotations)
    }

    private var recordedRotationBound: Double {
        entries.filter { $0.key.hasPrefix("stunt.total.") }.values.map(\.current).max() ?? 0
    }

    /// Materialize new milestones from known progress, without inventing a completion date or unseen rotations.
    mutating func restoreRotationMilestones(_ catalog: [AchievementDefinition]) {
        lifetimeRotations = max(lifetimeRotations, recordedRotationBound)
        for definition in catalog where definition.requirement == .totalRotations {
            let old = progress(for: definition)
            let current = max(old.current, min(definition.target, lifetimeRotations))
            if current > 0 {
                entries[definition.id] = AchievementProgress(current: current, target: definition.target, completedAt: old.completedAt)
            }
        }
        needsLifetimeMigration = false
    }

    /// Called once per validated landing, before advancing the individual cumulative trophies.
    mutating func addLandedRotations(_ count: Int) {
        lifetimeRotations += Double(count)
    }

    public func progress(for definition: AchievementDefinition) -> AchievementProgress {
        guard let stored = entries[definition.id] else {
            return AchievementProgress(current: 0, target: definition.target)
        }
        // Counts remain exact across repeated reads and incremental events. Rescale only for a changed target.
        if stored.target == definition.target { return stored }
        return AchievementProgress(current: min(definition.target, stored.percentComplete / 100 * definition.target),
                                   target: definition.target, completedAt: stored.completedAt)
    }

    mutating func advance(_ definition: AchievementDefinition, value: Double, cumulative: Bool, at date: Date) {
        let old = progress(for: definition)
        let next = definition.requirement == .totalRotations
            ? min(definition.target, lifetimeRotations)
            : min(definition.target, cumulative ? old.current + value : max(old.current, value))
        let earned = old.completedAt ?? (!old.isCompleted && next >= definition.target ? date : nil)
        entries[definition.id] = AchievementProgress(current: next, target: definition.target, completedAt: earned)
    }

    mutating func merge(_ definition: AchievementDefinition, percent: Double, completedAt: Date?) {
        let old = progress(for: definition)
        let next = max(old.current, definition.target * percent / 100)
        if definition.requirement == .totalRotations { lifetimeRotations = max(lifetimeRotations, next) }
        // A server completion without an earning date stays undated; never pretend it happened now.
        let date = old.completedAt ?? (percent >= 100 ? completedAt : nil)
        entries[definition.id] = AchievementProgress(current: next, target: definition.target, completedAt: date)
    }

    func isValid() -> Bool {
        lifetimeRotations.isFinite && lifetimeRotations >= 0 && entries.allSatisfy { key, value in
            !key.isEmpty && value.target.isFinite && value.target > 0 && value.current.isFinite
                && value.current >= 0 && value.current <= value.target
                && (value.completedAt == nil || (value.isCompleted && value.completedAt!.timeIntervalSince1970.isFinite))
        }
    }
}
