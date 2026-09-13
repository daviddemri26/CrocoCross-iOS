import SwiftUI

struct RideSpeedometer: View {
    let speed: Double
    // Presentation-only scale: simulation speed and travelled distance remain physical.
    private var shownSpeed: Double { speed.isFinite ? max(0, speed) * 2 : 0 }

    var body: some View {
        ZStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2 + 1)
                let radius = min(size.width, size.height) / 2 - 3
                let progress = min(1, shownSpeed / 200)
                var track = Path()
                track.addArc(
                    center: center, radius: radius, startAngle: .degrees(140), endAngle: .degrees(400), clockwise: false
                )
                context.stroke(
                    track, with: .color(.white.opacity(0.12)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                if progress > 0 {
                    var fill = Path()
                    fill.addArc(
                        center: center, radius: radius, startAngle: .degrees(140),
                        endAngle: .degrees(140 + 260 * progress), clockwise: false)
                    context.stroke(
                        fill, with: .color(progress > 0.8 ? CrocoTheme.orange : CrocoTheme.lime),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                }
                for tick in 0...10 {
                    let angle = (140 + Double(tick) * 26) * .pi / 180
                    var mark = Path()
                    mark.move(
                        to: CGPoint(x: center.x + cos(angle) * (radius - 6), y: center.y + sin(angle) * (radius - 6)))
                    mark.addLine(
                        to: CGPoint(x: center.x + cos(angle) * (radius - 9), y: center.y + sin(angle) * (radius - 9)))
                    context.stroke(mark, with: .color(.white.opacity(0.25)), lineWidth: 1)
                }
            }
            VStack(spacing: -1) {
                Text("\(Int(shownSpeed))").font(.system(size: 25, weight: .black, design: .rounded)).monospacedDigit()
                Text("KM/H").font(.system(size: 7, weight: .black, design: .monospaced)).tracking(1)
                    .foregroundStyle(CrocoTheme.muted)
            }.offset(y: 3)
        }.frame(width: 74, height: 65)
            .accessibilityElement(children: .ignore).accessibilityLabel("Speed")
            .accessibilityValue("\(Int(shownSpeed)) kilometres per hour").accessibilityIdentifier("speedometer")
    }
}
