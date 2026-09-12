# CrocoCross — native Game Center setup

Prepared September 12, 2026. This is a configuration procedure for the independent iOS app. The identifiers below are implemented locally; they are not evidence that App Store Connect resources exist. No GameKit bundle is fabricated by this document and no synchronization has been performed as part of its preparation.

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
| Weekly High Score | `com.daviddemri.crococross.weekly.score.v1` | Recurring | Integer | High to low |
| Weekly Fastest Finish | `com.daviddemri.crococross.weekly.time.v1` | Recurring | Elapsed time in centiseconds | Low to high |
| Endless High Score | `com.daviddemri.crococross.endless.score.v1` | Classic | Integer | High to low |

Use **Best Score** for all three. Do not use Most Recent Score. Keep optional score limits unset unless a validated range has been established for the final physics and scoring. Add at least an English localization before synchronization. The time board receives an integer count of hundredths of a second, not seconds or milliseconds. [Apple leaderboard properties](https://developer.apple.com/help/app-store-connect/reference/game-center/leaderboards).

## Weekly schedule

Enable **Recurring** for both weekly boards. Under the recurring settings, use the same first start instant and these values:

- Start: a Monday at `00:00:00 UTC` that is still in the future when the remote configuration is created.
- Duration: `7 days` = `604800 seconds`.
- Restart interval: `7 days` = `604800 seconds`.

The duration controls how long an occurrence accepts scores; the restart interval controls when the next one begins. Equal values make consecutive occurrences with no gap. [Apple recurring leaderboards](https://developer.apple.com/documentation/gamekit/creating-recurring-leaderboards).

For configuration on September 12, 2026, use `2026-09-14T00:00:00Z`. Recalculate if preparation happens later. Check the UTC instant even if Xcode's date control displays a local time zone. Apple requires the first remote start to be in the future. [Apple's first-start-date explanation](https://developer.apple.com/videos/play/wwdc2021/10067/).

CrocoCross validates Monday midnight UTC, the seven-day duration, and `nextStartDate - startDate == 604800` for both returned leaderboards. Their occurrences must match and be active. The server occurrence start determines the stable `native-1` course seed. A mismatched, inactive or unavailable configuration leaves weekly play in practice mode. [`GKLeaderboard.nextStartDate`](https://developer.apple.com/documentation/gamekit/gkleaderboard/nextstartdate).

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
