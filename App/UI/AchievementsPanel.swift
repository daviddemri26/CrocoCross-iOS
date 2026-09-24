import CrocoCrossCore
import SwiftUI

struct AchievementsPanel: View {
    @Bindable var session: GameSession
    private var catalog: [AchievementDefinition] { AchievementCatalog.standard }
    private var completed: [AchievementDefinition] {
        catalog.filter { session.achievements.state.progress(for: $0).isCompleted }
    }
    private var categories: [String] {
        catalog.reduce(into: []) { titles, item in
            if !titles.contains(item.category.title) { titles.append(item.category.title) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 14) {
                    Image(systemName: "medal.fill").font(.system(size: 36)).foregroundStyle(CrocoTheme.lime)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Little wins. Big rides.").font(.title2.bold())
                        Text("\(completed.count) / \(catalog.count) unlocked · \(completed.reduce(0) { $0 + $1.points }) points")
                            .font(.subheadline).foregroundStyle(CrocoTheme.muted)
                            .accessibilityIdentifier("achievements.summary")
                    }
                }
                Text("Safe landings, longer rides and new discoveries. Progress is saved on this device, even offline.")
                    .font(.subheadline).foregroundStyle(CrocoTheme.muted)
                if let error = session.achievements.saveError {
                    Text(error).font(.footnote).foregroundStyle(CrocoTheme.orange)
                }
                Button {
                    if session.gameCenter.isAuthenticated { session.showAchievements() }
                    else { session.gameCenter.authenticate() }
                } label: {
                    Label(session.gameCenter.isAuthenticated ? "Open Game Center" : "Connect with Game Center",
                          systemImage: "person.crop.circle.badge.checkmark")
                        .font(.subheadline.bold()).frame(maxWidth: .infinity).padding(16)
                        .background(CrocoTheme.lime.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
                }.accessibilityIdentifier("achievements.gameCenter")
                ForEach(categories, id: \.self) { category in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(category.uppercased())
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .tracking(1.5).foregroundStyle(CrocoTheme.muted)
                        ForEach(catalog.filter { $0.category.title == category }, id: \.id) { definition in
                            achievement(definition)
                        }
                    }
                }
            }.padding(22).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(CrocoTheme.ink).foregroundStyle(.white)
            .accessibilityIdentifier("achievements.list")
    }

    private func achievement(_ definition: AchievementDefinition) -> some View {
        let progress = session.achievements.state.progress(for: definition)
        let unlocked = progress.isCompleted
        return HStack(alignment: .top, spacing: 14) {
            Image(systemName: UIImage(systemName: definition.symbolName) == nil ? "medal.fill" : definition.symbolName)
                .font(.system(size: 24, weight: .semibold)).frame(width: 48, height: 48)
                .foregroundStyle(unlocked ? CrocoTheme.lime : CrocoTheme.muted)
                .background((unlocked ? CrocoTheme.lime : .white).opacity(0.08), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(definition.title).font(.headline)
                    Spacer(minLength: 4)
                    if unlocked {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(CrocoTheme.lime)
                    }
                    Text("\(definition.points) pt").font(.caption.bold()).foregroundStyle(CrocoTheme.muted)
                }
                Text(definition.description).font(.subheadline).foregroundStyle(CrocoTheme.muted)
                if !unlocked {
                    ProgressView(value: progress.percentComplete, total: 100).tint(CrocoTheme.lime)
                    Text("\(Int(progress.current).formatted()) / \(Int(progress.target).formatted())")
                        .font(.caption.monospacedDigit()).foregroundStyle(CrocoTheme.muted)
                } else {
                    Text("Unlocked").font(.caption.bold()).foregroundStyle(CrocoTheme.lime)
                }
            }
        }.padding(16)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("achievement.\(definition.id)")
            .accessibilityValue(unlocked ? "Unlocked" : "\(Int(progress.percentComplete)) percent")
    }
}

struct AchievementToast: View {
    let notice: GameSession.AchievementNotice
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notice.unlocked.last?.symbolName ?? "medal.fill")
                .font(.system(size: 26)).foregroundStyle(CrocoTheme.lime)
            VStack(alignment: .leading, spacing: 3) {
                Text(notice.unlocked.count == 1 ? "ACHIEVEMENT UNLOCKED" : "\(notice.unlocked.count) ACHIEVEMENTS UNLOCKED")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundStyle(CrocoTheme.lime)
                Text(notice.unlocked.map(\.title).joined(separator: " · "))
                    .font(.subheadline.bold()).lineLimit(2)
            }
        }.padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: 360, alignment: .leading)
            .background(CrocoTheme.ink.opacity(0.96), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(CrocoTheme.lime.opacity(0.5)))
            .foregroundStyle(.white).shadow(radius: 8)
            .accessibilityElement(children: .combine).accessibilityIdentifier("achievementUnlocked")
            .allowsHitTesting(false)
    }
}
