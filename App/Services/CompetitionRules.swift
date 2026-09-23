import Foundation

/// Each competition revision starts fresh records, queues and leaderboards.
enum CompetitionRules {
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
        ["weekly.score", "weekly.time", "endless.score"].contains { leaderboardID($0) == identifier }
    }

    static func acceptsSubmission(rulesVersion: String, leaderboardID: String,
                                  weeklyBoardIDs: Set<String>, endlessBoardID: String,
                                  challengeIdentifier: String?) -> Bool {
        guard rulesVersion == version, isCurrentLeaderboard(leaderboardID) else { return false }
        if weeklyBoardIDs.contains(leaderboardID) {
            return challengeIdentifier?.hasPrefix("\(version).weekly.") == true
        }
        return leaderboardID == endlessBoardID && challengeIdentifier == nil
    }
}
