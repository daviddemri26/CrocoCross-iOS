# App Store submission package

## Current update — October 6, 2026

**CrocoCross 1.2.0 (19) and Endless Jungle v3 are Waiting for Review.** App Store Connect confirms **2 Items Submitted** in submission `54239666-7a03-4a66-9762-be463dae2b97`. Date Submitted is **October 6 at 23:10 America/Los_Angeles**, with minute precision; final item states were observed at 2026-10-07T06:11:27Z. Approval and public release are pending.

- Build 19 is processed, selected and saved. Source baseline is `bd426186619b25c4bd4ea3fc9243bd14d2d1179b` plus the recorded 1.2.0 (19) version settings.
- English subtitle **Bike Flips & Scooter Stunts**, description, promo, keywords, What's New and review notes are saved. The update adds Milo, Tropical Jungle route 6 and Pause sound controls; existing progress and records are retained.
- Six iPhone Dynamic Island Large screenshots and three iPad 13-inch screenshots are processed in order. The required iPhone Medium placement retains its existing scaled assets. One Header and one Search asset accompany the app review; final device previews preserve the full original logo and three-character composition.
- Jungle board `com.daviddemri.crococross.endless.jungle.route_6.score.v3`, resource `e49c53af-f72e-494c-8912-061329f87c54`, is the only new Game Center submission item. The existing four v3 boards are Live and were not resubmitted. No achievements were submitted; all 40 remain local and remote synchronization stays disabled.
- Existing review-contact fields are filled and sign-in required is unchecked; no private values are retained here. Published privacy remains Data Not Collected. Age/category/availability declarations are inherited, with no new legal agreement or pricing mutation.
- Release remains automatic after approval, immediately to all users, keeping the existing overview rating. Version 1.1.0 (18) is Ready for Distribution and its previous review is completed.
- Strict signature checks, matching binary/dSYM UUIDs, 314 source fingerprints, 139 bundled-art comparisons, 114 core tests and 630 local package checks pass. The package checks include historical local image sets; new media was separately verified in its manifest and ASC. The uploaded Xcode export is not asserted byte-identical to the local IPA.
- No physical-device playtest or genuine live Game Center score/rank round-trip was performed this session. The paired phone was locked; the live-score gate stays false. Submission does not establish gameplay read-back.

Current remote evidence is `artifacts/release-2026-10-06/asc-state-final.json` and `asc-waiting-for-review.jpg`; local package/upload evidence is in the same release folder. Current media and exact hashes are under `artifacts/marketing/app-store-release-2026-10-06/`. Historical 1.1.0 JSON snapshots are retained under `historical1_1_0`.

## Historical 1.1.0 preparation — September 24, 2026

The following dated preparation, validation and holds describe the earlier candidate. They are preserved as history and are superseded by the current release block above. In particular, prior blank-contact fields, unsubmitted draft and live 1.0.0 statements are not current.

The current candidate is **CrocoCross 1.1.0 (18)**, English (U.S.) only. Text is in [distribution/metadata/en-US](../distribution/metadata/en-US); current gates are in [HANDOFF.md](../distribution/HANDOFF.md).

Verified on **September 24, 2026 at 00:32 America/Los_Angeles**: TestFlight **1.1.0 (18)** is processed (**Terminé**, **Prêt à soumettre**). Build 18 is selected and saved for version 1.1.0; the Save button is disabled. The existing **iOS review draft contains exactly five items: app 1.1.0 (18) and the four v3 leaderboards**, with no achievements. Its dialog confirms the items will be reviewed with version 1.1.0 on iOS. **The final Envoyer pour vérification button has not been clicked.**

The current description, promotional text, keywords, What’s New and review notes are saved. All **10 replacement screenshots** are processed and visually reviewed in the 1.1.0 draft: five iPhone 6.9-inch and five iPad 13-inch, ordered Weekly, Endless, Home, Controls, Audio.

The copy describes Kenji/Japan earned unlocks, a 2,600 m Weekly course, 40 local achievements, per-world Endless records, flexible controls and falls. There are no purchases or ads. Remote achievement synchronization remains disabled; the seven saved remote achievements are excluded from the draft.

The final local archive and Apple Distribution export passed signature, identifier, entitlement and **629 package checks**; 199 source fingerprints were unchanged. Evidence is in `artifacts/qa/release-1.1.0/final-ipa-metadata.json`. Xcode upload succeeded at **2026-09-24T07:24:44Z** (`artifacts/app-store-1.1.0-final/upload.log`). The upload used a separate export from the same archive; the local IPA SHA-256 is not asserted as the uploaded-byte hash. Earlier evidence records **97 passing core tests** and Release Store-capture tests on iPhone 17 Pro Max and iPad Pro 13-inch (M5).

The App Review **phone and email fields are blank**. Permission to reuse the prepared private contact file is pending; do not copy its contents into Git or upload them without that permission. **Real Game Center score round-trip testing has not been attempted**, so its readiness gate remains false. Preparation of the draft is not a final submission or a public release. The draft still uses Automatic release; no release-setting change is claimed.
