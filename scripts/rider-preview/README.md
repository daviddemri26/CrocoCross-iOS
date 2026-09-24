# Native rider preview

Run from the repository root on a Mac with a Metal/WindowServer session:

```sh
bash scripts/render-rider-preview.sh croco /tmp/rocco-preview
bash scripts/render-rider-preview.sh shiba /tmp/shiba-preview
bash scripts/render-rider-preview.sh croco /tmp/rocco-before --baseline
swift scripts/check-rocco-assets.swift
swift scripts/check-rocco-assets.swift --rider shiba
```

The harness compiles the production artwork loader and articulated renderer into a temporary native Mac app with only an AppKit image-name adapter. It renders neutral, wheelie, airborne, compressed landing, inverted and detached poses plus five sampled motion frames. It measures both palms, both soles and the common waist directly from the SpriteKit node transforms during 180 frames and two complete rotations through ±π. Contact tolerance is 1.5 mm for the hands and 0.1 mm for soles/waist. Torso motion cannot exceed its configured angular speed. The cached catalog image is also exported and its cache reuse checked.

`--baseline` reads Rocco's original renderer from Git HEAD without modifying the checkout, then renders the same six poses. Compare those PNGs with the current Rocco images. Source PNGs and manifests are never rewritten. Temporary build artifacts go to `/tmp`; generated QA outputs go only to the requested directory.

`contacts-and-bounds.json` records the measurements and pre-framing bounds. The preview camera fits each pose so the whole rider remains inspectable. These are native renderer checks and scripted poses, not physical-device play tests.

The asset validator preserves the old Rocco command and checks all eleven PNGs, dimensions, alpha, painted bounds, mandatory anchors, joint/calibration agreement, palm contacts, wheel dimensions, spoke holes, waist alignment, and both limb chains. Kenji's `rig.pelvisTravel`/`rig.torsoAngleTravel` must equal its presentation limits so the entire attached posture envelope is checked. Rocco retains its historical validator envelope and renderer limits for exact compatibility.

For `presentation.retainDetachPose: true`, the harness also checks release with active lean/shift filtering, follows independent physical body rotations/translations while the camera changes scale and origin, and checks new-run and reattachment resets. The captured body-local offsets affect artwork only. Existing Rocco defaults retain their exact legacy rendering.

Boots always meet the calf at their authored cuff pivot and the sole at the footpeg. `bootAngleOffset` sets the attached sole pitch while allowing the ankle to flex; Rocco defaults to zero. Optional `bootFollowsCalf` instead solves a combined calf-and-boot effective segment with exact cuff-axis alignment. The harness reports both cuff position error and boot rotation, and requires axis alignment only when that option is enabled.
