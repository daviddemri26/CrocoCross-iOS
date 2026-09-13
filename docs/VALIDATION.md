# Validation record

Updated September 12, 2026. Native implementation is complete; this is a development candidate, not a production-validated release. This record distinguishes local evidence from the external checks still required.

## Latest artwork candidate — September 13, 2026

- All nine worlds now bundle 54 decorative images and 18 terrain materials. The corrected artwork passed 108 targeted native views in both orientations; details are in [SCENERY.md](SCENERY.md) and [TERRAIN.md](TERRAIN.md).
- The final nine-world gameplay UI test passed in 201.174 seconds after an unchanged retry. Its first attempt encountered an unexpected pause at 0 m in Arctic; that pause was not reproduced and its cause is not established.
- The latest signed Release build, version 1.0.0 (7), installed and launched successfully on David's physical iPhone on September 13. All 72 scenery/terrain files in that app bundle matched the local source PNGs byte for byte. This confirms installation and process launch, not sustained physical gameplay or audio quality.
- Before the GitHub checkpoint, all 34 core tests passed with zero failures in 13.329 seconds. No simulator or media player was launched by these core tests.

## Build 7 — bottom panel actions and immediate choices

September 12, 2026. Version 1.0.0 (7), unchanged engine/course `native-3`.

- Speedometer display changed from x3 to **x2**: the old physical 60 km/h now displays 120. The matching dial range is 200. Physics, course distance, elapsed time and scores are unchanged.
- Home's Rankings, Settings and Help buttons now share equal dimensions, typography and a neutral style. Settings no longer looks permanently selected.
- Every panel has one **checkmark button at bottom right**, replacing the top-right Done action. Settings places it beside General / Audio / About. Other panels reserve a fixed footer. Content and footer occupy separate layout regions, so the last rows can scroll entirely into view.
- Tapping a rider or world applies the choice and immediately dismisses the picker. Closing without a selection keeps the current choice. Choices survive relaunch. Existing pause, Home and fresh-run behavior remain.
- **Three final targeted UI tests passed on iPhone (149.612 s) and three on iPad (151.074 s), zero failures.** They verify equal home-button geometry, all five panel close actions, bottom-right 48-point dismissal targets, absence of Done, full scroll access to the last rider/world and Audio Effects slider, fixed tabs/close during scrolling, immediate selection, preference persistence and the complete weekly pause/Home/restart route.
- Initial tests caught content below the footer and gestures at the outer sheet margin. Layout now reserves the footer's height; test swipes run inside the scroll view. An incremental iPhone run also executed older test methods. The final pass used clean build directories and freshly installed test runners; all three current scenarios ran on each device. Earlier failure logs are retained for traceability.
- Direct visual review confirmed the neutral home bar, checkmarks, aligned pickers and fixed settings footer on portrait iPhone and landscape iPad. 38 final screenshots and test/build logs are retained in `artifacts/qa/2026-09-12-v7`, indexed by `proof-index.json`.
- Release compilation, strict host signature verification and `git diff --check` passed. Build 7 is ready, but the physical installation attempt failed before transfer because David's iPhone was unavailable. Reconnection has been requested; installation/launch are not yet confirmed.
- The original website remains clean and untouched. No App Store submission or online Game Center write/readback was performed in this iteration.

## Build 6 — speedometer display scale

September 12, 2026. Version 1.0.0 (6), unchanged engine/course `native-3`. The speedometer now displays three times the physical simulation speed: 60 becomes 180 km/h. Both visible text and accessibility use this display value. The dial scale increases from 100 to 300 so its relative fill is unchanged. Simulation velocity, elapsed time, course distance, physics and scoring are unchanged. Release compilation, strict signature verification and `git diff --check` passed. Build 6 installed successfully on David's iPhone and launched at 21:06:13 PDT. No new tests were added for this presentation-only change. Evidence: `artifacts/qa/2026-09-12-v6/logs`.

## Build 5 — Endless label

September 12, 2026. Version 1.0.0 (5), unchanged engine/course `native-3`. Removed the small “∞ m” badge from ENDLESS; its decorative infinity icon remains. Weekly still shows 4,000 m. Release compilation, strict signature verification and `git diff --check` passed. Build 5 installed successfully on David's iPhone and launched at 21:01:21 PDT. No new tests were added for this presentation-only change. Build/install/launch evidence: `artifacts/qa/2026-09-12-v5/logs`.

## Build 4 — direct navigation and icon actions

September 12, 2026, evening. Version 1.0.0 (4), unchanged engine/course `native-3`.

- Home labels the selected **Rider** and **World** above their names. The original site's Lucide Bike symbol is drawn natively in the rider selector, with its license retained in source and About. Long names stay on one line. Results now have icon buttons for Ride again, Rankings and Home, using the same action tiles as Pause.
- Returning Home or actually backgrounding the app abandons the ride. Relaunch always opens Home. Start and Restart act immediately, with no Continue button, saved-run notice or replacement confirmation. Manual pause and temporary inactive interruptions retain the in-memory ride for Keep riding; a real viewport change or an active-play stall can still pause it. Closing an overlay or opening Rankings inside the app does not itself abandon the run.
- `SavedRun`, its restoration, autosave and error notices are removed. The migration deletes only `active-run-v1.json`. A pre-existing 1,528-byte build-3 run was present before the first build-4 launch and absent afterward. The selected rider/world, best Endless score (380), haptics, audio enablement, selected track/mode and all three volumes stayed identical. Evidence: `logs/crococross-v4-data-before.json` and `logs/crococross-v4-data-after-migration.json`. Eligible Game Center submissions remain queued separately; same-tick pause/background submissions are deduplicated.
- **Four targeted UI tests passed on iPhone (158.695 s) and four on iPad (169.590 s), zero failures.** Coverage includes the home labels and equal square button geometry, settings and Rankings, two real weekly crashes per device, icon actions on the results card, results → Rankings → Home, pause/resume preserving progress, immediate Restart, Home → another mode, terminate/relaunch, and real background/foreground transitions. Fresh runs assert zero score/distance and released controls. No physics change was made, so the 34-test core result from build 3 remains the applicable core evidence.
- **36 captured views and two viewport reports** are retained under `artifacts/qa/2026-09-12-v4`, indexed by `proof-index.json`. Direct visual review on iPhone portrait and iPad landscape confirmed complete labels and icon buttons, single-line Japan Mountains, consistent pause/results actions and an unobscured home rider. iPad orientation requests kept the app window at its landscape dimensions; this does not establish a dedicated Duo resize test.
- Release compilation passed. **Strict host signature verification passed and the app bundle identifies build 4. Build 4 installed successfully on David's iPhone after reconnection and launched at 20:22:39 PDT**, PID 64675. Verification in the restricted environment initially could not evaluate the trust chain; the host check succeeds. The first physical install attempt could not find the disconnected phone, before any app transfer; the subsequent `install-final` and `launch` logs confirm success. Physical gameplay and audible output remain separate user checks.
- Current documentation matches the simplified navigation and separate Rankings panel. `git diff --check` passes. The original website remains clean at `4525d7d32ee874849ef664e1063df7001238f88f`; no web, database, App Store or Xcode-installation action was taken.

## Build 3 — jumps, braking and navigation

September 12, 2026, evening. Version 1.0.0 (3), engine/course `native-3`. Evidence below supersedes build 2 for the changed behavior; earlier records are retained for traceability.

- **34 core tests passed, zero failures, 13.332 seconds**, from the actual iOS repository after the final review correction. The jump corpus now discards crash/recovery/respawn intervals and requires eight consecutive active contact ticks before accepting a landing. Six 4,000 m weekly completions and three flips from real seeded ramps use the same coupled pedal inputs as the app, with no state rewrite or automatic balance force. Log: `artifacts/qa/2026-09-12-v3/logs/crococross-v3-core-final.log`.
- Braking requests **2,800 N, 65% rear / 35% front**, still limited by actual contact and traction. The controlled wheelie fixture with 90% throttle returns the front wheel in **0.408 s versus 0.675 s**; continued braking stays stable. A 10 m/s stop measures **6.194 m versus 6.688 m**. These are fixture results, not guarantees for every pitch/slope.
- Terrain retains a 10% descending baseline, with two rises per 48 m section and substantially larger main ramps. With the same predictive test rider at a requested 12 m/s ceiling, three completed weekly routes average **169 observed flights versus 61**, **1.33 s versus 0.78 s** in the air, and **1.91 m versus 0.46 m** clearance. Average course time rises from 344 to 416 seconds because these routes require more speed control. The flight measure may include the final flight ending at the finish; it is not a count of validated flips. Source: `logs/final-comparison.json`.
- Home has one rider entry and one world entry, visible names, equally sized animated square launch buttons, and a fixed bottom bar for Rankings / Settings / Help. Decorative animation respects Reduce Motion. Narrow windows use the compact layout; the sidebar requires at least 700 points. Long world names and both tires were checked in the final captures.
- Settings contains only **General / Audio / About**, with tabs fixed at the bottom on both devices. Vibrations are in General. Audio contains music mode, a single track list and independent volumes; there is no duplicate current-track title or transport row. Records and Game Center connection are grouped in Rankings outside Settings.
- The normal HUD is identical for connected/offline runs: **Practice and other ranking-status notices are removed from play/results**. Server eligibility remains checked before submission. Speed uses a dial, distance is more prominent, and pause actions have icons.
- Crashes hide the complete rider/bike assembly, wheels, accessories, shadow and dust immediately. Explosion and smoke remain visible; camera framing holds steady. Both the real UI video and independent frame review show a hidden bike through the effect/results and a complete bike after retry. The recorded ride also contains actual flips and visible successful landings. Visual frames are sampled every 0.25 seconds; audible output still needs owner listening.
- **Full iPhone integration suite: 10/10 passed**, 428.224 seconds. It covers all nine rider/world pairs, wheel animations, volume and track persistence, floating pedals, real crash/results/retry, home/navigation, save/restore and interruptions. The iPad full suite passed **9/10**: its initial transition paused at zero distance during first-track loading. The startup clock now drops loading intervals until the first simulation step while preserving pause-on-stall for an advancing ride.
- **Final focused reruns: 4/4 passed on iPhone (105.519 s) and 4/4 on iPad (115.795 s).** These include the failed initial iPad scenario, active acceleration, home/button geometry, bottom tabs staying fixed after scrolling, Rankings, save/restore and background pause/resume. The corrected route still requires explicit resume after a real background interruption. Bundles: `/tmp/crococross-v3-iphone-polish.xcresult` and `/tmp/crococross-v3-ipad-polish.xcresult`.
- Earlier visual/test passes caught an accessibility wrapper on the new launch buttons and an inherited identifier on the settings tab container. Both were fixed and the final tests target the individual buttons. Generated project consistency and `git diff --check` pass. No new remote dependency was introduced.
- **Development-signed Release build and independent strict signature verification passed. Build 3 installed on David's iPhone at 19:11:21 PDT and launched successfully at 19:12:42**, PID 64356. A filtered process check at 19:14:15 confirmed the same app process remained running after more than 90 seconds. Logs: `logs/crococross-v3-device.log`, `logs/crococross-v3-signature.log`, `logs/crococross-v3-install.*`, `logs/crococross-v3-launch.*`.
- **174 captured views**, comparison/test/build logs and the crash/flip/retry video are retained under `artifacts/qa/2026-09-12-v3`, indexed by `proof-index.json`. The `iphone-polish` / `ipad-polish` folders are the final navigation captures. Generated QA artifacts are excluded from Git.
- Original website remains clean at `4525d7d32ee874849ef664e1063df7001238f88f`. No website or database changes, store submission or new Xcode download. Old `native-1`/`native-2` development rides must restart; personal records and preferences remain. Live Game Center setup/write-readback, dedicated Duo resizing and sustained physical gameplay remain release gates below.

## Build 2 — handling and presentation iteration

September 12, 2026, evening. Version 1.0.0 (2), engine/course `native-2`. Earlier sections below retain the initial-build evidence; the results in this section apply to this iteration.

- Large independent touch zones cover the lower 49% of the viewport, split left/right. Controls appear at the thumb position; the right starts at 90%, the brake at 100%, and a vertical drag can reduce either to zero. Touch identity, release, cancellation, pause, restoration and VoiceOver reset paths are explicit. The pause button is bottom-centre.
- A 10% downhill baseline and five smooth jump profiles replace the balanced hills. Braking is stronger at the rear, with front braking retained only at its tire contact. No automatic upright torque or artificial jump impulse was added.
- **33 core tests passed, zero failures, 10.968 seconds.** Six actual 4,000 m simulated completions, a one-hour endurance run, deterministic weekly/save fixtures and a twelve-seed jump corpus are covered. The jump corpus requires genuine airtime and clearance rather than counting contact chatter. Evidence: `artifacts/qa/2026-09-12-v2/logs/crococross-native2-core-33-tests.log`.
- A dedicated two-control regression holds throttle at 90% during braking: the front wheel returns in 0.675 s while the no-brake control crashes at 0.842 s. Ground-contact-only states and equality with zero lean demonstrate that the recovery comes from tire forces. This controlled fixture does not establish recovery from every possible wheelie. Detailed measurement is stored in `logs/two-thumb-wheelie-measurement.log`.
- **22 audio-state checks passed** for circular playlist navigation, one-track looping, selection, intentional pause, off, saved position, migration, invalid preferences and bounded volumes. The harness is `scripts/check-audio-settings.swift` and now runs in CI. UI tests additionally change and restore all three volumes and a selected playback mode/track after relaunch.
- **The eight-scenario iPhone integration suite passed** in 340.104 s. It covers all nine rider/world pairs, settings, floating controls, actual acceleration, weekly save/restore, interruption, a real uncontrolled crash, score presentation and retry. Result bundle: `/tmp/crococross-v2-iphone-final.xcresult`.
- The iPad integration suite passed seven of eight scenarios. Video showed that its failed volume test overscrolled past Effects. The test now makes short edge drags, verifies complete visibility and can scroll back. **The corrected iPad volume and weekly/navigation tests both passed** in 73.240 s: `/tmp/crococross-v2-ipad-polish.xcresult`. The app's volume behavior did not need a workaround.
- Visual review found world images overflowing grid columns, weak crash-smoke contrast and a low-contrast Practice label on clouds. Images now receive explicit column widths; the original RGBA explosion uses alpha blending and its original 285-point size; Practice and the active power readout have dark backgrounds. Post-fix navigation assertions and captures verify separated, aligned world cards on iPhone and iPad. The crash/retry test passed again after the explosion correction.
- **The final two iPhone touch/selector tests passed** in 49.702 s: `/tmp/crococross-v2-iphone-wheels.xcresult`. A new selector test brings every card entirely into view before taking two delayed captures. An initially excessive 64-point test margin prevented reaching the last row and was corrected; the final Bubbles captures show the complete motorcycle.
- All nine rider illustrations have complete tires and independent rotating rotors. Paired-image review confirms motion for both wheels across all nine riders on iPad and all nine final iPhone selector pairs. Forks remain fixed. Breathing, landing absorption and flight movement are cosmetic and parameterized by rider shape.
- Nine distinct scenic distributions replace the generic bird/animal pair. Surface accents and cutaway scenes remain outside physics: fossils, koi, freight, waterfall, fish under ice, mine train, sailboat, metro, and floating cloud accents. The added accents use a simpler illustrated style than the detailed background art.
- The corrected explosion was inspected frame by frame: visible fireball, dark smoke, sparks, fade and then the score card after 1.8 s. The original explosion sound is dispatched by the same crash event. Physical loudspeaker/headphone listening remains a human check; simulator video is visual evidence only.
- **Final development-signed Release build and independent strict signature verification passed. Build 2 installed successfully on the connected iPhone at 18:07:16 PDT.** The subsequent launch at 18:08:45 was denied because the phone was locked; this is not an app crash. The owner was asked to unlock it for startup verification. Evidence: `logs/crococross-v2-device-final.log`, `logs/crococross-v2-signature-final.log`, `logs/crococross-v2-install.*`, and `logs/crococross-v2-launch.*`.
- 124 captures/measurements, test/build logs, wheel-motion analysis and the corrected explosion video are retained under `artifacts/qa/2026-09-12-v2`, indexed by `proof-index.json`. `iphone-integration` and `ipad-integration` preserve the initial visual pass; `ipad-corrected`, `iphone-corrected` and `iphone-wheels-final` contain the corrected selections. These generated QA files are excluded from Git.
- The source website is still clean at `4525d7d32ee874849ef664e1063df7001238f88f`. No deployment or database action was taken. This development iteration intentionally rejects `native-1` run snapshots; records and audio preferences remain. The unpublished `.v1` Game Center board IDs are retained for the first release. Live Game Center, dedicated Duo transitions and store submission still require the external checks listed below.

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

1. Owner playtest of build 3 handling and difficulty, especially simultaneous throttle/brake and jump timing. Installation and startup are verified; automated test riders do not establish human control feel.
2. Physical play sessions: handling and difficulty, multitouch cancellation, headphones/Bluetooth, silent switch, background/lock interruptions, sustained frame rate, memory and heat.
3. Configure the independent App Store Connect app and the three Game Center boards documented in `GAME-CENTER-SETUP.md`. Prove real score write/readback for the correct player and weekly occurrence; repeat with another player and account/network transitions.
4. Test actual iPad window resizing and dedicated Duo opening, closing, rotation and safe areas using the supported SDK and hardware when available.
5. Complete support/privacy URLs, owner contacts, store disclosures and release screenshots; draft copy is in `STORE-LISTING.md`.
6. TestFlight validation and App Store review. No upload, public release or live leaderboard submission has been performed.

## Repository publication preparation

On September 12, 2026, David Demri confirmed that he created all images and the three music tracks and holds all rights to them, and authorized publication of all bundled project files in the public GitHub repository. See [SOURCE-PROVENANCE.md](SOURCE-PROVENANCE.md). This resolves the earlier repository-privacy and pending asset-rights notes; it does not change the remaining gameplay, Game Center or App Store validation steps.

Before the initial GitHub push, 27 core tests passed with zero failures, the local persistence harness passed, and the unsigned iOS simulator build succeeded. Project regeneration, local Markdown links, YAML syntax and staged-file checks also passed. UI and physical-device tests were not rerun for this documentation and repository setup change.
