import SwiftUI

/// Equal-sized ride modes. All motion is decorative and stops with Reduce Motion.
struct LaunchTile: View {
    let weekly: Bool
    let reducedMotion: Bool
    let action: () -> Void
    private var color: Color { weekly ? CrocoTheme.lime : CrocoTheme.orange }

    var body: some View {
        Button(action: action) {
            GeometryReader { geometry in
                let side = geometry.size.width
                TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reducedMotion)) { timeline in
                    let time = reducedMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                    let sway = sin(time * 1.7 + (weekly ? 0 : .pi))
                    ZStack(alignment: .topLeading) {
                        LinearGradient(
                            colors: [
                                color, color,
                                weekly
                                    ? Color(red: 0.37, green: 0.77, blue: 0.20)
                                    : Color(red: 0.9, green: 0.29, blue: 0.16),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        Canvas { context, size in
                            // Rolling trail and moving road markings echo the actual game.
                            let shift = reducedMotion ? 0 : (time * 13).truncatingRemainder(dividingBy: 36)
                            for offset in stride(from: -size.width, through: size.width * 2, by: 36.0) {
                                var line = Path()
                                line.move(to: CGPoint(x: offset - shift, y: size.height * 0.67))
                                line.addLine(to: CGPoint(x: offset - shift - 40, y: size.height))
                                context.stroke(line, with: .color(CrocoTheme.ink.opacity(0.06)), lineWidth: 15)
                            }
                            var trail = Path()
                            trail.move(to: CGPoint(x: -10, y: size.height * 0.63))
                            trail.addCurve(
                                to: CGPoint(x: size.width + 12, y: size.height * 0.56),
                                control1: CGPoint(x: size.width * 0.38, y: size.height * (0.83 + sway * 0.015)),
                                control2: CGPoint(x: size.width * 0.63, y: size.height * 0.35)
                            )
                            context.stroke(
                                trail, with: .color(.white.opacity(0.3)),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        }
                        Image(systemName: weekly ? "flag.checkered" : "infinity")
                            .font(.system(size: side * 0.42, weight: .black))
                            .rotationEffect(.degrees(weekly ? -12 + sway * 4 : -14 + sway * 3))
                            .offset(x: side * 0.37, y: side * (0.14 + sway * 0.015))
                            .foregroundStyle(CrocoTheme.ink.opacity(0.86))
                            .shadow(color: .white.opacity(0.22), radius: 0, x: 2, y: 3)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 0) {
                            if weekly {
                                Text("4,000 m")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .padding(.horizontal, 9).padding(.vertical, 6)
                                    .background(CrocoTheme.ink.opacity(0.09), in: Capsule())
                            }
                            Spacer(minLength: 0)
                            HStack(spacing: 4) {
                                Text(weekly ? "WEEKLY" : "ENDLESS")
                                    .font(.system(size: side * 0.135, weight: .black, design: .rounded)).italic()
                                    .lineLimit(1).minimumScaleFactor(0.8)
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12, weight: .black))
                                    .frame(width: 26, height: 26)
                                    .background(CrocoTheme.ink.opacity(0.1), in: Circle())
                            }
                        }.padding(side * 0.09)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .overlay(RoundedRectangle(cornerRadius: 25).strokeBorder(.white.opacity(0.38), lineWidth: 1))
                .shadow(color: color.opacity(0.18), radius: 13, y: 5)
            }.aspectRatio(1, contentMode: .fit).contentShape(RoundedRectangle(cornerRadius: 25))
        }
        .buttonStyle(LaunchTilePressStyle())
        .foregroundStyle(CrocoTheme.ink)
        .accessibilityLabel(weekly ? "Weekly, 4,000 metres" : "Endless")
        .accessibilityIdentifier(weekly ? "startWeekly" : "startEndless")
    }
}

private struct LaunchTilePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reducedMotion ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.07 : 0)
            .animation(reducedMotion ? nil : .easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
