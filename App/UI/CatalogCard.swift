import SwiftUI

struct CatalogCard: View {
    let id: String
    let name: String
    let subtitle: String
    let asset: String
    let availability: CatalogAvailability
    let selected: Bool
    var rider = false
    let action: () -> Void

    private var unlocked: Bool { availability.isUnlocked }

    var body: some View {
        Button {
            guard unlocked else { return }
            action()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    LinearGradient(colors: [CrocoTheme.muted.opacity(0.12), .white.opacity(0.015)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                    artwork
                        .saturation(unlocked ? 1 : 0.7)
                        .blur(radius: unlocked ? 0 : 1.5)
                        .opacity(unlocked ? 1 : 0.85)
                    if !unlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 35, weight: .bold))
                            .foregroundStyle(CrocoTheme.lime)
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
                        Text(unlocked ? (selected ? "SELECTED" : "AVAILABLE") : "TO UNLOCK")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced)).tracking(1.2)
                            .foregroundStyle(unlocked ? CrocoTheme.lime : CrocoTheme.muted)
                        Text(unlocked ? subtitle : availability.requirementText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(CrocoTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }.frame(maxWidth: .infinity, minHeight: 49, alignment: .topLeading)
                }.padding(13).frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(.white.opacity(selected && unlocked ? 0.075 : 0.035),
                        in: RoundedRectangle(cornerRadius: 20))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20)
                .stroke(selected && unlocked ? CrocoTheme.lime : .white.opacity(0.12),
                        lineWidth: selected && unlocked ? 2 : 1))
        }
        .buttonStyle(CatalogCardButtonStyle()).foregroundStyle(.white).disabled(!unlocked)
        .accessibilityIdentifier("select-\(id)")
        .accessibilityLabel(unlocked ? name : "\(name), Locked")
        .accessibilityValue(unlocked ? subtitle : availability.requirementText)
        .accessibilityAddTraits(selected && unlocked ? [.isSelected] : [])
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
