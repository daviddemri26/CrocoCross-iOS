# Cloud Nine — correction des objets

## Périmètre

Deux assets corrigés après audit : lune et trois étoiles sur nuage (`ground-3.png`), poisson volant (`sky-2.png`). Quatre assets conservés intacts : `ground-1.png` (baleine), `ground-2.png` (îlot), `sky-1.png` (montgolfière), `wayside.png` (fleurs). Leurs SHA-256 ont été comparés à la sauvegarde `artifacts/scenery-corrections/before/Scenery/clouds/` et sont identiques.

## Inspection et choix

Le fond `App/Resources/GameAssets/cloud-nine.png` et les deux sprites initiaux ont été inspectés avant génération. L'ancien croissant nacré presque blanc manquait de contraste sur les nuages clairs. Le poisson initial avait beaucoup de bijoux, dorures, perles et rubans, peu lisibles en petit.

Le nouveau croissant conserve sa silhouette, son ouverture à droite, exactement trois étoiles et sa base nuage. L'or miel et les ombres lavande offrent un contraste plus franc. Le poisson final regarde à droite, possède une silhouette simple, des nageoires légères bleu/rose, une queue courte et aucun bijou, dorure ou ruban. La génération neuve du poisson est plus sobre que l'édition initiale. La direction finale reste identique.

## Provenance des fichiers retenus

Built-in `image_gen` uniquement. Aucun CLI/API, détourage, recoloriage ou recadrage programmatique. Les PNG retenus sont copiés intacts dans les ressources du projet.

- `App/Resources/GameAssets/Scenery/clouds/ground-3.png` : `/Users/daviddemri/.codex/generated_images/01a09941-5521-7673-ad88-1bf893d59177/exec-d4024e46-700e-41a3-bc95-176721972e57.png`, 1254 × 1254, alpha réel.
- `App/Resources/GameAssets/Scenery/clouds/sky-2.png` : `/Users/daviddemri/.codex/generated_images/01a09941-5521-7673-ad88-1bf893d59177/exec-5fb3f93b-4e1c-4e84-8681-21cc91282048.png`, 1536 × 1024, alpha réel.

## Contrôle alpha

`sips` confirme `hasAlpha: yes` pour les deux PNG. Lecture réelle des pixels avec CoreGraphics, rapport `artifacts/scenery-corrections/clouds/alpha-check.json` :

- Lune : 740350 / 1572516 pixels ont alpha ≤ 8 (47,08 %), coins testés alpha=0; intérieur du sujet présent, alpha généralement 253.
- Poisson : 1234807 / 1572864 pixels ont alpha ≤ 8 (78,51 %), coins et marges testés alpha=0; intérieur du sujet présent, alpha généralement 252.

L'aperçu générateur peut montrer un halo issu du RGB sous les pixels transparents. Les pixels extérieurs effectivement lus ont alpha nul et ne doivent pas rendre ce RGB dans le moteur. Le contrôle natif final de l'agent principal demeure nécessaire pour confirmer l'affichage à l'échelle du jeu.

## Essais et prompts exacts

### 1. Édition de la lune (essai visuel retenu, sortie opaque rejetée)

Référence : ancien `App/Resources/GameAssets/Scenery/clouds/ground-3.png`.
Sortie : `exec-b04928d7-3c0e-47b4-9ef7-b906253a6f4b.png`. La sortie contenait un damier opaque (`hasAlpha: no`) et n'a pas été intégrée.

Use case: precise-object-edit. Edit the supplied reference sprite for a polished fantasy side-scrolling motorcycle game. Keep the same beautiful painterly illustration style, centered compact composition, a crescent moon open to the RIGHT, EXACTLY THREE five-point stars inside its opening, and the small cloud cushion beneath. Change only the color values enough to improve small-size legibility against bright white cloud scenery: make the moon and the three stars a warmer honey-gold with gentle amber shadows and controlled pale highlights, rather than nearly white pearlescent. Give the cloud cushion softly shaded lavender/periwinkle volume with restrained cream highlights. Keep it tasteful, simple, soft, charming, premium hand-painted detail, without thick outlines. Preserve the recognisable silhouette and proportions. No additional stars, ornaments, faces, objects or background. No glow halo outside the silhouette, no glitter particles or detached flecks. Output an isolated sprite on a genuinely transparent background with real alpha, including the opening around the stars and every gap. No opaque background, no black fill, no rectangle, no vignette, no checkerboard illustration, no frame, no text or watermark. Entire object uncropped with comfortable transparent margin. PNG.

### 2. Extraction alpha de la lune (retenue)

Référence : sortie de l'étape 1, même répertoire generated_images.

Use case: background-extraction. Remove the gray checkerboard background from this image completely. Return the moon, exactly three stars, and its cloud cushion as an isolated PNG cutout with REAL TRANSPARENT ALPHA pixels everywhere outside the artwork, including all gaps between the stars and moon. Preserve the honey-gold moon, stars, lavender cloud, shapes, colors and painted detail exactly. The checkerboard is unwanted visible imagery: remove every gray square rather than reproducing a transparency preview. No scene or solid background at all. No visual checkerboard, white, black or gray fill. Genuine empty transparent background only.

### 3. Simplification du poisson (sortie opaque rejetée)

Référence : ancien `App/Resources/GameAssets/Scenery/clouds/sky-2.png`.
Sortie : `exec-18de0657-960e-4cbd-8163-907e3515091f.png`. La sortie contenait un damier opaque (`hasAlpha: no`) et n'a pas été intégrée.

Use case: precise-object-edit. Edit the supplied flying-fish fantasy sprite. Keep the graceful friendly fish facing RIGHT, pretty pearly pastel blue/lilac body with soft pink accents, its simple clear eye and the high-quality soft painted illustration style. Simplify strongly for a small airborne game decoration: remove ALL jewellery, pearls, necklaces, pendants, tassels, metal, gold trim, stars, curls, emblems, filigree, ornamental patterns and long trailing ribbons. Retain only a clean compact fish silhouette with two light natural translucent-looking wing-like pectoral fins, a small dorsal fin, and a short elegant forked fish tail. Fins should be delicate pale blue with a hint of blush pink, with only a few natural fin rays. No giant triangular sails, no decorative accessories. Reduce scale microdetail to a few broad understated pearly scale suggestions readable at tiny display size. Beautiful, simple, airy and charming. Isolated whole fish centered with transparent space around its tail and fins, no cropping. Output PNG with genuinely transparent background and real alpha including every gap. Absolutely no surrounding glow, colored mist or halo, no black or white backdrop, no vignette, no rectangle, no illustrated checkerboard, no scene, no water, no cloud or text.

### 4. Extraction alpha du poisson (valide, variante non retenue)

Référence : sortie de l'étape 3.
Sortie : `exec-b05995fe-f296-4f6b-8120-7b29f5cd1d19.png`, alpha valide. La génération suivante a été préférée pour sa simplicité et ses marges.

Use case: background-extraction. Remove the gray checkerboard background from this image completely. Return only this pretty simple pastel blue/pink flying fish facing right as an isolated PNG cutout with REAL TRANSPARENT ALPHA pixels everywhere outside the artwork and in all the gaps. Preserve the friendly eye, compact fish body, delicate wing-like fins, forked tail, pastel colors and soft painted detail. No jewellery or ornaments. The checkerboard is unwanted visible imagery: remove every gray square rather than reproducing a transparency preview. No scene or solid background at all. No visual checkerboard, white, black or gray fill. Genuine empty transparent background only. Entire silhouette within the image, with some transparent margin, never cropped.

### 5. Génération neuve du poisson (retenue)

Sans référence image, après les problèmes de transparence initiale et pour améliorer la simplicité.

Create one small fantasy flying fish game sprite as a genuine transparent PNG cutout. A graceful friendly fish in clear side profile facing RIGHT, soft pastel powder-blue body, subtle lilac and blush pink on its short forked tail and two delicate wing-like pectoral fins. One simple dark-blue eye. Compact clean silhouette and simple natural fin rays; only a few broad hints of scales. Beautiful restrained hand-painted storybook illustration matching a sunny pastel floating-cloud world. No jewellery, no gold, no ornaments, no ribbons, no stars. A softly painted opaque subject with crisp antialiased silhouette, NOT luminous, no outer glow or mist. Entire fish uncropped with 10 percent transparent padding. Background truly empty with real alpha transparency everywhere outside the fish, including all fin gaps. Do not draw any background, checkerboard, shadow, halo or environment.
