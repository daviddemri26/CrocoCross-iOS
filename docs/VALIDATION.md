# Validation record

Updated September 12, 2026. Native implementation is complete; this is a development candidate, not a production-validated release. This record distinguishes local evidence from the external checks still required.

## Environment and source isolation

- macOS 26.5.1, Xcode 26.6, iOS 26.5 SDK, Swift 6 with strict concurrency.
- iPhone 17 and iPad Air 11-inch (M4) simulators, iOS 26.5.
- The original Sites checkout remains clean at `4525d7d32ee874849ef664e1063df7001238f88f`. No source, database or deployment change was made there.
- Native assets and audio are bundled. No remote Swift package or original website service is required to launch and play.

## Core and persistence

- **27 core tests passed, zero failures**, in 13.58 seconds. Evidence: `/tmp/crococross-core-tests-final.log`.
- Coverage includes suspension equilibrium, traction-induced wheelies, airborne gravity, recoverable angled contacts, crash/respawn, finite-state validation, exact simulation restore, stunt scoring, exact 4,000 m finish distance, and deterministic weekly fixtures.
- Weekly tests cover UTC Monday boundaries, year boundaries, daylight-saving independence, seven-day duration and immediate restart, matching occurrence metadata, and rejection of invalid schedules.
- Automated input controllers completed six full procedural weekly courses, with one life, using the normal pedal inputs. This proves reachability for those seeds; it does not establish human difficulty or enjoyment.
- An endurance test simulates one hour of riding and checks bounded, finite state.
- **LocalStore harness passed**: round-trip, atomic replacement, missing save, preservation of corrupt/unsupported-version files, path confinement and idempotent removal. Command: `xcrun swiftc -swift-version 6 App/Services/LocalStore.swift scripts/check-local-store.swift -o /tmp/crococross-local-store-check && /tmp/crococross-local-store-check`.

## Interface and visual review

- Earlier integrated suites passed five iPhone tests and four iPad tests, covering settings persistence, weekly save/restore, menus and all nine rider/world pairs.
- Inspection of all 18 iPad catalog/ride captures and eight representative iPhone captures confirmed complete menus, aligned motorcycle artwork and visible biome scenery. It also exposed defects that automated existence checks did not catch.
- Corrected recursive audio volume setters that crashed the first integration build. The regression test changes all three volumes, relaunches, and checks persisted values.
- Corrected low HUD contrast, the Cloud Nine background ending above the pedals, and the home preview retaining the previous run's crashed pose.
- Corrected start/resume timing and layout observation: hiding system bars must not count as a window resize, and the first rendering interval after a menu transition must not simulate menu time or immediately pause the ride.
- Strengthened UI checks to require a hittable throttle, no pause/results overlay, and increasing distance after acceleration. The focused iPad acceleration regression passed and its screenshot shows an active ride at 33 m.
- A device-orientation change in the iPad simulator did not change the actual landscape window geometry. The old test incorrectly expected a resize pause; the revised test checks actual window dimensions before choosing the expected state. This is not evidence of a real window resize or Duo pose transition.
- **Final strengthened suites passed: five iPhone scenarios and five iPad scenarios, zero failures**, respectively 219.60 and 230.88 seconds. Both suites check all nine rider/world pairs, active acceleration, audio persistence after relaunch, weekly save/restore and background pause/resume.
- Final result bundles: `/tmp/crococross-ui-iphone-verified.xcresult` and `/tmp/crococross-ui-ipad-verified.xcresult`. The viewport attachments record 1,180 × 820 points before and after both iPad device-orientation requests: the interface remained landscape, so real resizing remains unverified.
- Four final Cloud Nine home/ride captures were inspected on iPhone and iPad. The background now covers the full viewport, and the HUD, Continue button and rider caption are readable. Buttons and text are not clipped; the foreground caption partially overlays the decorative tires on the compact home screen.
- Durable local copies of the screenshots, dimensions and build/test logs are in `artifacts/qa/2026-09-12`, with a `proof-index.json` mapping captures to their tests. These generated artifacts are excluded from Git.

## Builds and signing

- **Final Release build for arm64 iPhone passed with signing disabled**: `/tmp/crococross-release-unsigned-final.log`.
- Swift 6 simulator builds passed. The only routine build warning is skipped App Intents metadata extraction because the app does not use App Intents.
- **Final development-signed arm64 iPhone Release build passed at 16:00:27 PDT** after the owner locked and explicitly unlocked the login keychain. Evidence: `/tmp/crococross-device-after-unlock.log`, including `CodeSign` and `BUILD SUCCEEDED`. It uses the existing Apple Development certificate and app provisioning profile.
- Independent `codesign --verify --deep --strict` verification outside the command sandbox **passed**: the final app is valid on disk and satisfies its designated requirement. The earlier sandboxed trust error did not reproduce in this verification.
- The earlier local signing failures, including Xcode GUI at 15:47:45, were keychain decode/integrity errors surfaced as `errSecAuthFailed (-25293)` and `errSecInternalComponent`. Reloading the keychain resolved the observed failure without creating/revoking certificates or changing trust settings or key ACLs. Details: [SIGNING-DIAGNOSTIC.md](SIGNING-DIAGNOSTIC.md).
- **Physical installation succeeded at 16:01:02** for `com.daviddemri.crococross`; `/tmp/crococross-install-after-unlock.json` records `outcome: success`, with the matching `/tmp/crococross-install-after-unlock.log`. The connected iPhone reports iOS 27.0 beta.
- **Physical process launch succeeded at 16:01:35**, PID `63065`, and a process listing at 16:02:20 confirmed it remained running after 45 seconds. Durable build/install/launch evidence is in `artifacts/qa/2026-09-12/logs`, including `crococross-launch-physical.*` and `crococross-running-physical.*`. Human gameplay, audio and sustained performance remain unverified.

## Duo toolchain

Apple specifies Xcode 27.1 and DeviceHub for the dedicated iPhone Duo simulator. On September 12, the authenticated Apple downloads list offered Xcode 27 RC, not 27.1. Xcode 27 RC also requires macOS 26.6 or later. Following the owner's instruction to download only the Duo testing version, no alternative Xcode version or macOS upgrade is being installed.

The app uses scene bounds and independent safe-area insets, but adaptive iPad screenshots do not establish tested Duo compatibility. Sources: [Apple Duo preparation](https://developer.apple.com/videos/play/tech-talks/111461/), [Xcode system requirements](https://developer.apple.com/xcode/system-requirements/).

## Remaining release gates

1. Confirm visible startup and controls with the owner on the physical iPhone. The local signing failure is resolved; the signed build, independent signature verification, installation and process launch have passed, with the process still running 45 seconds later. Human interaction remains to be checked.
2. Physical play sessions: handling and difficulty, multitouch cancellation, headphones/Bluetooth, silent switch, background/lock interruptions, sustained frame rate, memory and heat.
3. Configure the independent App Store Connect app and the three Game Center boards documented in `GAME-CENTER-SETUP.md`. Prove real score write/readback for the correct player and weekly occurrence; repeat with another player and account/network transitions.
4. Test actual iPad window resizing and dedicated Duo opening, closing, rotation and safe areas using the supported SDK and hardware when available.
5. Complete support/privacy URLs, owner contacts, asset rights confirmation, store disclosures and release screenshots; draft copy is in `STORE-LISTING.md`.
6. TestFlight validation and App Store review. No upload, public release or live leaderboard submission has been performed.
