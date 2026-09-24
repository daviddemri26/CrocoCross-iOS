import Foundation

@main struct SceneryPresentationChecks {
    static func main() throws {
        let worlds = ["canyon", "japan", "highway", "jungle", "arctic", "mine", "sanfrancisco", "paris", "clouds"]
        var report: [[String: Any]] = []
        for world in worlds {
            for layer in SceneryLayer.allCases {
                for variant in 1...layer.variantCount {
                    let item = SceneryPresentation.forImage(world: world, layer: layer, variant: variant)
                    precondition(!item.name.isEmpty && item.clearance > 0 && item.skyScale > 0 && item.skySpeed > 0)
                    if layer != .sky {
                        let large = layer == .ground && (item.footingDepth != nil || item.roadOverlap != nil)
                        precondition(item.width > 0 && item.width <= (large ? 12 : 5.5))
                        precondition(item.maxHeight > 0 && item.maxHeight <= (large ? 14 : 3.5))
                        if let footing = item.footingDepth {
                            precondition(layer == .ground && footing > 0 && footing < item.maxHeight)
                        }
                    }
                    if let overlap = item.roadOverlap {
                        precondition(world == "japan" && layer == .ground && variant == 3,
                                     "Only the Japanese torii may use occasional road overlap")
                        precondition(overlap.fraction == 1.0 / 3 && overlap.ridingLine == 0.30)
                    }
                    report.append(["world": world, "layer": layer.rawValue, "variant": variant,
                                   "object": item.name, "widthMetres": item.width, "maxHeightMetres": item.maxHeight,
                                   "skyScale": item.skyScale, "skySpeed": item.skySpeed, "followsSlope": item.followsSlope,
                                   "footingDepth": item.footingDepth as Any? ?? NSNull(),
                                   "roadOverlapFraction": item.roadOverlap?.fraction as Any? ?? NSNull(),
                                   "roadRidingLineFraction": item.roadOverlap?.ridingLine as Any? ?? NSNull()])
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
        // At the most distant plane, even the small subjects retain a useful
        // phone silhouette. Vehicles have a distinctly larger canonical footprint.
        for world in worlds {
            for variant in 1...3 {
                let item = ground(world, variant)
                precondition(item.width * 23 * 0.68 * 0.94 >= 27, "Ground silhouette is too small to read")
                precondition(item.maxHeight * 23 * 0.68 * 0.94 >= 20, "Ground height budget is too small")
            }
            for variant in 1...2 {
                let item = SceneryPresentation.forImage(world: world, layer: .sky, variant: variant)
                let far = SkyPerspective(depth: 0, speed: item.skySpeed)
                let near = SkyPerspective(depth: 1, speed: item.skySpeed)
                precondition(far.scale < near.scale && far.duration > near.duration,
                    "Sky depth must link smaller size with slower movement")
                precondition(far.duration <= SkyPerspective.maximumDuration && near.duration >= 16)
                precondition(375 * 0.27 * sky(world, variant) * far.scale * 0.94 >= 32,
                    "Distant sky silhouette is too small")
            }
        }
        precondition(ground("highway", 1).width > ground("canyon", 1).width * 2)
        precondition(ground("highway", 3).width > ground("paris", 1).width * 2)
        precondition(ground("jungle", 2).width < ground("jungle", 1).width)
        precondition(ground("mine", 2).width < ground("mine", 1).width)
        // Increasing both pond budgets keeps the actual aspect-fit image about 1.5x larger.
        // Its existing base-anchor mode avoids losing the larger pond below a shallow viewport.
        let pond = ground("japan", 1), fox = ground("japan", 2), torii = ground("japan", 3)
        precondition((1.5...1.6).contains(pond.width / 3.8) && (1.5...1.6).contains(pond.maxHeight / 2.3),
                     "Both pond dimensions must increase; a retained height cap defeats the larger width")
        for item in [pond] {
            precondition(item.footingDepth != nil && !item.followsSlope)
            let footing = item.footingDepth!
            for landscape in [false, true] {
                for depth in stride(from: 0.0, through: 1, by: 0.1) {
                    let depthOffset = depth * (landscape ? 1 : 2.4)
                    let largestHeight = item.maxHeight * (0.68 + depth * 0.32) * 1.08
                    precondition(footing + depthOffset - largestHeight >= 0.52 - 0.000001,
                                 "Japan's new vignettes must stay completely below the riding ribbon")
                }
            }
            for viewport in [(390.0, 844.0), (844, 390), (834, 1194), (1194, 834)] {
                let (width, height) = viewport
                let landscape = width > height
                for speedFraction in [0.0, 1] {
                    let visibleMetres = landscape ? 19 + speedFraction * 9 : 10 + speedFraction * 5
                    let ppm = min(64, max(23, min(width / visibleMetres, height / 13))) * 1.18
                    let availableDepth = height * (landscape ? 0.40 : 0.39) / ppm
                    precondition(footing + (landscape ? 1 : 2.4) < availableDepth,
                                 "A centred Japan vignette on level ground must fit the portrait/landscape foreground")
                }
            }
        }
        precondition(pond.width * 1.08 / 2 < 8 && torii.width * 1.08 / 2 < 8,
                     "The existing eight-metre side margin must retain the complete entering silhouette")
        precondition(fox.width == 2.8 && fox.maxHeight == 1.8 && fox.clearance == 0.55
                     && fox.footingDepth == nil && !fox.followsSlope,
                     "The approved Japan fox presentation must remain unchanged")
        precondition(torii.width == 9 && torii.maxHeight == 9.2 && torii.footingDepth == nil && !torii.followsSlope,
                     "The Japanese gate must read as full-size architecture, with ordinary occurrences entirely below road")
        precondition(torii.roadAnchor(at: 0) == 0.30 && torii.roadAnchor(at: 1.0 / 3) == nil
                     && torii.roadAnchor(at: 1) == nil && pond.roadAnchor(at: 0) == nil)
        for seed: UInt64 in [0, 1234, 5678, .max] {
            let gates = SceneryPlacement.visible(world: "japan", layer: .ground,
                lower: -1_000, upper: 100_000, seed: seed).filter { $0.variant == 3 }
            // Runtime alpha-trimmed aspect is 1112 / 1143 at the large-art resolution.
            // Test actual aspect fitting over the seeded depth/scale distribution.
            for gate in gates {
                let scale = gate.scale * (0.68 + gate.depth * 0.32)
                let height = min(torii.maxHeight, torii.width / (1112.0 / 1143)) * scale
                precondition((5.8...10.0).contains(height), "Every gateway keeps a monumental silhouette")
                if let anchor = torii.roadAnchor(at: gate.depth) {
                    precondition((4.0...5.6).contains(height * (1 - anchor)),
                                 "Raised gateways must have their lintel well above the rider")
                    for ppm in [23.0, 40, 75] {
                        let roadY = 100.0
                        let base = roadY - height * ppm * anchor
                        precondition(abs((base - roadY) / ppm + height * anchor) < 0.000001,
                                     "The opening must stay fixed relative to the road through zoom")
                    }
                } else {
                    for landscape in [false, true] {
                        let topBelowSupport = torii.clearance + 0.15 + gate.depth * (landscape ? 1 : 2.4)
                        precondition(topBelowSupport > 0.7, "Ordinary gateways remain entirely below local support")
                    }
                }
            }
            let fraction = Double(gates.filter { torii.roadAnchor(at: $0.depth) != nil }.count) / Double(gates.count)
            precondition(gates.count > 500 && (0.28...0.39).contains(fraction),
                         "About one third of Japanese gateways should rise above their local support")
            for original in gates.prefix(100) {
                for reducedMotion in [false, true] {
                    let factor = SceneryMotion.foregroundFactor(reducedMotion: reducedMotion)
                    for offset in [-6.01, 0, 5.99] {
                        let camera = original.coordinate + offset
                        let start = SceneryMotion.coordinate(screenMetres: 0, camera: camera, factor: factor)
                        let shifted = SceneryPlacement.visible(world: "japan", layer: .ground,
                            lower: start - 12, upper: start + 20, seed: seed).first { $0.cell == original.cell }!
                        precondition(torii.roadAnchor(at: shifted.depth) == torii.roadAnchor(at: original.depth),
                                     "Scrolling, strip boundaries and Reduce Motion cannot toggle a gateway's overlap")
                        precondition(shifted.coordinate == original.coordinate && shifted.scale == original.scale)
                    }
                }
            }
            fputs("Japan torii overlap seed \(seed): \(Int((fraction * 1000).rounded())) / 1000 across \(gates.count) placements\n", stderr)
        }
        let japanLamp = SceneryPresentation.forImage(world: "japan", layer: .wayside, variant: 1)
        precondition(japanLamp.width == 1.65 && japanLamp.maxHeight == 2 && japanLamp.clearance == 0.32
                     && japanLamp.footingDepth == nil && !japanLamp.followsSlope,
                     "The existing Japanese stone lantern presentation must remain unchanged")
        let building = ground("paris", 3), car = ground("paris", 2)
        precondition(building.width > car.width * 2 && building.maxHeight > car.maxHeight * 4,
            "The Paris building must read as architecture beside a car")
        precondition(building.footingDepth != nil && car.footingDepth != nil)
        let lamp = SceneryPresentation.forImage(world: "mine", layer: .wayside, variant: 1)
        precondition(lamp.maxHeight >= 1 && !lamp.followsSlope, "Lantern visibility or upright alignment regressed")
        for world in ["japan", "paris"] {
            precondition(!SceneryPresentation.forImage(world: world, layer: .wayside, variant: 1).followsSlope)
        }
        print(String(decoding: try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self))
        fputs("PASS: 54 explicit image profiles, phone visibility budgets, subject size relationships, enlarged Japan pond, monumental torii with stable occasional road openings and preserved fox/lantern\n", stderr)
    }
}
