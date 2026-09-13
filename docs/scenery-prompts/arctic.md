# Arctic scenery assets

Generated with the built-in image_gen tool. Six independent generation calls, one subject per PNG. Existing scene reference inspected: `App/Resources/GameAssets/arctic-aurora.png`.

## Art direction and placement

Soft natural illustrated arctic details, white fur and snow, icy blues and subdued aurora reflections. Three small ground details below the road; two complete flying birds above it; one low roadside cairn seated directly on the road edge. Intended to appear rarely and at varied positions. All images are original generator PNGs copied without resizing, recoloring, alpha processing, cropping, or other pixel modifications.

## Visual and alpha QA

All six subjects inspected individually at full preview size. Clear compact silhouettes, no text, frame, checkerboard, or plastic 3D style. PNG alpha channels verified with Pillow in read-only mode: each is RGBA and contains substantial fully transparent exterior areas. Some RGB channels retain a background-looking glow at alpha=0, which the raw preview may show; those pixels are fully invisible when composited with alpha. Final integrated scene appearance remains the responsibility of the scene renderer QA.

Both flying subjects face **right**: sky-1 snowy owl, sky-2 Atlantic puffin. The puffin is anatomically a flying puffin, not a penguin. Wayside is a low three-stone cairn, not a pole.

| File | Subject | Dimensions | Fully transparent pixels | Alpha extrema |
| --- | --- | --- | --- | --- |
| ground-1.png | Curled sleeping arctic fox on snow | 1536 × 1024 | 764338 | 0–254 |
| ground-2.png | Baby seal on small ice floe | 1536 × 1024 | 857722 | 0–254 |
| ground-3.png | Glacier-blue ice crystals in snow | 1374 × 1145 | 828479 | 0–255 |
| sky-1.png | Snowy owl flying right | 1536 × 1024 | 931738 | 0–254 |
| sky-2.png | Atlantic puffin flying right | 1536 × 1024 | 986549 | 0–254 |
| wayside.png | Low frosted cairn and grass tuft | 1536 × 1024 | 1002990 | 0–254 |

## Exact generation prompts and sources

### ground-1.png

Source: `/Users/daviddemri/.codex/generated_images/01a0990b-7291-7962-ac00-675af2c7c087/exec-03842f00-99ce-4622-88f0-c22a9414be02.png`

Destination: `App/Resources/GameAssets/Scenery/arctic/ground-1.png`

```text
Use case: illustration-story.
Asset type: single transparent PNG cutout game scenery sprite for CrocoCross, an elegant side-scrolling motorcycle game.
Style/medium: beautiful hand-painted digital illustration, natural detailed brushwork and convincing textures, polished softly whimsical storybook realism. Match a dramatic arctic nighttime environment: deep cobalt blue snowy mountains and vivid turquoise aurora, illuminated white snow and icy cyan edges. Gentle cool blue shadows, soft moonlight with only faint turquoise reflected highlights. Should look like quality illustrated game artwork, not primitive shapes.
Composition: ONE complete subject centered, isolated, fully inside the image, with narrow padding; subject should occupy approximately 85% of canvas in its longest dimension. Readable at 60–110 pixels, appealing simple silhouette, side-view or slight three-quarter side-view to suit landscape scenery.
Background: genuinely transparent RGBA alpha; no opaque background, no floor outside the small specified local base, no gradients, no white backdrop, no checkerboard drawn in the image, no halo or vignette. No floating stray sparkles or particles.
Constraints: no text, no watermark, no border, no frame, no toy/plastic 3D render, no low-poly aesthetic, no vector or stick drawing. Do not create a sprite sheet, only one isolated sprite.
Primary request: A small white arctic fox curled up peacefully asleep, with its thick fluffy tail wrapped around its tucked paws and nose, one triangular ear visible. The fox rests on a very small irregular cushion of powdery blue-shadowed snow. Tender quietly playful detail. Clear compact horizontal silhouette; natural anatomy.
```

### ground-2.png

Source: `/Users/daviddemri/.codex/generated_images/01a0990b-7291-7962-ac00-675af2c7c087/exec-44431331-a169-47b6-b8bf-88d673d5ff78.png`

Destination: `App/Resources/GameAssets/Scenery/arctic/ground-2.png`

```text
Use case: illustration-story.
Asset type: single transparent PNG cutout game scenery sprite for CrocoCross, an elegant side-scrolling motorcycle game.
Style/medium: beautiful hand-painted digital illustration, natural detailed brushwork and convincing textures, polished softly whimsical storybook realism. Match a dramatic arctic nighttime environment: deep cobalt blue snowy mountains and vivid turquoise aurora, illuminated white snow and icy cyan edges. Gentle cool blue shadows, soft moonlight with only faint turquoise reflected highlights. Should look like quality illustrated game artwork, not primitive shapes.
Composition: ONE complete subject centered, isolated, fully inside the image, with narrow padding; subject should occupy approximately 85% of canvas in its longest dimension. Readable at 60–110 pixels, appealing simple silhouette, side-view or slight three-quarter side-view to suit landscape scenery.
Background: genuinely transparent RGBA alpha; no opaque background, no floor outside the small specified local base, no gradients, no white backdrop, no checkerboard drawn in the image, no halo or vignette. No floating stray sparkles or particles.
Constraints: no text, no watermark, no border, no frame, no toy/plastic 3D render, no low-poly aesthetic, no vector or stick drawing. Do not create a sprite sheet, only one isolated sprite.
Primary request: An adorable baby seal resting on a small, low, irregular floe of pale cyan glacial ice with a dusting of snow. Soft silvery white fur, two small flippers and bright dark eyes, head tilted slightly inquisitively toward the viewer. Natural realistic anatomy, tiny whiskers, compact low silhouette, no surrounding water.
```

### ground-3.png

Source: `/Users/daviddemri/.codex/generated_images/01a0990b-7291-7962-ac00-675af2c7c087/exec-c2e47240-db9a-4b3c-a4a0-dfd1620d4541.png`

Destination: `App/Resources/GameAssets/Scenery/arctic/ground-3.png`

```text
Use case: illustration-story.
Asset type: single transparent PNG cutout game scenery sprite for CrocoCross, an elegant side-scrolling motorcycle game.
Style/medium: beautiful hand-painted digital illustration, natural detailed brushwork and convincing textures, polished softly whimsical storybook realism. Match a dramatic arctic nighttime environment: deep cobalt blue snowy mountains and vivid turquoise aurora, illuminated white snow and icy cyan edges. Gentle cool blue shadows, soft moonlight with only faint turquoise reflected highlights. Should look like quality illustrated game artwork, not primitive shapes.
Composition: ONE complete subject centered, isolated, fully inside the image, with narrow padding; subject should occupy approximately 85% of canvas in its longest dimension. Readable at 60–110 pixels, appealing simple silhouette, side-view or slight three-quarter side-view to suit landscape scenery.
Background: genuinely transparent RGBA alpha; no opaque background, no floor outside the small specified local base, no gradients, no white backdrop, no checkerboard drawn in the image, no halo or vignette. No floating stray sparkles or particles.
Constraints: no text, no watermark, no border, no frame, no toy/plastic 3D render, no low-poly aesthetic, no vector or stick drawing. Do not create a sprite sheet, only one isolated sprite.
Primary request: A small tight cluster of three to five natural glacier-blue translucent ice crystals embedded in a low irregular patch of powder snow. Asymmetric pointed crystal shards, largest in middle-left, intricate internal frost and subtle turquoise reflected aurora. Restrained sparkle inside the ice only, no fantasy glowing aura. Compact decorative formation.
```

### sky-1.png

Source: `/Users/daviddemri/.codex/generated_images/01a0990b-7291-7962-ac00-675af2c7c087/exec-d659f6fb-20ee-4ebb-9fc8-fec6c77d4723.png`

Destination: `App/Resources/GameAssets/Scenery/arctic/sky-1.png`

```text
Use case: illustration-story.
Asset type: single transparent PNG cutout game scenery sprite for CrocoCross, an elegant side-scrolling motorcycle game.
Style/medium: beautiful hand-painted digital illustration, natural detailed brushwork and convincing textures, polished softly whimsical storybook realism. Match a dramatic arctic nighttime environment: deep cobalt blue snowy mountains and vivid turquoise aurora, illuminated white snow and icy cyan edges. Gentle cool blue shadows, soft moonlight with only faint turquoise reflected highlights. Should look like quality illustrated game artwork, not primitive shapes.
Composition: ONE complete subject centered, isolated, fully inside the image, with narrow padding; subject should occupy approximately 85% of canvas in its longest dimension. Readable at 60–110 pixels, appealing simple silhouette, side-view or slight three-quarter side-view to suit landscape scenery.
Background: genuinely transparent RGBA alpha; no opaque background, no floor outside the small specified local base, no gradients, no white backdrop, no checkerboard drawn in the image, no halo or vignette. No floating stray sparkles or particles.
Constraints: no text, no watermark, no border, no frame, no toy/plastic 3D render, no low-poly aesthetic, no vector or stick drawing. Do not create a sprite sheet, only one isolated sprite.
Primary request: A snowy owl in graceful flight, wings fully extended with distinct soft white feathers and restrained gray speckles, small round head with amber eyes, head facing to the right. Three-quarter side view showing both wings and complete tail. Beautiful natural bird anatomy. Self-contained horizontal silhouette, no perch, no ground or clouds.
```

### sky-2.png

Source: `/Users/daviddemri/.codex/generated_images/01a0990b-7291-7962-ac00-675af2c7c087/exec-bf3ce2f8-4d2b-4f54-af80-c0f9f94d1d57.png`

Destination: `App/Resources/GameAssets/Scenery/arctic/sky-2.png`

```text
Use case: illustration-story.
Asset type: single transparent PNG cutout game scenery sprite for CrocoCross, an elegant side-scrolling motorcycle game.
Style/medium: beautiful hand-painted digital illustration, natural detailed brushwork and convincing textures, polished softly whimsical storybook realism. Match a dramatic arctic nighttime environment: deep cobalt blue snowy mountains and vivid turquoise aurora, illuminated white snow and icy cyan edges. Gentle cool blue shadows, soft moonlight with only faint turquoise reflected highlights. Should look like quality illustrated game artwork, not primitive shapes.
Composition: ONE complete subject centered, isolated, fully inside the image, with narrow padding; subject should occupy approximately 85% of canvas in its longest dimension. Readable at 60–110 pixels, appealing simple silhouette, side-view or slight three-quarter side-view to suit landscape scenery.
Background: genuinely transparent RGBA alpha; no opaque background, no floor outside the small specified local base, no gradients, no white backdrop, no checkerboard drawn in the image, no halo or vignette. No floating stray sparkles or particles.
Constraints: no text, no watermark, no border, no frame, no toy/plastic 3D render, no low-poly aesthetic, no vector or stick drawing. Do not create a sprite sheet, only one isolated sprite.
Primary request: A small Atlantic puffin flying toward the right, complete wings extended in a gentle downstroke, dark navy-black upper feathers, white belly and cheeks, tiny orange feet tucked back and distinctive orange-yellow beak. Natural puffin anatomy, charming and elegant, not a penguin. Slight three-quarter side view; complete bird only, no ground, no clouds.
```

### wayside.png

Source: `/Users/daviddemri/.codex/generated_images/01a0990b-7291-7962-ac00-675af2c7c087/exec-b1b2af74-ac25-41f8-97c9-705dd77d8025.png`

Destination: `App/Resources/GameAssets/Scenery/arctic/wayside.png`

```text
Use case: illustration-story.
Asset type: single transparent PNG cutout game scenery sprite for CrocoCross, an elegant side-scrolling motorcycle game.
Style/medium: beautiful hand-painted digital illustration, natural detailed brushwork and convincing textures, polished softly whimsical storybook realism. Match a dramatic arctic nighttime environment: deep cobalt blue snowy mountains and vivid turquoise aurora, illuminated white snow and icy cyan edges. Gentle cool blue shadows, soft moonlight with only faint turquoise reflected highlights. Should look like quality illustrated game artwork, not primitive shapes.
Composition: ONE complete subject centered, isolated, fully inside the image, with narrow padding; subject should occupy approximately 85% of canvas in its longest dimension. Readable at 60–110 pixels, appealing simple silhouette, side-view or slight three-quarter side-view to suit landscape scenery.
Background: genuinely transparent RGBA alpha; no opaque background, no floor outside the small specified local base, no gradients, no white backdrop, no checkerboard drawn in the image, no halo or vignette. No floating stray sparkles or particles.
Constraints: no text, no watermark, no border, no frame, no toy/plastic 3D render, no low-poly aesthetic, no vector or stick drawing. Do not create a sprite sheet, only one isolated sprite.
Primary request: A low rounded cairn made of three small smooth dark blue-gray stones loosely stacked, dusted with frost and powder snow, beside one tiny tuft of tawny arctic grass. Organic gently asymmetric mound, firmly resting on a small flat snow patch. Very low compact silhouette, maximum height about its width, plausible beside the edge of a snowy road. No tall post, no sign, no marker pole, no roadway in image.
```
