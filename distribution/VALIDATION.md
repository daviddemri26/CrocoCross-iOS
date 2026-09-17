# Validation — CrocoCross 1.0.0 (17)

## Verified build and assets

- Release arm64 iOS archive built successfully with Xcode 26.6 / iOS 26.5 SDK, minimum iOS 18, iPhone and iPad.
- Bundle `com.daviddemri.crococross`, version 1.0.0, build 17. Archive signature verified with `codesign --verify --deep --strict`.
- Release UI capture scenarios passed on iPhone 17 Pro Max and iPad Pro 13-inch (M5), iOS 26.5 simulators. The first iPad capture attempt timed out opening How to; the unchanged second run passed and supplied the delivered images.
- Ten English marketing screenshots and twelve raw captures remain. All four French/English sets were originally reviewed; French assets have now been removed at the owner's request.
- Store PNG dimensions: iPhone 1320 × 2868; iPad landscape 2752 × 2064. Twelve opaque icon sizes include 1024 × 1024. Full real game captures are scaled without fake scores or poses.
- Package validation results are in `validation.json`; checks now enforce English-only localization.
- Full audio decoding passed: original rider-fall cue 4.09 seconds, explosion 2.35 seconds. Renaming the fall cue preserved SHA-256 `228f570ceabf993e83907366e50a630f583e743c0371f9a603f0235ef63e31c2`.
- The prior source commit `5bfe30a` passed GitHub core, persistence, audio, competition, scenery, asset and simulator-build CI checks.
- The owner connected Xcode. **App Store export succeeded**, resolving the earlier No Accounts/distribution-profile error. Store upload/preparation status is recorded separately after verification.

## Evidence and limits

Local evidence is kept in `artifacts/app-store-release/evidence/`, excluded from public Git. The private Apple contact is excluded from public Git and public HTML. French pages are removed from the current website source.

Build 17 was not newly installed on a physical device during Store preparation. Its driving parameters are unchanged. UI captures do not prove live Game Center score submission or human gameplay quality. The final App Review submission and public release remain owner actions.
