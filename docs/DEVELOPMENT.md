# Development guide

Native SwiftUI / SpriteKit motorcycle game. Independent from the continuing ChatGPT Sites project.

## Product

- Weekly competition: 4,000 metres, one life, no time limit; Monday 00:00 UTC rollover.
- Endless: three lives, procedural hills, stable-ground recovery and local records.
- Rear-wheel drive, chassis inertia, damped suspension, traction-limited acceleration, natural wheelies and gravity-driven jumps. No owner workshop or automatic upright assist.
- Rocco as the first articulated rider (eight other characters retained for later rig adaptation) and nine animated worlds, textured terrain, below-ground details, native audio and haptics.
- iPhone portrait, iPad landscape, adaptive scene bounds for wide/foldable displays. Fixed illustrated buttons sit in the lower left/right corners; Pause stays at bottom centre.
- Game Center only: weekly points, weekly completion time, endless points. Both modes remain playable offline; connection status appears only in Rankings.
- Free; no ads, purchases, custom backend or third-party analytics.

## Open and build

Open `CrocoCross.xcodeproj`, select the CrocoCross scheme and an iPhone/iPad destination. Deployment target: iOS 18.0. The project uses Apple's SDKs and one local Swift package with vendored Box2D 3.1.1 (MIT); there are no remote package dependencies.

The project is reproducible after adding/removing Swift files:

```sh
python3 scripts/generate-project.py
swift test --disable-sandbox
xcodebuild -project CrocoCross.xcodeproj -scheme CrocoCross \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/crococross-derived CODE_SIGNING_ALLOWED=NO build
```

The checked-in project selects David Demri's development team. Signing certificates and provisioning profiles remain in Xcode/Keychain, never in this repository. No App Store upload is performed by the generator or build scripts.

## Architecture

- `Sources/CrocoCrossCore`: portable 120 Hz Box2D simulation with a uniquely owned world, Codable value snapshots, procedural terrain, stunt tracking and weekly date/seed model. Metres, seconds, positive-up coordinates.
- `App/GameSession.swift`: fixed-step clock, render interpolation, run lifecycle, safe pause, records and ephemeral rides.
- `App/Scene`: SpriteKit rendering; no physics authority. Gameplay and decorative randomization are separate.
- `App/UI`: adaptive SwiftUI menus and UIKit-backed cancellable multi-pedal controls.
- `App/Services`: Game Center, persistent score queue, AVFAudio, file storage.

Painted scenery, its independent random placement, asset provenance and isolated visual validation are documented in [Scenery](SCENERY.md). Rider silhouettes, shared wheelbase scale, speed-dependent zoom, preview height limits and recovery/jump framing are documented in [Rider sizes](RIDER-SIZES.md).

Physics constants live in `PhysicsConfiguration`. Score/terrain changes that make records incomparable require a new engine/course version and new Game Center leaderboard identifiers. Existing App Store clients retain their own rule/board versions. Do not port the historical web verification engines or connect the original Sites database.

The current development engine is `box2d-1`, backed by pinned Box2D 3.1.1. [Physics](PHYSICS.md) documents the five-body rig, wheel joints and pilot posture. Gameplay runs at 120 Hz with four solver substeps per tick. SpriteKit renders independent chassis, wheel, pelvis and torso poses; it does not resolve collisions. The rider shifts weight with bounded bike-relative muscle effort and detaches only after a confirmed body impact. There is no world-upright target, automatic recovery, landing speed injection or launch impulse.

Motor effort ramps over 0.18 seconds and tapers toward 24 m/s; gravity can carry the bike faster downhill. Full braking requests 2,800 N equivalent wheel effort, split 65% rear / 35% front. Wheel motors exchange torque with the chassis and Box2D contacts enforce friction. Holding both buttons cancels lean while drive and braking remain requested. Left balance gains extra authority only when the rear supports a raised front wheel.

Rides are not saved or restored. `GameSimulation` is a reference with one owned Box2D world, not Codable or Sendable; reproducibility uses fresh worlds with identical input sequences. Legacy records, rider choice and queued scores remain untouched. New local keys and queue use `box2d-1`; Game Center uses new `.v2` identifiers. Records from the two engines are not comparable. Neither legacy scores nor queued submissions are retagged for the new boards. Offline play stays available if the new boards are not configured.


## Navigation

Home has one named rider selector with the original Lucide Bike symbol and a Rider label, one named world selector with a World label, two equally sized animated square mode buttons and a fixed bottom bar for Rankings, Settings and Help. Layout switches to the sidebar only when the window is at least 700 points wide. Reduce Motion stops decorative mode-button motion. Rankings, Settings and Help share the same neutral button style and equal dimensions; none appears selected on Home. Every panel has a fixed Close button at bottom right. Settings integrates it beside the section tabs. Choosing a rider or world applies that choice and dismisses the picker immediately; closing without selecting preserves the current choice.

Settings uses fixed bottom tabs: General (haptics), Audio (music and volumes), and About (version, privacy, credits). Personal records and Game Center connection/leaderboards live together in the dedicated Rankings panel. The game HUD uses the same normal presentation in every run; it does not show Practice/Unranked labels or connection notices. Eligibility checks for online score submission remain enforced internally.

## Controls

Two [fixed image buttons](CONTROLS.md) sit at the lower corners: 112 pt square on iPhone portrait and 124 pt on iPad landscape. Their original transparent handlebar PNGs are bundled without visible text or arrows. Procedural rims provide press/release springs, a touch ripple and a held pulse; Reduce Motion uses immediate color feedback. Pause remains a separate button at bottom centre. Both controls can be held independently at once.

Right grip: throttle and backward balance. Left grip and brake lever: braking and forward balance. Rider balance fades in as either wheel clears the ground, alongside any remaining tire contact forces. App input is binary: a Boolean hold maps to 1, release maps to 0. Finger movement never changes power or the button position; the owning touch remains active until lifted or cancelled. There is no slider, power gauge, adjustable accessibility trait or percentage. VoiceOver double-tap toggles a full hold/release. Release, cancellation, teardown, pause and recovery clear held controls. With both tires loaded, inputs rotate the chassis through tire forces and weight transfer alone.

Returning Home or backgrounding the app abandons the ride and resets the controls; relaunch always opens Home. Starting and restarting begin immediately, without a Continue button or confirmation. Manual pause, a transient system interruption, a large layout change or a long frame stall pauses the ride in memory; Keep riding resumes it. Personal records and eligible pending Game Center scores survive leaving the ride. Progress is submitted every 1,200 simulation ticks and when pausing; weekly scores still require finishing. An expired weekly ride can continue locally after a temporary pause, without a status label.

## Effects and scores

The HUD speedometer applies a presentation-only multiplier of 2 to `hypot(vx, vy) * 3.6`. Its display is therefore an arcade scale, not physical km/h; the dial uses a matching 200-unit range. Simulation velocities remain metres per second, course distance is still horizontal progress in metres, and timers/scoring are unchanged.

Landings produce dust and impact feedback. A confirmed crash detaches the rider from the motorcycle while preserving their physical velocities. The rig stays visible, the camera follows the fall, and a small impact burst accompanies the crash sound. Crash presentation runs at 0.5× speed with a warm desaturated filter on the scene only, fading in/out over 0.65 seconds (0.2 seconds with Reduce Motion). At every death the trimmed GTA cue plays once in full on a dedicated AVAudioPlayer. Its duration is 6.09 seconds, with silent/very quiet edges removed and a 150 ms end fade. It honors Effects volume and mute and cannot be replaced by landing/success effects. On the third lost Endless life, the rider and motorcycle disappear and the existing explosion plays in color at real speed, above foreground art. Terminal physics stops and the score card waits at least 1.8 seconds. Weekly crashes and recoverable Endless falls keep their physical slow motion and filter; the Weekly card waits at least 3.6 seconds. Reduce Motion sets the visual minimum to 0.3 seconds, but never shortens the selected audio. Every result/respawn waits for both its minimum duration and completion of the selected clip. After the existing bounded fall/explosion finishes, the scene holds until the sound ends; physics and explosion playback are not stretched. Pausing a recoverable fall pauses both its countdown and clip; restarting or leaving the ride cancels them. Weekly terminal physics presentation is limited to 216 steps and cannot change the terminal score, tick or lives. Endless recovery advances to a fresh rig at the last stable checkpoint. Reduce Motion reduces decorative effects; physical poses remain visible and correct.

Landed flips show a prominent combo notice with the actual awarded points: 1,000 for a single, 3,000 for a double and 7,000 for a triple. Airborne turns are not banked before landing. The HUD and score ledger share `GameSimulation.flipBonus(for:)`; rendering does not award points. Results use an animated score counter and highlight a new local best, with distance, time and flips alongside the total. Ride again, Rankings and Home all use icon buttons; pause and results share the same action-tile style.

## Audio

The Audio tab contains Music, Tracks and Volume. Music can be switched off, play the three bundled tracks in a repeating playlist, or repeat one selected track with **One track**. Selecting a track starts it. The track list is the sole track display; there are no previous/play/next transport buttons. Haptic feedback is separate in General.

Music, engine and effects have separate volumes. Mute all sound preserves those levels; haptic feedback has its own switch. Track selection, playback mode, music enablement, explicit pause, volumes and mute/haptic preferences survive relaunch. Playback position is saved when pausing or backgrounding. Game pause silences the engine while allowing music to continue, and returning to the game does not undo a deliberate music pause. Backgrounding silences audio. System interruptions and a disconnected audio output are handled without rewriting playback preferences or automatically switching music to the speaker.

## Online setup

Game Center IDs and exact App Store Connect configuration are documented in [Game Center setup](GAME-CENTER-SETUP.md) and the [release checklist](RELEASE.md). Native service code alone is not evidence that live leaderboards are configured or that score write/readback has passed. No score is attributed retroactively to a guest or different Game Center account.

The [App Store listing](STORE-LISTING.md) includes English product copy, TestFlight testing instructions and review notes. [Support](SUPPORT-DRAFT.md) and [privacy](PRIVACY-POLICY-DRAFT.md) page drafts are also prepared. Owner contact details and public support/privacy URLs must be completed before submission.

## Source and validation

See [source provenance](SOURCE-PROVENANCE.md), the [accepted brief](IMPLEMENTATION.md) and the [validation record](VALIDATION.md). All app assets are bundled; startup does not fetch resources from the site. The source web checkout is a read-only reference for this project.

## Persistence harness

```sh
xcrun swiftc -swift-version 6 App/Services/LocalStore.swift scripts/check-local-store.swift -o /tmp/crococross-store-check
/tmp/crococross-store-check
```

## Audio harness

```sh
xcrun swiftc -swift-version 6 -module-cache-path /tmp/crococross-audio-module-cache \
  App/Services/AudioService.swift scripts/check-audio-settings.swift \
  -o /tmp/crococross-check-audio-settings
/tmp/crococross-check-audio-settings
```

This Foundation-only harness checks playlist order and wraparound, single-track repeat, selection, preference restoration, legacy track-index migration and invalid volume values. It uses isolated preferences and does not play audio. Actual output, route changes and interruption behavior require simulator/device validation.

## GitHub CI

The workflow uses macOS 26 with Xcode 26.6, matching the locally validated Xcode version. Runner availability is documented in the [official GitHub runner image inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md). The checkout action is pinned to a verified commit; Dependabot checks action updates monthly.

CI checks generated-project consistency, core tests, local persistence, competition-version isolation, audio preferences and playlist behavior, and an unsigned simulator build. UI scenarios stay available in the shared Xcode scheme for focused simulator runs. Physical-device interaction and real Game Center write/read-back require separate validation.

## Competition isolation harness

```sh
xcrun swiftc -swift-version 6 App/Services/CompetitionRules.swift App/Services/LocalStore.swift \
  scripts/check-competition-versioning.swift -o /tmp/crococross-competition-check
/tmp/crococross-competition-check
```

Checks current engine/board matching, rejects stale and future versions, and confirms that the legacy queue is preserved byte for byte. UI validation uses `-ui-testing`, which disables Game Center authentication, refreshes and submissions.

## Physical-device physics benchmark

Launch the signed Release app with **both** `-ui-testing` and `-physics-benchmark`. The first disables Game Center; the second runs 1,000 warm-up steps and 10,000 measured calls to the actual `GameSimulation.step`. It writes `Documents/physics-benchmark.json` in the app container. World creation/reset, input selection, rendering and file IO are outside the timing interval. The report identifies device, build, thermal state, seeds and percentile method. Ordinary launches never run this harness.

This measures solver/game-rule CPU cost. It does not measure total frame time, GPU work, touch latency or subjective play feel.

Character authoring and joint placement: [creation guide](CHARACTER-CREATION.md).

Build 11 increases the in-game camera scale by 18%, retaining its speed-dependent zoom-out, smoothing, adaptive framing and headroom correction. The Home preview scale and physical rider/bike dimensions are unchanged.

Validate the bundled WAV without speaker playback with `scripts/check-death-sounds.swift` (compile alongside `AudioService.swift`). `scripts/trim-death-sound.py` reproduces the trim from a PCM16 WAV decoded from the user MP3. Source and output hashes are recorded in [death-sounds.json](death-sounds.json).
