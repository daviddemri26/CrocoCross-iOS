# Canyon scenery image assets

Generated on 2026-09-13 with the built-in `image_gen.imagegen` tool, one separate call for each of the six assets. The existing `App/Resources/GameAssets/canyon-backdrop.png` was visually inspected as an aesthetic reference: peach sandstone highlights, lavender shadows, painterly illustrated landscape. No existing asset was edited.

## Delivery and verification

All six source PNG files were copied byte-for-byte to `App/Resources/GameAssets/Scenery/canyon/`. Their original generated files are preserved. All are RGBA and contain genuinely transparent pixels; there was no background-removal, recoloring, resizing, cropping, or procedural drawing after generation. Each generated result was visually inspected for its requested subject, a complete silhouette, refined painted detail, and absence of text or a frame. Main silhouettes remain within their canvases; fully transparent RGB edge padding can contain color data, which is invisible when alpha is honored. Alpha-above-128 bounding boxes below refer to visible content. The condor uses almost the full height and should be scaled with its original aspect ratio.

This asset-only verification does not claim live game integration or animation testing. Suggested subtle motion, when applicable: slow vertical drift for the two sky objects; very small breathing float for the resting fox; keep the fossil, geode, and cactus still. The wayside cactus replaces regular roadside poles when selected by the parent implementation.

## ground-1 — Ammonite fossil in a compact sandstone piece

- Destination: `/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Scenery/canyon/ground-1.png`
- Generated source: `/Users/daviddemri/.codex/generated_images/01a09904-f9e0-7e62-81a1-4fd6c688dfca/exec-aab507a0-b10f-41f5-8192-ee1ab543f4f1.png`
- Dimensions: 1536 × 1024; PNG RGBA; alpha = 0 on 44.51% of pixels.
- Visible alpha > 128 bounding box: 74, 98 – 1461, 936.

Exact prompt:

```text
Use case: illustration-story. Asset type: a small isolated transparent PNG scenery sprite for a beautiful side-scrolling motorcycle game, visible at about 60-110 px. Create one single charming richly painted 2D illustration, hand-painted storybook gouache with refined shapes and warm peach sandstone highlights, gentle lavender shadows, lively but tasteful small details. Beautiful natural painterly texture, polished illustration, no plastic 3D, no primitive geometric drawing, no thick black outline, no text, no logo, no frame. Subject complete and centered, occupies approximately 85% of the canvas, clean readable silhouette and small margin on every side, all extremities fully inside canvas. BACKGROUND MUST BE GENUINELY TRANSPARENT with an alpha channel, no scenery, no floor beyond the explicitly requested tiny object's base, no solid color backdrop, no checkerboard drawn into image, no cast shadow outside the subject. Output one PNG. Subject: a single ancient curled ammonite fossil embedded in a small irregular flat chunk of reddish canyon sandstone, warm pale beige spiral ribbing, naturally weathered edges, whimsical discovery for an American desert canyon. The fossil spiral is the clear focus; sandstone rock is a compact horizontal piece with a slightly angled face visible. View from side and slightly above, simple readable large spiral.
```

## ground-2 — Resting desert fox on a small sandstone ledge

- Destination: `/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Scenery/canyon/ground-2.png`
- Generated source: `/Users/daviddemri/.codex/generated_images/01a09904-f9e0-7e62-81a1-4fd6c688dfca/exec-6611022c-e00a-43e9-a60b-4a01e6b6f5af.png`
- Dimensions: 1374 × 1145; PNG RGBA; alpha = 0 on 45.88% of pixels.
- Visible alpha > 128 bounding box: 80, 37 – 1290, 1114.

Exact prompt:

```text
Use case: illustration-story. Asset type: a small isolated transparent PNG scenery sprite for a beautiful side-scrolling motorcycle game, visible at about 60-110 px. Create one single charming richly painted 2D illustration, hand-painted storybook gouache with refined shapes and warm peach sandstone highlights, gentle lavender shadows, lively but tasteful small details. Beautiful natural painterly texture, polished illustration, no plastic 3D, no primitive geometric drawing, no thick black outline, no text, no logo, no frame. Subject complete and centered, occupies approximately 85% of the canvas, clean readable silhouette and small margin on every side, all extremities fully inside canvas. BACKGROUND MUST BE GENUINELY TRANSPARENT with an alpha channel, no scenery, no floor beyond the explicitly requested tiny object's base, no solid color backdrop, no checkerboard drawn into image, no cast shadow outside the subject. Output one PNG. Subject: one adorable small desert kit fox resting curled on a tiny peach sandstone ledge, large alert ears, fluffy sandy orange fur, cream face and tail tip, happy subtle expression looking right. Full body plus little irregular ledge only, side view, natural graceful anatomy, refined painted fur, no clothes or props.
```

## ground-3 — Purple amethyst geode in warm stone

- Destination: `/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Scenery/canyon/ground-3.png`
- Generated source: `/Users/daviddemri/.codex/generated_images/01a09904-f9e0-7e62-81a1-4fd6c688dfca/exec-043d862b-56ac-4d2d-af73-6e53c725d82c.png`
- Dimensions: 1327 × 1185; PNG RGBA; alpha = 0 on 40.89% of pixels.
- Visible alpha > 128 bounding box: 64, 48 – 1263, 1126.

Exact prompt:

```text
Use case: illustration-story. Asset type: a small isolated transparent PNG scenery sprite for a beautiful side-scrolling motorcycle game, visible at about 60-110 px. Create one single charming richly painted 2D illustration, hand-painted storybook gouache with refined shapes and warm peach sandstone highlights, gentle lavender shadows, lively but tasteful small details. Beautiful natural painterly texture, polished illustration, no plastic 3D, no primitive geometric drawing, no thick black outline, no text, no logo, no frame. Subject complete and centered, occupies approximately 85% of the canvas, clean readable silhouette and small margin on every side, all extremities fully inside canvas. BACKGROUND MUST BE GENUINELY TRANSPARENT with an alpha channel, no scenery, no floor beyond the explicitly requested tiny object's base, no solid color backdrop, no checkerboard drawn into image, no cast shadow outside the subject. Output one PNG. Subject: one small naturally broken geode, warm peach sandstone outer shell with a beautiful purple amethyst crystal hollow facing viewer, a few large readable lavender crystal points and soft sparkling highlights without separate sparkles. Compact single stone, visually simple at small scale, side view and slightly from above, no other objects.
```

## sky-1 — Condor gliding right with extended wings

- Destination: `/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Scenery/canyon/sky-1.png`
- Generated source: `/Users/daviddemri/.codex/generated_images/01a09904-f9e0-7e62-81a1-4fd6c688dfca/exec-2dd29a3c-c3c1-4661-b5e5-7d66597743af.png`
- Dimensions: 1536 × 1024; PNG RGBA; alpha = 0 on 60.42% of pixels.
- Visible alpha > 128 bounding box: 28, 7 – 1502, 998.

Exact prompt:

```text
Use case: illustration-story. Asset type: a small isolated transparent PNG scenery sprite for a beautiful side-scrolling motorcycle game, visible at about 60-110 px. Create one single charming richly painted 2D illustration, hand-painted storybook gouache with refined shapes and warm peach sandstone highlights, gentle lavender shadows, lively but tasteful small details. Beautiful natural painterly texture, polished illustration, no plastic 3D, no primitive geometric drawing, no thick black outline, no text, no logo, no frame. Subject complete and centered, occupies approximately 85% of the canvas, clean readable silhouette and small margin on every side, all extremities fully inside canvas. BACKGROUND MUST BE GENUINELY TRANSPARENT with an alpha channel, no scenery, no floor beyond the explicitly requested tiny object's base, no solid color backdrop, no checkerboard drawn into image, no cast shadow outside the subject. Output one PNG. Subject: a single majestic friendly condor gracefully gliding to the right with spread wings, warm dark brown and cream feathers, full extended wings seen at a shallow three-quarter side angle, sunlight on upper feathers, small red-brown head. Clear elegant natural bird silhouette, no motion lines, no clouds, no ground, no sky background.
```

## sky-2 — Cream and canyon-red vintage propeller plane flying right

- Destination: `/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Scenery/canyon/sky-2.png`
- Generated source: `/Users/daviddemri/.codex/generated_images/01a09904-f9e0-7e62-81a1-4fd6c688dfca/exec-c5208489-7378-4f0e-b6ea-19e00d0ee94f.png`
- Dimensions: 1536 × 1024; PNG RGBA; alpha = 0 on 61.88% of pixels.
- Visible alpha > 128 bounding box: 33, 108 – 1513, 918.

Exact prompt:

```text
Use case: illustration-story. Asset type: a small isolated transparent PNG scenery sprite for a beautiful side-scrolling motorcycle game, visible at about 60-110 px. Create one single charming richly painted 2D illustration, hand-painted storybook gouache with refined shapes and warm peach sandstone highlights, gentle lavender shadows, lively but tasteful small details. Beautiful natural painterly texture, polished illustration, no plastic 3D, no primitive geometric drawing, no thick black outline, no text, no logo, no frame. Subject complete and centered, occupies approximately 85% of the canvas, clean readable silhouette and small margin on every side, all extremities fully inside canvas. BACKGROUND MUST BE GENUINELY TRANSPARENT with an alpha channel, no scenery, no floor beyond the explicitly requested tiny object's base, no solid color backdrop, no checkerboard drawn into image, no cast shadow outside the subject. Output one PNG. Subject: a single lovely tiny vintage propeller airplane in flight toward the right, cream fuselage with muted canyon red wings and tail, small dark teal windshield, one simple propeller, tasteful weathered painted metal detail, three-quarter side view, complete aircraft. No text, no registration marks, no logo, no contrails, no motion lines, no clouds, no landscape.
```

## wayside — Compact flowering prickly-pear cactus on a tiny rocky base

- Destination: `/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Scenery/canyon/wayside.png`
- Generated source: `/Users/daviddemri/.codex/generated_images/01a09904-f9e0-7e62-81a1-4fd6c688dfca/exec-07d500d3-2f60-4f60-987c-6d046506ca47.png`
- Dimensions: 1254 × 1254; PNG RGBA; alpha = 0 on 57.97% of pixels.
- Visible alpha > 128 bounding box: 167, 48 – 1144, 1213.

Exact prompt:

```text
Use case: illustration-story. Asset type: a small isolated transparent PNG scenery sprite for a beautiful side-scrolling motorcycle game, visible at about 60-110 px. Create one single charming richly painted 2D illustration, hand-painted storybook gouache with refined shapes and warm peach sandstone highlights, gentle lavender shadows, lively but tasteful small details. Beautiful natural painterly texture, polished illustration, no plastic 3D, no primitive geometric drawing, no thick black outline, no text, no logo, no frame. Subject complete and centered, occupies approximately 85% of the canvas, clean readable silhouette and small margin on every side, all extremities fully inside canvas. BACKGROUND MUST BE GENUINELY TRANSPARENT with an alpha channel, no scenery, no floor beyond the explicitly requested tiny object's base, no solid color backdrop, no checkerboard drawn into image, no cast shadow outside the subject. Output one PNG. Subject: a single compact flowering prickly-pear cactus growing directly from a tiny irregular peach sandstone rocky base, 4 or 5 muted sage-green rounded pads and two coral pink flowers, tiny painted pale spines. Appealing simple silhouette, squat small roadside plant for canyon, fully visible side view, base flat enough to sit beside a road. No pot, no post, no sign, no extra scenery.
```
