# Box2D migration — Rocco first

Approved September 16, 2026. Baseline: `ca740ed` (52 core tests passing), pushed to `origin/main` before implementation. Work is isolated on `codex/box2d-rocco`.

## Accepted behavior

- Replace the custom integrator/contact solver completely with pinned Box2D 3.1.1, compiled as C17 in the local Swift package. SpriteKit remains rendering-only.
- Preserve fixed 120 Hz gameplay and start with four Box2D substeps. Natural contacts, zero material restitution, damped suspension, no scripted upright correction or landing speed injection.
- Keep expressive input-driven rotation, current acceleration as the reference, and stronger forward balance only while the rear supports a raised front wheel.
- Keep the current descending terrain generator, weekly 4,000 m rules, three-life Endless, offline play, and both binary controls.
- First playable rider is **Rocco only**. Retain the eight other characters/assets for later adaptation; do not ship their combined artwork against the independent pilot rig.
- The owner explicitly allows improving Rocco's drawing, fine details, style and proportions during this work. Preserve the recognizable green crocodile / orange helmet / orange bike identity; prioritize clean articulated anatomy and readability at phone scale over exact pixel matching.

## Motorcycle and pilot

- Five dynamic bodies: chassis, rear wheel, front wheel, pelvis, torso/head. Redistribute the existing 150 kg total rather than adding rider mass.
- Two wheel joints, 1.58 m wheelbase, 0.32 m radius and 0.38 m travel. Calibrate static sag to 30%, preserving the current approximate 0.814 m resting chassis height and ground clearance.
- Pelvis uses a chassis-relative motor joint with bounded force/torque. Torso uses a limited revolute hip joint with a bounded posture motor. Targets are relative to the bike, never the world vertical.
- Rider weight transfer supplements controls. Recalibrate manual airborne torque rather than doubling input authority. Motor applies rear-wheel torque with opposite chassis reaction; brakes act on wheel rotation.
- On a confirmed crash, detach the pelvis from the bike and disable posture drive; preserve body velocities and internal hip limits. No artificial launch impulse or force-spike-only ejection.
- Freeze score and run time while continuing a bounded physical crash presentation. No repeated loss of life from detached-body impacts; cleanup and recreate all bodies on respawn.

## Interfaces and presentation

- `GameSimulation` owns a unique Box2D world and is neither Codable nor Sendable. Keep `step(input:)`, read-only `state`, `terrainHeight(at:)`, and scoring constants.
- Snapshot values remain Codable/Sendable. Add `RigidBodyState` (position, velocity, angle, angular velocity), `RiderState` (pelvis, torso, isAttached), and `SimulationState.rider`.
- Add `stepPresentation()` for terminal crash motion without advancing gameplay tick, score or lives.
- Chassis rendering follows chassis pose at fixed scale; wheels and rider follow their own interpolated poses. Rocco receives derived transparent artwork layers and anchored two-segment visual limbs. Retain original images unchanged.
- Terrain uses 64 m chain chunks sampled on a global 0.25 m grid, correct upward collision winding and ghost-vertex joins, approximately 128 m behind / 256 m ahead.
- Keep global Double coordinates. Validate rare common translations of all local bodies on both axes beyond 512 m, in multiples of 256 m. Box2D 3.1.1 has no native ShiftOrigin; continuity must be measured.
- The owner confirmed a fresh start for records. New `box2d-1` rules, local records, pending-score storage and v2 Game Center boards are isolated from legacy data. No external leaderboard configuration or live score submission is part of development validation.

## Implementation gates

1. Vendor/compile and prove independent world lifecycle, flat suspension, terrain joins and origin rebasing before replacing production simulation.
2. Integrate the five-body motorcycle and rider; migrate fixture/replay tests without depending on obsolete JSON world restoration or value-copy semantics.
3. Connect app lifecycle, detached crash presentation, score namespaces and the Rocco render rig.
4. Calibrate with identical scenario inputs and record actual measurements. Never weaken a failing assertion solely to hide a physical defect.
5. Run core, lifecycle/storage checks, generated-project check, iOS/iPad builds, visual QA and physical-device Release validation.

## Acceptance

- Aligned drops at 12/16/20 m/s and ordinary vertical impacts up to about 8 m/s: no unexplained rear kick, peak rebound below 1.2 m/s, at least 90% horizontal speed retained after settling on flat ground.
- Moderate ±20° drops: controllable recovery, at least 80% speed retained on flat ground, no prolonged second flight. Extreme 12–20 m/s impacts must remain finite and not tunnel; crashes may occur.
- Both directions of balance with either tire supporting, left wheelie boost selective, transitions smooth, no passive upright torque.
- Rebase at rest, in flight, on one wheel, during full compression and across a seam: continuous global snapshots and no false crash/landing/flip. Test reverse travel and distant respawn.
- Deterministic same-build replay, independent worlds and at least one simulated hour with bounded bodies/memory. Benchmark Release physics (initial target p95 under 1 ms/tick on the physical iPhone) separately from render performance and subjective feel.
- Visual anchors remain connected while riding; detachment preserves pose; art never stretches the chassis to match wheel motion. Original art and eight deferred characters remain available in source.

## Validation status

The replacement and app integration are implemented. Verified local evidence on September 16, 2026:

- **57 core tests pass, zero failures, 52.534 seconds** in `artifacts/qa/2026-09-16-box2d/core/swift-test-final.log`. This supersedes the earlier 53-test integration run; the 52-test count remains the native-5 baseline only.
- The four added origin/lifecycle checks cover either single-wheel support, full compression, reverse travel through seams/rebases and distant crash/respawn. The same suite covers deterministic independent worlds, actual flips and bounded crash presentation without extra score or life loss.
- All 27 recorded ordinary drops remain active: minimum forward-speed retention 97.691% aligned / 97.686% at ±20°, with maximum rebound 0.6042 / 0.4926 m/s. Full values and fixture definitions are in `core/metrics.json` and `core/README.md` beneath that evidence directory.
- Three complete weekly courses and 24 binary-input rides pass. A simulated hour reaches 82,006.213 m with 160 rebases and three lives retained. World size remains at most 13 bodies/eight chunks; the isolated Box2D allocation counter stays at 1,933,736 bytes after warmup, not a whole-process memory measurement.
- The articulated renderer passes 11 active asset checks and 525 nominal attached postures. Four native offscreen captures were inspected (neutral, wheelie, landing, detached). These checks establish asset geometry and selected poses, not every transient pose or phone UI behavior.
- Debug simulator integration, competition-version isolation, 22 audio checks and exact MIT license packaging pass. The opt-in benchmark exports actual `GameSimulation.step` timings; an earlier simulator export smoke test does not establish final physical-iPhone performance.

### Final app/device evidence

- Signed Release **1.0.0, build 8** compiles and installs on the physical iPhone 17 (`iPhone18,3`, iOS 27.0). The offline benchmark launched and returned its JSON report; the subsequent normal launch also succeeded at 15:50:42 PDT (`device-launch.json`).
- Two focused final iPhone simulator UI tests pass in 60.340 seconds: image pedals/pause and crash/results/retry. One iPad landscape readability test passes in 13.933 seconds. Final iPhone riding and iPad screenshots were visually inspected with Rocco visible. The full nine-world UI suite was not rerun for expedited delivery.
- Physical iPhone Release physics benchmark: **10,000 measured steps after 1,000 warmup steps; median 0.003791 ms, p95 0.004625 ms, max 0.093666 ms**. This meets the initial p95 <1 ms target for the recorded solver workload. The script uses real binary inputs and resets after crashes (17 measured resets); creation/reset, rendering and IO are excluded. Thermal samples remain nominal (0 → 0); Low Power Mode is off. Report: `artifacts/qa/2026-09-16-box2d/device-physics-benchmark.json`.

Remaining: owner playtest of control feel, articulated motion, landings and difficulty, and sustained app frame-rate/memory/heat checks. Solver timing does not establish GPU or complete-frame performance. No live Game Center score write/readback is claimed. See [VALIDATION.md](VALIDATION.md) for logs and scope.
