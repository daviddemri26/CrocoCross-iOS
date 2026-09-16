# Changelog

## Unreleased

Current native iOS development candidate:

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
