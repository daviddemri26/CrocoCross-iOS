# San Francisco — corrections des objets sous la route

Trois images de remplacement créées par trois appels distincts à l’outil intégré `image_gen`, sans API/CLI, et copiées intactes dans les ressources. Les originaux restent sauvegardés dans `artifacts/scenery-corrections/before/Scenery/sanfrancisco/`. Aucune modification du code de rendu par cet agent.

## Inspection des références

Références examinées avec `view_image` : `App/Resources/GameAssets/san-francisco.png` et les trois anciens `App/Resources/GameAssets/Scenery/sanfrancisco/ground-{1,2,3}.png`.

Le fond présente la baie et des rochers grèges sous une lumière chaude. L’ancienne otarie était isolée sur un socle sans contexte côtier sous la route. Le voilier et le tramway donnaient une impression de miniatures au milieu de la terre. Les remplacements introduisent un contexte de petite cavité et des objets compatibles avec une coupe de terrain.

## Objets finaux

- `ground-1.png` : otarie couchée sur rebord dans une petite grotte littorale avec bassin d’eau visible. Vignette conseillée : **2,1 m de large** ; corps visible approximativement 60 % de la largeur utile, soit environ 1,25 m. PNG 1536 × 1024. Animal entièrement visible, oreille externe, nageoires et posture horizontale. Une seule petite poche d’eau, sans panorama.
- `ground-2.png` : coquillage fossile à côtes rayonnantes partiellement enchâssé dans une roche grège, remplace le voilier. Vignette conseillée : **0,9 m de large** ; fossile environ 40 % de la largeur utile, soit environ 0,36 m. PNG 1536 × 1024. Vue frontale adaptée à une paroi, relief peu profond, pas de socle flottant.
- `ground-3.png` : court câble d’acier posé sur une petite poulie ancienne dans une poche de galerie, remplace le tramway. Vignette conseillée : **1,6 m de large** ; roue environ 28 % de la largeur utile, soit environ 0,45 m. PNG 1586 × 992. Une seule poulie lisible, câble passant dans sa gorge et deux extrémités reposant dans la galerie.

Ces dimensions sont des recommandations pour le cadre utile hors marges transparentes. Les proportions des sujets ont été estimées visuellement, pas mesurées anatomiquement. Le réglage final de taille, le détourage runtime et le contrôle natif appartiennent à l’intégration.

## Contrôle alpha et réserves visuelles

Les trois sorties ont été inspectées visuellement, puis décodées en RGBA avec ImageIO/CoreGraphics. Transparence réelle, proportion de pixels alpha exactement nul : **50,37 %**, **47,44 %**, **42,09 %**, respectivement. Limites utiles au seuil alpha > 8 : ground-1 [181,63,1349,959], ground-2 [47,112,1499,919], ground-3 [20,110,1566,883]. Le contour extérieur est irrégulier et réellement transparent. Quelques pixels à alpha très faible prolongent les marges ; le halo sombre visible dans certaines prévisualisations brutes ne constitue pas un fond opaque. Aucune suppression d’arrière-plan ni retouche par script.

La grotte de l’otarie conserve une bordure rocheuse visible : contrôler en rendu natif qu’elle reste une petite cavité plutôt qu’un cadre dominant. Le coquillage doit rester discret à 0,9 m de vignette. La poulie garde une géométrie frontale simple. Aucun élément n’a besoin d’animation.

## Provenance des sorties finales

- ground-1 : `/Users/daviddemri/.codex/generated_images/01a09940-7eba-7eb3-8a93-f925c26f0fd3/exec-7290ceee-749a-4e50-8383-3be1d63fa8d5.png`
- ground-2 : `/Users/daviddemri/.codex/generated_images/01a09940-7eba-7eb3-8a93-f925c26f0fd3/exec-5d8dd7f5-8396-4cd1-b7fe-6da85d209db0.png`
- ground-3 : `/Users/daviddemri/.codex/generated_images/01a09940-7eba-7eb3-8a93-f925c26f0fd3/exec-f1c8bff2-b769-4a6c-9372-d85aa7f9aa3d.png`

## Prompts exacts

### ground-1.png

```text
Use case: stylized-concept. Asset type: one isolated transparent PNG scenery sprite for CrocoCross, a polished 2D side-scrolling motorcycle game, San Francisco coastal terrain cutaway. Primary request: a small California sea lion lying peacefully sideways on a low natural rock ledge INSIDE a tiny coastal cave pocket, with a clearly visible little pool of muted blue seawater below the ledge. The animal has warm soft brown fur, small ear flaps, rounded friendly natural face, folded flippers; relaxed horizontal body, full body visible. The vignette represents about 2.1 metres total width; sea lion body about 1.2 metres, believable proportions, no oversized head. A minimal shallow cave recess behind the sea lion explains the underground placement. Thin irregular soft greige slate rock edges surround part of the niche, softly tapering to actual transparency; no thick arch, no massive frame. Water occupies a small quiet area beneath the animal inside the pocket, no waterfall. Camera: strict frontal side elevation, level eye, like a small opening in a vertical terrain cross-section, not an isometric diorama or viewed from above. Art: beautifully refined hand-painted game illustration, soft realistic materials, warm coastal golden-hour accents, gentle shadows, muted gray taupe stone, quiet dusty blue water, natural restrained detail, simple charming readable silhouette. Entire isolated vignette fully visible with generous TRANSPARENT space all around, RGBA with genuine zero-alpha transparent exterior and soft natural irregular edges. No background, no rectangle, no full scene, no horizon, no sky, no sea panorama, no detached floating pedestal, no toy diorama, no text, no watermark, no black background, no white background, no checkerboard pattern baked into image. Generate exactly one PNG image at least 1024 pixels.
```

### ground-2.png

```text
Use case: stylized-concept. Asset type: one isolated transparent PNG underground scenery sprite for CrocoCross, polished 2D side-view motorcycle game, San Francisco coastal ground. Primary request: one small fossilized seashell, an elegant pale warm cream scallop shell fossil partially embedded in muted warm greige coastal sedimentary rock. The shell is naturally mineralized, its ridged fan-shaped impression clearly visible, about 0.3 metres across inside an irregular patch of rock representing about 0.9 metres total width. The shell is IN the stone, not a loose fresh shell placed on a podium. Only a thin patch of softly textured compact rock immediately surrounds the fossil, with shallow natural broken uneven edges that taper into genuine transparent pixels. Viewed straight-on in strict FRONT ELEVATION as a small discovery in a vertical terrain cutaway, no top-down view, no isometric view, no deep block, no thick raised frame, no freestanding boulder, no floating pedestal. High-quality hand-painted illustration matching a beautifully painted golden-hour San Francisco game background, quiet natural realistic mineral materials, warm cream fossil, dusty gray taupe stone, gentle shallow relief, simple composition and restrained detail, soft diffuse light. Entire small isolated rock-and-fossil vignette fully inside frame with generous truly transparent RGBA margins. No environment, sky, water, plants, other fossils, jewelry, ornamental border, frame, panorama, gradient backdrop, glow, text, labels, logos, watermark, solid background, checkerboard pattern. Preserve transparent background, actual zero alpha outside the irregular rock silhouette. Generate exactly one PNG image at least 1024 pixels.
```

### ground-3.png

```text
Use case: stylized-concept. Asset type: one isolated transparent PNG underground scenery sprite for CrocoCross, polished 2D side-scrolling motorcycle game, San Francisco. Primary request: a short length of old braided STEEL CABLE resting over one small dark iron pulley wheel, in a modest shallow underground service-gallery pocket. A simple subtle reference to cable-car machinery, NOT a cable car vehicle. Exactly one aged iron sheave wheel mounted close to the rocky floor in a short low simple bracket, cable bent gently across its groove with two short ends visible and resting; mechanically intelligible, no complex contraption, no toy, no extra wheels. The small underground niche is a shallow recess in muted warm greige rock, minimal dark interior immediately behind the machinery; thin irregular soft rock margins dissolve naturally to transparent exterior. Vignette total width about 1.6 metres; pulley diameter about 0.45 metres and cable thickness a few centimetres, believable object proportions. Composition: strict frontal side elevation, camera square to the face of the wheel and gallery cutaway, no isometric angle, no overhead perspective, no detached floating base, no deep diorama. Beautiful refined hand-painted game illustration, simple quiet readable forms, softly worn blue-gray iron with subtle brown oxidation and warm gray taupe rock, soft diffuse warm coastal light, restrained detail, low to moderate contrast. Entire isolated vignette fully visible with generous genuine transparent RGBA margins. No train, no tram, no vehicle, no rails, no tunnel stretching into distance, no full environment, no horizon, no foliage, no text, no labels, no logos, no massive rock frame, no rectangular background, no vignette glow, no white or black solid background, no checkerboard pattern. True zero-alpha outside the irregular niche outline. Generate exactly one PNG image at least 1024 pixels.
```
