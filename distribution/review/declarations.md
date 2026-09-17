# Submission declarations — 1.0.0 (17)

Prepared from the current code and content. These declarations apply only to this app version.

## Privacy

Proposed answer: **Data Not Collected by the developer from the app**. There is no developer-operated backend, analytics, advertising or tracking SDK. Preferences, records and pending submissions are local. Game Center uses the app-scoped `gamePlayerID`, not `teamPlayerID`, and does not request friends.

Apple operates authentication and leaderboards. Eligible scores, times and game-scoped identifiers are processed by Apple, as explained in the public policy. Do not retain this declaration if a developer backend, profile extraction or analytics is added. [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/), [GameKit identifiers](https://developer.apple.com/documentation/gamekit/protecting-the-player-s-privacy-using-scoped-identifiers).

- Tracking: No. No ATT prompt is needed.
- Privacy policy: the English URL in metadata.
- Optional support email contains only the information the user chooses to send.
- GitHub Pages processes technical hosting requests; no analytics scripts are added.
- Privacy manifest: no tracking; empty collected-data array; UserDefaults reason **CA92.1**; SystemBootTime **35F9.1** for local audio/haptic intervals and Box2D timing. These clocks do not identify devices or send timing data to a server.

## Age rating

Cartoon crocodile falls and the final-life explosion contain no blood, gore or realistic human injury. Do not reuse the keyboard app's rating; Apple calculates this app's rating from its answers.

| Field | Current content |
|---|---|
| Parental controls / age assurance | No / No |
| Unrestricted in-app web browsing | No; fixed external links only |
| User-generated content, chat, social feeds | No |
| Advertising | No |
| Profanity, sexual content, nudity, drugs, medical topics | None |
| Horror / fear | No horror themes; cartoon race failures |
| Cartoon / fantasy violence | Repeated falls and explosions during play |
| Realistic violence, sadistic violence, weapons | None |
| Contests | Repeated leaderboard competition and weekly challenges; no monetary prizes |
| Gambling, simulated gambling, loot boxes | None |
| Made for Kids | No |

Frequent cartoon violence/contests may produce **13+ on OS 26+**. Use Apple's actual calculated rating and regional results. [Apple rating definitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions).

## Encryption

`ITSAppUsesNonExemptEncryption=false`. No custom cryptography or bundled cryptographic library. Connections and storage protections use Apple operating-system services. [Apple export compliance](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/).

## Publisher, rights and distribution

- Seller: David Demri. Copyright: 2026 Lafayette Consulting, matching SweetKeyboard Pro.
- The owner confirmed authorship of the artwork, music and rider-fall sound. The sound is now named `rider-fall-impact.wav`, without changing its audio. See `docs/SOURCE-PROVENANCE.md`.
- The Mixkit Fuel Explosion effect, Box2D and Lucide retain their separate licenses and credits.
- Standard Apple EULA applies unless the owner chooses a custom agreement.
- Reuse the existing account's verified business/trader details. Do not invent addresses or legal status.
- Reduced Motion is implemented. Do not claim full gameplay VoiceOver support without dedicated validation.
- Territories with local game-license requirements need actual authorization; no license number has been supplied.
