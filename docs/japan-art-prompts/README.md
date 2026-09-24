# Japan panorama and foreground art

Generated with built-in imagegen on September 23, 2026. Files are copied intact, with no pixel editing. Exact prompts, actual output dimensions, source paths and SHA-256 values are recorded here. The requested wide panorama was returned as 2172 x 724 (3:1); it is displayed as a large continuous background by the scene, rather than stretching the catalog artwork.

`japan-panorama.png` is a new opaque Fuji/valley/lake/cherry panorama. `Scenery/japan/ground-3.png` replaces the mushroom vignette with a clean transparent vermilion torii and mossy stone base. The existing fox, koi pond, wayside stone lantern and original catalog painting remain byte-identical. The pond size/footing and torii architectural scale are controlled in presentation code.

The old mushroom and preserved-asset hashes are archived in `artifacts/qa/kenji/japan-panorama-2026-09-23/`. Code, foreground fitting and simulator/device validation are documented separately in that QA directory and `docs/NEXT-RELEASE.md`.

After approving the generated torii, David explicitly allowed occasional road overlap, then requested a much larger, believable architectural scale relative to the rider. Its source PNG stays unchanged; presentation code controls size and a stable subset of raised placements. The initial generation prompt describes the originally intended below-road placement and is preserved verbatim as provenance. Final dimensions and placement validation are recorded with the native scenery QA.
