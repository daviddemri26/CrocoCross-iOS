# Paris riding surface

Generated on 2026-09-13 with the built-in ImageGen tool (no CLI fallback). Selected output copied byte-for-byte; no crop, recolor, compositing or resampling.

- Asset: `App/Resources/GameAssets/Terrain/paris/road.png`
- Preserved previous asset: `artifacts/road-signatures/before/paris-road.png`
- Source: `/Users/daviddemri/.codex/generated_images/01a09b7e-07f7-7f31-9209-1d8ce188e366/exec-9b1baa17-b563-4a06-ad0e-88b23b8c7213.png`
- Dimensions: 1254 × 1254; RGB PNG, no alpha channel
- SHA-256: `a5dff71e2783cb2ca8cf19e7d19a6778b71b62be71dbc5289fcf398a50c601f6`

- Initial generation (not selected): `/Users/daviddemri/.codex/generated_images/01a09b7e-07f7-7f31-9209-1d8ce188e366/exec-a0507be0-a16b-492b-854f-1a872b1831eb.png`

## Prompt

```text
Use case: stylized-concept.
Asset type: final opaque seamless horizontal road ribbon texture for CrocoCross, a polished hand-painted 2D side-scrolling motorcycle game.
Primary request: create a square 1024 by 1024 image of a classic Paris limestone cobblestone promenade surface, a pale cream signature on the exact riding line.
Technical composition: this ENTIRE square image will be compressed vertically into a 10 to 16 point high ribbon along a hill, with no crop. Therefore use very large, bold simple shapes. A continuous narrow cream limestone upper lip occupies the top 12 percent. Under it, fill the rest of the rectangle with EXACTLY TWO slightly staggered rows of big rounded rectangular limestone pavers, three to four pavers across each row. The pavers are broad chunky rectangular blocks with softly rounded corners; the lower row is horizontally offset by half a block. No third row. All pavers fill the whole image, including cut continuation blocks at left and right edges. No empty background, no exterior pavement scene.
Perspective: flat orthographic material view, horizontal rows, no perspective, no vanishing point, no dramatic shadow. Edge-to-edge horizontally seamless repeat. Left and right edges must tile without a visible joint in tone or row placement; no vertical border.
Style/medium: simple high-quality hand-painted game illustration with clear large forms, subtle broad tonal shading, softly beveled paver edges, no granular speckling or photoreal texture.
Palette/material: pale cream and warm light grey limestone, a few muted dusty lavender-grey undertones, restrained dark mauve mortar lines between pavers, warm evening highlight along the continuous cream upper lip. Overall distinctly pale stone. Keep each paver face simple and smooth with only very faint broad shading. This is Paris stone, not ochre canyon rock.
Constraints: opaque square at least 1024 pixels; every pixel filled with material, no alpha, no margins. No text, numbers, logos, watermarks, vehicles, skyline, lamps, poles, landscape, vegetation, asphalt, pebbles, noisy cracks, micrograin, little stones, mosaics, ornate carvings, metallic elements. Exactly two rows of large pavers under the upper lip.
```

## Targeted edit prompt

```text
Use case: precise-object-edit.
Edit target: the supplied square Paris limestone ribbon texture.
Change only the row layout: eliminate the partial third row currently visible along the bottom. Enlarge the TWO existing main paver rows vertically so that the second row ends exactly at the bottom image boundary, leaving exactly two complete rows under the continuous upper lip. Keep the existing smooth pale cream and light warm grey paver material, mauve mortar, broad softly rounded rectangles, gently hand-painted style, square dimensions and fully opaque edge-to-edge composition. No extra rows or bottom border. Continue both rows cleanly at the left and right edges so the image repeats horizontally; no side border. Keep the warm cream upper lip simple and continuous. This image is a tiny riding ribbon, no scene, no text or additional objects.
```

## Inspection and integration notes

Inspected against App/Resources/GameAssets/paris.png and the mine road.png technical reference. The initial generation included an unwanted partial third paver row. A targeted built-in edit removed it; the selected final contains exactly two broad, staggered paver rows under a continuous warm cream lip. Pale cream/warm grey stone with muted lavender shading and mauve joints is distinct from ochre canyon stone and vermilion bridge steel. No text, scene or micrograin. Horizontal edges have compatible row placement and tone, but an exact pixel-identical seam is not claimed. Recommend full-height UV mapping, 12–14 pt depth, approximately 2.0–2.4 m horizontal repeat. Native hill rendering and tiny-scale visual QA are handled separately.
