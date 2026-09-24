import SwiftUI

/// A short reveal follows the durable claim. Dismissing/interruption never replays or loses it.
struct KenjiUnlockView: View {
    let ride: () -> Void
    let dismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @State private var opened = false
    @State private var revealed = false
    @State private var complete = false

    private let blue = Color(red: 0.20, green: 0.66, blue: 1)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CrocoTheme.ink.ignoresSafeArea()
                RadialGradient(colors: [blue.opacity(revealed ? 0.34 : 0.12), .clear],
                    center: .center, startRadius: 0, endRadius: min(geometry.size.width, 500))
                    .ignoresSafeArea()
                if !reducedMotion {
                    ForEach(0..<28, id: \.self) { index in
                        let angle = Double(index) * .pi * 2 / 28
                        let distance = min(geometry.size.width * 0.45, 230) * (index.isMultiple(of: 3) ? 0.7 : 1)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index.isMultiple(of: 2) ? blue : .white)
                            .frame(width: index.isMultiple(of: 3) ? 5 : 8, height: 12)
                            .rotationEffect(.degrees(revealed ? Double(index * 37) : 0))
                            .offset(x: revealed ? cos(angle) * distance : 0,
                                    y: revealed ? sin(angle) * distance - 45 : -45)
                            .opacity(revealed ? 0 : 1)
                            .animation(.easeOut(duration: 1.5), value: revealed)
                    }
                }
                ScrollView {
                    VStack(spacing: 18) {
                        Spacer(minLength: 12)
                        Text(complete ? "KENJI UNLOCKED" : "A NEW RIDER")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .tracking(3).foregroundStyle(blue)
                            .accessibilityIdentifier("kenjiUnlockTitle")
                        ZStack {
                            RiderArtworkView(riderID: "shiba", animated: complete)
                                .saturation(revealed ? 1 : 0.7)
                                .blur(radius: revealed ? 0 : 4)
                                .opacity(revealed ? 1 : 0.45)
                                .scaleEffect(revealed || reducedMotion ? 1 : 0.93)
                            Image(systemName: opened ? "lock.open.fill" : "lock.fill")
                                .font(.system(size: 46, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(24).background(blue, in: RoundedRectangle(cornerRadius: 28))
                                .rotationEffect(.degrees(opened && !reducedMotion ? -12 : 0))
                                .offset(y: revealed && !reducedMotion ? -65 : 0)
                                .opacity(revealed ? 0 : 1)
                        }
                        .frame(height: min(geometry.size.height * 0.42, 300))
                        .accessibilityHidden(true)
                        VStack(spacing: 6) {
                            Text("KENJI").font(.custom("AvenirNextCondensed-HeavyItalic", size: 45))
                            Text("Shiba Inu · Superbike")
                                .font(.system(size: 15, weight: .medium)).foregroundStyle(CrocoTheme.muted)
                        }
                        VStack(spacing: 10) {
                            Button(action: ride) {
                                Label("Ride with Kenji", systemImage: "arrow.right")
                                    .font(.headline.bold()).frame(maxWidth: .infinity).padding(18)
                                    .foregroundStyle(CrocoTheme.ink)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
                            }.accessibilityIdentifier("rideWithKenji")
                            Button("Not now", action: dismiss)
                                .font(.subheadline.bold()).foregroundStyle(CrocoTheme.muted)
                                .frame(minHeight: 44).accessibilityIdentifier("dismissKenjiUnlock")
                        }.opacity(complete ? 1 : 0).disabled(!complete).accessibilityHidden(!complete)
                    }.padding(24).frame(maxWidth: 430)
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                }.scrollIndicators(.hidden)
            }.foregroundStyle(.white)
        }
        .accessibilityIdentifier("kenjiUnlockCelebration")
        .task {
            if reducedMotion {
                opened = true
                withAnimation(.easeOut(duration: 0.2)) { revealed = true }
                try? await Task.sleep(for: .milliseconds(220))
            } else {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { opened = true }
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.65)) { revealed = true }
                try? await Task.sleep(for: .milliseconds(1_350))
            }
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { complete = true }
        }
    }
}
