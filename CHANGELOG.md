# Changelog

## Next version — unreleased

Changes accumulated for the next owner-authorized release; version/build not assigned yet.

- Restore all nine riders and nine worlds to the pickers, with locked names, large padlocks and reserved unlock requirements. Apply the same lightly filtered preview to every locked entry; keep Rocco/Canyon playable.
- Stage per-world route/road/score identities and a plan for distinct terrain. The future Weekly event will share one world among all players each week.
- Shorten Weekly from 4,000 m to 2,600 m; update the finish line, progress, Home and How to.
- Keep failed Weekly points visible with one short explanation: “Reach the finish line to validate your score.”
- Keep the large Game Over title, reduce failed Weekly scores and enlarge the finish-line explanation.
- Enlarge the finish flag and add a translucent vertical checker guide. Celebrate a Weekly finish for five seconds in full-color half-speed coasting, with confetti and a short original victory cue; falls beyond the line cannot change the saved victory, score or time.
- Put Keep riding below the secondary actions in Pause.
- Start Weekly and Endless records, pending submissions and all three leaderboards fresh (`box2d-2` / Game Center `v3`), with no import of earlier scores.

Preparation and future launch gates: [next release](docs/NEXT-RELEASE.md). No archive, upload or App Store/Game Center change is part of this preparation.

## 1.0.0 (17) — submission baseline

The owner reported this first version awaiting App Store review on September 20, 2026. The following notes describe its earlier preparation:

- Keep the submission package and public support/privacy pages in English only; remove French screenshot sets and metadata.

- Prepare build 17 for manual App Store submission with English/French listing copy, real iPhone/iPad screenshots, opaque icons, bilingual support/privacy pages and a reproducible archive workflow.
- Declare local elapsed-time API use, disable Release testability, and rename the owner-created fall sound without changing its audio. App Store distribution signing and live Game Center setup remain pending.

- Focus the preview on Canyon with continuous background travel and rider-focused crash zoom.
- Center Game Over and total score, show distance/flip point contributions, and enlarge Ride again below the secondary actions.
- Enlarge the HUD score, align solid hearts right with a falling/fading loss animation, and integrate directional flip notices.
- Simplify rider/world selection, remove the preview label, and rebuild How to with grip artwork and clear scoring blocks.
- Open Settings on Audio with Volume first; share an explicit Sound on/off shortcut with Home.
- Use only a stronger Fuel Explosion sound on the third Endless life, shortening the result delay to about 2.35 seconds.

- Use only the GTA death cue, trimmed to 4.09 seconds with a 450 ms end fade; retain full playback and cinematic minimums. Keep detached bodies moving through the audio tail without advancing score or recovery.

- Anchor both palms on the visible handlebar grips and recalibrate forearm reach to retain contact through rider movement.

- Fine-tune the hip/shoulder placement and zoom gameplay in by 18% for clearer rider detail.
- Restore a real-time, full-color explosion replacing the rig on the third Endless life; retain physical slow-motion falls in Weekly and on recoverable Endless crashes.
- Give the death cue a simpler descending boom and more pronounced echoes.

- Integrate the upper arm into the shoulder and the upper thigh into the buttock, with internal pivots and fuller muscle volume; document the rules for future riders.
- Fade the crash filter over 0.65 seconds and add a deeper impact with fading echoes.

- Stabilize Rocco’s attached posture with a connected waist, bounded torso lean and smooth movement; move the thigh joint into the hip, refine limb proportions and enlarge the biceps.
- Preserve lives on upright hard landings when the skid plate grazes the ground; confirm crashes from tilted rider or overturned chassis contact.
- Play physical falls at half speed with a subtle warm grayscale scene effect.

- Replace the custom contact engine with pinned Box2D 3.1.1: independent chassis, wheels, pelvis and torso, damped wheel joints, and physical rider detachment on a confirmed crash (`box2d-1`).
- Introduce articulated Rocco artwork with independent suspension, hands and feet; keep the eight other riders in source for a later rig adaptation. All nine worlds remain selectable.
- Isolate new records, pending submissions and Game Center v2 boards from legacy physics; keep offline play available.

- Softer landing suspension, simultaneous two-tire bottom-stop response and stronger left-button balance during rear-wheel support (`native-5`); acceleration and right-button tuning retained.

- Revised landing suspension, progressive rider balance on either wheel, smoother power delivery and varied downhill terrain (`native-4`).

- Realistic right/left handlebar images, a left brake lever and animated programmatic button rims, without labels or arrows; fixed positions and binary hold/release replace sliding power adjustment.

- Nine illustrated worlds with distinct riding surfaces, fixed foreground textures and image-based scenery.
- Coherent Paris streets and San Francisco Bay scenery, with larger buildings, vehicles and boats that can pass in front of the rider.
- Stable ground-object perspective, depth-dependent sky motion, improved backdrop framing and coverage during high jumps.
- Proportional rider artwork, improved Home framing and camera reset after an Endless respawn.
- A compact status bar with lives on a separate row; removal of terrain review labels, motorcycle shadow and recovery text.
- Weekly 4,000 m challenge and three-life Endless mode, deterministic physics, local records and optional Game Center integration.
- Immediate new runs and restarts; returning Home or leaving the app ends the current ride.
- Rewritten product README with ten current native iPhone simulator screenshots.
- Core, native interface, rendering, scenery and persistence checks, plus release and asset documentation.

Live Game Center validation, remaining device checks and distribution are tracked in [the release checklist](docs/RELEASE.md). This entry does not represent an App Store release.
