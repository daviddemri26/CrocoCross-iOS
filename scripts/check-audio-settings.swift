// Run from the project root:
// xcrun swiftc -swift-version 6 -module-cache-path /tmp/crococross-audio-module-cache App/Services/AudioService.swift scripts/check-audio-settings.swift -o /tmp/crococross-check-audio-settings
// /tmp/crococross-check-audio-settings
// Foundation-only state tests; no speakers, simulators or standard app preferences are touched.
import Foundation

@main struct AudioSettingsChecks {
    static func main() throws {
        let suite = "CrocoCross.AudioChecks.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else { fatalError("Cannot create isolated preferences") }
        defer { defaults.removePersistentDomain(forName: suite) }
        var checks = 0
        func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
            guard condition() else { fatalError(message) }
            checks += 1
        }

        var state = MusicPlaybackState(defaults: defaults)
        let first = MusicTrack.all[0].id
        let second = MusicTrack.all[1].id
        let third = MusicTrack.all[2].id
        expect(state.enabled && state.wantsPlayback && state.mode == .playlist, "Fresh install should play the playlist")
        expect(state.trackID == first && state.position == 0, "Fresh install should select the first track")
        state.finishTrack()
        expect(state.trackID == second, "A completed playlist track should advance")
        state.finishTrack()
        state.finishTrack()
        expect(state.trackID == first, "Playlist should wrap after the last track")
        state.move(forward: false)
        expect(state.trackID == third, "Previous should wrap to the last track")
        state.move(forward: true)
        expect(state.trackID == first, "Next should wrap to the first track")

        state.mode = .track
        state.select(second)
        state.position = 123.5
        state.finishTrack()
        expect(state.trackID == second && state.position == 0, "One track should repeat the same track")
        state.position = 123.5
        expect(state.select(second) && state.position == 123.5, "Reselecting the same track should keep its position")
        expect(!state.select("missing-track") && state.trackID == second, "Invalid track IDs should be ignored")
        state.select(third)
        expect(state.position == 0, "Selecting another track should reset the position")

        state.enabled = false
        state.wantsPlayback = false
        state.position = 42.25
        state.save(to: defaults)
        let restored = MusicPlaybackState(defaults: defaults)
        expect(restored == state, "Track, position, mode, Music Off and manual pause should survive relaunch")
        state.move(forward: true)
        expect(!state.enabled && !state.wantsPlayback, "Previous/Next should not undo Music Off or a manual pause")
        state.mode = .playlist
        state.finishTrack()
        expect(!state.enabled && !state.wantsPlayback, "A late finished callback should not undo Music Off or a manual pause")

        defaults.removePersistentDomain(forName: suite)
        defaults.set(2, forKey: "audio.trackIndex")
        expect(MusicPlaybackState(defaults: defaults).trackID == third, "Old native track indexes should migrate")
        defaults.set(Int.max, forKey: "audio.trackIndex")
        defaults.set("missing-track", forKey: "audio.trackID")
        defaults.set("invalid-mode", forKey: "audio.musicPlaybackMode")
        defaults.set(-100, forKey: "audio.trackPosition")
        let repaired = MusicPlaybackState(defaults: defaults)
        expect(repaired.trackID == first && repaired.mode == .playlist && repaired.position == 0, "Invalid preferences should fall back safely")
        defaults.set(second, forKey: "audio.trackID")
        expect(MusicPlaybackState(defaults: defaults).trackID == second, "A saved track ID should take precedence over an old index")

        expect(AudioPreferenceStorage.volume(.nan, fallback: 0.45) == 0.45, "NaN volume should restore the default")
        expect(AudioPreferenceStorage.volume(.infinity, fallback: 0.65) == 0.65, "Infinite volume should restore the default")
        expect(AudioPreferenceStorage.volume(-1, fallback: 0.4) == 0, "Negative volume should clamp to zero")
        expect(AudioPreferenceStorage.volume(2, fallback: 0.4) == 1, "Excess volume should clamp to one")
        defaults.set("corrupted", forKey: "audio.musicVolume")
        expect(AudioPreferenceStorage.savedVolume("audio.musicVolume", fallback: 0.45, defaults: defaults) == 0.45, "Non-numeric stored volume should restore the default")
        defaults.set(0.25, forKey: "audio.musicVolume")
        expect(AudioPreferenceStorage.savedVolume("audio.musicVolume", fallback: 0.45, defaults: defaults) == 0.25, "Valid volume should survive relaunch")
        print("PASS: \(checks) audio preference and playlist checks")
    }
}
