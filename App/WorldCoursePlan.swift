/// Catalog preparation only. Planned worlds do not yet configure the simulation or submit scores.
struct WorldCoursePlan: Equatable {
    enum Status { case ready, planned }

    let worldID: String
    let revision: Int
    let status: Status

    var identifier: String { "\(worldID).route-\(revision)" }
    var roadArtworkID: String { worldID }

    /// Future records must include both the rules and the world/route revision.
    /// This scope is staged metadata; existing Canyon records keep their current keys for now.
    var scoreScope: String { "\(CompetitionRules.version).\(identifier)" }
}
