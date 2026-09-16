# Physics and terrain — native-5

## Current correction

This pass addresses a pitch kick after nearly level landings and strengthens the left button when the rear tire supports a raised front wheel. Motor power, throttle response, top-speed tuning, right-button balance, airborne balance and terrain profiles retain their native-4 settings.

## Suspension and stops

| Parameter | native-4 | native-5 |
|---|---:|---:|
| Suspension travel | 0.32 m | 0.38 m |
| Spring rate | 20,000 N/m | 16,000 N/m |
| Compression damping | 2,200 N·s/m | 2,200 N·s/m |
| Rebound damping | 3,400 N·s/m | 5,000 N·s/m |
| Bump stops | Rear then front, sequential | Both tire constraints solved together |
| Gameplay/contact integration | 120 / 360 Hz | unchanged |

The softer spring and extra travel allow more compression. Slower extension reduces the second kick after impact. Compression damping is retained to absorb incoming motion before the suspension reaches its stops.

The earlier bottom-stop loop handled one tire and changed chassis rotation before handling the other. In a very hard, almost level reception this could create a large transient pitch velocity. The new two-contact solve calculates the required impulses from the same pose, including the other tire's remaining travel. It considers both tires, either single tire, or no tire; impulses can only push. Position correction uses the same geometry without adding velocity. The calculation never targets an upright angle or replaces forward speed.

## Left-button wheelie recovery

The left button still requests braking and forward rider effort. When the rear tire is loaded and the front is clear, the forward balance torque now reaches **1.8 times** its previous value. The extra effort fades with rear suspension unloading and with front tire clearance, so no new contact switch is introduced.

The right button's balance torque has not increased. Left balance with only front-wheel support and fully airborne controls keep their previous strength. Both buttons held together still produce zero net lean, while tire drive/braking remain requested. Maintaining a forward command after the front lands can still lift the rear; the rider must release the correction.

## Retained ride settings

- Rear drive: 1,550 N maximum; throttle rise/release time constants 0.18 / 0.065 s; motor force tapers toward 24 m/s.
- Braking: 2,800 N requested, split 65% rear / 35% front and constrained by contact and tire grip.
- Base balance: 550 N·m maximum airborne torque, half authority per fully clear tire; clearance transition spans 0.18 m.
- Terrain: six low/medium/tall profiles, shuffled groups, 64 m sections and 16% baseline descent; analytical height/slope with continuous joins. The generator is unchanged in this pass.
- Fixed 120 Hz input/scoring and three 360 Hz contact substeps. Gravity, tire forces and rider input remain the sources of movement.

The engine/course identifier advances to `native-5`, so old encoded simulation fixtures are incompatible and versioned weekly seeds advance. This changes the seed for the current weekly occurrence without redesigning the terrain profiles. Existing unpublished Game Center board configuration is retained; no online configuration or submission was performed.

## Measurements against native-4

Same flat fixtures, 16 m/s forward, starting 2 m above ground, neutral controls:

| Scenario | native-4 | native-5 |
|---|---:|---:|
| Initial descent −4 m/s, level: peak rebound | 0.603 m/s | 0.355 m/s |
| Initial descent −8 m/s, level: peak rebound | 1.274 m/s | 0.752 m/s |
| Initial descent −16 m/s, level: peak rebound | 1.434 m/s | 0.964 m/s |
| Initial descent −16 m/s, 0.02 rad tilt: peak pitch speed | 7.492 rad/s | 0.206 rad/s |
| Same tilted impact: final forward speed after 1.5 s | 14.898 m/s | 14.882 m/s |

The rebound reduction in these level examples is 33–41%. The near-level pitch example captures the short numerical kick, not a reproduced end-over-end crash. These fixtures do not establish that every possible landing is recoverable.

Regression coverage includes 27 almost-level hard landings at 12/16/20 m/s, exact left/right symmetry of stationary two-tire bottom-outs, 75 passive-energy cases, selective 80% forward-balance gain and continuity when rear support disappears. Existing tests retain six complete weekly courses, real flips, 24 routes with 100 ms binary pedal holds and one hour of bounded Endless state.

## Evidence and device status

The source snapshots, runners and before/after results live locally under `artifacts/qa/2026-09-15-soft-landings/`. See [the validation record](VALIDATION.md) for final test/build results. Those artifacts are intentionally ignored by Git.

The signed Release build of native-5 has been installed and launched successfully on David’s iPhone 17. Installation and launch do not replace physical-device play testing of the revised landing and left-button response.
