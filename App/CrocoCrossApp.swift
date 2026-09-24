import SwiftUI

@main
struct CrocoCrossApp: App {
    #if !DEBUG
    @State private var session = GameSession()
    #endif
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-game-center-audit") {
                GameCenterAuditView().preferredColorScheme(.dark)
            } else {
                GameApplicationRoot().preferredColorScheme(.dark)
            }
            #else
            GameRootView(session: session).preferredColorScheme(.dark)
            #endif
        }
    }
}

#if DEBUG
/// Kept behind the launch branch so the read-only audit cannot initialize a gameplay session or its outboxes.
private struct GameApplicationRoot: View {
    @State private var session = GameSession()
    var body: some View { GameRootView(session: session) }
}
#endif
