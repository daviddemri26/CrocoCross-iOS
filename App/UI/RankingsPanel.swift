import SwiftUI

struct RankingsPanel: View {
    @Bindable var session: GameSession
    let showEndlessWorlds: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Label("Weekly", systemImage: "flag.checkered")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .accessibilityIdentifier("rankings.weeklyHeading")
                TimelineView(.everyMinute) { timeline in
                    let challenge = session.currentWeeklyChallenge(now: timeline.date)
                    let local = session.weeklyRecords.record(for: challenge.identifier)
                    let sameWeek = session.gameCenter.weeklyRecordsChallengeIdentifier == challenge.identifier
                    VStack(spacing: 14) {
                        record(time: false, local: local.score,
                               remote: sameWeek ? session.gameCenter.weeklyScoreRecord : nil)
                        record(time: true, local: local.timeCentiseconds,
                               remote: sameWeek ? session.gameCenter.weeklyTimeRecord : nil)
                    }.accessibilityElement(children: .contain)
                        .accessibilityIdentifier("rankings.localRecords")
                }
                Button {
                    if session.gameCenter.isAuthenticated { session.showLeaderboards() }
                    else { session.gameCenter.authenticate() }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                        Text(session.gameCenter.isAuthenticated ? "Game Center" : "Connect Game Center")
                            .font(.subheadline.bold())
                        Spacer()
                        if session.gameCenter.weeklyRecordsLoading { ProgressView().tint(CrocoTheme.lime) }
                        else { Image(systemName: "arrow.up.right").font(.caption.bold()) }
                    }.padding(16).frame(minHeight: 48)
                        .background(CrocoTheme.lime.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
                }.buttonStyle(.plain).foregroundStyle(CrocoTheme.lime)
                    .accessibilityIdentifier(session.gameCenter.isAuthenticated ? "rankings.all" : "rankings.connect")
                Divider().overlay(.white.opacity(0.12))
                Button(action: showEndlessWorlds) {
                    HStack(spacing: 12) {
                        Image(systemName: "infinity").foregroundStyle(CrocoTheme.orange)
                        Text("Endless leaderboards").font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(CrocoTheme.muted)
                    }.padding(.vertical, 16).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityIdentifier("rankings.endlessWorlds")
            }.padding(22).frame(maxWidth: 620).frame(maxWidth: .infinity)
        }.background(CrocoTheme.ink).foregroundStyle(.white)
            .accessibilityIdentifier("rankings.list")
            .task { await session.gameCenter.refresh() }
    }

    private func record(time: Bool, local: Int?, remote: WeeklyPlayerRecord?) -> some View {
        let best: Int? = switch (local, remote?.score) {
        case let (local?, online?): time ? min(local, online) : max(local, online)
        case let (local?, nil): local
        case let (nil, online?): online
        case (nil, nil): nil
        }
        let available = session.gameCenter.isAuthenticated && session.gameCenter.isWeeklyLeaderboardConfirmed(time: time)
        return Button { session.showWeeklyLeaderboard(time: time) } label: {
            HStack(spacing: 16) {
                Image(systemName: time ? "stopwatch" : "trophy.fill")
                    .font(.system(size: 27, weight: .semibold)).foregroundStyle(time ? CrocoTheme.orange : CrocoTheme.lime)
                    .frame(width: 40)
                VStack(alignment: .leading, spacing: 8) {
                    Text(time ? "BEST TIME" : "BEST SCORE")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced)).tracking(1.3)
                        .foregroundStyle(CrocoTheme.muted)
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text(best.map { formatted($0, time: time) } ?? "—")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
                        if !time { Text("pts").font(.caption.bold()).foregroundStyle(CrocoTheme.muted) }
                    }
                    if let remote {
                        Text(remote.score == best
                             ? "#\(remote.rank.formatted()) worldwide"
                             : "Game Center · \(formatted(remote.score, time: time))\(time ? "" : " pts") · #\(remote.rank.formatted())")
                            .font(.caption).foregroundStyle(CrocoTheme.lime)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                if available { Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(CrocoTheme.muted) }
            }.padding(20).frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(ReadableRecordButtonStyle()).disabled(!available)
            .accessibilityIdentifier(time ? "rankings.weeklyTime" : "rankings.weeklyScore")
            .accessibilityLabel(time ? "Weekly best time" : "Weekly best score")
            .accessibilityValue((best.map { time ? formatted($0, time: true) : "\($0) points" } ?? "No record")
                + (remote.map { ", Game Center \(formatted($0.score, time: time)), number \($0.rank) worldwide" } ?? ""))
    }

    private func formatted(_ value: Int, time: Bool) -> String {
        guard time else { return value.formatted() }
        return String(format: "%d:%02d.%02d", value / 6_000, (value / 100) % 60, value % 100)
    }
}

// Offline personal records remain readable; only their online navigation is disabled.
private struct ReadableRecordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.85 : 1)
    }
}
