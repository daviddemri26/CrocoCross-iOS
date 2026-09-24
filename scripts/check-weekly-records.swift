// Run from the native repository root:
// xcrun swiftc -swift-version 6 App/Services/WeeklyRecordStore.swift scripts/check-weekly-records.swift -o /tmp/crococross-weekly-records-check
// /tmp/crococross-weekly-records-check
// Uses a unique temporary UserDefaults suite; no live app data or Game Center access.
import Foundation
import Observation

private final class ObservationFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    func mark() { lock.lock(); value = true; lock.unlock() }
    var changed: Bool { lock.lock(); defer { lock.unlock() }; return value }
}

@main struct CheckWeeklyRecords {
    enum Failure: Error { case expectation(String) }
    static func expect(_ value: @autoclosure () -> Bool, _ message: String) throws {
        guard value() else { throw Failure.expectation(message) }
    }

    @MainActor static func main() throws {
        let suite = "CrocoCrossWeeklyRecordsTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let firstWeek = "box2d-2.weekly.1790035200"
        let nextWeek = "box2d-2.weekly.1790640000"
        let legacyKey = "bestWeekly.box2d-2"
        defaults.set(987_654, forKey: legacyKey)
        let store = WeeklyRecordStore(defaults: defaults)
        try expect(store.record(for: firstWeek) == WeeklyRecord(), "A new occurrence has no invented record")
        let observed = ObservationFlag()
        withObservationTracking { _ = store.record(for: firstWeek) } onChange: { observed.mark() }
        try expect(store.record(score: 100, elapsed: 12.34, challengeIdentifier: firstWeek), "First finish creates both records")
        try expect(observed.changed, "A successful write invalidates an observed snapshot getter")
        try expect(store.record(for: firstWeek) == WeeklyRecord(score: 100, timeCentiseconds: 1_234), "Time is stored in GC centiseconds")

        try expect(store.record(score: 200, elapsed: 15, challengeIdentifier: firstWeek), "A slower ride can improve score")
        try expect(store.record(for: firstWeek) == WeeklyRecord(score: 200, timeCentiseconds: 1_234), "Score and fastest time are independent")
        try expect(store.record(score: 50, elapsed: 11.116, challengeIdentifier: firstWeek), "A lower scoring ride can improve time")
        try expect(store.record(for: firstWeek) == WeeklyRecord(score: 200, timeCentiseconds: 1_112), "Time rounds to nearest centisecond")
        try expect(!store.record(score: 50, elapsed: 11.116, challengeIdentifier: firstWeek), "Repeated finish is idempotent")
        try expect(!store.record(score: 199, elapsed: 12, challengeIdentifier: firstWeek), "Worse runs never replace either record")

        try expect(store.record(for: nextWeek) == WeeklyRecord(), "Next week starts empty without overwriting the previous course")
        try expect(store.record(score: 20, elapsed: 10, challengeIdentifier: nextWeek), "Next week stores its own records")
        try expect(store.record(for: firstWeek).score == 200, "Old week remains intact")
        try expect(store.record(score: 300, elapsed: 11.5, challengeIdentifier: firstWeek), "A finish submitted later still updates its frozen original week")
        try expect(store.record(for: nextWeek) == WeeklyRecord(score: 20, timeCentiseconds: 1_000), "An old run never contaminates the new week")
        let relaunched = WeeklyRecordStore(defaults: UserDefaults(suiteName: suite)!)
        try expect(relaunched.record(for: firstWeek) == WeeklyRecord(score: 300, timeCentiseconds: 1_112), "Original week's records survive store recreation")
        try expect(relaunched.record(for: nextWeek) == WeeklyRecord(score: 20, timeCentiseconds: 1_000), "Current week's records survive store recreation")
        try expect(defaults.integer(forKey: legacyKey) == 987_654, "Unknown-occurrence legacy personal best is preserved, not imported")

        for time in [Double.nan, .infinity, -.infinity, 0, -1, 0.004, Double(Int.max), Double.greatestFiniteMagnitude] {
            try expect(!store.record(score: 999, elapsed: time, challengeIdentifier: nextWeek), "Invalid or unrepresentable elapsed time is rejected")
        }
        try expect(!store.record(score: -1, elapsed: 1, challengeIdentifier: nextWeek), "Negative score is rejected")
        for identifier in ["", " ", "box2d-2", "box2d-2.weekly.", "box2d-2.weekly.-1", "box2d-2.weekly.+1", "box2d-2.weekly.01", "box2d-2.weekly.not-a-date", "box2d-2.endless.1"] {
            try expect(!store.record(score: 1, elapsed: 1, challengeIdentifier: identifier), "Malformed occurrence identifier is rejected")
            try expect(store.record(for: identifier) == WeeklyRecord(), "Malformed occurrence returns an empty snapshot")
        }
        try expect(store.record(for: nextWeek) == WeeklyRecord(score: 20, timeCentiseconds: 1_000), "Invalid candidates leave valid records unchanged")

        let damagedWeek = "box2d-2.weekly.1791244800"
        let damagedKey = WeeklyRecordStore.storagePrefix + damagedWeek
        for bytes in [Data("broken".utf8), Data("{\"version\":99,\"value\":{\"score\":500,\"timeCentiseconds\":100}}".utf8),
                      Data("{\"version\":1,\"value\":{\"score\":-1,\"timeCentiseconds\":100}}".utf8)] {
            defaults.set(bytes, forKey: damagedKey)
            try expect(store.record(for: damagedWeek) == WeeklyRecord(), "Unreadable data is not displayed as a valid record")
            try expect(!store.record(score: 1, elapsed: 1, challengeIdentifier: damagedWeek), "Unreadable or newer data is never overwritten")
            try expect(defaults.data(forKey: damagedKey) == bytes, "Unreadable bytes remain intact")
        }
        let revised = "box2d-3.weekly.1790035200"
        try expect(store.record(for: revised) == WeeklyRecord(), "Another course version has independent records")
        print("PASS: independent Weekly score/time, nearest centisecond conversion, monotonic comparison, occurrence rollover, frozen old occurrence, store recreation, legacy preservation, invalid input and corrupted/newer save protection.")
    }
}
