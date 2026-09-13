# Cloud Nine — matières de route et de sous-route

## Intention

Deux matières peintes simples, opaques, fines et discrètes, liées aux nuages nacrés, aux ombres lavande et au ciel bleu du paysage Cloud Nine. Le dessus reste clair et chaud; le dessous est légèrement plus sombre et plus froid pour distinguer la bande roulable du ruban flottant. La matière ne contient ni scène, ni route dessinée, ni objet.

## Références inspectées

- `App/Resources/GameAssets/cloud-nine.png`: nuages blancs/crème, ombres bleu lavande, lumière chaude; îles flottantes fantastiques.
- `artifacts/scenery-review/clouds-ground-1.png`: ancienne bande plate aux ovales répétitifs et trait violet; l'objectif est de remplacer cette lecture géométrique par une matière peinte délicate.

## Assets et provenance

Génération avec le tool built-in `image_gen`, deux appels indépendants. PNG copiés intacts, aucune retouche ni recadrage. Les deux images font 1254 × 1254 pixels, sans canal alpha (`sips`: `hasAlpha: no`).

- `App/Resources/GameAssets/Terrain/clouds/road.png`
  - Original: `/Users/daviddemri/.codex/generated_images/01a09941-5521-7673-ad88-1bf893d59177/exec-14ab3ca8-a449-4d6a-b5ab-97dfaf093c7a.png`
- `App/Resources/GameAssets/Terrain/clouds/earth.png`
  - Original: `/Users/daviddemri/.codex/generated_images/01a09941-5521-7673-ad88-1bf893d59177/exec-9c209dcf-83ea-48e4-a1aa-09dba23ff63b.png`

## Prompts exacts

### road.png

Use case: stylized-concept. Asset type: production game material texture, opaque square PNG at least 1024 by 1024 pixels. Create a seamless tileable full-frame painted cloud-matter texture for the very thin riding surface of a floating cloud road in a polished side-scrolling fantasy motorcycle game. This is ONLY an even material swatch, not an image of a road. Pearly warm white and ivory cream, subtly interwoven with the palest lilac and icy blue. Exquisite restrained hand-painted fine vapor wisps, smooth soft gauzy transitions, tiny delicate tonal variation. A calm luminous cloud substance, elegant and simple, uniformly distributed fine-scale detail so that any narrow horizontal crop remains beautiful and legible at small game size. No giant cloud lobes, no individual clouds, no landscape, no sky, no horizon, no perspective, no objects, no stars, no sparkles, no pebbles, no road drawing, no line markings, no contour borders, no edge framing, no vignette, no central light or shadow, no radial gradient, no letters or watermark. Entire image fully opaque and filled with material. Low contrast, equal brightness across all edges, seamless repeating texture in both directions. Soft premium painted illustration, never plastic 3D.

### earth.png

Use case: stylized-concept. Asset type: production game material texture, opaque square PNG at least 1024 by 1024 pixels. Create a seamless tileable full-frame texture of gently shaded cloud substance, used inside the slender floating ribbon beneath a fantasy motorcycle game's cloud road. ONLY a uniform material swatch, no scene and no road silhouette. Refined premium painted illustration, pastel periwinkle lavender and soft powder blue, with faint pearly lilac wisps and very subtle warm blush. A muted medium-light pastel value, visibly a little darker and cooler than an ivory-white riding surface, never dark or saturated. Delicate soft organic cloud-fiber grain and tiny vapor curls evenly distributed across the whole frame, smooth dreamy gauzy texture, low contrast. No large cloud balls, no distinct cloud shapes, no landscapes, no sky patches, no horizon, no perspective, no objects, no stars or sparkles, no rainbow, no stones, no geometric patterns, no drawn road, no edge outlines, no frame or borders, no vignette, no central highlight or shadow, no directional lighting gradient, no text or watermark. Entire frame fully opaque and filled by continuous cloud material. Uniform luminance at all edges, seamless repeat in both directions, beautiful when sampled in a thin shallow strip. Simple, restrained, elegant painted fantasy atmosphere, not plastic 3D.

## Inspection

Les deux images générées ont été inspectées visuellement. Elles sont uniformes et plein cadre, sans horizon, objet, bordure ou groupe de nuages individualisé. Le dessus est blanc nacré avec de très fines volutes pastel. Le dessous est pervenche/lavande avec quelques reflets rosés très discrets. Les variations restent souples et à faible contraste. L'échelle fine convient à une bande de route de 0,20 m et à un intérieur flottant d'environ 0,90 m. Les textures ont été demandées répétables; aucune certification de raccord pixel à pixel n'est faite ici. L'intégration et la vérification des raccords dans le renderer natif restent à la charge de l'agent principal.
