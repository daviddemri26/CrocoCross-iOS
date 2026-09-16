// Run from the native repository root:
// xcrun swiftc -swift-version 6 App/Services/CompetitionRules.swift App/Services/LocalStore.swift scripts/check-competition-versioning.swift -o /tmp/crococross-competition-check
// /tmp/crococross-competition-check
// Uses an isolated temporary directory; no account, network or app data is accessed.
import Foundation

@main struct CheckCompetitionVersioning {
    enum Failure: Error { case expectation(String) }
    struct Score: Codable, Equatable { let rulesVersion: String; let score: Int }

    static func expect(_ condition: Bool, _ message: String) throws {
        if !condition { throw Failure.expectation(message) }
    }

    static func main() throws {
        let weeklyScore = CompetitionRules.leaderboardID("weekly.score")
        let weeklyTime = CompetitionRules.leaderboardID("weekly.time")
        let endless = CompetitionRules.leaderboardID("endless.score")
        let week = "box2d-1.weekly.1789344000"
        func accepted(_ board: String, _ challenge: String?, version: String = "box2d-1") -> Bool {
            CompetitionRules.acceptsSubmission(rulesVersion: version, leaderboardID: board,
                weeklyBoardIDs: [weeklyScore, weeklyTime], endlessBoardID: endless,
                challengeIdentifier: challenge)
        }
        try expect(accepted(weeklyScore, week), "Current weekly points must remain eligible")
        try expect(accepted(weeklyTime, week), "Current weekly times must remain eligible")
        try expect(accepted(endless, nil), "Current Endless scores must remain eligible")
        for version in ["native-5", "box2d-2", ""] {
            try expect(!accepted(weeklyScore, week, version: version), "Other rule versions must never submit")
            try expect(!accepted(endless, nil, version: version), "Endless must enforce rule version too")
        }
        try expect(!accepted(weeklyScore, "native-5.weekly.1789344000"), "An old course cannot join the new week")
        try expect(!accepted(weeklyScore, nil), "Weekly needs its original challenge")
        try expect(!accepted(endless, week), "A weekly result cannot enter Endless")
        try expect(!accepted("com.daviddemri.crococross.endless.score.v1", nil), "Legacy board IDs must be rejected")
        try expect(!accepted("unrelated.score.v2", nil), "Version suffix alone does not authorize a board")
        try expect(CompetitionRules.weeklyRecordKey != "bestWeekly" &&
                   CompetitionRules.endlessRecordKey != "bestEndless" &&
                   CompetitionRules.riderPreferenceKey != "rider", "Legacy preferences must retain their namespace")

        let root = FileManager.default.temporaryDirectory.appendingPathComponent("CrocoCrossCompetition-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalStore(rootURL: root)
        let legacyFilename = "game-center-pending.json"
        try store.save([Score(rulesVersion: "native-5", score: 12345)], to: legacyFilename)
        let legacyBytes = try Data(contentsOf: root.appendingPathComponent(legacyFilename))
        try expect(try store.load([Score].self, from: CompetitionRules.queueFilename) == nil,
                   "The new engine must start with an empty queue, not import the old one")
        let current = [Score(rulesVersion: CompetitionRules.version, score: 900)]
        try store.save(current, to: CompetitionRules.queueFilename)
        try expect(try store.load([Score].self, from: CompetitionRules.queueFilename) == current,
                   "The current queue must round-trip")
        try expect(try Data(contentsOf: root.appendingPathComponent(legacyFilename)) == legacyBytes,
                   "Saving a current result must preserve the exact legacy queue")
        print("PASS: competition version isolation, board/challenge routing and byte-for-byte legacy queue preservation.")
    }
}
