import Foundation

enum MusicPlaybackMode: String, CaseIterable, Identifiable, Sendable {
    case playlist, track
    var id: String { rawValue }
    var title: String { self == .playlist ? "Playlist" : "One track" }
}

struct MusicTrack: Identifiable, Equatable, Sendable {
    let id: String
    let filename: String
    let title: String

    static let all = [
        MusicTrack(id: "quarter-in-the-slot", filename: "quarter_in_the_slot", title: "Quarter in the Slot"),
        MusicTrack(id: "crossing-the-black-river", filename: "crossing_the_black_river", title: "Crossing the Black River"),
        MusicTrack(id: "miles-past-the-skyline", filename: "miles_past_the_skyline", title: "Miles Past the Skyline")
    ]
}

/// Playback intent survives lifecycle pauses. A system interruption never rewrites it.
struct MusicPlaybackState: Equatable {
    var enabled: Bool
    var wantsPlayback: Bool
    var mode: MusicPlaybackMode
    private(set) var trackID: String
    var position: TimeInterval

    var track: MusicTrack { MusicTrack.all.first { $0.id == trackID } ?? MusicTrack.all[0] }

    init(defaults: UserDefaults) {
        enabled = defaults.object(forKey: "audio.musicEnabled") == nil || defaults.bool(forKey: "audio.musicEnabled")
        wantsPlayback = defaults.object(forKey: "audio.musicWantsPlayback") == nil || defaults.bool(forKey: "audio.musicWantsPlayback")
        mode = MusicPlaybackMode(rawValue: defaults.string(forKey: "audio.musicPlaybackMode") ?? "") ?? .playlist
        let savedID = defaults.string(forKey: "audio.trackID")
        let legacyIndex = defaults.integer(forKey: "audio.trackIndex")
        let fallback = MusicTrack.all.indices.contains(legacyIndex) ? MusicTrack.all[legacyIndex] : MusicTrack.all[0]
        trackID = MusicTrack.all.first { $0.id == savedID }?.id ?? fallback.id
        let savedPosition = defaults.double(forKey: "audio.trackPosition")
        position = savedPosition.isFinite ? max(0, savedPosition) : 0
    }

    @discardableResult mutating func select(_ id: String) -> Bool {
        guard MusicTrack.all.contains(where: { $0.id == id }) else { return false }
        if trackID != id { trackID = id; position = 0 }
        return true
    }

    mutating func move(forward: Bool) {
        let index = MusicTrack.all.firstIndex { $0.id == trackID } ?? 0
        let offset = forward ? 1 : MusicTrack.all.count - 1
        trackID = MusicTrack.all[(index + offset) % MusicTrack.all.count].id
        position = 0
    }

    mutating func finishTrack() {
        if mode == .playlist { move(forward: true) }
        else { position = 0 }
    }

    func save(to defaults: UserDefaults) {
        defaults.set(enabled, forKey: "audio.musicEnabled")
        defaults.set(wantsPlayback, forKey: "audio.musicWantsPlayback")
        defaults.set(mode.rawValue, forKey: "audio.musicPlaybackMode")
        defaults.set(trackID, forKey: "audio.trackID")
        defaults.set(position.isFinite ? max(0, position) : 0, forKey: "audio.trackPosition")
    }
}

enum AudioPreferenceStorage {
    static func volume(_ value: Double, fallback: Double) -> Double {
        value.isFinite ? min(1, max(0, value)) : fallback
    }

    static func savedVolume(_ key: String, fallback: Double, defaults: UserDefaults) -> Double {
        guard let number = defaults.object(forKey: key) as? NSNumber else { return fallback }
        return volume(number.doubleValue, fallback: fallback)
    }
}

/// The trimmed GTA cue is decoded losslessly; its player supplies the duration.
enum DeathSoundCatalog {
    static let filenames = ["gta-death-trimmed"]
    static let fileExtension = "wav"
}

#if canImport(UIKit)
import AVFAudio
import CrocoCrossCore
import Observation
import UIKit

/// All control changes are on MainActor. The engine renders a precomputed seamless PCM loop.
@MainActor @Observable
final class AudioService: NSObject, AVAudioPlayerDelegate {
    private var storedMusicVolume: Double
    private var storedEngineVolume: Double
    private var storedEffectsVolume: Double
    private var storedHapticsEnabled: Bool
    private var storedMuted: Bool
    private var playback: MusicPlaybackState

    var tracks: [MusicTrack] { MusicTrack.all }
    var selectedTrackID: String { playback.trackID }
    var currentTrackTitle: String { playback.track.title }

    var musicVolume: Double {
        get { storedMusicVolume }
        set {
            let normalized = AudioPreferenceStorage.volume(newValue, fallback: 0.45)
            guard normalized != storedMusicVolume else { return }
            let wasSilent = storedMusicVolume == 0
            storedMusicVolume = normalized
            defaults.set(normalized, forKey: "audio.musicVolume")
            musicPlayer?.volume = Float(normalized)
            if normalized == 0 { pauseMusicPlayer() }
            else if wasSilent { startMusic() }
        }
    }
    var engineVolume: Double {
        get { storedEngineVolume }
        set {
            let normalized = AudioPreferenceStorage.volume(newValue, fallback: 0.65)
            guard normalized != storedEngineVolume else { return }
            storedEngineVolume = normalized
            defaults.set(normalized, forKey: "audio.engineVolume")
            if normalized == 0 { motor.volume = 0; lastMotorVolume = 0 }
        }
    }
    var effectsVolume: Double {
        get { storedEffectsVolume }
        set {
            let normalized = AudioPreferenceStorage.volume(newValue, fallback: 0.4)
            guard normalized != storedEffectsVolume else { return }
            storedEffectsVolume = normalized
            defaults.set(normalized, forKey: "audio.effectsVolume")
            effectMixer.outputVolume = isMuted ? 0 : Float(normalized)
            deathPlayer?.volume = isMuted ? 0 : Float(normalized) * 0.75
        }
    }
    var hapticsEnabled: Bool {
        get { storedHapticsEnabled }
        set { storedHapticsEnabled = newValue; defaults.set(newValue, forKey: "audio.hapticsEnabled") }
    }
    var isMuted: Bool {
        get { storedMuted }
        set {
            guard storedMuted != newValue else { return }
            storedMuted = newValue
            defaults.set(newValue, forKey: "audio.muted")
            effectMixer.outputVolume = newValue ? 0 : Float(effectsVolume)
            deathPlayer?.volume = newValue ? 0 : Float(effectsVolume) * 0.75
            if newValue {
                motor.volume = 0; lastMotorVolume = 0
                pauseMusicPlayer()
            } else { startMusic() }
        }
    }
    var musicEnabled: Bool {
        get { playback.enabled }
        set {
            guard playback.enabled != newValue else { return }
            playback.enabled = newValue
            if newValue {
                playback.wantsPlayback = true
                routeNeedsUserResume = false
                musicNeedsUserResume = false
            }
            playback.save(to: defaults)
            if newValue { startMusic() }
            else { pauseMusicPlayer() }
        }
    }
    var musicPlaybackMode: MusicPlaybackMode {
        get { playback.mode }
        set {
            playback.mode = newValue
            playback.save(to: defaults)
            musicPlayer?.numberOfLoops = newValue == .track ? -1 : 0
        }
    }
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
    @ObservationIgnored private var deathPlayers: [AVAudioPlayer] = []
    @ObservationIgnored private var deathPlayer: AVAudioPlayer?
    @ObservationIgnored private var deathPlaybackPaused = false
    @ObservationIgnored private(set) var deathSoundDuration: TimeInterval = 0
    var deathSoundPending: Bool { deathPlaybackPaused || deathPlayer?.isPlaying == true }
    @ObservationIgnored private var landingBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var successBuffer: AVAudioPCMBuffer?
    @ObservationIgnored private var musicPlayer: AVAudioPlayer?
    @ObservationIgnored private var configured = false
    @ObservationIgnored private var motorScheduled = false
    @ObservationIgnored private var gamePaused = true
    @ObservationIgnored private var motorSuppressed = false
    @ObservationIgnored private var suspended = false
    @ObservationIgnored private var interrupted = false
    @ObservationIgnored private var routeNeedsUserResume = false
    @ObservationIgnored private var musicNeedsUserResume = false
    @ObservationIgnored private var lastEffectTime: TimeInterval = 0
    @ObservationIgnored private var lastHapticTime: TimeInterval = 0
    @ObservationIgnored private var lastSpeedRate: Float = 0.8
    @ObservationIgnored private var lastMotorVolume: Float = 0
    @ObservationIgnored private var observers: [NotificationObservation] = []

    init(defaults: UserDefaults = .standard, bundle: Bundle = .main) {
        self.defaults = defaults
        self.bundle = bundle
        storedMusicVolume = AudioPreferenceStorage.savedVolume("audio.musicVolume", fallback: 0.45, defaults: defaults)
        storedEngineVolume = AudioPreferenceStorage.savedVolume("audio.engineVolume", fallback: 0.65, defaults: defaults)
        storedEffectsVolume = AudioPreferenceStorage.savedVolume("audio.effectsVolume", fallback: 0.4, defaults: defaults)
        storedHapticsEnabled = defaults.object(forKey: "audio.hapticsEnabled") == nil || defaults.bool(forKey: "audio.hapticsEnabled")
        storedMuted = defaults.bool(forKey: "audio.muted")
        playback = MusicPlaybackState(defaults: defaults)
        super.init()
        loadDeathSounds()
        observeAudioLifecycle()
    }

    /// Foreground entrypoint. Music continues while the game is paused or in a menu.
    func startMusic() {
        guard UIApplication.shared.applicationState == .active else { return }
        suspended = false
        guard !interrupted, !routeNeedsUserResume, shouldPlayMusic || !gamePaused else { return }
        do {
            try prepareAudio()
            guard shouldPlayMusic else { return }
            if musicPlayer == nil { try loadCurrentTrack() }
            musicPlayer?.volume = Float(musicVolume)
            musicPlaying = musicPlayer?.play() ?? false
            if musicPlaying { statusMessage = nil }
        } catch {
            musicPlaying = false
            statusMessage = "Music could not be played: \(error.localizedDescription)"
        }
    }

    func selectTrack(id: String) {
        let oldID = playback.trackID
        guard playback.select(id) else { return }
        if oldID != playback.trackID { discardMusicPlayer() }
        playMusic()
    }

    func nextTrack() { moveTrack(forward: true) }
    func previousTrack() { moveTrack(forward: false) }

    private func moveTrack(forward: Bool) {
        playback.move(forward: forward)
        discardMusicPlayer()
        playback.save(to: defaults)
        // Browsing tracks preserves an explicit pause or Music Off.
        startMusic()
    }

    private func discardMusicPlayer() {
        musicPlayer?.stop()
        musicPlayer?.delegate = nil
        musicPlayer = nil
        musicPlaying = false
    }

    func toggleMusicPlayback() {
        if musicPlaying { pauseMusic() }
        else { playMusic() }
    }

    func playMusic() {
        playback.enabled = true
        playback.wantsPlayback = true
        playback.save(to: defaults)
        routeNeedsUserResume = false
        musicNeedsUserResume = false
        startMusic()
    }

    func pauseMusic() {
        playback.wantsPlayback = false
        pauseMusicPlayer()
    }

    private var shouldPlayMusic: Bool {
        musicEnabled && playback.wantsPlayback && !isMuted && musicVolume > 0 && !musicNeedsUserResume
    }

    private func pauseMusicPlayer() {
        musicPlayer?.pause()
        musicPlaying = false
        if let musicPlayer { playback.position = musicPlayer.currentTime }
        playback.save(to: defaults)
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
        guard !gamePaused, !motorSuppressed, !suspended, !interrupted, !routeNeedsUserResume, !isMuted,
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
            playDeathSound()
            if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.error) }
            lastHapticTime = now
        case .landed(let impact):
            guard impact.isFinite, impact > 1, now - lastEffectTime > 0.15 else { return }
            lastEffectTime = now
            if !isMuted, effectsVolume > 0 { playEffect(landingBuffer, volume: Float(min(1, impact / 12))) }
            if hapticsEnabled, now - lastHapticTime > 0.15 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: min(1, impact / 12))
                lastHapticTime = now
            }
        case .flip:
            if !isMuted, effectsVolume > 0 { playEffect(successBuffer, volume: 0.45) }
            if hapticsEnabled { UISelectionFeedbackGenerator().selectionChanged() }
        case .finished:
            motorSuppressed = true
            motor.volume = 0
            if !isMuted, effectsVolume > 0 { playEffect(successBuffer) }
            if hapticsEnabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        case .respawned:
            motorSuppressed = false
            lastMotorVolume = 0
        }
    }

    private func loadDeathSounds() {
        deathPlayers = DeathSoundCatalog.filenames.compactMap { filename in
            guard let url = bundle.url(forResource: filename, withExtension: DeathSoundCatalog.fileExtension, subdirectory: "GameAssets/DeathSounds"),
                  let player = try? AVAudioPlayer(contentsOf: url), player.duration.isFinite, player.duration > 0 else { return nil }
            player.numberOfLoops = 0
            player.delegate = self
            player.prepareToPlay()
            return player
        }
    }

    private func playDeathSound() {
        stopDeathSound()
        guard let selected = deathPlayers.first else { return }
        deathPlayer = selected
        deathSoundDuration = selected.duration
        selected.currentTime = 0
        selected.volume = isMuted ? 0 : Float(effectsVolume) * 0.75
        // A separate player cannot be interrupted by landing or success effects.
        do { try prepareAudio(); selected.play() }
        catch { statusMessage = "The death sound could not be played." }
    }

    func pauseDeathSound() {
        guard deathPlayer?.isPlaying == true else { return }
        deathPlaybackPaused = true
        deathPlayer?.pause()
    }

    func resumeDeathSound() {
        guard deathPlaybackPaused, !suspended, !interrupted, !routeNeedsUserResume else { return }
        deathPlaybackPaused = false
        do { try prepareAudio(); deathPlayer?.play() }
        catch { statusMessage = "The death sound could not resume." }
    }

    func stopDeathSound() {
        deathPlayer?.stop()
        deathPlayer = nil
        deathPlaybackPaused = false
        deathSoundDuration = 0
    }

    /// Background entrypoint. Retains playback position and preferences for foreground restoration.
    func shutdown() {
        suspended = true
        pauseDeathSound()
        pauseMusicPlayer()
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
        effectMixer.outputVolume = isMuted ? 0 : Float(effectsVolume)
        motorBuffer = Self.makeBuffer(format: format, seconds: 1) { t in
            let phase = t * 2 * Double.pi * 48
            let exhaust = sin(phase) * 0.48 + sin(phase * 2) * 0.23 + sin(phase * 3) * 0.12
            return Float(tanh(exhaust * 1.4) * (0.8 + 0.2 * sin(t * 2 * Double.pi * 24)))
        }
        landingBuffer = Self.makeBuffer(format: format, seconds: 0.13) { t in
            Float(sin(2 * Double.pi * 75 * t) * exp(-t * 32) * 0.6)
        }
        successBuffer = Self.makeBuffer(format: format, seconds: 0.28) { t in
            let frequency = t < 0.12 ? 660.0 : 880.0
            return Float(sin(t * 2 * Double.pi * frequency) * min(1, t * 150) * exp(-t * 8) * 0.35)
        }
        configured = true
        engine.prepare()
    }

    private func loadCurrentTrack() throws {
        let track = playback.track
        guard let url = assetURL(track.filename, extension: "mp3") else {
            throw NSError(domain: "CrocoCross.Audio", code: 1, userInfo: [NSLocalizedDescriptionKey: "The bundled track is missing."])
        }
        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        player.volume = Float(musicVolume)
        player.numberOfLoops = musicPlaybackMode == .track ? -1 : 0
        player.prepareToPlay()
        player.currentTime = playback.position < player.duration ? playback.position : 0
        musicPlayer = player
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
                    self.pauseDeathSound()
                    self.pauseMusicPlayer()
                    self.effectPlayer.stop()
                    self.motor.volume = 0
                    self.engine.pause()
                } else {
                    self.interrupted = false
                    let mayResume = AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume)
                    if !mayResume {
                        self.stopDeathSound()
                        self.routeNeedsUserResume = true
                        self.musicNeedsUserResume = true
                        self.statusMessage = "Audio paused. Resume playback or the game."
                    }
                    if mayResume, !self.suspended, UIApplication.shared.applicationState == .active {
                        self.startMusic()
                        self.resumeDeathSound()
                    }
                }
            }
        }))
        observers.append(NotificationObservation(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] notification in
            let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            Task { @MainActor [weak self] in
                guard let self, let rawReason else { return }
                if AVAudioSession.RouteChangeReason(rawValue: rawReason) == .oldDeviceUnavailable {
                    self.stopDeathSound()
                    // Headphones unplugged: do not surprise the player by switching music to the speaker.
                    self.routeNeedsUserResume = true
                    self.musicNeedsUserResume = true
                    self.pauseMusicPlayer()
                    self.effectPlayer.stop()
                    self.motor.volume = 0
                    self.engine.pause()
                    self.statusMessage = "Audio output changed. Resume playback or the game."
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
            if flag {
                self.playback.finishTrack()
                self.discardMusicPlayer()
                self.playback.save(to: self.defaults)
                self.startMusic()
            }
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
        stopDeathSound()
        loadDeathSounds()
        if let musicPlayer { playback.position = musicPlayer.currentTime }
        playback.save(to: defaults)
        engine.stop()
        musicPlayer?.stop()
        musicPlayer = nil
        musicPlaying = false
        engine = AVAudioEngine()
        motor = AVAudioPlayerNode()
        pitch = AVAudioUnitVarispeed()
        effectPlayer = AVAudioPlayerNode()
        effectMixer = AVAudioMixerNode()
        configured = false
        motorScheduled = false
        guard !suspended, !interrupted, !routeNeedsUserResume, UIApplication.shared.applicationState == .active else { return }
        do {
            try prepareAudio()
            if shouldPlayMusic {
                try loadCurrentTrack()
                musicPlaying = musicPlayer?.play() ?? false
            }
        } catch { statusMessage = "Audio was reset by the system. Try resuming playback." }
    }

}
#endif
