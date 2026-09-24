# CrocoCross 1.1.0 (18) preparation handoff

Signed-in checks on **September 23, 2026** confirmed **1.0.0 (17), Ready for Distribution**, and the owner-created **1.1.0 draft**, **À finaliser avant soumission**. Description, promotional text, keywords, What's New and App Review notes are saved in that draft. Its release setting remains **Automatic**; manual release is a recommendation, not an applied change. TestFlight has only 1.0.0 (17), uploaded September 16 and marked Ready to Submit. Build 18 remains local. Historical `review/store-status.json` retains the September 17 state without rewriting that evidence.

## Completed preparation

- Release **1.1.0 (18) archive succeeded**, with code signature verified. IPA export was attempted and **failed**: `No Accounts` / `No signing certificate "iOS Distribution" found`.
- **97 core tests passed**, as did Release `AppStoreCaptureTests` on **iPhone 17 Pro Max and iPad Pro 13-inch (M5)**. The refreshed package passed **584 checks**. Logs are under `artifacts/qa/release-1.1.0/`.
- Ten refreshed Store screenshots and both contact sheets are visually reviewed locally. The remote draft still has inherited 1.0.0 screenshots.
- Current English metadata and review instructions cover Kenji, Japan, 2,600 m Weekly, 40 local achievements, records, controls and flexible falls.
- Four v3 board IDs and a **40-achievement / 1,000-point** catalog are prepared. All 40 distinct achievement badges are generated and visually reviewed. No new leaderboard or achievement is configured remotely; achievement synchronization remains disabled.

## Remaining gates

1. Reconnect the Xcode account and provide distribution signing, then retry the authorized local IPA export and verify its final bundle/signature. Build 18 has not been uploaded; recheck build availability if preparation is delayed.
2. Upload the reviewed screenshots when authorized. Review final physical-device gameplay, audio, interruptions and controls; automated captures do not replace that validation.
3. When remote configuration is authorized, create/associate the four v3 leaderboards and 40 achievements with their reviewed localizations and images. Configure the two Weekly recurring boards once: matching Monday 00:00 UTC first starts, seven-day duration and immediate seven-day restart. Game Center creates future occurrences automatically; no advance week creation or history UI is required.
4. Validate genuine score/rank read-back, matching Weekly occurrences, account isolation and achievement restoration before enabling `CrocoGameCenterAchievementsEnabled`. Keep all remote readiness gates false until evidence exists.
5. Review the draft's release setting, private review contact, agreements, age rating, territory restrictions, privacy/export declarations and public support/marketing/privacy content. The Automatic setting does not authorize submission or release.

The owner authorized local candidate/archive/export preparation and committing/pushing reviewed changes to GitHub main. **Do not automatically upload, submit for review or publish.** TestFlight, App Review and public release remain distinct steps. A website-source push on main can trigger the existing GitHub Pages publication workflow.

Private Apple contacts and signed IPA/archive files remain outside public Git. No demo account is required; Game Center authentication is optional. [Machine-readable readiness](release-readiness.json).
