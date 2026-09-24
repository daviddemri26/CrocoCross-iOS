import CrocoCrossCore

/// A course is frozen at run start, independently of the home-screen selection.
struct WorldCoursePlan: Equatable {
    enum Status { case ready, planned }

    let worldID: String
    let revision: Int
    let status: Status

    var identifier: String { "\(worldID).route-\(revision)" }
    var roadArtworkID: String { worldID }

    var scoreScope: String { "\(CompetitionRules.version).\(identifier)" }
    var terrainStyle: PhysicsConfiguration.TerrainStyle { worldID == "japan" ? .japanMountains : .hills }
    var competitionIdentity: CompetitionRules.CourseIdentity { .init(worldID: worldID, revision: revision) }
    var endlessLeaderboardID: String? {
        status == .ready ? CompetitionRules.endlessLeaderboardID(for: competitionIdentity) : nil
    }
    var supportsLeaderboards: Bool { endlessLeaderboardID != nil }
    var endlessRecordKey: String {
        CompetitionRules.endlessRecordKey(for: competitionIdentity)
    }

    static let weekly = WorldCoursePlan(worldID: "canyon", revision: 1, status: .ready)
}
