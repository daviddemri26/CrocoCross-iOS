# Painted road and underground materials

Nine landscape agents created eighteen opaque PNG paintings with the built-in image generation tool. The originals live in `App/Resources/GameAssets/Terrain/<world>/road.png` and `earth.png`. Both images cover the entire canvas with material; they contain no background scene or decorative objects. The exact prompts and original output provenance are linked below.

- [Canyon](terrain-prompts/canyon.md): compact golden sand over warm terracotta sandstone.
- [Japan Mountains](terrain-prompts/japan.md): muted earth path over soft woodland soil.
- [American Sunset](terrain-prompts/highway.md): warm grey asphalt over tobacco and ochre earth.
- [Tropical Jungle](terrain-prompts/jungle.md): ochre forest path over deep brown soil with olive nuances.
- [Arctic Aurora](terrain-prompts/arctic.md): pearly packed snow over milky blue glacier ice.
- [Old Gold Mine](terrain-prompts/mine.md): dusty mineral track over subdued brown slate.
- [San Francisco](terrain-prompts/sanfrancisco.md): blue grey asphalt over coastal grey mineral earth.
- [Paris](terrain-prompts/paris.md): small warm limestone pavers over pinkish chalky limestone.
- [Cloud Nine](terrain-prompts/clouds.md): ivory cloud surface over lavender cloud material.

## Rendering

`TerrainArtwork.swift` loads each image at a maximum of 768 pixels with mipmaps and a 24 MiB texture cache. The generated source PNGs are preserved intact. `TerrainStyle` controls the physical grain scale and surface thickness separately for every world. Paris pavers are roughly twenty centimetres wide; the whole square painting is never squeezed into the thin road ribbon.

`TerrainMaterialNode` pools six-metre strips and conforms their mesh to the sampled road. Texture coordinates use course position and depth below the surface, not screen position. This keeps painted details in place during scrolling, tile recycling and camera zoom. Fine road textures use mirrored sampling. Broad underground textures blend offset samples at their edges, avoiding both seams and the conspicuous symmetrical chevrons caused by mirroring. There are no time-dependent material animations. A gentle depth shade is anchored to the surface.

`TrackNode` clips the materials to the terrain and retains a thin, readable road silhouette. The former flat gradient, wavy strata, regular pebbles, artificial roots, rail-like lines and geometric material marks are removed. Cloud Nine retains its shallow floating ribbon, with a quieter, less regular lower contour, and separate mask for the scenery beneath it. The changes affect rendering only; the track height and physics are unchanged.

## Validation tools

```sh
swiftc -parse-as-library -module-cache-path /tmp/crococross-terrain-module-cache \
  scripts/check-terrain-assets.swift -o /tmp/crococross-check-terrain-assets
/tmp/crococross-check-terrain-assets
```

The asset check decodes all eighteen original files with ImageIO and verifies square dimensions of at least 1024 pixels and complete opacity.

Launch a Debug simulator build with `-terrain-review`, optionally `-terrain-review=canyon`, to export native SpriteKit views. The exporter produces landscape and portrait images at three camera positions per world, including a material-strip boundary crossing. It writes images and texture-load results into the app's `Documents/terrain-review/` directory. This opt-in exporter is excluded from Release builds.

```sh
swiftc -parse-as-library -module-cache-path /tmp/crococross-terrain-module-cache \
  scripts/check-terrain-scroll.swift -o /tmp/crococross-check-terrain-scroll
/tmp/crococross-check-terrain-scroll artifacts/terrain-review/renders
```

The scroll check compares the same painted underground points across camera translations. It verifies the material remains attached to the terrain, including when strips are recycled. Cloud Nine's thin floating ribbon is reviewed visually instead of sampling the sky beneath it.

[Native previews and validation results](../artifacts/terrain-review/README.md).

## Validation — September 12, 2026

All 18 original 1254 × 1254 opaque PNGs passed ImageIO integrity checks. All 54 native material views loaded the intended road and underground textures. The 32 image comparisons passed camera translation checks, including a strip recycle boundary. Landscape agents reviewed the results and rechecked the corrected earth blending and softened cloud contour.

The final gameplay renderer passed `testAllRidersAndWorldsRenderAndPlay` on the dedicated iPhone 17 / iOS 26.5 simulator: nine world/rider pairs, 193.385 seconds, zero failures. The unsigned simulator build succeeded. Physical-device performance was not measured.
