# Jungle scenery corrections

Generated with the built-in `image_gen` tool in three independent calls on 2026-09-13. Project PNGs are intact copies of tool outputs, with no cropping, recoloring, alpha processing or resampling.

## Context inspected

Inspected the full `App/Resources/GameAssets/tropical-jungle.png` landscape and all three previous `App/Resources/GameAssets/Scenery/jungle/ground-{1,2,3}.png` assets. The previous moss pedestal, oversized frog and isolated ornamental waterfall lacked a convincing place in the soil below the road. Originals were backed up by the parent agent in `artifacts/scenery-corrections/before/Scenery/jungle`.

## Objects and intended scale

- **ground-1: Tapir endormi dans un abri de terre et racines.** Intended total vignette width: approximately 2.7 m. Source: `/Users/daviddemri/.codex/generated_images/01a0993e-0dd9-7a40-ae50-15e3f237e0e1/exec-eb1283f2-c90b-487f-ada8-d3e058b88204.png`. Saved to `App/Resources/GameAssets/Scenery/jungle/ground-1.png`.
- **ground-2: Petite grenouille sur feuille dans une poche de mousse et racines.** Intended total vignette width: approximately 0.5 m. Source: `/Users/daviddemri/.codex/generated_images/01a0993e-0dd9-7a40-ae50-15e3f237e0e1/exec-5cc95587-f2bc-4b02-8219-86d2d40ad92e.png`. Saved to `App/Resources/GameAssets/Scenery/jungle/ground-2.png`.
- **ground-3: Source et bassin dans une ouverture rocheuse, avec arrivée et sortie d'eau.** Intended total vignette width: approximately 1.5 m. Source: `/Users/daviddemri/.codex/generated_images/01a0993e-0dd9-7a40-ae50-15e3f237e0e1/exec-55af31bc-813f-486d-b2a1-08abc7ef780b.png`. Saved to `App/Resources/GameAssets/Scenery/jungle/ground-3.png`.

The frog occupies roughly one fifth of the vignette width: at 0.5 m total it reads as approximately 10 cm rather than a giant animal. Width here is the entire supporting recess, not the animal alone. The tapir now rests on a horizontal floor inside an open natural shelter. The spring has a visible water source, a low drop into a shallow pool and an outlet channel.

## Validation

Inspected all three final workspace PNGs visually. They provide a frontal lateral cutaway, modest natural earth/root/rock context, horizontal support and softly irregular boundaries. No painted checkerboard, rectangular frame or floating diorama base. The muted brown supporting material is compatible with the new forest earth texture; the small water and leaf accents match the existing jungle palette.

All files decode through ImageIO/CoreGraphics at **1536 x 1024** and have a real alpha channel. A pixel scan verified transparent exterior pixels and opaque interior content; all four image corners have alpha 0:

- ground-1: 46.47% of pixels alpha < 8; 52.84% alpha > 200.
- ground-2: 47.80% of pixels alpha < 8; 50.72% alpha > 200.
- ground-3: 54.79% of pixels alpha < 8; 44.50% alpha > 200.

The source includes soft edge coloration; compositing and final in-game visibility still need the parent's native QA. Exact world scale and placement, and the separate butterfly reduction, are handled in shared renderer code by the parent agent. This agent made no code or other-world asset modifications.

## Exact prompts

### ground-1

```text
Use case: stylized-concept
Asset type: transparent PNG scenery sprite for a premium illustrated 2D side-scrolling jungle motorcycle game.
Primary request: a peaceful brown tapir sleeping in a natural earthen root shelter, open across the front, shown in a straight-on lateral cutaway. This sprite will be embedded within brown forest soil below the game's road, so the animal needs a believable horizontal ground and a sheltered recess, not a floating display pedestal.
Subject and proportions: one anatomically recognizable adult brown tapir curled asleep, its small flexible snout resting near front feet, occupying around 65 percent of the width of a shallow natural shelter whose total real-world width is about 2.7 metres. Modest thin arch of warm brown earth and a few roots above it, dark warm shallow hollow behind the animal, small patch of moss on the horizontal floor. No thick ornamental frame.
Style: polished gently painted illustration, soft believable fur and earth details simplified for a small game sprite, natural jungle palette, charming but not plastic or 3D. Compatible with lush emerald illustrated jungle and turquoise distant waterfall. Keep the animal silhouette clear.
Composition: front-facing elevation, horizontal side-on ground plane, no aerial or isometric view. Compact horizontal vignette. Thin irregular brown earthen boundary blends softly into TRUE ALPHA TRANSPARENCY on every outer side; transparent outside the shelter. Entire sprite safely inside image with margins. Minimal supporting environment only. No standalone island, diorama plinth, massive rock ring, rectangle, frame or landscape backdrop.
Lighting: gentle diffuse warm light, readable sleepy face, no dramatic spotlight.
Output: one high quality PNG at least 1024 pixels with genuinely transparent background and clean alpha edges, not a painted checkerboard. No text, labels, border, horizon, extra animals or watermark.
```

### ground-2

```text
Use case: stylized-concept
Asset type: transparent PNG scenery sprite for a premium illustrated 2D side-scrolling jungle motorcycle game.
Primary request: a TINY red-eyed green tropical tree frog on a leaf, nestled in a small natural pocket of roots and moss in brown forest earth. Seen straight from the side/front in a natural shallow cutaway recess, open across the front. The entire vignette represents only half a metre in width; the frog is a small 10 cm animal, occupying about ONE FIFTH of the vignette width, not a giant frog.
Subject: one small recognizable green frog with orange toes and red eyes, calm side profile on a single curled green leaf. The leaf rests on a thin horizontal mossy earthy ledge. A few fine roots and a thin irregular dark brown earth overhang suggest a shallow forest pocket behind it. Minimal small-scale support, no large boulders, flowers or ornate moss island. Keep the frog visible despite its small relative size; simplicity matters more than tiny ornament.
Style: beautiful softly painted illustration with restrained believable detail, natural emerald and moss green, warm umber earth, tiny warm orange accents. Same quality as a lush illustrated jungle environment. Not plastic or rendered 3D.
Composition: frontal lateral elevation appropriate for a flat 2D side-view game. No aerial/isometric perspective, no freestanding diorama pedestal. Thin softly irregular dark brown earthen edges fade directly to TRUE ALPHA TRANSPARENCY all around. All exterior canvas must be genuinely transparent. The recess interior behind frog is muted brown. No solid rectangular backdrop or thick frame. Entire sprite has safe transparent margins.
Output: one high quality PNG at least 1024 pixels, with genuine transparent background, clean alpha edges, no painted checkerboard, no backdrop haze or halo. No text, labels, watermark, border, horizon, additional animals or landscape.
```

### ground-3

```text
Use case: stylized-concept
Asset type: transparent PNG scenery sprite for a premium illustrated 2D side-scrolling jungle motorcycle game.
Primary request: a small natural spring inside a shallow rocky opening shown in frontal lateral cutaway. The sprite will be embedded into brown forest earth under the road, and must visibly belong inside the ground. Its entire width represents about 1.5 metres.
Subject: a little stream emerges from a narrow fissure in a muted brown-grey rock recess at the upper left, trickles down one low irregular rock step into a shallow turquoise pool on the horizontal floor, then visibly flows out through a narrow channel at the lower right. Only a few discreet moss patches and one or two small fern fronds. A thin uneven earthy-rock ceiling and side edges explain the hollow. The water source and outlet should both be clear, no water magically appearing from a rock.
Style: beautiful softly painted premium game illustration, natural and simple, gentle hand-painted details, muted earthy umber edges, moss green, a restrained turquoise-water accent that matches a tropical jungle waterfall landscape. Not plastic 3D, not architectural fountain.
Composition: straight-on side-view elevation, open-front shallow underground niche. Do not look down from above, no isometric view. No rounded decorative basin, flowers, floating pedestal or freestanding miniature fountain. Minimal irregular thin supporting rocks, not a massive stone frame. The entire sprite has generous transparent margins.
Background and edges: genuine fully TRANSPARENT alpha outside the natural cutaway. Exterior earth edges taper softly and directly to transparency without colored fog or background blur. Interior of recess is warm muted rock. No rectangular background, black backdrop, painted checkerboard, graphic frame or border.
Output: one PNG at least 1024 pixels, actual alpha channel, no text, labels, watermark, animals, horizon or extra landscape.
```
