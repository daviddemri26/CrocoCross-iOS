import CrocoCrossCore
import Foundation
import Observation
import SpriteKit

@MainActor @Observable
final class GameSession {
    enum Phase { case home, playing, paused, results }
    var phase: Phase = .home
    var mode: RunMode = .weekly
    var score = 0
    static var weeklyDistanceText: String {
        Int(GameSimulation.weeklyDistance).formatted(.number.locale(Locale(identifier: "en_US")))
    }
    var weeklyProgress: Double { min(1, max(0, distance / GameSimulation.weeklyDistance)) }
    var weeklyProgressPercent: Int { Int(weeklyProgress * 100) }
    var distance: Double = 0
    var elapsed: Double = 0
    var speed: Double = 0
    var lives = 1
    var flips = 0
    var distancePoints: Int { Int(floor(distance * 10)) }
    var finishPoints: Int { finished ? 1_000 : 0 }
    var flipPoints: Int { max(0, score - distancePoints - finishPoints) }
    var eventRotatesForward = false
    var finished = false
    var recovering = false
    var showingFinalExplosion: Bool { phase == .results && !finished && mode == .endless }
    var showingCrash: Bool { (phase == .playing && recovering) || (phase == .results && !finished && !showingFinalExplosion) }
    var showingFinishCelebration: Bool { phase == .results && finished && !resultsVisible }
    var ranked = false
    var pedalReset = 0
    var eventText: String?
    var eventPoints = 0
    var resultsVisible = false
    var newRecord = false
    var characterID: String { didSet { defaults.set(characterID, forKey: CompetitionRules.riderPreferenceKey) } }
    private(set) var worldID: String { didSet { defaults.set(worldID, forKey: "world") } }
    var bestWeekly: Int { didSet { defaults.set(bestWeekly, forKey: CompetitionRules.weeklyRecordKey) } }
    private(set) var bestEndless: Int
    private(set) var runCourse = WorldCoursePlan.weekly
    var activeWorldName: String { GameCatalog.world(runCourse.worldID).name }
    let scene = GameScene(size: CGSize(width: 390, height: 844))
    let gameCenter = GameCenterService()
    let audio = AudioService()
    let riderProgression: RiderProgression
    let worldProgression: WorldProgression
    let achievements: AchievementProgression
    let weeklyRecords: WeeklyRecordStore
    struct AchievementNotice: Identifiable {
        let id = UUID()
        let unlocked: [AchievementDefinition]
    }
    var achievementNotice: AchievementNotice?
    @ObservationIgnored private var progressionRunID = UUID()
    @ObservationIgnored private var achievementRunPlayerID: String?
    #if DEBUG
    @ObservationIgnored private var unlockLandingFixtureActive = false
    @ObservationIgnored private var unlockFixtureDirection = 1.0
    @ObservationIgnored private var unlockFixtureAngle = 0.0
    @ObservationIgnored private var unlockFixturePreviousAngle = 0.0
    #endif
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var simulation = GameSimulation(mode: .endless, seed: 42)
    @ObservationIgnored private let previewSimulation = GameSimulation(mode: .endless, seed: 42)
    @ObservationIgnored private var previousState = SimulationState(mode: .endless, seed: 42)
    @ObservationIgnored private var input = ControlInput.neutral
    @ObservationIgnored private var accumulator: Double = 0
    @ObservationIgnored private var riderMotionSeconds: Double = 0
    @ObservationIgnored private var shownRiderMotionSeconds: Double = 0
    @ObservationIgnored private var recoveryExtraSteps = 0
    @ObservationIgnored private var lastHUD: Double = 0
    @ObservationIgnored private var lastSubmissionTick = 0
    @ObservationIgnored private var resultsAt: Double = 0
    @ObservationIgnored private var recordToBeat = 0
    @ObservationIgnored private var eventUntil: Double = 0
    @ObservationIgnored private var frameTime: Double = 0
    @ObservationIgnored private var playerID: String?
    @ObservationIgnored private var wasRankedAtStart = false
    @ObservationIgnored private var challenge: WeeklyChallenge?
    @ObservationIgnored private var reducedMotion = false
    @ObservationIgnored private var interrupted = false
    @ObservationIgnored private var discardNextPlayingDelta = false
    @ObservationIgnored private var awaitingFirstSimulationStep = true
    @ObservationIgnored private var crashPresentationSteps = 0
    @ObservationIgnored private var recoveryPresentationSteps = 0
    @ObservationIgnored private var deathHoldRemaining: TimeInterval = 0
    @ObservationIgnored private var crashPresentationStepLimit = 216

    init() {
        let prefs = UserDefaults.standard
        precondition(CompetitionRules.version == GameSimulation.engineVersion)
        let progression = RiderProgression.forCurrentLaunch()
        riderProgression = progression
        let worlds = WorldProgression.forCurrentLaunch()
        worldProgression = worlds
        achievements = AchievementProgression.forCurrentLaunch()
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ui-testing") {
            let index = arguments.firstIndex(of: "-weekly-record-test-id")
            let testID = index.flatMap { arguments.indices.contains($0 + 1) ? arguments[$0 + 1] : nil } ?? UUID().uuidString
            weeklyRecords = WeeklyRecordStore(defaults: UserDefaults(suiteName: "CrocoCross.WeeklyRecords.UITests.\(testID)")!)
        } else { weeklyRecords = WeeklyRecordStore() }
        #else
        weeklyRecords = WeeklyRecordStore()
        #endif
        let preferredRider = prefs.string(forKey: CompetitionRules.riderPreferenceKey) ?? "croco"
        characterID = GameCatalog.playableRiders(progression: progression).contains(where: { $0.id == preferredRider })
            ? preferredRider : "croco"
        let preferredWorld = prefs.string(forKey: "world") ?? "canyon"
        let selectedWorld = GameCatalog.playableWorlds(progression: worlds).contains(where: { $0.id == preferredWorld })
            ? preferredWorld : "canyon"
        worldID = selectedWorld
        bestWeekly = prefs.integer(forKey: CompetitionRules.weeklyRecordKey)
        bestEndless = prefs.integer(forKey: GameCatalog.world(selectedWorld).course.endlessRecordKey)
        // Legacy rider selection, records and pending scores remain untouched.
        scene.scaleMode = .resizeFill
        scene.onFrame = { [weak self] dt in self?.frame(dt) }
        achievements.importClaimedUnlocks(
            riderIDs: progression.state.kenjiClaimed ? ["shiba"] : [],
            worldIDs: worlds.state.japanClaimed ? ["japan"] : [], at: Date())
        gameCenter.achievementProgressProvider = { [weak self] playerID in
            self?.achievements.gameCenterProgress(for: playerID) ?? [:]
        }
        gameCenter.achievementRemoteProgressHandler = { [weak self] playerID, progress, dates in
            self?.achievements.mergeRemoteProgress(progress, playerID: playerID, completionDates: dates)
        }
    }

    func start(_ mode: RunMode) {
        audio.stopDeathSound()
        deathHoldRemaining = 0
        recoveryPresentationSteps = 0
        if !riderAvailability(characterID).isUnlocked { characterID = "croco" }
        riderProgression.flush()
        worldProgression.flush()
        achievements.flush()
        progressionRunID = UUID()
        if !worldAvailability(worldID).isUnlocked {
            worldID = "canyon"
            bestEndless = defaults.integer(forKey: CompetitionRules.endlessRecordKey)
        }
        runCourse = mode == .weekly ? .weekly : GameCatalog.world(worldID).course
        self.mode = mode
        recordToBeat = bestEndless
        newRecord = false
        resultsVisible = false
        scene.clearTransientEffects()
        let confirmedWeek = gameCenter.weeklyChallenge.flatMap { $0.contains(Date()) ? $0 : nil }
        challenge = mode == .weekly ? (confirmedWeek ?? .practice(now: Date())) : nil
        if let challenge {
            recordToBeat = weeklyRecords.record(for: challenge.identifier).score ?? 0
            if gameCenter.weeklyRecordsChallengeIdentifier == challenge.identifier,
               let remote = gameCenter.weeklyScoreRecord { recordToBeat = max(recordToBeat, remote.score) }
        }
        playerID = gameCenter.currentPlayerID
        achievementRunPlayerID = gameCenter.currentPlayerID
        wasRankedAtStart = runCourse.supportsLeaderboards && playerID != nil
            && (mode == .endless ? gameCenter.isEndlessLeaderboardConfirmed(for: runCourse) : confirmedWeek != nil)
        ranked = wasRankedAtStart
        let seed = challenge?.seed ?? UInt32.random(in: 1...UInt32.max)
        var configuration = PhysicsConfiguration()
        configuration.terrainStyle = runCourse.terrainStyle
        simulation = GameSimulation(mode: mode, seed: seed, configuration: configuration)
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if mode == .weekly && arguments.contains("-ui-testing") && arguments.contains("-finish-preview") {
            simulation = .finishFixtureForTesting(airborne: arguments.contains("-finish-preview-airborne"))
            wasRankedAtStart = false
            ranked = false
        }
        let frontflipFixture = arguments.contains("-world-unlock-landing-preview")
        unlockLandingFixtureActive = arguments.contains("-ui-testing")
            && (arguments.contains("-unlock-landing-preview") || frontflipFixture)
        if unlockLandingFixtureActive {
            unlockFixtureDirection = frontflipFixture ? -1 : 1
            simulation = frontflipFixture ? .frontflipFixtureForTesting(mode: mode) : .backflipFixtureForTesting(mode: mode)
            unlockFixtureAngle = 0
            unlockFixturePreviousAngle = simulation.state.bike.angle
            wasRankedAtStart = false
            ranked = false
        }
        #endif
        previousState = simulation.state
        accumulator = 0
        riderMotionSeconds = 0
        shownRiderMotionSeconds = 0
        recoveryExtraSteps = 0
        crashPresentationSteps = 0
        lastSubmissionTick = 0
        clearPedals()
        discardNextPlayingDelta = true
        awaitingFirstSimulationStep = true
        eventText = nil
        eventPoints = 0
        finished = false
        phase = .playing
        interrupted = false
        audio.setPaused(false)
        audio.startMusic()
        refreshHUD()
    }

    func riderAvailability(_ id: String) -> CatalogAvailability {
        GameCatalog.riderAvailability(id, progression: riderProgression)
    }

    func selectRider(_ id: String) {
        guard riderAvailability(id).isUnlocked else { return }
        characterID = id
    }

    func claimKenji() -> Bool {
        guard riderProgression.claimKenji() else { return false }
        announceAchievements(achievements.recordUnlock(kind: .rider, catalogID: "shiba",
            playerID: gameCenter.currentPlayerID, at: Date()))
        audio.playUnlockCelebration()
        return true
    }

    func worldAvailability(_ id: String) -> CatalogAvailability {
        GameCatalog.worldAvailability(id, progression: worldProgression)
    }

    func selectWorld(_ id: String) {
        guard phase == .home, worldAvailability(id).isUnlocked else { return }
        worldID = id
        bestEndless = defaults.integer(forKey: GameCatalog.world(id).course.endlessRecordKey)
    }

    func claimJapan() -> Bool {
        guard worldProgression.claimJapan() else { return false }
        announceAchievements(achievements.recordUnlock(kind: .world, catalogID: "japan",
            playerID: gameCenter.currentPlayerID, at: Date()))
        audio.playUnlockCelebration()
        return true
    }

    func setPedal(right: Bool, pressed: Bool) {
        guard phase == .playing, simulation.state.status == .active else {
            input = .neutral
            return
        }
        let value = pressed ? 1.0 : 0.0
        if right { input.throttle = value } else { input.brake = value }
        input.lean = input.throttle - input.brake
    }

    func pause() {
        guard phase == .playing else { return }
        riderProgression.flush()
        worldProgression.flush()
        achievements.flush()
        phase = .paused
        audio.pauseDeathSound()
        clearPedals()
        accumulator = 0
        audio.setPaused(true)
        submitProgress()
    }

    func resume() {
        guard phase == .paused else { return }
        clearPedals()
        accumulator = 0
        discardNextPlayingDelta = true
        awaitingFirstSimulationStep = true
        if let challenge, Date() >= challenge.end {
            ranked = false
        }
        phase = .playing
        interrupted = false
        audio.setPaused(false)
        audio.resumeDeathSound()
    }

    func goHome() {
        riderProgression.flush()
        worldProgression.flush()
        achievements.flush()
        audio.stopDeathSound()
        deathHoldRemaining = 0
        recoveryPresentationSteps = 0
        if phase == .playing || phase == .paused { submitProgress() }
        phase = .home
        accumulator = 0
        crashPresentationSteps = 0
        discardNextPlayingDelta = true
        awaitingFirstSimulationStep = true
        resultsVisible = false
        newRecord = false
        finished = false
        eventText = nil
        eventPoints = 0
        wasRankedAtStart = false
        ranked = false
        playerID = nil
        achievementRunPlayerID = nil
        challenge = nil
        simulation = GameSimulation(mode: mode, seed: 42)
        previousState = simulation.state
        lastSubmissionTick = 0
        refreshHUD()
        scene.clearTransientEffects()
        clearPedals()
        audio.setPaused(true)
    }

    /// A transient inactive state pauses; actually leaving the app abandons the ride.
    func leaveApp() {
        goHome()
        interrupted = true
        audio.shutdown()
    }

    func setActive(_ active: Bool) {
        if !active {
            pause()
            interrupted = true
            audio.shutdown()
        } else {
            interrupted = false
            // Do not integrate an inactive interval into the crash presentation.
            accumulator = 0
            audio.startMusic()
            if phase == .results { audio.resumeDeathSound() }
            Task { await gameCenter.refresh() }
        }
    }

    func setReducedMotion(_ enabled: Bool) { reducedMotion = enabled }

    func currentWeeklyChallenge(now: Date = Date()) -> WeeklyChallenge {
        gameCenter.weeklyChallenge.flatMap { $0.contains(now) ? $0 : nil } ?? .practice(now: now)
    }

    func bestEndless(for worldID: String) -> Int {
        if worldID == self.worldID { return bestEndless }
        return defaults.integer(forKey: GameCatalog.world(worldID).course.endlessRecordKey)
    }

    func showEndlessLeaderboard(worldID: String) {
        pause()
        gameCenter.showLeaderboards(course: GameCatalog.world(worldID).course)
    }

    func showWeeklyLeaderboard(time: Bool) {
        pause()
        gameCenter.showWeeklyLeaderboard(time: time)
    }

    func showLeaderboards(endlessForSelectedWorld: Bool = false) {
        pause()
        gameCenter.showLeaderboards(course: endlessForSelectedWorld ? GameCatalog.world(worldID).course : nil)
    }

    private func frame(_ rawDelta: Double) {
        let dt = rawDelta.isFinite ? max(0, min(rawDelta, 0.1)) : 0
        if !interrupted { frameTime += dt }
        if !interrupted && (phase == .playing || phase == .results) {
            deathHoldRemaining = max(0, deathHoldRemaining - dt)
        }
        if phase == .playing && !interrupted {
            // GameScene has established a fresh timestamp for this frame. Its interval
            // may include menu, pause or setup work, so gameplay begins on the next one.
            if discardNextPlayingDelta {
                discardNextPlayingDelta = false
            }
            // Loading the first track frame can take longer than one interval.
            // Drop that startup time; only an already advancing ride should pause.
            else if rawDelta > 0.25 {
                if !awaitingFirstSimulationStep { pause() }
            } else {
                accumulator += dt * (simulation.state.status == .recovering ? 0.5 : 1)
                var steps = 0
                while accumulator >= 1.0 / 120 && steps < 12 && phase == .playing {
                    let recoveringStep = simulation.state.status == .recovering
                    // Keep detached bodies moving while audio finishes. These extra
                    // presentation steps do not advance recovery, score or game time.
                    if recoveringStep && recoveryPresentationSteps >= 215 &&
                        (deathHoldRemaining > 0 || audio.deathSoundPending) {
                        previousState = simulation.state
                        if recoveryExtraSteps < crashPresentationStepLimit {
                            simulation.stepPresentation(maximumSteps: crashPresentationStepLimit)
                            riderMotionSeconds += GameSimulation.timeStep
                            recoveryExtraSteps += 1
                        }
                        accumulator -= GameSimulation.timeStep
                        steps += 1
                        continue
                    }
                    if recoveringStep { recoveryPresentationSteps += 1 }
                    previousState = simulation.state
                    let events = simulation.step(input: inputForSimulationStep())
                    riderMotionSeconds += GameSimulation.timeStep
                    awaitingFirstSimulationStep = false
                    for event in events { handle(event) }
                    accumulator -= 1.0 / 120
                    steps += 1
                }
                if simulation.state.tick - lastSubmissionTick >= 1_200 { submitProgress() }
                if frameTime - lastHUD >= 0.08 {
                    refreshHUD()
                    lastHUD = frameTime
                }
                audio.update(bike: simulation.state.bike)
            }
        } else if phase == .results && !resultsVisible && !showingFinalExplosion && !interrupted &&
                    crashPresentationSteps < crashPresentationStepLimit {
            // Score, time and outcome are final; only coasting/falling bodies advance.
            if rawDelta <= 0.25 {
                accumulator += dt * GameSimulation.finishPresentationSpeed
                var steps = 0
                while accumulator >= GameSimulation.timeStep && steps < 12 &&
                        crashPresentationSteps < crashPresentationStepLimit {
                    previousState = simulation.state
                    simulation.stepPresentation(maximumSteps: crashPresentationStepLimit)
                    riderMotionSeconds += GameSimulation.timeStep
                    crashPresentationSteps += 1
                    accumulator -= GameSimulation.timeStep
                    steps += 1
                }
            } else { accumulator = 0 }
        }
        if eventText != nil && frameTime > eventUntil {
            eventText = nil
            eventPoints = 0
        }
        if phase == .results && !interrupted && !resultsVisible && frameTime >= resultsAt &&
            deathHoldRemaining <= 0 && !audio.deathSoundPending { resultsVisible = true }
        if !interrupted && (phase == .playing || (phase == .results && !resultsVisible)) {
            // Match the body's interpolated pose, including 120 Hz displays at
            // half speed. Pausing retains the exact last displayed limb pose.
            let canInterpolate = previousState.status == simulation.state.status &&
                crashPresentationSteps < crashPresentationStepLimit && recoveryExtraSteps < crashPresentationStepLimit
            let clock = canInterpolate ? riderMotionSeconds - GameSimulation.timeStep + min(GameSimulation.timeStep, accumulator)
                                       : riderMotionSeconds
            shownRiderMotionSeconds = max(shownRiderMotionSeconds, clock)
        }
        scene.isCrashPaused = phase == .paused || interrupted
        scene.finishCelebrationElapsed = showingFinishCelebration
            ? max(0, GameSimulation.finishPresentationDuration - (resultsAt - frameTime)) : nil
        scene.isPreview = phase == .home
        if phase == .home {
            scene.display(
                state: previewSimulation.state, terrain: previewSimulation.terrainHeight,
                characterID: characterID, worldID: worldID, reducedMotion: reducedMotion)
        } else {
            scene.display(
                state: renderedState(), terrain: simulation.terrainHeight,
                characterID: characterID, worldID: runCourse.worldID, reducedMotion: reducedMotion,
                riderMotionSeconds: shownRiderMotionSeconds)
        }
    }

    private func inputForSimulationStep() -> ControlInput {
        #if DEBUG
        if unlockLandingFixtureActive {
            // The controller from the core physical-flip tests: real Box2D flight and reception,
            // with no synthetic score or progression event. Never active in normal play or Release.
            let bike = simulation.state.bike
            unlockFixtureAngle += atan2(sin(bike.angle - unlockFixturePreviousAngle), cos(bike.angle - unlockFixturePreviousAngle))
            unlockFixturePreviousAngle = bike.angle
            let error = Double.pi * 2 - unlockFixtureAngle * unlockFixtureDirection
            let velocity = bike.angularVelocity * unlockFixtureDirection
            let stopping = velocity * abs(velocity) / (2 * 4.1)
            let lean = bike.grounded ? 0 : error > 1.2 ? (error > stopping + 0.06 ? 1.0 : -1.0)
                : min(1, max(-1, error * 6 - velocity * 2.2))
            return ControlInput(lean: lean * unlockFixtureDirection)
        }
        #endif
        return input
    }

    /// Blend only presentation coordinates; scoring and contact always use fixed-step state.
    private func renderedState() -> SimulationState {
        let physicsIsAdvancing = phase == .playing || (phase == .results && !resultsVisible && !showingFinalExplosion &&
            crashPresentationSteps < crashPresentationStepLimit)
        guard physicsIsAdvancing, !interrupted, previousState.status == simulation.state.status,
            abs(previousState.bike.position.x - simulation.state.bike.position.x) < 2
        else { return simulation.state }
        let alpha = max(0, min(1, accumulator * 120))
        func point(_ a: Vector2, _ b: Vector2) -> Vector2 {
            Vector2(x: a.x + (b.x - a.x) * alpha, y: a.y + (b.y - a.y) * alpha)
        }
        func angle(_ a: Double, _ b: Double) -> Double { a + atan2(sin(b - a), cos(b - a)) * alpha }
        var shown = simulation.state
        let old = previousState.bike
        shown.bike.position = point(old.position, shown.bike.position)
        shown.bike.angle = angle(old.angle, shown.bike.angle)
        shown.bike.rear.position = point(old.rear.position, shown.bike.rear.position)
        shown.bike.front.position = point(old.front.position, shown.bike.front.position)
        shown.bike.rear.angle = angle(old.rear.angle, shown.bike.rear.angle)
        shown.bike.front.angle = angle(old.front.angle, shown.bike.front.angle)
        shown.rider.pelvis.position = point(previousState.rider.pelvis.position, shown.rider.pelvis.position)
        shown.rider.pelvis.angle = angle(previousState.rider.pelvis.angle, shown.rider.pelvis.angle)
        shown.rider.torso.position = point(previousState.rider.torso.position, shown.rider.torso.position)
        shown.rider.torso.angle = angle(previousState.rider.torso.angle, shown.rider.torso.angle)
        return shown
    }

    private func handle(_ event: GameEvent) {
        audio.handle(event: event, finalExplosion: simulation.state.mode == .endless && simulation.state.status == .crashed)
        switch event {
        case .flip(let count):
            announceAchievements(achievements.recordSafeLanding(
                backflips: simulation.landedBackflips, frontflips: simulation.landedFrontflips,
                runID: progressionRunID, tick: simulation.state.tick,
                playerID: achievementRunPlayerID, at: Date()))
            riderProgression.recordLanding(backflips: simulation.landedBackflips,
                runID: progressionRunID, tick: simulation.state.tick)
            worldProgression.recordLanding(frontflips: simulation.landedFrontflips,
                runID: progressionRunID, tick: simulation.state.tick)
            let prefix = count == 2 ? "DOUBLE " : count == 3 ? "TRIPLE " : count > 3 ? "\(count)× " : ""
            eventRotatesForward = simulation.landedFrontflips > 0 && simulation.landedBackflips == 0
            if simulation.landedBackflips > 0 && simulation.landedFrontflips > 0 {
                eventText = "BACK + FRONTFLIP"
            } else {
                eventText = prefix + (eventRotatesForward ? "FRONTFLIP" : "BACKFLIP")
            }
            eventPoints = GameSimulation.flipBonus(for: count)
            eventUntil = frameTime + 1.8
        case .crashed:
            recoveryPresentationSteps = 0
            recoveryExtraSteps = 0
            let terminal = simulation.state.status == .crashed
            let baseDuration = terminal ? (reducedMotion ? 0.3 : mode == .endless ? 1.8 : 3.6) : 3.6
            deathHoldRemaining = max(baseDuration, audio.deathSoundDuration)
            // Budget the half-speed fall for the entire cue, plus one second of
            // scheduling headroom. Core still enforces a hard 600-step ceiling.
            crashPresentationStepLimit = min(600, max(216, Int(ceil(deathHoldRemaining * 60)) + 60))
            scene.playCrash(at: simulation.state.bike.position, impact: min(2, max(0.6, speed / 35)),
                            finalExplosion: simulation.state.mode == .endless && simulation.state.status == .crashed)
            eventText = nil
            eventPoints = 0
            clearPedals()
            refreshHUD()
            if simulation.state.status == .crashed { endRun() }
        case .finished:
            if simulation.state.mode == .weekly {
                announceAchievements(achievements.recordWeeklyFinish(runID: progressionRunID,
                    playerID: achievementRunPlayerID, at: Date()))
            }
            finished = true
            eventText = nil
            eventPoints = 0
            crashPresentationStepLimit = GameSimulation.finishPresentationSteps
            scene.playFinish()
            endRun()
        case .landed(let impact):
            let x = simulation.state.bike.position.x
            scene.playLanding(at: Vector2(x: x, y: simulation.terrainHeight(at: x)), intensity: impact)
        case .respawned:
            audio.stopDeathSound()
            deathHoldRemaining = 0
            scene.restoreBikeAfterRespawn()
            clearPedals()
            eventPoints = 0
            eventText = nil
            eventUntil = 0
        }
    }

    private func refreshHUD() {
        let state = simulation.state
        ranked =
            wasRankedAtStart && playerID == gameCenter.currentPlayerID && playerID != nil
            && (challenge.map { $0.contains(Date()) } ?? true)
        score = state.score
        distance = state.distance
        elapsed = state.elapsed
        lives = state.lives
        flips = state.flips
        speed = hypot(state.bike.velocity.x, state.bike.velocity.y) * 3.6
        recovering = state.status == .recovering
        if phase == .playing { recordAchievementDistance() }
    }

    private func endRun() {
        refreshHUD()
        clearPedals()
        phase = .results
        newRecord = score > recordToBeat && (mode == .endless || finished)
        resultsVisible = false
        crashPresentationSteps = 0
        // Victory is already saved while its five-second celebration plays.
        let baseDuration = finished ? GameSimulation.finishPresentationDuration
            : reducedMotion ? 0.3 : showingFinalExplosion ? 1.8 : 3.6
        resultsAt = frameTime + max(baseDuration, deathHoldRemaining)
        audio.setPaused(true)
        submitProgress()
    }

    private func submitProgress() {
        recordAchievementDistance()
        achievements.flush()
        syncAchievements()
        let state = simulation.state
        if state.mode == .endless {
            let best = max(defaults.integer(forKey: runCourse.endlessRecordKey), state.score)
            defaults.set(best, forKey: runCourse.endlessRecordKey)
            if worldID == runCourse.worldID { bestEndless = best }
        } else if state.status == .finished {
            bestWeekly = max(bestWeekly, state.score)
            if let challenge {
                weeklyRecords.record(score: state.score, elapsed: state.elapsed, challengeIdentifier: challenge.identifier)
            }
        }
        // Pause followed immediately by backgrounding must not enqueue the same tick twice.
        guard state.tick != lastSubmissionTick else { return }
        lastSubmissionTick = state.tick
        if wasRankedAtStart { gameCenter.record(state: state, challenge: challenge, playerID: playerID, course: runCourse) }
    }

    func showAchievements() {
        pause()
        syncAchievements()
        gameCenter.showAchievements()
    }

    private func recordAchievementDistance() {
        guard simulation.state.mode == .endless, simulation.state.tick > 0 else { return }
        announceAchievements(achievements.recordEndlessDistance(simulation.state.distance,
            runID: progressionRunID, playerID: achievementRunPlayerID, at: Date()))
    }

    private func announceAchievements(_ unlocked: [AchievementDefinition]) {
        guard !unlocked.isEmpty else { return }
        achievementNotice = AchievementNotice(unlocked: unlocked)
        syncAchievements()
    }

    func syncAchievements() {
        guard let playerID = gameCenter.currentPlayerID else { return }
        gameCenter.syncAchievements(localProgress: achievements.gameCenterProgress(for: playerID), playerID: playerID)
    }

    private func clearPedals() {
        input = .neutral
        pedalReset &+= 1
    }
}
