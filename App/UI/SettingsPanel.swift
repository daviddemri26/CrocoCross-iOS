import CrocoCrossCore
import SwiftUI

struct SettingsPanel: View {
    @Bindable var session: GameSession
    let onClose: () -> Void
    @State private var selectedTab: SettingsTab = .audio

    private enum SettingsTab: String, CaseIterable, Identifiable {
        case audio, general, about
        var id: String { rawValue }
        var title: String {
            switch self {
            case .general: "General"
            case .audio: "Audio"
            case .about: "About"
            }
        }
        var symbol: String {
            switch self {
            case .general: "slider.horizontal.3"
            case .audio: "speaker.wave.2.fill"
            case .about: "info.circle.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .general: generalPanel
                case .audio: audioPanel
                case .about: aboutPanel
                }
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            bottomTabs
        }
        .background(CrocoTheme.ink)
    }

    private var generalPanel: some View {
        @Bindable var audio = session.audio
        return Form {
            Section("Controls") {
                Toggle("Haptic feedback", isOn: $audio.hapticsEnabled)
            }
        }
    }

    private var audioPanel: some View {
        @Bindable var audio = session.audio
        return Form {
            Section("Volume") {
                volume("Music volume", value: $audio.musicVolume)
                volume("Engine", value: $audio.engineVolume)
                volume("Effects", value: $audio.effectsVolume)
                SoundToggleButton(audio: audio, identifier: "settingsSoundToggle")
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
            }
            Section("Music") {
                Toggle("Play music", isOn: $audio.musicEnabled)
                Picker("Playback", selection: $audio.musicPlaybackMode) {
                    ForEach(MusicPlaybackMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("music.playbackMode")
                if let message = audio.statusMessage {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                }
            }
            Section("Tracks") {
                ForEach(Array(audio.tracks.enumerated()), id: \.element.id) { index, track in
                    let selected = audio.selectedTrackID == track.id
                    Button {
                        audio.selectTrack(id: track.id)
                    } label: {
                        HStack(spacing: 12) {
                            Text(String(format: "%02d", index + 1))
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(selected ? CrocoTheme.lime : .secondary)
                            Text(track.title)
                                .fontWeight(selected ? .semibold : .regular)
                                .foregroundStyle(.primary)
                            Spacer(minLength: 8)
                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected ? CrocoTheme.lime : .secondary)
                                .accessibilityHidden(true)
                        }.padding(.vertical, 5)
                    }
                    .listRowBackground(
                        selected ? CrocoTheme.lime.opacity(0.1) : Color(uiColor: .secondarySystemGroupedBackground)
                    )
                    .accessibilityLabel(track.title)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("music.track.\(track.id)")
                }
            }

        }
    }

    private var aboutPanel: some View {
        Form {
            Section("About") {
                Text("CrocoCross").font(.headline)
                LabeledContent(
                    "Version",
                    value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
                LabeledContent(
                    "Build", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—")
                LabeledContent("Engine", value: PhysicsConfiguration.engineVersion)
                LabeledContent("Physics", value: "Box2D \(GameSimulation.backendVersion)")
            }
            Section("Information") {
                DisclosureGroup("Privacy") { PrivacyView() }
                DisclosureGroup("Credits") { CreditsView() }
            }
        }
    }

    private var bottomTabs: some View {
        HStack(spacing: 6) {
            ForEach(SettingsTab.allCases) { tab in
                let selected = selectedTab == tab
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbol).font(.system(size: 19, weight: .semibold))
                        Text(tab.title).font(.system(size: 12, weight: .semibold))
                            .lineLimit(1).minimumScaleFactor(0.85)
                    }
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(selected ? CrocoTheme.lime : Color.secondary)
                    .background(
                        selected ? CrocoTheme.lime.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 13)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier("settings.tab.\(tab.rawValue)")
            }
            Rectangle().fill(.white.opacity(0.16)).frame(width: 1, height: 28).padding(.horizontal, 5)
            PanelCloseButton(action: onClose)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(CrocoTheme.ink)
        .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.12)).frame(height: 1) }
    }

    private func volume(_ label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .foregroundStyle(.secondary).monospacedDigit()
            }
            Slider(value: value, in: 0...1).accessibilityLabel(label)
        }.padding(.vertical, 3)
    }
}

private struct PrivacyView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(
                "CrocoCross saves settings, local records and pending scores on your device. It contains no advertising or third-party analytics SDK."
            )
            Text(
                "If you connect to Game Center, the app uses your Game Center player identity to send scores and show Apple’s leaderboards. Game Center is provided by Apple and is governed by Apple’s privacy policies."
            )
            Text(
                "Playing without Game Center keeps your results local. Removing the app removes its local data; it does not delete data held separately by Game Center."
            )
            Text("No camera, microphone, location or contacts access is requested.")
            Link("CrocoCross privacy policy", destination: URL(string: "https://daviddemri26.github.io/CrocoCross-iOS/privacy.html")!)
            Link("Contact support", destination: URL(string: "https://daviddemri26.github.io/CrocoCross-iOS/support.html")!)
            Link(
                "Apple Game Center privacy",
                destination: URL(string: "https://www.apple.com/legal/privacy/data/en/game-center/")!)
        }.padding(.vertical, 12)
    }
}

private struct CreditsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Original game and creative direction: David Demri.")
            Text(
                "Music: Quarter in the Slot, Crossing the Black River, Miles Past the Skyline. Tracks supplied for CrocoCross."
            )
            Text("Explosion sound: Fuel Explosion by Mixkit, used under the Mixkit Sound Effects Free License.")
            Link("Mixkit license", destination: URL(string: "https://mixkit.co/license/#sfxFree")!)
            DisclosureGroup("Box2D license") {
                Text(box2DLicense).font(.footnote).padding(.vertical, 8)
            }
            DisclosureGroup("Rider icon license") {
                Text(LegacyRiderIcon.license).font(.footnote).padding(.vertical, 8)
            }
            Text("Built with Swift, SpriteKit, SwiftUI, AVFAudio and GameKit.").font(.footnote).foregroundStyle(
                .secondary)
        }.padding(.vertical, 12)
    }

    private var box2DLicense: String {
        guard let url = Bundle.main.url(forResource: "box2d-license", withExtension: "txt"),
              let license = try? String(contentsOf: url, encoding: .utf8) else {
            return "Box2D \(GameSimulation.backendVersion) by Erin Catto. MIT License."
        }
        return license
    }
}
