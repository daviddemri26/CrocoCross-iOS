import Foundation

/// Art direction for every image. Ground/wayside dimensions describe the complete
/// painted vignette in metres; sky scale describes a distant silhouette on screen.
struct SceneryPresentation {
    let name: String
    var width: Double
    var maxHeight: Double
    var clearance: Double = 0.32
    var skyScale: Double = 1
    var skyAltitude: Double = 0.76
    var followsSlope: Bool = false
    var roadInset: Double = 0.035

    static func forImage(world: String, layer: SceneryLayer, variant: Int) -> Self {
        let key = "\(world)/\(layer == .wayside ? "wayside" : "\(layer.rawValue)-\(variant)")"
        guard let definition = catalog[key] else {
            preconditionFailure("Missing scenery art direction: \(key)")
        }
        return definition
    }

    static let catalog: [String: Self] = [
        "canyon/ground-1": .init(name: "Ammonite enchâssée dans le grès", width: 1.45, maxHeight: 1.05),
        "canyon/ground-2": .init(name: "Fennec endormi dans son terrier", width: 1.1, maxHeight: 0.6, clearance: 0.24),
        "canyon/ground-3": .init(name: "Géode d’améthyste dans la roche", width: 1.4, maxHeight: 1.1),
        "canyon/sky-1": .init(name: "Condor", width: 0, maxHeight: 0, skyScale: 0.8),
        "canyon/sky-2": .init(name: "Avion rétro crème et rouge", width: 0, maxHeight: 0, skyScale: 0.9),
        "canyon/wayside": .init(name: "Cactus fleuri", width: 1.05, maxHeight: 1.3),

        "japan/ground-1": .init(name: "Petit pot en céramique enfoui", width: 0.85, maxHeight: 0.8),
        "japan/ground-2": .init(name: "Renard endormi dans un terrier forestier", width: 1.2, maxHeight: 1.0, clearance: 0.24),
        "japan/ground-3": .init(name: "Recoin moussu avec champignons et fougère", width: 1.05, maxHeight: 0.85, clearance: 0.22),
        "japan/sky-1": .init(name: "Hirondelle", width: 0, maxHeight: 0, skyScale: 0.42),
        "japan/sky-2": .init(name: "Cerf-volant japonais", width: 0, maxHeight: 0, skyScale: 0.8),
        "japan/wayside": .init(name: "Lanterne japonaise en pierre", width: 1.0, maxHeight: 1.2),

        "highway/ground-1": .init(name: "Enjoliveur rétro partiellement enfoui", width: 0.7, maxHeight: 0.7),
        "highway/ground-2": .init(name: "Coyote endormi dans un abri rocheux", width: 1.4, maxHeight: 1.05, clearance: 0.24),
        "highway/ground-3": .init(name: "Fer à cheval dans la terre", width: 0.45, maxHeight: 0.4),
        "highway/sky-1": .init(name: "Avion léger crème et orange", width: 0, maxHeight: 0, skyScale: 0.9),
        "highway/sky-2": .init(name: "Rapace brun", width: 0, maxHeight: 0, skyScale: 0.82),
        "highway/wayside": .init(name: "Pneus anciens et fleurs jaunes", width: 1.25, maxHeight: 0.9, followsSlope: true, roadInset: 0.005),

        "jungle/ground-1": .init(name: "Tapir endormi à l’abri des racines", width: 2.7, maxHeight: 1.85, clearance: 0.24),
        "jungle/ground-2": .init(name: "Petite grenouille dans un recoin végétal", width: 0.5, maxHeight: 0.4, clearance: 0.18),
        "jungle/ground-3": .init(name: "Source dans une ouverture rocheuse", width: 1.5, maxHeight: 1.6),
        "jungle/sky-1": .init(name: "Ara rouge, bleu et jaune", width: 0, maxHeight: 0, skyScale: 0.82),
        "jungle/sky-2": .init(name: "Petit papillon bleu", width: 0, maxHeight: 0, skyScale: 0.25, skyAltitude: 0.63),
        "jungle/wayside": .init(name: "Fougères et broméliacée", width: 1.25, maxHeight: 0.8, followsSlope: true),

        "arctic/ground-1": .init(name: "Renard polaire dans son abri de neige", width: 1.3, maxHeight: 0.95, clearance: 0.24),
        "arctic/ground-2": .init(name: "Jeune phoque dans une ouverture de banquise", width: 1.65, maxHeight: 1.15),
        "arctic/ground-3": .init(name: "Cristaux dans la paroi de glace", width: 1.7, maxHeight: 1.5),
        "arctic/sky-1": .init(name: "Harfang blanc", width: 0, maxHeight: 0, skyScale: 0.9),
        "arctic/sky-2": .init(name: "Petit oiseau polaire", width: 0, maxHeight: 0, skyScale: 0.46),
        "arctic/wayside": .init(name: "Cairn enneigé", width: 1.1, maxHeight: 0.75, followsSlope: true),

        "mine/ground-1": .init(name: "Wagonnet sur rails dans une petite galerie", width: 2.65, maxHeight: 1.7),
        "mine/ground-2": .init(name: "Petite taupe dans son terrier", width: 0.62, maxHeight: 0.48, clearance: 0.24),
        "mine/ground-3": .init(name: "Géode turquoise et violette enchâssée", width: 1.55, maxHeight: 1.4),
        "mine/sky-1": .init(name: "Petite chauve-souris", width: 0, maxHeight: 0, skyScale: 0.5),
        "mine/sky-2": .init(name: "Petit papillon de nuit", width: 0, maxHeight: 0, skyScale: 0.26, skyAltitude: 0.68),
        "mine/wayside": .init(name: "Lanterne portative sur pierres", width: 0.42, maxHeight: 0.52, roadInset: 0.01),

        "sanfrancisco/ground-1": .init(name: "Otarie dans une grotte littorale", width: 2.1, maxHeight: 1.45),
        "sanfrancisco/ground-2": .init(name: "Coquillage fossile dans la roche", width: 0.9, maxHeight: 0.75),
        "sanfrancisco/ground-3": .init(name: "Ancien câble d’acier dans une petite galerie", width: 1.6, maxHeight: 1.1),
        "sanfrancisco/sky-1": .init(name: "Goéland blanc", width: 0, maxHeight: 0, skyScale: 0.9),
        "sanfrancisco/sky-2": .init(name: "Pélican brun", width: 0, maxHeight: 0, skyScale: 0.95),
        "sanfrancisco/wayside": .init(name: "Pavots orange et rocher", width: 1.15, maxHeight: 0.85, followsSlope: true),

        "paris/ground-1": .init(name: "Chat et livres dans une alcôve de cave", width: 1.1, maxHeight: 0.85, clearance: 0.25),
        "paris/ground-2": .init(name: "Ancienne roue de métro dans un tunnel", width: 1.5, maxHeight: 1.1),
        "paris/ground-3": .init(name: "Clé ancienne dans le calcaire", width: 0.65, maxHeight: 0.5),
        "paris/sky-1": .init(name: "Petite hirondelle", width: 0, maxHeight: 0, skyScale: 0.48),
        "paris/sky-2": .init(name: "Pigeon gris", width: 0, maxHeight: 0, skyScale: 0.64),
        "paris/wayside": .init(name: "Rosier en pot et arrosoir", width: 1.1, maxHeight: 1.05),

        "clouds/ground-1": .init(name: "Baleine endormie sur un nuage", width: 2.2, maxHeight: 1.75, clearance: 1.05),
        "clouds/ground-2": .init(name: "Îlot flottant fleuri", width: 2.2, maxHeight: 1.75, clearance: 1.05),
        "clouds/ground-3": .init(name: "Lune dorée et trois étoiles sur un nuage", width: 2.1, maxHeight: 1.65, clearance: 1.05),
        "clouds/sky-1": .init(name: "Montgolfière pastel", width: 0, maxHeight: 0, skyScale: 0.9),
        "clouds/sky-2": .init(name: "Poisson volant pastel", width: 0, maxHeight: 0, skyScale: 0.75),
        "clouds/wayside": .init(name: "Trois fleurs sur un petit nuage", width: 1.1, maxHeight: 1.1, followsSlope: true),
    ]
}
