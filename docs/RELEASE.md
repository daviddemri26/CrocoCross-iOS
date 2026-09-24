# Release configuration and gates

## Current candidate: 1.1.0 (18)

Verified on **September 24, 2026 at 00:32 America/Los_Angeles**: TestFlight **1.1.0 (18)** is processed (**Terminé**, **Prêt à soumettre**). Build 18 is selected and saved for version 1.1.0; the Save button is disabled. The existing **iOS review draft contains exactly five items: app 1.1.0 (18) and the four v3 leaderboards**, with no achievements. Its dialog confirms the items will be reviewed with version 1.1.0 on iOS. **The final Envoyer pour vérification button has not been clicked.**

The final local archive and Apple Distribution export passed signature, identifier, entitlement and **629 package checks**; 199 source fingerprints were unchanged. Evidence is in `artifacts/qa/release-1.1.0/final-ipa-metadata.json`. Xcode upload succeeded at **2026-09-24T07:24:44Z** (`artifacts/app-store-1.1.0-final/upload.log`). The upload used a separate export from the same archive; the local IPA SHA-256 is not asserted as the uploaded-byte hash. Earlier evidence records **97 passing core tests** and Release Store-capture tests on iPhone 17 Pro Max and iPad Pro 13-inch (M5).

The App Review **phone and email fields are blank**. Permission to reuse the prepared private contact file is pending; do not copy its contents into Git or upload them without that permission. **Real Game Center score round-trip testing has not been attempted**, so its readiness gate remains false. Preparation of the draft is not a final submission or a public release.

## Identity and local configuration

- CrocoCross · `com.daviddemri.crococross` · App Store Connect app `6812979862`.
- Team `57XAAX65VC`; iPhone and iPad, iOS/iPadOS 18 or later. Mac and Vision targets remain disabled.
- Free, no ads, no purchases, no separate CrocoCross account and no background-audio entitlement.
- Keep version/build settings in `scripts/generate-project.py`, the generated project and package metadata consistent. Automatic export build-number management is disabled.
- The app declares the Game Center entitlement, OS-only exempt encryption, no tracking, and the documented UserDefaults/SystemBootTime privacy reasons. Recheck the final signed bundle, not only these source files.
- The opaque 1024-pixel icon and bundled Box2D/license credits are present. Apple currently requires Xcode 26 or later and the iOS 26 SDK or later for uploads; recheck at upload time. [Apple SDK requirements](https://developer.apple.com/news/upcoming-requirements/).

## Game Center: boards created, remote achievements deferred

The four v3 boards are created, localized and **associated with app 1.1.0 (18) in the same iOS review draft**. Their state is ready for review; they have not been sent to Apple. Japan uses `endless.japan.route_1.score.v3`; the local route/storage identity is unchanged.

| Identifier suffix under `com.daviddemri.crococross.` | Type | Value | Ordering |
|---|---|---|---|
| `weekly.score.v3` | Recurring | Points | High to low |
| `weekly.time.v3` | Recurring | Centiseconds | Low to high |
| `endless.score.v3` | Classic | Canyon points | High to low |
| `endless.japan.route_1.score.v3` | Classic | Japan points | High to low |

The two Weekly recurring boards share a configured first start of **2026-09-28 00:00 UTC**, a seven-day duration and an immediate seven-day restart (604,800 seconds). They are configured once: Game Center creates subsequent occurrences automatically. The app presents the current week only, with no advance week creation or history UI. A ranked Weekly start still requires confirmed matching active schedules, and completing 2,600 m is required to submit points/time. See [Game Center setup](GAME-CENTER-SETUP.md).

All **40 achievements / 1,000 points** work locally. Game Center achievement synchronization is **deferred and disabled** (`CrocoGameCenterAchievementsEnabled` absent/false). Seven complete remote records are preserved but are not included in the review draft: first backflip, first frontflip, double, triple, 10 total rotations, 1 km and first Weekly finish. There are no partial records to complete. The other 33 remote entries remain deferred; do not create, edit or delete more achievements.

Genuine score/rank read-back, matching active Weekly occurrences and account/retry behavior remain unverified. Fake gateways and offline fixtures do not establish live Game Center behavior. Remote achievement restoration is deferred with the feature.

## Store material and validation

The current description, promotional text, keywords, What’s New and review notes are saved. All **10 replacement screenshots** are processed and visually reviewed in the 1.1.0 draft: five iPhone 6.9-inch and five iPad 13-inch, ordered Weekly, Endless, Home, Controls, Audio.

The draft retains **Automatic** release; recommending manual release has not changed that setting. The live baseline remains 1.0.0 (17), Ready for Distribution. Historical September 17 evidence in `distribution/review/` remains unchanged. Review any outstanding physical-device, account/declaration and public-page checks before final submission; installation or automated captures alone do not establish them. See [current handoff](../distribution/HANDOFF.md).

## Automation boundary

The existing GitHub workflow runs tests and a simulator build. Signing/archive/upload automation can be prepared separately with protected credentials and a manual trigger; no App Store deployment workflow is claimed operational here. GitHub Pages publishes `distribution/web` changes pushed to main, so website changes require a deliberate publication decision. A local archive/export remains distinct from upload, TestFlight distribution, App Review and public release.
