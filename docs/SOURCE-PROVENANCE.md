# Source and asset provenance

Read-only source snapshot: CrocoCross Sites export, git commit `4525d7d32ee874849ef664e1063df7001238f88f`.

The new project contains no `.openai/hosting.json`, Sites project ID, D1 database, Sites runtime or authentication headers. No migration of live profiles/scores/settings was requested or performed.

The native code is a new Swift implementation inspired by the source mechanics and artwork. Physics differs intentionally; JavaScript replay equivalence is not claimed.

## Bundled art/audio

The images, artwork and three music tracks were created by David Demri, who confirms that he holds all rights to them. The paths below record their import from the original web project.

- Original `public/croco-rider.png`, `public/canyon-backdrop.png`.
- Nine-rider catalog from `public/characters/` and nine-world catalog from `public/environments/` plus Canyon/Rocco.
- Three original music tracks created by David Demri, imported from `public/music/`: `quarter_in_the_slot.mp3`, `crossing_the_black_river.mp3` and `miles_past_the_skyline.mp3`.
- `public/effects/explosion-sheet.png` and `fuel-explosion.mp3`.
- CrocoCross branding from `public/branding/`.
- App icon from original `assets/branding/crococross-icon.png` (1254px opaque source), resized to1024px for the asset catalog.

WebP resources were converted losslessly to PNG for native loading. Native drawing derives runtime wheel masks and articulation from the source metadata. Cosmetic changes do not alter wheelbase, tire radius or collision rules.

## Owner confirmation and public repository

On September 12, 2026, David Demri confirmed that he created all images and the three music tracks and holds all rights to them. He also confirmed the rights needed to publish the bundled project files and explicitly authorized pushing the complete project, including its media, to the public `daviddemri26/CrocoCross-iOS` repository.

This records the owner's confirmation. It replaces the earlier pending-rights statement and the instruction to keep the source repository private.

## Existing third-party credit

Box2D 3.1.1 is vendored from the official Erin Catto repository under its MIT License. The exact release commit, archive checksum and compilation choices are recorded in [ThirdParty/Box2D/PROVENANCE.md](../ThirdParty/Box2D/PROVENANCE.md). CrocoCross's own source and media retain their separate rights.

The articulated Rocco artwork was generated with the built-in imagegen tool from the owner's original crocodile artwork on September 16, 2026, with permission to improve its style and details. Original assets are preserved. The selected transparent PNGs, prompts and provenance are recorded in [Rocco rig artwork](rocco-rig-prompts/README.md).

The explosion effect retains its existing attribution: Mixkit Fuel Explosion, item 1705, under the [Mixkit Sound Effects Free License](https://mixkit.co/license/#sfxFree). This sound-effect credit is separate from David Demri's authorship of the three music tracks.

Publication of this repository does not apply an open-source license or grant downstream rights to its media; see [RIGHTS.md](../RIGHTS.md).
