import Foundation

@main struct SceneryPresentationChecks {
    static func main() throws {
        let worlds = ["canyon", "japan", "highway", "jungle", "arctic", "mine", "sanfrancisco", "paris", "clouds"]
        var report: [[String: Any]] = []
        for world in worlds {
            for layer in SceneryLayer.allCases {
                for variant in 1...layer.variantCount {
                    let item = SceneryPresentation.forImage(world: world, layer: layer, variant: variant)
                    precondition(!item.name.isEmpty && item.clearance > 0 && item.skyScale > 0)
                    if layer != .sky {
                        precondition(item.width > 0 && item.width <= 3 && item.maxHeight > 0 && item.maxHeight <= 2)
                    }
                    report.append(["world": world, "layer": layer.rawValue, "variant": variant,
                                   "object": item.name, "widthMetres": item.width, "maxHeightMetres": item.maxHeight,
                                   "skyScale": item.skyScale, "followsSlope": item.followsSlope])
                }
            }
        }
        precondition(SceneryPresentation.catalog.count == 54 && report.count == 54)
        func ground(_ world: String, _ variant: Int) -> SceneryPresentation {
            .forImage(world: world, layer: .ground, variant: variant)
        }
        func sky(_ world: String, _ variant: Int) -> Double {
            SceneryPresentation.forImage(world: world, layer: .sky, variant: variant).skyScale
        }
        precondition(ground("jungle", 2).width < ground("jungle", 1).width * 0.3, "Frog vignette is too big relative to tapir")
        precondition(ground("mine", 2).width < ground("mine", 1).width * 0.3, "Mole vignette is too big relative to mine cart")
        precondition(sky("jungle", 2) < sky("jungle", 1) * 0.4, "Butterfly is too big relative to macaw")
        precondition(sky("mine", 2) < sky("mine", 1) * 0.6, "Moth is too big relative to bat")
        let lamp = SceneryPresentation.forImage(world: "mine", layer: .wayside, variant: 1)
        precondition(lamp.maxHeight * 1.12 < 0.6 && !lamp.followsSlope, "Handheld lantern dimensions or vertical alignment regressed")
        for world in ["japan", "paris"] {
            precondition(!SceneryPresentation.forImage(world: world, layer: .wayside, variant: 1).followsSlope)
        }
        print(String(decoding: try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self))
        fputs("PASS: 54 explicit image profiles, animal size relationships, portable lamp size and upright props\n", stderr)
    }
}
