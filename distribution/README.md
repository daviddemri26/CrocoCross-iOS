# CrocoCross — App Store distribution

CrocoCross **1.2.0 (19)** and **Endless Jungle v3** were submitted on October 6, 2026 at 23:10 America/Los_Angeles. Both are **Waiting for Review**. Publication is automatic after approval, immediately to all users, with the existing rating retained. Version 1.1.0 (18) remains Ready for Distribution.

- App: `6812979862`; bundle `com.daviddemri.crococross`; team `57XAAX65VC`.
- Submission: `54239666-7a03-4a66-9762-be463dae2b97` — [Apple dossier](https://appstoreconnect.apple.com/apps/6812979862/distribution/reviewsubmissions/details/54239666-7a03-4a66-9762-be463dae2b97).
- Native source baseline: `bd426186619b25c4bd4ea3fc9243bd14d2d1179b`, with version/build settings updated to 1.2.0 (19).
- This update adds Milo on an electric scooter, Tropical Jungle and its platform jumps, Jungle camera/scenery changes and the Pause sound toggle. Existing progress and records are preserved.

## Store material

- `metadata/en-US/`: saved English subtitle, description, promo, keywords and What's New.
- `review/app-review-notes.txt`: saved reviewer instructions and feature scope. Existing complete contact fields were retained; private contact values remain outside Git.
- `metadata/app-information.json` and `release-readiness.json`: current identity, submission evidence and accurately scoped validation. Previous JSON snapshots are retained under `historical1_1_0`.
- `artifacts/marketing/app-store-release-2026-10-06/`: six iPhone screenshots, three iPad screenshots, Header and Search Results artwork, editable HTML/CSS composition, gallery, source hashes and generation prompts. All eleven PNGs are opaque RGB and contain only available or earnable release content. Original logo and genuine native UI layers are preserved.
- iPhone assets are 1320 × 2868, uploaded in Dynamic Island Large; required Medium uses the existing scaled assets. iPad assets are 2752 × 2064. Header is 3840 × 1646; Search Results is 1920 × 1280. Upload processing, screenshot order and live creative previews were checked.
- `screenshots/upload/en-US/`: historical five-per-device image sets, retained for prior-package validation; these are not the nine current remote screenshots.
- `icons/` and `game-center/achievements/`: original icon assets and forty local achievement badges.
- `web/`: website sources; website publication is separate from this App Store update and no website source changed here.

## Validation and remaining scope

114 core tests and 630 package checks passed, together with signature/entitlement checks, matching binary/dSYM UUIDs, 314 unchanged source fingerprints and 139 byte-identical bundled game assets. Package checks include the historical image package; current marketing files were verified separately by their source manifest and actual Apple uploads/previews. A separate Xcode export from the verified archive was uploaded; its bytes are not asserted identical to the inspected local IPA hash.

The new Jungle leaderboard is submitted with the app; four existing v3 leaderboards are Live and were not resubmitted. No achievements were submitted, and Game Center achievement synchronization remains disabled while all forty achievements remain local.

Physical-device gameplay and a genuine live Game Center score/rank round-trip were not performed in this session; the paired phone was locked. These checks remain unverified. App Review acceptance and public release are also pending.

Current evidence: `artifacts/release-2026-10-06/asc-state-final.json`, `asc-waiting-for-review.jpg`, `submission-report.md`, `package-verification.json` and `upload-verification.json`. Previous release documents are retained in Git history and the local `historical-docs-1.1.0/` evidence directory. See [handoff](HANDOFF.md), [release configuration](../docs/RELEASE.md) and [Game Center setup](../docs/GAME-CENTER-SETUP.md).
