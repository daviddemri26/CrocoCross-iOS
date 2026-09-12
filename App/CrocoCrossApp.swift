import SwiftUI

@main
struct CrocoCrossApp: App {
    @State private var session = GameSession()
    var body: some Scene {
        WindowGroup { GameRootView(session: session).preferredColorScheme(.dark) }
    }
}
