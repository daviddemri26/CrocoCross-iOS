# Kenji articulated artwork

Kenji keeps the existing orange-and-cream Shiba Inu, curled tail, blue/white/black racing leathers and blue superbike identity. The original `shiba-yamaha.png` stays unchanged. The eleven active PNG layers in `App/Resources/GameAssets/ShibaRig/` were generated with the built-in imagegen tool and copied intact. No raster pixel edits were used. Their matching prompts, source output paths and selected SHA-256/dimensions are recorded in this directory.

The active pelvis is generation `pelvis-v5`, and the active calf is `calf-v2`. Earlier candidates were rejected for diffuse exterior halos, an unwanted leg extension or rear-facing double buttocks. David explicitly requested a single side-profile hip, a visible tail and a deeply overlapping independent thigh. The original motorcycle logos are omitted from the newly drawn layers; all components share the same blue/white design. Hidden ends of limbs are complete to support overlap at their pivots.

`manifest.json` is the source of truth for top-left normalized landmarks, physical calibration, art orientation, painted bounds and presentation settings. Both the gameplay renderer and the catalog use the same assembly. Chassis/wheels use the existing 1.58 m wheelbase and 0.64 m tyre diameter; no gameplay physics was retuned. Only the suspension links change length as the physical wheel centres move.

Kenji has a compact superbike posture: 0.06 m maximum cosmetic pelvis shift and 0.18 rad relative torso lean. The source torso orientation preserves an expressive face while leaning toward the handlebars. Arms use 0.36 m and 0.43 m joint spans, legs 0.32 m and 0.34 m, and independent ankle boots remain on the pegs. Their ankle pivots sit inside the top cuff. The leg solver includes the ankle-to-sole offset so the shin enters the top opening. The accepted boot pitch is fixed at -0.30 rad relative to the chassis, with ankle flex at the cuff and exact sole support; `bootFollowsCalf` is false. Per-character data prevents Rocco's 1.8x arm thickness and pelvis crop from being inherited. A retained visual body offset maintains continuity when the rider detaches, then follows the physical torso/pelvis.

Validation commands:

```sh
swift scripts/check-rocco-assets.swift --rider shiba
bash scripts/render-rider-preview.sh shiba artifacts/qa/kenji/renderer/shiba
```

The native SpriteKit harness inspects neutral, wheelie, air, landing, inverted and detached poses; checks moving palms, soles and waist; and renders the same catalog snapshot used in the app. The validator checks source alpha and calibrated reach throughout the configured posture envelope. See `docs/NEXT-RELEASE.md` for app/device validation and the release hold.

## Small chassis correction — September 23, 2026

The active chassis is `bike-v2-front-fairing-trim`. David requested a small visual correction because the unchanged front wheel appeared too far behind the fairing. The built-in imagegen edit gently retracts the front nose and fender and opens the lower front contour. It preserves the original 1634 × 962 canvas; all ten other PNG files remain byte-identical.

No wheel, suspension, rider, hand/foot anchor, physics dimension or rig calibration changed. Only the chassis PNG and its measured `visibleBounds` camera metadata were updated. The generated source was copied intact; the prior image and complete invariant hash report are retained under `artifacts/qa/kenji/chassis-japan-2026-09-23/`. The exact edit prompt is `shiba-bike-v2.txt`, and `generations.json`/`assets.json` record provenance and the selected hash.
