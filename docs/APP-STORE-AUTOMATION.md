# Manual App Store automation

`.github/workflows/app-store.yml` prepares a signed App Store package from an explicitly selected **main** commit. It runs only via **Run workflow**; neither push, tags nor pull requests trigger distribution. Export is the default. The optional upload sends the same archive to App Store Connect; it does not submit to App Review, assign testers, edit Game Center, change Store metadata or release publicly.

## One-time setup, after owner authorization

No live setup was performed while preparing these files. Before running:

1. Create GitHub environment **app-store**. Restrict deployment branches to **main**, require an owner review, and disable administrative bypass if appropriate. The current repository is public, so treat its workflow code and artifacts as public-facing material.
2. Keep environment variable **APP_STORE_RELEASE_ENABLED** absent or `false` during the release hold. Set it to `true` only when the owner authorizes an archive/distribution candidate. This flag is a guard, not authorization by itself.
3. Add environment secrets **APPLE_DISTRIBUTION_P12_BASE64**, **APPLE_DISTRIBUTION_P12_PASSWORD**, and **APP_STORE_PROFILE_BASE64**. The P12 must contain an Apple Distribution certificate **and its private key**. Use an unexpired App Store profile for `com.daviddemri.crococross`, team `57XAAX65VC`, including Game Center. The script checks profile/team/entitlement/certificate agreement before archiving.
4. For optional upload only, add **ASC_PRIVATE_KEY_BASE64**, **ASC_KEY_ID**, and **ASC_ISSUER_ID** from an authorized App Store Connect API key with the necessary upload access. Export does not require these credentials. Do not paste keys into source, workflow inputs, logs, issues or chat.

GitHub documents [certificate/profile installation on macOS runners](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications) and [environment protection rules](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments). The script creates a temporary runner keychain and deletes it, its P12/profile and any API key both on exit and in an `always()` cleanup step. It does not export, read or modify signing credentials on the developer's Mac. Runner destruction is an additional cleanup boundary.

## Release operation

- Confirm the exact main commit, version and an **unused build number in App Store Connect**. The workflow's initial build input `18` is a candidate, not a reservation or proof of availability. Supply a new number on a rerun after an upload; a GitHub run number does not establish Apple build uniqueness.
- Complete the candidate's physical-device checks and intended Game Center configuration/validation separately. See [NEXT-RELEASE.md](NEXT-RELEASE.md). The release workflow does not activate pending leaderboards or achievements.
- In Actions → **Manual App Store package** → **Run workflow**, select **main**, enter the build number, and leave **upload** off to review a local export first. The marketing version comes from the project; the build number is passed to Xcode for this archive without rewriting source.
- Download the seven-day artifact. It contains the archive/dSYMs, exported IPA, command logs and `package.json` with the source commit, version/build and IPA hash. Signing secrets remain outside this artifact directory.
- Upload also runs `python3 scripts/check-app-store-package.py --submission`; the release-readiness flags must confirm the App Store version, the four Game Center boards and their real score round-trip, reviewed artwork, and final screenshots. Remote achievement requirements depend on the explicit release mode below. A valid local export or passing CI does not establish upload readiness.
- After export verification and explicit authorization to upload, run with **upload** on and an unused build number. Apple processes successful uploads asynchronously; confirm processing in App Store Connect before claiming the build is available. [Apple upload guidance](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds).
- Metadata, privacy/age declarations, Game Center definitions, tester groups, submission to App Review and public release remain separate owner-approved actions. Uploading alone does not publish the app.

### Local achievements and optional Game Center synchronization

The candidate retains all **40 local achievements / 1,000 points**. `distribution/release-readiness.json` declares `achievementReleaseMode` as `local-only` or `game-center`, plus the Boolean `remoteAchievementSyncEnabled`. These fields must agree with the actual `CrocoGameCenterAchievementsEnabled` Boolean in `App/Info.plist`; an absent key means disabled. The packaged configuration copy must still match the app.

- **Local-only:** use `achievementReleaseMode: "local-only"`, `remoteAchievementSyncEnabled: false`, and leave the app flag absent or `false`. The validator does not require `fortyAchievementsConfiguredAndAssociated` or `sandboxAchievementRoundTripPassed` to be true. Keep these gates false while remote configuration, version association or testing is incomplete; partial remote entries do not become proof of readiness.
- **Game Center synchronization:** use `achievementReleaseMode: "game-center"`, `remoteAchievementSyncEnabled: true`, and set the app flag to `true` only after both achievement gates are true: all 40 remote definitions are configured and associated, and a genuine achievement round-trip has passed. A flag/mode mismatch or missing gate fails validation.

Both modes retain every local catalog and badge integrity check. Both also require `appleVersionAndBuildVerified`, `fourLeaderboardsConfiguredAndAssociated`, `gameCenterArtworkComplete`, `releaseScreenshotsReviewed`, and `sandboxGameCenterRoundTripPassed` to be true. The last gate covers real leaderboard score/rank read-back and matching Weekly occurrences; it does not certify achievement synchronization. Any additional submission gate remains mandatory. All gate values must be explicit Booleans. This separation permits a local-only achievement release without marking deferred remote work complete or weakening leaderboard validation.

The workflow uses GitHub-hosted `macos-26` with `/Applications/Xcode_26.6.app/Contents/Developer`, matching existing CI. Checkout and artifact actions are pinned to commits verified against their official repositories. The available hosted Xcode image and Apple's submission requirements must still be checked when releasing.

## Preparation validation

Safe checks that do not archive, sign, upload or modify remote state:

```sh
bash -n scripts/app-store-ci.sh
git diff --check -- .github/workflows/app-store.yml scripts/app-store-ci.sh docs/APP-STORE-AUTOMATION.md
```

The workflow is unexecuted preparation until signing material and the protected environment are configured. Existing historical distribution evidence does not validate this new automation.
