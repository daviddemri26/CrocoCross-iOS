# CrocoCross — native Game Center setup

## Current remote preparation — September 24, 2026

Four v3 boards are created, localized and associated with **app 1.1.0 (18) in one iOS review draft**, verified September 24 at 00:32 local time. Its five items are the app plus Weekly Score v3, Weekly Time v3, Endless Canyon v3 and Endless Japan v3; there are no achievements. The dialog confirms review with version 1.1.0 on iOS. The final send button was not clicked.

The identifiers are `weekly.score.v3`, `weekly.time.v3`, `endless.score.v3` and **`endless.japan.route_1.score.v3`** under `com.daviddemri.crococross`. Japan's remote ID uses an underscore; the local route/storage namespace remains `box2d-2.japan.route-1`. Review/activation and genuine score read-back are separate from the confirmed draft association. Score round-trip testing has not been attempted. Apple distinguishes draft preparation from final submission: [Submit Game Center components](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-game-center-components).

The two recurring Weekly boards share **2026-09-28 00:00 UTC** as their first start, with seven-day duration and immediate seven-day restart. Configure them once; Game Center creates future occurrences automatically. The app presents the current week, with no advance week creation or history UI.

The owner stopped further achievement entry after seven complete records were saved. Preserve them with no edits or deletion; the other remote achievements are deferred. All **40 achievements work locally**, and `CrocoGameCenterAchievementsEnabled` remains absent/false. See [achievement status](ACHIEVEMENTS-GAME-CENTER.md) and [current release gates](RELEASE.md). The v2 setup below remains historical first-version documentation.
## Current Weekly personal records — September 23, 2026

The Rankings UI reads two independent entries for the authenticated player: Weekly points and Weekly time. `GameCenterService.weeklyScoreRecord` and `weeklyTimeRecord` are optional `WeeklyPlayerRecord(score: Int, rank: Int)` values. `weeklyRecordsLoading` covers pending reads; `weeklyRecordsChallengeIdentifier` identifies their confirmed occurrence. An absent entry or failed read remains `nil`, and one unavailable board does not discard a successful result from the other. A Game Center rank is displayed with that same remote entry's score, never attached to a newer unsent local best.

The time score is **centiseconds**: submission uses `Int((elapsedSeconds * 100).rounded())`. Read it as `Double(record.score) / 100` seconds, not milliseconds. Lower time scores are better. Points use integer scores, with higher scores better. The new entry request path is read-only. The existing refresh flow may separately retry previously queued gameplay submissions, as before.

After both recurring board schedules are confirmed as the same active Monday-UTC week, the service calls the existing `GKLeaderboard` instances with `loadEntries(for: .global, timeScope: .allTime, range: NSRange(location: 1, length: 1))`. The separately returned `localPlayerEntry` contains the local player's score and global rank even when they are outside that requested top row. For recurring boards the instance chooses the occurrence; Apple's `timeScope` filter applies only to classic boards. The implementation uses the current async GameKit API, available from iOS 14. [Load entries](https://developer.apple.com/documentation/gamekit/gkleaderboard/loadentries(for:timescope:range:completionhandler:)), [Leaderboard entry](https://developer.apple.com/documentation/gamekit/gkleaderboard/entry), [Recurring leaderboards](https://developer.apple.com/documentation/gamekit/creating-recurring-leaderboards).

Entry requests do not block course confirmation, submission retries or gameplay. They refresh after confirmed metadata, after a successful Weekly submission, and when the app refreshes on foreground/network restoration or after dismissing the Game Center dashboard. Rankings can call the existing `refresh()` when opened. Every read validates the player, exact board instances and active occurrence before and after its await. A request generation also rejects old callbacks after A → sign-out → A or another refresh. Account changes, invalid metadata and the occurrence deadline clear displayed values. These results are ephemeral and are not persisted as local run records. Standard automated UI tests disable online access.

`scripts/check-weekly-player-records.swift` exercises independent success/failure, missing entries, raw time units, account and occurrence changes, stale callbacks, exact boundary rejection, rank validation and expiry using fake loaders only. It does not contact Game Center or validate the pending v3 remote configuration.

## Staged world-specific Endless rankings — September 22, 2026

Weekly stays on Canyon route 1: every player receives the exact same 2,600 m course for a given confirmed server occurrence. The Weekly points and time boards remain shared; a selected Japan world does not change the Weekly course. Endless generates a new seed for each run and keeps records and rankings separate for each world and terrain revision.

| English display name | Next-version identifier | Type | Ordering |
|---|---|---|---|
| Weekly Score | `com.daviddemri.crococross.weekly.score.v3` | Recurring | High to low |
| Weekly Time | `com.daviddemri.crococross.weekly.time.v3` | Recurring | Low to high |
| Endless — Canyon | `com.daviddemri.crococross.endless.score.v3` | Classic | High to low |
| Endless — Japan Mountains | `com.daviddemri.crococross.endless.japan.route_1.score.v3` | Classic | High to low |

Both Endless boards use integer points and Best Score. Keep Canyon's existing v3 identifier and `bestEndless.box2d-2` local key. Japan uses `bestEndless.box2d-2.japan.route-1`; future terrain revisions require a separately registered board and local key. Do not combine Japan scores into the Canyon leaderboard.

New pending submissions freeze the rules version, world, terrain revision, board, original player and any Weekly occurrence. Existing current-version entries without a course field are recognized only as Canyon. A route/board mismatch cannot upload; a queue containing incompatible entries is preserved on disk instead of being silently replaced. Japan's optional board is loaded independently, so its absence does not disable confirmed Canyon or Weekly competition. Until Japan's board is confirmed, Japan remains playable with local records.

After explicit release authorization, complete and record this setup:

1. Inspect App Store Connect and create or verify the four exact v3 identifiers above; retain the v2 historical boards. Configure matching future Monday UTC occurrences for the two Weekly boards.
2. Add the English world labels above, attach the new components to the intended release and verify their review/activation state. The four board definitions now exist; this checklist does not establish version association, review/activation or gameplay read-back.
3. With the Japan board absent in a test environment, confirm Canyon Endless and Weekly still become eligible, while Japan runs stay local.
4. Play real Endless runs in both worlds. Verify each result and best-score replacement on its own board; confirm a world switch does not replace the other world's local best. Do not fabricate production entries.
5. Queue a result while offline, change the home-screen world and reconnect with the original account. Confirm upload uses the frozen original world/route board. Repeat an account switch to confirm the pending score remains with its original owner.
6. Start Weekly while Japan is selected and compare two players' seeds and course samples for the same occurrence. Both must ride the shared Canyon course. Restart Endless repeatedly and confirm fresh seeds.

The checks below describing v2 and the original 4,000 m course document the first-version baseline. Use the v3 identifiers and 2,600 m distance above when validating the prepared next release.


## Live configuration status — September 17, 2026

All three v2 leaderboards below have been created in App Store Connect for app **6812979862**, with English (U.S.) localization only. Weekly Score and Weekly Time use Best Score and start together at **2026-09-21 00:00 UTC**, lasting and restarting every seven days. The current browser UI displays this as **September 20, 17:00 UTC-7**; always check the displayed time zone. Endless Score is a classic, descending Best Score board. Game Center is enabled for app version 1.0.0, build 17.

The review submission is being prepared for the owner; configuration does not prove live score upload/read-back. The real-run acceptance checks below remain necessary. Legacy v1 scores and queues were not retagged; new records use the `box2d-1` namespace. The following Xcode instructions are an optional future local test workflow, not a claim that a `.gamekit` bundle was generated.

## App identity

- App and target: `CrocoCross`
- Bundle ID: `com.daviddemri.crococross`
- Configured development team: `57XAAX65VC`; confirm the selected account owns this app.
- The target already declares the Game Center entitlement. Verify it under **Signing & Capabilities** and confirm that the App Store Connect app record uses this exact bundle ID.

Use Xcode's native GameKit editor and its connected developer account. This workflow does not require creating a separate App Store Connect API key. Apple demonstrates local configuration, account/app selection and synchronization in [Get started with Game Center](https://developer.apple.com/videos/play/wwdc2025/214/).

## Create a reviewable local bundle

1. Open the native CrocoCross project in Xcode.
2. Choose **File > New > File from Template**, search for **GameKit**, select **GameKit Bundle**, then **Next**.
3. Name the bundle `CrocoCross.gamekit`, save it in the native repository, select the CrocoCross target and create it. [Apple bundle creation](https://developer.apple.com/documentation/gamekit/initializing-and-configuring-game-center).
4. In the bundle editor, use **+ > Leaderboard**. Enter the reference name and identifier for each row below, then **Add**.
5. Select each leaderboard and set its score format, ordering and Best Score submission behavior. Add the English localization using **+** in the localization area. [Apple leaderboard editing walkthrough](https://developer.apple.com/videos/play/wwdc2025/214/).

Let Xcode generate the package contents; no public serialization schema was established during this preparation.

| Reference name and English display name | Identifier | Type | Score format | Ordering |
|---|---|---|---|---|
| Weekly Score | `com.daviddemri.crococross.weekly.score.v2` | Recurring | Integer | High to low |
| Weekly Time | `com.daviddemri.crococross.weekly.time.v2` | Recurring | Elapsed time in centiseconds | Low to high |
| Endless Score | `com.daviddemri.crococross.endless.score.v2` | Classic | Integer | High to low |

Use **Best Score** for all three. Do not use Most Recent Score. Keep optional score limits unset unless a validated range has been established for the final physics and scoring. Add at least an English localization before synchronization. The time board receives an integer count of hundredths of a second, not seconds or milliseconds. [Apple leaderboard properties](https://developer.apple.com/help/app-store-connect/reference/game-center/leaderboards).

## Weekly schedule

Enable **Recurring** for both weekly boards. Under the recurring settings, use the same first start instant and these values:

- Start: a Monday at `00:00:00 UTC` that is still in the future when the remote configuration is created.
- Duration: `7 days` = `604800 seconds`.
- Restart interval: `7 days` = `604800 seconds`.

The duration controls how long an occurrence accepts scores; the restart interval controls when the next one begins. Equal values make consecutive occurrences with no gap. [Apple recurring leaderboards](https://developer.apple.com/documentation/gamekit/creating-recurring-leaderboards).

For configuration after September 16, 2026, choose the next future Monday UTC. Recalculate at the time of synchronization. Check the UTC instant even if Xcode's date control displays a local time zone. Apple requires the first remote start to be in the future. [Apple's first-start-date explanation](https://developer.apple.com/videos/play/wwdc2021/10067/).

CrocoCross validates Monday midnight UTC, the seven-day duration, and `nextStartDate - startDate == 604800` for both returned leaderboards. Their occurrences must match and be active. The server occurrence start determines the stable `box2d-1` course seed. A mismatched, inactive or unavailable configuration leaves weekly play in practice mode. [`GKLeaderboard.nextStartDate`](https://developer.apple.com/documentation/gamekit/gkleaderboard/nextstartdate).

## Preserve Xcode's generated configuration

Review the new bundle and Xcode project/scheme diff before running `scripts/generate-project.py` again. That script currently regenerates both files. Its owner must preserve the actual references and settings emitted by Xcode, using the created bundle as evidence. Do not guess a package layout, a project file type or a scheme XML element. Include the bundle and the resulting generator change in version control after review.

## Test locally

Choose **Product > Scheme > Edit Scheme > Run > Options**, then enable **GameKit Configuration > Enable Debug Mode**. Run on a supported physical device and open **Debug > GameKit > Manage Game Progress**. Select that device and CrocoCross. This environment uses local test data; it does not prove that App Store Connect or production scores work. [Apple configuration and local testing](https://developer.apple.com/documentation/gamekit/initializing-and-configuring-game-center).

Play real runs and compare the app's score with the corresponding entry in Game Progress Manager. Test a completed weekly run for both points and time, plus an Endless score. Use the app's ordinary gameplay; do not fabricate production entries. A future first weekly occurrence is not immediately available for ranking, so schedule weekly acceptance testing after it opens. Endless and weekly practice remain playable while waiting.

Game Progress Manager can reset recurring leaderboards, but previous occurrences are unavailable in Debug Mode. A local reset alone cannot validate all server rollover behavior. [Apple recurring test limitations](https://developer.apple.com/documentation/gamekit/creating-recurring-leaderboards).

## Synchronize after the local configuration is reviewed

Select the bundle, choose **… > Push to App Store Connect**, select the intended team and CrocoCross app, review the destination, then push. This is a remote metadata change and a separate release step. Resources initially appear as **Not Live**; their creation is not public release. [Apple synchronization and lifecycle demonstration](https://developer.apple.com/videos/play/wwdc2025/214/).

If the app already has Game Center metadata, first inspect it using **… > Pull from App Store Connect** and review the local changes before editing or pushing. Never attach this app to the original site's identity or silently replace another app's configuration. [Apple account and configuration workflow](https://developer.apple.com/documentation/gamekit/initializing-and-configuring-game-center).

## Verify the server before release

Run with GameKit Debug Mode disabled and verify the configured server environment. Record the actual player, board identifier, start/end dates, returned score and visible entry for each check:

1. Sign in and load both active weekly boards; confirm identical Monday UTC occurrences and seven-day restart intervals.
2. Finish a real 4,000 m course. Read back that player's weekly score and centisecond time from the same occurrence. A submission callback alone is not a read-back.
3. Play Endless and confirm that a higher score replaces a lower one. Check that the time board retains a faster completed time.
4. Repeat with a second player. Confirm that equal point scores are not advertised as using a time tiebreak; points and time are separate boards.
5. Exercise connection loss and retry with the original player. Sign out or change accounts and confirm that a pending result is never attributed to the new player. Guest/practice results must not acquire an owner later.
6. Cross a weekly boundary and confirm that an expired result never reaches the new occurrence. The client submits weekly scores through the original loaded leaderboard instance.

These checks validate CrocoCross's implemented contract. Game Center provides ranking storage and player identity; this app does not have an independent server replaying runs to verify the physics. Do not describe scores as server-validated or cheat-proof.

Attach the three Game Center components to the first app version's review submission after beta validation. Apple documents that first component submissions accompany an app version. [Submit Game Center components](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-game-center-components). Archive creation, TestFlight upload, App Review and public release remain separate steps described in [RELEASE.md](RELEASE.md).
