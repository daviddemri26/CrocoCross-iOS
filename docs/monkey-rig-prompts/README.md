# Milo — generated source artwork

September 26, 2026. The owner requested a stylish monkey with baseball cap and sunglasses on a modern seated electric scooter, with independent articulation matching the character creation guide.

The built-in `image_gen` tool generated the initial identity concept and each isolated transparent PNG. No external scooter brand, photo or third-party character reference was used. Prompts are the adjacent `.txt` files; `generations.json` records exact output paths, reference image and the rejected first calf. Final selected PNG dimensions and SHA-256 values are in `assets.json`. Source outputs remain intact; alpha was checked through native compositing rather than inferred from the black image preview.

The first calf was rejected because it included a bent thigh. `monkey-calf-v2.txt` requests a straight isolated shin with a rounded knee overlap and narrow fur ankle. Its output is the production `monkey-calf.png`.

The head/torso, hip/tail, upper arm, forearm/hand, thigh, calf and sneaker are independent parts. Chassis, wheel, fork/mudguard and swingarm are also separate. Proportions and joint calibration belong to `GameAssets/MonkeyRig/manifest.json`, not to the simulation. The original Rocco and Kenji art remains unchanged. See [character guide](../CHARACTER-CREATION.md) and [Milo integration](../MILO.md).
