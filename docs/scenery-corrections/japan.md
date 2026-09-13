# Corrections des objets — Japon

Génération et édition via le built-in `image_gen`, sorties copiées intactes. Références visuelles inspectées : `App/Resources/GameAssets/japan-mountains.png` et les trois anciens `Scenery/japan/ground-{1,2,3}.png`. Originaux préservés dans `artifacts/scenery-corrections/before/Scenery/japan/`.

## Objets retenus et échelle visée

- `ground-1.png` : petit pot ancien japonais bleu/crème, partiellement enfoui dans une poche de terre brune et racines fines ; remplace le bassin koi dont la vue de dessus était incompatible avec la coupe souterraine. Vignette complète visée : 0,85 m de large, pot environ 0,40 m. PNG 1254 × 1254.
- `ground-2.png` : petit renard roux endormi dans un terrier frontal, sol horizontal et alcôve sombre ; remplace le renard sur socle mousseux flottant. Vignette complète visée : 1,20 m, renard recroquevillé environ 0,55 m. PNG 1254 × 1254.
- `ground-3.png` : petit recoin horizontal abrité avec pierre moussue, trois champignons minuscules et fougère, vu de face ; remplace le grand diorama rocheux. Vignette complète visée : 1 m. PNG 1774 × 887. La première proposition trop massive a été simplifiée avec un quatrième appel ciblé ; seule la version finale est intégrée.

Ces dimensions sont des cibles de composition pour le réglage du moteur par l'agent principal, pas une modification du code ici. Les images ont été inspectées : projection frontale, support lisible, contours irréguliers en terre brune, transparence réelle. Copies vérifiées identiques par SHA-256. Contrôle ImageIO des trois fichiers et fraction transparente : `artifacts/scenery-corrections/japan-alpha.json`. Aucun changement aux textures, au ciel, à la lanterne ou au code partagé.

## ground-1 — Pot japonais ancien partiellement enfoui

Source : `/Users/daviddemri/.codex/generated_images/01a0993b-58f0-7e90-bb88-57169bfaf250/exec-7fcf1174-82ab-4968-970b-b3b82b85d7bb.png`

Prompt exact :

```text
Use case: stylized-concept. Asset type: single transparent PNG game sprite, high quality 1024x1024 or larger. Create a small antique Japanese blue-and-cream ceramic storage pot partly embedded in a little irregular patch of brown forest soil, shown straight-on from the SIDE at eye level as if exposed in the vertical cutaway wall beneath a 2D game road. Simple graceful squat ceramic pot, slightly timeworn cream glaze, one subtle indigo botanical brush motif, small short neck and small flat rim, no readable writing. The lower quarter of the pot is visibly concealed by brown earth. A few delicate thin roots weave around the side in a small shaded earth pocket. Pot is the only focal object, approximately 40 cm across within an approximately 85 cm wide vignette. Restrained beautiful illustrated painterly craftsmanship compatible with a serene Japanese mountain forest game, warm umber earth and muted sage touches, cool indigo accent. Actual transparent background outside the irregular softly feathered soil edges, generous clear transparent margin. Earth boundary is thin and organic, fading into true alpha, no chunky platform, no stone ring, no thick cave frame. The tiny soil shelf is horizontal, camera perpendicular to a vertical cutaway, not seen from above. Clear readable small-scale silhouette, lovely but simple. No isometric view, no pedestal, no floating island, no outdoor scene, no horizon, sky, landscape, rectangle, border, frame, solid background, checkerboard drawn into image, cast shadow outside the vignette, text, watermark or logos.
```

## ground-2 — Petit renard endormi dans un terrier forestier

Source : `/Users/daviddemri/.codex/generated_images/01a0993b-58f0-7e90-bb88-57169bfaf250/exec-fbb1dafb-24d5-40af-9721-e90727af3d78.png`

Prompt exact :

```text
Use case: stylized-concept. Asset type: single transparent PNG game sprite, high quality square 1024x1024 or larger. Create one small curled sleeping red fox comfortably inside a modest woodland burrow, seen straight-on from the SIDE at eye level in the vertical cutaway wall beneath a 2D game road. The complete vignette represents only about 1.2 metres in width, the curled fox about 55 centimetres wide: a discreet small animal occupying less than half the overall vignette width. Fox with closed eyes, russet fur, cream cheek and tail tip, black ear tips, relaxed natural sleeping pose. Show a truly horizontal little floor of soft brown earth under its body and a small dark warm brown alcove behind and above, with a few fine roots forming a natural shelter. The animal rests within the cavity, never on an exposed floating moss platform. Earth transition around the opening is narrow, soft, irregular, brown-grey umber matching forest soil; perimeter fades gently into actual transparency. Premium delicate painterly illustration, warm and lovely, readable at small scale, restrained details, natural realistic proportions with slight storybook warmth. No large roots, heavy cave arch, stone frame, giant rocks, foliage frame, complicated background. Isolated asset with transparent space around all sides. Camera perpendicular to the vertical cross-section, no top view, no isometric diorama, no perspective pedestal, no floating island, no outside landscape, sky, rectangular background, solid black background outside the cavity, checkerboard painted in the image, writing, logos or watermark.
```

## ground-3 — Petite niche avec champignons minuscules et fougère (première génération écartée)

Source : `/Users/daviddemri/.codex/generated_images/01a0993b-58f0-7e90-bb88-57169bfaf250/exec-4965f98b-589c-4862-9302-b6c1bf910512.png`

Prompt exact :

```text
Use case: stylized-concept. Asset type: one transparent PNG side-view game sprite, high quality square 1024x1024 or larger. Create a small sheltered recess in a brown earth and stone wall beneath a Japanese mountain forest road, viewed perfectly straight-on from the SIDE at eye level. A modest asymmetrical dark earth niche with a short horizontal earthen ledge, one low mossy grey rock, three TINY tan mushrooms growing from the ledge, and one delicate small fern sprig. Overall vignette represents about 1 metre wide; mushrooms only about 4 to 7 centimetres tall and the fern about 20 centimetres. Keep subjects genuinely small within the recess, a quiet discovery in the underground cutaway. Beautiful restrained painterly illustration compatible with lush but serene blue Japanese mountain scenery, umber-brown soft forest soil, muted grey stone, subtle moss greens, warm cream mushroom accents. Only a narrow soft irregular earth transition around the shaded opening, gradually fading to genuine alpha transparency, generous transparent margin all around. Simple small-scale readable composition, visually believable horizontal support, frontal vertical cutaway projection. No giant mushrooms, roots, thick stone ring, heavy framing arch, exposed floating pedestal, outside scenery, isometric diorama, top-down perspective, sky, horizon, landscape, rectangular frame or backdrop, artificial shadow outside the vignette, solid background, checkerboard painted into the image, text, logos or watermark.
```

## ground-3 — Simplification finale de la niche

Source : `/Users/daviddemri/.codex/generated_images/01a0993b-58f0-7e90-bb88-57169bfaf250/exec-2f62f7c6-9e20-4115-a98d-d9fdf05c6de5.png`

Image de référence d'édition : sortie de la troisième génération ci-dessus.

Prompt exact :

```text
Edit this transparent game sprite. Keep the frontal eye-level side-view projection, tiny tan mushrooms, the little fern, quiet grey mossy stone and brown forest palette. Simplify the vignette substantially: remove the tall ceiling and massive rocky arch completely, shrink the surrounding wall and empty dark space to make a small low shallow recess, only a short overhang at upper left. The final irregular vignette must be low and wide, about twice as wide as tall. Show a small horizontal earthen ledge with one modest mossy rock, three very small mushrooms and one small fern, backed by a low shaded earth hollow rather than a cave. Thin irregular softly feathered brown soil edges blend into genuine alpha transparency, no heavy outline, thick frame, large roots or stones. Keep a finely painted natural illustrated finish, simple and lovely at tiny size. No floating raised pedestal, isometric or overhead view, exterior landscape, rectangular background, writing, logos or watermark. The entire surrounding canvas stays truly transparent.
```
