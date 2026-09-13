# Highway — corrections des objets sous la route

Trois générations indépendantes via le outil built-in `image_gen`, copiées intactes. Aucune modification des textures ni du code partagé.

Les originaux sont conservés dans `artifacts/scenery-corrections/before/Scenery/highway/`. Avant génération, inspection visuelle du fond `american-sunset.png` et des trois anciennes images. Palette conservée : terre ocre/tabac, métal patiné, lumière chaude et ombres mauves sobres.

## ground-1 — Enjoliveur rétro partiellement enfoui

Destination : `App/Resources/GameAssets/Scenery/highway/ground-1.png`

Source : `/Users/daviddemri/.codex/generated_images/01a0993b-8ede-7da3-8aa1-87e395c31c93/exec-cff009ae-aaae-4a32-8d09-80ddb05bed98.png`

Prompt exact :

> Use case: illustration-story. Asset type: one transparent PNG sprite for a polished 2D side-view motorbike game set beside an American desert highway at sunset. Create a small vintage automobile hubcap partly buried in a pocket of warm tobacco-brown earth and muted ochre soil, with two delicate roots and a few tiny stones. One round weathered chrome-and-cream hubcap about 45 cm diameter, subtle pale turquoise accent in the concentric rim, simple retro embossed center with NO letters, NO brand, NO emblem or words. We see the hubcap face nearly straight on, gently tilted, its lower half embedded in dirt; it is an archaeological roadside find visible in the cutaway soil below the road. The dirt pocket has a modest shadow directly behind the object, softly irregular feathered earth edges that blend into surrounding game soil, NOT a thick enclosing frame. Beautiful refined hand-painted illustration, softly dimensional painting not a 3D render, restrained detail, warm copper sunset highlights, quiet mauve shadow, charming yet believable. Orthographic frontal side-view cutaway, NOT an isometric diorama, NOT a floating island, NOT a pedestal, NO exterior scene, horizon, sky, road, plants above ground, rectangular backdrop or border. Entire isolated vignette centered with generous clear margins on genuinely transparent alpha background. No colored background, no halo, no glow, no drop shadow outside the earth pocket, no checkerboard painted into pixels, no text, no watermark. Single sprite, square image at least 1024 pixels.

## ground-2 — Coyote endormi dans une alcôve de terre

Destination : `App/Resources/GameAssets/Scenery/highway/ground-2.png`

Source : `/Users/daviddemri/.codex/generated_images/01a0993b-8ede-7da3-8aa1-87e395c31c93/exec-02f934ae-6833-444a-80fe-17a59a9a379b.png`

Prompt exact :

> Use case: illustration-story. Asset type: one transparent PNG sprite for a polished 2D side-view motorbike game set in the American desert at sunset. Create a small natural coyote peacefully sleeping curled up inside a shallow open underground den cut into warm tobacco-brown earth and muted ochre sandstone. The curled coyote is only about 80 cm long within a modest 1.4 metre-wide vignette, normal animal proportions, tawny grey fur and cream muzzle, eyes closed, head resting against tail. This is a frontal orthographic geological cutaway: visible narrow horizontal dirt floor beneath the animal, a gently darkened alcove behind it, and a THIN irregular arch of compacted earth with a couple of delicate roots above it, showing that the animal is comfortably supported in a genuine small burrow. Refined hand-painted illustration, beautiful soft fur but restrained small-scale detail, warm sunset copper accents and subtle mauve shadow. Earth edges softly irregular and taper outward into alpha, with no thick chunky frame. Do NOT make a floating rock pedestal or an isometric diorama; no protruding 3D island, no deep rectangular slab, no landscape, sky, horizon, road, grass growing on a surface above the den, other animals, props, text, letters, watermark, or scenery. Entire isolated vignette centered, generous clear margins, genuinely transparent alpha background outside the earth and coyote. No colored backdrop, no halo or glow, no shadow cast onto a background, no checkerboard painted into pixels. Single sprite, square image at least 1024 pixels.

## ground-3 — Fer à cheval ancien partiellement enfoui

Destination : `App/Resources/GameAssets/Scenery/highway/ground-3.png`

Source : `/Users/daviddemri/.codex/generated_images/01a0993b-8ede-7da3-8aa1-87e395c31c93/exec-bca1d356-b236-418f-a9f0-029f1f1ea51d.png`

Prompt exact :

> Use case: illustration-story. Asset type: one transparent PNG sprite for a polished 2D side-view motorbike game in the rural American desert at sunset. Create one small antique rusty iron horseshoe partly embedded in a modest irregular pocket of warm tobacco-brown soil with a few tiny ochre pebbles. The full vignette is only about 65 cm wide in game, while the horseshoe itself has believable ordinary horse size, around 17 cm wide, taking roughly a third of the vignette width. Clearly recognizable simple U shape with a few square nail holes, worn brown iron with gentle copper edges. It is a charming relic in the cutaway earth below an old rural highway, not a decorative sign. Front-facing orthographic side-view geological cutaway: the horseshoe is tilted slightly in the vertical earth face, lower curved end half-buried by fine soil, softly irregular shallow earth surround tapering outward into transparency. No raised 3D pedestal, no floating island, no isometric diorama, no thick rock frame, no rectangular slab. Refined hand-painted digital illustration, beautiful restrained detail, warm muted ochre and subdued reddish brown with subtle mauve shadows, readable at small size. No landscape, road, horizon, sky, grass, plants, text, inscriptions, logo, watermark, extra horseshoes or other props. Single isolated sprite centered with generous clear margins on genuinely transparent alpha background. No colored backdrop, no glow or halo, no shadow outside the dirt pocket, no checkerboard painted into the pixels. Single square image at least 1024 pixels.

## Inspection et échelle pour intégration

Les trois PNG mesurent 1254 × 1254 pixels avec canal alpha. Lecture AppKit sur un échantillon de pixels tous les quatre pixels : chaque image contient plus de 57 000 pixels transparents et plus de 11 000 pixels opaques, confirmant une véritable transparence. Inspection visuelle des sorties : objet lisible, terre irrégulière et transparence extérieure, absence de texte et de scène extérieure ; les vignettes disposent maintenant de leur support ou de leur contexte enfoui.

- Enjoliveur : remplace la caravane, dont l’échelle et le placement souterrain étaient injustifiés. Le métal représente environ les deux tiers de la largeur visible ; pour un enjoliveur proche de 45 cm, viser une vignette d’environ 65–70 cm.
- Coyote : conserve le sujet et ajoute une alcôve avec sol horizontal. L’animal occupe environ la moitié de la largeur de la vignette ; une vignette de 1,4 m maintient un animal discret, environ 70–80 cm. Le contour rocheux est visible et la vérification native doit confirmer sa fusion avec le terrain.
- Fer à cheval : remplace le pick-up miniature. L’objet occupe visuellement un peu plus de la moitié de la vignette, davantage que demandé dans le prompt. Pour éviter de le surdimensionner, une vignette proche de 40–45 cm donne un fer d’environ 22–25 cm ; 65 cm ferait un fer assez grand. L’échelle finale est gérée dans le renderer par l’intégrateur.

Vérification native de taille, contact et insertion dans le terrain laissée à l’intégrateur. Les images n’ont subi aucun redimensionnement ou traitement après génération.
