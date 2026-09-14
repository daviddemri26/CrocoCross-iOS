# Painted scenery and foreground

The area below the riding line represents the landscape surface seen in the foreground. Animals, vehicles, boats and small landscape vignettes belong on this plane. Their feet lie below the riding line in perspective; large subjects extend upward and can temporarily hide the motorcycle. This plane does not define a geological cross-section.

Each world has six transparent PNGs in `App/Resources/GameAssets/Scenery/<world>/`: three `ground` vignettes, two `sky` silhouettes and one `wayside` accent touching the road. This pass restores the 24 original ground paintings for the eight worlds other than Cloud Nine. The other 30 paintings retain their current versions, including Cloud Nine's warmer golden moon and simplified flying fish and Arctic's revised small polar bird. All 27 ground profiles are balanced by subject size. The 18 sky profiles now combine their subject proportions with stable depth and crossing speed; wayside settings are unchanged.

## Readable images and motion

`SceneryPresentation.swift` gives each complete vignette its own name, width, height budget and placement settings. Ground dimensions are now canonical world metres: fossils, frogs and moles use smaller footprints than foxes and seals, while caravans, pickups and urban vehicles retain widths of 4.8–5.2 metres. These remain readable art-direction proportions, not literal biological measurements.

A stable random depth selects a shared scale for width and height: **0.68 near the riding line → 1.0 lower in the foreground**. The same depth places an object's base farther below the route: depth × 2.4 m in portrait or depth × 1 m in landscape. Aspect ratio is preserved. Eleven selected large-subject profiles use an explicit base depth and grow upward, including the Paris building at an 11 × 13 m budget. Small vignettes keep their previous full-height clearance. World dimensions and footing remain stable through camera zoom. See [Scenery sizes](SCENERY-SIZES.md) for all profiles.

Foreground images, the broad foreground texture, the riding surface and wayside accents all remain attached to course coordinates at scrolling factor **1**, including with Reduce Motion. The earlier 0.64 experiment is removed: its texture drift and moving terrain sample beneath objects created the reported quicksand impression. Perspective now comes from fixed placement and size, with no independent ground movement. Gameplay physics, collisions, terrain height and scoring are unchanged.

Foreground images render independently of the terrain mask, in front of the complete rider rig. A tall building, mast or vehicle can cross the road silhouette and obscure the bike briefly; this has no collision behavior. Nine samples across each fixed world footprint keep the painted base below slopes. The painted foreground surface still fills the region below the route in every world, including Cloud Nine. Foreground objects are hidden in the Home hero preview. Upright wayside props stay vertical; low groups can follow gentle slopes. Five support samples reject steep or uneven wayside positions.

Each sky event keeps a fixed random apparent depth for its full crossing. `SkyPerspective` applies **0.62 scale at the farthest depth → 1.0 at the nearest depth** to both dimension budgets, preserving the original proportions. Far silhouettes sit slightly higher, and near silhouettes draw in front when two events overlap. Width remains based on `min(132 pt, 27% of viewport width)` and height on `min(110 pt, 22% of viewport height)`, multiplied by subject scale, placement variation and depth.

Crossings now take **16–36 seconds**, including off-screen margins. For ordinary subjects, the reference duration decreases from 32 seconds far away to 18 seconds nearby. Two planes have a 1.14 speed factor, the Japanese kite 0.90, the balloon 0.85 and the two butterflies 0.93. Duration is clamped to the 16–36 second range. This produces larger, faster images nearby while retaining calmer movement for balloons and kites. Selection searches the full maximum duration and discards expired events before assigning the two reusable actors, preserving irregular appearances without early disappearance.

The pelican continues leftward; the other painted silhouettes keep their existing rightward direction. Normal sky crossings retain their small vertical drift and rotation. Reduce Motion disables timed transforms and derives passage from camera movement, with the depth-dependent duration producing a correspondingly slower apparent movement for distant images. Ground sprites, including Cloud Nine, remain fixed to the course with no timed oscillation.

See the [18-object sky comparisons](../artifacts/sky-perspective/index.html) for near/far sizes and measured crossing speeds in both orientations.

The complete [27-object size table](SCENERY-SIZES.md) records the current canonical dimensions.

## Irregular appearances

A separate cosmetic seed selects variants, empty cells, offsets and scale for each ride. It never consumes the course or scoring RNG. Existing placements remain stable when the viewport changes.

| Layer | Selection cell | Appearance probability |
| --- | --- | --- |
| Ground | 26 metres on the foreground plane | 0.80 |
| Wayside | 54 metres along the course | 0.66 |
| Sky | 32 seconds during normal play | 0.84 |

These intervals are sampling cells, not a regular placement cadence. Random offsets and empty cells break repetition. Reduce Motion uses camera-derived sky timing instead of elapsed seconds.

## Artwork loading

`SceneryArtwork.swift` decodes the original PNGs with ImageIO at a maximum dimension of **768 pixels**, or **1536 pixels** for subjects with a width or height budget of at least 6 metres. Transparent padding is trimmed only in the runtime texture; generated files stay intact. Aspect ratios and real PNG alpha are preserved. Linear filtering and mipmaps keep enlarged images smooth, with a **20 MiB** scenery texture cache.

Procedural scenery actors, regular poles, terrain score labels and in-app scenery/terrain export hooks have been removed. The weekly finish flag remains a gameplay landmark.

## Current catalogue: 54 objects

Keys below identify the PNG filename inside each world's scenery folder. Linked generation records contain exact prompts and source provenance.

### Canyon

- `ground-1.png`: Ammonite sur le sable.
- `ground-2.png`: Fennec sur un rocher.
- `ground-3.png`: Géode d’améthyste ouverte.
- `sky-1.png`: Condor.
- `sky-2.png`: Avion rétro crème et rouge.
- `wayside.png`: Cactus fleuri.

[Original artwork and prompts](scenery-prompts/canyon.md).

### Japan Mountains

- `ground-1.png`: Bassin de carpes koï.
- `ground-2.png`: Renard endormi sur la mousse.
- `ground-3.png`: Pierres, champignons et fougère.
- `sky-1.png`: Hirondelle.
- `sky-2.png`: Cerf-volant japonais.
- `wayside.png`: Lanterne japonaise en pierre.

[Original artwork and prompts](scenery-prompts/japan.md).

### American Sunset

- `ground-1.png`: Caravane rétro.
- `ground-2.png`: Coyote endormi.
- `ground-3.png`: Pickup et citrouilles.
- `sky-1.png`: Avion léger crème et orange.
- `sky-2.png`: Rapace brun.
- `wayside.png`: Pneus anciens et fleurs jaunes.

[Original artwork and prompts](scenery-prompts/highway.md).

### Tropical Jungle

- `ground-1.png`: Tapir endormi.
- `ground-2.png`: Grenouille sur une feuille.
- `ground-3.png`: Cascade et bassin tropical.
- `sky-1.png`: Ara rouge, bleu et jaune.
- `sky-2.png`: Petit papillon bleu.
- `wayside.png`: Fougères et broméliacée.

[Original artwork and prompts](scenery-prompts/jungle.md).

### Arctic Aurora

- `ground-1.png`: Renard polaire sur la neige.
- `ground-2.png`: Phoque sur la banquise.
- `ground-3.png`: Cristaux de glace dressés.
- `sky-1.png`: Harfang blanc.
- `sky-2.png`: Petit oiseau polaire.
- `wayside.png`: Cairn enneigé.

[Original artwork and prompts](scenery-prompts/arctic.md); [current polar-bird revision](scenery-corrections/arctic.md).

### Old Gold Mine

- `ground-1.png`: Wagonnet de minerai.
- `ground-2.png`: Taupe sur une motte.
- `ground-3.png`: Géode turquoise ouverte.
- `sky-1.png`: Petite chauve-souris.
- `sky-2.png`: Petit papillon de nuit.
- `wayside.png`: Lanterne portative sur pierres.

[Original artwork and prompts](scenery-prompts/mine.md).

### San Francisco

- `ground-1.png`: Otarie sur un rocher.
- `ground-2.png`: Voilier sur la baie.
- `ground-3.png`: Ferry de la baie.
- `sky-1.png`: Goéland blanc.
- `sky-2.png`: Pélican brun.
- `wayside.png`: Bollard, cordage et bouée.

[Current bay direction and replacements](CITY-COHERENCE.md); [original generation records](scenery-prompts/sanfrancisco.md).

### Paris

- `ground-1.png`: Chat sur des livres.
- `ground-2.png`: 2CV française bleue.
- `ground-3.png`: Immeuble haussmannien.
- `sky-1.png`: Pigeon gris lointain (même image que la seconde variante).
- `sky-2.png`: Pigeon gris.
- `wayside.png`: Rosier en pot et arrosoir.

[Current Paris street direction and replacements](CITY-COHERENCE.md); [original generation records](scenery-prompts/paris.md).

### Cloud Nine

- `ground-1.png`: Baleine endormie sur un nuage.
- `ground-2.png`: Îlot flottant fleuri.
- `ground-3.png`: Lune dorée et étoiles sur un nuage.
- `sky-1.png`: Montgolfière pastel.
- `sky-2.png`: Poisson volant pastel.
- `wayside.png`: Trois fleurs sur un petit nuage.

[Original artwork and prompts](scenery-prompts/clouds.md); [current moon and flying-fish revisions](scenery-corrections/clouds.md).

## Checks for the current pass

The updated placement and presentation harnesses passed for this pass: all nine worlds and 54 profiles, phone visibility budgets, irregular placement, variant coverage, viewport stability and fixed course coordinates through 100 km. These checks validate numerical rules; they do not establish the appearance of a rendered frame. Current native checks cover 63 object views, fixed object/texture coordinates through scrolling and zoom, and rendered ground pixel comparisons in all nine worlds. Earlier portrait/recovery and landscape HUD tests remain historical evidence for the unchanged interface; see [Validation](VALIDATION.md) for scope.

Run from the project root:

~~~sh
swiftc -swift-version 6 -module-cache-path /tmp/crococross-scenery-swift-cache \
  App/Scene/SceneryPlacement.swift scripts/check-scenery.swift \
  -o /tmp/crococross-check-scenery
/tmp/crococross-check-scenery

swiftc -module-cache-path /tmp/crococross-scenery-swift-cache \
  App/Scene/SceneryPlacement.swift App/Scene/SceneryPresentation.swift \
  scripts/check-scenery-presentation.swift -o /tmp/crococross-check-scenery-presentation
/tmp/crococross-check-scenery-presentation

swiftc -swift-version 6 -parse-as-library \
  -module-cache-path /tmp/crococross-scenery-swift-cache \
  scripts/check-scenery-assets.swift -o /tmp/crococross-check-scenery-assets
/tmp/crococross-check-scenery-assets
~~~

The asset harness checks that all 54 PNGs exist, decode, carry alpha and contain both visible and transparent pixels. A valid alpha channel alone does not prove a clean silhouette or a good composition.

The new surface paintings and railway rendering are described in [TERRAIN.md](TERRAIN.md). Earlier [generation records](scenery-prompts) and [correction records](scenery-corrections) remain provenance archives; superseded correction descriptions and earlier validation captures are not evidence for the current presentation.

Current size and occlusion comparisons are in the [foreground overlap gallery](../artifacts/foreground-overlap/index.html). The [ground perspective gallery](../artifacts/ground-perspective/index.html) records the earlier small-object layout. The earlier [foreground gallery](../artifacts/foreground-refresh/index.html) records the superseded sizes and motion. See [Validation](VALIDATION.md) for the current scope and evidence.
