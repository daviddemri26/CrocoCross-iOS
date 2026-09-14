# Premier plan — Cloud Nine

## Intention

Surface de paysage vue en légère plongée sous la route : une surface visible au premier plan, pas une coupe souterraine. Grandes zones simples, défilement en parallaxe prévu à 0,64 et répétition sur 18 mètres. Cette tâche produit uniquement l’image ; intégration et vérification native par l’agent principal.

## Génération et provenance

- Outil : built-in image_gen, génération neuve, une seule proposition.
- Référence de palette inspectée : App/Resources/GameAssets/cloud-nine.png. La référence n’a pas été fournie comme cible d’édition.
- Source intacte : /Users/daviddemri/.codex/generated_images/01a099d3-4c4b-7a73-ac30-f607f5b17c16/exec-310815ed-2f24-45da-a862-1accd0752347.png.
- Destination : App/Resources/GameAssets/Terrain/clouds/earth.png.
- SHA-256 : 5d879bc746f618eadd4fda372ab3bc40467a6d7c2fefd3eae4fb651fc74ef22b.
- PNG copié sans recadrage, recoloriage, retouche ou modification alpha.

## Contrôle

Mer de nuages continue ivoire/rose/lavande, grands volumes doux et faible contraste. Aucune étoile, aucun objet ou soleil, pas de ciel vide ni trou transparent. Tous les bords contiennent la même matière et la même échelle.

Inspection visuelle du résultat complet avant acceptation. Métadonnées ImageIO via sips :

~~~text
/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Terrain/clouds/earth.png
  pixelWidth: 1254
  pixelHeight: 1254
  hasAlpha: no
~~~

Les raccords sont conçus pour un usage répété ; le contrôle natif final du shader reste nécessaire.

## Prompt exact

~~~text
Use case: illustration-story. Asset type: one finished square fully opaque PNG foreground surface painting for a premium illustrated side-scrolling motorcycle game, 1536x1536. Paint a serene endless sea of soft clouds seen gently from above, with the clouds filling the ENTIRE canvas edge to edge. Very large rounded flowing cloud masses, only six or seven broad gently interlocking billows across the square; soft luminous ivory highlights, pale blush peach-pink transitions and muted powder-blue/lavender shadows. Exceptionally simple, lovely, airy and calm. Hand-painted high-quality storybook illustration with elegant soft natural brushwork. Low contrast, no deep shadows, very little tiny texture or micrograin; broad soft cloud forms provide a quiet surface for separate sprites. All parts of the square have the same scale and similar brightness, no central focal point and no directional light gradient. Suitable as a continuous 18-metre foreground surface, not a sky backdrop: no empty blue sky gaps at all, no horizon, no distant clouds, no depth convergence. Make all four borders visually compatible for seamless repeat tiling with consistent clouds flowing to the frame edges, no vignette or border. Fully opaque solid painted PNG with no alpha transparency or holes. Absolutely no sun, moon, stars, rainbow, sparkle points, islands, land, grass, buildings, castles, balloons, animals, people, flowers, road, geological cutaway or objects. No text, signs, symbols, numerals, logos, watermarks, UI, frames. Avoid repeating scalloped rows, tiny popcorn cloud lumps, flat vector shapes, plastic CGI or photo texture. Generate only this one finished square foreground cloud painting.
~~~
