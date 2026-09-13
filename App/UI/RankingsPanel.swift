import SwiftUI

struct RankingsPanel: View {
    @Bindable var session: GameSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 12) {
                    Image(systemName: "trophy.fill").font(.system(size: 29, weight: .bold))
                        .foregroundStyle(CrocoTheme.lime)
                    Text("Your best").font(.system(size: 27, weight: .black, design: .rounded))
                }
                HStack(spacing: 12) {
                    record("WEEKLY", score: session.bestWeekly, icon: "flag.checkered", color: CrocoTheme.lime)
                    record("ENDLESS", score: session.bestEndless, icon: "infinity", color: CrocoTheme.orange)
                }.accessibilityIdentifier("rankings.localRecords")
                Text("Personal bests saved on this device.").font(.footnote).foregroundStyle(CrocoTheme.muted)
                VStack(alignment: .leading, spacing: 17) {
                    Label("Leaderboards", systemImage: "globe").font(.title3.bold())
                    Text("Weekly score · Weekly time · Endless score")
                        .font(.subheadline).foregroundStyle(CrocoTheme.muted)
                    if session.gameCenter.isAuthenticated {
                        Label(session.gameCenter.playerName, systemImage: "person.crop.circle.fill")
                            .font(.subheadline.bold())
                        Button {
                            session.showLeaderboards()
                        } label: {
                            Label("View rankings", systemImage: "trophy.fill")
                                .frame(maxWidth: .infinity).padding(16)
                        }.buttonStyle(RankingsButtonStyle()).accessibilityIdentifier("rankings.online")
                    } else {
                        Text("Connect with Game Center to compare your scores with other riders.")
                            .font(.subheadline).foregroundStyle(CrocoTheme.muted)
                        Button {
                            session.gameCenter.authenticate()
                        } label: {
                            Label("Connect", systemImage: "person.crop.circle.badge.checkmark")
                                .frame(maxWidth: .infinity).padding(16)
                        }.buttonStyle(RankingsButtonStyle()).accessibilityIdentifier("rankings.connect")
                    }
                    if let message = session.gameCenter.statusMessage {
                        Text(message).font(.footnote).foregroundStyle(CrocoTheme.muted)
                    }
                }.padding(20).background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 22))
            }.padding(22).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(CrocoTheme.ink).foregroundStyle(.white)

    }

    private func record(_ mode: String, score: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 17) {
            Image(systemName: icon).font(.system(size: 27, weight: .bold)).frame(height: 32).foregroundStyle(color)
            Text(mode).font(.system(size: 11, weight: .heavy, design: .monospaced)).tracking(1)
            Text(score.formatted()).font(.system(size: 32, weight: .black, design: .rounded))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
            Text("POINTS").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(CrocoTheme.muted)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18)
            .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(color.opacity(0.3), lineWidth: 1))
            .accessibilityElement(children: .ignore).accessibilityLabel("\(mode), \(score.formatted()) points")
    }
}

private struct RankingsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline.bold()).foregroundStyle(CrocoTheme.ink)
            .background(
                CrocoTheme.lime.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 15))
    }
}
