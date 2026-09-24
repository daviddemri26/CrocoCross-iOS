# CrocoCross — App Store candidate 1.1.0 (18)

This folder contains the prepared **1.1.0 (18)** candidate. Signed-in checks on **September 23, 2026** confirmed **1.0.0 (17), Ready for Distribution**, and the owner-created **1.1.0 draft**, **À finaliser avant soumission**. Current description, promotional text, keywords, What's New and review notes were saved in that draft. It retains **Automatic** release; a recommendation for manual release has not changed that setting. TestFlight contains only 1.0.0 (17), uploaded September 16. Build 18 upload is confirmed and Apple processing has started; no App Review submission or public release is established. The app and Store language are English.

The final local **1.1.0 (18) archive and Apple Distribution IPA export passed** signature, bundle-identifier, entitlement and package checks on September 24. The 199 recorded source fingerprints were unchanged; **629 package checks** passed. Evidence: `artifacts/qa/release-1.1.0/final-ipa-metadata.json`. The earlier signing failure is resolved. Xcode confirmed the **1.1.0 (18) upload at 2026-09-24 07:24:44 UTC** (`Uploaded CrocoCross`, `EXPORT SUCCEEDED`, exit 0). **Apple processing has started**; readiness for build selection is not yet confirmed. This separate upload export used the same verified source archive; its uploaded bytes are not asserted to match the local IPA SHA-256.

## Delivery status

| Material | Status |
|---|---|
| `metadata/en-US/` | Current candidate text; description, promo, keywords and What's New saved in the Store draft |
| `metadata/app-information.json` | Candidate identity and separately scoped live/local status |
| `review/app-review-notes.txt` | Review-ready gameplay instructions saved in the Store draft |
| `screenshots/upload/en-US/iphone-6.9/` | Five refreshed 1320 × 2868 images, processed and visually reviewed in the Store draft |
| `screenshots/upload/en-US/ipad-13/` | Five refreshed 2752 × 2064 images, processed and visually reviewed in the Store draft |
| `screenshots/raw/` | Current Release simulator capture evidence |
| `game-center/achievements/` | 40 opaque 1024 × 1024 badges, manifest and reviewed contact sheet; seven achievements saved remotely, remainder deferred |
| `icons/` | Opaque icon set, including the 1024 × 1024 marketing image |
| `config/` | Candidate export/bundle snapshots; verify again after successful distribution export |
| `web/` | Public-page sources; publication and live content are a separate check |
| `review/store-status.json`, `review/game-center.json`, `review/declarations.md` | September 17 historical 1.0.0 evidence |
| `validation.json`, `VALIDATION.md` | Final local candidate package: 629 checks passed |
| `release-readiness.json` | Current gates; local candidate/screenshots/upload verified, Apple processing pending, remote achievements deferred |

All **10 replacement screenshots** are now uploaded to the 1.1.0 draft and verified after processing: five iPhone 6.9-inch and five iPad 13-inch images, ordered Weekly, Endless, Home, Controls, Audio. The processed thumbnails and current visuals were checked on September 24. Earlier candidate evidence under `artifacts/qa/release-1.1.0/` includes 97 passing core tests, passing Release Store-capture tests on iPhone 17 Pro Max and iPad Pro 13-inch (M5), the successful archive and initial failed export log; signing was subsequently resolved. Final local archive/export evidence is recorded separately in `final-ipa-metadata.json` (629 package checks).

The candidate adds Kenji and Japan Mountains as earned unlocks, a 2,600 m shared Weekly route, 40 local achievements, per-week/per-world records, revised controls and more flexible falls. Other planned riders/worlds remain unavailable. There are no ads or purchases.

## Identity

CrocoCross · app **6812979862** · bundle `com.daviddemri.crococross` · SKU `CROCOCROSS-IOS-001` · team `57XAAX65VC`. Candidate **1.1.0 (18)**, iPhone+iPad, minimum iOS/iPadOS 18. Seller: David Demri; copyright: 2026 Lafayette Consulting. Free; Games/Racing/Sports. Confirm agreements, age rating, territories and declarations before submission.

Existing URLs: [Support](https://daviddemri26.github.io/CrocoCross-iOS/support.html), [Privacy](https://daviddemri26.github.io/CrocoCross-iOS/privacy.html), [Marketing](https://daviddemri26.github.io/CrocoCross-iOS/). Their publication/current contents are not reverified by this package update. Private review contact stays outside public Git.

## Remaining Game Center work

Four v3 boards are **created and localized**: Weekly points, Weekly centiseconds, Canyon Endless points and Japan Endless points (`endless.japan.route_1.score.v3`). All four are ready for review in one iOS draft created September 24 at 00:14 local time, containing exactly the four boards and no achievements. App 1.1.0 has not yet been added, and the final send button was not used. App association, review/activation and real score read-back remain separate checks. Both Weekly boards start **2026-09-28 00:00 UTC**, with seven-day duration and immediate restart. They are configured once; Game Center creates later occurrences automatically, with no advance weekly creation or app history UI.

**40 achievements / 1,000 points** remain available locally. The owner stopped remote achievement entry on September 24 after **seven complete records** were saved, with no partial entry outstanding. Preserve them and defer the remaining 33. `CrocoGameCenterAchievementsEnabled` stays absent/false; no remote achievement synchronization is promised for this candidate. The complete catalog, metadata and reviewed artwork remain available.
See [Game Center setup](../docs/GAME-CENTER-SETUP.md), [achievement metadata](../docs/ACHIEVEMENTS-GAME-CENTER.md) and [release gates](../docs/RELEASE.md).

## Authorized preparation

The owner authorized local candidate/archive/export preparation and committing/pushing reviewed source to GitHub main. Remote Game Center creation was subsequently authorized, then further achievement entry was stopped. Binary upload, App Review submission and public release remain separate actions. The existing Pages workflow publishes `distribution/web` changes on main; a website push is not a local-only edit.

`scripts/archive-app-store.sh` creates a local archive; export uses `destination=export`. A successful local archive/export is distinct from upload or Apple processing. Artifacts and signing material stay outside public Git. [Current handoff](HANDOFF.md).
