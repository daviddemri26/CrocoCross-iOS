# San Francisco riding surface

Generated on 2026-09-13 with the built-in ImageGen tool (no CLI fallback). Selected output copied byte-for-byte; no crop, recolor, compositing or resampling.

- Asset: `App/Resources/GameAssets/Terrain/sanfrancisco/road.png`
- Preserved previous asset: `artifacts/road-signatures/before/sanfrancisco-road.png`
- Source: `/Users/daviddemri/.codex/generated_images/01a09b7e-07f7-7f31-9209-1d8ce188e366/exec-25795391-57d4-46e7-bd9f-fdc76f6f5706.png`
- Dimensions: 1254 × 1254; RGB PNG, no alpha channel
- SHA-256: `ca41e65741d217f4b0d16805ee7e109aa87d901b40b873b0a79ebe06bf2f8726`

## Prompt

```text
Use case: stylized-concept.
Asset type: final opaque seamless horizontal road ribbon texture for CrocoCross, a polished hand-painted 2D side-scrolling motorcycle game.
Primary request: create a square 1024 by 1024 image of the SIDE FASCIA of an iconic warm vermilion steel bridge deck, giving San Francisco a distinctive exact riding line.
Technical composition: the entire square image will be compressed vertically into a 10 to 16 point high strip along a hill, with no crop. Therefore use very large, bold, simple forms. The opaque rectangle must be filled edge-to-edge by the bridge fascia, absolutely no scene or empty background. Horizontally tileable: continuous horizontal beams and matching left and right edge colors. Orthographic side elevation, flat straight top and bottom; no perspective, no vanishing point.
Structure: top 15 percent is a solid continuous flat orange steel upper beam that touches the wheels, a narrow golden-orange highlight along its top edge. Bottom 15 percent is one continuous orange lower beam. Middle 70 percent: three broad dark rusty rectangular recessed panels spanning the full width, with chunky bold vermilion diagonal X cross braces. Three panel divisions only, a few small silvery-brass round rivets only at structural joints. Braces run across the dark panels and remain visible as chevrons when image height is compressed. Strong contrast and clean silhouette.
Style/medium: simple high-quality hand-painted game illustration, soft broad painted shading, rounded bevel highlights, very restrained texture, readable at tiny height.
Palette: rich warm Golden Gate vermilion orange, dark maroon-rust recesses, warm orange-gold edge lights. Coherent with a sunlit San Francisco background.
Constraints: opaque square at least 1024 pixels; no transparency, no margins, no frame around image, all rectangular space is material. No text, numbers, logos, watermarks, vehicles, sky, buildings, shoreline, landscape, cables, towers, poles, guard rails, railroad rails, parallel silver rails or sleepers. No micrograin, scratches or noisy weathering. No top-down view.
```

## Inspection and integration notes

Inspected against App/Resources/GameAssets/san-francisco.png and the mine road.png technical reference. Warm vermilion bridge fascia fills the opaque square; three large dark inset panels and three X braces; continuous flat upper/lower orange beams; no text, scenery, tower or cable. Bold material is visually distinct from mine steel/sleepers. A few rivet clusters are secondary detail. Horizontal edges are structurally compatible; an exact pixel-identical seam is not claimed. Recommend full-height UV mapping, 14–16 pt road depth, approximately 2.4 m horizontal repeat so the three X panels remain readable. Native hill rendering and tiny-scale visual QA are handled separately.
