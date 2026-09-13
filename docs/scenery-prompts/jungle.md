# Jungle scenery images

Generated with the built-in `image_gen.imagegen` tool, one independent call per asset. The existing `App/Resources/GameAssets/tropical-jungle.png` was visually inspected as the style reference. Original generated PNGs were copied intact; no pixel editing or resizing was applied.

## Integration

- `ground-1.png`: sleeping tapir on compact moss island.
- `ground-2.png`: green tree frog on leaf and mossy rock.
- `ground-3.png`: short waterfall in flowered tropical rocks.
- `sky-1.png`: scarlet macaw, facing right.
- `sky-2.png`: blue morpho butterfly, dorsal three-quarter view, head pointing up and right; gentle rightward drift fits.
- `wayside.png`: low fern and bromeliad tuft, no pole. Visible base ends at y≈947/1254; account for its transparent bottom margin when grounding against the road.

## Quality inspection

All six files were opened visually. Subjects are complete, isolated and detailed, with natural silhouettes and no rectangular scene, text or checkerboard. The macaw has two visible wings and a full tail. The butterfly has both wings. The wayside plant is low and wide. The native alpha was inspected read-only with Pillow: all files are RGBA 1254×1254, alpha range 0–255. Very faint antialias remnants expand the unthresholded bounds; the alpha>16 bounds below describe the visible artwork. In-game scale and placement remain the integrating agent's responsibility.

## ground-1

Project asset: `App/Resources/GameAssets/Scenery/jungle/ground-1.png`

Original source: `/Users/daviddemri/.codex/generated_images/01a0990b-0bd4-7f51-92ae-afaef7327f2e/exec-36ee4dfc-0c34-4c7c-80aa-3f0d465f4d51.png`

SHA-256: `36229fbc38d35cfde0256a000dc45cdffa04d4ba069e655bd1cd8a27a0cd0386`

Fully transparent pixels: 46.62%. Visible alpha > 16 bounds: [7, 191, 1247, 1095].

Exact generation prompt:

```text
Use case: illustration-story. Asset type: one production PNG sprite for a premium hand-painted side-scrolling motorcycle landscape game. Style: detailed soft natural digital painting, rich emerald and lime foliage, warm tropical sunshine, softly painted realistic volumes, expressive natural charm. Matches a beautiful painted tropical jungle with waterfalls, mountains and turquoise water. Strong simple silhouette readable at 60–110 screen pixels. Not vector, not geometric primitives, not stick figure art, not plastic 3D. Composition: exactly one complete isolated subject, centered, filling approximately 85% of the square canvas, with comfortable margins and no clipping. Background: genuinely transparent alpha PNG, every area outside the subject transparent. Absolutely no background scene, no sky backdrop, no rectangular ground tile, no white or color backdrop, no fake checkerboard, no halo/glow, no shadow cast outside the subject. No text, no border, no labels. Primary request: an adorable small dark brown tapir sleeping peacefully curled slightly on a compact organic mossy jungle island, with tiny fern fronds at the base. Side three-quarter view. Its gentle face, rounded ears and short flexible snout are clearly visible. The moss base is naturally irregular and compact, entirely isolated. The tapir is the hero, realistic sweet proportions.
```

## ground-2

Project asset: `App/Resources/GameAssets/Scenery/jungle/ground-2.png`

Original source: `/Users/daviddemri/.codex/generated_images/01a0990b-0bd4-7f51-92ae-afaef7327f2e/exec-b053d3e7-e561-42f0-b56b-0fde86ae9b28.png`

SHA-256: `9596ae054250e3c98b154ffb04ee26f73dc262a0f618efcd28c65d4529a9cbec`

Fully transparent pixels: 44.51%. Visible alpha > 16 bounds: [59, 85, 1209, 1189].

Exact generation prompt:

```text
Use case: illustration-story. Asset type: one production PNG sprite for a premium hand-painted side-scrolling motorcycle landscape game. Style: detailed soft natural digital painting, rich emerald and lime foliage, warm tropical sunshine, softly painted realistic volumes, expressive natural charm. Matches a beautiful painted tropical jungle with waterfalls, mountains and turquoise water. Strong simple silhouette readable at 60–110 screen pixels. Not vector, not geometric primitives, not stick figure art, not plastic 3D. Composition: exactly one complete isolated subject, centered, filling approximately 85% of the square canvas, with comfortable margins and no clipping. Background: genuinely transparent alpha PNG, every area outside the subject transparent. Absolutely no background scene, no sky backdrop, no rectangular ground tile, no white or color backdrop, no fake checkerboard, no halo/glow, no shadow cast outside the subject. No text, no border, no labels. Primary request: a beautiful small exotic bright green tree frog with orange toes resting comfortably on a broad curled tropical leaf which rests over one little grey mossy rock. Three-quarter side view, complete frog and leaf and rock. A simple jewel-like jungle vignette, playful natural expression, detailed hand-painted skin and leaf veins without excessive tiny decoration.
```

## ground-3

Project asset: `App/Resources/GameAssets/Scenery/jungle/ground-3.png`

Original source: `/Users/daviddemri/.codex/generated_images/01a0990b-0bd4-7f51-92ae-afaef7327f2e/exec-a4671f45-db00-44cd-910b-900163263232.png`

SHA-256: `68538de991e00773140d4232eade8dc7466bb3853fed024fba71368f0e8689ab`

Fully transparent pixels: 31.86%. Visible alpha > 16 bounds: [28, 13, 1228, 1232].

Exact generation prompt:

```text
Use case: illustration-story. Asset type: one production PNG sprite for a premium hand-painted side-scrolling motorcycle landscape game. Style: detailed soft natural digital painting, rich emerald and lime foliage, warm tropical sunshine, softly painted realistic volumes, expressive natural charm. Matches a beautiful painted tropical jungle with waterfalls, mountains and turquoise water. Strong simple silhouette readable at 60–110 screen pixels. Not vector, not geometric primitives, not stick figure art, not plastic 3D. Composition: exactly one complete isolated subject, centered, filling approximately 85% of the square canvas, with comfortable margins and no clipping. Background: genuinely transparent alpha PNG, every area outside the subject transparent. Absolutely no background scene, no sky backdrop, no rectangular ground tile, no white or color backdrop, no fake checkerboard, no halo/glow, no shadow cast outside the subject. No text, no border, no labels. Primary request: a tiny lovely natural waterfall between a few compact mossy tropical rocks with a few pink and orange jungle flowers at the sides. The cascade flows only a short distance into a small turquoise rock basin. A self-contained complete organic nature vignette with a strong compact silhouette and naturally irregular rocky base. No surrounding landscape or background, just the little waterfall and its rocks and flowers.
```

## sky-1

Project asset: `App/Resources/GameAssets/Scenery/jungle/sky-1.png`

Original source: `/Users/daviddemri/.codex/generated_images/01a0990b-0bd4-7f51-92ae-afaef7327f2e/exec-152b5a8d-d01f-48ed-88b8-77b2e959f908.png`

SHA-256: `eb45a92acaccc50df8b7b2bb62c414bf06aeb6f4d35553127510f871d9a3b1dd`

Fully transparent pixels: 62.72%. Visible alpha > 16 bounds: [23, 10, 1236, 1229].

Exact generation prompt:

```text
Use case: illustration-story. Asset type: one production PNG sprite for a premium hand-painted side-scrolling motorcycle landscape game. Style: detailed soft natural digital painting, rich emerald and lime foliage, warm tropical sunshine, softly painted realistic volumes, expressive natural charm. Matches a beautiful painted tropical jungle with waterfalls, mountains and turquoise water. Strong simple silhouette readable at 60–110 screen pixels. Not vector, not geometric primitives, not stick figure art, not plastic 3D. Composition: exactly one complete isolated subject, centered, filling approximately 85% of the square canvas, with comfortable margins and no clipping. Background: genuinely transparent alpha PNG, every area outside the subject transparent. Absolutely no background scene, no sky backdrop, no rectangular ground tile, no white or color backdrop, no fake checkerboard, no halo/glow, no shadow cast outside the subject. No text, no border, no labels. Primary request: a magnificent scarlet macaw in graceful flight towards the right, bright red body, blue and yellow wings fully visible, elegant long tail, natural anatomy. Three-quarter side view with both wings clearly distinguishable and no cropping. Beautiful softly painted feathers, compact readable flying silhouette. Bird alone, no branch and no ground.
```

## sky-2

Project asset: `App/Resources/GameAssets/Scenery/jungle/sky-2.png`

Original source: `/Users/daviddemri/.codex/generated_images/01a0990b-0bd4-7f51-92ae-afaef7327f2e/exec-6e529b70-61b1-4d2e-ba6e-ffaac290a9c6.png`

SHA-256: `f9ae366bdb1e696d7a9cb553dd0b9398df916197bff1fabf0f9aefedac039ae7`

Fully transparent pixels: 54.23%. Visible alpha > 16 bounds: [76, 23, 1226, 1231].

Exact generation prompt:

```text
Use case: illustration-story. Asset type: one production PNG sprite for a premium hand-painted side-scrolling motorcycle landscape game. Style: detailed soft natural digital painting, rich emerald and lime foliage, warm tropical sunshine, softly painted realistic volumes, expressive natural charm. Matches a beautiful painted tropical jungle with waterfalls, mountains and turquoise water. Strong simple silhouette readable at 60–110 screen pixels. Not vector, not geometric primitives, not stick figure art, not plastic 3D. Composition: exactly one complete isolated subject, centered, filling approximately 85% of the square canvas, with comfortable margins and no clipping. Background: genuinely transparent alpha PNG, every area outside the subject transparent. Absolutely no background scene, no sky backdrop, no rectangular ground tile, no white or color backdrop, no fake checkerboard, no halo/glow, no shadow cast outside the subject. No text, no border, no labels. Primary request: one gorgeous blue morpho butterfly in gentle flight, three-quarter view, both brilliant sapphire blue wings open and clearly visible, delicate dark wing edges, tiny slim natural body and two antennae. A single charming natural butterfly, readable silhouette, refined painterly wing texture. Butterfly alone with absolutely no ground, branch or floral objects.
```

## wayside

Project asset: `App/Resources/GameAssets/Scenery/jungle/wayside.png`

Original source: `/Users/daviddemri/.codex/generated_images/01a0990b-0bd4-7f51-92ae-afaef7327f2e/exec-1fafcc82-fce4-411b-87ed-c1a8a7253101.png`

SHA-256: `67caef025fdd37dfdcdca53696048e14ba9cf47a3a1470b9ba4e07e55c55e0fd`

Fully transparent pixels: 63.8%. Visible alpha > 16 bounds: [21, 324, 1244, 947].

Exact generation prompt:

```text
Use case: illustration-story. Asset type: one production PNG sprite for a premium hand-painted side-scrolling motorcycle landscape game. Style: detailed soft natural digital painting, rich emerald and lime foliage, warm tropical sunshine, softly painted realistic volumes, expressive natural charm. Matches a beautiful painted tropical jungle with waterfalls, mountains and turquoise water. Strong simple silhouette readable at 60–110 screen pixels. Not vector, not geometric primitives, not stick figure art, not plastic 3D. Composition: exactly one complete isolated subject, centered, filling approximately 85% of the square canvas, with comfortable margins and no clipping. Background: genuinely transparent alpha PNG, every area outside the subject transparent. Absolutely no background scene, no sky backdrop, no rectangular ground tile, no white or color backdrop, no fake checkerboard, no halo/glow, no shadow cast outside the subject. No text, no border, no labels. Primary request: one low compact tuft of lush tropical ferns with a small coral red and pink flowering bromeliad nestled at its center, designed to sit right against a road edge. Strong low and wide silhouette, short organic moss-and-soil base with a natural flat grounded bottom, full plant visible. The foliage stays compact and low, no tall stalks, no poles, no signs, no long grass spikes. Hand-painted lush leaves and warm flower color.
```
