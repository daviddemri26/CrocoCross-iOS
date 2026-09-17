# CrocoCross — App Store package 1.0.0 (17)

English is the only app and Store language. Rocco and Canyon are the only playable character and world.

## Delivery files

| Folder | Use |
|---|---|
| `screenshots/upload/en-US/iphone-6.9/` | Five Store screenshots, ordered 01–05, 1320 × 2868 pixels |
| `screenshots/upload/en-US/ipad-13/` | Five landscape iPad screenshots, 2752 × 2064 pixels |
| `screenshots/raw/` | Real captures without marketing headings; alternative to the upload set |
| `icons/` | Twelve opaque icon sizes, including the 1024 × 1024 marketing icon |
| `metadata/en-US/` | One text file per Store or TestFlight field |
| `metadata/app-information.json` | App identity, URLs, price and categories |
| `review/` | App Review notes, privacy/age declarations and Game Center configuration |
| `private/app-review-contact.txt` | Owner-provided private Apple contact, excluded from public Git |
| `config/` | Export settings, app plist, privacy manifest and entitlements |
| `web/` | English support, privacy and marketing pages |
| `validation.json` and `VALIDATION.md` | Package checks and release evidence |

Use one screenshot set per device. The contact sheets named `preview-*.jpg` are for review, not upload. Screenshots contain real gameplay, without fabricated scores. App preview video is optional and is not included.

## App identity

- App: **CrocoCross**, iOS for iPhone and iPad, minimum iOS/iPadOS 18.
- [App Store Connect](https://appstoreconnect.apple.com/apps/6812979862/distribution/ios/version/inflight): **6812979862**.
- Bundle: **com.daviddemri.crococross**. SKU: **CROCOCROSS-IOS-001**.
- Version **1.0.0**, build **17**. Primary language: **English (U.S.)** only.
- Seller: **David Demri**. Copyright: **2026 Lafayette Consulting**.
- Free, no ads, no in-app purchases. Games: Racing / Sports.
- Native Mac and Vision targets are disabled. Their separate Store availability settings are also off.

## Public URLs

- [Support](https://daviddemri26.github.io/CrocoCross-iOS/support.html)
- [Privacy](https://daviddemri26.github.io/CrocoCross-iOS/privacy.html)
- [Marketing](https://daviddemri26.github.io/CrocoCross-iOS/)

Support and privacy contacts reuse the publisher details from SweetKeyboard Pro. The private review telephone is not published on the site or in Git.

## Apple preparation and final handoff

The CrocoCross record has been created. The owner connected the Apple Developer account in Xcode, and the App Store export succeeded. The earlier account/provisioning blocker is resolved. Build 17 has been uploaded, processed and selected. Detailed live status is recorded in `review/store-status.json`; see `HANDOFF.md` for the remaining owner actions.

The final action to **submit to App Review** and the eventual **release** remain with the owner. The first submission goes through Apple's review before the app can be publicly released. See [Apple's submission workflow](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/).

Game Center uses the three leaderboards in `review/game-center.json`. Both weekly boards must share a Monday 00:00 UTC anchor and a 604800-second duration/recurrence. A real score upload and read-back is separate from creating the configuration.

The development-signed archive and the exported distribution build are stored locally in `artifacts/app-store-release/`, outside public Git. The archive was built with Xcode 26.6 and the iOS 26.5 SDK.

## Reproduction

From the project root:

```sh
python3 scripts/generate-project.py
bash scripts/archive-app-store.sh /tmp/crococross-appstore-release
python3 scripts/check-app-store-package.py
```

The archive script does not upload. `config/ExportOptions-AppStore.plist` uses `destination=export` to produce a local IPA. A separately prepared upload configuration was used only after the owner authorized preparing the live Store record. Image generation uses Pillow and `scripts/prepare-store-images.py`; real UI captures are implemented in `UITests/AppStoreCaptureTests.swift`.

[Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
