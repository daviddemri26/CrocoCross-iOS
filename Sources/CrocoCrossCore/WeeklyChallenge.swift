import Foundation

/// A frozen weekly course. This value describes a period; it is not proof of Game Center eligibility.
public struct WeeklyChallenge: Codable, Equatable, Sendable {
    public static let courseVersion = PhysicsConfiguration.engineVersion
    public static let duration: TimeInterval = 7 * 24 * 60 * 60

    public let seed: UInt32
    public let start: Date
    public let end: Date
    public let identifier: String

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
        let epoch = Int64(start.timeIntervalSince1970.rounded(.down))
        identifier = "\(Self.courseVersion).weekly.\(epoch)"
        seed = identifier.utf8.reduce(UInt32(2_166_136_261)) { ($0 ^ UInt32($1)) &* 16_777_619 }
    }

    public func contains(_ date: Date) -> Bool { date >= start && date < end }

    /// Validates scheduling metadata; this does not authenticate the player or verify a score.
    /// Duration alone is insufficient: the next occurrence must begin immediately after this week.
    public static func fromSchedule(start: Date?, duration: TimeInterval, nextStart: Date?) -> WeeklyChallenge? {
        guard let start, let nextStart, duration.isFinite,
              start.timeIntervalSince1970.isFinite, nextStart.timeIntervalSince1970.isFinite,
              abs(duration - Self.duration) < 0.5,
              abs(nextStart.timeIntervalSince(start) - Self.duration) < 0.5 else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let parts = calendar.dateComponents([.weekday, .hour, .minute, .second], from: start)
        guard parts.weekday == 2, parts.hour == 0, parts.minute == 0, parts.second == 0 else { return nil }
        return WeeklyChallenge(start: start, end: start.addingTimeInterval(duration))
    }

    /// Local practice always starts on Monday at 00:00 UTC, independent of device locale and DST.
    public static func practice(now: Date = Date()) -> WeeklyChallenge {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let midnight = calendar.startOfDay(for: now)
        let daysSinceMonday = (calendar.component(.weekday, from: midnight) + 5) % 7
        let start = midnight.addingTimeInterval(-Double(daysSinceMonday) * 86_400)
        return WeeklyChallenge(start: start, end: start.addingTimeInterval(duration))
    }
}
