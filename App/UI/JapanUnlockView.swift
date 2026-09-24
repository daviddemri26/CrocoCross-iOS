import SwiftUI

/// The world is already durably claimed before this short, interruptible reveal begins.
struct JapanUnlockView: View {
    let ride: () -> Void
    let dismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @State private var opened = false
    @State private var revealed = false
    @State private var complete = false

    private let pink = Color(red: 0.98, green: 0.72, blue: 0.84)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CrocoTheme.ink.ignoresSafeArea()
                RadialGradient(colors: [pink.opacity(revealed ? 0.22 : 0.08), .clear],
                    center: .center, startRadius: 0, endRadius: min(geometry.size.width, 550))
                    .ignoresSafeArea()
                petals(in: geometry.size)
                ScrollView {
                    VStack(spacing: 18) {
                        Spacer(minLength: 12)
                        Text(complete ? "JAPAN MOUNTAINS UNLOCKED" : "A NEW WORLD")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .tracking(2).foregroundStyle(pink).multilineTextAlignment(.center)
                            .accessibilityIdentifier("japanUnlockTitle")
                        ZStack {
                            artwork
                                .saturation(revealed ? 1 : 0.55)
                                .blur(radius: revealed ? 0 : 4)
                                .opacity(revealed ? 1 : 0.45)
                                .scaleEffect(revealed || reducedMotion ? 1 : 0.94)
                            Image(systemName: opened ? "lock.open.fill" : "lock.fill")
                                .font(.system(size: 46, weight: .bold))
                                .foregroundStyle(CrocoTheme.ink)
                                .padding(24).background(pink, in: RoundedRectangle(cornerRadius: 28))
                                .rotationEffect(.degrees(opened && !reducedMotion ? -12 : 0))
                                .offset(y: revealed && !reducedMotion ? -65 : 0)
                                .opacity(revealed ? 0 : 1)
                        }
                        .frame(height: max(130, min(geometry.size.height * 0.40, 280)))
                        .accessibilityHidden(true)
                        VStack(spacing: 6) {
                            Text("JAPAN MOUNTAINS")
                                .font(.custom("AvenirNextCondensed-HeavyItalic", size: 40))
                                .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                            Text("Pines, peaks & falling petals")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(CrocoTheme.muted).multilineTextAlignment(.center)
                        }
                        VStack(spacing: 10) {
                            Button(action: ride) {
                                Label("Ride in Japan", systemImage: "arrow.right")
                                    .font(.headline.bold()).frame(maxWidth: .infinity).padding(18)
                                    .foregroundStyle(CrocoTheme.ink)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                            }.accessibilityIdentifier("rideInJapan")
                            Button("Not now", action: dismiss)
                                .font(.subheadline.bold()).foregroundStyle(CrocoTheme.muted)
                                .frame(minHeight: 44).accessibilityIdentifier("dismissJapanUnlock")
                        }.opacity(complete ? 1 : 0).disabled(!complete).accessibilityHidden(!complete)
                    }.padding(24).frame(maxWidth: 520)
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }.scrollIndicators(.hidden)
            }.foregroundStyle(.white)
        }
        .accessibilityIdentifier("japanUnlockCelebration")
        .task {
            do {
                if reducedMotion {
                    opened = true
                    withAnimation(.easeOut(duration: 0.2)) { revealed = true }
                    try await Task.sleep(for: .milliseconds(220))
                } else {
                    try await Task.sleep(for: .milliseconds(250))
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { opened = true }
                    try await Task.sleep(for: .milliseconds(400))
                    withAnimation(.easeOut(duration: 0.65)) { revealed = true }
                    try await Task.sleep(for: .milliseconds(1_350))
                }
                withAnimation(.easeOut(duration: 0.2)) { complete = true }
            } catch {
                // Leaving this cover cancels its task; the saved claim remains available.
            }
        }
    }

    @ViewBuilder private var artwork: some View {
        if let image = GameAssets.image(named: "japan-mountains") {
            GeometryReader { geometry in
                Image(uiImage: image).resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(pink.opacity(0.28), lineWidth: 1))
        }
    }

    @ViewBuilder private func petals(in size: CGSize) -> some View {
        if !reducedMotion {
            ForEach(0..<26, id: \.self) { index in
                let angle = Double(index) * .pi * 2 / 26
                let distance = min(size.width * 0.46, 270) * (index.isMultiple(of: 3) ? 0.7 : 1)
                Ellipse()
                    .fill(index.isMultiple(of: 3) ? .white.opacity(0.85) : pink)
                    .frame(width: index.isMultiple(of: 2) ? 7 : 10, height: 16)
                    .rotationEffect(.degrees(revealed ? Double(index * 47) : Double(index * 13)))
                    .offset(x: revealed ? cos(angle) * distance : 0,
                            y: revealed ? sin(angle) * distance + 35 : -45)
                    .opacity(revealed ? 0 : 0.9)
                    .animation(.easeOut(duration: 1.5), value: revealed)
            }.allowsHitTesting(false).accessibilityHidden(true)
        }
    }
}
