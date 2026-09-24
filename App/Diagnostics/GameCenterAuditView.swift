#if DEBUG
import CryptoKit
import CrocoCrossCore
import Foundation
import GameKit
import Observation
import SwiftUI

/// A separate application root: it never constructs GameSession, its stores, or its submission services.
struct GameCenterAuditView: View {
    @State private var audit = GameCenterAudit()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Game Center Audit").font(.largeTitle.bold())
                Text("Read-only · Debug").font(.headline).foregroundStyle(.secondary)
                Text("Reads achievement definitions and leaderboard metadata using the current Game Center account. Gameplay, saved progress and submission queues are not loaded.")
                Button("Read configuration") { audit.run() }
                    .buttonStyle(.borderedProminent).disabled(audit.isRunning)
                    .accessibilityIdentifier("gameCenterAudit.run")
                if audit.isRunning { ProgressView() }
                Text(audit.status).accessibilityIdentifier("gameCenterAudit.status")
                if let url = audit.reportURL {
                    ShareLink("Share JSON report", item: url)
                    Text(url.path).font(.caption.monospaced()).textSelection(.enabled)
                        .accessibilityIdentifier("gameCenterAudit.reportPath")
                }
                if !audit.details.isEmpty {
                    Text(audit.details).font(.caption.monospaced()).textSelection(.enabled)
                        .accessibilityIdentifier("gameCenterAudit.details")
                }
            }.padding(24).frame(maxWidth: 820, alignment: .leading).frame(maxWidth: .infinity)
        }.accessibilityIdentifier("gameCenterAudit.screen")
    }
}

@MainActor @Observable
private final class GameCenterAudit {
    struct Issue: Encodable {
        let endpoint: String
        let domain: String
        let code: Int
        let message: String
    }
    struct Achievement: Encodable {
        let identifier: String
        let title: String
        let beforeEarned: String
        let afterEarned: String
        let maximumPoints: Int
        let hidden: Bool
        let replayable: Bool
        let releaseState: String
        let mismatches: [String]
    }
    struct Board: Encodable {
        let requestedIdentifier: String
        let identifier: String
        let title: String?
        let type: String
        let expectedTypeMatches: Bool
        let startDate: Date?
        let nextStartDate: Date?
        let durationSeconds: Double?
        let releaseState: String
        let hidden: Bool?
        let weeklyScheduleValid: Bool?
        let activeNow: Bool?
        let challengeIdentifier: String?
    }
    struct Report: Encodable {
        let auditID = UUID()
        let startedAt = Date()
        var finishedAt: Date?
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "unknown"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let preferredLanguages = Locale.preferredLanguages
        let readOnly = true
        let normalGameSessionCreated = false
        let reportsScoresOrProgress = false
        let achievementReportingFlag = Bundle.main.object(forInfoDictionaryKey: "CrocoGameCenterAchievementsEnabled") as? Bool == true
        let expectedAchievementIdentifiers = AchievementCatalog.standard.map(\.gameCenterID)
        let expectedLeaderboardIdentifiers = GameCenterAudit.boardIDs
        var authenticated = false
        var playerFingerprint: String?
        var accountRemainedStable = true
        var achievementDefinitionsLoaded = false
        var achievements: [Achievement] = []
        var leaderboards: [Board] = []
        var missingAchievementIdentifiers: [String] = []
        var unexpectedAchievementIdentifiers: [String] = []
        var missingLeaderboardIdentifiers: [String] = []
        var weeklySchedulesMatch: Bool?
        var issues: [Issue] = []
        // These settings require an App Store Connect review; the loaded SDK objects do not expose them.
        let notVerifiedByThisAudit = ["leaderboard score format and sort order", "leaderboard best-score aggregation",
                                      "App Store version association", "achievement image contents", "score or achievement reporting"]
    }

    nonisolated static let boardIDs = ["weekly.score", "weekly.time", "endless.score", "endless.japan.route_1.score"]
        .map(CompetitionRules.leaderboardID)
    private(set) var status = "Ready. Nothing has been requested."
    private(set) var isRunning = false
    private(set) var reportURL: URL?
    private(set) var details = ""
    @ObservationIgnored private var report = Report()
    @ObservationIgnored private var runID = UUID()
    @ObservationIgnored private var authenticationPending = false
    @ObservationIgnored private var timeout: Task<Void, Never>?

    func run() {
        guard !isRunning else { return }
        report = Report(); reportURL = nil; details = ""; runID = UUID(); isRunning = true
        let token = runID
        status = "Checking the current Game Center session…"
        print("CROCO_GAME_CENTER_AUDIT_STARTED \(report.auditID)")
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(60))
            guard !Task.isCancelled, let self, self.active(token) else { return }
            self.report.issues.append(Issue(endpoint: "audit", domain: "CrocoCross.GameCenterAudit", code: 1,
                                           message: "Timed out after 60 seconds; incomplete endpoints remain unverified."))
            self.finish(token)
        }
        if GKLocalPlayer.local.isAuthenticated {
            Task { await load(token) }
        } else {
            authenticationPending = true
            GKLocalPlayer.local.authenticateHandler = { [weak self] controller, error in
                // Do not present an authentication controller or change the account.
                let needsSignIn = controller != nil
                Task { @MainActor [weak self] in
                    guard let self, self.active(token), self.authenticationPending else { return }
                    if let error { self.append(error, endpoint: "authentication"); self.finish(token) }
                    else if needsSignIn {
                        self.report.issues.append(Issue(endpoint: "authentication", domain: "CrocoCross.GameCenterAudit", code: 2,
                                                       message: "GameKit requires sign-in. No login UI was presented; sign in through device Settings, then retry."))
                        self.finish(token)
                    } else if GKLocalPlayer.local.isAuthenticated {
                        self.authenticationPending = false
                        await self.load(token)
                    } else {
                        self.report.issues.append(Issue(endpoint: "authentication", domain: "CrocoCross.GameCenterAudit", code: 3,
                                                       message: "The current player is not authenticated."))
                        self.finish(token)
                    }
                }
            }
        }
    }

    private func load(_ token: UUID) async {
        guard active(token), GKLocalPlayer.local.isAuthenticated else { return }
        let owner = GKLocalPlayer.local.gamePlayerID
        report.authenticated = true
        report.playerFingerprint = SHA256.hash(data: Data(owner.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
        status = "Reading achievement definitions…"
        do {
            let definitions = try await GKAchievementDescription.loadAchievementDescriptions()
            guard sameAccount(owner, token: token) else { return }
            report.achievementDefinitionsLoaded = true
            let expected = Dictionary(uniqueKeysWithValues: AchievementCatalog.standard.map { ($0.gameCenterID, $0) })
            report.achievements = definitions.map { item in
                var mismatches: [String] = []
                if let local = expected[item.identifier] {
                    if item.title != local.title { mismatches.append("title") }
                    if item.unachievedDescription != local.description { mismatches.append("beforeEarned") }
                    if item.achievedDescription != Self.earnedDescription(local.description) { mismatches.append("afterEarned") }
                    if item.maximumPoints != local.points { mismatches.append("maximumPoints") }
                    if item.isHidden { mismatches.append("hidden") }
                    if item.isReplayable { mismatches.append("replayable") }
                }
                let release: String
                if #available(iOS 18.4, *) { release = String(describing: item.releaseState) }
                else { release = "unavailable-on-this-OS" }
                return Achievement(identifier: item.identifier, title: item.title, beforeEarned: item.unachievedDescription,
                                   afterEarned: item.achievedDescription, maximumPoints: item.maximumPoints,
                                   hidden: item.isHidden, replayable: item.isReplayable, releaseState: release, mismatches: mismatches)
            }.sorted { $0.identifier < $1.identifier }
            let received = Set(definitions.map(\.identifier))
            report.missingAchievementIdentifiers = Set(expected.keys).subtracting(received).sorted()
            report.unexpectedAchievementIdentifiers = received.subtracting(expected.keys).sorted()
        } catch {
            guard sameAccount(owner, token: token) else { return }
            append(error, endpoint: "achievementDescriptions")
        }
        for identifier in Self.boardIDs {
            status = "Reading \(identifier)…"
            do {
                let boards = try await GKLeaderboard.loadLeaderboards(IDs: [identifier])
                guard sameAccount(owner, token: token) else { return }
                guard let board = boards.first(where: { $0.baseLeaderboardID == identifier }) else {
                    report.missingLeaderboardIdentifiers.append(identifier)
                    continue
                }
                let weekly = identifier == Self.boardIDs[0] || identifier == Self.boardIDs[1]
                let type = board.type == .recurring ? "recurring" : "classic"
                let challenge = weekly ? WeeklyChallenge.fromSchedule(start: board.startDate, duration: board.duration, nextStart: board.nextStartDate) : nil
                let release: String, hidden: Bool?
                if #available(iOS 26.0, *) { release = String(describing: board.releaseState); hidden = board.isHidden }
                else { release = "unavailable-on-this-OS"; hidden = nil }
                report.leaderboards.append(Board(requestedIdentifier: identifier, identifier: board.baseLeaderboardID, title: board.title,
                    type: type, expectedTypeMatches: weekly ? board.type == .recurring : board.type == .classic,
                    startDate: Self.finite(board.startDate), nextStartDate: Self.finite(board.nextStartDate),
                    durationSeconds: board.duration.isFinite ? board.duration : nil, releaseState: release, hidden: hidden,
                    weeklyScheduleValid: weekly ? challenge != nil : nil, activeNow: challenge?.contains(Date()), challengeIdentifier: challenge?.identifier))
            } catch {
                guard sameAccount(owner, token: token) else { return }
                report.missingLeaderboardIdentifiers.append(identifier)
                append(error, endpoint: identifier)
            }
        }
        if let score = report.leaderboards.first(where: { $0.identifier == Self.boardIDs[0] }),
           let time = report.leaderboards.first(where: { $0.identifier == Self.boardIDs[1] }) {
            report.weeklySchedulesMatch = score.weeklyScheduleValid == true && time.weeklyScheduleValid == true
                && score.challengeIdentifier == time.challengeIdentifier && score.startDate == time.startDate
                && score.nextStartDate == time.nextStartDate && score.durationSeconds == time.durationSeconds
        }
        finish(token)
    }

    private func active(_ token: UUID) -> Bool { isRunning && runID == token }
    private func sameAccount(_ owner: String, token: UUID) -> Bool {
        guard active(token) else { return false }
        guard GKLocalPlayer.local.isAuthenticated, GKLocalPlayer.local.gamePlayerID == owner else {
            report.accountRemainedStable = false
            report.issues.append(Issue(endpoint: "authentication", domain: "CrocoCross.GameCenterAudit", code: 4,
                                       message: "The authenticated account changed during the read. Remaining results are unverified."))
            finish(token)
            return false
        }
        return true
    }
    private func append(_ error: Error, endpoint: String) {
        let error = error as NSError
        report.issues.append(Issue(endpoint: endpoint, domain: error.domain, code: error.code, message: error.localizedDescription))
    }
    private func finish(_ token: UUID) {
        guard active(token) else { return }
        timeout?.cancel(); timeout = nil; authenticationPending = false
        report.finishedAt = Date(); isRunning = false
        let mismatches = report.achievements.filter { !$0.mismatches.isEmpty }.count
        status = "Read complete: \(report.achievements.count)/40 achievement definitions, \(report.leaderboards.count)/4 leaderboards, \(report.issues.count) errors, \(mismatches) metadata mismatches."
        do {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(report)
            let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("GameCenterAudit", isDirectory: true)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            let url = root.appendingPathComponent("game-center-audit-\(report.auditID.uuidString).json")
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            reportURL = url
            details = String(decoding: data, as: UTF8.self)
            print("CROCO_GAME_CENTER_AUDIT_REPORT \(url.path)\n\(details)")
        } catch {
            details = "Could not write the local audit report: \(error.localizedDescription)"
            print("CROCO_GAME_CENTER_AUDIT_SAVE_ERROR \(details)")
        }
    }
    private static func finite(_ date: Date?) -> Date? { date.flatMap { $0.timeIntervalSince1970.isFinite ? $0 : nil } }
    private static func earnedDescription(_ description: String) -> String {
        for (action, completion) in [("Safely land ", "You safely landed "), ("Ride ", "You rode "),
                                     ("Finish ", "You finished "), ("Unlock ", "You unlocked ")] {
            if description.hasPrefix(action) { return completion + description.dropFirst(action.count) }
        }
        return description
    }
}
#endif
