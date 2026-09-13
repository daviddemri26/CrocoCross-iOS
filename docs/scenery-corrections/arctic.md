# Arctic — corrections des objets

## Exécution et références

Skill imagegen lu dans cette tâche. Quatre appels distincts au générateur d'images intégré (`image_gen`), sans CLI/API. Images neuves ; aucun fichier de référence transmis au générateur. Les originaux d'Arctic et les rendus précédents ont été inspectés visuellement : `arctic-aurora.png`, les quatre sprites remplacés, et les rendus natifs terrain/scenery. Palette neige nacrée, glace cyan/bleue et ombres nocturnes douces.

Les quatre PNG sélectionnés ont été copiés **intacts** dans le projet. Les versions précédentes étaient déjà sauvegardées par l'agent principal dans `artifacts/scenery-corrections/before/Scenery/arctic`. Aucune modification du moteur, des textures terrain ou d'un autre monde.

## Validation de la transparence

Décodage intégral des quatre PNG par ImageIO/CoreGraphics (contrôle Swift en lecture seule). Tous contiennent de vrais pixels alpha zéro ainsi qu'un sujet opaque ; les quatre coins de chaque fichier sont alpha zéro. Aucun faux damier. Entre 1,3 % et 2,7 % des pixels ont un alpha intermédiaire inférieur à 200, compatible avec les contours adoucis. Les rendus noirs/halos de l'aperçu du générateur ne sont pas des fonds opaques peints.

Le calibrage final des dimensions et la validation dans le jeu sont confiés à l'agent principal.

## ground-1 — Petit renard blanc endormi dans un abri de neige et glace

- Projet : `App/Resources/GameAssets/Scenery/arctic/ground-1.png`
- Source : `/Users/daviddemri/.codex/generated_images/01a0993e-40ca-7c32-99ad-4af538b42b2b/exec-6b5295d9-2ee7-406a-afdd-28ae8ec9d5fe.png`
- Taille : 1536 × 1024 pixels.
- Pixels totalement transparents : 52.50%.
- Inspection : Abri latéral avec sol horizontal clair ; renard dans une cavité plutôt que posé dans la glace massive. La couronne de glace donne le contexte nécessaire. Largeur de vignette prévue environ 1,3 m, à régler par le moteur.

Prompt exact :

```text
Use case: stylized-concept. Create one premium painted 2D game sprite on a genuinely transparent alpha background, 1024x1024 or larger PNG. Subject: a small white Arctic fox curled up asleep INSIDE a shallow shelter hollowed into snow and pale blue glacier ice. The fox lies securely on a clearly horizontal snowy floor. Show the shelter as a small irregular side-view cutaway pocket: a thin curved roof of snow and ice, softly shaded cool blue recess behind the fox, and a thin snowy ledge under it, all ending naturally in an irregular transparent silhouette. Direct frontal lateral orthographic view for a side-scrolling motorcycle game, no isometric perspective. Total shelter vignette represents about 1.3 metres wide; the curled fox is modest within it, about half the vignette width. Calm lovely white fur, tiny closed eyes, tail around nose, refined soft hand-painted detail and readable forms. Harmonize pearl snow and subdued cyan ice with an Arctic night aurora landscape. Beautiful, simple, restrained, not an ornate diorama. Only minimal surrounding ice is required to explain the shelter. Keep the full sprite comfortably inside the canvas with transparent margins. Real transparent pixels outside the irregular object silhouette, NOT a checkerboard drawing, no black background, no colored background, no glow halo. No full landscape, sky, horizon, sea, extra animals, text, watermark, rectangle, border, bulky frame, separate pedestal, floating isometric slab, large rocks or oversized crystals.
```

## ground-2 — Petit phoque sur rebord enneigé à côté d'une poche d'eau dans la banquise

- Projet : `App/Resources/GameAssets/Scenery/arctic/ground-2.png`
- Source : `/Users/daviddemri/.codex/generated_images/01a0993e-40ca-7c32-99ad-4af538b42b2b/exec-72b8b2e8-dbbd-4afc-9ce4-72c1194a7a8d.png`
- Taille : 1610 × 977 pixels.
- Pixels totalement transparents : 55.63%.
- Inspection : Phoque de petite taille, rebord relié à la paroi gauche, eau turquoise distinctement liquide avec ligne d'eau et profondeur visible à droite. Largeur de vignette prévue environ 1,65 m. Le sujet est volontairement petit dans sa poche de glace ; contrôle de lisibilité natif nécessaire.

Prompt exact :

```text
Use case: stylized-concept. Create one polished hand-painted 2D game sprite on a genuinely transparent alpha background, 1024x1024 or larger PNG. Subject: one small soft white seal pup resting on a horizontal snowy ice ledge INSIDE an irregular opening in blue sea ice, with a clearly visible calm deep turquoise WATER POCKET immediately beside and below the ledge. The seal is small and cute with natural proportions and relaxed flippers. The water is visibly liquid, with a clear horizontal waterline and two delicate ripples, occupying the right part of the opening; its blue depth is visible in lateral cutaway below the waterline. Show this as a small frontal lateral 2D cutaway niche in the glacier terrain of a side-scrolling game, total vignette about 1.65 metres wide. The snowy ledge is physically connected to the left icy wall and the water lies in a connected side pocket, NOT a floating slab lost inside opaque solid ice. Minimal thin irregular rim of milky blue ice explains the opening; no large cave frame or pedestal. Pearl white and muted cyan with cool soft shadows, refined painterly game illustration, lovely simple readable forms, low contrast detail. Full irregular silhouette comfortably inside canvas with transparent margins. REAL transparent empty pixels outside vignette, NOT a rendered checkerboard, no black or colored background, no glow halo. No overall landscape, sea panorama, sky, horizon, text, watermark, border, rectangle, isometric view, top-down view, decorative rock base, extra animals, large crystals.
```

## ground-3 — Cristaux de glace bleus enchâssés dans une fissure

- Projet : `App/Resources/GameAssets/Scenery/arctic/ground-3.png`
- Source : `/Users/daviddemri/.codex/generated_images/01a0993e-40ca-7c32-99ad-4af538b42b2b/exec-ff37fb8e-5a47-4d4e-bb5d-088af32e6d0e.png`
- Taille : 1619 × 971 pixels.
- Pixels totalement transparents : 68.82%.
- Inspection : Cinq cristaux à racines masquées par les lèvres de glace, sans socle séparé. Silhouette allongée et irrégulière, ouverture simple sans scène complète. Largeur prévue environ 1,7 m.

Prompt exact :

```text
Use case: stylized-concept. Create one premium softly hand-painted 2D game sprite, genuinely transparent alpha PNG, 1024x1024 or larger. Subject: a modest cluster of translucent BLUE ICE CRYSTALS visibly embedded INSIDE a shallow natural fissure in milky glacier ice, seen straight from the front in a lateral orthographic 2D cutaway. The crystal roots disappear into the surrounding ice, some edges partially occluded by the fissure rim, clearly ENCASED and growing within the glacier, not a freestanding crystal object or a crystal sitting on a pedestal. An irregular thin rim of pale blue glacial ice with subtle frost forms a small tapering patch around the darker blue opening. Four or five simple clear crystals of different small sizes nestled in the opening; lovely subdued cyan depth and white-blue highlights, restrained glow confined inside the ice. Total vignette about 1.7 metres wide for below-road terrain; avoid tall or gigantic gems. Match polished painted Arctic night game illustration, beautiful simple readable forms, delicate soft texture, minimal context and subdued contrast. Entire irregular sprite isolated with ample truly transparent margins and no surrounding color or glow halo. No landscape, sky, horizon, snow field, text, watermark, border, rectangle, circular frame, bulky rock surround, pedestal, isometric block, top-down view, floating slab, extra objects, rainbow colors or long hard cracks outside the vignette. Empty background must be real alpha transparency, NOT a drawn checkerboard or black background.
```

## sky-2 — Petit oiseau polaire blanc et brun en vol vers la droite

- Projet : `App/Resources/GameAssets/Scenery/arctic/sky-2.png`
- Source : `/Users/daviddemri/.codex/generated_images/01a0993e-40ca-7c32-99ad-4af538b42b2b/exec-d34dce81-4249-4c8c-b71c-02a425c966a6.png`
- Taille : 1254 × 1254 pixels.
- Pixels totalement transparents : 70.50%.
- Inspection : Oiseau générique sans attribution taxonomique stricte ; tête/bec à droite, queue à gauche, silhouette lisible et couleurs adaptées aux montagnes enneigées. Remplace le macareux côtier.

Prompt exact :

```text
Use case: stylized-concept. Create one premium painted 2D game sprite on a genuinely transparent alpha background, 1024x1024 or larger PNG. Subject: ONE small Arctic mountain bird in a simple natural gliding flight pose, flying toward the RIGHT, right-facing head and short beak clearly on the right, tail on the left, two wings extended in a compact readable silhouette. Mostly soft white winter feathers with a few muted warm-brown and slate-brown wing markings; a small dark eye and short subtle charcoal beak, natural unexaggerated proportions. A generic little polar bird suited to snowy mountain and glacier scenery, no strict species identity required. NOT a puffin, not a seabird with a large colorful bill, not an owl, not a bird of prey. Delicate refined hand-painted illustration, softly shaded like a polished children's adventure game, charming but not a cartoon face. Simple broad readable feather shapes for display at small size; no busy ornament. Cool subtle blue reflected light, pale white plumage with enough gray/brown structure to remain legible. Full bird comfortably inside canvas with ample real transparent margins around all feathers. Empty pixels must be true alpha transparency, NOT a drawn checkerboard; no sky, clouds, landscape, background color, glow halo, particles, frame, border, text or watermark. No extra birds, props, ribbons or motion lines.
```
