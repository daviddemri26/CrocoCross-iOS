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
        var japanEndlessScore: String

        static func configured(in bundle: Bundle = .main) -> Self {
            func identifier(_ key: String, _ suffix: String) -> String {
                let value = bundle.object(forInfoDictionaryKey: key) as? String
                return value.flatMap { $0 == CompetitionRules.leaderboardID(suffix) ? $0 : nil }
                    ?? CompetitionRules.leaderboardID(suffix)
            }
            return Self(
                weeklyScore: identifier("CrocoWeeklyScoreLeaderboardID", "weekly.score"),
                weeklyTime: identifier("CrocoWeeklyTimeLeaderboardID", "weekly.time"),
                endlessScore: identifier("CrocoEndlessScoreLeaderboardID", "endless.score"),
                japanEndlessScore: identifier("CrocoJapanEndlessScoreLeaderboardID", "endless.japan.route-1.score")
            )
        }

        var isCurrentVersion: Bool {
            weeklyScore == CompetitionRules.leaderboardID("weekly.score") &&
            weeklyTime == CompetitionRules.leaderboardID("weekly.time") &&
            endlessScore == CompetitionRules.leaderboardID("endless.score") &&
            japanEndlessScore == CompetitionRules.leaderboardID("endless.japan.route-1.score")
        }

        func endlessScore(for course: CompetitionRules.CourseIdentity) -> String? {
            switch course {
            case .canyon: endlessScore
            case .japan: japanEndlessScore
            default: nil
            }
        }
    }

    private struct PendingScore: Codable, Equatable {
        var rulesVersion = CompetitionRules.version
        var playerID: String
        var leaderboardID: String
        var score: Int
        var context: Int
        var challenge: WeeklyChallenge?
        // Optional only for decoding existing Canyon queues. New records always freeze their course.
        var course: CompetitionRules.CourseIdentity?
    }

    private(set) var isAuthenticated = false
    private(set) var playerName = "Guest"
    private(set) var currentPlayerID: String?
    private(set) var statusMessage: String?
    private(set) var weeklyChallenge: WeeklyChallenge?
    private let weeklyRecords = WeeklyPlayerRecords()
    var weeklyScoreRecord: WeeklyPlayerRecord? { weeklyRecordsAreCurrent ? weeklyRecords.score : nil }
    var weeklyTimeRecord: WeeklyPlayerRecord? { weeklyRecordsAreCurrent ? weeklyRecords.time : nil }
    var weeklyRecordsLoading: Bool { weeklyRecordsAreCurrent && weeklyRecords.isLoading }
    var weeklyRecordsChallengeIdentifier: String? {
        weeklyRecordsAreCurrent ? weeklyRecords.scope?.challengeIdentifier : nil
    }
    private var confirmedEndlessBoardIDs: Set<String> = []
    var endlessLeaderboardConfirmed: Bool { confirmedEndlessBoardIDs.contains(ids.endlessScore) }

    /// Both callbacks use the explicit Game Center owner, never the device-global UI ledger.
    @ObservationIgnored var achievementProgressProvider: ((String) -> [String: Double])?
    @ObservationIgnored var achievementRemoteProgressHandler: ((String, [String: Double], [String: Date]) -> Void)?
    private(set) var achievementStatusMessage: String?
    @ObservationIgnored private let achievementSync: GameCenterAchievementSync
    @ObservationIgnored private var achievementRetryTask: Task<Void, Never>?
    @ObservationIgnored private var achievementRetryAttempt = 0
    @ObservationIgnored private var isRefreshingAchievements = false
    @ObservationIgnored private var refreshAchievementsAgain = false

    @ObservationIgnored private let ids: LeaderboardIDs
    @ObservationIgnored private let store: LocalStore
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let onlineEnabled: Bool
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
    @ObservationIgnored private static let queueFilename = CompetitionRules.queueFilename

    init(ids: LeaderboardIDs = .configured(), store: LocalStore = LocalStore(), now: @escaping () -> Date = Date.init,
         onlineEnabled: Bool = !ProcessInfo.processInfo.arguments.contains("-ui-testing")) {
        self.ids = ids
        self.store = store
        self.now = now
        self.onlineEnabled = onlineEnabled
        achievementSync = GameCenterAchievementSync(
            store: store, gateway: GameKitAchievementGateway(),
            allowedIDs: Set(AchievementCatalog.standard.map(\.gameCenterID)),
            enabled: GameCenterAchievementPolicy.allowsReporting(
                configurationEnabled: Bundle.main.object(forInfoDictionaryKey: "CrocoGameCenterAchievementsEnabled") as? Bool == true,
                onlineEnabled: onlineEnabled))
        super.init()
        achievementSync.onRemoteProgress = { [weak self] owner, progress, dates in
            self?.achievementRemoteProgressHandler?(owner, progress, dates)
        }
        do {
            pending = try store.load([PendingScore].self, from: Self.queueFilename) ?? []
            if !pending.allSatisfy(accepts) {
                // Do not silently erase a stale or mismatched route. Valid items may still retry in memory.
                queueCanBeSaved = false
                statusMessage = "Some saved scores use a different course. The original queue is preserved; new submissions will stay in memory."
            }
        }
        catch {
            // Preserve a malformed/newer file for recovery; do not silently overwrite it.
            queueCanBeSaved = false
            statusMessage = "Saved Game Center submissions could not be restored. New scores will stay in memory."
        }
        guard onlineEnabled else { return }
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
        guard onlineEnabled else { return }
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
        guard onlineEnabled, ids.isCurrentVersion else { return }
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
        // An unavailable achievement endpoint must not delay ranked-course validation.
        Task { [weak self] in await self?.refreshAchievements() }
        guard GKLocalPlayer.local.isAuthenticated, GKLocalPlayer.local.gamePlayerID == playerID else { return }
        // Each world is confirmed independently, including when the base board group fails to load.
        await refreshJapanLeaderboard(playerID: playerID)
        guard currentPlayerID == playerID, GKLocalPlayer.local.isAuthenticated,
              GKLocalPlayer.local.gamePlayerID == playerID else { return }
        do {
            let loaded = try await GKLeaderboard.loadLeaderboards(IDs: [ids.weeklyScore, ids.weeklyTime, ids.endlessScore])
            guard currentPlayerID == playerID, GKLocalPlayer.local.gamePlayerID == playerID else { return }
            confirmedEndlessBoardIDs.remove(ids.endlessScore)
            if loaded.contains(where: {
                $0.baseLeaderboardID == ids.endlessScore && $0.type == .classic
            }) { confirmedEndlessBoardIDs.insert(ids.endlessScore) }
            guard let score = loaded.first(where: { $0.baseLeaderboardID == ids.weeklyScore }),
                  let time = loaded.first(where: { $0.baseLeaderboardID == ids.weeklyTime }),
                  score.type == .recurring, time.type == .recurring,
                  let challenge = WeeklyChallenge.fromSchedule(start: score.startDate, duration: score.duration, nextStart: score.nextStartDate),
                  let timeChallenge = WeeklyChallenge.fromSchedule(start: time.startDate, duration: time.duration, nextStart: time.nextStartDate),
                  challenge == timeChallenge else {
                weeklyChallenge = nil
                weeklyBoards.removeAll()
                weeklyRecords.clear()
                statusMessage = "Weekly competition is not configured yet. Practice and Endless remain available."
                await flushPending()
                return
            }
            guard challenge.contains(now()) else {
                weeklyChallenge = nil
                weeklyBoards.removeAll()
                weeklyRecords.clear()
                statusMessage = "The next weekly competition has not started. You can practice locally."
                await flushPending()
                return
            }
            weeklyBoards = [ids.weeklyScore: score, ids.weeklyTime: time]
            weeklyChallenge = challenge
            refreshWeeklyPlayerRecords()
            statusMessage = queueCanBeSaved ? nil : statusMessage
            await flushPending()
        } catch {
            guard currentPlayerID == playerID else { return }
            // No newly ranked start while the active period cannot be confirmed.
            weeklyChallenge = nil
            weeklyBoards.removeAll()
            weeklyRecords.clear()
            confirmedEndlessBoardIDs.remove(ids.endlessScore)
            statusMessage = confirmedEndlessBoardIDs.contains(ids.japanEndlessScore)
                ? "Canyon and Weekly rankings could not be confirmed. Japan Endless remains available."
                : "Game Center could not be reached. Scores are kept locally; weekly practice is available."
            await flushPending()
        }
    }

    private var weeklyRecordsAreCurrent: Bool {
        guard onlineEnabled, isAuthenticated, let scope = weeklyRecords.scope,
              scope.playerID == currentPlayerID, scope.contains(now()),
              weeklyChallenge?.identifier == scope.challengeIdentifier,
              GKLocalPlayer.local.isAuthenticated,
              GKLocalPlayer.local.gamePlayerID == scope.playerID else { return false }
        return true
    }

    private func refreshWeeklyPlayerRecords() {
        guard onlineEnabled, isAuthenticated, ids.isCurrentVersion, let playerID = currentPlayerID,
              let challenge = weeklyChallenge, challenge.contains(now()),
              let scoreBoard = weeklyBoards[ids.weeklyScore], let timeBoard = weeklyBoards[ids.weeklyTime] else {
            weeklyRecords.clear()
            return
        }
        let scope = WeeklyPlayerRecords.Scope(playerID: playerID, challengeIdentifier: challenge.identifier,
                                              start: challenge.start, end: challenge.end)
        let isCurrent: @MainActor () -> Bool = { [weak self] in
            guard let self, self.isAuthenticated, self.currentPlayerID == playerID,
                  GKLocalPlayer.local.isAuthenticated, GKLocalPlayer.local.gamePlayerID == playerID,
                  self.weeklyChallenge == challenge, challenge.contains(self.now()),
                  self.weeklyBoards[self.ids.weeklyScore] === scoreBoard,
                  self.weeklyBoards[self.ids.weeklyTime] === timeBoard else { return false }
            return [scoreBoard, timeBoard].allSatisfy { board in
                board.type == .recurring && WeeklyChallenge.fromSchedule(
                    start: board.startDate, duration: board.duration, nextStart: board.nextStartDate) == challenge
            }
        }
        weeklyRecords.refresh(scope: scope, now: now(), isCurrent: isCurrent) { isTime in
            guard isCurrent() else { return nil }
            let board = isTime ? timeBoard : scoreBoard
            // The local player's entry is returned separately even if outside the requested top row.
            // A recurring instance already selects its occurrence; timeScope only filters classic boards.
            let (entry, _, _) = try await board.loadEntries(
                for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 1))
            guard isCurrent(), let entry, entry.player.gamePlayerID == playerID,
                  entry.rank > 0, entry.score >= 0, !isTime || entry.score > 0 else { return nil }
            return WeeklyPlayerRecord(score: entry.score, rank: entry.rank)
        }
    }

    func isEndlessLeaderboardConfirmed(for course: WorldCoursePlan) -> Bool {
        guard course.supportsLeaderboards, let identifier = ids.endlessScore(for: course.competitionIdentity) else { return false }
        return confirmedEndlessBoardIDs.contains(identifier)
    }

    private func refreshJapanLeaderboard(playerID: String) async {
        do {
            let loaded = try await GKLeaderboard.loadLeaderboards(IDs: [ids.japanEndlessScore])
            guard currentPlayerID == playerID, GKLocalPlayer.local.isAuthenticated,
                  GKLocalPlayer.local.gamePlayerID == playerID else { return }
            confirmedEndlessBoardIDs.remove(ids.japanEndlessScore)
            if loaded.contains(where: { $0.baseLeaderboardID == ids.japanEndlessScore && $0.type == .classic }) {
                confirmedEndlessBoardIDs.insert(ids.japanEndlessScore)
            }
        } catch {
            guard currentPlayerID == playerID else { return }
            confirmedEndlessBoardIDs.remove(ids.japanEndlessScore)
        }
    }

    /// Explicit Weekly routing for the two permanent Rankings rows. A selected
    /// Endless world never changes which recurring board these buttons open.
    func isWeeklyLeaderboardConfirmed(time: Bool) -> Bool {
        guard onlineEnabled, isAuthenticated, ids.isCurrentVersion,
              let challenge = weeklyChallenge, challenge.contains(now()) else { return false }
        return weeklyBoards[time ? ids.weeklyTime : ids.weeklyScore] != nil
    }

    func showWeeklyLeaderboard(time: Bool) {
        guard onlineEnabled else { return }
        synchronizePlayer()
        guard isAuthenticated else {
            authenticate()
            statusMessage = "Sign in to Game Center in your device Settings to compare scores."
            return
        }
        guard isWeeklyLeaderboardConfirmed(time: time) else {
            statusMessage = "Weekly rankings are not available yet. Your local records are preserved."
            Task { [weak self] in await self?.refresh() }
            return
        }
        guard let presenter = Self.presenter(), presenter.presentedViewController == nil else { return }
        let controller = GKGameCenterViewController(
            leaderboardID: time ? ids.weeklyTime : ids.weeklyScore, playerScope: .global, timeScope: .allTime)
        controller.gameCenterDelegate = self
        presenter.present(controller, animated: true)
    }

    func showLeaderboards(course: WorldCoursePlan? = nil) {
        guard onlineEnabled else { return }
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
        let controller: GKGameCenterViewController
        if let course, course.supportsLeaderboards,
           let identifier = ids.endlessScore(for: course.competitionIdentity) {
            controller = GKGameCenterViewController(leaderboardID: identifier, playerScope: .global, timeScope: .allTime)
        } else {
            controller = GKGameCenterViewController(state: .leaderboards)
        }
        controller.gameCenterDelegate = self
        presenter.present(controller, animated: true)
    }

    /// The local progression owner is captured at the run/claim, even if that
    /// player has since signed out. No guest or device-global snapshot is accepted.
    func syncAchievements(localProgress: [String: Double], playerID: String?) {
        guard let playerID, !playerID.isEmpty, achievementSync.enabled else { return }
        achievementSync.enqueue(localProgress, for: playerID)
        achievementStatusMessage = achievementSync.storageError
        Task { [weak self] in await self?.refreshAchievements() }
    }

    func refreshAchievements() async {
        guard onlineEnabled, achievementSync.enabled else { return }
        synchronizePlayer()
        guard let playerID = currentPlayerID, isAuthenticated else { return }
        if isRefreshingAchievements { refreshAchievementsAgain = true; return }
        isRefreshingAchievements = true
        defer {
            isRefreshingAchievements = false
            if refreshAchievementsAgain {
                refreshAchievementsAgain = false
                Task { [weak self] in await self?.refreshAchievements() }
            }
        }
        if let progress = achievementProgressProvider?(playerID) {
            achievementSync.enqueue(progress, for: playerID)
        }
        let result = await achievementSync.synchronize()
        guard currentPlayerID == playerID, GKLocalPlayer.local.isAuthenticated,
              GKLocalPlayer.local.gamePlayerID == playerID else { return }
        achievementStatusMessage = achievementSync.storageError ?? achievementSync.synchronizationError
        switch result {
        case .retry:
            scheduleAchievementRetry()
        case .synchronized:
            achievementRetryTask?.cancel()
            achievementRetryTask = nil
            achievementRetryAttempt = 0
        default:
            break
        }
    }

    func showAchievements() {
        guard onlineEnabled else { return }
        synchronizePlayer()
        guard isAuthenticated else {
            authenticate()
            achievementStatusMessage = "Sign in to Game Center in your device Settings to view synced achievements."
            return
        }
        guard let presenter = Self.presenter(), presenter.presentedViewController == nil,
              !GKAccessPoint.shared.isPresentingGameCenter else { return }
        GKAccessPoint.shared.trigger(state: .achievements) { }
        Task { [weak self] in await self?.refreshAchievements() }
    }

    private func scheduleAchievementRetry() {
        guard achievementRetryTask == nil else { return }
        let seconds = min(60, 2 << min(achievementRetryAttempt, 5))
        achievementRetryAttempt += 1
        achievementRetryTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
            guard let self else { return }
            self.achievementRetryTask = nil
            guard UIApplication.shared.applicationState == .active else { return }
            await self.refreshAchievements()
        }
    }

    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor [weak self] in
            gameCenterViewController.dismiss(animated: true)
            await self?.refresh()
        }
    }

    /// Call only for a run that began ranked, with the playerID and confirmed challenge captured at start.
    /// Queue under that original owner even after sign-out. Uploads wait for the same account to return.
    func record(state: SimulationState, challenge: WeeklyChallenge?, playerID: String?, course: WorldCoursePlan = .weekly) {
        guard onlineEnabled, ids.isCurrentVersion, course.supportsLeaderboards else { return }
        synchronizePlayer()
        guard let playerID, !playerID.isEmpty,
              state.score >= 0, state.tick > 0, state.elapsed.isFinite else { return }
        switch state.mode {
        case .weekly:
            guard course == .weekly, state.status == .finished, let challenge,
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
                                 score: state.score, context: state.tick, challenge: challenge, course: course.competitionIdentity))
            enqueue(PendingScore(playerID: playerID, leaderboardID: ids.weeklyTime,
                                 score: Int(centiseconds), context: state.score, challenge: challenge, course: course.competitionIdentity))
        case .endless:
            guard challenge == nil, let identifier = ids.endlessScore(for: course.competitionIdentity) else { return }
            enqueue(PendingScore(playerID: playerID, leaderboardID: identifier,
                                 score: state.score, context: state.tick, challenge: nil, course: course.competitionIdentity))
        }
        persistQueue()
        Task { [weak self] in await self?.flushPending() }
    }

    private func enqueue(_ candidate: PendingScore) {
        guard accepts(candidate) else { return }
        if let index = pending.firstIndex(where: {
            $0.rulesVersion == candidate.rulesVersion &&
            $0.playerID == candidate.playerID && $0.leaderboardID == candidate.leaderboardID &&
            ($0.course ?? .canyon) == (candidate.course ?? .canyon) &&
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
        let playerChanged = identifier != currentPlayerID
        if playerChanged {
            weeklyChallenge = nil
            confirmedEndlessBoardIDs.removeAll()
            weeklyBoards.removeAll()
            weeklyRecords.clear()
            retryTask?.cancel()
            retryTask = nil
            retryAttempt = 0
            achievementRetryTask?.cancel()
            achievementRetryTask = nil
            achievementRetryAttempt = 0
            achievementStatusMessage = nil
            if queueCanBeSaved { statusMessage = nil }
        }
        achievementSync.setAuthenticatedPlayer(identifier)
        currentPlayerID = identifier
        isAuthenticated = player.isAuthenticated
        playerName = player.isAuthenticated ? player.displayName : "Guest"
        if playerChanged, let identifier, let progress = achievementProgressProvider?(identifier) {
            // Persist first-account guest attribution even before remote
            // achievements are configured. An inactive outbox does no network I/O.
            achievementSync.enqueue(progress, for: identifier)
        }
    }

    private func flushPending() async {
        guard onlineEnabled, ids.isCurrentVersion, isAuthenticated, let playerID = currentPlayerID else { return }
        if isFlushing { flushAgain = true; return }
        isFlushing = true
        var submittedWeekly = false
        defer {
            if submittedWeekly { refreshWeeklyPlayerRecords() }
            isFlushing = false
            if flushAgain {
                flushAgain = false
                Task { [weak self] in await self?.flushPending() }
            }
        }
        pruneExpiredScores()
        // Snapshot prevents a concurrent better local result from being removed after this await.
        for submission in pending where submission.playerID == playerID && accepts(submission) {
            guard GKLocalPlayer.local.isAuthenticated,
                  GKLocalPlayer.local.gamePlayerID == playerID, currentPlayerID == playerID else { return }
            do {
                if let challenge = submission.challenge {
                    guard challenge == WeeklyChallenge.fromSchedule(start: challenge.start,
                              duration: challenge.end.timeIntervalSince(challenge.start), nextStart: challenge.end),
                          challenge.contains(now()), let leaderboard = weeklyBoards[submission.leaderboardID],
                          let start = leaderboard.startDate,
                          abs(start.timeIntervalSince(challenge.start)) < 0.5,
                          abs(leaderboard.duration - challenge.end.timeIntervalSince(challenge.start)) < 0.5 else {
                        continue
                    }
                    // Instance submission binds this score to the original occurrence even across midnight.
                    try await leaderboard.submitScore(submission.score, context: submission.context, player: GKLocalPlayer.local)
                } else {
                    guard confirmedEndlessBoardIDs.contains(submission.leaderboardID),
                          submission.leaderboardID == ids.endlessScore(for: submission.course ?? .canyon) else { continue }
                    try await GKLeaderboard.submitScore(submission.score, context: submission.context,
                                                        player: GKLocalPlayer.local, leaderboardIDs: [submission.leaderboardID])
                }
                guard currentPlayerID == playerID, GKLocalPlayer.local.isAuthenticated,
                      GKLocalPlayer.local.gamePlayerID == playerID else { return }
                if submission.challenge != nil { submittedWeekly = true }
                if let index = pending.firstIndex(of: submission) { pending.remove(at: index) }
                persistQueue()
                retryAttempt = 0
                statusMessage = queueCanBeSaved ? "Score submitted to Game Center." : statusMessage
            } catch {
                guard currentPlayerID == playerID, GKLocalPlayer.local.isAuthenticated,
                      GKLocalPlayer.local.gamePlayerID == playerID else { return }
                statusMessage = "Game Center is unavailable. Submission will be retried while the competition is open."
                flushAgain = false
                scheduleRetry()
                return
            }
        }
    }

    private func pruneExpiredScores() {
        let previousCount = pending.count
        pending.removeAll { accepts($0) && ($0.challenge.map { !$0.contains(now()) } ?? false) }
        if pending.count != previousCount { persistQueue() }
    }

    private func accepts(_ submission: PendingScore) -> Bool {
        guard !submission.playerID.isEmpty, submission.score >= 0, submission.context >= 0 else { return false }
        if let challenge = submission.challenge {
            guard challenge == WeeklyChallenge.fromSchedule(start: challenge.start,
                duration: challenge.end.timeIntervalSince(challenge.start), nextStart: challenge.end) else { return false }
        }
        return CompetitionRules.acceptsSubmission(
            rulesVersion: submission.rulesVersion, leaderboardID: submission.leaderboardID,
            weeklyBoardIDs: [ids.weeklyScore, ids.weeklyTime], endlessBoardID: ids.endlessScore,
            challengeIdentifier: submission.challenge?.identifier, course: submission.course,
            japanEndlessBoardID: ids.japanEndlessScore)
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
        achievementRetryTask?.cancel()
    }
}

/// Thin live adapter. Tests replace this gateway and never contact Game Center.
@MainActor
private final class GameKitAchievementGateway: GameCenterAchievementGateway {
    enum AccountError: Error { case changed }
    var authenticatedPlayerID: String? {
        GKLocalPlayer.local.isAuthenticated ? GKLocalPlayer.local.gamePlayerID : nil
    }

    func loadProgress(for playerID: String) async throws -> GameCenterAchievementSnapshot {
        guard authenticatedPlayerID == playerID else { throw AccountError.changed }
        let achievements = try await GKAchievement.loadAchievements()
        guard authenticatedPlayerID == playerID else { throw AccountError.changed }
        var snapshot = GameCenterAchievementSnapshot(progress: [:])
        for achievement in achievements {
            let identifier = achievement.identifier
            guard !identifier.isEmpty else { continue }
            snapshot.progress[identifier] = max(snapshot.progress[identifier] ?? 0, achievement.percentComplete)
            if achievement.isCompleted {
                snapshot.completionDates[identifier] = achievement.lastReportedDate
            }
        }
        return snapshot
    }

    func reportProgress(_ progress: [String: Double], for playerID: String) async throws {
        guard authenticatedPlayerID == playerID else { throw AccountError.changed }
        let player = GKLocalPlayer.local
        let achievements = progress.sorted { $0.key < $1.key }.map { identifier, percent in
            let achievement = GKAchievement(identifier: identifier, player: player)
            achievement.percentComplete = percent
            // CrocoCross owns the persisted local completion toast. Suppress
            // Apple's default banner during completion, replay and reconciliation.
            achievement.showsCompletionBanner = false
            return achievement
        }
        guard authenticatedPlayerID == playerID else { throw AccountError.changed }
        try await GKAchievement.report(achievements)
        guard authenticatedPlayerID == playerID else { throw AccountError.changed }
    }
}
