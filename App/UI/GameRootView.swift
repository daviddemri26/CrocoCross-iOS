import CrocoCrossCore
import SpriteKit
import SwiftUI

private enum GamePanel: String, Identifiable {
    case riders, worlds, settings, help, rankings
    var id: String { rawValue }
}

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

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= GameScene.minimumWideHomeWidth
            // System bars change safe-area insets when a ride starts. Pause only
            // when the window itself resizes, not when those bars disappear.
            let viewportSize = CGSize(
                width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
                height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
            )
            ZStack {
                SpriteView(scene: session.scene, preferredFramesPerSecond: 60)
                    .saturation(session.showingCrash ? 0.12 : 1)
                    .overlay {
                        Color(red: 0.40, green: 0.30, blue: 0.18)
                            .opacity(session.showingCrash ? 0.12 : 0)
                            .allowsHitTesting(false)
                    }
                    .animation(.easeInOut(duration: reducedMotion ? 0.2 : 0.65), value: session.showingCrash)
                    .ignoresSafeArea().accessibilityHidden(true)
                if session.phase == .home {
                    home(wide: wide, height: geometry.size.height)
                } else {
                    playOverlay(wide: geometry.size.width > geometry.size.height, height: geometry.size.height)
                    if session.phase == .paused { pauseOverlay }
                    if session.phase == .results && session.resultsVisible {
                        resultsOverlay.transition(.opacity.combined(with: .scale(scale: 0.94)))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(
                reducedMotion ? nil : .spring(response: 0.4, dampingFraction: 0.86), value: session.resultsVisible
            )
            .onChange(of: viewportSize) { old, new in
                if abs(old.width - new.width) > 30 || abs(old.height - new.height) > 30 { session.pause() }
            }
        }
        .tint(CrocoTheme.lime)
        .background(ScenePresentation().frame(width: 0, height: 0))
        .onChange(of: scenePhase) { _, value in
            switch value {
            case .active: session.setActive(true)
            case .inactive: session.setActive(false)
            case .background:
                panel = nil
                session.leaveApp()
            @unknown default: session.setActive(false)
            }
        }
        .onChange(of: reducedMotion) { _, value in session.setReducedMotion(value) }
        .task {
            session.setReducedMotion(reducedMotion)
            if PhysicsBenchmark.runIfRequested() { return }
            if !ProcessInfo.processInfo.arguments.contains("-ui-testing") { session.gameCenter.authenticate() }
            await session.gameCenter.refresh()
        }
        .sheet(item: $panel) { item in
            NavigationStack {
                VStack(spacing: 0) {
                    panelContent(item)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if item != .settings {
                        HStack {
                            Spacer()
                            PanelCloseButton { panel = nil }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(CrocoTheme.ink)
                        .overlay(alignment: .top) {
                            Rectangle().fill(.white.opacity(0.12)).frame(height: 1)
                        }
                    }
                }
                .background(CrocoTheme.ink)
                .navigationTitle(panelTitle(item))
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.large]).presentationDragIndicator(.visible)
            .tint(CrocoTheme.lime).preferredColorScheme(.dark)
        }
        .statusBarHidden(session.phase == .playing)
        .persistentSystemOverlays(session.phase == .playing ? .hidden : .automatic)
    }

    private func home(wide: Bool, height: CGFloat) -> some View {
        ZStack {
            LinearGradient(
                colors: [CrocoTheme.ink.opacity(0.45), .clear, CrocoTheme.ink.opacity(0.96)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            if wide {
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        ScrollView {
                            VStack(spacing: 18) {
                                brand.frame(maxWidth: 290)
                                Spacer(minLength: 0)
                                riderCaption
                                launchOptions
                            }.padding(26).frame(minHeight: max(0, height - 100))
                        }.scrollIndicators(.hidden)
                        utilityBar.padding(.horizontal, 26).padding(.bottom, 16)
                    }.frame(width: GameScene.homePanelWidth).background(CrocoTheme.ink.opacity(0.84))
                    Color.clear
                }
            } else {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 16) {
                            brand.frame(maxWidth: 250)
                            Spacer(minLength: 16)
                            riderCaption
                            launchOptions
                        }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 16)
                            .frame(minHeight: max(0, height - 94))
                    }.scrollIndicators(.hidden)
                    utilityBar.padding(.horizontal, 20).padding(.bottom, 8)
                }
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
            Text("ROCCO PREVIEW")
                .font(.system(size: 10, weight: .bold, design: .rounded)).tracking(1.4)
                .foregroundStyle(CrocoTheme.lime).accessibilityIdentifier("previewStatus")
        }.accessibilityElement(children: .ignore).accessibilityLabel("CrocoCross")
    }

    private var riderCaption: some View {
        HStack(spacing: 12) {
            selectionButton(
                GameCatalog.riders.first(where: { $0.id == session.characterID })?.name ?? "Rocco",
                title: "Rider", rider: true, id: "riders"
            ) { panel = .riders }
            selectionButton(
                GameCatalog.worlds.first(where: { $0.id == session.worldID })?.name ?? "Canyon",
                title: "World", rider: false, id: "worlds"
            ) { panel = .worlds }
        }
    }

    private func selectionButton(
        _ name: String, title: String, rider: Bool, id: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.system(size: 10, weight: .heavy, design: .rounded))
                    .textCase(.uppercase).tracking(1.3).foregroundStyle(CrocoTheme.muted)
                HStack(spacing: 8) {
                    Group {
                        if rider {
                            LegacyRiderIcon(size: 22)
                        } else {
                            Image(systemName: "mountain.2.fill").font(.system(size: 17, weight: .semibold))
                        }
                    }.frame(width: 22).foregroundStyle(CrocoTheme.lime)
                    Text(name).font(.system(size: 14, weight: .bold, design: .rounded))
                        .lineLimit(1).minimumScaleFactor(0.6).layoutPriority(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .black))
                        .foregroundStyle(CrocoTheme.muted)
                }
            }.padding(.horizontal, 12).frame(maxWidth: .infinity, alignment: .leading).frame(height: 76)
                .background(CrocoTheme.ink.opacity(0.93), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.2), lineWidth: 1))
        }.foregroundStyle(.white).accessibilityIdentifier(id)
            .accessibilityLabel("\(title): \(name)")
    }

    private var launchOptions: some View {
        HStack(spacing: 12) {
            LaunchTile(weekly: true, reducedMotion: reducedMotion) { session.start(.weekly) }
            LaunchTile(weekly: false, reducedMotion: reducedMotion) { session.start(.endless) }
        }
    }

    private var utilityBar: some View {
        HStack(spacing: 8) {
            utility("Rankings", icon: "trophy.fill", id: "rankings") { panel = .rankings }
            utility("Settings", icon: "slider.horizontal.3", id: "settings") { panel = .settings }
            utility("How to", icon: "questionmark.circle", id: "help") { panel = .help }
        }.padding(7).background(CrocoTheme.ink.opacity(0.9), in: RoundedRectangle(cornerRadius: 25))
    }

    private func utility(
        _ title: String, icon: String, fallback: String? = nil, id: String, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: UIImage(systemName: icon) == nil ? (fallback ?? "circle") : icon).font(
                    .system(size: 20, weight: .semibold))
                Text(title).font(.system(size: 11, weight: .bold))
            }.frame(maxWidth: .infinity).frame(height: 64).contentShape(Rectangle())
        }.buttonStyle(.plain).foregroundStyle(.white.opacity(0.88)).accessibilityIdentifier(id)
    }

    private func playOverlay(wide: Bool, height: CGFloat) -> some View {
        let pedalSize: CGFloat = wide ? 124 : 112
        return ZStack(alignment: .bottom) {
            HStack(spacing: 0) {
                PedalControl(
                    right: false, enabled: session.phase == .playing && !session.recovering,
                    resetToken: session.pedalReset
                ) { session.setPedal(right: false, pressed: $0) }
                    .frame(width: pedalSize, height: pedalSize)
                Spacer(minLength: 64)
                PedalControl(
                    right: true, enabled: session.phase == .playing && !session.recovering,
                    resetToken: session.pedalReset
                ) { session.setPedal(right: true, pressed: $0) }
                    .frame(width: pedalSize, height: pedalSize)
            }.padding(.horizontal, wide ? 28 : 16).padding(.bottom, 16)
                .opacity(session.phase == .playing ? 1 : 0)
                .allowsHitTesting(session.phase == .playing)
            VStack(spacing: 12) {
                VStack(spacing: 6) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.mode == .weekly ? "WEEKLY" : "ENDLESS")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced)).tracking(1.5).foregroundStyle(
                                    CrocoTheme.lime)
                            Text(session.score.formatted()).font(.system(size: 26, weight: .black, design: .rounded))
                                .lineLimit(1).minimumScaleFactor(0.6)
                                .monospacedDigit().contentTransition(.numericText()).accessibilityIdentifier("score")
                        }
                        Spacer(minLength: 0)
                        RideSpeedometer(speed: session.speed)
                            .scaleEffect(0.86).frame(width: 64, height: 56)
                        Spacer(minLength: 0)
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("DISTANCE").font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .tracking(1).foregroundStyle(CrocoTheme.muted)
                            Text("\(Int(session.distance).formatted()) m")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .lineLimit(1).minimumScaleFactor(0.7).monospacedDigit()
                                .accessibilityIdentifier("distance")
                            Text(timeString(session.elapsed))
                                .font(.system(size: 11, weight: .bold, design: .monospaced)).monospacedDigit()
                                .foregroundStyle(CrocoTheme.muted)
                        }
                    }
                    Rectangle().fill(.white.opacity(0.10)).frame(height: 1)
                    livesRow(wide: wide)
                }.padding(.horizontal, 14).padding(.vertical, 8)
                    .frame(maxWidth: 560)
                    .background(CrocoTheme.ink.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
                if session.mode == .weekly {
                    GeometryReader { geo in
                        Capsule().fill(CrocoTheme.ink.opacity(0.6))
                        Capsule().fill(CrocoTheme.lime).frame(
                            width: geo.size.width * min(1, max(0, session.distance / 4_000)))
                    }.frame(height: 4).accessibilityLabel("Course progress").accessibilityValue(
                        "\(Int(min(100, session.distance / 40))) percent")
                }
                if let text = session.eventText {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90").font(.title2.bold())
                        Text(text).font(.system(size: 22, weight: .black, design: .rounded)).italic()
                        if session.eventPoints > 0 {
                            Text("+\(session.eventPoints.formatted())").font(
                                .system(size: 22, weight: .black, design: .rounded)
                            ).monospacedDigit()
                        }
                    }.foregroundStyle(CrocoTheme.lime).padding(.horizontal, 18).padding(.vertical, 12)
                        .background(CrocoTheme.ink.opacity(0.94), in: RoundedRectangle(cornerRadius: 17))
                        .accessibilityElement(children: .combine).accessibilityIdentifier("stuntNotice")
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
                Spacer()
            }.padding(.horizontal, wide ? 28 : 16).padding(.top, 12).padding(.bottom, wide ? 88 : 160).allowsHitTesting(false)
            VStack(spacing: 5) {
                Button {
                    session.pause()
                } label: {
                    Image(systemName: "pause.fill").font(.system(size: 19, weight: .black)).frame(width: 54, height: 54)
                        .background(CrocoTheme.ink.opacity(0.94), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.24), lineWidth: 1))
                }.accessibilityLabel("Pause").accessibilityIdentifier("pause")

            }.padding(.bottom, 24).opacity(session.phase == .playing ? 1 : 0).allowsHitTesting(
                session.phase == .playing)
        }.foregroundStyle(.white)
            .animation(reducedMotion ? nil : .spring(response: 0.3, dampingFraction: 0.8), value: session.eventText)
    }

    private func livesRow(wide: Bool) -> some View {
        let capacity = session.mode == .endless ? 3 : 1
        let remaining = min(capacity, max(0, session.lives))
        return HStack(spacing: wide ? 10 : 12) {
            ForEach(0..<capacity, id: \.self) { index in
                Image(systemName: index < remaining ? "heart.fill" : "heart")
                    .font(.system(size: wide ? 18 : 20, weight: .bold))
                    .foregroundStyle(index < remaining ? CrocoTheme.orange : .white.opacity(0.22))
                    .frame(width: wide ? 26 : 28, height: 24)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lives")
        .accessibilityValue("\(remaining) of \(capacity) remaining")
        .accessibilityIdentifier("lives")
    }

    private var pauseOverlay: some View {
        modal {
            Text("PAUSED").font(.system(size: 27, weight: .black, design: .rounded)).italic()
            primaryButton("Keep riding", icon: "play.fill", id: "resume") { session.resume() }
            HStack(spacing: 10) {
                menuAction("Restart", icon: "arrow.counterclockwise", id: "restart") { session.start(session.mode) }
                menuAction("Settings", icon: "slider.horizontal.3", id: "pauseSettings") { panel = .settings }
                menuAction("Home", icon: "house.fill", id: "home") { session.goHome() }
            }

        }
    }

    private func menuAction(_ title: String, icon: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(CrocoTheme.lime)
                Text(title).font(.system(size: 12, weight: .bold))
            }.frame(maxWidth: .infinity).frame(height: 86)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.12), lineWidth: 1))
        }.foregroundStyle(.white).accessibilityIdentifier(id)
    }

    private var resultsOverlay: some View {
        modal {
            HStack {
                Image(systemName: session.finished ? "flag.checkered" : "bolt.fill")
                    .font(.system(size: 24, weight: .black)).foregroundStyle(CrocoTheme.orange)
                Text(session.finished ? "FINISH!" : "GAME OVER")
                    .font(.system(size: 29, weight: .black, design: .rounded)).italic()
            }
            VStack(alignment: .leading, spacing: 5) {
                if session.newRecord {
                    Label("NEW BEST", systemImage: "trophy.fill").font(
                        .system(size: 11, weight: .black, design: .rounded)
                    )
                    .foregroundStyle(CrocoTheme.ink).padding(.horizontal, 10).padding(.vertical, 6)
                    .background(CrocoTheme.orange, in: Capsule())
                }
                ScoreCounter(score: session.score, reducedMotion: reducedMotion)
                Text("POINTS").font(.system(size: 10, weight: .heavy, design: .monospaced)).tracking(2).foregroundStyle(
                    CrocoTheme.muted)
            }
            HStack(spacing: 8) {
                resultStat(
                    "DISTANCE", value: "\(Int(session.distance)) m",
                    icon: "point.bottomleft.forward.to.point.topright.scurvepath")
                resultStat("TIME", value: timeString(session.elapsed), icon: "stopwatch")
                resultStat("FLIPS", value: "\(session.flips)", icon: "arrow.clockwise")
            }
            if session.mode == .weekly {
                VStack(spacing: 6) {
                    ProgressView(value: min(4_000, session.distance), total: 4_000).tint(CrocoTheme.lime)
                    HStack {
                        Text("\(Int(min(100, session.distance / 40)))%")
                        Spacer()
                        Text("4,000 m")
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(CrocoTheme.muted)
                }
            }
            primaryButton("Ride again", icon: "arrow.clockwise", id: "rideAgain") { session.start(session.mode) }
            HStack(spacing: 10) {
                menuAction("Rankings", icon: "trophy.fill", id: "resultsRankings") { panel = .rankings }
                menuAction("Home", icon: "house.fill", id: "home") { session.goHome() }
            }
        }
    }

    private func resultStat(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).font(.system(size: 16, weight: .bold)).foregroundStyle(CrocoTheme.orange)
            Text(value).font(.system(size: 18, weight: .black, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
                .monospacedDigit()
            Text(title).font(.system(size: 8, weight: .heavy, design: .monospaced)).foregroundStyle(CrocoTheme.muted)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(11)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 14))
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
                VStack(alignment: .leading, spacing: 18) {
                    Text("Ride with Rocco")
                        .font(.title2.bold()).foregroundStyle(.white)
                    Text("This preview introduces Rocco's new movement and falls. The other riders will return after their animations are adapted. All nine worlds are available.")
                        .font(.subheadline).foregroundStyle(CrocoTheme.muted)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 14)], spacing: 14) {
                        ForEach(GameCatalog.playableRiders) { rider in
                            catalogCard(
                                id: rider.id, name: rider.name, asset: rider.assetName,
                                selected: session.characterID == rider.id, rider: true
                            ) {
                                session.characterID = rider.id
                                panel = nil
                            }
                        }
                    }
                }.padding(18)
            }.background(CrocoTheme.ink)
        case .worlds:
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 14)], spacing: 14) {
                    ForEach(GameCatalog.worlds) { world in
                        catalogCard(
                            id: world.id, name: world.name, asset: world.assetName,
                            selected: session.worldID == world.id
                        ) {
                            session.worldID = world.id
                            panel = nil
                        }
                    }
                }.padding(18)
            }.background(CrocoTheme.ink)
        case .settings: SettingsPanel(session: session) { panel = nil }
        case .rankings: RankingsPanel(session: session)
        case .help:
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    helpRow(
                        "arrow.right", "Right thumb",
                        "Accelerate and lean back as a wheel lifts. Use short bursts to control wheelies and backward rotation in the air."
                    )
                    helpRow(
                        "arrow.left", "Left thumb",
                        "Brake and lean forward as a wheel lifts. Catch a wheelie or control forward rotation in the air. Release to coast.")
                    helpRow(
                        "hand.tap.fill", "Touch controls",
                        "Hold the right grip to accelerate or the left brake lever to slow down. Each button applies full power while held; lift your thumb to release. Use short presses for finer control. Both buttons can be held together."
                    )
                    helpRow(
                        "arrow.down.right", "Land with the slope",
                        "Match the bike to the landing. Suspension absorbs a measured impact; a hard sideways landing can end your ride. Flips count only when you land safely."
                    )
                    helpRow(
                        "calendar", "One week. One trail.",
                        "The 4,000-metre challenge changes every Monday at 00:00 UTC. One life, no time limit. Finish to enter the weekly score and time leaderboards."
                    )
                    helpRow(
                        "wifi.slash", "Ride anywhere",
                        "Both game modes work offline. Open Rankings to connect and compare scores."
                    )
                }.padding(24)
            }.background(CrocoTheme.ink)
        }
    }

    private func catalogCard(
        id: String, name: String, asset: String, selected: Bool, rider: Bool = false, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    Group {
                        if rider {
                            RiderArtworkView(riderID: id, animated: selected).frame(height: 116)
                        } else if let image = GameAssets.image(named: asset) {
                            GeometryReader { geometry in
                                Image(uiImage: image).resizable().scaledToFill()
                                    .frame(width: geometry.size.width, height: 116).clipped()
                            }.frame(height: 116)
                        }
                    }.frame(maxWidth: .infinity).background(.white.opacity(0.025))
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .bold)).foregroundStyle(
                            selected ? CrocoTheme.lime : .white.opacity(0.6)
                        )
                        .background(CrocoTheme.ink.opacity(0.8), in: Circle()).padding(9)
                }
                Text(name).font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.6).layoutPriority(1).frame(
                        maxWidth: .infinity, alignment: .leading
                    )
                    .padding(.horizontal, 12).frame(height: 45)
            }.background(.white.opacity(selected ? 0.10 : 0.035), in: RoundedRectangle(cornerRadius: 18))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18).stroke(
                        selected ? CrocoTheme.lime : .white.opacity(0.12), lineWidth: selected ? 2 : 1))
        }.foregroundStyle(.white).accessibilityIdentifier("select-\(id)")
            .accessibilityLabel(name).accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func helpRow(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon).foregroundStyle(CrocoTheme.lime).font(.title2).frame(width: 28)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(text).font(.body).foregroundStyle(CrocoTheme.muted)
            }
        }
    }
    private func panelTitle(_ item: GamePanel) -> String {
        switch item {
        case .riders: "Riders"
        case .worlds: "Worlds"
        case .settings: "Settings"
        case .rankings: "Rankings"
        case .help: "How to play"
        }
    }
    private func timeString(_ seconds: Double) -> String {
        String(format: "%d:%02d", Int(seconds) / 60, Int(seconds) % 60)
    }
}

private struct ScoreCounter: View {
    let score: Int
    let reducedMotion: Bool
    @State private var shown = 0
    var body: some View {
        Text(shown.formatted()).font(.system(size: 58, weight: .black, design: .rounded))
            .foregroundStyle(CrocoTheme.lime).monospacedDigit().contentTransition(.numericText())
            .lineLimit(1).minimumScaleFactor(0.55).accessibilityIdentifier("finalScore").accessibilityLabel(
                "\(score.formatted()) points"
            )
            .task(id: score) {
                if reducedMotion {
                    shown = score
                    return
                }
                for step in 1...24 {
                    do { try await Task.sleep(for: .milliseconds(25)) } catch { return }
                    withAnimation(.easeOut(duration: 0.08)) {
                        shown = Int(Double(score) * (1 - pow(1 - Double(step) / 24, 3)))
                    }
                }
                shown = score
            }
    }
}

/// Shared dismissal action, anchored outside each panel's scrolling content.
struct PanelCloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "checkmark").font(.system(size: 18, weight: .bold))
                .frame(width: 48, height: 48)
                .foregroundStyle(.white.opacity(0.9))
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.16), lineWidth: 1))
        }.buttonStyle(.plain).accessibilityLabel("Close").accessibilityIdentifier("closePanel")
    }
}
