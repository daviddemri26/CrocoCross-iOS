# Paris — matières de route et terrain

## Direction et références

Agent dédié Paris, 2026-09-13. Skill imagegen lu. Inspection visuelle avant génération de `App/Resources/GameAssets/paris.png` et `artifacts/scenery-review/paris-ground-1.png` : paysage de Paris au coucher du soleil, tons beige chaud, rose, mauve ; ancienne route pavée très géométrique et sous-sol mauve avec grandes strates ondulées.

Deux générations natives séparées avec le built-in `image_gen.imagegen`, sans CLI/API. Images neuves décrites à partir de l'inspection ; aucun fichier de référence transmis comme cible d'édition. PNG générés copiés intacts, aucune retouche ni conversion.

## Route

Fichier : `App/Resources/GameAssets/Terrain/paris/road.png`.

Provenance : `/Users/daviddemri/.codex/generated_images/01a09940-ba37-7d00-9b74-caf4d5a7f617/exec-a569b845-8808-49ab-aac4-db831168c523.png`.

Prompt exact :

> Use case: stylized-concept. Asset type: seamless opaque square 1024 by 1024 game material texture, Paris road surface. Generate one full-frame orthographic material swatch of small warm greige limestone cobblestones, about 8 to 10 small stones across the width, laid in fine slightly irregular staggered horizontal rows. Refined hand-painted illustration with delicately worn matte stone, very fine restrained surface grain, narrow low-contrast muted taupe joints, soft warm beige-grey with a subtle dusty rose undertone suitable for a beautiful Paris sunset illustration. Every stone is small-scale and quietly varied. Premium clean simple charming game art, elegant understated material, not crude geometric vector art, not photorealistic. The texture will repeat along a road strip only 0.30 metres thick, with a 1.8 metre horizontal repeat, so all detail must remain small and restrained. Constant orthographic scale everywhere. Fill the entire square with material. Uniform neutral diffuse lighting and consistent value across all four boundaries for seamless repeating. No perspective, no horizon, no scene, no actual road composition, no sidewalk, no road edge, no border, no paint markings, no cracks crossing the image, no objects, no plants, no text, no vignette, no center highlight, no cast shadows, no large dark gaps. Fully opaque PNG.

Inspection : pavés petits, environ neuf par largeur, rangs irréguliers discrets ; surface matte soignée et joints grège étroits. Texture plein cadre orthographique sans scène, route dessinée, objets ni bords. Palette cohérente avec la pierre parisienne du fond. Taille livrée 1254 × 1254, RGB opaque. Pour une répétition horizontale de 1,8 m, chaque pavé fait environ 0,2 m de largeur, compatible avec une bande de 0,30 m si les coordonnées de texture conservent l'échelle. Ne pas étirer le carré complet dans la seule épaisseur de route. Le motif est conçu répétable ; les raccords exacts et l'échelle finale restent à inspecter dans le rendu natif.

## Terrain

Fichier : `App/Resources/GameAssets/Terrain/paris/earth.png`.

Provenance : `/Users/daviddemri/.codex/generated_images/01a09940-ba37-7d00-9b74-caf4d5a7f617/exec-0955a1c8-1a71-40f2-ad65-bc719b98c120.png`.

Prompt exact :

> Use case: stylized-concept. Asset type: seamless opaque square 1024 by 1024 game material texture, Paris earth beneath the road. Generate one full-frame orthographic material swatch of quiet natural chalky limestone earth in an elegant warm greige with dusty rose and muted taupe undertones, suited to a beautiful illustrated Paris sunset game. This is continuous natural mineral earth, NOT stone masonry. Very subtle soft chalky mineral mottling and tiny scattered limestone inclusions, finely hand-painted matte material with delicate micrograin. Simple, beautiful, calm, high quality restrained illustration. The texture repeats over several metres of underground terrain so the inclusions must be tiny and sparse, with consistent average color and value everywhere. Shallow soft mineral variations only, very low contrast, no large recognizable shapes. Flat even diffuse lighting. Orthographic front-facing flat material, constant scale, fill entire square edge to edge, designed for seamless repetition along both axes with matching edge color and grain. No layering or sediment bands, no strata, no streaks, no large cracks, no fissures, no horizontal lines, no bricks or masonry, no pavement, no stones arranged in a pattern, no horizon, no perspective, no landscape, no objects, no fossils, no roots, no plants, no text, no vignette, no central light or dark patch, no cast shadows, no border. Fully opaque PNG.

Inspection : matière calcaire crayeuse grège rosé, inclusions minuscules, variation douce et homogène. Aucun motif de maçonnerie, grandes strates, fissures, objets ni vignette. Surface délicate et sobre adaptée au terrain sous Paris. Taille livrée 1254 × 1254, RGB opaque. L'image reste claire ; le contraste du bord de route devra être contrôlé dans le rendu natif. Raccords exacts à confirmer lors de l'intégration, sans présumer que la génération est mathématiquement seamless.
