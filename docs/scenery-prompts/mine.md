# Old Gold Mine scenery assets

Generated with the built-in image_gen tool in six independent calls. Inspected `App/Resources/GameAssets/abandoned-mine.png` first to match the slate-blue and amber palette. Original generated PNGs were copied intact; no image retouching, resizing or alpha rewriting was performed.

## Concepts and orientation

- `ground-1.png`: weathered mine cart with slate and golden stones, rightward three-quarter view.
- `ground-2.png`: curious mole emerging from a small mound, looking right.
- `ground-3.png`: turquoise and amethyst geode in slate rock.
- `sky-1.png`: gentle bat in flight, facing right.
- `sky-2.png`: amber moth in flight, facing right.
- `wayside.png`: small portable amber lantern resting on three stones; upright, no pole or gantry.

## Visual and transparency QA

All six outputs were opened with view_image and visually checked. Complete subjects are readable, organically detailed, and match the environment. True RGBA alpha is present in all outputs and contains fully transparent pixels; no opaque rectangular backdrop or painted checkerboard. Bat includes a soft translucent warm halo around its wing edges; it is preserved intact. Some nearly transparent edge pixels extend to canvas bounds (alpha 1); the native renderer may ignore those for visual bounds. Actual in-game layout is handled by the parent integration task.

```jsonl
{"name": "ground-1.png", "mode": "RGBA", "size": [1354, 1161], "alpha": [0, 255], "transparent_pct": 49.81, "partial_pct": 50.15, "bbox": [63, 9, 1318, 1147], "corners": [0, 0, 0, 0], "sha256": "cd1b497fb615bb0e82e9fea142ae29bc639af4fcd4380ef2039b196e1c7d0de1"}
{"name": "ground-2.png", "mode": "RGBA", "size": [1374, 1145], "alpha": [0, 255], "transparent_pct": 50.4, "partial_pct": 49.59, "bbox": [0, 9, 1368, 1145], "corners": [0, 0, 1, 0], "sha256": "a81571856192da215eeafcedadf621d6759218063a84a7a21cb367b9d77c904b"}
{"name": "ground-3.png", "mode": "RGBA", "size": [1305, 1206], "alpha": [0, 255], "transparent_pct": 33.02, "partial_pct": 66.97, "bbox": [0, 0, 1294, 1206], "corners": [0, 0, 1, 0], "sha256": "1e3cd3d8a7bf82e4a24bb4251c71423a98dc0d53243e8510ea9c1f9b7011a63e"}
{"name": "sky-1.png", "mode": "RGBA", "size": [1536, 1024], "alpha": [0, 254], "transparent_pct": 69.69, "partial_pct": 30.31, "bbox": [19, 21, 1515, 1007], "corners": [0, 0, 0, 0], "sha256": "1b852e484c2fabcb3122da7f63ea791aac14b08fd970b0ff8f2c4175b24fd033"}
{"name": "sky-2.png", "mode": "RGBA", "size": [1393, 1129], "alpha": [0, 255], "transparent_pct": 47.76, "partial_pct": 52.22, "bbox": [0, 14, 1379, 1129], "corners": [0, 0, 0, 0], "sha256": "fd83c222a6ac0e7d6f32cc2cefa1c72a9d1af9832d364f5554478ddd5291faed"}
{"name": "wayside.png", "mode": "RGBA", "size": [1214, 1295], "alpha": [0, 255], "transparent_pct": 69.34, "partial_pct": 30.6, "bbox": [0, 21, 1168, 1266], "corners": [0, 0, 0, 0], "sha256": "afcc43d00ded4685460e3178f80b58fffa0a2a3903b0db5483c8d4c1f817b71d"}
```

## Exact prompts and original sources

### ground-1

Source: `/Users/daviddemri/.codex/generated_images/01a09910-4695-71e1-ac18-f9ba2d6c7e13/exec-fb693c74-22f7-4780-9e39-7ca960a22e21.png`

Destination: `/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Scenery/mine/ground-1.png`

```text
Use case: illustration-story. Asset type: one small transparent PNG decoration for a polished side-scrolling motorcycle game, Old Gold Mine landscape. A naturally hand-painted detailed illustration, soft brushwork and organic believable textures, muted slate-blue shadows and warm amber highlights matching a cinematic old underground mine. Charming, simple and quietly fun, with strong readable silhouette at 60–110px. One complete isolated subject occupies about 85 percent of canvas, fully visible, no cropping. Real transparent alpha background, empty transparent surroundings, no colored backdrop, NO checkerboard pattern, NO ground plane, no frame, no lettering or watermark, no vector/primitives/stick figures, no plastic 3D. Avoid broad outer glow or halo.
Subject: a small antique mine cart in three-quarter side view facing right, sturdy dark weathered wood and worn iron rims, four small metal wheels, filled with rough slate rocks and a few naturally golden stones. No rails, no pole, no ground.
```

### ground-2

Source: `/Users/daviddemri/.codex/generated_images/01a09910-4695-71e1-ac18-f9ba2d6c7e13/exec-936eddce-aa9b-47f2-953d-cc1fc1bb9c61.png`

Destination: `/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Scenery/mine/ground-2.png`

```text
Use case: illustration-story. Asset type: one small transparent PNG decoration for a polished side-scrolling motorcycle game, Old Gold Mine landscape. A naturally hand-painted detailed illustration, soft brushwork and organic believable textures, muted slate-blue shadows and warm amber highlights matching a cinematic old underground mine. Charming, simple and quietly fun, with strong readable silhouette at 60–110px. One complete isolated subject occupies about 85 percent of canvas, fully visible, no cropping. Real transparent alpha background, empty transparent surroundings, no colored backdrop, NO checkerboard pattern, NO ground plane, no frame, no lettering or watermark, no vector/primitives/stick figures, no plastic 3D. Avoid broad outer glow or halo.
Subject: a curious little mole emerging from a compact small mound of dark earth and two little stones. Soft charcoal fur, tiny inquisitive eyes and pink nose, two small paws resting on the earth, looking slightly right. Charming natural animal illustration, no clothes, no tool, not overly cartoonish.
```

### ground-3

Source: `/Users/daviddemri/.codex/generated_images/01a09910-4695-71e1-ac18-f9ba2d6c7e13/exec-bfbf7618-815e-4e1f-ac93-3efdb8503a16.png`

Destination: `/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Scenery/mine/ground-3.png`

```text
Use case: illustration-story. Asset type: one small transparent PNG decoration for a polished side-scrolling motorcycle game, Old Gold Mine landscape. A naturally hand-painted detailed illustration, soft brushwork and organic believable textures, muted slate-blue shadows and warm amber highlights matching a cinematic old underground mine. Charming, simple and quietly fun, with strong readable silhouette at 60–110px. One complete isolated subject occupies about 85 percent of canvas, fully visible, no cropping. Real transparent alpha background, empty transparent surroundings, no colored backdrop, NO checkerboard pattern, NO ground plane, no frame, no lettering or watermark, no vector/primitives/stick figures, no plastic 3D. Avoid broad outer glow or halo.
Subject: one beautiful naturally broken blue-grey rock geode revealing a compact cluster of turquoise and muted amethyst crystals. Uneven organic shape and subtle amber reflections, contained painted highlights without magical sparks, complete single rock.
```

### sky-1

Source: `/Users/daviddemri/.codex/generated_images/01a09910-4695-71e1-ac18-f9ba2d6c7e13/exec-c50621cd-cda5-4518-8362-e597e7cc4ad5.png`

Destination: `/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Scenery/mine/sky-1.png`

```text
Use case: illustration-story. Asset type: one small transparent PNG decoration for a polished side-scrolling motorcycle game, Old Gold Mine landscape. A naturally hand-painted detailed illustration, soft brushwork and organic believable textures, muted slate-blue shadows and warm amber highlights matching a cinematic old underground mine. Charming, simple and quietly fun, with strong readable silhouette at 60–110px. One complete isolated subject occupies about 85 percent of canvas, fully visible, no cropping. Real transparent alpha background, empty transparent surroundings, no colored backdrop, NO checkerboard pattern, NO ground plane, no frame, no lettering or watermark, no vector/primitives/stick figures, no plastic 3D. Avoid broad outer glow or halo.
Subject: one gentle small bat in flight, side-three-quarter view facing RIGHT, wings broadly spread with natural rounded silhouette, slate-brown fur and softly translucent warm umber membranes. Sweet subtle expression, closed mouth, natural anatomy. No setting, no moon, no cloud, no accessories.
```

### sky-2

Source: `/Users/daviddemri/.codex/generated_images/01a09910-4695-71e1-ac18-f9ba2d6c7e13/exec-140263ea-c725-4e48-a5c3-e94f8bc085c2.png`

Destination: `/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Scenery/mine/sky-2.png`

```text
Use case: illustration-story. Asset type: one small transparent PNG decoration for a polished side-scrolling motorcycle game, Old Gold Mine landscape. A naturally hand-painted detailed illustration, soft brushwork and organic believable textures, muted slate-blue shadows and warm amber highlights matching a cinematic old underground mine. Charming, simple and quietly fun, with strong readable silhouette at 60–110px. One complete isolated subject occupies about 85 percent of canvas, fully visible, no cropping. Real transparent alpha background, empty transparent surroundings, no colored backdrop, NO checkerboard pattern, NO ground plane, no frame, no lettering or watermark, no vector/primitives/stick figures, no plastic 3D. Avoid broad outer glow or halo.
Subject: one large amber moth in flight facing RIGHT in a three-quarter profile, complete broad velvety ochre and brown wings slightly lifted, subtle natural wing markings, fine antennae and a small fuzzy body. Quietly lovely natural specimen, not a butterfly, no setting or sparkles.
```

### wayside

Source: `/Users/daviddemri/.codex/generated_images/01a09910-4695-71e1-ac18-f9ba2d6c7e13/exec-3a5a5e46-2c94-4bed-9164-343df62e7d34.png`

Destination: `/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Scenery/mine/wayside.png`

```text
Use case: illustration-story. Asset type: one small transparent PNG decoration for a polished side-scrolling motorcycle game, Old Gold Mine landscape. A naturally hand-painted detailed illustration, soft brushwork and organic believable textures, muted slate-blue shadows and warm amber highlights matching a cinematic old underground mine. Charming, simple and quietly fun, with strong readable silhouette at 60–110px. One complete isolated subject occupies about 85 percent of canvas, fully visible, no cropping. Real transparent alpha background, empty transparent surroundings, no colored backdrop, NO checkerboard pattern, NO ground plane, no frame, no lettering or watermark, no vector/primitives/stick figures, no plastic 3D. Avoid broad outer glow or halo.
Subject: one small old portable miner's lantern standing upright on a tight cluster of three little slate stones, dark weathered iron casing, short folded carrying handle, amber candle flame visible behind glass. Full object including its bottom. Subtle warm light contained in the glass, no large halo. No post, no gantry, no hanging chain, no ground plane.
```
