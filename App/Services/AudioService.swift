import AVFAudio
import CrocoCrossCore
import Foundation
import Observation
import UIKit

/// All control changes are on MainActor. The engine renders a precomputed seamless PCM loop.
@MainActor @Observable
final class AudioService: NSObject, AVAudioPlayerDelegate {
    private struct Track {
        let filename: String
        let title: String
    }
    private static let tracks = [
        Track(filename: "quarter_in_the_slot", title: "Quarter in the Slot"),
        Track(filename: "crossing_the_black_river", title: "Crossing the Black River"),
        Track(filename: "miles_past_the_skyline", title: "Miles Past the Skyline")
    ]

    var musicVolume: Double = 0.45 {
        didSet {
            let normalized = Self.clamp(musicVolume, fallback: 0.45)
            if musicVolume != normalized { musicVolume = normalized; return }
            defaults.set(musicVolume, forKey: "audio.musicVolume")
            musicPlayer?.volume = Float(musicVolume)
        }
    }
    var engineVolume: Double = 0.65 {
        didSet {
            let normalized = Self.clamp(engineVolume, fallback: 0.65)
            if engineVolume != normalized { engineVolume = normalized; return }
            defaults.set(engineVolume, forKey: "audio.engineVolume")
            if engineVolume == 0 { motor.volume = 0 }
        }
    }
    var effectsVolume: Double = 0.4 {
        didSet {
            let normalized = Self.clamp(effectsVolume, fallback: 0.4)
            if effectsVolume != normalized { effectsVolume = normalized; return }
            defaults.set(effectsVolume, forKey: "audio.effectsVolume")
            explosionPlayer?.volume = Float(effectsVolume)
            effectMixer.outputVolume = Float(effectsVolume)
        }
    }
    var hapticsEnabled = true {
        didSet { defaults.set(hapticsEnabled, forKey: "audio.hapticsEnabled") }
    }
    var musicEnabled = true {
        didSet {
            defaults.set(musicEnabled, forKey: "audio.musicEnabled")
            if musicEnabled { startMusic() }
            else { musicPlayer?.pause(); musicPlaying = false }
        }
    }
    private(set) var currentTrackTitle = "Quarter in the Slot"
    private(set) var musicPlaying = false
    private(set) var statusMessage: String?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let bundle: Bundle
    @ObservationIgnored private var engine = AVAudioEngine()
    @ObservationIgnored private var motor = AVAudioPlayerNode()
    @ObservationIgnored private var pitch = AVAudioUnitVarispeed()
    @ObservationIgnored private var effectPlayer = AVAudioPlayerNode()
    @ObservationIgnored private var effectMixer = AVAudioMixerNode()
    @ObservationIgnored private var motorBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var crashBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var landingBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var successBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var musicPlayer: AVAudioPlayer?
    @ObservationIgnored private var explosionPlayer: AVAudioPlayer?
    @ObservationIgnored private var trackIndex = 0
    @ObservationIgnored private var configured = false
    @ObservationIgnored private var motorScheduled = false
    @ObservationIgnored private var gamePaused = true
    @ObservationIgnored private var motorSuppressed = false
    @ObservationIgnored private var suspended = false
    @ObservationIgnored private var interrupted = false
    @ObservationIgnored private var routeNeedsUserResume = false
    @ObservationIgnored private var lastEffectTime: TimeInterval = 0
    @ObservationIgnored private var lastHapticTime: TimeInterval = 0
    @ObservationIgnored private var lastSpeedRate: Float = 0.8
    @ObservationIgnored private var lastMotorVolume: Float = 0
    @ObservationIgnored private var observers: [NotificationObservation] = []

    init(defaults: UserDefaults = .standard, bundle: Bundle = .main) {
        self.defaults = defaults
        self.bundle = bundle
        super.init()
        musicVolume = Self.savedVolume("audio.musicVolume", fallback: 0.45, defaults: defaults)
        engineVolume = Self.savedVolume("audio.engineVolume", fallback: 0.65, defaults: defaults)
        effectsVolume = Self.savedVolume("audio.effectsVolume", fallback: 0.4, defaults: defaults)
        hapticsEnabled = defaults.object(forKey: "audio.hapticsEnabled") == nil || defaults.bool(forKey: "audio.hapticsEnabled")
        musicEnabled = defaults.object(forKey: "audio.musicEnabled") == nil || defaults.bool(forKey: "audio.musicEnabled")
        trackIndex = min(max(defaults.integer(forKey: "audio.trackIndex"), 0), Self.tracks.count - 1)
        currentTrackTitle = Self.tracks[trackIndex].title
        observeAudioLifecycle()
    }

    /// Foreground entrypoint. Music continues while the game is paused or in a menu.
    func startMusic() {
        guard UIApplication.shared.applicationState == .active else { return }
        suspended = false
        guard !interrupted, !routeNeedsUserResume, musicEnabled || !gamePaused else { return }
        do {
            try prepareAudio()
            guard musicEnabled else { return }
            if musicPlayer == nil { try loadCurrentTrack() }
            musicPlayer?.volume = Float(musicVolume)
            musicPlaying = musicPlayer?.play() ?? false
            if musicPlaying { statusMessage = nil }
        } catch {
            musicPlaying = false
            statusMessage = "Music could not be played: \(error.localizedDescription)"
        }
    }

    func nextTrack() {
        trackIndex = (trackIndex + 1) % Self.tracks.count
        defaults.set(trackIndex, forKey: "audio.trackIndex")
        currentTrackTitle = Self.tracks[trackIndex].title
        musicPlayer?.stop()
        musicPlayer = nil
        musicPlaying = false
        routeNeedsUserResume = false
        if musicEnabled { startMusic() }
    }

    func toggleMusicPlayback() {
        routeNeedsUserResume = false
        // A route interruption does not rewrite the user's music preference.
        if musicEnabled && !musicPlaying { startMusic() }
        else { musicEnabled.toggle() }
    }

    func setPaused(_ paused: Bool) {
        gamePaused = paused
        if !paused, UIApplication.shared.applicationState == .active { suspended = false }
        if paused {
            motor.volume = 0
            lastMotorVolume = 0
        } else if !suspended && !interrupted {
            motorSuppressed = false
            routeNeedsUserResume = false
            do { try prepareAudio() }
            catch { statusMessage = "Game audio is unavailable: \(error.localizedDescription)" }
            if musicEnabled && !musicPlaying { startMusic() }
        }
    }

    func update(bike: BikeState) {
        guard !gamePaused, !motorSuppressed, !suspended, !interrupted, !routeNeedsUserResume,
              bike.velocity.x.isFinite, bike.velocity.y.isFinite, bike.throttle.isFinite else { return }
        guard engine.isRunning else { return }
        let speed = min(1, max(0, hypot(bike.velocity.x, bike.velocity.y) / 30))
        let throttle = min(1, max(0, bike.throttle))
        let targetRate = Float(0.65 + speed * 1.2 + throttle * 0.2)
        lastSpeedRate += (targetRate - lastSpeedRate) * 0.1
        pitch.rate = lastSpeedRate
        let targetVolume = Float(engineVolume * (0.13 + throttle * 0.32 + speed * 0.15))
        lastMotorVolume += (targetVolume - lastMotorVolume) * 0.16
        motor.volume = lastMotorVolume
    }

    func handle(event: GameEvent) {
        guard !suspended, !interrupted, !routeNeedsUserResume else { return }
        let now = ProcessInfo.processInfo.systemUptime
        switch event {
        case .crashed:
            motorSuppressed = true
            motor.volume = 0
            lastMotorVolume = 0
            if effectsVolume > 0 {
                if let explosionPlayer {
                    explosionPlayer.currentTime = 0
                    explosionPlayer.volume = Float(effectsVolume)
                    explosionPlayer.play()
                } else { playEffect(crashBuffer) }
            }
            if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.error) }
            lastHapticTime = now
        case .landed(let impact):
            guard impact.isFinite, impact > 1, now - lastEffectTime > 0.15 else { return }
            lastEffectTime = now
            if effectsVolume > 0 { playEffect(landingBuffer, volume: Float(min(1, impact / 12))) }
            if hapticsEnabled, now - lastHapticTime > 0.15 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: min(1, impact / 12))
                lastHapticTime = now
            }
        case .flip:
            if effectsVolume > 0 { playEffect(successBuffer, volume: 0.45) }
            if hapticsEnabled { UISelectionFeedbackGenerator().selectionChanged() }
        case .finished:
            motorSuppressed = true
            motor.volume = 0
            if effectsVolume > 0 { playEffect(successBuffer) }
            if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        case .respawned:
            motorSuppressed = false
            lastMotorVolume = 0
        }
    }

    /// Background entrypoint. Retains playback position and preferences for foreground restoration.
    func shutdown() {
        suspended = true
        musicPlayer?.pause()
        musicPlaying = false
        explosionPlayer?.stop()
        motor.volume = 0
        motor.stop()
        effectPlayer.stop()
        motorScheduled = false
        engine.pause()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func prepareAudio() throws {
        guard !suspended, !interrupted, !routeNeedsUserResume else { return }
        let session = AVAudioSession.sharedInstance()
        // Ambient honors the hardware silent switch and cooperates with the player's other audio.
        try session.setCategory(.ambient, mode: .default, options: .mixWithOthers)
        try session.setActive(true)
        if !configured { configureEngine() }
        if !engine.isRunning { try engine.start() }
        if !motorScheduled, let motorBuffer {
            motor.scheduleBuffer(motorBuffer, at: nil, options: .loops)
            motorScheduled = true
        }
        if !motor.isPlaying { motor.play() }
        if !effectPlayer.isPlaying { effectPlayer.play() }
    }

    private func configureEngine() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        engine.attach(motor)
        engine.attach(pitch)
        engine.attach(effectPlayer)
        engine.attach(effectMixer)
        engine.connect(motor, to: pitch, format: format)
        engine.connect(pitch, to: engine.mainMixerNode, format: format)
        engine.connect(effectPlayer, to: effectMixer, format: format)
        engine.connect(effectMixer, to: engine.mainMixerNode, format: format)
        motor.volume = 0
        effectMixer.outputVolume = Float(effectsVolume)
        motorBuffer = Self.makeBuffer(format: format, seconds: 1) { t in
            let phase = t * 2 * Double.pi * 48
            let exhaust = sin(phase) * 0.48 + sin(phase * 2) * 0.23 + sin(phase * 3) * 0.12
            return Float(tanh(exhaust * 1.4) * (0.8 + 0.2 * sin(t * 2 * Double.pi * 24)))
        }
        landingBuffer = Self.makeBuffer(format: format, seconds: 0.13) { t in
            Float(sin(2 * Double.pi * 75 * t) * exp(-t * 32) * 0.6)
        }
        crashBuffer = Self.makeBuffer(format: format, seconds: 0.7) { t in
            let texture = sin(t * 13_731) * sin(t * 6_043) + sin(t * 2_749) * 0.3
            return Float((texture * 0.3 + sin(t * 2 * Double.pi * 52) * 0.5) * exp(-t * 7))
        }
        successBuffer = Self.makeBuffer(format: format, seconds: 0.28) { t in
            let frequency = t < 0.12 ? 660.0 : 880.0
            return Float(sin(t * 2 * Double.pi * frequency) * min(1, t * 150) * exp(-t * 8) * 0.35)
        }
        if let url = assetURL("fuel-explosion", extension: "mp3") {
            explosionPlayer = try? AVAudioPlayer(contentsOf: url)
            explosionPlayer?.prepareToPlay()
        }
        configured = true
        engine.prepare()
    }

    private func loadCurrentTrack() throws {
        let track = Self.tracks[trackIndex]
        guard let url = assetURL(track.filename, extension: "mp3") else {
            throw NSError(domain: "CrocoCross.Audio", code: 1, userInfo: [NSLocalizedDescriptionKey: "The bundled track is missing."])
        }
        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        player.volume = Float(musicVolume)
        player.numberOfLoops = 0
        player.prepareToPlay()
        musicPlayer = player
        currentTrackTitle = track.title
    }

    private func assetURL(_ filename: String, extension suffix: String) -> URL? {
        bundle.url(forResource: filename, withExtension: suffix, subdirectory: "GameAssets")
            ?? bundle.url(forResource: filename, withExtension: suffix)
    }

    private func playEffect(_ buffer: AVAudioPCMBuffer?, volume: Float = 1) {
        guard let buffer, engine.isRunning else { return }
        effectPlayer.volume = volume
        effectPlayer.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !effectPlayer.isPlaying { effectPlayer.play() }
    }

    private static func makeBuffer(format: AVAudioFormat, seconds: Double, sample: (Double) -> Float) -> AVAudioPCMBuffer? {
        let frames = AVAudioFrameCount(format.sampleRate * seconds)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames), let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frames
        for index in 0..<Int(frames) { samples[index] = sample(Double(index) / format.sampleRate) }
        return buffer
    }

    private func observeAudioLifecycle() {
        let center = NotificationCenter.default
        observers.append(NotificationObservation(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] notification in
            let rawType = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor [weak self] in
                guard let self, let rawType, let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }
                if type == .began {
                    self.interrupted = true
                    self.musicPlayer?.pause()
                    self.musicPlaying = false
                    self.motor.volume = 0
                    self.engine.pause()
                } else {
                    self.interrupted = false
                    let mayResume = AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume)
                    if mayResume, !self.suspended, UIApplication.shared.applicationState == .active {
                        self.startMusic()
                    }
                }
            }
        }))
        observers.append(NotificationObservation(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] notification in
            let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor [weak self] in
                guard let self, let rawReason else { return }
                if AVAudioSession.RouteChangeReason(rawValue: rawReason) == .oldDeviceUnavailable {
                    // Headphones unplugged: do not surprise the player by switching music to the speaker.
                    self.routeNeedsUserResume = true
                    self.musicPlayer?.pause()
                    self.musicPlaying = false
                    self.motor.volume = 0
                    self.statusMessage = "Audio output changed. Tap Play to resume music."
                }
            }
        }))
        observers.append(NotificationObservation(center.addObserver(forName: .AVAudioEngineConfigurationChange, object: nil, queue: .main) { [weak self] notification in
            let source = (notification.object as? AVAudioEngine).map { ObjectIdentifier($0) }
            Task { @MainActor [weak self] in
                guard let self, source == ObjectIdentifier(self.engine) else { return }
                self.motor.stop()
                self.motorScheduled = false
                guard !self.suspended, !self.interrupted, !self.routeNeedsUserResume else { return }
                do { try self.prepareAudio() }
                catch { self.statusMessage = "Audio output is unavailable. Try resuming the game." }
            }
        }))
        observers.append(NotificationObservation(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.rebuildAfterMediaReset() }
        }))
        observers.append(NotificationObservation(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.shutdown() }
        }))
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let identifier = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, let current = self.musicPlayer, ObjectIdentifier(current) == identifier else { return }
            self.musicPlaying = false
            if flag { self.nextTrack() }
            else { self.statusMessage = "Music playback stopped. Tap Play to try again." }
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        let identifier = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, let current = self.musicPlayer, ObjectIdentifier(current) == identifier else { return }
            self.musicPlaying = false
            self.statusMessage = "This track could not be decoded. Try the next track."
        }
    }

    private func rebuildAfterMediaReset() {
        let musicPosition = musicPlayer?.currentTime ?? 0
        engine.stop()
        musicPlayer?.stop()
        explosionPlayer?.stop()
        musicPlayer = nil
        explosionPlayer = nil
        musicPlaying = false
        engine = AVAudioEngine()
        motor = AVAudioPlayerNode()
        pitch = AVAudioUnitVarispeed()
        effectPlayer = AVAudioPlayerNode()
        effectMixer = AVAudioMixerNode()
        configured = false
        motorScheduled = false
        interrupted = false
        guard !suspended, !routeNeedsUserResume, UIApplication.shared.applicationState == .active else { return }
        do {
            try prepareAudio()
            if musicEnabled {
                try loadCurrentTrack()
                musicPlayer?.currentTime = musicPosition
                musicPlaying = musicPlayer?.play() ?? false
            }
        } catch { statusMessage = "Audio was reset by the system. Try resuming playback." }
    }

    private static func savedVolume(_ key: String, fallback: Double, defaults: UserDefaults) -> Double {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return clamp(defaults.double(forKey: key), fallback: fallback)
    }

    private static func clamp(_ value: Double, fallback: Double) -> Double {
        value.isFinite ? min(1, max(0, value)) : fallback
    }

}
