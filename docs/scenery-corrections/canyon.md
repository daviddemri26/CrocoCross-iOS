# Canyon — correction des objets sous la route

Les trois PNG sont générés avec le built-in `image_gen`, inspectés visuellement puis copiés intacts. Les originaux de la passe précédente sont sauvegardés par l'agent principal sous `artifacts/scenery-corrections/before/Scenery/canyon`. Aucune texture terrain ni aucun code modifié par cet agent.

## Objets finaux et dimensions conseillées

- `ground-1.png` : ammonite partiellement enchâssée dans une coupe frontale de grès ocre. Vignette totale recommandée : **1,5 m de large**, plafond de hauteur **1,1 m**, ratio conservé. Un pan de roche recouvre le côté droit du fossile ; bordure irrégulière à alpha doux. Source 1536 × 1024.
- `ground-2.png` : fennec endormi dans un terrier sableux horizontal, avec plafond bas et poche sombre qui donnent un vrai contexte souterrain. Vignette totale recommandée : **1,1 m de large**, plafond de hauteur **0,55 m**, ratio conservé. Le corps de l'animal occupe environ 55–60 % de la largeur : environ **0,6 m**. Garder la vignette horizontale sans rotation selon la pente. Source 1697 × 927.
- `ground-3.png` : poche d'améthyste enchâssée dans une coupe de grès, recouverte en bas et à droite par la roche hôte. Vignette totale recommandée : **1,4 m de large**, plafond de hauteur **1,2 m**, ratio conservé. Source 1374 × 1145.

Ces dimensions désignent les bornes visibles de toute la vignette après retrait des marges transparentes. L'agent principal doit vérifier le résultat après réglage de l'échelle. Les petites pierres de bordure doivent se confondre avec le terrain, sans rotation du terrier.

## ground-1 : prompt exact et source

Référence inspectée : `App/Resources/GameAssets/Scenery/canyon/ground-1.png` avant remplacement.

Source générée : `/Users/daviddemri/.codex/generated_images/01a0993b-1f45-7ed1-a769-716a54c5226d/exec-4d496671-0dc9-4783-bdf5-70f054f26689.png`

Use case: precise-object-edit. Create the corrected replacement for this ammonite game sprite. Preserve the beautiful warm hand-painted illustrative style, ochre sandstone and cream spiral fossil of the reference, but change its spatial construction: a FRONT ELEVATION flat side-view geological cutaway showing a small ammonite fossil PARTLY EMBEDDED inside a vertical face of compact canyon sandstone. This is for BELOW the road in a 2D side-scrolling game, not an object sitting on the surface. Half of the ammonite's outer shell is naturally occluded by warm dusty terracotta sandstone so it unmistakably belongs inside the earth. Spiral beautifully readable, material refined and softly painted, restrained detail. Just a small shallow irregular patch of host sandstone around it, about 1.5 metres wide in game total, fossil about 0.7 metres; not a large rock block. Outer edge thins irregularly into genuine RGBA transparency with tiny soft alpha transitions to blend into an existing ochre terrain; no coloured glow around the silhouette. Front-on flat composition, no visible lower pedestal or top-facing platform, no isometric angle, no freestanding specimen, no detached rock, no black cavity ring, no thick border. Transparent canvas with comfortable empty margins on all sides. No backdrop scene, sky, landscape, text, logo, frame, rectangle or painted checkerboard. Output one PNG with genuine transparent background, 1024 pixels minimum.

## ground-2 : prompt exact retenu et source

La référence animale initiale et le backdrop ont été inspectés. Deux premières sorties ont été rejetées : elles peignaient un faux damier opaque. Le dernier appel a produit une vraie découpe avec alpha, sans référence attachée afin de ne pas reproduire ce faux fond.

Source retenue : `/Users/daviddemri/.codex/generated_images/01a0993b-1f45-7ed1-a769-716a54c5226d/exec-09cef46d-b0dc-44d9-8ed2-1b11ba37b396.png`

Create a PNG game sprite with a TRANSPARENT BACKGROUND. One small adorable sleeping fennec curled up inside a shallow sandy underground burrow, viewed straight on in side elevation. Refined hand-painted illustration in soft cream, golden fur and warm ochre sandstone. The dark burrow pocket behind the animal and thin sandstone ceiling above it make the animal clearly sheltered underground. It rests on a slim horizontal sandy floor. Tiny irregular earth edges fade into transparent empty space, no heavy ring or pedestal. Calm, simple, beautiful and readable at small scale in a side-scrolling canyon motorcycle game. Entire vignette roughly 1.1 metres wide at game scale with a 0.6 metre curled animal. All exterior background is transparent, no visible canvas background or checkerboard pattern. No scenery, text, logo, frame, sky, isometric angle or external shadow. 1024 pixels minimum.

## ground-3 : prompt exact et source

Référence inspectée : `App/Resources/GameAssets/Scenery/canyon/ground-3.png` avant remplacement.

Source générée : `/Users/daviddemri/.codex/generated_images/01a0993b-1f45-7ed1-a769-716a54c5226d/exec-f2a58518-5c60-47cd-9add-928eb879a0a8.png`

Create a corrected replacement PNG game sprite with a TRANSPARENT BACKGROUND. Reference image supplies the refined hand-painted illustration style, lavender amethyst crystals and warm ochre stone palette. Change the freestanding geode into an underground geological cutaway: a small irregular amethyst pocket PARTLY EMBEDDED in the vertical face of compact orange-ochre canyon sandstone, seen straight on in side elevation. The surrounding host sandstone occludes part of the lower and right sides, so it clearly belongs inside the earth. A few beautiful softly lit purple crystal facets remain readable in the shallow pocket. Restrained detail, gentle colours, simple and lovely. Total vignette about 1.4 metres wide in game. Only a very thin irregular host-rock margin, tapering and fading into transparent space at the exterior. No freestanding rock chunk, floating pedestal, top-down or isometric view, massive rock ring, black outlined frame, external shadow or coloured glow. No scene, landscape, sky, text, logo, card or rectangle. Genuine transparent empty margins on all sides. 1024 pixels minimum.

## Contrôle

Trois sorties relues visuellement, puis test natif ImageIO/CoreGraphics de la transparence. Rapport : `artifacts/scenery-corrections/canyon/alpha-check.json`. Les trois fichiers contiennent une vraie transparence et une zone solide. La lecture en contexte final et l'échelle font l'objet de la QA native de l'agent principal.
