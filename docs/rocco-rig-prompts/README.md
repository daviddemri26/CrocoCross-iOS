# Rocco articulated artwork

The original `croco-rider.png` remains unchanged. Derived transparent layers are prepared with the built-in imagegen tool for the Box2D Rocco rig. Each source is inspected before selection; final generated files are copied intact into `App/Resources/GameAssets/RoccoRig/`. Pivots, scales and limb endpoints belong to the renderer manifest, not to destructive raster edits.

Eleven active layers: bare bike chassis (no wheels or suspension links), front fork, rear swingarm, torso/head, pelvis/tail, upper arm, forearm/glove, thigh, calf, independent ankle boot, and one illustrated wheel used for both axles. The owner approved improvements to style, details and proportions. The new drawing preserves the green crocodile, orange/white/black racing outfit and orange motorcycle identity, with complete joint contours and clearer clothing details.

Exact prompts are stored alongside this file. [generations.json](generations.json) records generated source filenames; [assets.json](assets.json) records SHA-256 and size of every selected PNG. The initial `rocco-bike` generation was edited to remove fixed suspension attachments; the selected project file `rocco-bike.png` corresponds to prompt `rocco-bike-v2.txt`. Generated originals remain intact at the tool's output location. No raster pixel editing was used.

Each sprite has its own normalized pivots, limb endpoints and physical scale in `App/Resources/GameAssets/RoccoRig/manifest.json`, loaded by `App/Scene/RoccoArtwork.swift`. `RoccoRig` uses independent bike/wheel poses and bounded, smoothed rider poses while attached; detached rider parts follow their physical poses. It connects the decorative limbs through two-segment inverse kinematics. Arms and legs are visual appendages; pelvis and torso/head own the rider's collisions. Suspension links follow the actual wheel centres without changing chassis scale.

The original generated `rocco-shin.png` (combined lower leg and boot) is retained as a source reference but is not used by the final rig. Two imagegen derivatives separate the ankle, so the knee can bend forward while the boot sole rests on the footpeg. This adds a visual joint, not another physical body.

Build 9 moves the thigh root into the upper hip, recalibrates the limb lengths and footpeg/shoulder positions, and widens the upper arms by 65% without moving joint endpoints. A native SpriteKit crop hides the pelvis layer’s redundant painted thigh extension. The waist anchors stay joined through bounded torso lean. These are manifest/renderer changes; all selected PNGs and their recorded hashes remain unchanged.

Build 10 moves the proximal pivots inside the shoulder and upper-thigh artwork, raises the torso shoulder attachment, and raises/backs up the hip attachment. Limb lengths are recalibrated around those joint centres; the far arm is tucked inside the silhouette. See the [character creation guide](../CHARACTER-CREATION.md) for the shared anatomical and validation rules.
