# Mine — correction des objets sous la route

Trois nouvelles illustrations générées avec le mode intégré `image_gen`, copiées intactes vers les emplacements de jeu autorisés. Aucune modification du code partagé ni des autres mondes.

## Références et intention

Fond `App/Resources/GameAssets/abandoned-mine.png` et rendu `artifacts/scenery-review/mine-ground-1.png` inspectés lors du travail textures ; les trois anciennes images ont été inspectées depuis `artifacts/scenery-corrections/before/Scenery/mine/`.
Les originaux représentaient un wagonnet sans rails, une taupe sur une motte et une géode comme objet posé. Les nouvelles versions sont des ouvertures vues de face dans le sous-sol.

## Objets et proportions inspectées

- `ground-1` : petit wagonnet en bois, minerai gris, roues posées sur un rail horizontal court, dans une galerie de roche brune. Vue latérale frontale, sans socle flottant. À une largeur totale prévue de 2,65 m, le wagon occupe visuellement environ 39 % de la largeur visible (donc environ 1,03 m). Le bord rocheux existe pour contextualiser l'ouverture et reste à vérifier fondu dans la texture native.
- `ground-2` : petite taupe dans une poche de terre, tête et pattes visibles au bord du terrier. L'animal occupe environ 27 % de la largeur solide de la vignette. À 0,60 m de largeur totale, il représente environ 0,16 m ; le halo de terre semi-transparent peut influer sur le recadrage natif, à vérifier lors de l'intégration. C'est une petite présence, plus une taupe géante.
- `ground-3` : cristaux turquoise/violets enracinés dans les parois d'une cavité rocheuse brune, vue de face. À 1,55 m de largeur totale, l'ouverture représente environ 1,0 m. Les cristaux sont de taille secondaire dans la cavité. Aucun socle posé ou angle isométrique.

Les dimensions sont des recommandations d'intégration et des estimations visuelles de proportion interne, pas un résultat déjà mesuré dans le jeu.

## Vérification des fichiers

Les trois sorties retenues sont des PNG avec vrai canal alpha. Vérification ImageIO/CoreGraphics par le contrôle dérivé de `scripts/check-scenery-assets.swift` : décodage réussi, plus de 5 % des pixels échantillonnés réellement transparents et plus de 2 % solides. Rapport : `artifacts/scenery-corrections/mine-alpha.json`.
Copies intactes vérifiées avec `cmp`. Aucun traitement d'image externe effectué.

## Prompts exacts et provenance retenue

### ground-1.png

Destination : `App/Resources/GameAssets/Scenery/mine/ground-1.png`

Source intégrée : `/Users/daviddemri/.codex/generated_images/01a0993e-7e29-72a1-9882-be0743bae025/exec-90e6a9b1-750c-4f53-bf75-64fe9dbba39c.png`

```text
An isolated transparent-background PNG sprite for a beautiful painted 2D game. A small wooden ore mine cart resting on a short horizontal rail, inside a COMPACT dark opening in brown slate rock. Strict front-on side elevation, wheels touch the rail. The cart fills HALF the total width of the rocky opening. Only a thin natural irregular rim of dark brown rock around the opening, fading naturally at the outside edges into transparency. Whole vignette 2.65 metres wide, cart 1.2 metres wide. Beautiful detailed digital painting with soft restrained shading, warm umber rock and wood, dark grey ore, small subtle ochre mineral accents. Simple charming composition, highly polished but quiet. No other props. No isometric view, no scene, no text, no floating pedestal, no border. Genuine transparent background.
```

### ground-2.png

Destination : `App/Resources/GameAssets/Scenery/mine/ground-2.png`

Source intégrée : `/Users/daviddemri/.codex/generated_images/01a0993e-7e29-72a1-9882-be0743bae025/exec-73eba7da-15a0-4f1f-bc12-33495eb38f40.png`

```text
An isolated transparent-background PNG sprite for a beautiful hand-painted 2D game. A tiny friendly brown mole peeking out inside a small cosy soil burrow, shown in FRONT-ON SIDE ELEVATION as an underground cross section. The little animal is small: about 20 cm long inside a 60 cm wide irregular pocket of dark brown earth, occupying about one THIRD of the total width. Show its soft grey-brown head and little pink digging paws resting on the earthy floor of the burrow. A shallow dark recess behind it and a very thin irregular rim of compact soil give it a real sheltered place. The outer earth edges dissolve organically into true transparency, with no thick frame, no raised mound, no floating plinth. Refined detailed painted illustration, soft fur, natural gentle expression, tiny eye, muted warm brown earth with subtle dark slate pebbles, soft restrained lighting. Charming, simple, quiet and readable at small game size. Strict 2D cutaway, no isometric angle or overhead view. Only the animal and minimal burrow context, no scenery, no grass or extra props, no text. Genuine transparent background around the irregular silhouette, finished PNG at least 1024 pixels wide.
```

### ground-3.png

Destination : `App/Resources/GameAssets/Scenery/mine/ground-3.png`

Source intégrée : `/Users/daviddemri/.codex/generated_images/01a0993e-7e29-72a1-9882-be0743bae025/exec-05c75e93-0d6a-4fbf-b601-33456a813396.png`

```text
An isolated transparent-background PNG sprite for a beautiful hand-painted 2D abandoned-mine game. A small natural geode cavity ENCASED IN dark brown-slate bedrock, revealed in a strict FRONT-ON geological cross-section. Quiet turquoise and muted violet crystals grow inward from the cavity walls, physically rooted in the surrounding rock, not a crystal cluster placed on a base. Whole irregular vignette about 1.55 metres wide, mineral cavity around 0.85 metre wide; keep crystals few, simple and medium-small. A modest thin jagged rim of dark warm slate-brown rock integrates the opening into an existing underground rock texture, fading softly into transparency along irregular outside edges. Elegant polished digital painting with natural mineral textures, softened crystal facets, restrained glints, soft warm ochre hints in the rock, subdued colors that complement a dark mine. Flat front view suitable for side-view game terrain. No isometric view, no visible top face, no freestanding boulder, no floating plinth or pedestal, no thick heavy stone border, no round specimen on display, no scene, no text, no props, no neon glow. Genuine transparent background around the irregular silhouette. Finished high-quality PNG at least 1024 pixels wide.
```

## Itérations du wagonnet écartées

La première version avait une galerie trop large, réduisant le wagon à environ un quart de la vignette. Deux essais d'édition ont produit un damier opaque et ont été écartés. Une nouvelle génération a donné le PNG final avec alpha réel. Les variantes rejetées ne remplacent aucun fichier du jeu.

Source écartée : `exec-43c32486-5839-4682-998c-d221daefa5bb.png`

```text
Use case: stylized-concept. Create a polished transparent PNG scenery sprite for a beautiful hand-painted 2D side-view motorcycle game in an abandoned mine. Primary subject: one small aged wooden mine cart filled modestly with dark ore, resting visibly on a short HORIZONTAL rail inside a shallow dark gallery opening cut into brown-slate bedrock. Critical view: strict FRONT-ON SIDE ELEVATION like a 2D underground cross section; cart seen in side profile with its two visible wheels firmly meeting the horizontal rail. No isometric angle, no view from above. The entire irregular vignette represents 2.65 metres width; the small cart is about 1.2 metres wide and occupies under half the total vignette width. Show the supporting horizontal rail and the dark recess behind it. Only a modest thin irregular rim of earthy brown-slate rock surrounds the gallery opening; the rim dissolves into a TRUE transparent outer background at uneven organic edges. Keep surrounding rock narrow and unobtrusive; it should integrate into an existing earth texture, not look like a freestanding boulder or framed tunnel portal. One charming quiet environmental detail, minimal composition, warm muted umber and charcoal, subtle ochre highlights, delicately painted material detail, soft tasteful shading, readable small silhouette. No lamp, no plant, no separate props. No floating diorama, no pedestal or plinth, no thick stone frame, no ornate archway, no deep tunnel perspective, no full landscape, no rectangle, no scenery backdrop, no floor extending outside the opening, no text, no watermark. Output a complete isolated raster sprite with REAL alpha transparency outside its irregular silhouette, no black/white/colored rectangle and no simulated transparency checkerboard. Image at least 1024 pixels wide.
```

Source écartée : `exec-5a11c9cc-1ee1-4425-8200-d0de3fa7a78d.png`

```text
Edit this transparent game sprite. Preserve the beautiful front-on 2D cross-section view, cart design, dark ore, brown-slate rock material, horizontal rail with wheels resting on it, thin organic irregular rock rim, and genuine transparent background. Make the gallery much more compact around the cart: shorten it strongly on both sides until the cart occupies about 45 to 50 percent of the total visible vignette width. Keep some dark recess above and beside the cart so its context remains clear. The whole small cutaway should be about 2.65 metres wide with a 1.2-metre cart. Do not enlarge the cart vertically relative to its existing proportions. Do not add any other object. No isometric perspective, massive frame, pedestal, scenery, rectangular background, text, or checkerboard. Return the isolated sprite with real alpha transparency.
```

Source écartée : `exec-cb679b26-7480-470b-8508-807d478b9409.png`

```text
Remove the entire grey and white checkerboard outside the irregular rocky silhouette. It is an unwanted opaque printed background. Return the identical mine-cart gallery illustration as a genuinely TRANSPARENT PNG cutout with actual alpha zero outside the silhouette. Preserve cart, rail, rocks, shapes, proportions, colors, detail and composition exactly. Do not draw a checkerboard, a solid background, or a replacement background. Background extraction only; the output must have a real alpha channel.
```
