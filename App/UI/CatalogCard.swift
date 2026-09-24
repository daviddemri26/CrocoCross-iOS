import SwiftUI

struct CatalogCard: View {
    let id: String
    let name: String
    let subtitle: String
    let asset: String
    let availability: CatalogAvailability
    let selected: Bool
    var rider = false
    var recordText: String? = nil
    var leaderboardAction: (() -> Void)? = nil
    var leaderboardEnabled = true
    var leaderboardStatus: String? = nil
    let action: () -> Void

    private var unlocked: Bool { availability.isUnlocked }
    private var ready: Bool { availability.isReadyToUnlock }

    var body: some View {
        VStack(spacing: 0) {
            selectionButton
            if recordText != nil || leaderboardAction != nil {
                recordFooter
            }
        }
        .background(.white.opacity(selected && unlocked ? 0.075 : 0.035),
                    in: RoundedRectangle(cornerRadius: 20))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20)
            .stroke(ready ? .cyan.opacity(0.65) : (selected && unlocked ? CrocoTheme.lime : .white.opacity(0.12)),
                    lineWidth: selected && unlocked ? 2 : 1)
            .allowsHitTesting(false))
    }

    // The optional ranking action is a sibling, so it never selects or unlocks a card.
    private var selectionButton: some View {
        Button {
            guard unlocked || ready else { return }
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    LinearGradient(colors: [CrocoTheme.muted.opacity(0.12), .white.opacity(0.015)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    artwork
                        .allowsHitTesting(false)
                        .saturation(unlocked ? 1 : 0.7)
                        .blur(radius: unlocked ? 0 : 1.5)
                        .opacity(unlocked ? 1 : 0.85)
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 35, weight: .bold))
                            .foregroundStyle(ready ? Color.cyan : CrocoTheme.lime)
                            .frame(width: 70, height: 70)
                            .background(CrocoTheme.ink.opacity(0.9), in: RoundedRectangle(cornerRadius: 23))
                            .overlay(RoundedRectangle(cornerRadius: 23).stroke(.white.opacity(0.13)))
                    }
                }
                .frame(height: 136).clipped().accessibilityHidden(true)
                .overlay(alignment: .topTrailing) {
                    if selected && unlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 23, weight: .bold)).foregroundStyle(CrocoTheme.lime)
                            .background(CrocoTheme.ink, in: Circle()).padding(9)
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text(name).font(.system(size: 15, weight: .bold, design: .rounded))
                        .lineLimit(2).frame(minHeight: 36, alignment: .topLeading)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(unlocked ? (selected ? "SELECTED" : "AVAILABLE") : (ready ? "TAP TO UNLOCK" : "TO UNLOCK"))
                            .font(.system(size: 9, weight: .heavy, design: .monospaced)).tracking(1.2)
                            .foregroundStyle(ready ? .cyan : (unlocked ? CrocoTheme.lime : CrocoTheme.muted))
                        Text(unlocked ? subtitle : availability.requirementText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(CrocoTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        if let progress = availability.progress {
                            ProgressView(value: progress.fraction)
                                .tint(ready ? .cyan : CrocoTheme.lime)
                                .accessibilityHidden(true)
                            Text(progress.text)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.9))
                                .accessibilityIdentifier("unlockProgress-\(id)")
                        }
                    }.frame(maxWidth: .infinity, minHeight: rider ? 72 : 49, alignment: .topLeading)
                }.padding(13).frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(CatalogCardButtonStyle()).foregroundStyle(.white).disabled(!unlocked && !ready)
        .accessibilityIdentifier("select-\(id)")
        .accessibilityLabel(unlocked ? name : "\(name), \(ready ? "Ready to unlock" : "Locked")")
        .accessibilityValue(unlocked ? subtitle : availability.requirementText + (availability.progress.map { ", " + $0.text } ?? ""))
        .accessibilityAddTraits(selected && unlocked ? [.isSelected] : [])
    }

    private var recordFooter: some View {
        VStack(spacing: 0) {
            Rectangle().fill(.white.opacity(0.10)).frame(height: 1).accessibilityHidden(true)
            HStack(spacing: 8) {
                if let recordText {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Best").font(.system(size: 10, weight: .medium)).foregroundStyle(CrocoTheme.muted)
                        Text(recordText).font(.system(size: 16, weight: .bold, design: .rounded))
                            .monospacedDigit().lineLimit(1).minimumScaleFactor(0.6).foregroundStyle(.white)
                    }.accessibilityElement(children: .ignore)
                        .accessibilityLabel("Endless record, \(name)")
                        .accessibilityValue(recordText)
                        .accessibilityIdentifier("worldRecord-\(id)")
                }
                Spacer(minLength: 0)
                if let leaderboardAction {
                    Button(action: leaderboardAction) {
                        Image(systemName: "trophy.fill").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(leaderboardEnabled ? CrocoTheme.lime : CrocoTheme.muted)
                            .frame(width: 44, height: 44)
                            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).disabled(!leaderboardEnabled)
                        .accessibilityLabel("Leaderboard, \(name)")
                        .accessibilityHint(leaderboardStatus ?? "Compare Endless scores in Game Center.")
                        .accessibilityIdentifier("worldLeaderboard-\(id)")
                }
            }.padding(.horizontal, 13).padding(.vertical, 9)
        }
    }

    @ViewBuilder private var artwork: some View {
        if rider {
            RiderArtworkView(riderID: id, animated: selected && unlocked)
        } else if let image = GameAssets.image(named: asset) {
            GeometryReader { geometry in
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height).clipped()
            }
        }
    }
}

/// Keep names and padlocks readable; only the artwork receives the light filter.
private struct CatalogCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.92 : 1)
    }
}
