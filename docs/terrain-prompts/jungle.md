# Jungle terrain textures

Generated with the built-in `image_gen` tool in two independent calls on 2026-09-13. Both PNG outputs were copied intact into the app resources. No code modifications, cropping, recoloring or resampling.

## References inspected

- `App/Resources/GameAssets/tropical-jungle.png` — lush illustrated emerald vegetation, turquoise water, warm mineral cliffs.
- `artifacts/scenery-review/jungle-ground-1.png` — native rendering: former broad green procedural ground and thin bright green track; the new materials replace this synthetic look with warm brown soil while preserving visual contrast with the forest.

## Deliverables and provenance

- `App/Resources/GameAssets/Terrain/jungle/road.png` — compact warm ochre-brown soil, tiny olive flecks.
  - Source: `/Users/daviddemri/.codex/generated_images/01a0993e-0dd9-7a40-ae50-15e3f237e0e1/exec-9541e7b5-626b-44c2-8409-1e3d385e6ab8.png`
- `App/Resources/GameAssets/Terrain/jungle/earth.png` — deeper umber forest soil, discreet olive mineral flecks.
  - Source: `/Users/daviddemri/.codex/generated_images/01a0993e-0dd9-7a40-ae50-15e3f237e0e1/exec-d9480fc9-bead-4134-ac0b-15fabfb4a0e1.png`

## Visual inspection

Inspected each generated image at full output resolution: both are uniform, square, opaque, edge-to-edge matter without a scene, perspective, roots, stripes, horizon, large rocks, text or vignette. Fine irregular inclusions and restrained painted relief are appropriate for the requested simple style. The road is clearly lighter than the earth without an artificial neon rim. Each has sufficient resolution for the intended game use.

The material is designed to repeat, but exact pixel equality at opposite edges is not guaranteed by generative output. Native integration should verify edge transitions and final grain scale at the game zoom. Avoid applying additional dark tint to the earth: it is already deep brown. Integration and native QA are performed by the parent agent.

## Exact prompt — road

```text
Use case: stylized-concept
Asset type: opaque seamless square game material texture, 1024 x 1024 pixels or larger.
Primary request: Create a beautiful simple hand-painted compact warm earth trail material for a premium illustrated tropical jungle side-scrolling motorcycle game. This is a material swatch, NOT a landscape or picture of a path.
Subject: Uniform full-frame warm muted clay-brown compact soil with a very fine irregular painterly grain, tiny muted olive moss flecks sparsely integrated into the grain. Earth predominates. Soft sophisticated color variation, fine-grained detail that stays quiet at small scale. In the game this square is sampled repeatedly along a narrow trail strip only 0.25 metres thick.
Style/medium: polished softly painted storybook game art, natural elegant pigments, subtly tactile, low contrast; no photorealistic harsh relief, no 3D rendering.
Composition: flat orthographic material albedo, the same scale and distribution everywhere, intended seamlessly repeatable on both axes, edge-to-edge opaque material. Equal lightness at all edges and in the center.
Palette: warm brown umber and muted ochre, very subtle olive hints, compatible with lush emerald vegetation and turquoise jungle background. No bright lime.
Constraints: exactly one full square texture, opaque PNG. No sky, horizon, perspective, road edges, central path, scene, objects, leaves, grass blades, roots, strata, giant stones, cracks, border, directional shadows, central light, gradient, vignette, text, labels, watermark or grid. Tiny details only, restrained and simple.
```

## Exact prompt — earth

```text
Use case: stylized-concept
Asset type: opaque seamlessly repeatable square game material texture, 1024 x 1024 pixels or larger.
Primary request: Create a beautiful simple hand-painted dark forest earth material for the broad ground below the road in a premium illustrated tropical jungle side-scrolling motorcycle game. This is a uniform soil material swatch, NOT a landscape, a terrain cross-section drawing or a picture of a path.
Subject: Full-frame rich muted deep umber forest earth with small, very subtle olive-green mineral inclusions and a very fine irregular painterly grain. Earth brown must predominate. Soft quiet nuanced mottling, restrained low contrast and elegant color. Material must read as dense soil, not emerald grass or moss carpet. The square will repeat across several metres of ground.
Style/medium: sophisticated softly painted storybook game art, subtly tactile but simple, cohesive with a lush emerald/turquoise tropical illustration. No harsh photorealistic relief, no 3D rendering.
Composition: flat orthographic material albedo, exactly the same scale and sparse detail distribution everywhere, intended seamlessly repeatable on both axes. Edge-to-edge fully opaque material. All edges and the center have similar lightness and saturation.
Palette: dark brown umber, warm charcoal brown, discreet moss-olive mineral specks. Avoid strong red or luminous green. Tiny soft flecks only.
Constraints: exactly one full square texture, opaque PNG. No sky, horizon, perspective, road edge, scenery, objects, leaves, grass blades, visible roots, sedimentary layers, large stones, cracks, stripes, central feature, border, directional shadows, spotlight, gradient, vignette, text, labels, watermark or grid. Quiet and fine-grained, suitable for a large unobtrusive background area.
```
