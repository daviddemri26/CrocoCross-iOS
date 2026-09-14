# Canyon riding surface

Generated: 2026-09-13. Method: built-in `image_gen` (one asset per call), original PNG preserved byte-for-byte.

Target: `App/Resources/GameAssets/Terrain/canyon/road.png`

Source: `/Users/daviddemri/.codex/generated_images/01a09b7d-4ce0-7e73-8b30-ed72605b9728/exec-8d232352-8caf-4379-a6f6-41dbd8a0bf02.png`

Dimensions: 1254 × 1254. SHA-256: `7588f06259a9e08a073a39598abc0da8f838bf34f779965fe84dd8e3cf321bf8`

Previous asset retained at `artifacts/road-signatures/before/canyon-road.png`; SHA-256: `54de6ab0afe54e0d51eef3214d61d8f1dfdf72c4f34be0ca3a96163b4649886a`.

Reference inspection: existing mine rails (`Terrain/mine/road.png`) and world background from `GameCatalog.swift`. References informed the prompt; this is a new generated material, not a transformed source painting.

## Full prompt

```text
Use case: stylized-concept
Asset type: one square opaque PNG game material at least 1024x1024 for CrocoCross native iOS; NOT a complete scene.
Primary request: a distinctive CANYON sandstone riding surface. Create a fully filled square top-down orthographic material. The entire square will be compressed vertically into a 10–16 pixel-high ribbon under vehicle wheels, and repeated horizontally every 3 metres. Therefore use a handful of very large clear shapes, with no micro detail.
Subject: a SINGLE ROW of 5 to 6 chunky broad sun-worn ochre sandstone slabs filling the square edge to edge. Slabs run vertically from a smooth continuous golden upper edge/lip down to a darker terracotta lower edge. Slab widths irregular, generous, separated by widely spaced slender irregular VERTICAL joints. Smooth central ochre stone faces with subtle broad painted tonal planes. Only one row of slabs, no wall grid or cobbles.
Style/medium: premium simple hand-painted mobile game art, calm readable material, gently softened highlights, no heavy outline. In keeping with a painted sunlit canyon of peach sandstone mesas and bright blue sky, but NO scenery in this image.
Composition: strict straight-on/top-down material, flat rectangular filled canvas, the path direction is LEFT TO RIGHT. Continuous narrow golden band along the top 12% and quiet dark terracotta band along bottom 12%, broad stone faces between them. Identical materials and heights at left and right to permit a clean horizontal repeat. Zero perspective or horizon; no corners showing extrusion. No transparent area, margins, surrounding terrain, or isolated object.
Avoid: tiny grain, noisy texture, pebbles, grass, plants, rails, asphalt, wood, text, labels, signs, people, vehicles, sky, perspective vanishing point, diagonal road, decorative border frame, multiple rows of tiles. Distinct stone-block construction must remain legible after severe vertical compression.
```

## Visual acceptance and integration

Accepted after visual inspection: one row of six broad ochre slab faces, irregular dark vertical joints, pale golden top and terracotta bottom. No scenery, perspective, text, grass, vehicles or transparent margin. Broad painted planes replace granular ground. Left/right stone color is close, with continuous horizontal edge tones; exact pixel seam is not claimed. Recommend roadDepth 0.34 m, roadTile 3.2 m with full-height UV, for roughly 10–14 pt road depth at ordinary gameplay scale.

Native renderer and in-game QA are handled separately; asset acceptance alone does not establish simulator or device validation.
