# Release configuration and evidence

## Current update: 1.2.0 (19)

App Store Connect confirms **Waiting for Review** for iOS App 1.2.0 (19) and Endless Jungle v3. Submission `54239666-7a03-4a66-9762-be463dae2b97` was sent October 6, 2026 at 23:10 America/Los_Angeles, with minute precision. Publication is automatic after approval, to all users immediately, with the existing rating retained. The published baseline remains 1.1.0 (18), Ready for Distribution.

- App identity: CrocoCross, `com.daviddemri.crococross`, app `6812979862`, team `57XAAX65VC`.
- iPhone and iPad, iOS/iPadOS 18 or later; Mac and Vision availability remain disabled.
- Source baseline: `bd426186619b25c4bd4ea3fc9243bd14d2d1179b`, with 1.2.0 (19) settings in `scripts/generate-project.py` and the generated project. Automatic export build-number management is disabled.
- Free, no ads or purchases, no separate app account and no background-audio entitlement.
- Existing original logo, app icon, license credits and genuine native UI are preserved.

## Build and validation

Release arm64 compilation, Apple Distribution export and upload succeeded. Build 19 was processed by Apple, selected and saved for the new version. Final signed package checks confirm the correct identifiers/team, Game Center entitlement, no development debugging entitlement, matching binary/dSYM UUIDs, 314 unchanged source fingerprints and 139 byte-identical bundled game assets.

114 core tests and 630 package checks passed, along with persistence, audio, competition, panorama and Rocco articulation checks. The package validator includes historical five-per-device image sets. Current six-iPhone/three-iPad screenshots and Header/Search assets were checked separately for dimensions, opaque RGB, source hashes, complete UI composition, actual upload processing/order and live creative previews.

A separate Xcode distribution export from the verified archive was uploaded; the inspected local IPA hash is not asserted as the uploaded-byte hash. This session did not perform physical-device gameplay or a genuine live Game Center score/rank round-trip; the paired phone was locked. Those gates remain unverified.

Evidence is in `artifacts/release-2026-10-06/`: `package-verification.json`, `upload-verification.json`, `asc-state-final.json`, `asc-waiting-for-review.jpg` and `submission-report.md`. Current metadata is in `distribution/metadata/en-US/`; current media is in `artifacts/marketing/app-store-release-2026-10-06/`.

## Game Center configuration

All leaderboard identifiers share the `com.daviddemri.crococross.` prefix:

- `weekly.score.v3`: recurring, points, high to low; Live.
- `weekly.time.v3`: recurring, centiseconds, low to high; Live.
- `endless.score.v3`: Classic, Canyon points, high to low; Live.
- `endless.japan.route_1.score.v3`: Classic, Japan points, high to low; Live.
- `endless.jungle.route_6.score.v3`: Classic Single, integer points, Best Score, high to low, not hidden; Waiting for Review. English name: **Endless — Tropical Jungle**. Remote UUID: `e49c53af-f72e-494c-8912-061329f87c54`.

The four existing v3 boards were not resubmitted. The two Weekly recurring boards have a configured first start of September 28, 2026 at 00:00 UTC, seven-day duration and immediate seven-day restart. Future occurrences are automatic. Ranked Weekly start requires confirmed matching active schedules and a completed 2,600 m course before score/time submission. The app presents the current week; no history UI is claimed. See [Game Center setup](GAME-CENTER-SETUP.md).

All forty achievements remain local. Game Center achievement synchronization is disabled (`CrocoGameCenterAchievementsEnabled` absent/false). Seven remote achievement records are preserved and the remaining thirty-three deferred; none were included in this submission. Physical score/rank read-back, active Weekly occurrence matching and account/retry behavior remain separately unverified.

## Store and inherited declarations

English subtitle **Bike Flips & Scooter Stunts**, description, promo, keywords, What's New and review notes are saved. Six iPhone Dynamic Island Large screenshots and three iPad 13-inch screenshots are processed in the documented order; required iPhone Medium uses the existing scaled assets. Header and Search Results assets are assigned and reviewed with the app version, rather than separate submission items.

Existing complete review contact fields were retained, with sign-in required unchecked; no private values are copied into Git. Privacy remains Data Not Collected. Age ratings, category and availability remain unchanged; no new legal agreement or pricing change occurred. Submission is not evidence of Apple approval or public release.

## Automation and historical evidence

The existing GitHub workflow tests and builds the simulator app. It is not claimed to be an App Store deployment workflow. Website changes under `distribution/web` can trigger GitHub Pages publication on main and require a deliberate publication decision; no website source changed in this release.

Older release state is preserved in Git history, dated `distribution/review/` evidence and `historical1_1_0` JSON snapshots. Earlier blank-contact, unsubmitted-draft and public 1.0.0 statements describe their historical verification dates and are superseded by the current state above. See [handoff](../distribution/HANDOFF.md).
