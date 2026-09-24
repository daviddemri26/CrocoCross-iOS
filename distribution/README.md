# CrocoCross — App Store candidate 1.1.0 (18)

Verified on **September 24, 2026 at 00:32 America/Los_Angeles**: TestFlight **1.1.0 (18)** is processed (**Terminé**, **Prêt à soumettre**). Build 18 is selected and saved for version 1.1.0; the Save button is disabled. The existing **iOS review draft contains exactly five items: app 1.1.0 (18) and the four v3 leaderboards**, with no achievements. Its dialog confirms the items will be reviewed with version 1.1.0 on iOS. **The final Envoyer pour vérification button has not been clicked.**

The final local archive and Apple Distribution export passed signature, identifier, entitlement and **629 package checks**; 199 source fingerprints were unchanged. Evidence is in `artifacts/qa/release-1.1.0/final-ipa-metadata.json`. Xcode upload succeeded at **2026-09-24T07:24:44Z** (`artifacts/app-store-1.1.0-final/upload.log`). The upload used a separate export from the same archive; the local IPA SHA-256 is not asserted as the uploaded-byte hash. Earlier evidence records **97 passing core tests** and Release Store-capture tests on iPhone 17 Pro Max and iPad Pro 13-inch (M5).

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
| `release-readiness.json` | Current gates; build selected, five-item draft prepared; private contact and score testing pending |

The current description, promotional text, keywords, What’s New and review notes are saved. All **10 replacement screenshots** are processed and visually reviewed in the 1.1.0 draft: five iPhone 6.9-inch and five iPad 13-inch, ordered Weekly, Endless, Home, Controls, Audio.

The candidate adds Kenji and Japan Mountains as earned unlocks, a 2,600 m shared Weekly route, 40 local achievements, per-week/per-world records, revised controls and more flexible falls. Other planned riders/worlds remain unavailable. There are no ads or purchases.

## Identity

CrocoCross · app **6812979862** · bundle `com.daviddemri.crococross` · SKU `CROCOCROSS-IOS-001` · team `57XAAX65VC`. Candidate **1.1.0 (18)**, iPhone+iPad, minimum iOS/iPadOS 18. Seller: David Demri; copyright: 2026 Lafayette Consulting. Free; Games/Racing/Sports. Confirm agreements, age rating, territories and declarations before submission.

Existing URLs: [Support](https://daviddemri26.github.io/CrocoCross-iOS/support.html), [Privacy](https://daviddemri26.github.io/CrocoCross-iOS/privacy.html), [Marketing](https://daviddemri26.github.io/CrocoCross-iOS/). Their publication/current contents are not reverified by this package update. Private review contact stays outside public Git.

## Remaining Game Center work

Four v3 leaderboards are created, localized and associated with **app 1.1.0 (18) in the same five-item iOS review draft**: Weekly Score, Weekly Time, Endless Canyon and Endless Japan (`endless.japan.route_1.score.v3`). No final review submission has been sent. Both Weekly boards start **2026-09-28 00:00 UTC**, with seven-day duration and immediate restart; future occurrences are automatic, with no advance week creation or app history UI.

All **40 achievements / 1,000 points** work locally. Game Center achievement synchronization is **deferred and disabled** (`CrocoGameCenterAchievementsEnabled` absent/false). Seven complete remote records are preserved but are not included in the review draft: first backflip, first frontflip, double, triple, 10 total rotations, 1 km and first Weekly finish. There are no partial records to complete. The other 33 remote entries remain deferred; do not create, edit or delete more achievements.

The App Review **phone and email fields are blank**. Permission to reuse the prepared private contact file is pending; do not copy its contents into Git or upload them without that permission. **Real Game Center score round-trip testing has not been attempted**, so its readiness gate remains false. Preparation of the draft is not a final submission or a public release.

See [Game Center setup](../docs/GAME-CENTER-SETUP.md), [achievement metadata](../docs/ACHIEVEMENTS-GAME-CENTER.md) and [release gates](../docs/RELEASE.md).

## Authorized preparation

The owner authorized local candidate/archive/export preparation and committing/pushing reviewed source to GitHub main. Remote Game Center creation was subsequently authorized, then further achievement entry was stopped. Binary upload, App Review submission and public release remain separate actions. The existing Pages workflow publishes `distribution/web` changes on main; a website push is not a local-only edit.

`scripts/archive-app-store.sh` creates a local archive; export uses `destination=export`. A successful local archive/export is distinct from upload or Apple processing. Artifacts and signing material stay outside public Git. [Current handoff](HANDOFF.md).
