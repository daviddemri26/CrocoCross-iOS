# Premier plan — Paris

## Intention

Surface de paysage vue en légère plongée sous la route : une surface visible au premier plan, pas une coupe souterraine. Grandes zones simples, défilement en parallaxe prévu à 0,64 et répétition sur 18 mètres. Cette tâche produit uniquement l’image ; intégration et vérification native par l’agent principal.

## Génération et provenance

- Outil : built-in image_gen, génération neuve, une seule proposition.
- Référence de palette inspectée : App/Resources/GameAssets/paris.png. La référence n’a pas été fournie comme cible d’édition.
- Source intacte : /Users/daviddemri/.codex/generated_images/01a099d3-4c4b-7a73-ac30-f607f5b17c16/exec-7acf7618-5a1c-448d-a186-759734144303.png.
- Destination : App/Resources/GameAssets/Terrain/paris/earth.png.
- SHA-256 : 22834f7206036716434e69f6bad5e4d8f819487cda7eca3859fd775db456b8b5.
- PNG copié sans recadrage, recoloriage, retouche ou modification alpha.

## Contrôle

Grandes dalles crème rosé et plages d’herbe sauge, deux feuilles discrètes. Les joints restent fins et les grandes zones offrent du calme visuel. Pas de pavés minuscules, escalier, rue, horizon, construction ni coupe du terrain. Palette chaude et ombres mauves adaptées au fond parisien.

Inspection visuelle du résultat complet avant acceptation. Métadonnées ImageIO via sips :

~~~text
/Users/daviddemri/_docs/projects2026/CrocoCross2 iOS/App/Resources/GameAssets/Terrain/paris/earth.png
  pixelWidth: 1254
  pixelHeight: 1254
  hasAlpha: no
~~~

Les raccords sont conçus pour un usage répété ; le contrôle natif final du shader reste nécessaire.

## Prompt exact

~~~text
Use case: illustration-story. Asset type: one finished square opaque PNG foreground landscape surface for a premium illustrated side-scrolling motorcycle game, 1536x1536. Paint a beautifully simple quiet surface from a Parisian riverside square or garden, seen from a gentle elevated near-overhead viewpoint, filling the entire canvas. Broad calm regions of smooth warm cream limestone paving, in a few very large worn flat slabs with faint soft joins, flow beside broad softly curved patches of short muted olive-sage lawn. Restrained beautiful hand-painted natural storybook finish, elegant soft brushwork, relaxed shapes, very low visual noise. Warm late-afternoon golden-pink light across the stone, quiet dusty mauve shadows, desaturated soft green grass; evoke a Paris sunset park without depicting any landmark. One or two tiny loose leaves as discreet accents, almost no speckling. This is a simple 18-metre ground-plane patch for game parallax; broad understated surface, detail scale consistent throughout, no vanishing point. No raised edges. Make the opposite borders visually compatible for continuous repeated tiling, balanced tones across all sides, no vignette, no central composition or framed island. Fully opaque painted pixels edge to edge. Absolutely no sky, horizon, road, street, miniature cobblestone pattern, steps, stairs, underground, geological layers, tunnels, rivers, boats, vehicles, buildings, architecture, furniture, people, animals, trees, large flowers or large objects. No lettering, numbers, signs, text, logos, watermarks, UI, borders, frames. Not photorealistic, not vector, not plastic CGI. Generate only this one square finished foreground painting.
~~~
