# Milo — monkey on an electric scooter

September 26, 2026. Local development version with a calf-thickness adjustment following David's first physical-device feedback. The updated app is validated and installed for the next iPhone playtest; the earlier candidate's results are preserved below.

## Requested identity and unlock

Milo is the new third rider after Rocco and Kenji, keeping all previous catalog entries. The working name is Milo, stable catalog ID `monkey`. Brown monkey fur, cream muzzle, backwards red/white cap, sunglasses, red short jacket, olive cargo trousers and high-top sneakers create the new identity. A contemporary ivory/charcoal seated electric scooter has a step-through frame and wide footboard.

David confirmed **100 safely landed backflips** for Release and **2 for Debug**. Existing Kenji counts and claims are preserved, including previously stored totals above 100. Backflips accumulate across modes and runs, including rides subsequently lost or abandoned. Frontflips, unfinished rotations and repeated callbacks do not contribute. The threshold enables an explicit durable claim and reveal; it does not silently change the selected rider. Debug and Release save files remain separate.

## Artwork and articulation

Eleven genuine PNG parts are stored in `App/Resources/GameAssets/MonkeyRig/`; prompt text and provenance live in [monkey-rig-prompts](monkey-rig-prompts/README.md). The first bent calf candidate was rejected and regenerated as a separate straight shin. No production bitmap was painted or substituted by code.

The same SpriteKit rig reads Milo's independent manifest. The scooter's wheelbase stays 1.58 m and tyres 0.64 m diameter. Hand contacts target the visible grips; sole contacts target the actual footboard. The thigh overlaps deeply into a single side-profile hip, the upper arm covers the torso's shoulder, the waist stays joined, and the shin enters the sneaker through its top opening. Art calibration changes presentation only; physics, controls and scoring remain the same.

The narrow home preview uses 80% of the normal preview scale so Milo's upright cap and face remain below the logo. The road anchor and wide home layout retain their existing behavior. Jungle's gameplay camera separately accommodates its larger gaps and higher jumps.

After the first playtest, David approved the remaining character and scooter visuals and requested thicker shins/calves only. Milo now uses `presentation.calfThickness: 1.25`: a 25% increase along the calf's transverse axis, with the same length, anchors and cuff contact. All eleven source PNGs and their alpha channels stay unchanged. Boots, palm/sole contacts, the rest of the character and the scooter retain their existing calibration. The shared rig defaults this parameter to `1` for Rocco and Kenji.

Validation covers alpha on light/dark backgrounds, full limb reach, cuff/sole/palm/waist contacts, neutral, wheelie, flight, compressed landing, complete rotations and detached falls. Rocco/Kenji regression checks accompany the new rig. Simulator and physical-device observations are recorded separately in the final validation evidence.

## Historical first-candidate validation

These results describe the candidate before the calf adjustment. They do not establish validation of the updated app. Evidence is under `artifacts/qa/next-version/milo-2026-09-26/`:

- `RIG-VALIDATION.md`: 208 posture samples, 180 native motion frames with two full rotations, detached continuity and limb motion, original-rider regression checks. Rocco's six compared poses remain pixel-identical to the baseline.
- `native-rig/neutral-light.png` and `neutral-dark.png`: the assembled production rig on light/dark backgrounds. `milo-native-motion.mp4` is a three-second scripted native preview, not phone gameplay.
- `independent-art-review/`: source alpha, anatomical overlaps and original PNG hashes checked independently. The final calibrated manifest preserves all eleven source PNGs.
- `rider-progression-debug.log` and `rider-progression-release.log`: exact 2/100 thresholds, old Kenji-save migration, persisted event deduplication, separate claims and write-failure recovery.
- `iphone-test-summary.json` and `ipad-test-summary.json`: eight iPhone and six iPad UI tests passed. After the visual review's home-framing correction, two focused iPhone scenarios and one iPad scenario passed again on the final source. The final screenshots are in `iphone-final/` and `ipad-final/`.
- `device-debug-final.log` and `device-release-final.log`: successful final iOS builds. The Debug app's signature and both bundles' twelve rig files were verified.
- `validated-source-hashes.json` and `unchanged-core-evidence.json`: final source identities; the core, core tests and articulated renderer are unchanged from the Jungle implementation's 105 passing core tests.

No new dedicated Game Center achievement is introduced. The existing rider-unlock flow remains local and independent of leaderboard records. Physical installation was initially deferred until the phone could be connected; the follow-up below supersedes that initial status.

## Physical iPhone follow-up

On September 26, 2026 at 18:24 America/Los_Angeles, David requested installation and the paired iPhone 17 became available. The validated first-candidate Debug build was installed and launched successfully without test fixtures, superseding the earlier connection deferral. The unlock thresholds remain two backflips for Milo and two frontflips for Jungle in this test build. David's subsequent driving feedback led to the calf-only adjustment above. Evidence for the earlier installation: `physical-iphone-install.json` and `physical-iphone-launch.json` in the validation folder.

## Updated-candidate validation

The calf comparison and native rig evidence are stored in `artifacts/qa/next-version/jungle-tuning-2026-09-26/milo-calves/` (`REPORT.md`, `comparison.html` and source hashes). Milo passes 208 posture samples and 180 native motion frames with unchanged numeric contacts. All eleven Milo PNGs remain byte-identical; all 28 Rocco and 31 Kenji regression images are pixel-identical.

The combined candidate passes Debug/Release iOS builds, four final iPhone scenarios and two iPad scenarios across the recorded runs. The iPhone camera test's unsupported landscape expectation was corrected and its portrait rerun passes. Both device bundles contain the twelve matching Milo rig files with thickness 1.25. The signed Debug app was installed and launched normally on David's iPhone 17 on September 26 at 18:56 America/Los_Angeles, without fixtures; two-backflip test unlocking remains in place. See the sibling `INTEGRATION.md` for exact run results and installation evidence. This confirms delivery, not David's assessment of the revised driving feel.
