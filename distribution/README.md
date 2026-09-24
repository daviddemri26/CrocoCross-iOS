# CrocoCross — App Store candidate 1.1.0 (18)

This folder contains the prepared **1.1.0 (18)** candidate. Signed-in checks on **September 23, 2026** confirmed **1.0.0 (17), Ready for Distribution**, and the owner-created **1.1.0 draft**, **À finaliser avant soumission**. Current description, promotional text, keywords, What's New and review notes were saved in that draft. It retains **Automatic** release; a recommendation for manual release has not changed that setting. TestFlight contains only 1.0.0 (17), uploaded September 16. Build 18 has not been uploaded, submitted or released. The app and Store language are English.

The local signed Release **1.1.0 (18) archive succeeded and its code signature was verified**. Local IPA export failed with `No Accounts` and `No signing certificate "iOS Distribution" found`; reconnecting the Xcode account and making distribution signing available remain required.

## Delivery status

| Material | Status |
|---|---|
| `metadata/en-US/` | Current candidate text; description, promo, keywords and What's New saved in the Store draft |
| `metadata/app-information.json` | Candidate identity and separately scoped live/local status |
| `review/app-review-notes.txt` | Review-ready gameplay instructions saved in the Store draft |
| `screenshots/upload/en-US/iphone-6.9/` | Five refreshed 1320 × 2868 images, visually reviewed locally |
| `screenshots/upload/en-US/ipad-13/` | Five refreshed 2752 × 2064 images, visually reviewed locally |
| `screenshots/raw/` | Current Release simulator capture evidence |
| `game-center/achievements/` | 40 opaque 1024 × 1024 badges, manifest and reviewed contact sheet; no remote upload |
| `icons/` | Opaque icon set, including the 1024 × 1024 marketing image |
| `config/` | Candidate export/bundle snapshots; verify again after successful distribution export |
| `web/` | Public-page sources; publication and live content are a separate check |
| `review/store-status.json`, `review/game-center.json`, `review/declarations.md` | September 17 historical 1.0.0 evidence |
| `validation.json`, `VALIDATION.md` | Refreshed candidate package: 584 checks passed |
| `release-readiness.json` | Current gates; online configuration and distribution export remain incomplete |

**The Store draft still contains inherited 1.0.0 screenshots.** Reviewed local images have not been uploaded. Candidate evidence under `artifacts/qa/release-1.1.0/` includes 97 passing core tests, passing Release Store-capture tests on iPhone 17 Pro Max and iPad Pro 13-inch (M5), the successful archive, and the failed export log.

The candidate adds Kenji and Japan Mountains as earned unlocks, a 2,600 m shared Weekly route, 40 local achievements, per-week/per-world records, revised controls and more flexible falls. Other planned riders/worlds remain unavailable. There are no ads or purchases.

## Identity

CrocoCross · app **6812979862** · bundle `com.daviddemri.crococross` · SKU `CROCOCROSS-IOS-001` · team `57XAAX65VC`. Candidate **1.1.0 (18)**, iPhone+iPad, minimum iOS/iPadOS 18. Seller: David Demri; copyright: 2026 Lafayette Consulting. Free; Games/Racing/Sports. Confirm agreements, age rating, territories and declarations before submission.

Existing URLs: [Support](https://daviddemri26.github.io/CrocoCross-iOS/support.html), [Privacy](https://daviddemri26.github.io/CrocoCross-iOS/privacy.html), [Marketing](https://daviddemri26.github.io/CrocoCross-iOS/). Their publication/current contents are not reverified by this package update. Private review contact stays outside public Git.

## Remaining Game Center work

Four v3 boards are prepared in code: Weekly points, Weekly centiseconds, Canyon Endless points and Japan Endless points. No new board has been created remotely. Configure the two Weekly recurring boards once with matching Monday 00:00 UTC starts, seven-day duration and immediate seven-day restart. Game Center creates later occurrences automatically; there is no advance weekly creation or app history UI.

**40 achievements / 1,000 points** have a catalog, JSON/CSV metadata and reviewed artwork. Remote localizations, upload, configuration, association and real score/achievement read-back remain pending. `CrocoGameCenterAchievementsEnabled` stays absent/false until configured and validated. Local play and achievements remain available.

See [Game Center setup](../docs/GAME-CENTER-SETUP.md), [achievement metadata](../docs/ACHIEVEMENTS-GAME-CENTER.md) and [release gates](../docs/RELEASE.md).

## Authorized preparation

The owner authorized local candidate/archive/export preparation and committing/pushing reviewed source to GitHub main. Binary upload, App Review submission, public release and remote Game Center configuration remain separate actions. The existing Pages workflow publishes `distribution/web` changes on main; a website push is not a local-only edit.

`scripts/archive-app-store.sh` creates a local archive; export uses `destination=export`. A successful local archive/export is distinct from upload or Apple processing. Artifacts and signing material stay outside public Git. [Current handoff](HANDOFF.md).
