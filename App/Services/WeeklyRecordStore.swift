import Foundation
import Observation

struct WeeklyRecord: Codable, Equatable {
    let score: Int?
    let timeCentiseconds: Int?

    init(score: Int? = nil, timeCentiseconds: Int? = nil) {
        self.score = score
        self.timeCentiseconds = timeCentiseconds
    }
}

/// Local personal bests for the original weekly occurrence, including successful practice runs.
/// Score and time are independent records and may come from different rides.
@MainActor @Observable
final class WeeklyRecordStore {
    static let storagePrefix = "weeklyRecords.v1."
    @ObservationIgnored private let defaults: UserDefaults
    private var revision = 0

    private struct Envelope: Codable {
        let version: Int
        let value: WeeklyRecord
    }
    private enum Loaded {
        case missing, unreadable
        case record(WeeklyRecord)
    }

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func record(for identifier: String) -> WeeklyRecord {
        // Observation tracks writes through this store even though UserDefaults itself is not observable.
        _ = revision
        guard Self.isValidIdentifier(identifier), case .record(let record) = load(identifier) else {
            return WeeklyRecord()
        }
        return record
    }

    /// The caller admits only genuinely finished Weekly runs and passes their frozen challenge identifier.
    /// Matches Game Center's integer hundredths: round(elapsed seconds * 100), with lower time winning.
    @discardableResult func record(score: Int, elapsed: Double, challengeIdentifier: String) -> Bool {
        guard Self.isValidIdentifier(challengeIdentifier), score >= 0, elapsed.isFinite, elapsed > 0 else { return false }
        let roundedTime = (elapsed * 100).rounded()
        guard roundedTime > 0, roundedTime < Double(Int.max) else { return false }
        let time = Int(roundedTime)
        let previous: WeeklyRecord
        switch load(challengeIdentifier) {
        case .missing: previous = WeeklyRecord()
        case .record(let record): previous = record
        case .unreadable: return false // Keep damaged or newer data intact for recovery.
        }
        let next = WeeklyRecord(score: max(previous.score ?? score, score),
                                timeCentiseconds: min(previous.timeCentiseconds ?? time, time))
        guard next != previous, let data = try? JSONEncoder().encode(Envelope(version: 1, value: next)) else { return false }
        defaults.set(data, forKey: Self.storagePrefix + challengeIdentifier)
        revision &+= 1
        return true
    }

    private func load(_ identifier: String) -> Loaded {
        let key = Self.storagePrefix + identifier
        guard let stored = defaults.object(forKey: key) else { return .missing }
        guard let data = stored as? Data,
              let envelope = try? JSONDecoder().decode(Envelope.self, from: data), envelope.version == 1,
              envelope.value.score.map({ $0 >= 0 }) ?? true,
              envelope.value.timeCentiseconds.map({ $0 > 0 }) ?? true else { return .unreadable }
        return .record(envelope.value)
    }

    private static func isValidIdentifier(_ identifier: String) -> Bool {
        let parts = identifier.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3, !parts[0].isEmpty, parts[0].count <= 64,
              parts[0].utf8.allSatisfy({ (97...122).contains($0) || (48...57).contains($0) || $0 == 45 }),
              parts[1] == "weekly", let epoch = Int64(parts[2]), epoch >= 0 else { return false }
        return parts[2] == Substring(String(epoch))
    }
}
