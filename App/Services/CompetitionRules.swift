import Foundation

/// Each competition revision starts fresh records, queues and leaderboards.
enum CompetitionRules {
    struct CourseIdentity: Codable, Equatable, Sendable {
        let worldID: String
        let revision: Int
        var identifier: String { "\(worldID).route-\(revision)" }
        static let canyon = CourseIdentity(worldID: "canyon", revision: 1)
        static let japan = CourseIdentity(worldID: "japan", revision: 1)
    }

    static let version = "box2d-2"
    static let leaderboardVersion = "v3"
    static let queueFilename = "game-center-pending-\(version).json"
    // A competition reset does not reset the selected rider.
    static let riderPreferenceKey = "rider.box2d-1"
    static let weeklyRecordKey = "bestWeekly.\(version)"
    static let endlessRecordKey = "bestEndless.\(version)"

    static func leaderboardID(_ suffix: String) -> String {
        "com.daviddemri.crococross.\(suffix).\(leaderboardVersion)"
    }

    static func isCurrentLeaderboard(_ identifier: String) -> Bool {
        ["weekly.score", "weekly.time", "endless.score", "endless.japan.route-1.score"]
            .contains { leaderboardID($0) == identifier }
    }

    /// Only explicitly registered course revisions can submit. Canyon retains its existing board.
    static func endlessLeaderboardID(for course: CourseIdentity) -> String? {
        switch course {
        case .canyon: leaderboardID("endless.score")
        case .japan: leaderboardID("endless.japan.route-1.score")
        default: nil
        }
    }

    static func endlessRecordKey(for course: CourseIdentity) -> String {
        course == .canyon ? endlessRecordKey : "bestEndless.\(version).\(course.identifier)"
    }

    static func acceptsSubmission(rulesVersion: String, leaderboardID: String,
                                  weeklyBoardIDs: Set<String>, endlessBoardID: String,
                                  challengeIdentifier: String?, course: CourseIdentity? = nil,
                                  japanEndlessBoardID: String = leaderboardID("endless.japan.route-1.score")) -> Bool {
        guard rulesVersion == version, isCurrentLeaderboard(leaderboardID) else { return false }
        // Saves from before world routing omitted the course and are Canyon-only by definition.
        let course = course ?? .canyon
        guard let expectedEndlessID = endlessLeaderboardID(for: course) else { return false }
        if weeklyBoardIDs.contains(leaderboardID) {
            guard course == .canyon,
                  [Self.leaderboardID("weekly.score"), Self.leaderboardID("weekly.time")].contains(leaderboardID),
                  let challengeIdentifier else { return false }
            let prefix = "\(version).weekly."
            guard challengeIdentifier.hasPrefix(prefix),
                  let start = Int64(challengeIdentifier.dropFirst(prefix.count)), start >= 0 else { return false }
            return true
        }
        let configuredID = course == .canyon ? endlessBoardID : japanEndlessBoardID
        return leaderboardID == configuredID && leaderboardID == expectedEndlessID && challengeIdentifier == nil
    }
}
