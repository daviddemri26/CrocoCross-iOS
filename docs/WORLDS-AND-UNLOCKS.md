# Worlds, courses and unlocks

## Accepted direction

David requested on September 20, 2026 that all existing riders and landscapes return to the selection lists with names, large padlocks and space for eventual unlock conditions. **Every locked entry displays its own artwork with the same light filter.** Rocco and Canyon remain available.

Each landscape has its own intended riding character and separate Endless records. Japan Mountains now implements the first distinct route: shorter, sharper rounded crests with long descending receptions. David confirmed on September 22 that **Weekly stays on Canyon, with the exact same course for every player throughout the week**; the shared course changes each Monday. Endless generates a new random course for each ride or restart, within the selected world. Both rules are explained on the home screen and in How to play.

This is local preparation for the held next release. Game Center code/configuration is staged locally; no App Store or remote Game Center metadata is changed here.

## Implemented catalog presentation

`CatalogAvailability` keeps access separate from preview rendering. Every locked entry shows its artwork with a light 1.5 pt blur, 70% saturation and 85% opacity. Kenji has a backflip requirement and Japan Mountains a frontflip requirement, each with a numeric counter and progress bar. Other locked entries show “Requirements coming soon.” under “TO UNLOCK”. Reaching a requirement enables an explicit claim and short reveal.

| Riders | Current state |
|---|---|
| Rocco | Playable |
| Kenji | 50 landed backflips, then tap to unlock; Debug uses 2 in separate local storage |
| Duke, Axel, Bjorn, Pinky, Rio, Bandit, Bubbles | Locked, lightly filtered artwork |

| Worlds | Current state |
|---|---|
| Canyon | Playable, current route ready |
| Japan Mountains | Route ready; 50 landed frontflips, then tap to unlock; Debug uses 2 in separate local storage |
| American Sunset, Tropical Jungle, Arctic Aurora, Old Gold Mine, San Francisco, Paris, Cloud Nine | Locked, lightly filtered artwork |

Locked cards below their threshold are disabled and action handlers also check access. A ready-to-unlock Kenji card becomes actionable for claiming, not directly playable. `GameSession` filters restored preferences and starts through the playable catalog, so an old saved world or rider cannot bypass a lock. A world must be both unlocked and route-ready. The original combined assets remain unchanged; Rocco and Kenji previews use their assembled articulated sprites. The shared filter is applied only in locked preview cards. Rocco and Canyon keep full-color artwork.

## Implemented course identity

Every `World` exposes a `WorldCoursePlan` with:

- A stable world ID and route revision, for example `japan.route-1`.
- The existing road-artwork ID, independent from the physical shape of the route.
- A readiness flag: Canyon and Japan are ready; other routes are planned.
- A score scope including the current rules version and world/route identity, with a registered Endless leaderboard for each ready route.

The run freezes this identity for terrain, scenery, local records and queued scores. Canyon preserves its existing keys and board. Japan uses a distinct local record and prepared Game Center board; it cannot enter Canyon rankings. The Japan board must be remotely created and confirmed before a run can start ranked. Until then, local riding remains available. An unavailable Japan board cannot disable the existing boards. See [Japan Mountains](JAPAN-MOUNTAINS.md) and [Game Center setup](GAME-CENTER-SETUP.md).

## Contract for current and future worlds

1. Define each world's course profile separately from its scenery: overall grade, uphill/downhill balance, hill height and length, ramp shapes, spacing, landing runs and transitions. Japan changes geometry only and keeps the accepted motorcycle physics.
2. Pass the selected, ready course profile into the deterministic core terrain generator. Keep continuous joins, wheel contact and natural player-controlled physics. Canyon's accepted handling is the baseline to preserve.
3. Freeze a course identity at run start: world ID, route revision, rules version, mode, seed and, for Weekly, the occurrence. Changing a selection must not relabel an existing result or pending submission.
4. Store Endless and local course records by world/route/rules, and show the active world on the ranking screen. Never compare incompatible routes in the same permanent leaderboard or import old Canyon totals into another world.
5. For Weekly, use one versioned schedule/configuration shared by all players. Each occurrence fixes the same world, 2,600 m route, seed and rules; a player's unlocked list or device locale must not choose that week's world. Rankings remain per occurrence, with points and time separate. Confirm event-access policy for progression-locked worlds before expanding the event pool; for now only Canyon is eligible.
6. Queued results preserve and validate the frozen course identity before submission. Japan has a separate v3 Endless board; each later world/revision must register its own compatible scope. The current v3 Weekly boards remain the Canyon baseline.
7. Define unlock rules one item at a time, persist earned progress separately from preview visibility, and validate the rider rig or course before enabling gameplay. Kenji is the first implementation: each safely landed backflip counts immediately across all modes, independent of final score validity; frontflips and failed figures do not count. Reaching 50 (Debug: 2) enables an explicit claim with a short reveal. Progress and claims are durable local data, separate from leaderboard rules and Debug/production saves.

Japan follows the same claim workflow as Kenji using safely landed **frontflips**, with Debug 2 / Release 50 and an independent save. Its counter survives abandoning or losing a run and remains bounded at the target.

Before releasing another world, finish its route and artwork checks, isolate its score storage, verify the shared Weekly schedule where applicable, and test physical-device play. This expansion stays subject to David's next-release launch signal.
