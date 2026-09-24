import Foundation

@MainActor private final class DeferredBoards {
    enum Failure: Error { case offline }
    var pending: [Bool: CheckedContinuation<WeeklyPlayerRecord?, any Error>] = [:]
    func load(_ isTime: Bool) async throws -> WeeklyPlayerRecord? {
        try await withCheckedThrowingContinuation { pending[isTime] = $0 }
    }
    func complete(_ isTime: Bool, _ record: WeeklyPlayerRecord?) {
        pending.removeValue(forKey: isTime)!.resume(returning: record)
    }
    func fail(_ isTime: Bool) { pending.removeValue(forKey: isTime)!.resume(throwing: Failure.offline) }
}

@main struct CheckWeeklyRecords {
    @MainActor static func main() async {
        var checks = 0
        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            guard condition() else { fatalError(message) }
            checks += 1
        }
        func settle() async { for _ in 0..<30 { await Task.yield() } }
        let start = Date()
        let a = WeeklyPlayerRecords.Scope(playerID: "A", challengeIdentifier: "week-1", start: start.addingTimeInterval(-10), end: start.addingTimeInterval(60))
        let b = WeeklyPlayerRecords.Scope(playerID: "B", challengeIdentifier: "week-1", start: a.start, end: a.end)
        let next = WeeklyPlayerRecords.Scope(playerID: "A", challengeIdentifier: "week-2", start: a.start, end: a.end)
        let result = WeeklyPlayerRecords()
        var current: WeeklyPlayerRecords.Scope? = a
        var clock = start
        func begin(_ scope: WeeklyPlayerRecords.Scope, _ boards: DeferredBoards) {
            result.refresh(scope: scope, now: clock,
                isCurrent: { current == scope && scope.contains(clock) }, load: boards.load)
        }
        let points = WeeklyPlayerRecord(score: 975, rank: 83)
        let duration = WeeklyPlayerRecord(score: 12345, rank: 217)
        let first = DeferredBoards()
        begin(a, first)
        expect(result.isLoading && result.scope == a, "Loading starts synchronously")
        await settle()
        expect(first.pending.count == 2, "Both requests start independently")
        first.complete(true, duration)
        await settle()
        expect(result.time == duration && result.score == nil && result.isLoading, "Time is visible while points pending")
        first.complete(false, points)
        await settle()
        expect(result.score == points && !result.isLoading, "Points preserve actual global rank outside requested top row")
        expect(result.time?.score == 12345, "Raw centiseconds remain unchanged")
        let empty = DeferredBoards()
        begin(a, empty)
        expect(result.score == nil && result.time == nil, "Refresh does not attach old rank to fresh data")
        await settle()
        empty.complete(false, nil); empty.fail(true)
        await settle()
        expect(!result.isLoading && result.scope == a && result.score == nil && result.time == nil, "Absent and unavailable stay nil")
        let partial = DeferredBoards()
        begin(a, partial); await settle()
        partial.fail(false); partial.complete(true, duration); await settle()
        expect(result.score == nil && result.time == duration && !result.isLoading, "Failure of one board preserves the other")
        let oldA = DeferredBoards()
        begin(a, oldA); await settle()
        current = b
        let newB = DeferredBoards()
        begin(b, newB); await settle()
        oldA.complete(false, points); oldA.complete(true, duration); await settle()
        expect(result.scope == b && result.score == nil && result.time == nil && result.isLoading, "Late A responses cannot modify B or its loading state")
        let bPoints = WeeklyPlayerRecord(score: 2, rank: 500)
        newB.complete(false, bPoints); newB.complete(true, nil); await settle()
        expect(result.score == bPoints && !result.isLoading, "Current B response succeeds")
        current = a
        let priorWeek = DeferredBoards()
        begin(a, priorWeek); await settle()
        current = next
        let newWeek = DeferredBoards()
        begin(next, newWeek); await settle()
        priorWeek.complete(false, points); priorWeek.complete(true, duration); await settle()
        expect(result.scope == next && result.score == nil && result.isLoading, "Old occurrence ignored after rollover")
        newWeek.complete(false, nil); newWeek.complete(true, nil); await settle()
        current = a
        let priorLogin = DeferredBoards()
        begin(a, priorLogin); await settle()
        current = nil; result.clear(); current = a
        let newLogin = DeferredBoards()
        begin(a, newLogin); await settle()
        priorLogin.complete(false, points); priorLogin.complete(true, duration); await settle()
        expect(result.isLoading && result.score == nil, "A to signed-out to A invalidates old generation")
        newLogin.complete(false, points); newLogin.complete(true, duration); await settle()
        expect(result.score == points && result.time == duration, "New login responses accepted")
        let expiry = DeferredBoards()
        begin(a, expiry); await settle()
        clock = a.end
        expiry.complete(false, points); expiry.complete(true, duration); await settle()
        expect(result.scope == nil && result.score == nil && !result.isLoading, "Results crossing exact occurrence end rejected")
        let unused = DeferredBoards()
        begin(a, unused); await settle()
        expect(unused.pending.isEmpty && !result.isLoading, "Expired scope launches no requests")
        clock = start; current = nil
        begin(a, unused); await settle()
        expect(unused.pending.isEmpty && result.scope == nil, "Unauthenticated scope launches no requests")
        current = a
        let invalid = DeferredBoards()
        begin(a, invalid); await settle()
        invalid.complete(false, WeeklyPlayerRecord(score: -1, rank: 1))
        invalid.complete(true, WeeklyPlayerRecord(score: 5, rank: 0)); await settle()
        expect(result.score == nil && result.time == nil, "Invalid score and unranked entry are rejected")
        let zero = DeferredBoards()
        begin(a, zero); await settle()
        zero.complete(false, WeeklyPlayerRecord(score: 0, rank: 42))
        zero.complete(true, WeeklyPlayerRecord(score: 0, rank: 42)); await settle()
        expect(result.score == WeeklyPlayerRecord(score: 0, rank: 42), "Zero points are a valid ranked score")
        expect(result.time == nil, "Zero-duration time is not a valid completed course")
        let signedOut = DeferredBoards()
        begin(a, signedOut); await settle()
        current = nil
        signedOut.complete(false, points); signedOut.complete(true, duration); await settle()
        expect(result.scope == nil && !result.isLoading, "Direct account invalidation while awaiting clears results")
        let short = WeeklyPlayerRecords.Scope(playerID: "A", challengeIdentifier: "closing", start: start.addingTimeInterval(-1), end: start.addingTimeInterval(0.2))
        current = short
        result.refresh(scope: short, now: start, isCurrent: { current == short }, load: { $0 ? duration : points })
        await settle()
        expect(result.score == points, "Current record can load before deadline")
        try? await Task.sleep(for: .milliseconds(220))
        expect(result.scope == nil && result.score == nil && result.time == nil, "Expiry timer removes already displayed ranks without another refresh")
        result.clear()
        print("PASS: \(checks) Weekly player-record checks; fake loaders only, no Game Center access")
    }
}
