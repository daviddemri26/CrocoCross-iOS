# Cloud Nine scenery images

Created with the built-in `image_gen` tool, one independent generation call per sprite. Six original PNG files were copied intact into `App/Resources/GameAssets/Scenery/clouds/`; no image editing or Python retouching was applied.

Reference inspected: `App/Resources/GameAssets/cloud-nine.png`. The sprites use warm cloud highlights, blue/pink pastels and lavender shadows matching the painted floating-island landscape. Ground assets belong below the floating road, sky assets belong above, and the wayside flowers should sit directly at the road edge. Sparse placement and simple optional drift/bob are controlled by the shared scenery renderer.

## Visual and transparency QA

All six sprites were inspected individually with `view_image`. Each shows a complete, detailed painterly subject with no frame, text or pole. All PNGs have real RGBA transparency; alpha values span 0–255, except `sky-2` at 0–254. Tiny antialias values of 1 occur in a few nominally empty edge pixels and do not form visible cropped artwork. No destructive alpha manipulation was applied.

The fish preview displays a soft surrounding glow because the preview can reveal RGB stored underneath alpha 0. A sample pixel at (768,20) is RGBA (160,157,158,0): fully transparent. The file's four corners also have alpha 0. This is not a baked opaque backdrop.

## ground-1.png

Sleeping pastel whale on a small cloud. Head points right.

- Destination: `App/Resources/GameAssets/Scenery/clouds/ground-1.png`
- Generated source: `/Users/daviddemri/.codex/generated_images/01a09916-3247-7161-969d-895d292a40b8/exec-094f8f56-ccdd-45b3-a2f3-e4672de093ae.png`
- Actual dimensions: 1254 × 1254.
- Fully transparent pixels: 52.23%.

Exact prompt:

```text
Use case: illustration-story.
Asset type: a single isolated transparent PNG scenery sprite for an illustrated 2D side-view motorbike game, Cloud Nine cloud-heaven environment.
Style: exquisitely painted soft fantasy storybook illustration, detailed natural brushwork, luminous soft sunlight, creamy white clouds with lavender shadows, blue and blush pink pastel accents. Match a beautiful blue-sky landscape with floating cloud islands, warm sunlight and rainbow colors. Painterly depth, not a plastic 3D toy, not vector artwork, not geometric primitive art.
Composition: one complete compact subject, centered and filling approximately 85 percent of a square 1024x1024 canvas, all tips fully inside the frame, about 7 percent transparent padding. Clean readable silhouette at 60 to 110 pixels on screen. One sprite only.
Background: genuinely transparent RGBA alpha outside the subject. Absolutely no colored or white background, no checkerboard pixels, no backdrop, no frame, no ground plane, no typography, no letters, no watermark. Only the requested subject and its tightly connected details.
Subject: an adorable small pastel blue and lilac whale peacefully asleep on a little fluffy cloud cushion. Its eye is gently closed, its tail curls upward to the left, its smiling rounded head faces right. Side view. The cloud is compact underneath the whale, softly sunlit cream and blush pink, connected as one single floating decorative object. No ocean, no splashes.
```

## ground-2.png

Floating flower garden and a small leafy tree. Neutral side/front orientation.

- Destination: `App/Resources/GameAssets/Scenery/clouds/ground-2.png`
- Generated source: `/Users/daviddemri/.codex/generated_images/01a09916-3247-7161-969d-895d292a40b8/exec-bb208f0d-aa4a-46a6-970a-517495cffa28.png`
- Actual dimensions: 1254 × 1254.
- Fully transparent pixels: 58.43%.

Exact prompt:

```text
Use case: illustration-story.
Asset type: a single isolated transparent PNG scenery sprite for an illustrated 2D side-view motorbike game, Cloud Nine cloud-heaven environment.
Style: exquisitely painted soft fantasy storybook illustration, detailed natural brushwork, luminous soft sunlight, creamy white clouds with lavender shadows, blue and blush pink pastel accents. Match a beautiful blue-sky landscape with floating cloud islands, warm sunlight and rainbow colors. Painterly depth, not a plastic 3D toy, not vector artwork, not geometric primitive art.
Composition: one complete compact subject, centered and filling approximately 85 percent of a square 1024x1024 canvas, all tips fully inside the frame, about 7 percent transparent padding. Clean readable silhouette at 60 to 110 pixels on screen. One sprite only.
Background: genuinely transparent RGBA alpha outside the subject. Absolutely no colored or white background, no checkerboard pixels, no backdrop, no frame, no ground plane, no typography, no letters, no watermark. Only the requested subject and its tightly connected details.
Subject: one charming tiny floating island with a tapered underside of pale stone wrapped in fluffy white clouds, a lush little grass top sprinkled with a few pink and golden flowers, and one small rounded leafy tree with a slim trunk. A compact miniature cloud garden viewed from the side and a little above, suspended by itself. Soft sunlight, painterly lavender shading. No landscape background, no waterfalls, no long dangling pieces.
```

## ground-3.png

Pearlescent crescent moon on a small cloud, with three golden stars. Neutral orientation.

- Destination: `App/Resources/GameAssets/Scenery/clouds/ground-3.png`
- Generated source: `/Users/daviddemri/.codex/generated_images/01a09916-3247-7161-969d-895d292a40b8/exec-dd1cae55-b5b9-44f6-aa2c-f99210f69596.png`
- Actual dimensions: 1254 × 1254.
- Fully transparent pixels: 56.08%.

Exact prompt:

```text
Use case: illustration-story.
Asset type: a single isolated transparent PNG scenery sprite for an illustrated 2D side-view motorbike game, Cloud Nine cloud-heaven environment.
Style: exquisitely painted soft fantasy storybook illustration, detailed natural brushwork, luminous soft sunlight, creamy white clouds with lavender shadows, blue and blush pink pastel accents. Match a beautiful blue-sky landscape with floating cloud islands, warm sunlight and rainbow colors. Painterly depth, not a plastic 3D toy, not vector artwork, not geometric primitive art.
Composition: one complete compact subject, centered and filling approximately 85 percent of a square 1024x1024 canvas, all tips fully inside the frame, about 7 percent transparent padding. Clean readable silhouette at 60 to 110 pixels on screen. One sprite only.
Background: genuinely transparent RGBA alpha outside the subject. Absolutely no colored or white background, no checkerboard pixels, no backdrop, no frame, no ground plane, no typography, no letters, no watermark. Only the requested subject and its tightly connected details.
Subject: one softly glowing pearlescent crescent moon nestled in a small fluffy cloud, with exactly three little golden stars clustered close to the crescent, forming one compact self-contained ornament. The crescent curves gracefully upward, creamy opal texture and pale pink reflected sunlight, the cloud has soft lavender shadows. An enchanting quiet celestial object, no face, no sky or starfield behind it, no long dangling strings.
```

## sky-1.png

Upright pastel hot-air balloon with an empty wicker basket. Neutral left/right orientation.

- Destination: `App/Resources/GameAssets/Scenery/clouds/sky-1.png`
- Generated source: `/Users/daviddemri/.codex/generated_images/01a09916-3247-7161-969d-895d292a40b8/exec-2f4b5d18-cfd3-4238-b29e-8bf89ecb6f09.png`
- Actual dimensions: 1254 × 1254.
- Fully transparent pixels: 61.17%.

Exact prompt:

```text
Use case: illustration-story.
Asset type: a single isolated transparent PNG scenery sprite for an illustrated 2D side-view motorbike game, Cloud Nine cloud-heaven environment.
Style: exquisitely painted soft fantasy storybook illustration, detailed natural brushwork, luminous soft sunlight, creamy white clouds with lavender shadows, blue and blush pink pastel accents. Match a beautiful blue-sky landscape with floating cloud islands, warm sunlight and rainbow colors. Painterly depth, not a plastic 3D toy, not vector artwork, not geometric primitive art.
Composition: one complete compact subject, centered and filling approximately 85 percent of a square 1024x1024 canvas, all tips fully inside the frame, about 7 percent transparent padding. Clean readable silhouette at 60 to 110 pixels on screen. One sprite only.
Background: genuinely transparent RGBA alpha outside the subject. Absolutely no colored or white background, no checkerboard pixels, no backdrop, no frame, no ground plane, no typography, no letters, no watermark. Only the requested subject and its tightly connected details.
Subject: one small elegant whimsical hot-air balloon in a gentle side view, with a luminous rounded silk envelope in alternating pastel peach, butter yellow, blush pink and powder blue panels, fine realistic seams, a short delicate rigging and a tiny woven wicker basket below. The basket is empty. Complete upright balloon silhouette centered, very slightly tilted right for a drifting feeling. No clouds, no flames, no people, no scenic background.
```

## sky-2.png

Celestial fish kite. Head on the right, flowing tail on the left; intended movement is to the right.

- Destination: `App/Resources/GameAssets/Scenery/clouds/sky-2.png`
- Generated source: `/Users/daviddemri/.codex/generated_images/01a09916-3247-7161-969d-895d292a40b8/exec-d447cbe3-9a59-47f9-b5cb-66b59e546df3.png`
- Actual dimensions: 1536 × 1024.
- Fully transparent pixels: 59.32%.

Exact prompt:

```text
Use case: illustration-story.
Asset type: a single isolated transparent PNG scenery sprite for an illustrated 2D side-view motorbike game, Cloud Nine cloud-heaven environment.
Style: exquisitely painted soft fantasy storybook illustration, detailed natural brushwork, luminous soft sunlight, creamy white clouds with lavender shadows, blue and blush pink pastel accents. Match a beautiful blue-sky landscape with floating cloud islands, warm sunlight and rainbow colors. Painterly depth, not a plastic 3D toy, not vector artwork, not geometric primitive art.
Composition: one complete compact subject, centered and filling approximately 85 percent of a square 1024x1024 canvas, all tips fully inside the frame, about 7 percent transparent padding. Clean readable silhouette at 60 to 110 pixels on screen. One sprite only.
Background: genuinely transparent RGBA alpha outside the subject. Absolutely no colored or white background, no checkerboard pixels, no backdrop, no frame, no ground plane, no typography, no letters, no watermark. Only the requested subject and its tightly connected details.
Subject: one beautiful gently smiling celestial flying-fish kite facing and traveling RIGHT, with its rounded fish head on the right and flowing tail on the left. Airy pearl white and pastel blue fabric with pink and warm golden highlights, delicate painted fish scales, graceful winglike fins, one short curling ribbon tail closely behind on the left. Dreamy and charming, soft detailed painterly finish, compact horizontally oriented silhouette, no person, no kite string reaching outside the object, no clouds.
```

## wayside.png

Three open pastel celestial flowers and a bud, low foliage and flat-bottomed cloud tuft. Intended to rest directly beside the road.

- Destination: `App/Resources/GameAssets/Scenery/clouds/wayside.png`
- Generated source: `/Users/daviddemri/.codex/generated_images/01a09916-3247-7161-969d-895d292a40b8/exec-8c4cc72e-18b9-4ef0-8b65-4972b651b761.png`
- Actual dimensions: 1254 × 1254.
- Fully transparent pixels: 58.36%.

Exact prompt:

```text
Use case: illustration-story.
Asset type: a single isolated transparent PNG scenery sprite for an illustrated 2D side-view motorbike game, Cloud Nine cloud-heaven environment.
Style: exquisitely painted soft fantasy storybook illustration, detailed natural brushwork, luminous soft sunlight, creamy white clouds with lavender shadows, blue and blush pink pastel accents. Match a beautiful blue-sky landscape with floating cloud islands, warm sunlight and rainbow colors. Painterly depth, not a plastic 3D toy, not vector artwork, not geometric primitive art.
Composition: one complete compact subject, centered and filling approximately 85 percent of a square 1024x1024 canvas, all tips fully inside the frame, about 7 percent transparent padding. Clean readable silhouette at 60 to 110 pixels on screen. One sprite only.
Background: genuinely transparent RGBA alpha outside the subject. Absolutely no colored or white background, no checkerboard pixels, no backdrop, no frame, no ground plane, no typography, no letters, no watermark. Only the requested subject and its tightly connected details.
Subject: one low, charming cluster of celestial wildflowers growing directly out of a small compact tuft of fluffy cloud. Three or four lovely blossoms, pale pink, warm gold and periwinkle, with soft green leaves and short delicate stems. The cloud tuft forms a low horizontal base with a clear flat lower resting edge so this single small object can sit directly beside the road. Side view slightly from above. No vase, no pot, no post, no sign, no hanging decoration, no tall stalks, no landscape background.
```
