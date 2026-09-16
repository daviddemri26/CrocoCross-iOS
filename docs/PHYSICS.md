# Physics — Box2D / box2d-1

CrocoCross now uses **Box2D 3.1.1** for all integration, collisions and joints. There is no parallel custom contact solver. SpriteKit only draws snapshots. See the [accepted migration plan](BOX2D-MIGRATION.md) and [validation record](VALIDATION.md).

## Five physical bodies

The 150 kg total is divided between chassis (84 kg), two wheels (8 kg each), pelvis (15 kg) and torso/head (35 kg). The chassis mass centre compensates for the other bodies so neutral balance stays near the original motorcycle's centre. Wheel radius remains 0.32 m, wheelbase 1.58 m, travel 0.38 m, and target static sag 30%.

Wheel joints provide suspension, finite travel limits and motor/brake torque. The pelvis follows a bike-relative posture using a force-limited motor joint. A limited hip hinge joins pelvis to torso. Neither joint targets the world vertical. The soft posture correction lets the pilot absorb an impact instead of instantly springing back against the frame.

The head and torso have real terrain collisions. After three consecutive ticks of body contact, the run loses one life and the pelvis-to-bike attachment is removed. Linear and angular velocities are preserved; there is no ejection impulse. The hip remains connected, with passive motion. Arms and legs use visual two-segment joints; they are not additional collision bodies.

## Inputs and speed

- Right button: rear-wheel drive and backward rider effort.
- Left button: wheel braking and forward rider effort.
- Both held: zero net lean while motor and brake efforts remain requested.
- Rider effort increases continuously as either wheel clears the ground. Forward effort gains extra authority only when the rear supports a raised front wheel.
- Rear drive requests up to 1,450 N equivalent wheel force, with a 0.18 s rise and 0.065 s release. Effort tapers toward 24 m/s; speed is not clamped on descents.
- Brake effort is 2,800 N equivalent wheel force, 65% rear and 35% front. Real joint torque and contact friction determine stopping and pitch response.

Input-driven air torque remains deliberate arcade assistance. It never corrects orientation without player input. There is no upright target, landing speed injection, wheel teleportation or automatic launch.

## Time, terrain and coordinates

Gameplay runs at 120 Hz with four Box2D substeps per tick. The current descending terrain generator is retained to keep the engine comparison meaningful. Its collision surface is sampled every 0.25 m into continuous 64 m chains with shared ghost vertices. A bounded window covers approximately 128 m behind and 256 m ahead.

Game positions remain Double values. Box2D's local Float origin shifts on either axis when the chassis is over 512 m from the current origin. All active dynamic and terrain bodies translate together by multiples of 256 m between steps. Velocities and global snapshots stay unchanged. Contacts are sampled before translation; regression checks cover the next steps as well as the immediate snapshots.

`GameSimulation` owns one world and is neither Codable nor Sendable. Snapshots remain Codable/Sendable. Reproducibility means identical inputs in independently created worlds on the same build; encoding a snapshot does not restore Box2D's private solver state.

## Crash and competition lifecycle

During terminal crash presentation, up to 216 additional physics steps show the fall without changing score, clock or lives. Endless recovery advances its timer and then constructs a fresh rig at the last stable checkpoint. Normal results, leaving the run and restarting release the old world.

The engine/course identifier is `box2d-1`. New records and pending-score storage have their own namespace, and Game Center uses `.v2` board IDs. Old records, rider preferences and pending submissions are retained separately and never retagged. New rankings require matching configured boards; offline play remains available.

## Calibration evidence

The complete rig settles at **0.8134 m** chassis height and **0.11393 m** wheel compression (29.98% sag). Suspension frequency is **4.57 Hz**, damping ratio **5.0**. These values were measured with the rider attached; they are not conversions of the old spring constants.

The pelvis attachment allows up to 8,829 N and 300 N·m, with a 0.05 positional correction factor. The hip motor is limited to 220 N·m and 3 rad/s. The force limits keep the rider supported during hard landings while the soft correction avoids a sharp return kick. The motor-joint translation target is rotated from chassis coordinates into the world coordinates required by Box2D 3.1.1.

Flat drops start at 1.5 m chassis height, with forward speed 12/16/20 m/s and initial vertical speed −2/−4/−8 m/s, followed by three seconds of neutral input:

| Matrix | Minimum forward speed retained | Highest upward rebound | Outcome |
|---|---:|---:|---|
| 9 aligned drops | 97.69% | 0.604 m/s | All remain active |
| 18 drops at ±20° | 97.69% | 0.493 m/s | All remain active |

Maximum compression is 0.383 m, including about 3 mm of solver tolerance at the nominal 0.38 m limit. Extreme falls down to −35 m/s stay finite; a crash is an acceptable outcome. On flat ground, holding the right pedal reaches 14.17 m/s at two seconds and stays active for the ten-second fixture. The 1,450 N drive setting is 6.5% below the initial prototype, putting ordinary flat acceleration below its rear-wheel tipping threshold.

The binary-input corpus completes 24 one-minute rides (12 seeds at two speeds) without losing a life. Three full 4 km weekly courses and three real terrain flips also complete. These controlled tests establish recoverable behavior, not a guarantee for every landing or subjective proof that the tuning is final.

Full measurements and validation are recorded in [VALIDATION.md](VALIDATION.md); local per-case data and runners are under `artifacts/qa/2026-09-16-box2d/core/`. Numbers from the historical section below refer only to the previous custom engine.

---

## Historical native-5 checkpoint

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
