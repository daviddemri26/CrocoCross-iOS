# Release configuration and gates

## Current candidate: 1.1.0 (18)

Version **1.1.0**, build **18**, is the prepared update. Signed-in App Store Connect checks on **September 23, 2026** confirmed **1.0.0 (17), Ready for Distribution**, and the owner-created **1.1.0 draft**, shown as **À finaliser avant soumission**. The draft retains **Automatic** release; no release-setting change was made. Manual release remains the recommended choice for a controlled launch, not the observed setting. Description, promotional text, keywords, What's New and App Review notes were saved successfully in that draft.

TestFlight contains only **1.0.0 (17)**, uploaded September 16 and marked **Ready to Submit**; build 18 has not been uploaded. The local Release **1.1.0 (18) archive succeeded and its code signature was verified**. IPA export was attempted and **failed** with `No Accounts` and `No signing certificate "iOS Distribution" found`. Reconnect the Xcode account and make the distribution certificate available before retrying the authorized local export.
David has authorized preparing the candidate, a local signed archive/export, and committing/pushing the reviewed changes to GitHub main. This does **not** authorize automatic binary upload, submission to App Review, public release, or live Game Center configuration. Keep those operations separate. The dated entries in [NEXT-RELEASE.md](NEXT-RELEASE.md) retain the history of earlier preparation restrictions.

## Identity and local configuration

- CrocoCross · `com.daviddemri.crococross` · App Store Connect app `6812979862`.
- Team `57XAAX65VC`; iPhone and iPad, iOS/iPadOS 18 or later. Mac and Vision targets remain disabled.
- Free, no ads, no purchases, no separate CrocoCross account and no background-audio entitlement.
- Keep version/build settings in `scripts/generate-project.py`, the generated project and package metadata consistent. Automatic export build-number management is disabled.
- The app declares the Game Center entitlement, OS-only exempt encryption, no tracking, and the documented UserDefaults/SystemBootTime privacy reasons. Recheck the final signed bundle, not only these source files.
- The opaque 1024-pixel icon and bundled Box2D/license credits are present. Apple currently requires Xcode 26 or later and the iOS 26 SDK or later for uploads; recheck at upload time. [Apple SDK requirements](https://developer.apple.com/news/upcoming-requirements/).

## Game Center activation still pending

The update uses four fresh Best Score boards. Their identifiers are prepared locally; this repository does not establish that they exist or are live in App Store Connect.

| Identifier suffix under `com.daviddemri.crococross.` | Type | Value | Ordering |
|---|---|---|---|
| `weekly.score.v3` | Recurring | Points | High to low |
| `weekly.time.v3` | Recurring | Centiseconds | Low to high |
| `endless.score.v3` | Classic | Canyon points | High to low |
| `endless.japan.route-1.score.v3` | Classic | Japan points | High to low |

Configure the two Weekly recurring leaderboards once, with the same Monday 00:00 UTC first start, a seven-day duration and an immediate seven-day restart (604,800 seconds). Game Center creates subsequent occurrences automatically; do not create boards or individual weeks in advance. The app presents the current week only and has no history UI. Choose a future first start when configuration is authorized. A ranked Weekly start requires confirmed matching schedules; completing the 2,600 m course is required to submit points/time. Until confirmation, local play remains available. Keep old v2 components as historical records and review their visibility in the new version. See [Game Center setup](GAME-CENTER-SETUP.md).

The **40 achievements / 1,000 points** work locally. Remote synchronization is disabled because `CrocoGameCenterAchievementsEnabled` is absent/false. The catalog, JSON/CSV metadata proposals and **40 distinct, reviewed 1024 × 1024 achievement images** are prepared locally. Their Game Center localizations, upload, configuration and version association are still pending. Configure and validate them before enabling the flag in the candidate. Do not advertise remote achievement synchronization while it remains disabled. See [achievement configuration](ACHIEVEMENTS-GAME-CENTER.md).

Required online evidence remains outstanding: real eligible Weekly score/time and each world's Endless score submitted and read back for the original player, matching Weekly occurrence/global ranks, retry and account-switch behavior, and remote achievement restoration. Fake gateways and offline UI fixtures cannot establish this.

## Store material and validation

The English copy in `distribution/metadata/en-US/` covers Kenji, Japan Mountains, 2,600 m Weekly, 40 achievements, controls and rider falls; the description, promotional text, keywords, What's New and App Review notes are saved in the 1.1.0 draft. [STORE-LISTING.md](STORE-LISTING.md) records that boundary. Fresh iPhone and iPad screenshot sets are prepared locally and both contact sheets have been visually reviewed. **The remote draft still contains its inherited 1.0.0 screenshots**; the new images have not been uploaded.

Candidate evidence under `artifacts/qa/release-1.1.0/`: **97 core tests passed**, Release `AppStoreCaptureTests` passed on **iPhone 17 Pro Max and iPad Pro 13-inch (M5)**, and the local signed archive succeeded. The refreshed distribution validator passed **584 checks**. Automated captures and their visual review do not establish physical-device gameplay or live Game Center behavior. The export failure remains recorded separately in `export.log`.
Update the support/marketing/privacy content before publication, including unlock progression and optional achievement synchronization/first-account attribution. This task has not published those pages. Recheck privacy disclosures, calculated age rating, export compliance, rights and territory restrictions against the final version. Keep the owner-provided private review contact out of Git. Historical remote evidence remains in `distribution/review/store-status.json` and related September 17 records; it must not be presented as a fresh verification.

Final gates: reviewed source commit and passing CI/package checks; candidate-specific Release validation; physical iPhone/iPad gameplay, audio, interruptions and controls; archive/export signature and bundled settings; refreshed Store screenshots; signed-in App Store Connect state; configured online features or explicitly deferred remote functionality. Installation/launch alone does not prove human gameplay or live Game Center behavior.

## Automation boundary

The existing GitHub workflow runs tests and a simulator build. Signing/archive/upload automation can be prepared separately with protected credentials and a manual trigger; no App Store deployment workflow is claimed operational here. GitHub Pages publishes `distribution/web` changes pushed to main, so website changes require a deliberate publication decision. A local archive/export remains distinct from upload, TestFlight distribution, App Review and public release.
