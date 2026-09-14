# jungle riding surface

Generated on 2026-09-13 with the built-in image_gen tool (stylized-concept). One image call for this asset; no API/CLI fallback. Selected original PNG is copied byte-for-byte without editing, resizing, color conversion, or transparency changes.

Source: `/Users/daviddemri/.codex/generated_images/01a09b7d-a5c2-7e01-b28c-8ee69d00de3a/exec-5ba600ee-faea-441f-9e77-7440c61e31bf.png`

Destination: `App/Resources/GameAssets/Terrain/jungle/road.png`

Previous asset backup: `artifacts/road-signatures/before/jungle-road.png`

Reference context inspected: `App/GameCatalog.swift`, the world's catalog backdrop, and `App/Resources/GameAssets/Terrain/mine/road.png`. Those references were visually inspected, not passed as image edit targets. This is a newly generated material.

## Visual inspection and integration

Visually inspected at full resolution. Seven broad alternating honey-gold and green bamboo poles, recognizable bamboo nodes, two sparse dark rope bands, continuous green rims. Strong warm/green rhythm should remain legible when vertically compressed; full-height UV use is required.

Suggested road depth: 14 pt. Suggested horizontal tile width: 2.6 m. Use the full vertical image as the narrow ribbon; do not crop to a small vertical slice. Horizontal edge compatibility was prompted and visually assessed, but actual in-game repeat QA belongs to the consuming renderer.

## Exact generation prompt

```text
Use case: stylized-concept
Asset type: opaque square repeating 2D mobile game riding-surface material, 1024x1024 or larger.
Primary request: A beautiful clean painted BAMBOO WALKWAY material for a lush tropical jungle. The ENTIRE SQUARE will be compressed vertically into a very thin horizontal ribbon underneath motorcycle wheels, so use extremely large recognizable shapes, not small detail. This is a surface texture, not a scene.
Composition: perfectly flat orthographic surface, filling the entire rectangle edge-to-edge. About 7 broad golden honey and fresh moss-green bamboo poles aligned VERTICALLY in the image, side by side across its width; the poles become crosswise walkway slats when the image is compressed. Show one or two broad characteristic bamboo node rings per pole. Very narrow dark separations. A continuous smooth moss-green upper edge band at the very top, and a continuous warm dark moss-green lower edge band at the very bottom. Two sparse dark-brown rope bindings run horizontally across the bamboo near top and bottom, with simple broad binding marks. Left and right boundaries must match for seamless horizontal repetition; everything continues beyond both side edges.
Style: polished hand-painted game illustration, smooth restrained brushwork, warm luminous bamboo and deep jungle green, subtle painterly bevels, simple clear material identity. Opaque image, no empty background, no transparency.
Constraints: full 1024x1024 square is useful material, no horizon, no sky, no perspective or vanishing point, no landscape, no trees or loose leaves, no platform silhouette, no text, no numbers, no vehicles, no characters, no rocks, no grain or speckled noise, no scattered objects, no large border. Minimal detail that stays legible in a 14-pixel-high strip.
```


## File verification

Dimensions: 1254 x 1254 px. PNG IHDR color type: 2 (2 = opaque RGB; 6 = RGBA).

SHA-256: `e1531a976740dc0ed22e9551a8d5ae39bce2448757af8ab1e3735e14bf8a5913`
