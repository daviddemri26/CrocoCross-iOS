# CrocoCross 1.1.0 (18) handoff

Verified on **September 24, 2026 at 00:32 America/Los_Angeles**: TestFlight **1.1.0 (18)** is processed (**Terminé**, **Prêt à soumettre**). Build 18 is selected and saved for version 1.1.0; the Save button is disabled. The existing **iOS review draft contains exactly five items: app 1.1.0 (18) and the four v3 leaderboards**, with no achievements. Its dialog confirms the items will be reviewed with version 1.1.0 on iOS. **The final Envoyer pour vérification button has not been clicked.**

## Prepared and verified

The final local archive and Apple Distribution export passed signature, identifier, entitlement and **629 package checks**; 199 source fingerprints were unchanged. Evidence is in `artifacts/qa/release-1.1.0/final-ipa-metadata.json`. Xcode upload succeeded at **2026-09-24T07:24:44Z** (`artifacts/app-store-1.1.0-final/upload.log`). The upload used a separate export from the same archive; the local IPA SHA-256 is not asserted as the uploaded-byte hash. Earlier evidence records **97 passing core tests** and Release Store-capture tests on iPhone 17 Pro Max and iPad Pro 13-inch (M5).

The current description, promotional text, keywords, What’s New and review notes are saved. All **10 replacement screenshots** are processed and visually reviewed in the 1.1.0 draft: five iPhone 6.9-inch and five iPad 13-inch, ordered Weekly, Endless, Home, Controls, Audio.

The draft retains **Automatic** release. The live baseline remains 1.0.0 (17), Ready for Distribution; September 17 files under `review/` are historical evidence.

## Remaining before final submission

- The App Review phone and email fields are blank. Permission to reuse the prepared private contact file is pending. Keep its contents out of Git.
- Real Game Center score/rank round-trip testing has not been attempted. Keep `sandboxGameCenterRoundTripPassed=false`; association of the boards does not prove gameplay read-back.
- Review outstanding physical-device, account/declaration and public-page checks, then make the final submission decision separately. **No final Envoyer pour vérification action has been performed.**

## Game Center scope

The draft includes Weekly Score v3, Weekly Time v3, Endless Canyon v3 and Endless Japan v3, including `endless.japan.route_1.score.v3`. Both Weekly boards begin **2026-09-28 00:00 UTC**, with seven-day duration and immediate restart. They are configured once; Game Center creates later occurrences automatically. The app has no weekly history UI.

All **40 achievements / 1,000 points** work locally. Game Center achievement synchronization is **deferred and disabled** (`CrocoGameCenterAchievementsEnabled` absent/false). Seven complete remote records are preserved but are not included in the review draft: first backflip, first frontflip, double, triple, 10 total rotations, 1 km and first Weekly finish. There are no partial records to complete. The other 33 remote entries remain deferred; do not create, edit or delete more achievements.

The local-only achievement mode deliberately exempts remote achievement configuration/testing from release gates; leaderboard score testing remains a separate requirement. No demo account is required. Signed archives/IPAs and private contacts stay outside public Git. [Machine-readable readiness](release-readiness.json).
