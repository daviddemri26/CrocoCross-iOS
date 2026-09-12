# Source and asset provenance

Read-only source snapshot: CrocoCross Sites export, git commit `4525d7d32ee874849ef664e1063df7001238f88f`.

The new project contains no `.openai/hosting.json`, Sites project ID, D1 database, Sites runtime or authentication headers. No migration of live profiles/scores/settings was requested or performed.

The native code is a new Swift implementation inspired by the source mechanics and artwork. Physics differs intentionally; JavaScript replay equivalence is not claimed.

## Bundled art/audio

- Original `public/croco-rider.png`, `public/canyon-backdrop.png`.
- Nine-rider catalog from `public/characters/` and nine-world catalog from `public/environments/` plus Canyon/Rocco.
- Three user-supplied MP3s from `public/music/`.
- `public/effects/explosion-sheet.png` and `fuel-explosion.mp3`.
- CrocoCross branding from `public/branding/`.
- App icon from original `assets/branding/crococross-icon.png` (1254px opaque source), resized to1024px for the asset catalog.

WebP resources were converted losslessly to PNG for native loading. Native drawing derives runtime wheel masks and articulation from the source metadata. Cosmetic changes do not alter wheelbase, tire radius or collision rules.

Explosion: Mixkit Fuel Explosion, item1705, https://mixkit.co/license/#sfxFree . The original AUDIO-CREDITS.md records permission for use incorporated in games and prohibits standalone stock redistribution. Keep the source repository private.

Before public release, the owner must confirm commercial distribution rights for the supplied music and image assets. The recovered files alone do not establish these rights. Inspect any visible third-party motorcycle branding before release; replace any unlicensed branding/content in the app copy.
