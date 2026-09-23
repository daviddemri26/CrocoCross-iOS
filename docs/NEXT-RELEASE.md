# Next CrocoCross release

## Status and boundary

Preparation started September 20, 2026. David reports the first App Store version, 1.0.0 (17), awaiting Apple review. This is owner-reported status; no live App Store inspection is part of this change.

Accumulate changes here until David explicitly says to launch and validate the next version. Version/build numbers remain unassigned; the project still carries the submitted baseline's numbers during local development. Do not treat local test builds as distribution candidates. Do not archive, upload, submit for review, publish or change the live Game Center configuration before that signal.

## Accumulated changes

- **Weekly:** finish at exactly 2,600 m instead of 4,000 m. Home, How to, course progress, accessibility text and result completion percentage use the same distance. One life and the +1,000 finish bonus remain.
- **Failed Weekly result:** keep the earned points visible under **TOTAL SCORE**, with one short sentence: “Reach the finish line to validate your score.” Simplified September 21 at David's request to remove repeated validation wording. A failed attempt does not update the Weekly best or submit a Weekly result. Endless results and completed Weekly runs do not show this warning.
- **Pause:** place **Keep riding** below Restart, Settings and Home.
- **Fresh competition:** David requested resetting all previous rankings, including Endless. New local records and pending submissions use `box2d-2`; earlier results are not imported. Physical tuning is unchanged. Rider, world and audio preferences are retained.

## Finish celebration and result hierarchy

Added September 21, 2026:

- Failed Weekly results retain the 46 pt **GAME OVER** heading, reduce the score from 72 to 42 pt, and enlarge the single finish-line explanation from 13 to 18 pt. Successful Weekly and Endless score sizes stay unchanged.
- The finish flag is nearly twice as wide, on a taller pole. A translucent black-and-white vertical checker strip extends from the road to the top of the view, including when an airborne rider puts the road below the screen. It is visual artwork with no collision body.
- Crossing 2,600 m saves the result immediately, then runs five active foreground seconds at 0.5× physical speed before the victory card. The bike coasts with no input or added impulse; the scene stays in full color.
- Two bounded confetti jets use lime, gold, teal and white, accompanied by an original 0.9-second major arpeggio and the existing success haptic. Reduce Motion substitutes a small stationary sprinkle. Audio honors mute, Effects volume and the device silent setting.
- A post-finish head/body impact releases the same physical ragdoll without a crash event, lost life, defeat sound or change to the winning result. Score, finish bonus, distance, flips and elapsed race time stay fixed throughout the maximum 300 presentation steps.
- A transient app interruption freezes the celebration. Leaving the app returns Home while keeping the result already recorded at the line.

## Catalog and world-course preparation

Added September 20, 2026:

- Both selection lists now show all nine existing entries. Rocco and Canyon remain the only playable selections.
- Eight riders and eight worlds are locked. Following David's correction, every locked entry shows its own artwork with the same light blur and gentle color treatment. Each locked card shows its name, a prominent padlock, and a reserved **TO UNLOCK** area.
- Until requirements are chosen, that area says **Requirements coming soon.** No completion threshold, purchase or automatic unlocking rule has been invented.
- Locked cards cannot select or dismiss the picker; stale stored selections also fall back to Rocco/Canyon.
- Each world has a staged route identity, road-artwork identity, readiness and score scope. Only Canyon is ready. Distinct terrain generation and per-world score persistence are future work, not active behavior in this change.
- David selected **one shared world for everyone each week**. Future Weekly events must freeze a common world, route revision and seed for the whole occurrence. Endless/local records will be separated by world and route; exact terrain profiles and unlock conditions remain to be designed.

See [worlds, routes and unlocks](WORLDS-AND-UNLOCKS.md). This addition follows the same release hold as the earlier changes.

## Game Center reset to activate at release

Use fresh boards so both modes start at zero, with no migration of previous entries:

| Board | New identifier | Behavior |
|---|---|---|
| Weekly Score | `com.daviddemri.crococross.weekly.score.v3` | Recurring seven days, highest points |
| Weekly Time | `com.daviddemri.crococross.weekly.time.v3` | Recurring seven days, lowest centiseconds |
| Endless Score | `com.daviddemri.crococross.endless.score.v3` | Classic, highest points |

All three identifiers are staged in the app; none has been created or reset remotely by this work. At the authorized release, configure/attach the new boards, use matching Monday 00:00 UTC periods for Weekly, and retire the old boards from the new version's visible leaderboard list. Until the new configuration is available and confirmed, local play remains available.

Old local records/queues are not read into the new competition, and old/future rules or board identifiers cannot submit to it. Legacy storage is inert; the new version does not display or migrate its scores.

## Local validation

### Weekly, pause and score-reset batch

Validated locally on September 20, 2026 with Xcode 26.6 / iOS 26.5 simulators:

- All **60 core tests pass** (101.533 s), including the exact 2,600 m finish, a single +1,000 bonus, three seeded completions, terrain density and versioned weekly fixtures.
- The standalone competition check passes: new boards/records/queue, rejection of old and future versions, and no import of the earlier score queue.
- Four UI scenarios pass on both **iPhone 17** and **iPad Pro 11-inch (M5)**: Home, Weekly pause/navigation, Weekly crash/retry, and Endless final life/retry. The initial simultaneous run passed six of eight; iPad crash/retry and iPhone Endless encountered interruptions, with the failed iPad capture showing Pause. The unchanged scenarios passed separately in 59.916 s and 36.721 s. No production pause guard was changed.
- Game Over and Pause screenshots were visually inspected on both formats: the warning is fully readable, points remain visible, and Keep riding appears below all secondary pause actions.
- Xcode project regeneration is unchanged; `git diff --check` passes. The compiled simulator plist contains the three v3 IDs. Version/build numbers remain 1.0.0 (17) as the development placeholder.

Evidence: `artifacts/qa/next-version/` (core/competition logs, initial and isolated `.xcresult` bundles, screenshots). Local QA uses `-ui-testing`, which disables Game Center authentication and submissions. Full physical-device gameplay QA and live Game Center validation remain release checks; the owner-requested development installation is recorded below.

### Locked catalog batch

- Both catalog/navigation scenarios passed on iPhone 17 and iPad Pro 11-inch (M5), four runs with zero failures, after correcting the cards' accessibility identifiers.
- The final light-filter version passed the full nine-rider/nine-world lock, scrolling, available-selection and restored-preference scenario on both devices (60.819 s / 53.672 s).
- Final screenshots were inspected: every locked image remains recognizable with the same light filter; names, padlocks and requirement text keep full contrast. Rocco/Canyon remain available and full-color.
- The three new Swift files are included in the regenerated Xcode project; regeneration is deterministic and `git diff --check` passes. No core physics or live ranking behavior changed in this catalog batch.
- Evidence: `artifacts/qa/next-version/catalog/light-filter.xcresult`, `final.xcresult` and the named iPhone/iPad PNGs beside them. The initial catalog run caught an accessibility wrapper exposing cards as Other instead of Button; the UI was fixed before the passing runs.

### Finish-celebration validation

- All **64 core tests pass** (58.495 s), including four new checks for coasting, airborne landing, head-first post-finish detachment, frozen results and the bounded presentation budget.
- The Game Over/retry and finish-celebration scenarios pass on both iPhone 17 and iPad Pro 11-inch (M5), four runs with zero failures. The finish scenario covers both ordinary and inverted airborne approaches, delayed victory, unchanged score, retained life and no invalid-score message after winning.
- iPhone and iPad screenshots were inspected for the result hierarchy, enlarged flag, translucent checker guide, confetti and full-color post-finish fall. The finish-card capture includes its existing entry animation; it is not a settled marketing screenshot.
- Debug device signing/build succeeds. Project regeneration is deterministic and `git diff --check` passes.
- This batch was also installed and launched normally on David's physical iPhone 17 on September 21, after retrying an interrupted device connection. The phone uses the ordinary start flow, without near-finish test arguments. No App Store or remote leaderboard changes were made.
- Evidence: `artifacts/qa/next-version/finish-celebration/`. UI scenarios use offline Debug-only near-finish fixtures; this does not claim a full 2,600 m human playtest or live Game Center verification.

### Owner-requested iPhone installation

On September 21, 2026, the accumulated changes were built and development-signed in Debug, installed on David's paired iPhone 17, and launched successfully with `devicectl`. The local build retains the temporary 1.0.0 (17) version numbers. The first connection attempt was interrupted; installation succeeded after reconnecting to the available device.

This confirms installation and process launch, not a full on-device gameplay or live Game Center validation. No archive, upload, App Store submission or remote leaderboard configuration was performed. Evidence: `artifacts/qa/next-version/device-2026-09-21/`.

The simplified Weekly result copy was then rebuilt, installed and launched on the same iPhone on September 21. The existing UI assertion was updated to match the single sentence and **TOTAL SCORE** label; the UI suite was not rerun for this wording-only change. Build/install/launch evidence: `artifacts/qa/next-version/device-2026-09-21/weekly-copy/`.

## Before the authorized release

- Review all accumulated changes, then assign the next version and build numbers.
- Prepare updated App Store copy/screenshots/support pages from the final candidate; keep the first submission package as historical evidence.
- Configure all three fresh boards and confirm the old boards are absent from the new version's ranking UI.
- Verify real completed Weekly score/time and Endless entries in the intended Game Center environment; local tests cannot establish live submission success.
- Perform final physical-device QA, archive/sign, upload and submit only after David's launch signal.
