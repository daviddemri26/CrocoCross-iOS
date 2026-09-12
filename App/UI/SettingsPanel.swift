import SwiftUI

struct SettingsPanel: View {
    @Bindable var session: GameSession
    var body: some View {
        @Bindable var audio = session.audio
        Form {
            Section("Music") {
                Toggle("Play music", isOn: $audio.musicEnabled)
                VStack(alignment: .leading, spacing: 12) {
                    Text(audio.currentTrackTitle).font(.headline)
                    HStack {
                        Button { audio.toggleMusicPlayback() } label: { Label(audio.musicPlaying ? "Pause" : "Play", systemImage: audio.musicPlaying ? "pause.fill" : "play.fill") }
                        Spacer()
                        Button { audio.nextTrack() } label: { Label("Next", systemImage: "forward.end.fill") }
                    }.buttonStyle(.borderless)
                }.padding(.vertical, 6)
                volume("Music volume", value: $audio.musicVolume)
            }
            Section("Sound & feel") {
                volume("Engine", value: $audio.engineVolume)
                volume("Effects", value: $audio.effectsVolume)
                Toggle("Haptic feedback", isOn: $audio.hapticsEnabled)
                if let message = audio.statusMessage { Text(message).font(.footnote).foregroundStyle(.secondary) }
            }
            Section("Your records") {
                LabeledContent("Weekly best", value: session.bestWeekly.formatted())
                LabeledContent("Endless best", value: session.bestEndless.formatted())
                Text("These records are saved on this device. Game Center keeps your submitted leaderboard scores.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Game Center") {
                Text(session.gameCenter.isAuthenticated ? session.gameCenter.playerName : "Play locally or connect to compete.")
                if let status = session.gameCenter.statusMessage { Text(status).font(.footnote).foregroundStyle(.secondary) }
                Button(session.gameCenter.isAuthenticated ? "Open leaderboards" : "Connect Game Center") {
                    if session.gameCenter.isAuthenticated { session.showLeaderboards() }
                    else { session.gameCenter.authenticate() }
                }
            }
            Section("About") {
                Text("CrocoCross").font(.headline)
                Text("An independent native motorcycle game. No ads. No purchases. Just one more ride.").font(.footnote).foregroundStyle(.secondary)
                NavigationLink("Privacy") { PrivacyView() }
                NavigationLink("Credits") { CreditsView() }
            }
        }.scrollContentBackground(.hidden).background(CrocoTheme.ink)
    }
    private func volume(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            HStack { Text(label); Spacer(); Text("\(Int(value.wrappedValue * 100))%").foregroundStyle(.secondary).monospacedDigit() }
            Slider(value: value, in: 0...1).accessibilityLabel(label)
        }.padding(.vertical, 3)
    }
}

private struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your ride stays yours.").font(.title.bold())
                Text("CrocoCross saves settings, local records, unfinished rides and pending scores on your device. It contains no advertising or third-party analytics SDK.")
                Text("If you connect to Game Center, the app uses your Game Center player identity to send scores and show Apple’s leaderboards. Game Center is provided by Apple and is governed by Apple’s privacy policies.")
                Text("Playing without Game Center keeps your results local. Removing the app removes its local data; it does not delete data held separately by Game Center.")
                Text("No camera, microphone, location or contacts access is requested.")
                Link("Apple Game Center privacy", destination: URL(string: "https://www.apple.com/legal/privacy/data/en/game-center/")!)
            }.padding(24)
        }.navigationTitle("Privacy")
    }
}

private struct CreditsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("CrocoCross").font(.largeTitle.bold())
                Text("Original game and creative direction: David Demri.")
                Text("Music: Quarter in the Slot, Crossing the Black River, Miles Past the Skyline. Tracks supplied for CrocoCross.")
                Text("Explosion sound: Fuel Explosion by Mixkit, used under the Mixkit Sound Effects Free License.")
                Link("Mixkit license", destination: URL(string: "https://mixkit.co/license/#sfxFree")!)
                Text("Built with Swift, SpriteKit, SwiftUI, AVFAudio and GameKit.").font(.footnote).foregroundStyle(.secondary)
            }.padding(24)
        }.navigationTitle("Credits")
    }
}
