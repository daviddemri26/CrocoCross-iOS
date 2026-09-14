# Ground object sizes

Canonical width and height budgets in world metres, before the stable depth multiplier (0.68 beside the road to 1.0 deeper in the foreground) and the per-placement variation (0.94–1.08). Rendering preserves the PNG aspect ratio. Dimensions are limits, not forced stretching.

Large buildings, vehicles and selected landscape features are anchored by their painted base and can rise above the riding line. They render in front of the complete bike, producing temporary visual occlusion during the pass. The Paris building now has an 11 × 13 m budget, rather than 3.8 × 3.5 m. Its actual fitted image is approximately three times larger. It may extend beyond a short landscape viewport instead of shrinking into a miniature.

| World | Image | Object | Width | Height budget | Base depth below road |
| --- | --- | --- | ---: | ---: | --- |
| canyon | ground-1.png | Ammonite sur le sable | 1.9 m | 1.4 m | Small vignette: full silhouette below road |
| canyon | ground-2.png | Fennec sur un rocher | 2.7 m | 2 m | Small vignette: full silhouette below road |
| canyon | ground-3.png | Géode d’améthyste ouverte | 2.2 m | 1.9 m | Small vignette: full silhouette below road |
| japan | ground-1.png | Bassin de carpes koï | 3.8 m | 2.3 m | Small vignette: full silhouette below road |
| japan | ground-2.png | Renard endormi sur la mousse | 2.8 m | 1.8 m | Small vignette: full silhouette below road |
| japan | ground-3.png | Pierres, champignons et fougère | 2.3 m | 1.6 m | Small vignette: full silhouette below road |
| highway | ground-1.png | Caravane rétro | 6 m | 3.6 m | 0.65 m |
| highway | ground-2.png | Coyote endormi | 2.8 m | 1.9 m | Small vignette: full silhouette below road |
| highway | ground-3.png | Pickup et citrouilles | 5.6 m | 3.4 m | 0.65 m |
| jungle | ground-1.png | Tapir endormi | 3.2 m | 2.4 m | Small vignette: full silhouette below road |
| jungle | ground-2.png | Grenouille sur une feuille | 1.9 m | 1.7 m | Small vignette: full silhouette below road |
| jungle | ground-3.png | Cascade et bassin tropical | 5.5 m | 5.2 m | 1.4 m |
| arctic | ground-1.png | Renard polaire sur la neige | 2.8 m | 1.8 m | Small vignette: full silhouette below road |
| arctic | ground-2.png | Phoque sur la banquise | 3 m | 1.9 m | Small vignette: full silhouette below road |
| arctic | ground-3.png | Cristaux de glace dressés | 4 m | 4.6 m | 0.85 m |
| mine | ground-1.png | Wagonnet de minerai | 3.6 m | 2.8 m | 0.7 m |
| mine | ground-2.png | Taupe sur une motte | 1.9 m | 1.4 m | Small vignette: full silhouette below road |
| mine | ground-3.png | Géode turquoise ouverte | 2.3 m | 2 m | Small vignette: full silhouette below road |
| sanfrancisco | ground-1.png | Otarie sur un rocher | 3.1 m | 2.6 m | Small vignette: full silhouette below road |
| sanfrancisco | ground-2.png | Voilier sur la baie | 6.4 m | 6.8 m | 1.2 m |
| sanfrancisco | ground-3.png | Ferry de la baie | 8.4 m | 4.4 m | 1.1 m |
| paris | ground-1.png | Chat sur des livres | 1.9 m | 1.45 m | Small vignette: full silhouette below road |
| paris | ground-2.png | 2CV française bleue | 4.2 m | 2.3 m | 0.6 m |
| paris | ground-3.png | Immeuble haussmannien | 11 m | 13 m | 3 m |
| clouds | ground-1.png | Baleine endormie sur un nuage | 6 m | 4.2 m | 1 m |
| clouds | ground-2.png | Îlot flottant fleuri | 5.6 m | 4.8 m | 1.2 m |
| clouds | ground-3.png | Lune dorée et étoiles sur un nuage | 3.5 m | 3.1 m | Small vignette: full silhouette below road |

The additional perspective depth is depth × 2.4 m in portrait or depth × 1 m in landscape. Nine support samples across the stable world footprint keep the whole painted base below ramps. Large subjects grow upward from that base; small vignettes retain their full-height clearance. Lower objects render in front of shallower ones. Foreground images are independent of the road's crop mask and hidden in the Home hero preview.

Texture, object footing and riding surface scroll together at factor 1. Size and footing do not depend on speed or camera height. Large subjects with a dimension budget of at least 6 m decode their existing PNG at up to 1536 pixels; smaller sprites retain the 768-pixel decode. No source PNG was modified for this size pass.

See [Scenery](SCENERY.md) for source provenance and placement, and the [current native gallery](../artifacts/foreground-overlap/index.html) for the building, other large subjects and the pass in front of the bike.
