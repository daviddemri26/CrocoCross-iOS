# Release configuration and gates

## Apple identity

- Display name: CrocoCross
- Bundle ID: `com.daviddemri.crococross`
- Development team: `57XAAX65VC` (public certificate metadata verified locally)
- Current Store candidate version/build: 1.0.0/17
- Target families: iPhone+iPad; iOS18+
- Box2D 3.1.1 is compiled into the native app; its MIT license is bundled and accessible in About. No advertisements, purchases or background audio entitlement.

App Store Connect record **6812979862** was created under David Demri's account. Build **17** was exported with distribution signing, uploaded successfully, processed by Apple and selected for version **1.0.0**. The final App Review submission and manual public release remain owner actions. See `distribution/review/store-status.json` for the current handoff.

## Game Center

Configure **Best Score** and submit these with the first app version:

| ID | Type | Format | Sort |
|---|---|---|---|
| com.daviddemri.crococross.weekly.score.v2 | Recurring7days | Integer points | High to low |
| com.daviddemri.crococross.weekly.time.v2 | Recurring7days | Elapsed time in centiseconds | Low to high |
| com.daviddemri.crococross.endless.score.v2 | Classic | Integer points | High to low |

These boards belong to the fresh `box2d-1` rules. Until their configuration is confirmed, play stays local; a configured identifier alone does not authorize a ranked start.

Both weekly boards must start on the same Monday at 00:00 UTC, with a duration and restart interval of 604,800 seconds. The native service validates each board's start, duration, and `nextStartDate - startDate`, and requires matching occurrences before permitting a ranked weekly start. A seven-day duration with a longer restart interval is rejected. Apple exposes the next occurrence's beginning through [`GKLeaderboard.nextStartDate`](https://developer.apple.com/documentation/gamekit/gkleaderboard/nextstartdate).

Choose a Monday that is still in the future when creating the leaderboards: Apple does not allow the initial start date to be in the past. The two boards created on September 17, 2026 share the anchor `2026-09-21T00:00:00Z` (displayed as September 20, 17:00 UTC-7 in App Store Connect). Schedule beta competition testing after that first occurrence begins; until then, weekly practice and the classic Endless board remain available. Recompute the future Monday if configuration happens later, verify the actual returned dates, and use separate test accounts. [Apple's recurring-leaderboard setup walkthrough](https://developer.apple.com/videos/play/wwdc2021/10067/).

Required live proof: sign in, load matching week, finish a real run, submit points/time, read entries back for the same player and occurrence; repeat with another player. Test retry, sign-out/account change and expired-week behavior. Never fabricate leaderboard entries for testing.

## Store materials

- 1024px opaque icon included.
- Capture actual iPhone and iPad screens from the validated release build.
- Create a concise description covering the weekly 4,000 m challenge, Endless, Rocco, Canyon and touch controls. The eight other riders are disabled during this preview and will return progressively; do not advertise them as playable.
- Dedicated support/privacy pages and owner contacts are prepared in `distribution/`; see its README for live publication and signing status.
- Complete age rating, encryption/export questions, EU trader information where applicable, and privacy disclosures based on actual Game Center data flows. The privacy manifest is not a substitute for the App Store privacy questionnaire.
- Asset publication authorized by David Demri on September 12, 2026; original artwork/music authorship and rights confirmation are recorded in [SOURCE-PROVENANCE.md](SOURCE-PROVENANCE.md).
- Recheck Apple's SDK requirements on submission day.
- TestFlight internal beta, then external beta/review if needed; record feedback fixes.
- Submit the final candidate and Game Center components; choose manual release.

## Platform-specific validation

Physical iPhone: sustained play/performance, heat, interruptions, headphones/Bluetooth, silent switch, lock/unlock and multitouch. iPad: landscape, resizing, safe areas, menus. Duo: Xcode27.1+ DeviceHub poses and physical testing when available. Do not infer these from a generic successful build.

Support/privacy hosting, live Game Center configuration, TestFlight distribution and public release are separate operations; no local script performs them automatically.
