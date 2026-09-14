# Paris et San Francisco — cohérence des décors

13 septembre 2026.

Paris utilise un premier plan de rue entièrement sec : petits pavés gris mauve en éventail et portions de dallage calcaire. La 2CV remplace la rame de métro et l'immeuble haussmannien remplace la barque. Les deux variantes du ciel utilisent désormais l'image du pigeon gris existant, avec des tailles et vitesses différentes. Le chat sur ses livres et le rosier sont conservés et réduits pour rester discrets.

San Francisco utilise uniquement de l'eau bleue de la baie sous la route, avec l'otarie, le voilier et un nouveau ferry. Le cable-car disparaît. Au contact du pont, le groupe bollard/cordage/bouée remplace les pavots ; son appui est ajusté pour absorber la marge douce de l'image. Le goéland et le pélican restent cohérents. Le cadrage portrait montre les deux tours du Golden Gate. Les peintures originales des arrière-plans sont conservées.

La ligne où roule la moto conserve ses pavés clairs à Paris et sa structure de pont vermillon à San Francisco. Les textures et éléments du premier plan restent attachés au parcours, sans déformation animée. L'échelle de répétition des pavés parisiens est ramenée à 6 m ; l'eau conserve 18 m. Tailles uniformes sur les deux axes et profondeur existante préservées.

## Liste des éléments

Les dimensions sont des budgets d'affichage, pas des corps physiques : elles restent multipliées par la profondeur et l'échelle stable de chaque apparition. L'immeuble utilise maintenant un budget de 11 × 13 m : il dépasse la route et peut masquer momentanément la moto. Les voitures et bateaux sont également ancrés par leur base. Voir la [passe de tailles et d'occultation](SCENERY-SIZES.md).

| Ville | Fichier | Sujet | Budget largeur × hauteur |
| --- | --- | --- | --- |
| sanfrancisco | [ground-1.png](../App/Resources/GameAssets/Scenery/sanfrancisco/ground-1.png) | Otarie sur un rocher | 3.1 × 2.6 m |
| sanfrancisco | [ground-2.png](../App/Resources/GameAssets/Scenery/sanfrancisco/ground-2.png) | Voilier sur la baie | 6.4 × 6.8 m |
| sanfrancisco | [ground-3.png](../App/Resources/GameAssets/Scenery/sanfrancisco/ground-3.png) | Ferry de la baie | 8.4 × 4.4 m |
| sanfrancisco | [sky-1.png](../App/Resources/GameAssets/Scenery/sanfrancisco/sky-1.png) | Goéland blanc | Profondeur variable |
| sanfrancisco | [sky-2.png](../App/Resources/GameAssets/Scenery/sanfrancisco/sky-2.png) | Pélican brun | Profondeur variable |
| sanfrancisco | [wayside.png](../App/Resources/GameAssets/Scenery/sanfrancisco/wayside.png) | Bollard, cordage et bouée | 1.35 × 1.1 m |
| paris | [ground-1.png](../App/Resources/GameAssets/Scenery/paris/ground-1.png) | Chat sur des livres | 1.9 × 1.45 m |
| paris | [ground-2.png](../App/Resources/GameAssets/Scenery/paris/ground-2.png) | 2CV française bleue | 4.2 × 2.3 m |
| paris | [ground-3.png](../App/Resources/GameAssets/Scenery/paris/ground-3.png) | Immeuble haussmannien | 11 × 13 m |
| paris | [sky-1.png](../App/Resources/GameAssets/Scenery/paris/sky-1.png) | Pigeon gris lointain | Profondeur variable |
| paris | [sky-2.png](../App/Resources/GameAssets/Scenery/paris/sky-2.png) | Pigeon gris | Profondeur variable |
| paris | [wayside.png](../App/Resources/GameAssets/Scenery/paris/wayside.png) | Rosier en pot et arrosoir | 1.4 × 1.5 m |

## Images et prompts

Les six nouveaux PNG retenus ont été créés avec le générateur intégré imagegen, puis copiés intacts dans le projet. Aucune retouche externe ni modification d'alpha. La première texture parisienne à rangées horizontales a été rejetée après rendu natif : elle ressemblait trop à un mur. La texture retenue ci-dessous utilise des pavés en éventail. Le fichier `paris/sky-1.png` est une copie exacte du pigeon déjà présent dans `sky-2.png`, et non une nouvelle génération.

### paris-ground-texture

- Destination : [App/Resources/GameAssets/Terrain/paris/earth.png](../App/Resources/GameAssets/Terrain/paris/earth.png).
- Source : `/Users/daviddemri/.codex/generated_images/01a09902-c73c-7452-9170-1133530d18c5/exec-657d09e7-ef0a-421e-b1b6-9763fb854350.png`.
- SHA-256 : `88559404af8f906bcf606e250c6b411481ff2e784b82055cbf860d9a6a23259b`.

```text
Use case: stylized-concept. One opaque square seamless 2D game GROUND texture, 1536x1536. A Parisian side-street pavement seen directly from ABOVE, parallel overhead view of a FLAT WALKABLE FLOOR. Closely spaced SMALL dry grey-mauve cobblestones arranged in classic flowing FAN-shaped arcs, roughly 25 to 35 small stones across the image. Subtle pale limestone aggregate between them, muted warm pink sunset tint. Very low contrast, soft painterly natural realism, stones flush with each other, no raised bevels or directional edge shadows. Include one very broad gentle diagonal area of cream limestone pedestrian paving made of flat large slabs near one corner; most of the tile remains the finer grey fan-paved street. Ground fills entire image, seamless across borders, even lighting, quiet cohesive colors. No horizon, no vanishing point, no buildings, people, cars, objects, lawn, plants, sand, water. Absolutely NO masonry wall, no long rectangular bricks, no horizontal brick courses or regular horizontal striped bands. This must read as a Paris street FLOOR supporting a car, not a wall behind it. No outlines, text, labels, borders, grid or watermark. Full opaque PNG.
```

### sanfrancisco-water-texture

- Destination : [App/Resources/GameAssets/Terrain/sanfrancisco/earth.png](../App/Resources/GameAssets/Terrain/sanfrancisco/earth.png).
- Source : `/Users/daviddemri/.codex/generated_images/01a09902-c73c-7452-9170-1133530d18c5/exec-8d153637-b899-48bb-ba15-430b1e40ec01.png`.
- SHA-256 : `f640c08e817519cba62f358cd61f709d57607f19ccf0618edc77ce2f7e904773`.

```text
Use case: stylized-concept. Asset type: opaque seamless foreground water texture for a polished 2D side-scrolling motorcycle game. Generate one square raster painting, 1536x1536. San Francisco Bay: WATER ONLY filling every pixel, clean deep blue-teal bay water seen steeply from above, calm broad horizontal ripples with restrained lighter blue and soft pale-gold highlights. Clearly readable as open seawater, not tropical shallow beach water. Beautiful painterly realism, simple quiet color fields, low-to-medium contrast, no plastic 3D, no dense noisy grain. Mostly rich desaturated blue, a little teal, subtle warm afternoon reflections. Seamless tiling in both axes with even scale/illumination, no horizon, no perspective vanishing point. Absolutely no land, islands, shore, rocks, sand, roads, buildings, boats, animals, flowers, grass, text or symbols. No animation implied, no large foam curls. Opaque full-bleed PNG.
```

### paris-car

- Destination : [App/Resources/GameAssets/Scenery/paris/ground-2.png](../App/Resources/GameAssets/Scenery/paris/ground-2.png).
- Source : `/Users/daviddemri/.codex/generated_images/01a09902-c73c-7452-9170-1133530d18c5/exec-818c37a3-7f4d-4683-9683-ed3a1d8f4de5.png`.
- SHA-256 : `a0481a3e569ca804af718d26aafc709691b07af022bdb56b40c87cf5d933bdea`.

```text
Use case: stylized-concept. Asset type: isolated transparent PNG scenery sprite for a beautiful painted 2D motorcycle game. One instantly recognizable vintage French Citroen 2CV, soft French blue body and cream fabric roof, rounded headlights, curved fenders, four-door compact body and thin black tyres. No readable logos or text. Car alone in exact side view facing right, both wheels touch the same horizontal baseline, slightly painterly detailed hand-painted realism matching elegant storybook Paris sunset scenery. Warm peach rim light, gentle shadows on the car itself, clean crisp readable silhouette. Full car centred with 8% empty padding on all sides. No people, props, road, platform, sky, buildings, ground plane or cast shadow outside the car. Actual transparent alpha background, not white or grey, not a painted checkerboard. Output one PNG with transparency.
```

### paris-building

- Destination : [App/Resources/GameAssets/Scenery/paris/ground-3.png](../App/Resources/GameAssets/Scenery/paris/ground-3.png).
- Source : `/Users/daviddemri/.codex/generated_images/01a09902-c73c-7452-9170-1133530d18c5/exec-7fa94d5a-74a1-4d6a-ae2e-8cd286117ef7.png`.
- SHA-256 : `249f9bf2d859f77a37be628b1d68da257e5d5afcfec30323cbf2c278699b0430`.

```text
Use case: stylized-concept. Asset type: isolated transparent PNG foreground scenery sprite for a high-quality painted 2D game. One compact Parisian Haussmann corner apartment building, three storeys plus grey zinc mansard roof, cream limestone facade, tall French windows with black wrought-iron Juliet balconies, small burgundy shop awnings on the ground floor and a wooden double entrance. Charming and recognizably Paris, no readable text or logos. Mostly frontal view with a narrow visible right side, flat horizontal base, complete roof and chimneys. Beautiful warm sunset painterly realism, simple broad readable architectural features, no dense noise, no toy plastic 3D. Building alone, 8% empty padding on all edges, a tiny strip of dry cream pavement directly at its feet only. No cars, people, trees, water, river, other buildings, sky, backdrop, floating shadow. Actual transparent alpha background, no white fill, no checkerboard. Output one transparent PNG.
```

### sf-ferry

- Destination : [App/Resources/GameAssets/Scenery/sanfrancisco/ground-3.png](../App/Resources/GameAssets/Scenery/sanfrancisco/ground-3.png).
- Source : `/Users/daviddemri/.codex/generated_images/01a09902-c73c-7452-9170-1133530d18c5/exec-4d9a0860-f9bd-462e-9ba4-c1699029fe8b.png`.
- SHA-256 : `f19625cf25883d22cc3e3986d63ba9b9a6214c594e3c1ebf3893b52704308624`.

```text
Use case: stylized-concept. Asset type: isolated transparent PNG scenery sprite for a beautiful painted 2D motorcycle game. One classic San Francisco Bay passenger ferry, low wide white two-deck cabin with neat dark blue windows, navy blue hull, one small red-orange funnel, rounded bow facing right, recognizably maritime working bay ferry, no readable logos or text. Side view with a very slight three-quarter view of the bow; hull sits level at the waterline. Short restrained blue-teal wake touches the hull, no large water platform. Clean readable silhouette, warm afternoon painterly realism matching a Golden Gate Bay painting. Full boat centred with 8% empty padding. No people, cars, wheels, dock, rocks, buildings, land, sky, backdrop. Genuine transparent PNG alpha outside the boat and tiny wake; never render a checkerboard or solid background.
```

### sf-mooring

- Destination : [App/Resources/GameAssets/Scenery/sanfrancisco/wayside.png](../App/Resources/GameAssets/Scenery/sanfrancisco/wayside.png).
- Source : `/Users/daviddemri/.codex/generated_images/01a09902-c73c-7452-9170-1133530d18c5/exec-5e242a72-cd3e-4744-9913-3622778b4fcb.png`.
- SHA-256 : `a7de34afecf497c902924f30026b092843c9b2ec552c931a5f330cc3c3cf56a1`.

```text
Use case: stylized-concept. Asset type: small transparent PNG roadside marine vignette for a painted 2D motorcycle game crossing a San Francisco Bay bridge/quay. A single low dark blue-grey iron mooring bollard with a neat coil of thick tan nautical rope and a small orange-white lifebuoy leaning against its side. One simple compact nautical group, three-quarter side view, flat level base, recognizable from a small size. Beautiful hand-painted realistic materials, gentle golden afternoon light. No tall pole, sign, lettering, dock slab, vegetation, flowers, soil, sand, rocks, water square or cast shadow outside the objects. Entire group centred with 8% transparent padding. Actual transparent alpha background, no white background, no checkerboard texture. Output one transparent PNG.
```

## Vérification

[Galerie native](../artifacts/city-coherence/index.html), [rapport](../artifacts/city-coherence/validation.md), [prompts et provenance structurés](../artifacts/city-coherence/generated-assets.json).
