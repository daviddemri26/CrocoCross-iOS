# Canyon — route et terrain

Génération : built-in `image_gen`, deux appels indépendants. Sources originales conservées et PNG copiés intacts ; aucune retouche ni génération procédurale.

Références inspectées : `App/Resources/GameAssets/canyon-backdrop.png` et `artifacts/scenery-review/canyon-ground-1.png`. Palette retenue : sable doré compact pour le ruban roulant, grès ocre rosé mat pour le dessous.

## Road

Fichier : `App/Resources/GameAssets/Terrain/canyon/road.png`

Source : `/Users/daviddemri/.codex/generated_images/01a0993b-1f45-7ed1-a769-716a54c5226d/exec-737ae3cd-bc0b-4b18-97e6-bb17afec32bc.png`

Prompt exact :

Use case: stylized-concept. Asset type: seamless square opaque terrain material texture for a polished hand-painted side-scrolling motorcycle game, 1024 by 1024 pixels minimum. Primary request: a beautiful simple compacted desert sand and finely worn sandstone surface, uniformly covering every pixel edge to edge. Color palette: warm golden ochre, muted peach sandstone and fine buff grains, matching a sunlit red-rock canyon landscape illustrated with soft clean painterly strokes. The texture will be sampled finely inside a very narrow riding-surface ribbon only 0.35 to 0.45 metres thick, so detail must be extremely small, quiet and irregular. Hand-painted restrained material variation, matte finish, subtle scattered mineral flecks much smaller than the image, understated tonal variation, luxurious illustration finish. Flat material map only, orthographic, evenly lit. Seamlessly tileable left/right and top/bottom, matching colors and detail density at all borders. No depicted road, no edges, no road markings, no perspective, no landscape scene, no horizon, no objects, no rocks or large pebbles, no cracks, no strong grooves, no stripes, no grid, no central subject, no gradient or vignette, no cast shadow, no border, no text or logo, no transparency. Keep the texture calm and readable as an almost uniform warm sand material at game scale; do not create gritty photographic noise.

## Earth

Fichier : `App/Resources/GameAssets/Terrain/canyon/earth.png`

Source : `/Users/daviddemri/.codex/generated_images/01a0993b-1f45-7ed1-a769-716a54c5226d/exec-0d73ec84-0971-47bd-87cf-8686091baefd.png`

Prompt exact :

Use case: stylized-concept. Asset type: seamless square opaque sandstone material map for the large below-road earth cross-section in a polished hand-painted motorcycle game. 1024 by 1024 pixels minimum. Primary request: simple beautiful warm ochre and softly rosy terracotta canyon sandstone material, completely filling the square edge to edge. Refined matte hand-painted illustration, very low-contrast irregular soft mineral mottling and fine compact sandy mineral grain. Soft muted copper orange, warm dusty coral and ochre hues harmonize with a sunlit Southwestern red-rock canyon illustration. This image will cover many metres of visible earth and must remain restful and elegant behind small decorative objects. Very faint mineral variations only; broadly even density throughout. Flat orthographic material map, absolutely even ambient lighting, seamless on all four edges, edge colors and fine texture matching. No scene or canyon view, no perspective, no skyline, no objects, no fossils or gemstones, no large pebbles, no drawn road or road edge. No large horizontal strata, no explicit horizontal lines or bands, no wavy stripes, no cracks, no grid, no framing, no center glow, no vignette, no cast shadow, no text or logos, no transparency. Subtle quiet painted material, not photorealistic grit, not visible patterned shapes.

## Vérification

Deux PNG opaques de 1254 × 1254 pixels. Images inspectées visuellement après génération : aucune scène, aucun objet ni bord de route dessiné ; granularité fine et diffuse, absence de grosses strates. Route plus claire que le grès du dessous afin de distinguer le contact roulant. Les différences irrégulières de teinte sont discrètes et ne forment pas de motif figuratif. Les cartes sont conçues pour être répétées, mais l'absence de joint doit être vérifiée dans le rendu natif : les bords d'une génération ne sont pas garantis identiques pixel par pixel.
