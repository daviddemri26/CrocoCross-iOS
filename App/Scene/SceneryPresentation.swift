import Foundation

/// Art direction for every image. Ground/wayside dimensions describe the complete
/// painted vignette in world metres. Ground images receive a stable depth scale;
/// small subjects retain readable silhouettes, while vehicles remain larger.
struct SceneryPresentation {
    let name: String
    var width: Double
    var maxHeight: Double
    var clearance: Double = 0.32
    var skyScale: Double = 1
    var skySpeed: Double = 1
    var skyAltitude: Double = 0.64
    var followsSlope: Bool = false
    var roadInset: Double = 0.035
    /// Distance from the riding line to the painted base, in world metres.
    /// Tall foreground subjects grow upward from this footing and may hide the rider.
    /// Nil keeps a small vignette entirely below the road.
    var footingDepth: Double? = nil
    /// A stable subset of gateways spans the road with its transparent opening.
    /// Depth already belongs to the seeded placement; no new randomness.
    var roadOverlap: RoadOverlap? = nil

    struct RoadOverlap {
        let fraction: Double
        /// Height of the riding line inside the trimmed artwork, measured from its base.
        let ridingLine: Double
    }

    func roadAnchor(at depth: Double) -> Double? {
        guard let overlap = roadOverlap, depth < overlap.fraction else { return nil }
        return overlap.ridingLine
    }

    static func forImage(world: String, layer: SceneryLayer, variant: Int) -> Self {
        let key = "\(world)/\(layer == .wayside ? "wayside" : "\(layer.rawValue)-\(variant)")"
        guard let definition = catalog[key] else {
            preconditionFailure("Missing scenery art direction: \(key)")
        }
        return definition
    }

    static let catalog: [String: Self] = [
        "canyon/ground-1": .init(name: "Ammonite sur le sable", width: 1.9, maxHeight: 1.4, clearance: 0.55),
        "canyon/ground-2": .init(name: "Fennec sur un rocher", width: 2.7, maxHeight: 2.0, clearance: 0.55),
        "canyon/ground-3": .init(name: "Géode d’améthyste ouverte", width: 2.2, maxHeight: 1.9, clearance: 0.55),
        "canyon/sky-1": .init(name: "Condor", width: 0, maxHeight: 0, skyScale: 1),
        "canyon/sky-2": .init(name: "Avion rétro crème et rouge", width: 0, maxHeight: 0, skyScale: 1.08, skySpeed: 1.14),
        "canyon/wayside": .init(name: "Cactus fleuri", width: 1.8, maxHeight: 2.2),

        "japan/ground-1": .init(name: "Bassin de carpes koï", width: 5.8, maxHeight: 3.5, clearance: 0.55, footingDepth: 3.3),
        "japan/ground-2": .init(name: "Renard endormi sur la mousse", width: 2.8, maxHeight: 1.8, clearance: 0.55),
        "japan/ground-3": .init(name: "Torii vermillon sur pierres moussues", width: 9.0, maxHeight: 9.2, clearance: 0.55, roadOverlap: .init(fraction: 1.0 / 3, ridingLine: 0.30)),
        "japan/sky-1": .init(name: "Hirondelle", width: 0, maxHeight: 0, skyScale: 0.72),
        "japan/sky-2": .init(name: "Cerf-volant japonais", width: 0, maxHeight: 0, skyScale: 1, skySpeed: 0.9),
        "japan/wayside": .init(name: "Lanterne japonaise en pierre", width: 1.65, maxHeight: 2.0),

        "highway/ground-1": .init(name: "Caravane rétro", width: 6.0, maxHeight: 3.6, clearance: 0.55, footingDepth: 0.65),
        "highway/ground-2": .init(name: "Coyote endormi", width: 2.8, maxHeight: 1.9, clearance: 0.55),
        "highway/ground-3": .init(name: "Pickup et citrouilles", width: 5.6, maxHeight: 3.4, clearance: 0.55, footingDepth: 0.65),
        "highway/sky-1": .init(name: "Avion léger crème et orange", width: 0, maxHeight: 0, skyScale: 1.08, skySpeed: 1.14),
        "highway/sky-2": .init(name: "Rapace brun", width: 0, maxHeight: 0, skyScale: 1),
        "highway/wayside": .init(name: "Pneus anciens et fleurs jaunes", width: 2.15, maxHeight: 1.5, followsSlope: true, roadInset: 0.005),

        "jungle/ground-1": .init(name: "Tapir endormi", width: 3.2, maxHeight: 2.4, clearance: 0.55),
        "jungle/ground-2": .init(name: "Grenouille sur une feuille", width: 1.9, maxHeight: 1.7, clearance: 0.55),
        "jungle/ground-3": .init(name: "Cascade et bassin tropical", width: 5.5, maxHeight: 5.2, clearance: 0.55, footingDepth: 1.4),
        "jungle/sky-1": .init(name: "Ara rouge, bleu et jaune", width: 0, maxHeight: 0, skyScale: 1),
        "jungle/sky-2": .init(name: "Petit papillon bleu", width: 0, maxHeight: 0, skyScale: 0.6, skySpeed: 0.93, skyAltitude: 0.63),
        "jungle/wayside": .init(name: "Fougères et broméliacée", width: 2.15, maxHeight: 1.4, followsSlope: true),

        "arctic/ground-1": .init(name: "Renard polaire sur la neige", width: 2.8, maxHeight: 1.8, clearance: 0.55),
        "arctic/ground-2": .init(name: "Phoque sur la banquise", width: 3.0, maxHeight: 1.9, clearance: 0.55),
        "arctic/ground-3": .init(name: "Cristaux de glace dressés", width: 4.0, maxHeight: 4.6, clearance: 0.55, footingDepth: 0.85),
        "arctic/sky-1": .init(name: "Harfang blanc", width: 0, maxHeight: 0, skyScale: 1),
        "arctic/sky-2": .init(name: "Petit oiseau polaire", width: 0, maxHeight: 0, skyScale: 0.72),
        "arctic/wayside": .init(name: "Cairn enneigé", width: 1.9, maxHeight: 1.3, followsSlope: true),

        "mine/ground-1": .init(name: "Wagonnet de minerai", width: 3.6, maxHeight: 2.8, clearance: 0.55, footingDepth: 0.70),
        "mine/ground-2": .init(name: "Taupe sur une motte", width: 1.9, maxHeight: 1.4, clearance: 0.55),
        "mine/ground-3": .init(name: "Géode turquoise ouverte", width: 2.3, maxHeight: 2.0, clearance: 0.55),
        "mine/sky-1": .init(name: "Petite chauve-souris", width: 0, maxHeight: 0, skyScale: 0.82),
        "mine/sky-2": .init(name: "Petit papillon de nuit", width: 0, maxHeight: 0, skyScale: 0.6, skySpeed: 0.93, skyAltitude: 0.68),
        "mine/wayside": .init(name: "Lanterne portative sur pierres", width: 1.05, maxHeight: 1.3, roadInset: 0.01),

        "sanfrancisco/ground-1": .init(name: "Otarie sur un rocher", width: 3.1, maxHeight: 2.6, clearance: 0.55),
        "sanfrancisco/ground-2": .init(name: "Voilier sur la baie", width: 6.4, maxHeight: 6.8, clearance: 0.55, footingDepth: 1.2),
        "sanfrancisco/ground-3": .init(name: "Ferry de la baie", width: 8.4, maxHeight: 4.4, clearance: 0.55, footingDepth: 1.1),
        "sanfrancisco/sky-1": .init(name: "Goéland blanc", width: 0, maxHeight: 0, skyScale: 1.04),
        "sanfrancisco/sky-2": .init(name: "Pélican brun", width: 0, maxHeight: 0, skyScale: 1.08),
        "sanfrancisco/wayside": .init(name: "Bollard, cordage et bouée", width: 1.35, maxHeight: 1.1, roadInset: 0.10),

        "paris/ground-1": .init(name: "Chat sur des livres", width: 1.9, maxHeight: 1.45, clearance: 0.55),
        "paris/ground-2": .init(name: "2CV française bleue", width: 4.2, maxHeight: 2.3, clearance: 0.55, footingDepth: 0.6),
        "paris/ground-3": .init(name: "Immeuble haussmannien", width: 11.0, maxHeight: 13.0, clearance: 0.55, footingDepth: 3.0),
        "paris/sky-1": .init(name: "Pigeon gris lointain", width: 0, maxHeight: 0, skyScale: 0.75, skySpeed: 0.96),
        "paris/sky-2": .init(name: "Pigeon gris", width: 0, maxHeight: 0, skyScale: 0.85),
        "paris/wayside": .init(name: "Rosier en pot et arrosoir", width: 1.4, maxHeight: 1.5),

        "clouds/ground-1": .init(name: "Baleine endormie sur un nuage", width: 6.0, maxHeight: 4.2, clearance: 0.55, footingDepth: 1.0),
        "clouds/ground-2": .init(name: "Îlot flottant fleuri", width: 5.6, maxHeight: 4.8, clearance: 0.55, footingDepth: 1.2),
        "clouds/ground-3": .init(name: "Lune dorée et étoiles sur un nuage", width: 3.5, maxHeight: 3.1, clearance: 0.55),
        "clouds/sky-1": .init(name: "Montgolfière pastel", width: 0, maxHeight: 0, skyScale: 1.08, skySpeed: 0.85),
        "clouds/sky-2": .init(name: "Poisson volant pastel", width: 0, maxHeight: 0, skyScale: 1),
        "clouds/wayside": .init(name: "Trois fleurs sur un petit nuage", width: 1.9, maxHeight: 1.9, followsSlope: true),
    ]
}
