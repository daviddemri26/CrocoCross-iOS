# Premier plan — San Francisco

## Intention

Surface de paysage vue en légère plongée sous la route : une surface visible au premier plan, pas une coupe souterraine. Grandes zones simples, défilement en parallaxe prévu à 0,64 et répétition sur 18 mètres. Cette tâche produit uniquement l’image ; intégration et vérification native par l’agent principal.

## Génération et provenance

- Outil : built-in image_gen, génération neuve, une seule proposition.
- Référence de palette inspectée : App/Resources/GameAssets/san-francisco.png. La référence n’a pas été fournie comme cible d’édition.
- Source intacte : /Users/daviddemri/.codex/generated_images/01a099d3-4c4b-7a73-ac30-f607f5b17c16/exec-7993731b-1a5b-4669-bf67-85d9c8956f20.png.
- Destination : App/Resources/GameAssets/Terrain/sanfrancisco/earth.png.
- SHA-256 : 06682705d560f22824b9a9225eb02276823fd28b1e8c319ac3ec507599e1f7e5.
- PNG copié sans recadrage, recoloriage, retouche ou modification alpha.

## Contrôle

Surface côtière claire, eau turquoise et sable/pierre répartis en larges plages, peinture douce sans horizon. Les quelques pierres sont basses et appartiennent à la surface. Contraste contenu et palette cohérente avec la baie du fond. Aucun objet narratif, texte, route ou coupe géologique.

Inspection visuelle du résultat complet avant acceptation. Métadonnées ImageIO via sips :

~~~text
/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Terrain/sanfrancisco/earth.png
  pixelWidth: 1254
  pixelHeight: 1254
  hasAlpha: no
~~~

Les raccords sont conçus pour un usage répété ; le contrôle natif final du shader reste nécessaire.

## Prompt exact

~~~text
Use case: illustration-story. Asset type: one finished square opaque PNG foreground landscape surface for a premium illustrated side-scrolling motorcycle game, 1536x1536. Paint an extremely simple tranquil San Francisco coastal surface seen from a gentle elevated near-overhead viewpoint, filling the entire frame edge to edge. Large quiet shapes of pale warm sand and smooth buff-grey coastal stone intermingle with broad softly bounded areas of muted clear turquoise bay water, as a continuous simplified bay shore surface. No raised shoreline walls. Only a few small rounded pebbles, very sparse soft sage moss touches, broad barely visible water ripples. Soft finely painted natural storybook illustration, graceful brushwork, no plastic, no geometric vector. Match a sunny San Francisco bay palette: pale warm cream and sandstone, restrained muted turquoise blue water, soft warm golden lighting and faint cool blue-grey shadows. Surface detail must be deliberately understated, large-scale and calm so separately drawn animals and vehicles remain clearly readable. Equal detail scale everywhere, no horizon or perspective convergence; the canvas depicts the surface only, no distant scenery. Make all four borders visually compatible for seamless repeated tiling: similar color distribution, no strong directional gradient, no dark border, no central framed island, no vignette, no sharp graphic boundary. Treat this as a large 18-metre foreground patch with a gentle sense of perspective, not a geological cutaway. Fully opaque filled pixels everywhere. Absolutely no sky, horizon, bridge, buildings, road, rails, cliffs, underground strata, caves, cross-section, boats, animals, people, flowers, large rocks or large objects. No text, numerals, signs, logos, watermark, frame or UI. Generate this single finished square game painting only.
~~~
