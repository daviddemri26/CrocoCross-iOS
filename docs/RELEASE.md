# Release configuration and gates

## Current candidate: 1.1.0 (18)

Version **1.1.0**, build **18**, is the prepared update. Signed-in App Store Connect checks on **September 23, 2026** confirmed **1.0.0 (17), Ready for Distribution**, and the owner-created **1.1.0 draft**, shown as **À finaliser avant soumission**. The draft retains **Automatic** release; no release-setting change was made. Manual release remains the recommended choice for a controlled launch, not the observed setting. Description, promotional text, keywords, What's New and App Review notes were saved successfully in that draft.

The latest TestFlight check on September 24 still showed only **1.0.0 (17)**. The final local **1.1.0 (18) archive and Apple Distribution IPA export passed** signature, bundle-identifier, entitlement and package checks on September 24. The 199 recorded source fingerprints were unchanged; **629 package checks** passed. Evidence: `artifacts/qa/release-1.1.0/final-ipa-metadata.json`. The earlier signing failure is resolved. Xcode confirmed the **1.1.0 (18) upload at 2026-09-24 07:24:44 UTC** (`Uploaded CrocoCross`, `EXPORT SUCCEEDED`, exit 0). **Apple processing has started**; readiness for build selection is not yet confirmed. This separate upload export used the same verified source archive; its uploaded bytes are not asserted to match the local IPA SHA-256.

David authorized local release preparation and reviewed GitHub delivery, then explicitly authorized creating the new Game Center components. On **September 24**, he stopped further remote achievement entry. Preserve the saved components; do not create, edit or delete more achievements. Screenshot replacement is complete. Binary upload is confirmed; Apple processing and adding app 1.1.0 to the existing leaderboard draft remain pending. No App Review submission or public release is established by this document.

## Identity and local configuration

- CrocoCross · `com.daviddemri.crococross` · App Store Connect app `6812979862`.
- Team `57XAAX65VC`; iPhone and iPad, iOS/iPadOS 18 or later. Mac and Vision targets remain disabled.
- Free, no ads, no purchases, no separate CrocoCross account and no background-audio entitlement.
- Keep version/build settings in `scripts/generate-project.py`, the generated project and package metadata consistent. Automatic export build-number management is disabled.
- The app declares the Game Center entitlement, OS-only exempt encryption, no tracking, and the documented UserDefaults/SystemBootTime privacy reasons. Recheck the final signed bundle, not only these source files.
- The opaque 1024-pixel icon and bundled Box2D/license credits are present. Apple currently requires Xcode 26 or later and the iOS 26 SDK or later for uploads; recheck at upload time. [Apple SDK requirements](https://developer.apple.com/news/upcoming-requirements/).

## Game Center: boards created, remote achievements deferred

The four fresh Best Score boards have been **created and localized in App Store Connect**. After the owner explicitly confirmed including all four boards, they were added to **one iOS draft submission**, created September 24 at 00:14 local time. The draft contains exactly the four v3 leaderboards and no achievements. All four are **Prêt pour la vérification**. App version **1.1.0 is not yet included**, and the final **Envoyer pour vérification** action was not used; app association, review/activation and genuine score read-back remain separate checks. Japan uses the accepted underscore identifier `endless.japan.route_1.score.v3`; its local route/storage identity remains unchanged.

| Identifier suffix under `com.daviddemri.crococross.` | Type | Value | Ordering |
|---|---|---|---|
| `weekly.score.v3` | Recurring | Points | High to low |
| `weekly.time.v3` | Recurring | Centiseconds | Low to high |
| `endless.score.v3` | Classic | Canyon points | High to low |
| `endless.japan.route_1.score.v3` | Classic | Japan points | High to low |

The two Weekly recurring boards share a configured first start of **2026-09-28 00:00 UTC**, a seven-day duration and an immediate seven-day restart (604,800 seconds). They are configured once: Game Center creates subsequent occurrences automatically. The app presents the current week only, with no advance week creation or history UI. A ranked Weekly start still requires confirmed matching active schedules, and completing 2,600 m is required to submit points/time. See [Game Center setup](GAME-CENTER-SETUP.md).

All **40 achievements / 1,000 points** work locally. Remote achievement synchronization stays **disabled** (`CrocoGameCenterAchievementsEnabled` absent/false) and is **deferred for this candidate**. Before the stop, **seven complete achievements** were saved remotely: the first backflip, first frontflip, double, triple, 10 total rotations, 1 km and first Weekly finish. There are no partially completed entries to finish. Preserve those seven without further edits or deletion; their existence does not enable synchronization or establish review/activation. The 40-entry catalog, JSON/CSV metadata and reviewed images remain available for future work. See [achievement configuration](ACHIEVEMENTS-GAME-CENTER.md).
Required online evidence remains outstanding: real eligible Weekly score/time and each world's Endless score submitted and read back for the original player, matching Weekly occurrence/global ranks, retry and account-switch behavior, and, only if remote achievements are resumed later, remote achievement restoration. Fake gateways and offline UI fixtures cannot establish this.

## Store material and validation

The English copy in `distribution/metadata/en-US/` covers Kenji, Japan Mountains, 2,600 m Weekly, 40 achievements, controls and rider falls; the description, promotional text, keywords, What's New and App Review notes are saved in the 1.1.0 draft. [STORE-LISTING.md](STORE-LISTING.md) records that boundary. All **10 replacement screenshots** are now uploaded to the 1.1.0 draft and verified after processing: five iPhone 6.9-inch and five iPad 13-inch images, ordered Weekly, Endless, Home, Controls, Audio. The processed thumbnails and current visuals were checked on September 24.

Earlier candidate evidence under `artifacts/qa/release-1.1.0/`: **97 core tests passed**, Release `AppStoreCaptureTests` passed on **iPhone 17 Pro Max and iPad Pro 13-inch (M5)**, and the local signed archive succeeded. That earlier distribution validator passed **584 checks**; the final local candidate now passes **629**. Automated captures and their visual review do not establish physical-device gameplay or live Game Center behavior. The initial export failure remains recorded in `export.log`; it predates the successful final local export recorded above. Live Game Center score round-trip testing has not been attempted, so its gate remains false.
Update the support/marketing/privacy content before publication, including unlock progression and optional achievement synchronization/first-account attribution. This task has not published those pages. Recheck privacy disclosures, calculated age rating, export compliance, rights and territory restrictions against the final version. Keep the owner-provided private review contact out of Git. Historical remote evidence remains in `distribution/review/store-status.json` and related September 17 records; it must not be presented as a fresh verification.

Final gates: reviewed source commit and passing CI/package checks; candidate-specific Release validation; physical iPhone/iPad gameplay, audio, interruptions and controls; archive/export signature and bundled settings; refreshed Store screenshots; signed-in App Store Connect state; configured online features or explicitly deferred remote functionality. Installation/launch alone does not prove human gameplay or live Game Center behavior.

## Automation boundary

The existing GitHub workflow runs tests and a simulator build. Signing/archive/upload automation can be prepared separately with protected credentials and a manual trigger; no App Store deployment workflow is claimed operational here. GitHub Pages publishes `distribution/web` changes pushed to main, so website changes require a deliberate publication decision. A local archive/export remains distinct from upload, TestFlight distribution, App Review and public release.
