import Foundation
import CrocoCrossCore

extension AchievementProgression {
    static func forCurrentLaunch() -> AchievementProgression {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ui-testing") {
            func argument(_ name: String) -> String? {
                guard let index = arguments.firstIndex(of: name), arguments.indices.contains(index + 1) else { return nil }
                return arguments[index + 1]
            }
            let id = argument("-achievement-test-id").flatMap(UUID.init(uuidString:)) ?? UUID()
            let root = FileManager.default.temporaryDirectory.appendingPathComponent("AchievementProgressionUITests", isDirectory: true)
                .appendingPathComponent(id.uuidString, isDirectory: true)
            return AchievementProgression(rootURL: root, remoteReportingEnabled: false)
        }
        #endif
        return AchievementProgression(rootURL: LocalStore().rootURL)
    }
}
