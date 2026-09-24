# Game Center achievements

The implementation and local configuration proposal are ready for review. **No achievement has been created, changed, reset, uploaded or submitted in App Store Connect by this work.** Local candidate/archive preparation is authorized; remote configuration, upload, review submission and publication remain separate operations. Local achievements work without Game Center.

## Configuration proposal

The production `AchievementCatalog.standard` defines 40 achievements worth 1,000 points. [The JSON manifest](achievements-game-center.json) and [CSV manifest](achievements-game-center.csv) contain the exact identifiers, titles, descriptions, points, English localization, and proposed image filenames. Every achievement is non-hidden and non-repeatable. The earned descriptions are proposed past-tense versions of the catalog copy and should be reviewed before remote configuration.

Identifiers use the permanent prefix `com.daviddemri.crococross.achievement.` with these suffixes:

| Suffix | Points |
| --- | ---: |
| `stunt.backflip.first` | 10 |
| `stunt.frontflip.first` | 10 |
| `stunt.double.landed` | 20 |
| `stunt.triple.landed` | 40 |
| `stunt.total.10` | 15 |
| `stunt.total.50` | 30 |
| `stunt.total.100` | 60 |
| `stunt.total.250` | 20 |
| `stunt.total.500` | 25 |
| `stunt.total.1000` | 30 |
| `stunt.total.2500` | 40 |
| `stunt.total.5000` | 50 |
| `stunt.total.10000` | 70 |
| `endless.distance.1000` | 10 |
| `endless.distance.2000` | 10 |
| `endless.distance.3000` | 10 |
| `endless.distance.4000` | 10 |
| `endless.distance.5000` | 10 |
| `endless.distance.6000` | 10 |
| `endless.distance.7000` | 10 |
| `endless.distance.8000` | 10 |
| `endless.distance.9000` | 10 |
| `endless.distance.10000` | 10 |
| `endless.distance.11000` | 10 |
| `endless.distance.12000` | 10 |
| `endless.distance.13000` | 10 |
| `endless.distance.14000` | 10 |
| `endless.distance.15000` | 10 |
| `endless.distance.20000` | 20 |
| `endless.distance.25000` | 25 |
| `endless.distance.30000` | 30 |
| `endless.distance.35000` | 35 |
| `endless.distance.40000` | 40 |
| `endless.distance.45000` | 45 |
| `endless.distance.50000` | 50 |
| `weekly.finish.1` | 20 |
| `weekly.finish.5` | 40 |
| `weekly.finish.10` | 75 |
| `unlock.rider.shiba` | 25 |
| `unlock.world.japan` | 25 |

The 22 distance achievements cover every kilometre from 1 to 15 km, then 20/25/30/35/40/45/50 km, each in one Endless run.

Double and triple achievements are binary successes: `0/1` until two or three rotations are safely landed in the same jump, then `1/1`. They combine front/back rotations; the 10/50/100/250/500/1,000/2,500/5,000/10,000 totals also combine both directions. A single rotation gives no partial double/triple progress. The unconfigured older `.double.first` and `.triple.first` proposal IDs are replaced by `.double.landed` and `.triple.landed`; their old partial or complete progress is not migrated.

They intentionally do not inherit leaderboard or physics revisions. Apple makes achievement identifiers permanent and limits each to 100 bytes for single-byte text, with at most 100 points per achievement and 1,000 points total. The exporter checks these bounds and uniqueness. Apple allows up to 100 achievements per app. [Achievement properties](https://developer.apple.com/help/app-store-connect/reference/game-center/achievements), [Manage achievements](https://developer.apple.com/help/app-store-connect/configure-game-center/manage-achievements).

Regenerate the review files from the real catalog:

```sh
swiftc Sources/CrocoCrossCore/AchievementCatalog.swift scripts/export-game-center-achievements.swift -o /tmp/export-crococross-achievements
/tmp/export-crococross-achievements docs
```

## Artwork and future release preparation

All **40 distinct achievement badges are generated and visually reviewed locally** in [distribution/game-center/achievements](../distribution/game-center/achievements), with an image manifest and contact sheet. The images are opaque 1024 × 1024 sRGB PNGs at 72 ppi. They have not been uploaded to Game Center; remote localizations, configuration and version association remain pending. SF Symbols in the local panel are separate from these upload assets. For App Store Connect, supply 1024 × 1024 RGB PNG/JPEG/JPG images at a minimum of 72 ppi, plus at least one localization containing display name, pre-earned description and earned description. [Required metadata and image format](https://developer.apple.com/help/app-store-connect/reference/game-center/achievements).

Keep important content centered for Game Center's circular mask and use distinct artwork for each achievement. Apple recommends opaque artwork without embedded text. [Game Center design guidance](https://developer.apple.com/design/human-interface-guidelines/game-center), [Apple's Game Center design session](https://developer.apple.com/videos/play/wwdc2020/10145/).

After explicit release/configuration authorization, configure the reviewed IDs, points, localization and artwork in App Store Connect, associate them with the app version, and perform approved sandbox testing. Only then enable the Boolean `CrocoGameCenterAchievementsEnabled` in the app's Info.plist. The key is currently absent, which means disabled because the remote achievement IDs are not configured. Debug and Release use the same activation policy and the same local achievement ledger. The standard `-ui-testing` launch flag keeps automated UI tests offline regardless of that setting. No remote reset API is used.

## Session API

`GameCenterService` reuses the existing GameKit authentication, reachability and foreground refresh. `GameSession` supplies the account ledger, not its device-global panel totals:

```swift
gameCenter.achievementProgressProvider = { [weak self] playerID in
    self?.achievements.gameCenterProgress(for: playerID) ?? [:]
}
gameCenter.achievementRemoteProgressHandler = { [weak self] playerID, progress, dates in
    self?.achievements.mergeRemoteProgress(progress, playerID: playerID, completionDates: dates)
}
gameCenter.syncAchievements(localProgress: snapshot, playerID: owner)
await gameCenter.refreshAchievements()
gameCenter.showAchievements()
```

`owner` must be captured at the run/claim. Guest adoption is the progression ledger's one-time persisted decision; the provider is called on authenticated account changes even before remote achievements are configured, so first-account attribution does not depend on network activation. The synchronization layer never transfers device-global progress or account A's queue to B. Remote percentages restore the local panel without reconstructing stunt histories or replaying completion notices. Dates passed from GameKit are `lastReportedDate` values for completed achievements, not invented dates inferred from counters.

## Offline behavior and network adapter

`GameCenterAchievementSync` stores desired and acknowledged percentages separately for each `gamePlayerID` in `game-center-achievements-v1.json`, using `LocalStore`'s versioned atomic envelope. Whole percentages are clamped to 0–100, restricted to configured IDs, and only increase. A report acknowledges the immutable batch actually sent, so newer local progress remains pending. No unchanged confirmed progress is reported; refreshes still read remote state for reconciliation and restoration.

Each synchronization first loads remote achievements, takes the maximum of confirmed values, then reports only outstanding progress. This reconciles requests that reached Apple before their completion returned an error. Failed loads or reports retain the pending values. Failures retry with a 2/4/8/16/32/60-second backoff while active; foreground and restored network connectivity also retry. A failed file write retains data in memory and retries on an unchanged snapshot. Unreadable or newer outboxes remain untouched; the independently persisted progression ledger can replay current values.

A session generation and player identity are checked before and after every awaited gateway operation. Late responses from a prior account cannot update the current account or invoke its restore callback. Signing out and back into the same account invalidates the old in-flight request too. Score acknowledgements and error messages also verify their captured owner after their await.

The live adapter uses `GKAchievement.loadAchievements()` and `GKAchievement.report(_:)`. Reports explicitly set `showsCompletionBanner = false` because the local persisted completion notice already handles feedback; Apple's default is true. [GKAchievement](https://developer.apple.com/documentation/gamekit/gkachievement), [Reporting achievement progress](https://developer.apple.com/documentation/gamekit/rewarding-players-with-achievements), [Completion banners](https://developer.apple.com/documentation/gamekit/gkachievement/showscompletionbanner).

Rankings keep explicit routes independent of the selected terrain: `showWeeklyLeaderboard(time: false)` opens Weekly score, `showWeeklyLeaderboard(time: true)` opens Weekly time, and `showLeaderboards(course:)` receives the chosen Canyon/Japan course for Endless. The UI can query `isWeeklyLeaderboardConfirmed(time:)` and `isEndlessLeaderboardConfirmed(for:)` separately.

`showAchievements()` authenticates if necessary and opens the native achievements dashboard via `GKAccessPoint.shared.trigger(state: .achievements)`. It does not add a floating access point over the gameplay controls or change the existing Rankings presentation. [GKAccessPoint](https://developer.apple.com/documentation/gamekit/gkaccesspoint).

## Verification

`scripts/check-game-center-achievements.swift` uses a fake gateway only. It covers durable offline queues, monotone and bounded updates, failed load/report, an accepted report whose response failed, relaunch, concurrent higher progress, A→B switches during load/report, A→signed-out→A, restored remote dates, malformed/newer files, failed-save recovery, and the shared activation policy and UI-test isolation. The 29 checks pass both with and without `-D DEBUG`, with identical expected behavior. The live adapter also passes a Swift 6 strict-concurrency type-check against the iOS SDK. These checks do not validate a configured App Store Connect achievement or perform any remote write.

```sh
swiftc -swift-version 6 -strict-concurrency=complete App/Services/LocalStore.swift App/Services/GameCenterAchievementSync.swift scripts/check-game-center-achievements.swift -o /tmp/check-game-center-achievements
/tmp/check-game-center-achievements
```
