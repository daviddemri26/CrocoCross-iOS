# Tropical Jungle — route 6 mixed takeoffs

September 27, 2026. David requested greater variety: horizontal departures to lower platforms alongside ramp launches, a shared sound control directly in Pause, waterfalls sometimes below the route, and slightly larger animals. Route 6 is validated and delivered to David’s iPhone for playtesting; release remains on hold.

## Access and competition

Tropical Jungle is third in the world picker. Unlock requires 100 cumulative safely landed frontflips in Release, 2 in Debug, followed by its own claim/reveal. Milo remains the third rider, unlocked by 100 safely landed backflips in Release and 2 in Debug. Approved character artwork and calf proportions are retained.

Each Endless start uses a fresh random seed. The run freezes `jungle.route-6`, local key `bestEndless.box2d-2.jungle.route-6` and prepared board `com.daviddemri.crococross.endless.jungle.route_6.score.v3`. Earlier route 1/2/3/4/5 scores remain in their original keys; frozen queued identities cannot be relabelled. Canyon, Japan and Weekly retain their course and record scopes. Weekly remains the same Canyon course for every player in that UTC week. Remote Game Center creation/activation and publication are outside this work.

## Riding variety

The 132 m sections retain the introductory 18 m gap and receiving edge 1.5 m above takeoff. Six ordinary motifs vary the ramp length, curvature, lip angle, timing, receiving slope and run-out:

| Motif | Gap | Reception above takeoff | Approach and run-out |
| --- | --- | --- | --- |
| Steep rising jump | 18 m | +3 m | Later, steep lip; gently descending reception |
| Progressive climb | 22 m | +4 m | Longer 34 m ramp; uphill receiving platform |
| Lower sweeping launch | 26 m | +1 m | Lower, differently curved ramp; downhill reception |
| Long crossing | 30 m | −1 m | Approved large ramp retained |
| Widest crossing | 34 m | −2 m | Approved large ramp retained |
| Rolling interlude | 14 m | +1 m | Short low ramp; shallow dip and roller afterward |

One crossing per six sections, starting with section six, instead uses a 38 m gap with a +1 m bank or a 40 m gap with a −1 m bank. These are occasional: the opening five sections and the ordinary 14–34 m motifs remain. A deeper acceleration hollow and a low curved takeoff preserve momentum through the ordinary physics. The receiving platform still leaves recovery room for the next jump. The ordinary 26 m motif receives 0.5 m lower than route 4 (+1 m above takeoff) to retain wheel clearance after a recovery following a new larger crossing.

Starting with the fourth section, approximately one crossing in three leaves a twelve-metre horizontal deck. The new motifs are:

| Departure | Gap | Reception below takeoff | Reception and run-out |
| --- | --- | --- | --- |
| Short horizontal drop | 16 m | 5.5 m | Level receiving shelf, then a gradual run-out |
| Long horizontal drop | 24 m | 10.5 m | Gentle downhill receiving shelf, then a gradual run-out |

Both use normal momentum and gravity, with no jump impulse. Their deck heights and twelve-metre receiving shelves preserve momentum into the next ramp. Existing 14–34 m ramp motifs and occasional 38/40 m crossings remain. Slow approaches can still miss the longer drop.

Receiving differences are absolute world heights, including the descending grade. Seeded gap positions vary more widely, changing the distance between takeoffs. Real platform surfaces and their cliff walls still come from `solidSpans`; the interpolated guide over a hole never creates physical ground. A too-low arrival hits the receiving wall. Wheel-only wall contact does not count as a landing.

Checkpoints retain 60 m of supported approach and the normal 3.5 m/s recovery speed. The Jungle camera now follows the rider closely and never zooms out to fit a gap or its receiving bank. Its target scale is at least 25.96 pt/m, with modest speed-based variation. Vertical following tracks the flight with a small bounded lead, keeping the rider visible while the distant bank may remain offscreen. Zoom retains the earlier velocity/acceleration limits and rider-centred pivot; crash transitions remain progressive. Tire forces, suspension, gravity, braking and air controls are unchanged; no automatic boost or pose correction is applied. Tree-to-tree platform artwork remains deferred.

## Route 6 validation

Evidence: `artifacts/qa/next-version/jungle-diversity-2026-09-27/`. All 114 core tests pass, including 13 Jungle terrain tests. All 84 recovery approaches and seven 90-second binary-control rides pass. New flat-departure tests confirm horizontal lip velocities, distinct drops, real cliff clearance and failure without enough momentum. The lowest flat-crossing clearance in the seven-seed recovery corpus is 1.432 m. All 84 camera replays pass over 529,200 frames with no hidden tested rider bounds. Debug/Release competition checks pass. Eight native scenery renders and the focused app scenarios pass: four on iPhone (the Pause scenario passed after correcting a test-only world-picker tap) and three on iPad. Signed Debug and unsigned Release builds, signature and bundled-art checks pass. The signed Debug app (1.1.0, build 18) was installed and launched normally on David’s paired iPhone 17 at 15:51 PDT on September 27, without fixture arguments. A first transfer lost its connection; the fresh attempt succeeded. Automated controls establish tested reachability; David assesses human difficulty and enjoyment.

## Historical route 5 validation

Evidence: `artifacts/qa/next-version/jungle-close-2026-09-26/`. All 84 tested recovery approaches pass, including 14 exceptional crossings; the lowest measured wheel clearance at those larger receiving rims is 0.234 m. Six of seven 90-second pedal-controlled rides complete without a crash; the fixed controller crashes at 1,021.85 m for seed 7, whose isolated recovery crossings still pass. Camera replays pass 84 screen/rate combinations with close framing, bounded zoom and the complete tested rider bounds visible; offscreen receiving banks are explicitly permitted. Debug and Release competition checks pass, including retired route 4 rejection and preserved record keys. The full core suite passes 113 tests; three iPhone and two iPad UI scenarios pass, as do signed Debug and unsigned Release builds, signature validation and bundled asset verification. The signed Debug app (1.1.0, build 18) was installed on David's paired iPhone 17 at 20:49 and launched normally at 20:50 PDT on September 26, without UI fixture arguments. These checks establish reachability under the tested controls; David assesses human difficulty and enjoyment.

## Jungle scenery

The existing background painting now spans 2.4 viewport heights, versus 1.45 in portrait and 1.30 in landscape. Its three overlapping tiles scroll continuously at 5 screen points per metre instead of approaching the old 24-point horizontal limit. A GPU subtexture uses the central half of the existing painting, removing its framing palms; a 16% edge blend joins its forested edges without mirrored landmarks. The shader normalizes the subtexture coordinates before fading, so the overlap remains effective. The background follows global rider displacement, independently of the gameplay camera's zoom or framing; vertical travel is bounded to ±64 points. Preview and Reduce Motion freeze background motion. No source painting was edited.

Waterfall/pool vignettes use 15.125 × 14.3 m size budgets, 2.75 times the old width and height. They remain in front of the rider. A stable 60% subset sits entirely beneath the road; the others keep the 3.85 m base depth and rise above it. This selection uses the existing seeded depth, so scrolling or zoom cannot toggle a waterfall between placements. Their entire footprint plus 6 m on either side must fit a connected platform, leaving takeoff and receiving lips clear. A stable 36 m spacing rule avoids clusters. The tapir is 20% larger (3.84 × 2.88 m budgets); the frog is 25% larger (2.375 × 2.125 m). Source PNGs and proportions are unchanged. See [scenery sizes](SCENERY-SIZES.md).

Pause now contains the same `SoundToggleButton` and `AudioService` state as Home and Settings, in all worlds and modes. Muting/unmuting does not resume the ride; the selected state follows the player back to Home.

## Historical route 4 camera and foreground follow-up

David requested waterfalls in the foreground and slower zoom transitions. This presentation-only pass keeps route4, its seeds, physics and records unchanged. The production `JungleCamera` is replayed over seven real 90-second pedal-controlled trajectories in four viewport shapes at 30/60/120 fps: 84 cases, 528,836 frames, including 109,904 airborne-void frames. All measured receiving banks and rider bounds remain visible. Log-scale speed is limited to 0.48/s outward and 0.22/s inward, with 0.9/s² acceleration; no instantaneous outward clamp remains. The wider view opens early and survives transient contacts. Waterfall dimensions and ledge margins are retained, with the original foreground draw order restored.

Evidence: `artifacts/qa/next-version/jungle-camera-2026-09-26/`. Replay and scenery checks pass, as do two final iPhone and two final iPad UI scenarios, signed Debug and unsigned Release builds, signature validation and bundle asset verification. The signed Debug app was installed on David's iPhone at 20:18 and launched normally at 20:19 PDT on September 26; physical gameplay feedback remains with David. The route4 validation below describes the previous delivered candidate.

## Route 4 validation before the camera follow-up

Evidence: `artifacts/qa/next-version/jungle-variety-2026-09-26/`. The full core suite passes 112 tests, including eleven Jungle cases. All 84 recovery approaches succeed; six of seven 90-second binary-controller rides finish without a crash. The one failure loses momentum before a 26 m crossing around 1,551 m; that crossing succeeds from a normal recovery. The lowest measured recovery lip clearance is 5.4 cm, so the 26 m motif remains demanding. Canyon/Japan/Flat geometry is identical across 753,444 sample pairs. Debug/Release local competition checks pass. Eighteen standalone native background captures and geometry/wrap checks pass. Final in-game tests pass three iPhone scenarios and two iPad scenarios, including portrait/landscape apex captures and the enlarged waterfall. Debug/Release builds, signature and bundled artwork checks pass. The signed Debug app was installed on David's paired iPhone 17 at 19:52 and launched normally at 19:53 America/Los_Angeles on September 26. No test fixture arguments were used. This proves installation and process launch; human gameplay assessment remains David's next step. Automated reachability and visual inspection do not establish human difficulty or enjoyment; David's next playtest remains the feel assessment.

### Historical route 3 validation

Evidence for this candidate is stored under `artifacts/qa/next-version/jungle-challenge-2026-09-26/`. The confirmed terrain corpus includes 84/84 recovery approaches (seven seeds × twelve gaps), each starting 60 m before the lip at the normal 3.5 m/s speed. A binary controller reacts every 100 ms and targets 24 m/s through the ordinary pedals; that target is not an imposed velocity. Seven 90-second rides from the normal course start succeed with the same controller. Tested passive approaches fail around 117–118 m; clearing the gaps requires an active approach rather than coasting through the first section. These automated results establish reachability under the tested controls, not human difficulty or fun.

Local competition checks pass in Debug and Release; `versioning/` records rejection of retired route 1/2 identities, separation of their retained record keys, and unchanged Canyon/Japan/Weekly scopes. The complete core suite passes 111 tests, including ten Jungle cases and four cliff-collision cases. Three iPhone UI scenarios and one iPad scenario pass. Debug/Release iOS builds, the Debug signature and bundled resources are verified. The signed Debug app was installed on David's iPhone 17 at 19:21 America/Los_Angeles. Automatic launch at 19:22 was blocked by the device lock; no launch success is claimed. See `INTEGRATION.md` in this candidate's evidence folder. The earlier route 2 results below remain historical.

### Historical route 2 validation

Route 2 used 72 m sections, an introductory 6 m gap, later gaps of 7–11 m and 24 m recovery approaches. Its records retain the `jungle.route-2` scope. The following validation describes that earlier candidate, before route 3's larger gaps, raised banks and physical walls.

Evidence: `artifacts/qa/next-version/jungle-tuning-2026-09-26/INTEGRATION.md` and `VALIDATION.md`. The full core suite passes 106 tests; all nine Jungle tests pass again after extending the Debug-only capture fixture. Twenty-one prepared one-minute rides cross the wider gaps without a crash, and 105 recovery approaches pass at 24 m. Slow approaches can still fail. Canyon/Japan/Flat remain bit-identical over 753,444 height/slope pairs.

Four distinct final iPhone scenarios and two iPad scenarios pass across the recorded runs. The camera test initially requested unsupported iPhone landscape; its test-only assumption was corrected and the portrait scenario passed on rerun. Native screenshots of a physically reached third-jump apex were inspected on iPhone portrait and iPad portrait/landscape. Jungle widens its view for the gaps and bounds airborne framing to keep the rider and reception visible together.

Debug/Release competition checks and iOS builds passed. The signed Debug app was installed and launched normally on David's iPhone 17 at 18:56 America/Los_Angeles, without test fixtures. David's subsequent playtest found route 2 too easy and prompted route 3. Earlier route 1 results below describe their original candidate.

### Historical route 1 results

The original candidate used 44 m sections and 2.5–3.5 m gaps. These preserved results are in `artifacts/qa/next-version/jungle-2026-09-26/`:

- 105 core tests pass, including 8 Jungle cases. Thirty-six one-minute seeded rides and six simple acceleration/coast rides have no crashes. Canyon/Japan/Flat profile samples are unchanged bit for bit over 724,914 positions.
- Four UI scenarios pass on iPhone portrait and four on iPad landscape. Actual first-gap, reveal and catalog screenshots were inspected.
- Debug and Release progression/competition checks, signed Debug device build and Release compile passed for that candidate. Its remote board remained source-only. Physical installation was initially deferred because the phone was unavailable (CoreDevice error 1011); the later combined Milo/Jungle installation and playtest are recorded in [Milo](MILO.md). This is not an installation record for route 2 or route 3.
