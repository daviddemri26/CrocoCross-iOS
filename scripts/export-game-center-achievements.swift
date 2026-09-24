import Foundation

/// Compile with the production AchievementCatalog.swift. This writes local
/// review material only; it has no GameKit or App Store Connect dependencies.
@main struct ExportGameCenterAchievements {
    struct Row: Codable {
        let id: String
        let gameCenterID: String
        let title: String
        let description: String
        let earnedDescription: String
        let points: Int
        let hidden: Bool
        let repeatable: Bool
        let locale: String
        let category: String
        let target: Double
        let proposedImageFilename: String
    }
    struct Manifest: Codable {
        let configurationStatus: String
        let achievementCount: Int
        let totalPoints: Int
        let achievements: [Row]
    }
    static func main() throws {
        let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "docs", isDirectory: true)
        let rows = AchievementCatalog.standard.map { definition in
            var earned = definition.description
            for (action, completion) in [("Safely land ", "You safely landed "), ("Ride ", "You rode "),
                                         ("Finish ", "You finished "), ("Unlock ", "You unlocked ")] {
                if earned.hasPrefix(action) { earned = completion + earned.dropFirst(action.count); break }
            }
            return Row(id: definition.id, gameCenterID: definition.gameCenterID,
                title: definition.title, description: definition.description, earnedDescription: earned,
                points: definition.points, hidden: false, repeatable: false, locale: "en-US",
                category: definition.category.rawValue, target: definition.target,
                proposedImageFilename: definition.id.replacingOccurrences(of: ".", with: "-") + ".png")
        }
        let points = rows.reduce(0) { $0 + $1.points }
        precondition(rows.count <= 100 && points <= 1000)
        precondition(Set(rows.map(\.gameCenterID)).count == rows.count)
        precondition(rows.allSatisfy { $0.gameCenterID.utf8.count <= 100 && (0...100).contains($0.points) })
        let manifest = Manifest(configurationStatus: "Local proposal only. No remote configuration or submission performed. Achievement artwork still required.",
            achievementCount: rows.count, totalPoints: points, achievements: rows)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(manifest).write(to: output.appendingPathComponent("achievements-game-center.json"), options: .atomic)
        func csv(_ value: String) -> String { "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        var lines = ["id,gameCenterID,title,description,earnedDescription,points,hidden,repeatable,locale,category,target,proposedImageFilename"]
        for row in rows {
            lines.append([row.id, row.gameCenterID, row.title, row.description, row.earnedDescription,
                String(row.points), String(row.hidden), String(row.repeatable), row.locale, row.category,
                String(row.target), row.proposedImageFilename].map(csv).joined(separator: ","))
        }
        try (lines.joined(separator: "\n") + "\n").write(to: output.appendingPathComponent("achievements-game-center.csv"), atomically: true, encoding: .utf8)
        print("Exported \(rows.count) achievements / \(points) points from the production catalog; no remote action.")
    }
}
