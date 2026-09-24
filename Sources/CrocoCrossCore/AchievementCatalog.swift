import Foundation

public enum AchievementCategory: String, Codable, CaseIterable, Sendable {
    case stunts, distance, weekly, collection
    public var title: String { rawValue.capitalized }
}

public enum AchievementRequirement: Codable, Equatable, Sendable {
    case firstBackflip, firstFrontflip, totalRotations, endlessMetres, weeklyFinishes
    case rotationsInJump(minimum: Int)
    case rider(String), world(String)
}

public struct AchievementDefinition: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let description: String
    public let symbolName: String
    public let category: AchievementCategory
    public let target: Double
    public let points: Int
    public let requirement: AchievementRequirement
    public var gameCenterID: String { "com.daviddemri.crococross.achievement." + id }

    public init(id: String, title: String, description: String, symbolName: String,
                category: AchievementCategory, target: Double, points: Int, requirement: AchievementRequirement) {
        self.id = id; self.title = title; self.description = description; self.symbolName = symbolName
        self.category = category; self.target = target; self.points = points; self.requirement = requirement
    }
}

public enum AchievementCatalog {
    /// Stable achievement identifiers deliberately do not contain an engine or leaderboard revision.
    public static let standard: [AchievementDefinition] = [
        .init(id: "stunt.backflip.first", title: "Back in Business", description: "Safely land your first backflip.", symbolName: "arrow.uturn.backward", category: .stunts, target: 1, points: 10, requirement: .firstBackflip),
        .init(id: "stunt.frontflip.first", title: "Forward Thinking", description: "Safely land your first frontflip.", symbolName: "arrow.uturn.forward", category: .stunts, target: 1, points: 10, requirement: .firstFrontflip),
        .init(id: "stunt.double.landed", title: "Double Trouble", description: "Safely land two rotations in one jump.", symbolName: "2.circle.fill", category: .stunts, target: 1, points: 20, requirement: .rotationsInJump(minimum: 2)),
        .init(id: "stunt.triple.landed", title: "Triple Threat", description: "Safely land three rotations in one jump.", symbolName: "3.circle.fill", category: .stunts, target: 1, points: 40, requirement: .rotationsInJump(minimum: 3)),
        .init(id: "stunt.total.10", title: "Spin Starter", description: "Safely land 10 rotations across your rides.", symbolName: "arrow.trianglehead.2.clockwise.rotate.90", category: .stunts, target: 10, points: 15, requirement: .totalRotations),
        .init(id: "stunt.total.50", title: "Frequent Flyer", description: "Safely land 50 rotations across your rides.", symbolName: "airplane", category: .stunts, target: 50, points: 30, requirement: .totalRotations),
        .init(id: "stunt.total.100", title: "Spin Legend", description: "Safely land 100 rotations across your rides.", symbolName: "star.circle.fill", category: .stunts, target: 100, points: 60, requirement: .totalRotations),
        .init(id: "stunt.total.250", title: "Spin Doctor", description: "Safely land 250 rotations across your rides.", symbolName: "arrow.trianglehead.2.clockwise.rotate.90", category: .stunts, target: 250, points: 20, requirement: .totalRotations),
        .init(id: "stunt.total.500", title: "Gyro Hero", description: "Safely land 500 rotations across your rides.", symbolName: "sparkles", category: .stunts, target: 500, points: 25, requirement: .totalRotations),
        .init(id: "stunt.total.1000", title: "Rotation Royalty", description: "Safely land 1,000 rotations across your rides.", symbolName: "crown.fill", category: .stunts, target: 1_000, points: 30, requirement: .totalRotations),
        .init(id: "stunt.total.2500", title: "Spin Cyclone", description: "Safely land 2,500 rotations across your rides.", symbolName: "tornado", category: .stunts, target: 2_500, points: 40, requirement: .totalRotations),
        .init(id: "stunt.total.5000", title: "Orbit Breaker", description: "Safely land 5,000 rotations across your rides.", symbolName: "globe", category: .stunts, target: 5_000, points: 50, requirement: .totalRotations),
        .init(id: "stunt.total.10000", title: "Spin Immortal", description: "Safely land 10,000 rotations across your rides.", symbolName: "infinity", category: .stunts, target: 10_000, points: 70, requirement: .totalRotations),
    ] + distanceMilestones + [
        .init(id: "weekly.finish.1", title: "Checkered Flag", description: "Finish your first Weekly course.", symbolName: "flag.checkered", category: .weekly, target: 1, points: 20, requirement: .weeklyFinishes),
        .init(id: "weekly.finish.5", title: "Regular Finisher", description: "Finish five Weekly runs.", symbolName: "flag.checkered.2.crossed", category: .weekly, target: 5, points: 40, requirement: .weeklyFinishes),
        .init(id: "weekly.finish.10", title: "Weekly Legend", description: "Finish ten Weekly runs.", symbolName: "trophy.fill", category: .weekly, target: 10, points: 75, requirement: .weeklyFinishes),
        riderUnlock(catalogID: "shiba", name: "Kenji", title: "Good Dog, Great Ride"),
        worldUnlock(catalogID: "japan", name: "Japan Mountains", title: "Mountain Passport")
    ]

    private static let distanceMilestones: [AchievementDefinition] =
        (Array(stride(from: 1_000, through: 15_000, by: 1_000)) + Array(stride(from: 20_000, through: 50_000, by: 5_000))).map { metres in
            let kilometres = metres / 1_000
            return .init(id: "endless.distance.\(metres)", title: "\(kilometres) km Club",
                         description: "Ride \(kilometres) km in one Endless run.", symbolName: "road.lanes",
                         category: .distance, target: Double(metres), points: metres <= 15_000 ? 10 : kilometres,
                         requirement: .endlessMetres)
        }

    /// Future catalog additions opt in explicitly; starters and unavailable entries are never auto-listed.
    public static func riderUnlock(catalogID: String, name: String, title: String? = nil, points: Int = 25) -> AchievementDefinition {
        .init(id: "unlock.rider." + catalogID, title: title ?? "Ride with " + name,
              description: "Unlock " + name + ".", symbolName: "person.crop.circle.badge.checkmark",
              category: .collection, target: 1, points: points, requirement: .rider(catalogID))
    }
    public static func worldUnlock(catalogID: String, name: String, title: String? = nil, points: Int = 25) -> AchievementDefinition {
        .init(id: "unlock.world." + catalogID, title: title ?? "Discover " + name,
              description: "Unlock " + name + ".", symbolName: "mountain.2.fill",
              category: .collection, target: 1, points: points, requirement: .world(catalogID))
    }
}
