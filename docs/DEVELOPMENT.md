# Development guide

Native SwiftUI / SpriteKit motorcycle game. Independent from the continuing ChatGPT Sites project.

## Product

- Weekly competition: 4,000 metres, one life, no time limit; Monday 00:00 UTC rollover.
- Endless: three lives, procedural hills, stable-ground recovery and local records.
- Rear-wheel drive, chassis inertia, damped suspension, traction-limited acceleration, natural wheelies and gravity-driven jumps. No owner workshop or automatic upright assist.
- Nine cosmetic riders and nine animated worlds, textured terrain, below-ground details, native audio and haptics.
- iPhone portrait, iPad landscape, adaptive scene bounds for wide/foldable displays. Both pedals remain bottom left/right.
- Game Center only: weekly points, weekly completion time, endless points. Offline practice is independent of authentication.
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
- `App/GameSession.swift`: fixed-step clock, render interpolation, run lifecycle, safe pause, records, atomic restore.
- `App/Scene`: SpriteKit rendering; no physics authority. Gameplay and decorative randomization are separate.
- `App/UI`: adaptive SwiftUI menus and UIKit-backed cancellable multi-pedal controls.
- `App/Services`: Game Center, persistent score queue, AVFAudio, file storage.

Physics constants live in `PhysicsConfiguration`. Score/terrain changes that make records incomparable require a new engine/course version and new Game Center leaderboard identifiers. Existing App Store clients retain their own rule/board versions. Do not port the historical web verification engines or connect the original Sites database.

## Controls

Right pedal: throttle on the ground, backward rotation in flight. Left: braking on the ground, forward rotation in flight. Hold then slide down to reduce a pedal's strength; release to return to zero. This is touch position, not unsupported force-pressure detection. Ground inputs do not directly apply rotation torque.

Backgrounding, opening a game menu, a large layout change, or a long frame stall pauses the run. Resume explicitly. An atomic run snapshot is saved every 10 simulation seconds and when pausing; abrupt termination can lose the most recent unsaved segment. A restored run opens paused. An expired weekly run can continue as local practice only.

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

## GitHub CI

The workflow uses macOS 26 with Xcode 26.6, matching the locally validated Xcode version. Runner availability is documented in the [official GitHub runner image inventory](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-Readme.md). The checkout action is pinned to a verified commit; Dependabot checks action updates monthly.

CI checks generated-project consistency, core tests, local persistence and an unsigned simulator build. UI scenarios stay available in the shared Xcode scheme for focused simulator runs. Physical-device interaction and real Game Center write/read-back require separate validation.
