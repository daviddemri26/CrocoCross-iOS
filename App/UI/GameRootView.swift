import CrocoCrossCore
import SpriteKit
import SwiftUI

private enum GamePanel: String, Identifiable {
    case riders, worlds, settings, help, rankings, achievements
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
    @State private var showingKenjiUnlock = false
    @State private var showingJapanUnlock = false
    @State private var showingUnlockError = false
    @State private var unlockErrorMessage: String?
    private var showingUnlock: Bool { showingKenjiUnlock || showingJapanUnlock }

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
                    if session.showingFinishCelebration {
                        VStack {
                            Spacer().frame(height: geometry.size.height * 0.24)
                            Label("FINISH!", systemImage: "flag.checkered")
                                .font(.custom("AvenirNextCondensed-HeavyItalic", size: 28))
                                .foregroundStyle(CrocoTheme.lime)
                                .padding(.horizontal, 22).padding(.vertical, 10)
                                .background(CrocoTheme.ink.opacity(0.85), in: Capsule())
                                .accessibilityIdentifier("finishCelebration")
                            Spacer()
                        }.allowsHitTesting(false)
                    }
                    if session.phase == .paused { pauseOverlay }
                    if session.phase == .results && session.resultsVisible {
                        resultsOverlay.transition(.opacity.combined(with: .scale(scale: 0.94)))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .top) {
                if let notice = session.achievementNotice {
                    AchievementToast(notice: notice)
                        .padding(.horizontal, 20)
                        .padding(.top, session.phase == .playing ? 142 : 12)
                        .transition(.opacity)
                        .task(id: notice.id) {
                            do { try await Task.sleep(for: .seconds(3)) } catch { return }
                            if session.achievementNotice?.id == notice.id {
                                withAnimation(reducedMotion ? nil : .easeOut(duration: 0.18)) {
                                    session.achievementNotice = nil
                                }
                            }
                        }
                }
            }
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
                showingKenjiUnlock = false
                showingJapanUnlock = false
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
                        .accessibilityHidden(showingUnlock)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if item != .settings && !showingUnlock {
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
                .overlay {
                    if showingKenjiUnlock {
                        KenjiUnlockView {
                            session.selectRider("shiba")
                            showingKenjiUnlock = false
                            panel = nil
                        } dismiss: {
                            showingKenjiUnlock = false
                        }
                    } else if showingJapanUnlock {
                        JapanUnlockView {
                            session.selectWorld("japan")
                            showingJapanUnlock = false
                            panel = nil
                        } dismiss: {
                            showingJapanUnlock = false
                        }
                    }
                }
                .navigationTitle(panelTitle(item))
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.large]).presentationDragIndicator(.visible)
            .interactiveDismissDisabled(showingUnlock)
            .alert("Progress not saved", isPresented: $showingUnlockError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(unlockErrorMessage ?? "Please try again.")
            }
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
        .overlay(alignment: .topTrailing) {
            SoundToggleButton(audio: session.audio, compact: true, identifier: "homeSoundToggle")
                .padding(.trailing, 16).padding(.top, 8)
        }
    }

    private var brand: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let image = GameAssets.image(named: "crococross-logo-768") {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 150)
            } else {
                Text("CROCO\nCROSS").font(.system(size: 53, weight: .black, design: .rounded)).italic().lineSpacing(-8)
            }

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
        VStack(spacing: 9) {
            HStack(spacing: 12) {
                LaunchTile(weekly: true, reducedMotion: reducedMotion, worldName: "Canyon") { session.start(.weekly) }
                LaunchTile(weekly: false, reducedMotion: reducedMotion, worldName: GameCatalog.world(session.worldID).name) { session.start(.endless) }
            }
            HStack(alignment: .top, spacing: 12) {
                Text("Same course for everyone.")
                    .accessibilityIdentifier("weeklyCourseInfo")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("New random course every ride.")
                    .accessibilityIdentifier("endlessCourseInfo")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.font(.system(size: 11, weight: .medium)).foregroundStyle(CrocoTheme.muted)
                .fixedSize(horizontal: false, vertical: true).padding(.horizontal, 5)
        }
    }

    private var utilityBar: some View {
        HStack(spacing: 8) {
            utility("Rankings", icon: "trophy.fill", id: "rankings") { panel = .rankings }
            utility("Achievements", icon: "medal.fill", id: "achievements") { panel = .achievements }
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
                Text(title).font(.system(size: 11, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
            }.frame(maxWidth: .infinity).frame(height: 64).contentShape(Rectangle())
        }.buttonStyle(.plain).foregroundStyle(.white.opacity(0.88)).accessibilityIdentifier(id)
    }

    private func playOverlay(wide: Bool, height: CGFloat) -> some View {
        let pedalSize: CGFloat = wide ? 124 : 112
        let zoneHeight = wide ? min(190, max(144, height * 0.42)) : min(240, max(180, height * 0.30))
        return ZStack(alignment: .bottom) {
            HStack(spacing: 0) {
                PedalControl(
                    right: false, diameter: pedalSize, enabled: session.phase == .playing && !session.recovering,
                    resetToken: session.pedalReset
                ) { session.setPedal(right: false, pressed: $0) }
                    .frame(maxWidth: .infinity).frame(height: zoneHeight)
                Color.clear.frame(width: 64, height: 1).allowsHitTesting(false)
                PedalControl(
                    right: true, diameter: pedalSize, enabled: session.phase == .playing && !session.recovering,
                    resetToken: session.pedalReset
                ) { session.setPedal(right: true, pressed: $0) }
                    .frame(maxWidth: .infinity).frame(height: zoneHeight)
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
                            Text(session.activeWorldName)
                                .font(.system(size: 9, weight: .semibold)).foregroundStyle(CrocoTheme.muted)
                                .lineLimit(1).accessibilityIdentifier("activeWorld")
                            Text(session.score.formatted()).font(.custom("AvenirNextCondensed-HeavyItalic", size: 36))
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
                    HStack(spacing: 6) {
                        Color.clear.frame(width: 70, height: 24)
                        stuntNotice.frame(maxWidth: .infinity)
                        livesRow(wide: wide)
                    }.frame(height: 24)
                }.padding(.horizontal, 14).padding(.vertical, 8)
                    .frame(maxWidth: 560)
                    .background(CrocoTheme.ink.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
                if session.mode == .weekly {
                    GeometryReader { geo in
                        Capsule().fill(CrocoTheme.ink.opacity(0.6))
                        Capsule().fill(CrocoTheme.lime).frame(
                            width: geo.size.width * session.weeklyProgress)
                    }.frame(height: 4).accessibilityLabel("Course progress").accessibilityValue(
                        "\(session.weeklyProgressPercent) percent")
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

    @ViewBuilder private var stuntNotice: some View {
        if let text = session.eventText {
            HStack(spacing: 5) {
                Image(systemName: session.eventRotatesForward ? "arrow.clockwise" : "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .black))
                Text(text).font(.custom("AvenirNextCondensed-HeavyItalic", size: 17))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }.foregroundStyle(CrocoTheme.lime)
                .accessibilityElement(children: .combine).accessibilityIdentifier("stuntNotice")
                .transition(.opacity)
        } else { Color.clear.frame(height: 24) }
    }

    private func livesRow(wide: Bool) -> some View {
        let capacity = session.mode == .endless ? 3 : 1
        let remaining = min(capacity, max(0, session.lives))
        return HStack(spacing: 7) {
            // Stable indices remove the LEFTMOST surviving heart. No empty slots.
            ForEach((capacity - remaining)..<capacity, id: \.self) { _ in
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .bold)).foregroundStyle(CrocoTheme.orange)
                    .frame(width: 20, height: 24)
                    .transition(.asymmetric(insertion: .opacity,
                        removal: reducedMotion ? .opacity : .offset(y: 42).combined(with: .opacity)))
            }
        }
        .frame(width: 74, height: 24, alignment: .trailing)
        .animation(.easeIn(duration: reducedMotion ? 0.2 : 0.7), value: remaining)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Lives")
        .accessibilityValue("\(remaining) of \(capacity) remaining")
        .accessibilityIdentifier("lives")
    }

    private var pauseOverlay: some View {
        modal {
            Text("PAUSED").font(.system(size: 27, weight: .black, design: .rounded)).italic()
            HStack(spacing: 10) {
                menuAction("Restart", icon: "arrow.counterclockwise", id: "restart") { session.start(session.mode) }
                menuAction("Settings", icon: "slider.horizontal.3", id: "pauseSettings") { panel = .settings }
                menuAction("Home", icon: "house.fill", id: "home") { session.goHome() }
            }
            primaryButton("Keep riding", icon: "play.fill", id: "resume") { session.resume() }
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
            VStack(spacing: 6) {
                Text(session.finished ? "FINISH!" : "GAME OVER")
                    .font(.custom("AvenirNextCondensed-HeavyItalic", size: 46))
                    .tracking(1).foregroundStyle(CrocoTheme.orange)
                    .shadow(color: .black.opacity(0.8), radius: 0, x: 2, y: 3)
                    .frame(maxWidth: .infinity).accessibilityIdentifier("resultHeading")
                if session.newRecord {
                    Label("NEW BEST", systemImage: "trophy.fill")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(CrocoTheme.ink).padding(.horizontal, 10).padding(.vertical, 5)
                        .background(CrocoTheme.orange, in: Capsule())
                }
                ScoreCounter(score: session.score, reducedMotion: reducedMotion,
                             fontSize: session.mode == .weekly && !session.finished ? 42 : 72)
                    .frame(maxWidth: .infinity)
                Text("TOTAL SCORE").font(.custom("AvenirNextCondensed-HeavyItalic", size: 18))
                    .tracking(2).foregroundStyle(CrocoTheme.muted)
                if session.mode == .weekly && !session.finished {
                    Text("Reach the finish line to validate your score.")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white).multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6).accessibilityIdentifier("unvalidatedScoreMessage")
                }
            }.frame(maxWidth: .infinity)
            HStack(spacing: 10) {
                resultStat("DISTANCE", value: "\((Double(session.distancePoints) / 10).formatted(.number.precision(.fractionLength(1)))) m",
                           points: session.distancePoints, icon: "point.bottomleft.forward.to.point.topright.scurvepath")
                resultStat("FLIPS", value: "\(session.flips) landed",
                           points: session.flipPoints, icon: "arrow.clockwise")
            }
            HStack {
                Label(timeString(session.elapsed), systemImage: "stopwatch")
                Spacer()
                if session.finished { Text("FINISH +\(session.finishPoints.formatted())") }
                else if session.mode == .weekly { Text("\(session.weeklyProgressPercent)% OF \(GameSession.weeklyDistanceText) m") }
            }.font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(CrocoTheme.muted)
            HStack(spacing: 10) {
                menuAction("Rankings", icon: "trophy.fill", id: "resultsRankings") { panel = .rankings }
                menuAction("Home", icon: "house.fill", id: "home") { session.goHome() }
            }
            Button { session.start(session.mode) } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 26, weight: .black))
                    Text("RIDE AGAIN").font(.custom("AvenirNextCondensed-HeavyItalic", size: 30)).tracking(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right.2").font(.system(size: 18, weight: .black))
                }.padding(.horizontal, 22).frame(maxWidth: .infinity).frame(height: 80)
                    .foregroundStyle(CrocoTheme.ink)
                    .background(LinearGradient(colors: [CrocoTheme.lime, Color(red: 0.57, green: 0.83, blue: 0.16)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.4), lineWidth: 1.5))
                    .shadow(color: CrocoTheme.lime.opacity(0.17), radius: 12, y: 5)
            }.accessibilityIdentifier("rideAgain").accessibilityLabel("Ride again")
        }
    }

    private func resultStat(_ title: String, value: String, points: Int, icon: String) -> some View {
        VStack(spacing: 7) {
            Label(title, systemImage: icon).font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundStyle(CrocoTheme.muted)
            Text("+\(points.formatted())").font(.custom("AvenirNextCondensed-HeavyItalic", size: 27))
                .foregroundStyle(CrocoTheme.lime).monospacedDigit().lineLimit(1).minimumScaleFactor(0.65)
                .accessibilityIdentifier(title == "DISTANCE" ? "distancePoints" : "flipPoints")
            Text(value).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.white)
        }.frame(maxWidth: .infinity).padding(.vertical, 13)
            .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 16))
    }

    private func modal<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16, content: content)
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
                    if let error = session.riderProgression.saveError {
                        Text(error).font(.footnote).foregroundStyle(CrocoTheme.orange)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 14)], spacing: 14) {
                        ForEach(GameCatalog.riders) { rider in
                            CatalogCard(
                                id: rider.id, name: rider.name, subtitle: rider.subtitle, asset: rider.assetName,
                                availability: session.riderAvailability(rider.id), selected: session.characterID == rider.id, rider: true
                            ) {
                                let availability = session.riderAvailability(rider.id)
                                if rider.id == "shiba" && availability.isReadyToUnlock {
                                    if session.claimKenji() { showingKenjiUnlock = true }
                                    else {
                                        unlockErrorMessage = session.riderProgression.saveError
                                        showingUnlockError = true
                                    }
                                } else if availability.isUnlocked {
                                    session.selectRider(rider.id)
                                    panel = nil
                                }
                            }
                        }
                    }
                }.padding(18)
            }.background(CrocoTheme.ink)
        case .worlds:
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let error = session.worldProgression.saveError {
                        Text(error).font(.footnote).foregroundStyle(CrocoTheme.orange)
                    }
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 14)], spacing: 14) {
                        ForEach(GameCatalog.worlds) { world in
                            CatalogCard(
                                id: world.id, name: world.name, subtitle: world.subtitle, asset: world.assetName,
                                availability: session.worldAvailability(world.id), selected: session.worldID == world.id,
                                recordText: world.course.supportsLeaderboards ? "\(session.bestEndless(for: world.id).formatted()) pts" : nil,
                                leaderboardAction: world.course.supportsLeaderboards ? {
                                    if session.gameCenter.isAuthenticated { session.showEndlessLeaderboard(worldID: world.id) }
                                    else { session.gameCenter.authenticate() }
                                } : nil,
                                leaderboardEnabled: !session.gameCenter.isAuthenticated || session.gameCenter.isEndlessLeaderboardConfirmed(for: world.course),
                                leaderboardStatus: session.gameCenter.isAuthenticated ? "Compare Endless scores in Game Center." : "Connect with Game Center."
                            ) {
                                let availability = session.worldAvailability(world.id)
                                if world.id == "japan" && availability.isReadyToUnlock {
                                    if session.claimJapan() { showingJapanUnlock = true }
                                    else {
                                        unlockErrorMessage = session.worldProgression.saveError
                                        showingUnlockError = true
                                    }
                                } else if availability.isUnlocked {
                                    session.selectWorld(world.id)
                                    panel = nil
                                }
                            }
                        }
                    }
                }.padding(18)
            }.background(CrocoTheme.ink)
        case .settings: SettingsPanel(session: session) { panel = nil }
        case .rankings: RankingsPanel(session: session) { panel = .worlds }
        case .achievements: AchievementsPanel(session: session)
        case .help: HowToView()
        }
    }

    private func panelTitle(_ item: GamePanel) -> String {
        switch item {
        case .riders: "Riders"
        case .worlds: "Worlds"
        case .settings: "Settings"
        case .rankings: "Rankings"
        case .achievements: "Achievements"
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
    let fontSize: CGFloat
    @State private var shown = 0
    var body: some View {
        Text(shown.formatted()).font(.custom("AvenirNextCondensed-HeavyItalic", size: fontSize))
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
