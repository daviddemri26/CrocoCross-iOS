# Rider proportions and camera framing

Updated September 13, 2026.

The nine riders are cosmetic choices using the same 1.58 m physical wheelbase and 0.32 m collision-wheel radius. Artwork scales uniformly from its measured axle centres; the canvas width is not a size reference. This preserves source aspect ratios, shared collision behaviour and natural silhouette differences such as Rocco's tail or Pinky's neck. No rider PNG was resized or replaced in this pass.

## Visible sizes

Approximate level-ground silhouette bounds include visible artwork and generated wheels where applicable, excluding transparent canvas margins. These are presentation measurements, not separate collision bodies. The point-size column uses the 402 pt portrait view at 22 m/s (26.8 pt/m). Dimensions during jumps change with the bike's angle.

| Rider | Visible width × height, m | Fast portrait width × height, pt |
| --- | --- | --- |
| Rocco | 2.67 × 1.63 | 71.6 × 43.7 |
| Kenji | 2.24 × 1.56 | 60.1 × 41.9 |
| Duke | 2.25 × 1.42 | 60.2 × 38.1 |
| Axel | 2.30 × 1.65 | 61.6 × 44.2 |
| Bjorn | 2.27 × 1.69 | 60.8 × 45.2 |
| Pinky | 2.18 × 1.83 | 58.5 × 49.0 |
| Rio | 2.38 × 1.81 | 63.7 × 48.4 |
| Bandit | 2.33 × 1.62 | 62.5 × 43.3 |
| Bubbles | 2.41 × 1.68 | 64.5 × 45.0 |

Kenji's painted rear tyre extends about 0.54 pt below the nominal line at this fast scale, and about 3 pt in the largest home preview. Native visual inspection accepted its slight overlap with the painted road lip; changing the shared cosmetic-radius offset would lift the front tyre unnecessarily.

## Zoom and framing

- Gameplay zoom depends on viewport and speed, identically for all riders. At 402 × 874 pt, the camera moves smoothly from 40.2 pt/m stopped to 26.8 pt/m at 22 m/s. Landscape height limits can hold the scale steady when the view already provides sufficient distance ahead.
- Preview scale also respects available height: the wheelbase is capped by the space above the road, allowing 1.2 wheelbases for the tallest silhouette and 24 pt of headroom. The 667 × 375 preview now uses a 120.625 pt wheelbase; the 568 × 320 preview uses 100 pt. Ordinary portrait and large tablet previews retain their prior scale.
- Preview sky actors are hidden because their passage through the enlarged hero can look like extra vehicle parts. The painted sky remains visible; gameplay sky actors retain their depth and motion.
- Camera position and scale hold through a crash. The first respawn frame resets following to the new checkpoint immediately, without resetting the background's course origin.
- During high jumps, the complete rig stays below a reserved top margin (20% of view height, capped at 80 pt landscape / 120 pt portrait). The final camera projection is shared with terrain, decorations, effects and both wheels. No zoom or simulation parameters change for this guard.

## Evidence

[81 native views and comparisons](../artifacts/rider-zoom-review/index.html), [validation report](../artifacts/rider-zoom-review/validation.md), [source geometry audit](../artifacts/rider-zoom-review/geometry-audit/review.md). The controlled native scene harness has no audio or HUD. Physical-device and full SwiftUI interaction testing are separate from these checks.
