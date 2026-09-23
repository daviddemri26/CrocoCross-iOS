# Worlds, courses and unlocks

## Accepted direction

David requested on September 20, 2026 that all existing riders and landscapes return to the selection lists with names, large padlocks and space for eventual unlock conditions. **Every locked entry displays its own artwork with the same light filter.** Rocco and Canyon remain available.

Each landscape will eventually have a distinct route, road style, uphill/downhill rhythm and score records. The exact profiles will be designed later. David chose **one world shared by all players each week** for Weekly, rather than simultaneous per-world weekly events.

This is local preparation for the held next release. No App Store or Game Center configuration is changed here.

## Implemented catalog presentation

`CatalogAvailability` keeps access separate from preview rendering. Every locked entry shows its artwork with a light 1.5 pt blur, 70% saturation and 85% opacity. It can carry its own unlock-requirement text; no requirement is defined yet, so cards show “Requirements coming soon.” under “TO UNLOCK”. Filling in the text does not itself unlock an entry.

| Riders | Current state |
|---|---|
| Rocco | Playable |
| Kenji, Duke, Axel, Bjorn, Pinky, Rio, Bandit, Bubbles | Locked, lightly filtered artwork |

| Worlds | Current state |
|---|---|
| Canyon | Playable, current route ready |
| Japan Mountains, American Sunset, Tropical Jungle, Arctic Aurora, Old Gold Mine, San Francisco, Paris, Cloud Nine | Locked, lightly filtered artwork |

Locked cards are disabled and action handlers also check access. `GameSession` filters restored preferences and starts through the playable catalog, so an old saved world or rider cannot bypass a lock. A world must be both unlocked and route-ready. Existing assets are unchanged; the shared filter is applied only in locked preview cards. Rocco and Canyon keep full-color artwork.

## Staged world metadata

Every `World` exposes a `WorldCoursePlan` with:

- A stable world ID and route revision, for example `japan.route-1`.
- The existing road-artwork ID, independent from the future shape of the route.
- A readiness flag: Canyon is ready; all other routes are planned.
- A future score scope that includes the current rules version and world/route identity.

These identifiers do not create new terrain, records or online boards yet. The live simulation and current records still use the existing Canyon behavior. The planned route descriptors prevent a future unlock from silently enabling a world with no implemented course.

## Future implementation contract

1. Define each world's course profile separately from its scenery: overall grade, uphill/downhill balance, hill height and length, ramp shapes, spacing, landing runs and transitions. Decide road material/traction separately where appropriate. No per-world numeric tuning is committed by this plan.
2. Pass the selected, ready course profile into the deterministic core terrain generator. Keep continuous joins, wheel contact and natural player-controlled physics. Canyon's accepted handling is the baseline to preserve.
3. Freeze a course identity at run start: world ID, route revision, rules version, mode, seed and, for Weekly, the occurrence. Changing a selection must not relabel an existing result or pending submission.
4. Store Endless and local course records by world/route/rules, and show the active world on the ranking screen. Never compare incompatible routes in the same permanent leaderboard or import old Canyon totals into another world.
5. For Weekly, use one versioned schedule/configuration shared by all players. Each occurrence fixes the same world, 2,600 m route, seed and rules; a player's unlocked list or device locale must not choose that week's world. Rankings remain per occurrence, with points and time separate. Confirm event-access policy for progression-locked worlds before expanding the event pool; for now only Canyon is eligible.
6. Extend queued results with the frozen course identity and validate it against the active weekly configuration before submission. Define/verify the final Game Center board layout at that stage; the current v3 reset remains the prepared Canyon baseline.
7. Define unlock rules one item at a time, persist earned progress separately from preview visibility, and validate the rider rig or course before enabling gameplay. No unlock thresholds or automatic progression are active yet.

Before enabling another world, finish its route and artwork checks, isolate its score storage, verify the shared Weekly schedule where applicable, and test physical-device play. This expansion stays subject to David's next-release launch signal.
