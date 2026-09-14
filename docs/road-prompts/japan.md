# Japan riding surface

Generated: 2026-09-13. Method: built-in `image_gen` (one asset per call), original PNG preserved byte-for-byte.

Target: `App/Resources/GameAssets/Terrain/japan/road.png`

Source: `/Users/daviddemri/.codex/generated_images/01a09b7d-4ce0-7e73-8b30-ed72605b9728/exec-86747edf-2b37-4f16-b0f4-bd5ee629eb74.png`

Dimensions: 1254 × 1254. SHA-256: `881fb72f41e28af31ce0e909918c75eec125c95d9f583ce70d97d5372f715f5d`

Previous asset retained at `artifacts/road-signatures/before/japan-road.png`; SHA-256: `659af4e11a3e8109b64e645b2fc2e302376a4f949e5240453b9df6e83907eefb`.

Reference inspection: existing mine rails (`Terrain/mine/road.png`) and world background from `GameCatalog.swift`. References informed the prompt; this is a new generated material, not a transformed source painting.

## Full prompt

```text
Use case: stylized-concept
Asset type: one square opaque PNG game material at least 1024x1024 for CrocoCross native iOS; NOT a complete scene.
Primary request: a distinctive JAPAN garden bridge riding surface. A fully filled square top-down orthographic material. The entire square will be compressed vertically into a very shallow 10–16 pixel-high ribbon beneath vehicle wheels, repeated left-to-right every 3 metres. Large shapes and clean bold differences must survive this severe compression.
Subject: elegant lacquered vermilion and muted dark red wooden Japanese bridge decking. 7 broad regular vertical planks run from top to bottom and repeat horizontally. Quiet warm vermilion faces, deeper red narrow plank joins. Wood only lightly suggested by a few broad clean painterly streaks, not lines of noisy grain. Each plank has two tiny muted brass joining dots, near top and bottom only. Continuous restrained red-brown side borders run perfectly LEFT TO RIGHT across the top 10% and bottom 10% of the canvas, with a softly lit lacquer upper edge.
Style/medium: premium simple hand-painted mobile game art, calm, slightly stylized. Harmonizes with a painted Japanese mountain lake landscape with blue peaks, green pines and cherry blossoms but NO scenery or plants in this material.
Composition: perfectly straight top-down rectangular filled canvas. Road travels LEFT TO RIGHT. Parallel planks constant width, no receding perspective. Flat borders at constant y positions. Left and right edges match for a clean horizontal repeat. Entire square opaque material, no margin, blank space, surrounding terrain or isolated bridge scene.
Avoid: perspective, horizon, vanishing point, arched bridge, handrails, posts, shadows from outside objects, kanji, any text, decals, signs, characters, vehicles, stones, noisy grain, scratches, rustic brown timber, multiple rows of wood. Red lacquer bridge identity must be obvious at small scale.
```

## Visual acceptance and integration

Accepted after visual inspection: seven regular vermilion lacquer planks, narrow dark seams, restrained horizontal dark red border beams, tiny brass joining dots. Clear bridge decking identity; no scenery, perspective, text, plants or vehicles. Left and right borders align; quiet edge color supports horizontal repetition. Recommend roadDepth 0.34 m, roadTile 3.2 m with full-height UV, for roughly 10–14 pt road depth at ordinary gameplay scale.

Native renderer and in-game QA are handled separately; asset acceptance alone does not establish simulator or device validation.
