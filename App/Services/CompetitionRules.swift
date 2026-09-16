import Foundation

/// Incompatible physics starts a new competition without rewriting legacy data.
enum CompetitionRules {
    static let version = "box2d-1"
    static let leaderboardVersion = "v2"
    static let queueFilename = "game-center-pending-\(version).json"
    static let riderPreferenceKey = "rider.\(version)"
    static let weeklyRecordKey = "bestWeekly.\(version)"
    static let endlessRecordKey = "bestEndless.\(version)"

    static func leaderboardID(_ suffix: String) -> String {
        "com.daviddemri.crococross.\(suffix).\(leaderboardVersion)"
    }

    static func isCurrentLeaderboard(_ identifier: String) -> Bool {
        identifier.hasSuffix(".\(leaderboardVersion)")
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
