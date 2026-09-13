# Mine — textures de route et de sous-sol

Deux textures originales générées avec le mode intégré `image_gen`, puis copiées intactes dans le projet. Aucun traitement d'image ni modification du code partagé.

## Références inspectées
- `App/Resources/GameAssets/abandoned-mine.png` : mine illustrée, roches sombres ardoise/brunes, éclairage ocre des lanternes.
- `artifacts/scenery-review/mine-ground-1.png` : route et sous-sol précédents avec lignes/strates très visibles, retenus comme diagnostic d'intégration uniquement.

Les références ont été inspectées visuellement avant génération. Les deux images sont de nouvelles matières, sans image d'entrée au générateur.

## Fichiers et provenance
- `App/Resources/GameAssets/Terrain/mine/road.png`
  - Source : `/Users/daviddemri/.codex/generated_images/01a0993e-7e29-72a1-9882-be0743bae025/exec-bfe2116e-e45f-426a-97e2-a86d23b9aee5.png`
- `App/Resources/GameAssets/Terrain/mine/earth.png`
  - Source : `/Users/daviddemri/.codex/generated_images/01a0993e-7e29-72a1-9882-be0743bae025/exec-f64fdddd-1546-43b7-9912-a48b244f9724.png`

## Inspection des sorties
- Vérification locale avec `sips` : les deux PNG font 1254 × 1254 px, sans canal alpha (opaques).
- Route : gris-beige chaud de poussière et gravier fin. La tonalité plus claire permet de lire la surface au-dessus de la roche sombre ; pas de dessin de route, rail, bord, objet, perspective ou horizon.
- Sous-sol : roche brune fumée/ardoise avec fines inclusions ocre. Pas de grosses strates, de fissures marquées ou d'objets. Texture plus sombre et discrète que la piste.
- Les deux sorties sont carrées, entièrement remplies, avec un grain organique distribué sans point focal ni vignette volontaire.
- Réserve : texture conçue pour répétition, mais raccord mathématique des pixels opposés non certifié. L'intégration native doit vérifier le raccord et maintenir le grain de la route à une échelle fine. Le sous-sol comporte de légères variations minérales, à conserver subordonnées aux décors.

## Prompt exact — road.png

```text
Use case: stylized-concept. Asset type: square opaque repeating material texture for a polished illustrated side-view motorcycle game, 1024 by 1024 pixels or larger. Primary request: a beautifully painted uniform mine-track surface of compacted warm grey-beige mineral dust with extremely fine irregular gravel grain. This is only a material swatch, edge to edge, not a picture of a road. Palette: subdued warm limestone grey and muted taupe with tiny soft ochre grains; average medium-light warm grey, enough readability above a darker brown-slate underground. Style: refined hand-painted digital illustration, elegant restrained softly textured brushwork, natural fine granular variation, quiet matte finish, low contrast. Composition: perfectly flat orthographic material without perspective, evenly detailed and evenly lit across the entire square, no focus area. Designed for seamless horizontal and vertical repetition with equal tonal values at all edges. Grain must stay fine and subdued when this texture is clipped into a thin 0.23-metre track strip in a game. No rocks larger than a tiny grain, no dramatic fissures, no strata, no lines, no seams, no track marks, no rails, no road drawing, no horizon, no scenery, no objects, no grass, no transparent areas, no borders, no text, no vignette, no center spotlight or directional shadow. Generate a finished high-quality square raster game material.
```

## Prompt exact — earth.png

```text
Use case: stylized-concept. Asset type: square opaque repeating underground material texture for a polished illustrated side-view motorcycle game, 1024 by 1024 pixels or larger. Primary request: beautifully painted compact brown-slate bedrock with gentle mineral softness and very faint muted ochre inclusions for the earth mass underneath a mine track. Only a uniform material swatch covering the whole square, not scenery. Palette: restrained dark warm slate grey, smoky charcoal brown, subtle desaturated umber, extremely occasional tiny ochre mineral flecks; middle-dark average tone without deep black. Style: refined hand-painted digital illustration, soft irregular stony brush grain and unobtrusive granular pores, clean beautiful quiet texture, low contrast. It must feel mineral but not busy. Composition: flat orthographic material evenly distributed and evenly lit edge to edge, suitable for seamless horizontal and vertical repetition; equal tonal values at all borders, no obvious repeating motif. Material will cover several metres of underground in a 2D side-view game; grain must stay fine and subordinate to characters, vehicles and scenery cutouts. NO scene, NO perspective, NO horizon, NO objects, NO rails, NO large chunks, NO pronounced cracks or veins, NO horizontal strata or bands, NO directional lines, NO sharp polygon facets, NO individual boulders, NO shiny crystals, NO gold nugget shapes, NO border, NO text, NO vignette, NO spotlight, NO directional shadows. Entirely opaque, high-quality finished square raster texture.
```
