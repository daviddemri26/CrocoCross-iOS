import CrocoCrossCore
import Foundation
import GameKit
import Network
import Observation
import UIKit

@MainActor @Observable
final class GameCenterService: NSObject, GKGameCenterControllerDelegate {
    struct LeaderboardIDs: Sendable {
        var weeklyScore: String
        var weeklyTime: String
        var endlessScore: String

        static func configured(in bundle: Bundle = .main) -> Self {
            func identifier(_ key: String, _ suffix: String) -> String {
                let value = bundle.object(forInfoDictionaryKey: key) as? String
                return value?.isEmpty == false ? value! : "com.daviddemri.crococross.\(suffix).v1"
            }
            return Self(
                weeklyScore: identifier("CrocoWeeklyScoreLeaderboardID", "weekly.score"),
                weeklyTime: identifier("CrocoWeeklyTimeLeaderboardID", "weekly.time"),
                endlessScore: identifier("CrocoEndlessScoreLeaderboardID", "endless.score")
            )
        }
    }

    private struct PendingScore: Codable, Equatable {
        var playerID: String
        var leaderboardID: String
        var score: Int
        var context: Int
        var challenge: WeeklyChallenge?
    }

    private(set) var isAuthenticated = false
    private(set) var playerName = "Guest"
    private(set) var currentPlayerID: String?
    private(set) var statusMessage: String?
    private(set) var weeklyChallenge: WeeklyChallenge?

    @ObservationIgnored private let ids: LeaderboardIDs
    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let monitor = NWPathMonitor()
    @ObservationIgnored private var pending: [PendingScore] = []
    @ObservationIgnored private var queueCanBeSaved = true
    @ObservationIgnored private var weeklyBoards: [String: GKLeaderboard] = [:]
    @ObservationIgnored private var authenticationStarted = false
    @ObservationIgnored private var isFlushing = false
    @ObservationIgnored private var flushAgain = false
    @ObservationIgnored private var isRefreshing = false
    @ObservationIgnored private var refreshAgain = false
    @ObservationIgnored private var foregroundObserver: NotificationObservation?
    @ObservationIgnored private var retryTask: Task<Void, Never>?
    @ObservationIgnored private var retryAttempt = 0
    @ObservationIgnored private var pendingAuthenticationController: UIViewController?
    @ObservationIgnored private static let queueFilename = "game-center-pending.json"

    init(ids: LeaderboardIDs = .configured(), store: LocalStore = LocalStore(), now: @escaping () -> Date = Date.init) {
        self.ids = ids
        self.store = store
        self.now = now
        super.init()
        do { pending = try store.load([PendingScore].self, from: Self.queueFilename) ?? [] }
        catch {
            // Preserve a malformed/newer file for recovery; do not silently overwrite it.
            queueCanBeSaved = false
            statusMessage = "Saved Game Center submissions could not be restored. New scores will stay in memory."
        }
        monitor.pathUpdateHandler = { [weak self] path in
            guard path.status == .satisfied else { return }
            Task { @MainActor [weak self] in await self?.refresh() }
        }
        monitor.start(queue: DispatchQueue(label: "CrocoCross.GameCenter.network"))
        foregroundObserver = NotificationObservation(NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in Task { @MainActor [weak self] in await self?.refresh() } })
    }

    /// Call once at launch. GameKit owns sign-in; gameplay remains available if the player declines.
    func authenticate() {
        if authenticationStarted {
            if let controller = pendingAuthenticationController, let presenter = Self.presenter(),
               presenter.presentedViewController == nil {
                presenter.present(controller, animated: true)
                pendingAuthenticationController = nil
            } else if !isAuthenticated {
                statusMessage = "Sign in to Game Center in your device Settings to compare scores."
            }
            return
        }
        authenticationStarted = true
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let controller {
                    self.pendingAuthenticationController = controller
                    if let presenter = Self.presenter(), presenter.presentedViewController == nil {
                        presenter.present(controller, animated: true)
                        self.pendingAuthenticationController = nil
                    } else {
                        self.statusMessage = "Open Rankings to connect with Game Center."
                    }
                    return
                }
                self.pendingAuthenticationController = nil
                self.synchronizePlayer()
                if self.isAuthenticated {
                    await self.refresh()
                } else {
                    self.statusMessage = error == nil ? nil : "Game Center is unavailable. You can still play locally."
                }
            }
        }
    }

    func refresh() async {
        synchronizePlayer()
        guard isAuthenticated, let playerID = currentPlayerID else { return }
        if isRefreshing { refreshAgain = true; return }
        isRefreshing = true
        defer {
            isRefreshing = false
            if refreshAgain {
                refreshAgain = false
                Task { [weak self] in await self?.refresh() }
            }
        }
        pruneExpiredScores()
        do {
            let loaded = try await GKLeaderboard.loadLeaderboards(IDs: [ids.weeklyScore, ids.weeklyTime])
            guard currentPlayerID == playerID, GKLocalPlayer.local.gamePlayerID == playerID else { return }
            guard let score = loaded.first(where: { $0.baseLeaderboardID == ids.weeklyScore }),
                  let time = loaded.first(where: { $0.baseLeaderboardID == ids.weeklyTime }),
                  score.type == .recurring, time.type == .recurring,
                  let challenge = WeeklyChallenge.fromSchedule(start: score.startDate, duration: score.duration, nextStart: score.nextStartDate),
                  let timeChallenge = WeeklyChallenge.fromSchedule(start: time.startDate, duration: time.duration, nextStart: time.nextStartDate),
                  challenge == timeChallenge else {
                weeklyChallenge = nil
                weeklyBoards.removeAll()
                statusMessage = "Weekly competition is not configured yet. Practice and Endless remain available."
                await flushPending()
                return
            }
            guard challenge.contains(now()) else {
                weeklyChallenge = nil
                weeklyBoards.removeAll()
                statusMessage = "The next weekly competition has not started. You can practice locally."
                await flushPending()
                return
            }
            weeklyBoards = [ids.weeklyScore: score, ids.weeklyTime: time]
            weeklyChallenge = challenge
            statusMessage = queueCanBeSaved ? nil : statusMessage
            await flushPending()
        } catch {
            guard currentPlayerID == playerID else { return }
            // No newly ranked start while the active period cannot be confirmed.
            weeklyChallenge = nil
            statusMessage = "Game Center could not be reached. Scores are kept locally; weekly practice is available."
            await flushPending()
        }
    }

    func showLeaderboards() {
        guard isAuthenticated else {
            if let controller = pendingAuthenticationController, let presenter = Self.presenter(),
               presenter.presentedViewController == nil {
                presenter.present(controller, animated: true)
                pendingAuthenticationController = nil
                return
            }
            statusMessage = "Sign in to Game Center in your device Settings to compare scores."
            return
        }
        guard let presenter = Self.presenter(), presenter.presentedViewController == nil else { return }
        let controller = GKGameCenterViewController(state: .leaderboards)
        controller.gameCenterDelegate = self
        presenter.present(controller, animated: true)
    }

    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in gameCenterViewController.dismiss(animated: true) }
    }

    /// Call only for a run that began ranked, with the playerID and confirmed challenge captured at start.
    /// Queue under that original owner even after sign-out. Uploads wait for the same account to return.
    func record(state: SimulationState, challenge: WeeklyChallenge?, playerID: String?) {
        synchronizePlayer()
        guard let playerID, !playerID.isEmpty,
              state.score >= 0, state.tick > 0, state.elapsed.isFinite else { return }
        switch state.mode {
        case .weekly:
            guard state.status == .finished, let challenge,
                  challenge.seed == state.seed,
                  challenge == WeeklyChallenge.fromSchedule(start: challenge.start,
                      duration: challenge.end.timeIntervalSince(challenge.start), nextStart: challenge.end) else { return }
            guard challenge.contains(now()) else {
                statusMessage = "This week's competition ended. Your result is saved locally."
                return
            }
            let centiseconds = (state.elapsed * 100).rounded()
            guard centiseconds > 0, centiseconds < Double(Int.max) else { return }
            enqueue(PendingScore(playerID: playerID, leaderboardID: ids.weeklyScore,
                                 score: state.score, context: state.tick, challenge: challenge))
            enqueue(PendingScore(playerID: playerID, leaderboardID: ids.weeklyTime,
                                 score: Int(centiseconds), context: state.score, challenge: challenge))
        case .endless:
            enqueue(PendingScore(playerID: playerID, leaderboardID: ids.endlessScore,
                                 score: state.score, context: state.tick, challenge: nil))
        }
        persistQueue()
        Task { [weak self] in await self?.flushPending() }
    }

    private func enqueue(_ candidate: PendingScore) {
        if let index = pending.firstIndex(where: {
            $0.playerID == candidate.playerID && $0.leaderboardID == candidate.leaderboardID &&
            $0.challenge?.identifier == candidate.challenge?.identifier
        }) {
            let isBetter = candidate.leaderboardID == ids.weeklyTime
                ? candidate.score < pending[index].score : candidate.score > pending[index].score
            if isBetter { pending[index] = candidate }
        } else { pending.append(candidate) }
    }

    private func synchronizePlayer() {
        let player = GKLocalPlayer.local
        let identifier = player.isAuthenticated ? player.gamePlayerID : nil
        if identifier != currentPlayerID {
            weeklyChallenge = nil
            weeklyBoards.removeAll()
            retryTask?.cancel()
            retryTask = nil
            retryAttempt = 0
        }
        currentPlayerID = identifier
        isAuthenticated = player.isAuthenticated
        playerName = player.isAuthenticated ? player.displayName : "Guest"
    }

    private func flushPending() async {
        guard isAuthenticated, let playerID = currentPlayerID else { return }
        if isFlushing { flushAgain = true; return }
        isFlushing = true
        defer {
            isFlushing = false
            if flushAgain {
                flushAgain = false
                Task { [weak self] in await self?.flushPending() }
            }
        }
        pruneExpiredScores()
        // Snapshot prevents a concurrent better local result from being removed after this await.
        for submission in pending where submission.playerID == playerID {
            guard GKLocalPlayer.local.isAuthenticated,
                  GKLocalPlayer.local.gamePlayerID == playerID, currentPlayerID == playerID else { return }
            do {
                if let challenge = submission.challenge {
                    guard challenge.contains(now()), let leaderboard = weeklyBoards[submission.leaderboardID],
                          let start = leaderboard.startDate,
                          abs(start.timeIntervalSince(challenge.start)) < 0.5,
                          abs(leaderboard.duration - challenge.end.timeIntervalSince(challenge.start)) < 0.5 else {
                        continue
                    }
                    // Instance submission binds this score to the original occurrence even across midnight.
                    try await leaderboard.submitScore(submission.score, context: submission.context, player: GKLocalPlayer.local)
                } else {
                    guard submission.leaderboardID == ids.endlessScore else { continue }
                    try await GKLeaderboard.submitScore(submission.score, context: submission.context,
                                                        player: GKLocalPlayer.local, leaderboardIDs: [submission.leaderboardID])
                }
                if let index = pending.firstIndex(of: submission) { pending.remove(at: index) }
                persistQueue()
                retryAttempt = 0
                statusMessage = queueCanBeSaved ? "Score submitted to Game Center." : statusMessage
            } catch {
                statusMessage = "Game Center is unavailable. Submission will be retried while the competition is open."
                flushAgain = false
                scheduleRetry()
                return
            }
        }
    }

    private func pruneExpiredScores() {
        let previousCount = pending.count
        pending.removeAll { $0.challenge.map { !$0.contains(now()) } ?? false }
        if pending.count != previousCount { persistQueue() }
    }

    private func persistQueue() {
        guard queueCanBeSaved else { return }
        do { try store.save(pending, to: Self.queueFilename) }
        catch { statusMessage = "Game Center submissions could not be saved on this device. Please keep the app open." }
    }

    private func scheduleRetry() {
        guard retryTask == nil else { return }
        let seconds = min(60, 2 << min(retryAttempt, 5))
        retryAttempt += 1
        retryTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
            guard let self else { return }
            self.retryTask = nil
            guard UIApplication.shared.applicationState == .active else { return }
            await self.refresh()
        }
    }

    private static func presenter() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows.first { $0.isKeyWindow }
        var controller = window?.rootViewController
        while let presented = controller?.presentedViewController { controller = presented }
        return controller
    }

    deinit {
        monitor.cancel()
        retryTask?.cancel()
    }
}
