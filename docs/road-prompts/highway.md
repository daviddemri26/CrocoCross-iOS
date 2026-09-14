# Highway riding surface

Generated: 2026-09-13. Method: built-in `image_gen` (one asset per call), original PNG preserved byte-for-byte.

Target: `App/Resources/GameAssets/Terrain/highway/road.png`

Source: `/Users/daviddemri/.codex/generated_images/01a09b7d-4ce0-7e73-8b30-ed72605b9728/exec-706228cb-0cdc-48c9-9bc6-8869c791f7e3.png`

Dimensions: 1254 × 1254. SHA-256: `4a89d34650417911144483457c625f79de38537458aaac278f14bc0117f5ce07`

Previous asset retained at `artifacts/road-signatures/before/highway-road.png`; SHA-256: `d9c6727ca8e32d2344bff3ea39046c0ce89609ac28580655b3a50b592ed1c564`.

Reference inspection: existing mine rails (`Terrain/mine/road.png`) and world background from `GameCatalog.swift`. References informed the prompt; this is a new generated material, not a transformed source painting.

## Full prompt

```text
Use case: stylized-concept
Asset type: one square opaque PNG game material at least 1024x1024 for CrocoCross native iOS; NOT a complete scene.
Primary request: distinctive American HIGHWAY riding-surface material. Fully filled square top-down orthographic asphalt material, absolutely no perspective. The full square will be vertically compressed into a shallow 14–16 pixel-high ribbon directly under vehicle wheels, and repeated horizontally. Make bold shapes survive this compression.
Subject: very quiet deep blue charcoal asphalt with exactly TWO crisp warm golden-yellow continuous parallel central road marking lines running perfectly LEFT TO RIGHT from canvas edge to edge. One yellow line occupies y=38% through 45%, the other y=55% through 62%, separated by an asphalt gap. Lines never dash, never converge, do not curve. Thin warm ivory continuous edge lines run horizontally at y=8% through 13% and y=87% through 92%. Asphalt fills all remaining areas. Simple clean freshly painted markings, subtle soft painterly edges but almost geometric clarity.
Style/medium: premium clean hand-painted mobile game material, restrained broad painterly asphalt shading with extremely low texture contrast. Matches a painted American desert sunset of coral pink and violet mesas, but includes NO scenery. Warm line colors and cool asphalt clearly distinctive from other worlds.
Composition/framing: square canvas entirely occupied by the flat material; road travel LEFT TO RIGHT; top-down orthographic no vanishing point, no horizon. All four horizontal markings remain constant width and same y positions at left and right edges for seamless horizontal repeat.
Avoid: vertical road, perspective, receding road, diagonal lines, dashed center lines, markings other than these four lines, cracks, stones, pebbles, grains, noise, tire marks, text, numbers, signs, vehicles, characters, grass, dirt shoulders, sky, mountains, shadows, margin, border frame. The two separated yellow center lines are the essential signature.
```

## Visual acceptance and integration

Accepted after visual inspection: deep blue charcoal asphalt with exactly two separated continuous horizontal golden-yellow lines and two thin ivory outer lines. No vanishing point, perspective, dashed markings, scenery, text or vehicles. All four lines meet left and right canvas edges at the same heights; subtle asphalt remains quiet. Recommend roadDepth 0.40 m, roadTile 3.6 m with full-height UV, for roughly 12–16 pt road depth at ordinary gameplay scale so the two yellow lines remain distinct.

Native renderer and in-game QA are handled separately; asset acceptance alone does not establish simulator or device validation.
