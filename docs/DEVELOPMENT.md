# Development guide

Native SwiftUI / SpriteKit motorcycle game. Independent from the continuing ChatGPT Sites project.

## Product

- Weekly competition: 4,000 metres, one life, no time limit; Monday 00:00 UTC rollover.
- Endless: three lives, procedural hills, stable-ground recovery and local records.
- Rear-wheel drive, chassis inertia, damped suspension, traction-limited acceleration, natural wheelies and gravity-driven jumps. No owner workshop or automatic upright assist.
- Nine cosmetic riders and nine animated worlds, textured terrain, below-ground details, native audio and haptics.
- iPhone portrait, iPad landscape, adaptive scene bounds for wide/foldable displays. Fixed illustrated buttons sit in the lower left/right corners; Pause stays at bottom centre.
- Game Center only: weekly points, weekly completion time, endless points. Both modes remain playable offline; connection status appears only in Rankings.
- Free; no ads, purchases, custom backend or third-party analytics.

## Open and build

Open `CrocoCross.xcodeproj`, select the CrocoCross scheme and an iPhone/iPad destination. Deployment target: iOS 18.0. The project uses Apple's SDKs and one local Swift package; there are no remote package dependencies.

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

- `Sources/CrocoCrossCore`: portable, Codable 120 Hz simulation, procedural terrain, stunt tracking, weekly date/seed model. Metres, seconds, positive-up coordinates.
- `App/GameSession.swift`: fixed-step clock, render interpolation, run lifecycle, safe pause, records and ephemeral rides.
- `App/Scene`: SpriteKit rendering; no physics authority. Gameplay and decorative randomization are separate.
- `App/UI`: adaptive SwiftUI menus and UIKit-backed cancellable multi-pedal controls.
- `App/Services`: Game Center, persistent score queue, AVFAudio, file storage.

Painted scenery, its independent random placement, asset provenance and isolated visual validation are documented in [Scenery](SCENERY.md). Rider silhouettes, shared wheelbase scale, speed-dependent zoom, preview height limits and recovery/jump framing are documented in [Rider sizes](RIDER-SIZES.md).

Physics constants live in `PhysicsConfiguration`. Score/terrain changes that make records incomparable require a new engine/course version and new Game Center leaderboard identifiers. Existing App Store clients retain their own rule/board versions. Do not port the historical web verification engines or connect the original Sites database.

The current development engine is `native-5`. [Physics tuning and validation](PHYSICS.md) describe the current landing correction and earlier power/terrain pass. The 120 Hz simulation uses three 360 Hz contact substeps, 0.38 m suspension travel, 16,000 N/m springs and 5,000 N·s/m rebound damping. Both suspension stops are solved together to avoid a sequential pitch kick. Rider balance blends with tire clearance, with 80% stronger forward effort while the rear supports a raised front wheel; the right input and fully airborne strengths are unchanged. Tire traction and braking still act only at real contacts. There is no target angle, automatic recovery, landing speed boost or launch impulse.

Motor force ramps up over 0.18 seconds and tapers toward 24 m/s; gravity can carry the bike faster downhill. Full braking remains 2,800 N, split 65% rear / 35% front before traction and stopping-force limits. This preserves strong rear-wheel braking while adding the rider's forward effort during a wheelie. Holding both buttons cancels the lean command while both tire drive and braking remain requested.

Rides are no longer saved or restored. The legacy `active-run-v1.json` file is removed on launch; records, preferences and the pending Game Center score queue remain. The three unpublished Game Center IDs retain their `.v1` suffix for the first release; this is a development transition, not a migration of live scores. After publication, an incompatible physics, terrain or scoring change must advance the engine/course version and use new leaderboard IDs.

## Navigation

Home has one named rider selector with the original Lucide Bike symbol and a Rider label, one named world selector with a World label, two equally sized animated square mode buttons and a fixed bottom bar for Rankings, Settings and Help. Layout switches to the sidebar only when the window is at least 700 points wide. Reduce Motion stops decorative mode-button motion. Rankings, Settings and Help share the same neutral button style and equal dimensions; none appears selected on Home. Every panel has a fixed Close button at bottom right. Settings integrates it beside the section tabs. Choosing a rider or world applies that choice and dismisses the picker immediately; closing without selecting preserves the current choice.

Settings uses fixed bottom tabs: General (haptics), Audio (music and volumes), and About (version, privacy, credits). Personal records and Game Center connection/leaderboards live together in the dedicated Rankings panel. The game HUD uses the same normal presentation in every run; it does not show Practice/Unranked labels or connection notices. Eligibility checks for online score submission remain enforced internally.

## Controls

Two [fixed image buttons](CONTROLS.md) sit at the lower corners: 112 pt square on iPhone portrait and 124 pt on iPad landscape. Their original transparent handlebar PNGs are bundled without visible text or arrows. Procedural rims provide press/release springs, a touch ripple and a held pulse; Reduce Motion uses immediate color feedback. Pause remains a separate button at bottom centre. Both controls can be held independently at once.

Right grip: throttle and backward balance. Left grip and brake lever: braking and forward balance. Rider balance fades in as either wheel clears the ground, alongside any remaining tire contact forces. App input is binary: a Boolean hold maps to 1, release maps to 0. Finger movement never changes power or the button position; the owning touch remains active until lifted or cancelled. There is no slider, power gauge, adjustable accessibility trait or percentage. VoiceOver double-tap toggles a full hold/release. Release, cancellation, teardown, pause and recovery clear held controls. With both tires loaded, inputs rotate the chassis through tire forces and weight transfer alone.

Returning Home or backgrounding the app abandons the ride and resets the controls; relaunch always opens Home. Starting and restarting begin immediately, without a Continue button or confirmation. Manual pause, a transient system interruption, a large layout change or a long frame stall pauses the ride in memory; Keep riding resumes it. Personal records and eligible pending Game Center scores survive leaving the ride. Progress is submitted every 1,200 simulation ticks and when pausing; weekly scores still require finishing. An expired weekly ride can continue locally after a temporary pause, without a status label.

## Effects and scores

The HUD speedometer applies a presentation-only multiplier of 2 to `hypot(vx, vy) * 3.6`. Its display is therefore an arcade scale, not physical km/h; the dial uses a matching 200-unit range. Simulation velocities remain metres per second, course distance is still horizontal progress in metres, and timers/scoring are unchanged.

Landings produce dust and impact feedback. A crash immediately hides the complete rider/bike assembly and dust, and triggers the explosion and bundled sound from the same event. The camera stays steady through the blast. The bike returns only for a respawn, new run or home preview; normal finishes keep it visible. The final score card waits 1.8 seconds after a crash so the blast is visible; finishing or Reduce Motion uses a shorter 0.3-second delay. Reduced Motion also limits the visual effects.

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

CI checks generated-project consistency, core tests, local persistence, audio preferences and playlist behavior, and an unsigned simulator build. UI scenarios stay available in the shared Xcode scheme for focused simulator runs. Physical-device interaction and real Game Center write/read-back require separate validation.
