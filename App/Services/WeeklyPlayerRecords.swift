import Foundation
import Observation

/// The score belongs to the same server entry as rank. Weekly time scores are centiseconds.
struct WeeklyPlayerRecord: Equatable, Sendable {
    let score: Int
    let rank: Int
}

/// Read-only, ephemeral results. Never carry a rank across an account or occurrence change.
@MainActor @Observable
final class WeeklyPlayerRecords {
    struct Scope: Equatable, Sendable {
        let playerID: String
        let challengeIdentifier: String
        let start: Date
        let end: Date

        func contains(_ date: Date) -> Bool { date >= start && date < end }
    }

    private(set) var scope: Scope?
    private(set) var score: WeeklyPlayerRecord?
    private(set) var time: WeeklyPlayerRecord?
    private(set) var isLoading = false
    @ObservationIgnored private var generation: UInt64 = 0
    @ObservationIgnored private var remaining = 0
    @ObservationIgnored private var tasks: [Task<Void, Never>] = []
    @ObservationIgnored private var expiryTask: Task<Void, Never>?

    func clear() {
        generation &+= 1
        tasks.forEach { $0.cancel() }
        tasks.removeAll()
        expiryTask?.cancel()
        expiryTask = nil
        scope = nil
        score = nil
        time = nil
        remaining = 0
        isLoading = false
    }

    /// Each board completes independently, and stale callbacks cannot clear a newer request.
    func refresh(scope: Scope, now: Date,
                 isCurrent: @escaping @MainActor () -> Bool,
                 load: @escaping @MainActor (_ time: Bool) async throws -> WeeklyPlayerRecord?) {
        clear()
        guard scope.contains(now), isCurrent() else { return }
        self.scope = scope
        isLoading = true
        remaining = 2
        let request = generation
        for isTime in [false, true] {
            tasks.append(Task { @MainActor [weak self] in
                guard !Task.isCancelled, isCurrent() else {
                    self?.finish(nil, time: isTime, request: request, isCurrent: isCurrent)
                    return
                }
                let result: WeeklyPlayerRecord?
                do { result = try await load(isTime) }
                catch { result = nil }
                self?.finish(result, time: isTime, request: request, isCurrent: isCurrent)
            })
        }
        expiryTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(for: .seconds(scope.end.timeIntervalSince(now))) }
            catch { return }
            guard let self, self.generation == request else { return }
            self.clear()
        }
    }

    private func finish(_ record: WeeklyPlayerRecord?, time isTime: Bool, request: UInt64,
                        isCurrent: @MainActor () -> Bool) {
        guard generation == request else { return }
        guard isCurrent() else { clear(); return }
        let valid = record.flatMap { $0.score >= 0 && $0.rank > 0 && (!isTime || $0.score > 0) ? $0 : nil }
        if isTime { time = valid } else { score = valid }
        remaining -= 1
        isLoading = remaining > 0
        if !isLoading { tasks.removeAll() }
    }

    deinit {
        tasks.forEach { $0.cancel() }
        expiryTask?.cancel()
    }
}
