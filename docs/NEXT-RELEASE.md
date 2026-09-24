# Next CrocoCross release

## Current candidate and authorization

Prepared candidate: **1.1.0 (18)**. David authorized preparing the candidate and a local signed archive/export, then committing/pushing reviewed changes to GitHub main. Automatic binary upload, App Review submission, public release and live Game Center configuration are **not** included. Signed-in checks on **September 23, 2026** confirmed **1.0.0 (17), Ready for Distribution**, and the owner-created **1.1.0 draft**, **À finaliser avant soumission**, with Automatic release retained. The current description, promotional text, keywords, What's New and App Review notes were saved in that draft. TestFlight has only 1.0.0 (17), uploaded September 16; build 18 remains local.

The Release **1.1.0 (18) archive succeeded and its code signature was verified**. IPA export failed with `No Accounts` / `No signing certificate "iOS Distribution" found`; reconnecting the Xcode account and supplying distribution signing remain required. **97 core tests**, Release Store-capture tests on iPhone 17 Pro Max and iPad Pro 13-inch (M5), and **584 package checks** passed. Both refreshed screenshot contact sheets and all 40 achievement badges were visually reviewed. The images are prepared locally; the Store draft still has its inherited screenshots.
Current scope includes the 2,600 m Weekly course, Kenji/Japan earned unlocks, Japan scenery, separate Weekly score/time and per-world Endless records, flexible controls, expressive detached limbs, and **40 local achievements / 1,000 points**. The six additional rotation milestones are 250, 500, 1,000, 2,500, 5,000 and 10,000 safely landed rotations, combining both directions.

Readiness still depends on successful distribution export, uploading the reviewed screenshots when authorized, final physical-device validation and account/declaration review, **four v3 leaderboards**, and remote configuration/localization/association of the **40 achievements**. `CrocoGameCenterAchievementsEnabled` remains absent/false until remote achievements are configured and verified. Configure the two Weekly recurring boards once with matching Monday 00:00 UTC starts, seven-day duration and restart; Game Center creates later occurrences automatically. No advance week creation or history UI is required. See [release gates](RELEASE.md) and [handoff](../distribution/HANDOFF.md).
The dated sections below preserve the development record. Earlier 1.0.0 (17) placeholders, 34-achievement counts and release-hold statements describe their original batches; this current section supersedes their preparation boundary. `distribution/review/store-status.json` remains explicitly historical September 17 evidence, not a fresh statement about Apple's review state. No upload or publication is claimed here.

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

## Kenji character and backflip unlock

Added September 23, 2026 (local development):

- Kenji is an articulated Shiba Inu on a blue/white superbike, using eleven original transparent layers, calibrated hand/foot contacts and the shared SpriteKit rendering rig. Gameplay physics, collisions and competition rules are unchanged.
- Each safely landed backflip adds to permanent local progress immediately, across Weekly, Endless and unranked practice. A double backflip counts twice. Losing or leaving afterward retains progress; frontflips and failed figures do not count. Old scores are not reconstructed into this counter.
- The card shows the requirement, progress bar and `current / target`. At the target it displays **TAP TO UNLOCK**; an explicit claim is saved before a two-second blue/white reveal and **Ride with Kenji** action. Reduce Motion uses a short fade; sound and haptics follow existing preferences.
- Debug uses **2 backflips** in `rider-progression.debug.json`; Release already uses **50** in `rider-progression.json`. Debug claims cannot unlock the production catalog. No manual threshold edit is needed at release.
- All other riders remain locked. World availability follows the separate Japan unlock described below. No public release, remote ranking or App Store changes accompany this character work.
- Sources/prompts and asset provenance: `docs/shiba-rig-prompts/`. Native preview/diagnostic commands: `scripts/rider-preview/README.md`.

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


### Kenji final artwork, progression and device validation

Validated September 22, 2026 locally (September 23 UTC):

- The full Kenji progression suite passed five scenarios each on iPhone 17 and iPad Pro 11-inch (M5), ten runs with zero failures. It covers locked progress, real safe receptions across modes, claim/reveal, interruption and persistence. Standalone progression checks pass in Debug and Release, including the distinct 2/50 thresholds and storage.
- After the owner's final pelvis/tail and boot corrections, the complete claim/reveal/first-ride/relaunch scenario passed again, sequentially, on iPhone 17 Pro (39.663 s) and iPad Pro 13-inch (M5) (38.442 s). Gameplay assertions remain strict. The earlier simultaneous attempt encountered an interrupted/paused start and an unavailable picker after relaunch; a bounded sheet-ready wait was added to the test helper. No production pause protection was changed.
- The final native renderer passes 208 posture samples and 180 animated frames, including two full rotations, boot-cuff and waist contacts, camera changes and detachment continuity. Maximum contact/joint error is below 0.0000003 m. Six Rocco reference poses remain byte-identical to the prior renderer. Source and bundled PNG/manifest hashes match the tested final candidate.
- The signed Debug build, including the parallel Japan changes, was installed and launched normally on David's paired iPhone 17. The first transfer lost its connection; the fresh retry succeeded. No UI-test, progress-seeding or automatic-claim arguments were used. David can earn two safe backflips, then tap Kenji's card to unlock and select him. Version/build remain the development placeholder 1.0.0 (17).
- This confirms automated checks, visual previews, installation and process launch. A human physical-phone gameplay/audio assessment and live Game Center verification remain separate. The release hold is unchanged.
- Evidence: `artifacts/qa/kenji/progression-qa.md`, `renderer/`, `final-art-iphone-sequential.xcresult`, `final-art-ipad-sequential.xcresult`, `device-asset-verification.log`, `device-build-final.log`, `device-install-retry.json` and `device-launch.json`. Reusable owner directions are preserved in `docs/CHARACTER-CREATION.md` and the authorized memory note.

## Before the authorized release

- Review all accumulated changes, then assign the next version and build numbers.
- Prepare updated App Store copy/screenshots/support pages from the final candidate; keep the first submission package as historical evidence.
- Configure the three fresh Canyon/Weekly boards plus the distinct Japan Endless board, and confirm the old boards are absent from the new version's ranking UI.
- Verify real completed Weekly score/time and Endless entries in the intended Game Center environment; local tests cannot establish live submission success.
- Perform final physical-device QA, archive/sign, upload and submit only after David's launch signal.

## Japan Mountains and per-world Endless — September 22, 2026

- First distinct Japanese course: 60 m seeded sections, shorter rounded summits, more pronounced ridge transitions and long downhill receptions. Motorcycle physics and the existing Canyon course are preserved.
- Unlock Japan after 50 safely landed frontflips; Debug uses 2 in a separate local save. Progress persists immediately across modes and runs, with a counter, explicit claim and pink-petal reveal. Claim writes precede the animation.
- Endless records are separated by world and route revision locally and in prepared Game Center routing. Japan uses `com.daviddemri.crococross.endless.japan.route-1.score.v3`; pending scores freeze their course. Existing Canyon keys and board are unchanged.
- Weekly remains Canyon for every player, with an identical course throughout each UTC week. Endless generates a new random course every ride/restart. Home mode descriptions, the world picker and How to play explain the distinction.
- Japan's online board is only staged. New runs remain local until that exact board is remotely configured and confirmed; unavailable boards do not invalidate other worlds. No remote leaderboard metadata or live scores changed during this work.
- Full core suite passed 69 tests after terrain integration, plus the added real-frontflip fixture test in both modes. The Japanese binary-pedal corpus completed 24 one-minute runs without a crash. Canyon height/slope match the prior implementation bit-for-bit at 602,046 sampled positions. These checks do not replace human tuning feedback.
- Progression checks pass in Debug and Release; competition checks reject cross-world/revision mismatches and preserve legacy Canyon compatibility. Existing terrain/scenery assets pass load/transparency checks. See [Japan Mountains](JAPAN-MOUNTAINS.md) and [Game Center setup](GAME-CENTER-SETUP.md).
- Simulator UI validation passes: all 8 Japan scenarios on iPhone 17 and 5 focused scenarios on iPad Pro 11-inch (M5), with zero failures. Coverage includes actual frontflip receptions across both modes, pause/resume deduplication, durable claim/relaunch, separate local records, Japanese Endless/Canyon Weekly routing and the visible mode descriptions. iPad also checks the existing home/settings layout. Captures of the home screen, unlock, catalog and live Japanese terrain were visually inspected.
- Evidence: `artifacts/qa/next-version/japan-2026-09-22/`; raw result bundles remain at `/tmp/crococross-japan-iphone.xcresult` and `/tmp/crococross-japan-ipad.xcresult`. Tests use offline Debug fixtures and do not establish live Game Center submission success. Project regeneration is deterministic and `git diff --check` passes.

## Kenji chassis refinement and sharper Japan terrain — September 23, 2026

- Kenji's chassis image received a small front-fairing/nose and front-fender trim, improving the fixed front wheel's apparent position. The canvas remains 1634 × 962; all ten other character/motorcycle PNGs, wheel positions, suspension and rider contact calibration are unchanged. Only measured camera `bike.visibleBounds` metadata changed with the new contour. Built-in imagegen prompt/provenance: `docs/shiba-rig-prompts/shiba-bike-v2.txt` and `generations.json`.
- Japan now has narrower primary and secondary crowns, unequal shoulders, and a sharper crest pitch change, with long receptions and smooth valley exits. Mean upper-crown width is about 3.94–3.99 m, compared with 5.25–5.32 m in the prior Japan candidate and 6.87–6.92 m for Canyon across six seeds. This is width above 85% of each ridge's detrended peak. Lowest measured descent length remains 14.15 m. Canyon, Weekly and the motorcycle's physical parameters are unchanged. This continues tuning of the unreleased Japan route-1.
- All 72 core tests pass (57.40 s). The unchanged 24-run binary-control traversal gates pass with zero crashes and sustained progression; meaningful jumps and three safely landed natural backflips are also checked. The discarded taller trial was stable but too slow, so its amplitude was reduced without widening the sharper crowns. These automated controllers do not determine the owner's subjective difficulty preference.
- Kenji's native validator passes 208 postures and 180 moving frames with identical contact/detachment measurements to the prior accepted rig. The two focused app scenarios pass on iPhone 17 Pro: Kenji reveal/ride/relaunch (34.819 s) and Japan Endless/Canyon Weekly routing (30.699 s).
- The signed Debug build was installed and launched normally on David's paired iPhone 17 at 16:59 local time, without test arguments or seeded unlocks. Packaged artwork/manifest hashes and the compiled terrain source hash match the tested candidate. Human gameplay feedback remains the next tuning input; no archive, upload or live leaderboard configuration was performed.
- Evidence and sources: `artifacts/qa/kenji/chassis-japan-2026-09-23/`, [Japan Mountains](JAPAN-MOUNTAINS.md), [character artwork prompts](shiba-rig-prompts/README.md).


## Japan panorama, foreground and home clarity — September 23, 2026

- Japan uses a new wide Fuji panorama, enlarged to at least 1.60 times the viewport height, with continuous camera-driven parallax. Three overlapping tiles blend their edges without reflecting landmarks; camera zoom does not resize distant mountains. Reduce Motion and the home preview freeze decorative movement. Canyon retains its existing presentation.
- The approved koi pond is about 1.52 times larger, with its world-space footing adjusted for visibility. The fox remains unchanged. A transparent vermilion torii replaces the mushroom; following owner feedback it is presented as a large architectural gate, with occasional raised placements. No collisions or physical tuning accompany these scenery changes.
- Home descriptions now read **Same course for everyone.** and **New random course every ride.** The Weekly tile shows only the local calendar date of the next shared-course boundary, on one concise line with no time or visible prefix. The date follows the existing Monday 00:00 UTC schedule and refreshes even with Reduce Motion.
- Original images and exact built-in imagegen prompts: [Japan art prompts](japan-art-prompts/README.md). Implementation and evidence: [Japan Mountains](JAPAN-MOUNTAINS.md) and `artifacts/qa/kenji/japan-panorama-2026-09-23/`.

Validation for the panorama/home batch, including the owner's final gate-size and date-only corrections:

- Panorama checks pass 7,974 assertions across 630 coverage cases, plus 24 composition frames and 10 native SpriteKit/Metal frames. Forward/reverse recycling remains opaque; the old Canyon formula is preserved.
- All three scenery validators pass: deterministic placement, 54 presentation profiles and all 54 transparent images. Final torii bounds are about 8.95 by 9.2 m before seeded scale/depth; 4,121 placements retain 32.0–33.6% raised gates. Fourteen native scenery views check architectural proportions, opening/rider visibility, smaller/larger seeded scales and foreground cropping.
- The eight Weekly boundary tests pass, including UTC turnover and local timezone/DST dates. Both initial iPhone scenarios pass (home/settings and Japan Endless/Canyon Weekly). On iPad the route scenario passes; the initial home/settings run missed a Settings tap, with home still visible. The unchanged standalone retry passes, with no production workaround. This original failure remains in its result bundle.
- After the final date-only correction, home/settings passes again on iPhone 17 Pro (28.993 s) and iPad Pro 13-inch (M5) (36.543 s). The date is one line with no time or prefix; captions remain concise and primary tile labels aligned. These are focused checks, not a new full UI-suite run.
- The signed final Debug build passes, and its bundled art matches the sources. Presentation source hashes stayed unchanged throughout compilation. It installed successfully on David's paired iPhone 17 at about 17:53 local time on September 23. The subsequent launch was refused because the phone was locked (SBMainWorkspace / FBSOpenApplicationErrorDomain Locked); this final build has not been confirmed opened on the physical phone. Unlocking and opening CrocoCross is the remaining manual step. The earlier panorama candidate had launched successfully at 17:41.
- Final evidence: `date-only-iphone.xcresult`, `date-only-ipad.xcresult`, `native-scenery-monumental/`, `device-build-final.log`, `device-bundle-verification-final.json`, `device-install-final.json` and `device-launch-final.json` in the batch QA folder. `git diff --check` passes. No distribution or remote Game Center action was taken.


## Foreground torii, flexible controls and achievements — September 23, 2026

- Every torii is now in the foreground, so the rider passes behind its opaque pillars/base. The large scale and one-third road-spanning placement are unchanged.
- The Weekly date keeps a single concise line without a time and adds context: **Ends Sep 27** (with the actual next boundary formatted locally).
- Broad lower-left/right touch zones control braking/acceleration. Each image settles beneath the first touch, stays anchored while that finger slides, and returns to its resting place on lift. Pause has its own central corridor. Cancel, resize, disable and app interruption clear held inputs. Gameplay physics and binary pedal strength are unchanged.
- Thirty-four achievements cover first safe flips, binary first double/triple jumps (0/1 then 1/1, either direction), 10/50/100 safely landed rotations, every kilometre from 1 through 15 km then every 5 km from 20 through 50 km in one Endless ride, 1/5/10 Weekly finishes, and explicit Kenji/Japan unlocks. Double/triple landings contribute two/three rotations to the shared 10/50/100 totals, adding forward and backward rotations together. A dedicated Achievements dock entry shows local progress and Game Center access, with a brief local completion notification. Rankings stay separate, with two concise Weekly cards for the best score and time and no fixed world name. Local Weekly bests are stored by the frozen weekly occurrence, so changing weeks does not mix courses or erase older records. Confirmed Game Center entries can show each actual server score/time and global rank independently. An Endless link opens the world selector; each supported world's card shows its local record and a separate leaderboard action, regardless of selection or unlock state. Existing claimed unlocks can be recognized; old stunt/distance/finish history is not invented.
- GameKit integration has stable achievement IDs, per-account progress, offline persistence/retry and remote restoration. Guest progress belongs to the first linked account only. Normal Debug and Release builds share one achievement save and behavior at the owner's request; only automated UI fixtures stay isolated. App Store Connect definitions and the common activation flag remain part of the existing release hold; no remote setup or publication occurs in this batch.
- Configuration details and metadata: `docs/ACHIEVEMENTS-GAME-CENTER.md`. Evidence: `artifacts/qa/achievements-controls-2026-09-23/`.

### Final validation of this batch

- Achievement model: 20/20 tests pass, including binary double/triple progress and exact forward/backward cumulative totals. Transport: 29 fake-gateway checks pass in each Debug/Release policy. Weekly records: local store checks and 22 fake-loader checks pass, with independent score/time results and account/occurrence guards.
- Final UI scenarios pass on iPhone 17 Pro and iPad Pro 13-inch (M5): achievements/claim/relaunch, independent Weekly score/time/persistence, and record-bearing world cards through the Endless link. Home/dock and flexible-control lifecycle scenarios also pass on both devices. Screenshots were inspected. Tests remain offline; they do not validate live Apple records or tactile gameplay feel.
- Release and development-signed Debug device builds pass. The final app installed and launched normally on David's iPhone 17 at approximately 22:19 local time on September 23. No fixture arguments were passed. Source hashes remain unchanged through final validation; `git diff --check` passes.
- Evidence and preserved initial test failures: `artifacts/qa/achievements-controls-2026-09-23/README.md`. No publication or remote Game Center setup was performed; the existing release hold remains in force.
