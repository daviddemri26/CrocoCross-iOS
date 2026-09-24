# Japan Mountains — first playable course

Local next-release preparation requested September 22, 2026. This prototype combines a distinct physical route with a wide Japanese panorama, road textures, pines, wayside details and petals. No publication or live leaderboard change is included.

## Riding character

Japan uses its own deterministic `japanMountains` terrain profile. The September 23 refinement gives its mountain crowns a visibly pointed silhouette: two-metre pitch transitions, uneven twin ridges, and alternating early/late main peaks. Medium and tall crowns are about 25% narrower than the initial Japan profile and 42% narrower than Canyon in the measured corpus. Low, medium and tall sections still appear in seeded groups, with a gentle opening and long descending receptions. Taller main ridges alternate with smaller shoulders; valleys remain rounded so the suspension has time to settle.

The motorcycle, gravity, grip, suspension, throttle and air-control parameters are shared with Canyon. Jumps come from tire contact and speed; the new course adds no launch impulse or automatic correction. Canyon's existing generator remains unchanged.


## Panorama and foreground — September 23, 2026

The live Japanese scene uses a new opaque 3:1 Fuji panorama (`japan-panorama.png`), while the catalog retains the existing `japan-mountains.png` painting. Its height is at least 1.60 times the viewport and its horizontal travel remains linear at 8 screen points per camera metre, independent of motorcycle zoom. Three reusable tiles overlap by 8%; a one-edge GPU fade blends an incoming painting over an opaque neighbour without reflecting its landmarks. Forward/reverse movement, jumps and viewport changes retain coverage. Reduce Motion and the home preview freeze decorative parallax. Canyon retains its previous path unchanged.

The approved fox and koi-pond images remain intact. Both pond size budgets grow about 1.52 times; a fixed world-space footing keeps the enlarged subject legible in the foreground. The mushroom vignette is replaced by a transparent vermilion torii with a mossy stone base. Following owner feedback, its presentation budget is 9 m wide by 9.2 m high, more than three times the initial small-gate treatment. Roughly one third of placements align the road with the transparent opening, 30% up from the painted base; the lintel sits above the helmet. Following the next owner correction, all torii draw in the foreground, so the rider passes behind their opaque pillars/base and remains visible through the transparent opening. The subset comes from existing seeded depth and does not change while scrolling. Other large gates stay below the road as foreground architecture and can extend beyond the viewport. These are decorative sprites with no collisions.

Native terrain/scenery captures show the full pond in portrait and on gentle landscape ground; steeper landscape examples can naturally crop the bottom at the viewport edge. Placement remains tied to world ground rather than clamped to the screen. Original sources, exact built-in imagegen prompts and hashes are in [Japan art prompts](japan-art-prompts/README.md); coverage, GPU and scene evidence is in `artifacts/qa/kenji/japan-panorama-2026-09-23/`.

## Unlock

- Land 50 frontflips in Release; Debug uses 2.
- A frontflip is a forward rotation (negative angle in the core), banked only after a safe reception. Backflips, incomplete/failed rotations and home-screen previews do not count. Multiple landed frontflips count individually.
- Progress accumulates immediately across runs and modes, including a run later abandoned or lost. It stops at the requirement, bounding the event history.
- The Japan card shows the count and progress bar. Reaching the threshold enables **TAP TO UNLOCK**; it does not automatically select the world.
- A tap saves the unlock before a short pink-petal reveal. **Ride in Japan** selects the world; **Not now** leaves it available. Reduce Motion uses a short fade.
- Debug and Release use separate local saves. Read failures preserve existing data; write failures remain retryable. A claim is never presented as saved before the write succeeds.

## Modes and records

Japan is an Endless course. The chosen world is shown on the Endless button. A new random seed generates a fresh course at each Endless start or restart. Weekly explicitly stays on Canyon: every player receives the exact same course throughout the UTC week, with a new shared course each Monday. These differences are explained beneath the home mode buttons, in the world picker and in How to play. A run freezes its course at start; its terrain, scenery and score storage all use that identity.

This remains the unreleased first Japan route; its internal route identity stays at `japan.route-1` during this tuning. The remote Game Center ID uses `route_1` because App Store Connect does not allow hyphens in leaderboard identifiers. Existing local development records are preserved. Japan's local Endless record is scoped to `box2d-2.japan.route-1`. Its dedicated Game Center board is `com.daviddemri.crococross.endless.japan.route_1.score.v3`. Existing Canyon record keys and board stay intact. Pending results retain the original world and route revision; routing rejects cross-world or mismatched revisions. Japan never enters the Canyon leaderboard. The rankings panel names the selected world and offers its specific Endless board plus access to all rankings. Other worlds remain locked.

The new online board is prepared in code and configuration only. A Japan run can start ranked only after Game Center confirms that exact board. Until remote configuration is authorized, Japan saves local records; an unavailable Japan board does not disable Canyon or Weekly. See [Game Center setup](GAME-CENTER-SETUP.md) for the held remote setup and real-score read-back steps.

## Validation

See `JapanTerrainTests`, `FrontflipFixtureTests`, `JapanWorldUITests`, and `scripts/check-world-progression.swift`. Offline UI fixtures require both Debug and `-ui-testing`; fixture progress is stored separately from player data.

### September 23 terrain refinement

Only Japan's six authored profiles changed. The seed schedule, 60 m section length, entry, downhill baseline, shared interpolation, Canyon/Weekly geometry and motorcycle parameters stayed unchanged. Each two-metre crown transition spans eight Box2D ground segments at the existing 0.25 m sampling; the curve retains continuous height, slope and curvature.

Geometry was sampled at 0.05 m over 2,600 m for seeds `0, 1, 3, 42, 913, UInt32.max`. Crown widths use mature medium/tall sections and the region above 85% of their height relative to the descending baseline.

| Metric across seeds | Initial Japan | Refined Japan |
| --- | ---: | ---: |
| Mean crown width | 5.25–5.32 m | 3.94–3.99 m |
| Maximum main-ridge height above baseline | 6.56–6.71 m | 7.11–7.28 m |
| Maximum crest curvature | 0.587–0.599 /m | 0.960–0.981 /m |
| Maximum valley compression curvature | 0.214–0.223 /m | 0.179–0.187 /m |
| Maximum absolute slope | 0.665–0.699 | 0.643–0.654 |
| Shortest measured downhill reception | 15.85–16.75 m | 14.15–14.40 m |

The unchanged 24-run corpus (seeds 1–12, target speeds 12/16 m/s, 60 seconds, binary pedal holds of 100 ms) completed with **zero crashes**, all riders active and all three lives. Distances were 640.65–661.74 m at target 12 and 720.34–737.58 m at target 16, above the existing 630/700 m gates. Before refinement, the same seeds reached 654.75–677.97 m and 724.07–749.15 m respectively. The new terrain produced 19–24 substantial landed jumps per run (at least 0.3 s airborne and over 0.6 m clearance); each run's longest flight was 1.90–2.375 s.

New checks compare the 25th, 50th and 75th crown-width percentiles with Canyon, reject contact chatter as a jump, and perform natural backflips on Japan seeds 3/8/11 followed by three seconds of safe riding. The authored high-ridge range now allows the intended taller peaks; existing slope, valley compression, reception length, crash and traversal gates were retained. All **6 Japan tests** and the complete **72-test core suite** passed.

Evidence: `artifacts/qa/kenji/chassis-japan-2026-09-23/terrain-qa.md`, the before/final geometry JSON, same-seed CSV, riding comparison JSON and test logs. These automated controls establish stability and traversal, not a human assessment of fun or difficulty.
