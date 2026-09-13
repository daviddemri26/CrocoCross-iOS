# San Francisco — textures route et terrain

Créées avec l’outil intégré `image_gen`, deux générations distinctes, sans retouche ni transformation du PNG fourni. Fichiers opaques carrés 1254 × 1254 pixels. Aucun appel API/CLI.

## Références inspectées

- `App/Resources/GameAssets/san-francisco.png` : illustration côtière lumineuse, baie bleue, architecture chaude, végétation sombre et rochers grèges.
- `artifacts/scenery-review/sanfrancisco-ground-1.png` : ancien terrain bleu ardoise avec larges strates courbes ; conserver une séparation route/terrain sobre, remplacer ces lignes par une matière discrète.

## Assets livrés et provenance

- `App/Resources/GameAssets/Terrain/sanfrancisco/road.png` — asphalte gris bleu marin à grain fin. Source intacte : `/Users/daviddemri/.codex/generated_images/01a09940-7eba-7eb3-8a93-f925c26f0fd3/exec-e5fffc34-8998-4078-8528-e02a08cfccbb.png`.
- `App/Resources/GameAssets/Terrain/sanfrancisco/earth.png` — roche/terre compacte grège sourde. Source intacte : `/Users/daviddemri/.codex/generated_images/01a09940-7eba-7eb3-8a93-f925c26f0fd3/exec-e6033a81-a212-4d35-9796-786816b86fb9.png`.

## Inspection visuelle

Les deux sorties ont été inspectées. Matières uniformes plein cadre, opaques, sans scène, objet, texte, marquage, bord, perspective, grandes fissures ou strates. Asphalte plus froid et sombre ; terrain plus chaud et légèrement plus clair, cohérent avec les rochers de la baie. Le grain de la route doit rester très fin dans la bande de 0,24 m. Celui du terrain reste diffus sur plusieurs mètres. Le fichier brut présente un détail fin perceptible à pleine résolution ; vérifier à l’échelle native que ce détail ne concurrence pas la moto. Répétabilité demandée ; absence exacte de raccord visible et lisibilité dans les pentes à confirmer dans le moteur par l’agent intégrateur.

## Prompt exact — road.png

```text
Use case: stylized-concept. Asset type: opaque square 1024x1024 seamless repeating material texture for a polished hand-painted side-view motorcycle game set in San Francisco at golden hour. Primary request: one full-frame uniform asphalt material, soft marine blue-gray asphalt with a tiny touch of warm coastal sunset light in its finely scattered muted mineral grain. The road consumes only a narrow 0.24 metre strip in the game; grain must be extremely fine and understated, not gravel rocks. High quality delicately painted illustration, elegant, simple, beautiful, matte, low contrast. Orthographic flat material swatch at a single constant scale, diffuse even neutral illumination, evenly distributed subtle irregular fine grain everywhere. Color palette: medium dark muted marine slate blue-gray, slight warm greige micro-specks; not pitch black. Entire frame filled with the SAME asphalt material, no gradient, perfectly flat light. Designed to tile seamlessly on all four edges with no obvious repeating motif. Avoid: road shape or road scene, markings, lines, stripes, lanes, borders, sidewalks, rails, large cracks, coarse rocks, objects, scenery, horizon, perspective, raised geometry, 3D render, vignette, central glow, focal point, directional shadow, directional light, words, letters, labels, watermark, transparency. Generate exactly one square PNG image.
```

## Prompt exact — earth.png

```text
Use case: stylized-concept. Asset type: opaque square 1024x1024 seamless repeating underground material texture for a polished hand-painted side-view motorcycle game set in San Francisco with a golden-hour coastal city backdrop. Primary request: one uniform full-frame material swatch of compact coastal earth and weathered fine-grained stone, soft muted greige slate rock mixed with dry compact soil. Sophisticated simple beautiful painterly finish, matte, very low contrast, fine restrained irregular mineral detail. This image fills several metres of terrain beneath the playable road, so it must remain calm and homogeneous without large recognisable features. Color palette: medium muted warm gray-taupe greige with very subtle desaturated slate blue in the mineral matrix, slightly warm sand-tinted micro-grain, moderate dark value. Orthographic flat surface swatch at one constant scale, evenly diffused illumination across the whole image, no spotlight or gradient. Entire frame filled with one continuous compact mineral-earth material; only small subtly varied grains and softly mottled microtextures, no major cracks. Designed to tile seamlessly on all four edges without a motif. Avoid: road or road section, landscape, objects, plants, roots, fossils, loose big stones, boulders, distinct pebble clusters, layers, strata, bands, cracks, lines, rails, geometric pattern, perspective, horizon, sharp relief, 3D render, hard shadows, central shadow, vignette, bright patches, dramatic light, words, letters, labels, watermark, transparency. Generate exactly one square PNG image.
```
