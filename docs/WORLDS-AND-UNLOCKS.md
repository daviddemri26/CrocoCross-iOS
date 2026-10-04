# Worlds, courses and unlocks

## Accepted direction

David requested on September 20, 2026 that all existing riders and landscapes return to the selection lists with names, large padlocks and space for eventual unlock conditions. **Every locked entry displays its own artwork with the same light filter.** Rocco and Canyon remain available.

Each landscape has its own intended riding character and separate Endless records. Japan Mountains now implements the first distinct route: shorter, sharper rounded crests with long descending receptions. David confirmed on September 22 that **Weekly stays on Canyon, with the exact same course for every player throughout the week**; the shared course changes each Monday. Endless generates a new random course for each ride or restart, within the selected world. Both rules are explained on the home screen and in How to play.

This is local preparation for the held next release. Game Center code/configuration is staged locally; no App Store or remote Game Center metadata is changed here.

## Implemented catalog presentation

`CatalogAvailability` keeps access separate from preview rendering. Every locked entry shows its artwork with a light 1.5 pt blur, 70% saturation and 85% opacity. Kenji and Milo have backflip requirements; Japan Mountains and Tropical Jungle have frontflip requirements, each with a numeric counter and progress bar. Other locked entries show “Requirements coming soon.” under “TO UNLOCK”. Reaching a requirement enables an explicit claim and short reveal.

| Riders | Current state |
|---|---|
| Rocco | Playable |
| Kenji | 50 landed backflips, then tap to unlock; Debug uses 2 in separate local storage |
| Milo | Third rider; 100 landed backflips, then tap to unlock; Debug uses 2 in separate local storage |
| Duke, Axel, Bjorn, Pinky, Rio, Bandit, Bubbles | Locked, lightly filtered artwork |

| Worlds | Current state |
|---|---|
| Canyon | Playable, current route ready |
| Japan Mountains | Route ready; 50 landed frontflips, then tap to unlock; Debug uses 2 in separate local storage |
| Tropical Jungle | Third in the world list; route 6 mixed horizontal departures and ramps; final checks in progress; 100 cumulative landed frontflips, then tap to unlock; Debug uses 2 |
| American Sunset, Arctic Aurora, Old Gold Mine, San Francisco, Paris, Cloud Nine | Locked, lightly filtered artwork |

Locked cards below their threshold are disabled and action handlers also check access. A ready-to-unlock Kenji card becomes actionable for claiming, not directly playable. `GameSession` filters restored preferences and starts through the playable catalog, so an old saved world or rider cannot bypass a lock. A world must be both unlocked and route-ready. The original combined assets remain unchanged; Rocco, Kenji and Milo previews use their assembled articulated sprites. The shared filter is applied only in locked preview cards. Rocco and Canyon keep full-color artwork.

## Implemented course identity

Every `World` exposes a `WorldCoursePlan` with:

- A stable world ID and route revision, for example `japan.route-1`.
- The existing road-artwork ID, independent from the physical shape of the route.
- A readiness flag: Canyon, Japan and Jungle are ready; other routes are planned.
- A score scope including the current rules version and world/route identity, with a registered Endless leaderboard for each ready route.

The run freezes this identity for terrain, scenery, local records and queued scores. Canyon preserves its existing keys and board. Japan uses a distinct local record and prepared Game Center board; it cannot enter Canyon rankings. The Japan board must be remotely created and confirmed before a run can start ranked. Until then, local riding remains available. An unavailable Japan board cannot disable the existing boards. See [Japan Mountains](JAPAN-MOUNTAINS.md) and [Game Center setup](GAME-CENTER-SETUP.md).

Jungle's current candidate uses `jungle.route-6`, local key `bestEndless.box2d-2.jungle.route-6` and prepared board `com.daviddemri.crococross.endless.jungle.route_6.score.v3`. Original route 1/2/3/4/5 records remain in their own scopes and are not imported into route 6; queued results cannot change their frozen route identity. Canyon, Japan and Weekly keep their existing terrain and competition scopes. This is local routing preparation, with no remote board creation or activation in the tuning batch.

## Contract for current and future worlds

1. Define each world's course profile separately from its scenery: overall grade, uphill/downhill balance, hill height and length, ramp shapes, spacing, landing runs and transitions. Japan changes geometry only and keeps the accepted motorcycle physics.
2. Pass the selected, ready course profile into the deterministic core terrain generator. Keep continuous joins, wheel contact and natural player-controlled physics. Canyon's accepted handling is the baseline to preserve.
3. Freeze a course identity at run start: world ID, route revision, rules version, mode, seed and, for Weekly, the occurrence. Changing a selection must not relabel an existing result or pending submission.
4. Store Endless and local course records by world/route/rules, and show the active world on the ranking screen. Never compare incompatible routes in the same permanent leaderboard or import old Canyon totals into another world.
5. For Weekly, use one versioned schedule/configuration shared by all players. Each occurrence fixes the same world, 2,600 m route, seed and rules; a player's unlocked list or device locale must not choose that week's world. Rankings remain per occurrence, with points and time separate. Confirm event-access policy for progression-locked worlds before expanding the event pool; for now only Canyon is eligible.
6. Queued results preserve and validate the frozen course identity before submission. Japan has a separate v3 Endless board; each later world/revision must register its own compatible scope. The current v3 Weekly boards remain the Canyon baseline.
7. Define unlock rules one item at a time, persist earned progress separately from preview visibility, and validate the rider rig or course before enabling gameplay. Kenji is the first implementation: each safely landed backflip counts immediately across all modes, independent of final score validity; frontflips and failed figures do not count. Reaching 50 (Debug: 2) enables an explicit claim with a short reveal. Progress and claims are durable local data, separate from leaderboard rules and Debug/production saves.

Japan follows the same claim workflow as Kenji using safely landed **frontflips**, with Debug 2 / Release 50 and an independent save. The shared frontflip counter survives abandoning or losing a run and now continues to the Jungle target: Release 100 / Debug 2. Jungle has its own explicit durable claim and reveal. Existing Japan saves migrate with their known count and claim intact; previously unrecorded flips above the old cap cannot be reconstructed.

The previous Tropical Jungle route 4 retains the approved 30/34 m crossings and adds different ramp shapes, receiving slopes, gap positions and a rolling 14 m interlude. It retains the introductory 18 m gap, elevated receptions, real cliff faces, 60 m recovery approach and natural physics. A larger background now scrolls continuously independently of motorcycle zoom; waterfall/pool vignettes are 2.75 times larger and now pass in front of the rider with clear ledge margins. A follow-up replaces abrupt Jungle zoom changes with early anticipation, bounded zoom velocity/acceleration and a slower return after settled reception. The preceding route4 candidate passed 112 core tests, three iPhone and two iPad UI scenarios, and Debug/Release builds; the signed Debug app was installed and launched on David's iPhone at 19:52/19:53 on September 26. Evidence is under `artifacts/qa/next-version/jungle-variety-2026-09-26/`. See [Tropical Jungle](TROPICAL-JUNGLE.md) for geometry, scenery and separately labelled earlier validation. Tree-to-tree platform art remains deferred. The subsequent camera/foreground pass passed 84 camera replays, two iPhone and two iPad UI scenarios, and final Debug/Release builds. That final Debug app was installed and launched at 20:18/20:19 PDT the same day, with evidence under `artifacts/qa/next-version/jungle-camera-2026-09-26/`; the core sources and route identity remain unchanged.

Route 5 then adds a close rider-following camera that permits offscreen receiving banks and an occasional 38/40 m crossing, one per six sections. Current evidence is under `artifacts/qa/next-version/jungle-close-2026-09-26/`; 113 core tests, three iPhone and two iPad UI scenarios, final builds and bundle checks pass. The signed Debug app (1.1.0, build 18) was installed on David's paired iPhone 17 at 20:49 and launched normally at 20:50 PDT on September 26, without UI fixture arguments.

Route 6 adds flat departures to lower platforms (16 m/−5.5 m and 24 m/−10.5 m), mixed among existing ramp launches, plus shared Pause sound control and varied waterfall placement. Current evidence is under `artifacts/qa/next-version/jungle-diversity-2026-09-27/`; 114 core tests, 84 recovery approaches, seven full control rides, 84 camera replays, eight scenery renders, four iPhone and three iPad UI scenarios, final builds and bundle checks pass. The iPhone Pause scenario passed after correcting a test-only world-selection tap. The signed Debug app (1.1.0, build 18) was installed and launched normally on David’s paired iPhone 17 at 15:51 PDT on September 27, without fixture arguments.

Milo's approved post-playtest visual adjustment is limited to 25% thicker calves via the rig profile. Source PNGs, limb lengths and contacts remain unchanged; Rocco and Kenji keep the default thickness. See [Milo](MILO.md). Earlier app test totals do not certify the new Jungle route 6 candidate.

Before releasing another world, finish its route and artwork checks, isolate its score storage, verify the shared Weekly schedule where applicable, and test physical-device play. This expansion stays subject to David's next-release launch signal.
