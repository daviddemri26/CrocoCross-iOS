# CrocoCross App Store handoff

Verified September 17, 2026. App **6812979862**, version **1.0.0**, build **17**.

## Prepared

- English (U.S.) only: metadata, ten screenshots, public marketing/support/privacy pages, icon and build.
- Distribution-signed IPA uploaded successfully and processed by Apple; build 17 selected.
- Review contact and instructions saved; no app login required.
- Games > Racing/Sports, calculated 13+ on OS 26+ (12+ on earlier systems; regional exceptions), free pricing.
- 171 territories. China mainland and Vietnam are excluded because no game license was supplied; Afghanistan and Morocco are excluded by Apple's rating restrictions. Future territories are not enabled automatically.
- iPhone/iPad distribution; separate Mac and Vision Pro availability disabled.
- Game Center enabled. Three English v2 leaderboards are in a single iOS draft submission. The two weekly boards start September 21 at 00:00 UTC and recur every seven days.
- Manual public release selected. Nothing has been sent to App Review or released.

## Remaining owner confirmation

The [privacy page](https://appstoreconnect.apple.com/apps/6812979862/distribution/privacy) has the policy URL and **Data Not Collected** answer saved. Apple asks for an explicit accuracy/update attestation before publishing these answers. The assistant requested the owner's confirmation and has not accepted that commitment yet. This publishes only the privacy label, not the game.

After this attestation:

1. Open [version 1.0.0](https://appstoreconnect.apple.com/apps/6812979862/distribution/ios/version/inflight), choose **Add for Review**, and add it to the existing draft containing all three leaderboards.
2. Review the four items together (app version plus three leaderboards). The owner performs **Submit for Review**.
3. After Apple approves it, the owner performs the manual public release.

The version-level validation reports only the unpublished privacy declaration as missing. Live Game Center score upload/read-back has not been tested; creation of the boards is configuration evidence only. Weekly practice works before the first scheduled occurrence.

## Local delivery

The English package ZIP, signed IPA and archive are under `artifacts/app-store-release/` in the native project. They are excluded from public Git. The ZIP contains the private App Review contact, so keep it private. Git and the public website do not include that phone number.

[Apple submission workflow](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/)
