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
    var distance: Double = 0
    var elapsed: Double = 0
    var speed: Double = 0
    var lives = 1
    var flips = 0
    var finished = false
    var recovering = false
    var ranked = false
    var pedalReset = 0
    var eventText: String?
    var eventPoints = 0
    var resultsVisible = false
    var newRecord = false
    var characterID: String { didSet { defaults.set(characterID, forKey: "rider") } }
    var worldID: String { didSet { defaults.set(worldID, forKey: "world") } }
    var bestWeekly: Int { didSet { defaults.set(bestWeekly, forKey: "bestWeekly") } }
    var bestEndless: Int { didSet { defaults.set(bestEndless, forKey: "bestEndless") } }
    let scene = GameScene(size: CGSize(width: 390, height: 844))
    let gameCenter = GameCenterService()
    let audio = AudioService()
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var simulation = GameSimulation(mode: .endless, seed: 42)
    @ObservationIgnored private let previewSimulation = GameSimulation(mode: .endless, seed: 42)
    @ObservationIgnored private var previousState = SimulationState(mode: .endless, seed: 42)
    @ObservationIgnored private var input = ControlInput.neutral
    @ObservationIgnored private var accumulator: Double = 0
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

    init() {
        let prefs = UserDefaults.standard
        characterID = prefs.string(forKey: "rider") ?? "croco"
        worldID = prefs.string(forKey: "world") ?? "canyon"
        bestWeekly = prefs.integer(forKey: "bestWeekly")
        bestEndless = prefs.integer(forKey: "bestEndless")
        if let directory = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        {
            // Retire only the old resumable ride; records, preferences and queued scores remain.
            try? FileManager.default.removeItem(at: directory.appendingPathComponent("active-run-v1.json"))
        }
        scene.scaleMode = .resizeFill
        scene.onFrame = { [weak self] dt in self?.frame(dt) }
        if !GameCatalog.riders.contains(where: { $0.id == characterID }) { characterID = "croco" }
        if !GameCatalog.worlds.contains(where: { $0.id == worldID }) { worldID = "canyon" }
    }

    func start(_ mode: RunMode) {
        self.mode = mode
        recordToBeat = mode == .weekly ? bestWeekly : bestEndless
        newRecord = false
        resultsVisible = false
        scene.clearTransientEffects()
        let confirmedWeek = gameCenter.weeklyChallenge.flatMap { $0.contains(Date()) ? $0 : nil }
        challenge = mode == .weekly ? (confirmedWeek ?? .practice(now: Date())) : nil
        playerID = gameCenter.currentPlayerID
        wasRankedAtStart = playerID != nil && (mode == .endless || confirmedWeek != nil)
        ranked = wasRankedAtStart
        let seed = challenge?.seed ?? UInt32.random(in: 1...UInt32.max)
        simulation = GameSimulation(mode: mode, seed: seed)
        previousState = simulation.state
        accumulator = 0
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

    func setPedal(right: Bool, value: Double) {
        guard phase == .playing, simulation.state.status == .active else {
            input = .neutral
            return
        }
        if right { input.throttle = value } else { input.brake = value }
        input.lean = input.throttle - input.brake
    }

    func pause() {
        guard phase == .playing else { return }
        phase = .paused
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
    }

    func goHome() {
        if phase == .playing || phase == .paused { submitProgress() }
        phase = .home
        accumulator = 0
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
            audio.startMusic()
            Task { await gameCenter.refresh() }
        }
    }

    func setReducedMotion(_ enabled: Bool) { reducedMotion = enabled }

    func showLeaderboards() {
        pause()
        gameCenter.showLeaderboards()
    }

    private func frame(_ rawDelta: Double) {
        let dt = rawDelta.isFinite ? max(0, min(rawDelta, 0.1)) : 0
        frameTime += dt
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
                accumulator += dt
                var steps = 0
                while accumulator >= 1.0 / 120 && steps < 12 && phase == .playing {
                    previousState = simulation.state
                    let events = simulation.step(input: input)
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
        }
        if eventText != nil && frameTime > eventUntil {
            eventText = nil
            eventPoints = 0
        }
        if phase == .results && !resultsVisible && frameTime >= resultsAt { resultsVisible = true }
        scene.isPreview = phase == .home
        if phase == .home {
            scene.display(
                state: previewSimulation.state, terrain: previewSimulation.terrainHeight,
                characterID: characterID, worldID: worldID, reducedMotion: reducedMotion)
        } else {
            scene.display(
                state: renderedState(), terrain: simulation.terrainHeight,
                characterID: characterID, worldID: worldID, reducedMotion: reducedMotion)
        }
    }

    /// Blend only presentation coordinates; scoring and contact always use fixed-step state.
    private func renderedState() -> SimulationState {
        guard phase == .playing, previousState.status == simulation.state.status,
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
        return shown
    }

    private func handle(_ event: GameEvent) {
        audio.handle(event: event)
        switch event {
        case .flip(let count):
            let prefix = count == 2 ? "DOUBLE " : count == 3 ? "TRIPLE " : count > 3 ? "\(count)× " : ""
            eventText = "\(prefix)FLIP!"
            eventPoints = GameSimulation.flipBonus(for: count)
            eventUntil = frameTime + 1.8
        case .crashed:
            scene.playCrash(at: simulation.state.bike.position, impact: min(2, max(0.6, speed / 35)))
            eventText = nil
            eventPoints = 0
            clearPedals()
            refreshHUD()
            if simulation.state.status == .crashed { endRun() }
        case .finished:
            finished = true
            endRun()
        case .landed(let impact):
            let x = simulation.state.bike.position.x
            scene.playLanding(at: Vector2(x: x, y: simulation.terrainHeight(at: x)), intensity: impact)
        case .respawned:
            scene.restoreBikeAfterRespawn()
            clearPedals()
            eventPoints = 0
            eventText = "BACK ON TRACK"
            eventUntil = frameTime + 1.3
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
    }

    private func endRun() {
        refreshHUD()
        clearPedals()
        phase = .results
        newRecord = score > recordToBeat && (mode == .endless || finished)
        resultsVisible = false
        // Let the explosion complete before covering the crash with the score card.
        resultsAt = frameTime + (finished || reducedMotion ? 0.3 : 1.8)
        audio.setPaused(true)
        submitProgress()
    }

    private func submitProgress() {
        let state = simulation.state
        if state.mode == .endless {
            bestEndless = max(bestEndless, state.score)
        } else if state.status == .finished {
            bestWeekly = max(bestWeekly, state.score)
        }
        // Pause followed immediately by backgrounding must not enqueue the same tick twice.
        guard state.tick != lastSubmissionTick else { return }
        lastSubmissionTick = state.tick
        if wasRankedAtStart { gameCenter.record(state: state, challenge: challenge, playerID: playerID) }
    }

    private func clearPedals() {
        input = .neutral
        pedalReset &+= 1
    }
}
