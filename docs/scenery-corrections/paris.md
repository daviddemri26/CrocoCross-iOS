# Paris — corrections des trois objets sous la route

Agent dédié Paris ; génération built-in image_gen le 2026-09-13, conformément au skill imagegen précédemment lu. Aucun CLI, aucune retouche des pixels, aucune modification de code. Les trois PNG sélectionnés ont été copiés intacts dans les chemins consommés par le jeu ; versions antérieures préservées par le coordinateur dans `artifacts/scenery-corrections/before/Scenery/paris`.

## Références inspectées

`App/Resources/GameAssets/paris.png`, `Scenery/paris/ground-1.png`, `ground-2.png`, `ground-3.png`. Ancien chat sur livres sans contexte, faux train miniature et barque dans la terre. L'illustration du décor présente Paris au soleil couchant et une palette calcaire chaude. Les nouvelles matières Paris déjà livrées sont grège rosé.

## ground-1 — petit chat sur livres dans une alcôve

Fichier : `App/Resources/GameAssets/Scenery/paris/ground-1.png`.
Source : `/Users/daviddemri/.codex/generated_images/01a09940-ba37-7d00-9b74-caf4d5a7f617/exec-084b2932-5523-4a9a-8d14-2079141aedc2.png`.

Prompt exact :

> Use case: stylized-concept. Asset type: isolated transparent PNG sprite for a beautiful illustrated 2D side-scrolling motorcycle game, small underground Paris decoration. Create one small sleeping tabby cat curled on three old burgundy and olive books, resting on a thin flat horizontal stone shelf INSIDE a modest natural limestone cellar alcove. Strict straight-on frontal side-elevation cross-section, all ground support horizontal, no isometric or three-quarter diorama view. Realistic object proportions: the complete alcove is about 1.1 metres wide; the curled cat is only about 0.35 metres wide, occupying roughly one third of the alcove width, each book about 0.35 metres wide. Cat has natural small proportions, peaceful eyes closed, elegant restrained painted fur. The books rest securely on the shelf; discreet taupe inner shadow behind them explains the hollow. Only a very thin softly irregular outer rim of warm greige, dusty rose limestone surrounds the pocket. Sparse tiny mineral details, no masonry arch, no massive rocky frame, no freestanding block, no floating island. Carefully painted warm soft illustration matching a refined Paris sunset landscape, natural materials, simple pretty and understated, no plastic 3D, no crude outlined cartoon. Centered compact wide vignette with generous transparent margin. The outer mineral edge softly and irregularly finishes into TRUE ALPHA TRANSPARENCY around the whole cutout, including below; absolutely no opaque background, no checkerboard painted into pixels, no black matte, no white matte, no rectangular panel. A single minimal self-contained underground pocket, not a whole scene. No vegetation, no lantern, no window, no text or lettering, no extra objects. Output high-resolution transparent PNG.

Inspection : chat endormi posé sur trois livres, eux-mêmes sur une tablette horizontale dans une alcôve calcaire frontale. Silhouette complète sans coupe rectangulaire. Le chat occupe environ 32 % de la largeur minérale utile, soit environ 0,35 m pour la vignette de 1,1 m prévue. L'image conserve un rebord de pierre visible autour du creux ; évaluer son contraste une fois incrustée dans le terrain.

## ground-2 — roue ferroviaire dans poche de tunnel

Fichier : `App/Resources/GameAssets/Scenery/paris/ground-2.png`.
Source : `/Users/daviddemri/.codex/generated_images/01a09940-ba37-7d00-9b74-caf4d5a7f617/exec-868cdd74-f503-4058-8255-a59561a71cd3.png`.

Prompt exact :

> Use case: stylized-concept. Asset type: isolated transparent PNG sprite for a beautiful illustrated 2D side-scrolling motorcycle game, small underground Paris decoration. Create a single old solid steel railway wheel, a simple dished flanged wheel rather than spokes, standing upright and resting securely on a short horizontal steel rail inside a small shallow limestone tunnel pocket. Strict frontal 2D side-elevation cross-section, wheel circular face visible, rail exactly horizontal. No perspective railway receding into distance, no train, no toy train, no isometric or three-quarter diorama. Realistic proportions: complete mineral pocket about 1.5 metres wide, wheel diameter about 0.60 metres, short rail spans 0.95 metres. Slight restrained rust patina, matte dark bluish steel with subdued warm reflections. A quiet shadow behind wheel and a minimal mineral ground shelf explain the hollow. The pocket outer edge is THIN natural chalky warm greige limestone with soft dusty rose undertone, irregular mineral cut edge that dissolves gently into true transparent alpha. No archway, no brickwork, no masonry, no individual blocks arranged around the subject, no thick border or rocky frame, no freestanding pedestal or floating island. Keep this a modest simple detail in earth, not a large cave scene. Soft refined hand-painted illustration matching a warm Paris sunset environment, premium natural material detail, calm and understated, no plastic 3D, no crude outline cartoon. Centered landscape-shaped vignette with ample transparent margins all around. Fully transparent background using real alpha, not painted checkerboard, no black or white matte, no opaque rectangle, no outer cast shadow. No labels, lettering, logos, lamps, vegetation, gems, tools or extra objects. Output high-resolution transparent PNG.

Inspection : roue pleine à boudin en acier patiné, sur un rail horizontal dans une petite cavité de calcaire, face circulaire frontale. Remplace le véhicule entier miniature. La roue occupe environ 35 % de la largeur minérale utile, soit diamètre environ 0,53 m pour une vignette de 1,5 m. Support et contexte souterrain explicites, pas d'île flottante ou de scène entière.

## ground-3 — petite clé ancienne partiellement enfouie

Fichier : `App/Resources/GameAssets/Scenery/paris/ground-3.png`.
Source sélectionnée : `/Users/daviddemri/.codex/generated_images/01a09940-ba37-7d00-9b74-caf4d5a7f617/exec-4355c93e-a445-4dd7-8060-155b0b6727f6.png`.

Prompt exact retenu :

> Create a high-resolution PNG game sprite on a genuinely TRANSPARENT background with an alpha channel. One TINY antique iron key embedded in the center of a much wider warm greige limestone soil cutaway patch. The small key takes up just ONE QUARTER of the whole patch's visible width: imagine a 12 to 15 centimetre key inside a 50 centimetre patch of earth. Most of the sprite is calm fine pale taupe limestone soil, and the key is a discreet little discovery, not a hero closeup. The key has an oval bow, short simple shaft and a single toothed bit, bronze-brown aged patina, partly buried. A flat frontal vertical cross-section of underground earth, seen straight on in 2D side elevation. Shallow granular soil pocket; no raised mound, pedestal, isometric block or top-down ground scene. Wide softly irregular thin patch with feathered mineral edges fading to genuine alpha transparency. Refined beautiful natural hand-painted illustration appropriate to the limestone under Paris, soft warm grey-beige and dusty rose palette, small-scale chalky grain. Simple, quiet, charming. Leave transparent margins on every side. Single sprite only. No border, cave arch, frame, masonry, large rocks, roots, objects other than the single tiny key, sky, landscape, text, outer glow or cast shadow. The canvas outside the irregular earth cutout must be truly transparent, not an opaque image of a backdrop.

Inspection : une petite clé simple patinée incorporée dans une poche de calcaire grège clair, bord irrégulier transparent. La clé représente environ 20 % de la largeur minérale utile : environ 0,10 m si la vignette mesure 0,5 m, ou 0,13 m avec une vignette de 0,65 m. Elle reste ainsi un petit objet crédible et discret. Vue frontale aplatie, sans socle isométrique.

Une première génération transparente a été rejetée pour clé trop grande (~55 % de largeur) : `exec-bc4d32d2-5f0a-4f89-aaed-fe6ef148ef31.png`.

Prompt initial exact :

> Use case: stylized-concept. Asset type: isolated transparent PNG sprite for a refined illustrated 2D side-scrolling motorcycle game, tiny underground Paris decoration. Create one small antique iron key with gentle bronze-brown patina, partly buried diagonally in a small shallow pocket of natural chalky greige limestone earth. Simple old key with oval bow and single modest toothed bit, no ornate fantasy filigree. The complete soil pocket represents about 0.50 metres across and the key only 0.15 metres long, roughly 30 percent of its width. Part of shaft and bit hidden by fine earth, bow visible; actual object small inside the modest pocket. Frontal flat 2D cross-section of earth, no top-down ground plane, no isometric or three-quarter diorama, no raised pedestal. Minimal natural context, quiet chalky granular earth with a very thin softly irregular outline, warm greige and dusty rose suited to Paris limestone at sunset. Soft shallow shading around the exposed key, sparse tiny limestone grains only. Outer earth edges gently irregularly taper into true alpha transparency all around. No big border, no masonry, no arch, no rocky frame, no large stones, no dark hole, no roots or other objects. Premium carefully painted natural illustration, simple beautiful understated warm material, no plastic 3D or crude cartoon outlines. Centered compact horizontal vignette with generous empty transparent margins. Output high-resolution genuinely transparent PNG with real alpha, no white or black background, no checkerboard baked into image, no rectangular picture panel, no outer glow or shadow. No letters, labels or text.

Une édition d'échelle a ensuite été rejetée car elle avait produit un damier opaque, malgré la demande d'alpha : `exec-c0ba2d70-c983-4b3f-bdd2-80f0b3d93be5.png`.

Prompt d'édition exact :

> Edit this transparent game sprite. Keep the warm greige limestone earth material, restrained elegant illustrated rendering, one single antique key partly buried, irregular softly granular outline and REAL alpha transparent background. Change the key-to-soil scale: make the key only HALF its current width and length relative to the whole earth patch. Final key length must be about 28 to 32 percent of the visible patch width, clearly small and discreet, with generous quiet natural earth around it. The complete patch represents 50 centimetres, the key only 15 centimetres. Make the patch read as a thin frontal vertical 2D cutaway of soil, not an isometric island or top-down pedestal; show the small key embedded in that vertical earth face, at a gentle diagonal. Do not add any other objects, roots, rocks, frame or landscape. Preserve true transparent alpha beyond the irregular soil edge, no black matte, no checkerboard, no rectangular background, no outside glow.

## Contrôle réel des fichiers

Contrôle de décodage CoreGraphics et distribution des pixels alpha, distinct de l'aperçu : les trois fichiers retenus possèdent une véritable transparence avec les quatre coins alpha 0. Les deux premiers sont 1536 × 1024. Chat : environ 47,83 % des pixels entièrement transparents ; roue : environ 59,41 %. Le contrôle de la clé sélectionnée et des copies se trouve dans `artifacts/scenery-corrections/paris-alpha.txt`.

Les proportions ci-dessus sont estimées visuellement sur la silhouette de matière visible, et ne remplacent pas une mesure native en mètres du rendu intégré. Le coordinateur conserve la responsabilité de l'échelle finale, des oiseaux, du rosier vertical et de la QA dans le jeu.
