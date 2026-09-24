// Run from the native repository root:
// xcrun swiftc -swift-version 6 App/Services/CompetitionRules.swift App/Services/LocalStore.swift scripts/check-competition-versioning.swift -o /tmp/crococross-competition-check
// /tmp/crococross-competition-check
// Uses an isolated temporary directory; no account, network or app data is accessed.
import Foundation

@main struct CheckCompetitionVersioning {
    enum Failure: Error { case expectation(String) }
    struct Score: Codable, Equatable { let rulesVersion: String; let score: Int }
    struct QueuedRoute: Codable, Equatable {
        let leaderboardID: String
        let course: CompetitionRules.CourseIdentity?
    }

    static func expect(_ condition: Bool, _ message: String) throws {
        if !condition { throw Failure.expectation(message) }
    }

    static func main() throws {
        let weeklyScore = CompetitionRules.leaderboardID("weekly.score")
        let weeklyTime = CompetitionRules.leaderboardID("weekly.time")
        let endless = CompetitionRules.leaderboardID("endless.score")
        let japan = CompetitionRules.leaderboardID("endless.japan.route-1.score")
        let week = "box2d-2.weekly.1789344000"
        func accepted(_ board: String, _ challenge: String?, version: String = "box2d-2",
                      course: CompetitionRules.CourseIdentity? = nil) -> Bool {
            CompetitionRules.acceptsSubmission(rulesVersion: version, leaderboardID: board,
                weeklyBoardIDs: [weeklyScore, weeklyTime], endlessBoardID: endless,
                challengeIdentifier: challenge, course: course, japanEndlessBoardID: japan)
        }
        try expect(accepted(weeklyScore, week), "Current weekly points must remain eligible")
        try expect(accepted(weeklyTime, week), "Current weekly times must remain eligible")
        try expect(accepted(endless, nil), "Current Endless scores must remain eligible")
        try expect(accepted(endless, nil, course: .canyon), "Explicit Canyon route preserves its current board")
        try expect(accepted(japan, nil, course: .japan), "Japan Endless uses its own board")
        try expect(!accepted(japan, nil), "A legacy queue without course identity cannot be relabeled Japan")
        try expect(!accepted(japan, nil, course: .canyon) && !accepted(endless, nil, course: .japan),
                   "Scores cannot cross world leaderboards")
        try expect(!accepted(japan, week, course: .japan) && !accepted(weeklyScore, week, course: .japan),
                   "Japan cannot enter either Weekly board or carry a Weekly challenge")
        try expect(!accepted(weeklyTime, week, course: .japan), "Japan cannot enter the Weekly time board")
        try expect(!CompetitionRules.acceptsSubmission(rulesVersion: CompetitionRules.version,
            leaderboardID: japan, weeklyBoardIDs: [weeklyScore, weeklyTime], endlessBoardID: japan,
            challengeIdentifier: nil, course: .canyon, japanEndlessBoardID: endless),
            "Swapped configured Endless boards cannot relabel a Canyon result")
        try expect(!CompetitionRules.acceptsSubmission(rulesVersion: CompetitionRules.version,
            leaderboardID: endless, weeklyBoardIDs: [weeklyScore, weeklyTime], endlessBoardID: japan,
            challengeIdentifier: nil, course: .japan, japanEndlessBoardID: endless),
            "Swapped configured Endless boards cannot relabel a Japan result")
        try expect(!CompetitionRules.acceptsSubmission(rulesVersion: CompetitionRules.version,
            leaderboardID: endless, weeklyBoardIDs: [endless, weeklyTime], endlessBoardID: endless,
            challengeIdentifier: week, course: .canyon), "An Endless board configured as Weekly is still rejected")
        for course in [CompetitionRules.CourseIdentity(worldID: "japan", revision: 2),
                       .init(worldID: "canyon", revision: 2), .init(worldID: "unknown", revision: 1)] {
            try expect(CompetitionRules.endlessLeaderboardID(for: course) == nil,
                       "Unregistered terrain revisions have no board")
            try expect(!accepted(japan, nil, course: course) && !accepted(endless, nil, course: course),
                       "Unregistered terrain revisions cannot submit")
        }
        try expect(CompetitionRules.endlessRecordKey(for: .canyon) == CompetitionRules.endlessRecordKey,
                   "Canyon's existing local record is preserved")
        try expect(CompetitionRules.endlessRecordKey(for: .japan) == "bestEndless.box2d-2.japan.route-1" &&
                   CompetitionRules.endlessRecordKey(for: .japan) != CompetitionRules.endlessRecordKey,
                   "Japan has an independent local record")
        try expect(CompetitionRules.endlessRecordKey(for: .init(worldID: "japan", revision: 2)) !=
                   CompetitionRules.endlessRecordKey(for: .japan), "Route revisions isolate local records")
        for version in ["native-5", "box2d-1", "box2d-3", ""] {
            try expect(!accepted(weeklyScore, week, version: version), "Other rule versions must never submit")
            try expect(!accepted(endless, nil, version: version), "Endless must enforce rule version too")
            try expect(!accepted(japan, nil, version: version, course: .japan), "Japan enforces rule version too")
        }
        try expect(!accepted(weeklyScore, "native-5.weekly.1789344000"), "An old course cannot join the new week")
        try expect(!accepted(weeklyScore, nil), "Weekly needs its original challenge")
        try expect(!accepted(weeklyScore, "box2d-2.weekly.") &&
                   !accepted(weeklyScore, "box2d-2.weekly.japan") &&
                   !accepted(weeklyScore, "box2d-2.weekly.-1"), "Malformed challenge identities are rejected")
        try expect(!accepted(endless, week), "A weekly result cannot enter Endless")
        try expect(!accepted("com.daviddemri.crococross.endless.score.v1", nil), "Legacy board IDs must be rejected")
        try expect(!accepted("unrelated.score.v3", nil), "Version suffix alone does not authorize a board")
        try expect(CompetitionRules.weeklyRecordKey != "bestWeekly" &&
                   CompetitionRules.endlessRecordKey != "bestEndless" &&
                   CompetitionRules.riderPreferenceKey != "rider", "Legacy preferences must retain their namespace")

        try expect(!accepted(weeklyScore, "box2d-1.weekly.1789344000"), "The previous 4,000 m course must not submit")
        for suffix in ["weekly.score", "weekly.time", "endless.score"] {
            let oldBoard = "com.daviddemri.crococross.\(suffix).v2"
            try expect(!CompetitionRules.isCurrentLeaderboard(oldBoard), "All previous boards must be excluded")
            try expect(!accepted(oldBoard, suffix.hasPrefix("weekly") ? week : nil), "No result may use an old board")
        }
        try expect(CompetitionRules.weeklyRecordKey != "bestWeekly.box2d-1" &&
                   CompetitionRules.endlessRecordKey != "bestEndless.box2d-1" &&
                   CompetitionRules.queueFilename != "game-center-pending-box2d-1.json",
                   "Both modes must start with fresh records and pending scores")
        try expect(CompetitionRules.riderPreferenceKey == "rider.box2d-1", "Keep the player's rider preference")

        let legacyRoute = try JSONDecoder().decode(QueuedRoute.self,
            from: Data("{\"leaderboardID\":\"\(endless)\"}".utf8))
        try expect(legacyRoute.course == nil && accepted(legacyRoute.leaderboardID, nil, course: legacyRoute.course),
                   "Existing Canyon queue entries remain eligible without a course field")
        let japanRoute = QueuedRoute(leaderboardID: japan, course: .japan)
        let restoredJapan = try JSONDecoder().decode(QueuedRoute.self, from: JSONEncoder().encode(japanRoute))
        try expect(restoredJapan == japanRoute && accepted(restoredJapan.leaderboardID, nil, course: restoredJapan.course),
                   "Frozen Japan world and route identity survive queue serialization")

        let root = FileManager.default.temporaryDirectory.appendingPathComponent("CrocoCrossCompetition-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = LocalStore(rootURL: root)
        let legacyFilename = "game-center-pending-box2d-1.json"
        try store.save([Score(rulesVersion: "box2d-1", score: 12345)], to: legacyFilename)
        let legacyBytes = try Data(contentsOf: root.appendingPathComponent(legacyFilename))
        try expect(try store.load([Score].self, from: CompetitionRules.queueFilename) == nil,
                   "The new engine must start with an empty queue, not import the old one")
        let current = [Score(rulesVersion: CompetitionRules.version, score: 900)]
        try store.save(current, to: CompetitionRules.queueFilename)
        try expect(try store.load([Score].self, from: CompetitionRules.queueFilename) == current,
                   "The current queue must round-trip")
        try expect(try Data(contentsOf: root.appendingPathComponent(legacyFilename)) == legacyBytes,
                   "Saving a current result must preserve the exact legacy queue")
        print("PASS: competition version isolation, independent world/revision boards and records, Weekly Canyon-only routing, frozen queued course identities, legacy Canyon compatibility and byte-for-byte legacy queue preservation.")
    }
}
