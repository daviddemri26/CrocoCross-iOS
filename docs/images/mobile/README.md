# Current mobile screenshots

Captured September 13, 2026 on an **iPhone 17 simulator**, 1206 × 2622 pixels, from CrocoCross **1.0.0 (7)**. These screenshots show the complete native app: nine Endless rides and the Home screen.

The application and core sources match commit `e843dc5`, before the illustrated-button refresh. The images remain a record of that scenery version; see the main README for the current control artwork. A temporary XCTest routine, added only to an isolated copy of the UI test target, selected each world/rider, opened Endless and pressed the real throttle control. The application received its existing muted-audio and UI-testing launch arguments; the latter suppresses automatic Game Center authentication. No scene state, terrain, score or artwork was replaced for the captures.

The ten selected screenshots were inspected individually and copied without changing their pixels. They include the revised HUD, world-specific roads and foreground textures, current rider proportions, and the enlarged Paris building. The capture routine passed and the dedicated simulator was shut down afterward. These are simulator screenshots; the separate signed-device installation and launch are recorded in the project's validation history.

[captures.json](captures.json) records image dimensions and SHA-256 hashes. [source-manifest.json](source-manifest.json) records the app/core Swift files and PNGs used for the capture build. Screenshots inherit the project's [rights notice](../../../RIGHTS.md).
