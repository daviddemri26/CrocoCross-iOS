# Painted road and foreground surfaces

Every world has an opaque `road.png` and `earth.png` in `App/Resources/GameAssets/Terrain/<world>/`. Despite its retained filename, `earth.png` depicts a visible landscape surface in the foreground. The region below the riding line can contain open sand, grass, water or clouds. It is not a cutaway through the ground.

All **nine foreground paintings** use broad, quiet surfaces seen from a slight elevated angle. Their larger shapes leave space for the decorative images. The riding line now has a distinct painted signature in every world, following the mine railway treatment: eight new road images join the retained mine rails. Built-in image generation produced the artwork, and selected PNGs were copied intact. Exact prompts, source paths and checksums are linked below.

## Materials by world

| World | Riding surface | Current foreground |
| --- | --- | --- |
| Canyon | [Broad ochre sandstone slabs](road-prompts/canyon.md) | [Soft ochre sand, broad terracotta washes and sparse sage tufts](foreground-prompts/canyon.md) |
| Japan Mountains | [Vermilion lacquered bridge planks](road-prompts/japan.md) | [Moss, soft garden clearings and a few cherry petals](foreground-prompts/japan.md) |
| American Sunset | [Charcoal asphalt, double yellow centre line and ivory edges](road-prompts/highway.md) | [Quiet cream-ochre and peach sand with faint swept curves](foreground-prompts/highway.md) |
| Tropical Jungle | [Honey-green bamboo decking with rope bindings](road-prompts/jungle.md) | [Soft green moss and earth with a few subdued fern details](foreground-prompts/jungle.md) |
| Arctic Aurora | [Cyan ice plates, blue cracks and a snowy lip](road-prompts/arctic.md) | [Broad pale snow and turquoise ice patches](foreground-prompts/arctic.md) |
| Old Gold Mine | [Two rails and broad wooden sleepers](foreground-prompts/mine-road.md) | [Walkable brown-violet mineral floor with gentle amber light](foreground-prompts/mine.md) |
| San Francisco | [Vermilion bridge structure with dark X-braced panels](road-prompts/sanfrancisco.md) | [Continuous blue-teal bay water, without sandy islands](CITY-COHERENCE.md) |
| Paris | [Two staggered rows of cream limestone pavers](road-prompts/paris.md) | [Dry fan-pattern street cobbles and cream limestone paving](CITY-COHERENCE.md) |
| Cloud Nine | [Ivory cloud cushions with lavender joints and a golden thread](road-prompts/clouds.md) | [Continuous soft ivory, blush and lavender cloud masses](foreground-prompts/clouds.md) |

The old `terrain-prompts` files are historical. Current road provenance is in `road-prompts`, except for the retained mine railway in `foreground-prompts/mine-road.md`. Current `earth.png` provenance is in `foreground-prompts`, except the Paris/San Francisco replacements in [City coherence](CITY-COHERENCE.md).

## Mapping and coverage

`TerrainArtwork.swift` decodes paintings at a maximum dimension of **768 pixels**, applies linear filtering and mipmaps, and uses a **24 MiB** terrain texture cache. Source PNGs remain unchanged.

The road and foreground use pooled six-metre mesh strips conforming to the sampled riding line. Foreground paintings span **18 metres**, except Paris street paving at **6 metres** to keep individual stones proportionate to the motorcycle. The depth-shade parameter is **0.04**, so the surface remains light and readable across the area below the road. Coverage extends below the viewport in all nine worlds, including Cloud Nine; its foreground no longer ends at a shallow floating ribbon.

The foreground texture, its decorative images and the road all use horizontal scrolling factor **1**, in normal play and with Reduce Motion. The former 0.64 experiment has been removed after the ground appeared to slide. Both material coordinates and object footings remain attached to fixed terrain coordinates during scrolling and zoom. Object depth now controls fixed size and placement only; see [SCENERY.md](SCENERY.md). Neither terrain height nor physics is changed.

Broad foreground textures blend shifted samples near their edges to soften repeated-tile joins without conspicuous mirror symmetry. Narrow road paintings mirror horizontally between repeats, giving matching joins while preserving their top and bottom. There are no independently timed material animations.

Every road uses its painting's **full height** across a narrow riding strip. This preserves the rails, double yellow lines, borders and large joints instead of sampling a small horizontal slice of the image. The material remains fixed to the riding surface at scrolling factor **1**, matching the foreground. Strip recycling and camera zoom do not reset its world-space phase.

| World | Ribbon depth (m) | Image width (m) | Depth at fast portrait scale, 26.8 pt/m |
| --- | ---: | ---: | ---: |
| Canyon | 0.40 | 3.2 | 10.7 pt |
| Japan Mountains | 0.40 | 3.2 | 10.7 pt |
| American Sunset | 0.46 | 3.6 | 12.3 pt |
| Tropical Jungle | 0.46 | 3.0 | 12.3 pt |
| Arctic Aurora | 0.44 | 3.2 | 11.8 pt |
| Old Gold Mine | 0.42 | 3.6 | 11.3 pt |
| San Francisco | 0.48 | 3.0 | 12.9 pt |
| Paris | 0.44 | 2.8 | 11.8 pt |
| Cloud Nine | 0.44 | 3.2 | 11.8 pt |

The complete mirrored cycle spans twice the image width. `TrackNode` uses a subtle highlight matched to each painting, so the riding edge remains legible without a mismatched green or brown line over the new material.

`TrackNode` clips these materials below the terrain outline and retains a thin readable road edge. Decorative foreground images are drawn separately in front of the rider. Large subjects are anchored by their base and can extend above the riding line, briefly obscuring the motorcycle. In-app material export hooks and terrain score labels are absent.

## Current validation

All nine road images have been inspected as sources and in 27 native renders: nine portrait, nine landscape and nine road-focused views. The isolated SpriteKit harness passed 666 strip checks across 135 world/camera/zoom cases, including full-height mapping, constant depth, contact with hills and phase continuity. See [Validation](VALIDATION.md) for scope and evidence.

The existing ImageIO asset harness verifies all eighteen material files decode, have square dimensions of at least 1024 pixels, and are completely opaque:

~~~sh
swiftc -parse-as-library -module-cache-path /tmp/crococross-terrain-module-cache \
  scripts/check-terrain-assets.swift -o /tmp/crococross-check-terrain-assets
/tmp/crococross-check-terrain-assets
~~~

The updated `scripts/check-scenery.swift` passed shared foreground coordinate and scrolling-continuity checks, including strip-boundary and long-distance cases; see [SCENERY.md](SCENERY.md) for the command. Numerical continuity does not replace rendered seam and motion inspection.

Earlier [terrain generation records](terrain-prompts) and local validation captures remain historical evidence for earlier materials. They do not validate this pass. The old scroll-image comparison predates the current artwork and sampling; current native shader and footing checks provide the relevant evidence.

The [road signature gallery](../artifacts/road-signatures/index.html) records the nine riding bands. Current object depth and fixed-ground presentation are shown in the [ground perspective gallery](../artifacts/ground-perspective/index.html). Final results are recorded in [Validation](VALIDATION.md).

## Background composition

Each world uses one original painting. The renderer no longer tiles or mirrors backgrounds, so buildings, mountains and mine structures cannot be duplicated at a seam. Horizontal parallax eases toward a 24 pt limit using the distance from the run's camera origin, independently of motorcycle zoom. It does not wrap, oscillate or reverse. Reduce Motion disables this movement.

The painting covers both viewport dimensions with overscan. Clamped placement retains at least 8 pt of horizontal margin and 2 pt vertically, including large jumps and wide windows. San Francisco uses a wider portrait crop centred between the Golden Gate towers, retaining overscan and coverage. A new run, world or viewport framing establishes a new camera origin. Japan's crop keeps Fuji's summit visible in portrait and landscape; Paris aligns the top of the painting so the Eiffel Tower's tip stays inside the viewport.

Cloud Nine's thin riding edge now uses a soft lavender highlight (`B7A1CF`) to separate the ivory cushions from the pastel foreground. The road PNG and ribbon thickness are unchanged.

See the [integrated visual review](../artifacts/composition-review/index.html) and [validation details](../artifacts/composition-review/validation.md).
