# Accepted implementation brief

Updated 2026-09-12 from David's execution instructions; supersedes the initial daily/phone-only plan.

1. Create an independent native game, preserve the continuing web/Sites project.
2. Use SwiftUI, SpriteKit, AVFAudio, GameKit and an independently testable Swift simulation.
3. Replace the daily event with a weekly 4,000-metre challenge, one life. Roll over Monday 00:00 UTC. Remove the obsolete 150-second cap; completion time remains a ranking metric.
4. Make riding more engaging and more demanding through rear traction, inertia and suspension. The front lifts from contact force/weight transfer, not a scripted wheelie. Landings may recover when the contact forces allow it. Tuning is code-owned; no workshop UI.
5. Keep the original visual identity, improve native animations, parallax, biome surface textures, beneath-terrain life and subtle rider movement.
6. Support portrait on compact iPhone; wide layout on iPad landscape and an open foldable. Use available scene bounds and safe areas, never a model-name detector or UIScreen.main.
7. Native Game Center identity and three independent leaderboards. No accounts/server shared with Sites, no backend replay verification in this version.
8. Save preferences, records, suspended runs and pending score submissions locally. Keep local practice available without login/network.
9. Free, no ads, no purchases. English UI retained. iOS18 baseline.

## Work sequence

Foundation → playable physics → all content/adaptive UI → Game Center integration → automated regression and simulator QA → signed physical device testing → TestFlight/live score readback → release.

The source can be complete before the external release gates are complete. Do not label the app production-validated until actual device play, live Game Center and release configuration are recorded in VALIDATION.md.

## iPhone Duo

Apple's documentation describes regular size classes for the inner display, asymmetric safe areas, and inner-display behavior that does not honor supported interface orientations. The renderer and UI resize continuously; phone portrait/iPad landscape masks do not substitute for this adaptation.

The installed toolchain during implementation was Xcode26.6/iOS26.5 SDK. Apple specifies Xcode27.1/DeviceHub for dedicated Duo pose simulation. Therefore adaptive iPad testing is useful evidence but does not establish Duo testing. A dedicated Xcode27.1+ run is required before claiming tested compatibility.

Source: https://developer.apple.com/videos/play/tech-talks/111461/
