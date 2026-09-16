# Illustrated handlebar buttons

Updated September 13, 2026.

The controls use realistic painted motorcycle parts viewed from the rider's position. The right throttle grip has its silver end cap on the right; the left grip has its end cap on the left and a curved silver brake lever anchored at the inner right. Lime and orange accents retain the game's control colors. Neither image contains arrows, text or a button rim. Button names remain available to VoiceOver.

| Control | Original PNG | Native touch size |
| --- | --- | --- |
| Right throttle | [control-throttle.png](../App/Resources/GameAssets/control-throttle.png) | 112 pt portrait / 124 pt landscape |
| Left brake | [control-brake.png](../App/Resources/GameAssets/control-brake.png) | 112 pt portrait / 124 pt landscape |

## Interaction

Hold for full power; lift to release. App input is a Boolean mapped to exactly 0 or 1 in `GameSession`. The right/left controls accelerate/brake through the tires in contact. As either wheel lifts, backward/forward rider balance blends in progressively; both directions remain available on either wheel and in flight. Forward balance is stronger while the rear supports a raised front wheel; right-button and fully airborne balance retain their previous strength. The buttons work independently and can be held together. Sliding never changes strength or button position. There is no slider, percentage, floating control or adjustable accessibility trait. VoiceOver double-tap toggles a full hold/release. Pause, cancellation, recovery, reset and teardown clear input immediately. The engine's internal continuous input representation is unchanged.

The dark teal surface, metallic bevel and accent ring are drawn with Core Animation layers. A press compresses the visual face to 93.5% with a spring and emits one soft 0.32-second ring ripple. During a hold, the rim pulses from 1 to 0.58 opacity over a 1.8-second cycle. Release rebounds to its resting scale and stops the pulse; cancellation/reset removes all interaction animations. The touch frame never scales. Reduce Motion replaces all movement with immediate color feedback. These effects never delay or alter simulation input.

## Validation

The final native iPhone test run passes both the control workflow and real life-loss/recovery (two tests, zero failures). The corresponding iPad landscape control workflow passes. These checks exercise acceleration, dragging then lifting, fixed button geometry, braking, pause/resume and recovery. An isolated UIKit/SwiftUI host uses the unchanged production control source and passes 25 additional checks for touch ownership, simultaneous holds, cancellation, VoiceOver, reset/teardown, animation lifecycle, absence of visible labels and Reduce Motion.

The [current iPhone capture](images/controls-iphone.png) is an intact 1206 × 2622 screenshot from the actual app using real UI/pedal input and muted audio. Native iPhone/iPad captures, the component checks, hashes and logs are retained locally under `artifacts/image-buttons/final/`. These are simulator checks, not physical-device gameplay validation.

## Artwork provenance

Created with the built-in imagegen tool. Selected 1254 × 1254 transparent PNGs were inspected and copied intact. All four corners are transparent; the left lever/grip gap has transparent space. The selected files match the bundled application byte for byte. No external pixel, color or alpha edits were used. Intermediate painted checkerboards and arrow-bearing versions were rejected; targeted built-in edits removed arrows and extracted genuine transparency. Source square canvas and original image proportions are preserved by aspect-fit rendering.

### Right handlebar

Source: `/Users/daviddemri/.codex/generated_images/01a09902-c73c-7452-9170-1133530d18c5/exec-30ebc459-865e-4a31-8f91-a8a048bb822b.png`.

SHA-256: `1d225d6b81b598dcd01136e33c29783613748ced88618fdbb5ba935a0c3025be`.

### Left handlebar

Source: `/Users/daviddemri/.codex/generated_images/01a09902-c73c-7452-9170-1133530d18c5/exec-639743f1-432b-4446-b045-a98e5e69e1cf.png`.

SHA-256: `ba1718c1f72c0c52f236c73a0f2b30e1d30793098ab5ecb779eb7b0afed763f0`.

### Right-handlebar generation

```text
Use case: stylized-concept. Asset type: ONE isolated motorcycle right-hand handlebar icon for the accelerator button of a premium painted mobile game. Rider's point of view, looking down at their own RIGHT handlebar. Orientation is essential: the short INNER handlebar shaft enters from the LEFT, the lime-green cylindrical rubber grip extends horizontally toward the RIGHT, and its closed silver OUTER END CAP is on the FAR RIGHT. Absolutely NOT the opposite orientation. A single beautiful throttle grip with five broad dark charcoal rubber grooves, lime-green ribs and collars, silver-grey handlebar stem on its LEFT, small brushed silver end cap on its RIGHT. A tiny curved lime twist arrow sits above the grip, simple and elegant. Polished hand-painted motorcycle illustration with softly brushed steel, supple matte rubber, restrained dimensional shading and upper-left highlights; not a technical diagram, not a photo. The shape is complete and centred, width around 80 percent of square canvas, with clear margin around all parts. Intended to display at 75 points wide inside a circular dark teal UI button; no button or circle should be painted here. Background MUST be genuine empty transparent alpha (PNG), no visible pixels outside the isolated handlebar and arrow. No disc, brake lever, left-hand handlebar, motorcycle body, hands, fingers, text, letters, numbers, logo, labels, rim, plaque, medallion, background color, floor, glow, cast shadow or checkerboard artwork. One finished transparent PNG at least1024x1024.
```

### Remove the throttle arrow

```text
Use case: precise-object-edit. Image 1 is the EDIT TARGET. Remove ONLY the floating curved lime-green arrow above this right-hand throttle grip. Replace the entire arrow and its halo with genuine transparent PNG alpha. Keep the motorcycle grip itself unchanged: exact shape, brushed silver stem entering from the LEFT, lime/dark rubber cylindrical grip extending RIGHT, closed silver end cap at FAR RIGHT, orientation, proportions, lighting and all material details. No arrows, text, symbols, diagrams, gauges, circle, rim or backdrop. A minimum-realistic isolated right handlebar as seen from the rider's position. Preserve true transparent alpha around every part of the grip and in the four corners, never paint checkerboard pixels. Complete original square canvas. Only remove the arrow.
```

### Matching left grip and brake lever

```text
Use case: precise-object-edit. Image 1 is the STYLE AND MATERIAL REFERENCE and edit starting point for a matching CrocoCross LEFT motorcycle handlebar with its brake lever. Make ONE corresponding left-hand grip, from the rider's point of view. Orientation MUST be opposite to the reference: closed silver OUTER END CAP at the FAR LEFT; charcoal rubber grip extends toward the LEFT from an INNER metal clamp and short handlebar stem at the RIGHT. Add its recognizable realistic hand BRAKE LEVER: one graceful long curved brushed-silver lever, mounted on a pivot at the INNER RIGHT, sweeping LEFT in front of and slightly ABOVE the black rubber grip, ending in a small rounded ball near the outer LEFT. The lever must be visibly separate from the grip with a generous clean transparent gap so it reads at mobile size. Mechanical assembly is plausible and simple: one grip, one lever, one small right-side pivot/clamp. No brake disc or caliper. Replace bright lime accents with restrained warm burnt-orange collars/ribs around otherwise dark charcoal rubber to identify braking while retaining realistic materials. Match the reference's high-quality painted semi-realistic motorcycle steel/rubber, upper-left lighting and shape/detail level. NO arrow at all, no floating symbols, no text or labels. Remove the green arrow from the reference. Entire handlebar-and-lever group isolated on genuine transparent PNG alpha, same square canvas, centred complete with 5% or more empty transparent margin, no background pixels or checkerboard art. No circle, button rim, medallion, hands, people, other motorcycle parts or scenery. Front/downward rider view; show the LEFT handlebar, not a right grip.
```

### Transparent extraction for each selected image

```text
Use case: background-extraction. Remove only the painted grey-and-white checkerboard from the supplied motorcycle handlebar image. Make it GENUINELY TRANSPARENT PNG ALPHA, with alpha=0 outside the handlebar. The checkerboard pixels are an unwanted background, not transparency. Keep the entire isolated mechanical object exactly unchanged: orientation, shape, silver metal, rubber grooves, colored accents, all proportions and lighting. Preserve complete square canvas. Also make the visible empty gap between any brake lever and grip transparent. NO new arrows, text, symbols, rims, button backgrounds, cast shadows or other additions. Do not paint checkerboard, white or black pixels around the object. Return this same intact handlebar with a true alpha-transparent background.
```
