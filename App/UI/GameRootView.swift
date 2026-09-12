import SwiftUI
import SpriteKit
import CrocoCrossCore

private enum GamePanel: String, Identifiable { case riders, worlds, settings, help; var id: String { rawValue } }

enum CrocoTheme {
    static let ink = Color(red: 0.04, green: 0.10, blue: 0.12)
    static let lime = Color(red: 0.76, green: 0.98, blue: 0.30)
    static let orange = Color(red: 1, green: 0.54, blue: 0.26)
    static let muted = Color(red: 0.67, green: 0.78, blue: 0.77)
}

struct GameRootView: View {
    @Bindable var session: GameSession
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @State private var panel: GamePanel?
    @State private var replacingSavedRun: RunMode?
    @State private var confirmRestart = false

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 650 || geometry.size.width > geometry.size.height
            // System bars change safe-area insets when a ride starts. Pause only
            // when the window itself resizes, not when those bars disappear.
            let viewportSize = CGSize(
                width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
                height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
            )
            ZStack {
                SpriteView(scene: session.scene, preferredFramesPerSecond: 60)
                    .ignoresSafeArea().accessibilityHidden(true)
                if session.phase == .home { home(wide: wide, height: geometry.size.height) }
                else {
                    playOverlay(wide: wide)
                    if session.phase == .paused { pauseOverlay }
                    if session.phase == .results { resultsOverlay }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if let notice = session.notice {
                    Text(notice).font(.footnote.weight(.medium)).padding(12)
                        .background(CrocoTheme.ink.opacity(0.96), in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20).padding(.top, 65).allowsHitTesting(false)
                }
            }
            .onChange(of: viewportSize) { old, new in
                if abs(old.width - new.width) > 30 || abs(old.height - new.height) > 30 { session.pause() }
            }
        }
        .tint(CrocoTheme.lime)
        .background(ScenePresentation().frame(width: 0, height: 0))
        .onChange(of: scenePhase) { _, value in session.setActive(value == .active) }
        .onChange(of: reducedMotion) { _, value in session.setReducedMotion(value) }
        .task {
            session.setReducedMotion(reducedMotion)
            if !ProcessInfo.processInfo.arguments.contains("-ui-testing") { session.gameCenter.authenticate() }
            await session.gameCenter.refresh()
        }
        .sheet(item: $panel) { item in
            NavigationStack {
                panelContent(item)
                    .navigationTitle(panelTitle(item))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { panel = nil }.accessibilityIdentifier("closePanel") } }
            }
            .presentationDetents([.large]).presentationDragIndicator(.visible)
            .tint(CrocoTheme.lime).preferredColorScheme(.dark)
        }
        .confirmationDialog("Start a new ride?", isPresented: Binding(get: { replacingSavedRun != nil }, set: { if !$0 { replacingSavedRun = nil } })) {
            if let mode = replacingSavedRun {
                Button("Replace saved ride", role: .destructive) { replacingSavedRun = nil; session.start(mode) }
            }
        } message: { Text("Your unfinished ride will be replaced. Your records will stay saved.") }
        .confirmationDialog("Restart this ride?", isPresented: $confirmRestart) {
            Button("Restart", role: .destructive) { session.start(session.mode) }
        }
        .statusBarHidden(session.phase == .playing)
        .persistentSystemOverlays(session.phase == .playing ? .hidden : .automatic)
    }

    private func home(wide: Bool, height: CGFloat) -> some View {
        ZStack {
            LinearGradient(colors: [CrocoTheme.ink.opacity(0.6), .clear, CrocoTheme.ink.opacity(0.96)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if wide {
                HStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) { brand; Spacer(minLength: 4); launchOptions; utilityBar }
                            .padding(28).frame(minHeight: height)
                    }.scrollIndicators(.hidden).frame(maxWidth: 385)
                        .background(CrocoTheme.ink.opacity(0.86))
                    VStack { accountBar; Spacer(); riderCaption }.padding(28)
                }
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        accountBar
                        brand.frame(maxWidth: 300)
                        Spacer(minLength: 36)
                        riderCaption
                        launchOptions
                        utilityBar
                    }.padding(.horizontal, 22).padding(.vertical, 12).frame(minHeight: height)
                }.scrollIndicators(.hidden)
            }
        }
    }

    private var brand: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let image = GameAssets.image(named: "crococross-logo-768") {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 150)
            } else {
                Text("CROCO\nCROSS").font(.system(size: 53, weight: .black, design: .rounded)).italic().lineSpacing(-8)
            }
            Text("FIND YOUR BALANCE.").font(.system(size: 11, weight: .heavy, design: .monospaced)).tracking(3).foregroundStyle(CrocoTheme.lime)
        }.accessibilityElement(children: .ignore).accessibilityLabel("CrocoCross. Find your balance.")
    }

    private var accountBar: some View {
        HStack {
            Button {
                if session.gameCenter.isAuthenticated { session.showLeaderboards() }
                else { session.gameCenter.authenticate() }
            } label: {
                Label(session.gameCenter.isAuthenticated ? session.gameCenter.playerName : "Game Center", systemImage: "person.crop.circle")
                    .font(.system(size: 13, weight: .semibold)).lineLimit(1)
            }.accessibilityIdentifier("gameCenter")
            Spacer()
            Button { panel = .settings } label: { Image(systemName: "slider.horizontal.3").font(.title3).frame(width: 44, height: 44) }
                .accessibilityLabel("Settings").accessibilityIdentifier("settings")
        }.foregroundStyle(.white)
    }

    private var riderCaption: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(GameCatalog.riders.first(where: { $0.id == session.characterID })?.name.uppercased() ?? "ROCCO")
                    .font(.system(size: 25, weight: .black, design: .rounded)).italic()
                Text(GameCatalog.worlds.first(where: { $0.id == session.worldID })?.name ?? "Canyon")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(CrocoTheme.muted)
            }
            Spacer()
        }.padding(12).background(CrocoTheme.ink.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
    }

    private var launchOptions: some View {
        VStack(spacing: 10) {
            if session.hasSavedRun {
                Button { session.restore() } label: { Label("Continue your ride", systemImage: "play.circle.fill").frame(maxWidth: .infinity).padding(12) }
                    .font(.subheadline.bold()).background(CrocoTheme.ink.opacity(0.92), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(CrocoTheme.lime.opacity(0.35), lineWidth: 1))
                    .accessibilityIdentifier("continueRun")
            }
            Button { start(.weekly) } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("WEEKLY CHALLENGE").font(.system(size: 19, weight: .black, design: .rounded))
                        Text("4,000 m  ·  One life  ·  One shared trail").font(.system(size: 11, weight: .semibold))
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "arrow.up.right").font(.title2.bold())
                }.padding(.horizontal, 18).padding(.vertical, 17)
                    .foregroundStyle(CrocoTheme.ink).background(CrocoTheme.lime, in: RoundedRectangle(cornerRadius: 20))
            }.accessibilityIdentifier("startWeekly")
            Button { start(.endless) } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ENDLESS RIDE").font(.system(size: 17, weight: .black, design: .rounded))
                        Text("Three lives. See how far you can go.").font(.system(size: 11, weight: .medium)).foregroundStyle(CrocoTheme.muted)
                    }
                    Spacer(); Image(systemName: "infinity").font(.title2.bold()).foregroundStyle(CrocoTheme.orange)
                }.padding(.horizontal, 18).padding(.vertical, 15)
                    .background(CrocoTheme.ink.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.17), lineWidth: 1))
            }.foregroundStyle(.white).accessibilityIdentifier("startEndless")
        }
    }

    private var utilityBar: some View {
        HStack(spacing: 0) {
            utility("Riders", icon: "helmet", fallback: "person.fill", id: "riders") { panel = .riders }
            utility("Worlds", icon: "mountain.2.fill", id: "worlds") { panel = .worlds }
            utility("Rankings", icon: "trophy.fill", id: "rankings") { session.showLeaderboards() }
            utility("How to", icon: "questionmark.circle", id: "help") { panel = .help }
        }.padding(.top, 2)
    }

    private func utility(_ title: String, icon: String, fallback: String? = nil, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: UIImage(systemName: icon) == nil ? (fallback ?? "circle") : icon).font(.system(size: 18, weight: .semibold))
                Text(title).font(.system(size: 10, weight: .semibold))
            }.frame(maxWidth: .infinity).frame(minHeight: 48)
        }.foregroundStyle(.white.opacity(0.88)).accessibilityIdentifier(id)
    }

    private func playOverlay(wide: Bool) -> some View {
        VStack {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.mode == .weekly ? "WEEKLY / 4,000 M" : "ENDLESS RIDE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(1.5).foregroundStyle(CrocoTheme.lime)
                    Text(session.score.formatted()).font(.system(size: 32, weight: .black, design: .rounded)).monospacedDigit().accessibilityIdentifier("score")
                    HStack(spacing: 8) {
                        Text("\(Int(session.distance)) m").accessibilityIdentifier("distance")
                        Text("·")
                        Text(timeString(session.elapsed))
                    }.font(.system(size: 12, weight: .semibold, design: .monospaced))
                }.padding(10).background(CrocoTheme.ink.opacity(0.84), in: RoundedRectangle(cornerRadius: 15))
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Button { session.pause() } label: { Image(systemName: "pause.fill").frame(width: 46, height: 46).background(CrocoTheme.ink.opacity(0.8), in: Circle()) }
                        .accessibilityLabel("Pause").accessibilityIdentifier("pause")
                    HStack(spacing: 5) {
                        ForEach(0..<max(0, session.lives), id: \.self) { _ in Image(systemName: "heart.fill").font(.system(size: 13)).foregroundStyle(CrocoTheme.orange) }
                    }.accessibilityElement(children: .ignore).accessibilityLabel("\(session.lives) lives remaining")
                }
            }
            .shadow(color: .black.opacity(0.8), radius: 6)
            if session.mode == .weekly {
                GeometryReader { geo in
                    Capsule().fill(.white.opacity(0.16))
                    Capsule().fill(CrocoTheme.lime).frame(width: geo.size.width * min(1, max(0, session.distance / 4_000)))
                }.frame(height: 3)
            }
            Spacer()
            if let text = session.eventText {
                Text(text).font(.system(size: 24, weight: .black, design: .rounded)).italic().foregroundStyle(CrocoTheme.lime)
                    .shadow(color: .black.opacity(0.6), radius: 8).padding(.bottom, 12)
            }
            if session.recovering { Text("GETTING BACK UP…").font(.caption.bold()).padding(10).background(CrocoTheme.ink.opacity(0.8), in: Capsule()) }
            HStack(alignment: .bottom) {
                PedalControl(right: false, enabled: session.phase == .playing && !session.recovering, resetToken: session.pedalReset) { session.setPedal(right: false, value: $0) }.frame(width: wide ? 124 : 108, height: 76)
                Spacer()
                VStack(spacing: 3) {
                    Text("\(Int(session.speed))").font(.system(size: 22, weight: .bold, design: .rounded)).monospacedDigit()
                    Text("KM/H").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(1.5)
                    if !session.ranked { Text("PRACTICE").font(.system(size: 8, weight: .bold)).foregroundStyle(CrocoTheme.lime).padding(.top, 5) }
                }.padding(10).background(CrocoTheme.ink.opacity(0.84), in: RoundedRectangle(cornerRadius: 14))
                    .padding(.bottom, 4).shadow(color: .black, radius: 8)
                Spacer()
                PedalControl(right: true, enabled: session.phase == .playing && !session.recovering, resetToken: session.pedalReset) { session.setPedal(right: true, value: $0) }.frame(width: wide ? 124 : 108, height: 76)
            }.opacity(session.phase == .playing ? 1 : 0).allowsHitTesting(session.phase == .playing)
        }.padding(.horizontal, wide ? 28 : 18).padding(.top, 12).padding(.bottom, 12).foregroundStyle(.white)
    }

    private var pauseOverlay: some View {
        modal {
            Text("TAKE A BREATHER.").font(.system(size: 27, weight: .black, design: .rounded)).italic()
            Text("Your ride is paused.").foregroundStyle(CrocoTheme.muted)
            primaryButton("Keep riding", icon: "play.fill", id: "resume") { session.resume() }
            HStack {
                Button("Restart") { confirmRestart = true }
                Spacer()
                Button("Sound") { panel = .settings }
                Spacer()
                Button("Home") { session.goHome() }.accessibilityIdentifier("home")
            }.font(.subheadline.bold()).padding(.vertical, 14)
        }
    }

    private var resultsOverlay: some View {
        modal {
            Text(session.finished ? "TRAIL CONQUERED." : "ONE MORE RUN?")
                .font(.system(size: 27, weight: .black, design: .rounded)).italic()
            Text(session.score.formatted()).font(.system(size: 55, weight: .black, design: .rounded)).foregroundStyle(CrocoTheme.lime).monospacedDigit()
            HStack {
                resultStat("DISTANCE", value: "\(Int(session.distance)) m")
                Spacer(); resultStat("TIME", value: timeString(session.elapsed))
                Spacer(); resultStat("FLIPS", value: "\(session.flips)")
            }
            if let message = session.gameCenter.statusMessage, session.ranked { Text(message).font(.footnote).foregroundStyle(CrocoTheme.muted) }
            primaryButton("Ride again", icon: "arrow.clockwise", id: "rideAgain") { session.start(session.mode) }
            HStack {
                Button("Leaderboards") { session.showLeaderboards() }
                Spacer(); Button("Home") { session.goHome() }.accessibilityIdentifier("home")
            }.font(.subheadline.bold()).padding(.top, 6)
        }
    }

    private func resultStat(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(CrocoTheme.muted)
            Text(value).font(.system(size: 17, weight: .bold, design: .rounded))
        }
    }

    private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20, content: content)
                    .padding(27).frame(maxWidth: 400)
                    .background(CrocoTheme.ink, in: RoundedRectangle(cornerRadius: 30))
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(.white.opacity(0.15), lineWidth: 1))
                    .frame(maxWidth: .infinity).padding(20)
            }.defaultScrollAnchor(.center)
        }.foregroundStyle(.white)
    }

    private func primaryButton(_ title: String, icon: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(.headline.bold()).frame(maxWidth: .infinity).padding(17)
                .foregroundStyle(CrocoTheme.ink).background(CrocoTheme.lime, in: RoundedRectangle(cornerRadius: 16))
        }.accessibilityIdentifier(id)
    }

    @ViewBuilder private func panelContent(_ item: GamePanel) -> some View {
        switch item {
        case .riders:
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 14)], spacing: 14) {
                    ForEach(GameCatalog.riders) { rider in
                        catalogCard(id: rider.id, name: rider.name, subtitle: rider.subtitle, asset: rider.assetName, selected: session.characterID == rider.id, imageHeight: 105) { session.characterID = rider.id }
                    }
                }.padding(18)
                Text("Every rider shares the same physics. Pick your style.").font(.footnote).foregroundStyle(CrocoTheme.muted).padding()
            }.background(CrocoTheme.ink)
        case .worlds:
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 14)], spacing: 14) {
                    ForEach(GameCatalog.worlds) { world in
                        catalogCard(id: world.id, name: world.name, subtitle: world.subtitle, asset: world.assetName, selected: session.worldID == world.id, imageHeight: 112) { session.worldID = world.id }
                    }
                }.padding(18)
            }.background(CrocoTheme.ink)
        case .settings: SettingsPanel(session: session)
        case .help:
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    helpRow("arrow.right", "Right thumb", "Accelerate on the ground. Lean back in the air. Feed the throttle in short bursts: too much torque can lift the front wheel.")
                    helpRow("arrow.left", "Left thumb", "Brake on the ground. Lean forward in the air. Release the controls to let momentum carry you.")
                    helpRow("hand.draw.fill", "A lighter touch", "Hold a pedal and slide your thumb down to reduce its strength. Lift your thumb to release it.")
                    helpRow("arrow.down.right", "Land with the slope", "Match the bike to the landing. Suspension absorbs a measured impact; a hard sideways landing can end your ride. Flips count only when you land safely.")
                    helpRow("calendar", "One week. One trail.", "The 4,000-metre challenge changes every Monday at 00:00 UTC. One life, no time limit. Finish to enter the weekly score and time leaderboards.")
                    helpRow("wifi.slash", "Ride anywhere", "Endless and weekly practice work offline. Connect to Game Center before starting a ranked challenge. Expired weekly results stay local.")
                }.padding(24)
            }.background(CrocoTheme.ink)
        }
    }

    private func catalogCard(id: String, name: String, subtitle: String, asset: String, selected: Bool, imageHeight: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                if let image = GameAssets.image(named: asset) {
                    Image(uiImage: image).resizable().scaledToFit().frame(maxWidth: .infinity).frame(height: imageHeight).clipped()
                }
                HStack { Text(name).font(.headline); Spacer(minLength: 2); if selected { Image(systemName: "checkmark.circle.fill").foregroundStyle(CrocoTheme.lime) } }
                Text(subtitle).font(.caption).foregroundStyle(CrocoTheme.muted).lineLimit(2).frame(minHeight: 29, alignment: .top)
            }.padding(12).background(.white.opacity(selected ? 0.10 : 0.035), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? CrocoTheme.lime : .white.opacity(0.12), lineWidth: selected ? 2 : 1))
        }.foregroundStyle(.white).accessibilityIdentifier("select-\(id)").accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func helpRow(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon).foregroundStyle(CrocoTheme.lime).font(.title2).frame(width: 28)
            VStack(alignment: .leading, spacing: 6) { Text(title).font(.headline); Text(text).font(.body).foregroundStyle(CrocoTheme.muted) }
        }
    }
    private func panelTitle(_ item: GamePanel) -> String {
        switch item { case .riders: "Choose your rider"; case .worlds: "Choose your world"; case .settings: "Settings"; case .help: "Find your balance" }
    }
    private func start(_ mode: RunMode) { if session.hasSavedRun { replacingSavedRun = mode } else { session.start(mode) } }
    private func timeString(_ seconds: Double) -> String { String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60) }
}
