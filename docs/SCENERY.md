# Painted scenery

Each of the nine worlds has six original transparent PNGs in `App/Resources/GameAssets/Scenery/<world>/`: three `ground` vignettes, two `sky` silhouettes and one static `wayside` accent. Exact generation prompts and source provenance are recorded in `scenery-prompts/<world>.md`. The built-in image generation tool created the artwork.

The old procedural actors, animated cutaway chambers, repeating wayside objects and San Francisco support braces have been removed. The single weekly finish flag remains a gameplay landmark.

Scenery has no physics bodies and never consumes the terrain or scoring RNG. A fresh cosmetic seed selects empty intervals, irregular offsets, image variants, sizes and depths for each ride. The same placement remains stable while scrolling or resizing the viewport. Ground images average one occurrence per 110 metres, wayside images per 192 metres, and sky passes per 61 seconds. These are statistical averages, not fixed placement distances; most views contain no extra decoration. Each sky pass lasts 15 seconds including its entry/exit margins.

Ground images sit below the sampled road height and are clipped by the exact terrain outline, including below Cloud Nine's floating road. Wayside images remain stationary at a fixed world coordinate, with their painted base touching the road. Lanterns, pots and upright props stay vertical; low plant/stone groups follow gentle slopes. Five samples under the image footprint reject steep or uneven bases; accepted props sit on the lowest support, accounting for rotation. Ground vignettes reserve the entire road-material thickness plus at least 0.10 metre of clearance. Their visible content is measured after removing transparent texture padding at load time. Image proportions are preserved. Generated PNG files are copied intact; ImageIO decodes at a maximum of 384 pixels and mipmapped SpriteKit textures use a 20 MiB cache. `SceneryPresentation.swift` defines the subject, dimensions and placement of each of the 54 images separately.

Motion is limited to a slow sky crossing with a tiny vertical drift and an optional two-point float for Cloud Nine's ground images. Reduce Motion disables that bob/rotation and replaces timed sky movement with a world-anchored image that only passes as the camera advances.

## Local checks

```sh
swiftc -swift-version 6 -module-cache-path /tmp/crococross-scenery-swift-cache \
  App/Scene/SceneryPlacement.swift scripts/check-scenery.swift \
  -o /tmp/crococross-check-scenery
/tmp/crococross-check-scenery
```

The placement harness checks all nine worlds, all 54 choices, sparse irregular gaps, stable placement across viewport boundaries and new-run variation. It does not validate the appearance of an image.

A Debug-only simulator review can be launched with `-scenery-review` (all worlds) or `-scenery-review=canyon` (one world). It writes native SpriteKit renders and an asset-loading report into the simulator app's Documents/scenery-review directory, using the real image loader, scenery nodes and terrain mask. The review is opt-in and is not compiled into Release. It intentionally frames each selected asset for inspection; normal gameplay uses the sparse schedule.

The asset-integrity harness uses Apple's ImageIO (no extra dependency):

```sh
swiftc -swift-version 6 -parse-as-library \
  -module-cache-path /tmp/crococross-scenery-swift-cache \
  scripts/check-scenery-assets.swift -o /tmp/crococross-check-scenery-assets
/tmp/crococross-check-scenery-assets
```

It verifies all 54 files exist, decode, carry alpha and contain both visible artwork and transparent pixels. The JSON output reports original dimensions and the measured transparent fraction. It complements visual review, since a valid alpha channel alone cannot prove a good silhouette.

## Image sets and exact prompts

- [Canyon](scenery-corrections/canyon.md): embedded ammonite, fennec in a burrow, embedded geode, condor, vintage plane, flowering cactus.
- [Japan Mountains](scenery-corrections/japan.md): buried ceramic pot, fox in a woodland den, mossy recess, small swallow, kite, upright stone lantern.
- [American Sunset](scenery-corrections/highway.md): buried hubcap, coyote in a den, buried horseshoe, plane, hawk, old tires and wildflowers.
- [Tropical Jungle](scenery-corrections/jungle.md): tapir in a root shelter, tiny frog in a root pocket, spring in a rock opening, macaw, small blue butterfly, fern and bromeliad.
- [Arctic Aurora](scenery-corrections/arctic.md): fox in a snow shelter, seal in an icy water opening, embedded ice crystals, snowy owl, small polar bird, frosted cairn.
- [Old Gold Mine](scenery-corrections/mine.md): mine cart on rails in a gallery, small mole in a burrow, embedded geode, small bat, tiny moth, correctly sized portable lantern.
- [San Francisco](scenery-corrections/sanfrancisco.md): sea lion in a sea cave, shell fossil, old cable mechanism, gull, pelican, orange poppies.
- [Paris](scenery-corrections/paris.md): small cat on books in a cellar recess, old railway wheel, buried antique key, small swallow, pigeon, roses and watering can.
- [Cloud Nine](scenery-corrections/clouds.md): cloud whale, floating island, warmer moon and stars, balloon, simplified flying fish, cloud flowers.

## Initial validation — September 12, 2026

- Final unsigned iOS Simulator build: passed.
- Original-asset integrity: all 54 PNGs decode and contain real alpha transparency.
- Placement harness: all nine worlds pass sparse spacing, variant coverage, viewport stability and independent run variation checks.
- Native SpriteKit review: all 54 targeted views rendered with their expected texture loaded. Reduced Motion assertions confirm that stationary-camera scenery stays still and scrolling passes it in the correct direction.
- `testAllRidersAndWorldsRenderAndPlay`: passed on the dedicated iPhone 17 / iOS 26.5 simulator, covering selection and gameplay for all nine world/rider pairs (195.966 seconds, zero failures).
- Visual review: original images inspected by their landscape agents; native views inspected for proportions, transparency, road contact and the floating-road mask.

[Local preview index](../artifacts/scenery-review/README.md). Logs, texture reports, original-alpha measurements and exported gameplay screenshots are in `artifacts/scenery-review/` (ignored build/QA output). The source PNGs, prompts and reproduction scripts are part of the project.

## Object corrections following the visual audit

The review in `artifacts/scenery-audit/` identified oversized small animals/insects, toy-sized vehicles and unsupported objects beneath the road. The revised artwork gives terrestrial animals a painted shelter, puts minerals into their surrounding rock, and replaces incompatible vehicles/boats with appropriately sized buried objects. The two fantasy cloud vignettes already suited to their setting are retained. Full subject lists, exact revision prompts and source provenance are in `scenery-corrections/<world>.md`; original generation records remain in `scenery-prompts/`.

The cosmetic placement schedule remains sparse. `SceneryPresentation` replaces the common image width with explicit per-object dimensions; these dimensions refer to the complete painted vignette, including its support. Small birds/insects get individually reduced screen scales, and butterflies/moths appear lower. The mine lantern is limited to a nominal 0.52-metre height including its stones. Its size, vertical alignment, smaller animals and catalog coverage are checked by:

```sh
swiftc -module-cache-path /tmp/crococross-scenery-swift-cache \
  App/Scene/SceneryPlacement.swift App/Scene/SceneryPresentation.swift \
  scripts/check-scenery-presentation.swift -o /tmp/crococross-check-scenery-presentation
/tmp/crococross-check-scenery-presentation
```

The revised Debug exporter produces 108 views (54 images in both orientations), reports their actual rendered dimensions, checks upright props and Reduce Motion, preserves backdrop proportions, and scales the reference rider by its real wheelbase. [Corrected preview gallery](../artifacts/scenery-corrections/README.md).


## Corrections validation — September 13, 2026

- 27 PNGs replaced/reworked; all 54 have explicit presentation profiles and pass transparency checks.
- Unsigned iOS Simulator build passed. The Debug exporter completed 108 native views, 54 images in both orientations, with loaded textures, road clearance, upright props, handheld lantern size and Reduce Motion assertions.
- The real steep-terrain reproduction (terrain 1234, scenery 3171, Japan at 429.740007 m) is rejected. Gentle upright and slope-following bases pass their contact checks.
- `testAllRidersAndWorldsRenderAndPlay` passed on the dedicated iPhone 17 / iOS 26.5 simulator: nine world/rider pairs, 201.174 seconds, zero failures on the final run. The first attempt stopped at an unexpected pause overlay at 0 m when starting Arctic; the same unchanged test passed on rerun. The cause of that initial pause was not established. Both logs and the failure recording are retained.
- Exact source replacements, SHA-256 comparisons, 54-object inventory, native views and gameplay captures are retained in `artifacts/scenery-corrections/`. The original 54 images are preserved in its `before/` directory.

[Visual review and small-detail limitations](../artifacts/scenery-corrections/visual-review.md).

Final visual review covered all 108 targeted views and nine gameplay captures. No blocking visual defect was observed; small-detail limitations are recorded in the linked review.
