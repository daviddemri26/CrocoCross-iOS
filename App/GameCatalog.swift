import SpriteKit
import UIKit

struct Rider: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let assetName: String
    let geometry: RiderGeometry
    let availability: CatalogAvailability
}

/// Artwork coordinates are normalized to the original 1536 x 1024 canvas.
/// Rocco's supplied artwork omits the wheels, which are rendered independently.
struct RiderGeometry {
    let rearX: CGFloat
    let frontX: CGFloat
    let rearY: CGFloat
    let frontY: CGFloat
    let radius: CGFloat
    var hasPaintedWheels: Bool = true
    var axleDistance: CGFloat { hypot(frontX - rearX, (frontY - rearY) * 2 / 3) }
}

struct World: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let assetName: String
    let sky: UIColor
    let earth: UIColor
    let deepEarth: UIColor
    let edge: UIColor
    let accent: UIColor
    let availability: CatalogAvailability

    var course: WorldCoursePlan {
        .init(worldID: id, revision: 1, status: id == "canyon" ? .ready : .planned)
    }
    var isPlayable: Bool { availability.isUnlocked && course.status == .ready }
}

@MainActor
enum GameCatalog {
    static let riders: [Rider] = [
        Rider(id: "croco", name: "Rocco", subtitle: "Crocodile · Motocross", assetName: "croco-rider", geometry: .init(rearX: 395 / 1635, frontX: 1330 / 1635, rearY: 790 / 962, frontY: 790 / 962, radius: 0.14, hasPaintedWheels: false), availability: .available),
        Rider(id: "shiba", name: "Kenji", subtitle: "Shiba Inu · Superbike", assetName: "shiba-yamaha", geometry: .init(rearX: 267 / 1536, frontX: 1250 / 1536, rearY: 744 / 1024, frontY: 776 / 1024, radius: 215.5 / 1536), availability: .locked()),
        Rider(id: "eagle", name: "Duke", subtitle: "Bald eagle · Cruiser", assetName: "eagle-harley", geometry: .init(rearX: 265 / 1536, frontX: 1314 / 1536, rearY: 791 / 1024, frontY: 791 / 1024, radius: 193 / 1536), availability: .locked()),
        Rider(id: "tiger", name: "Axel", subtitle: "Tiger · Enduro", assetName: "tiger-enduro", geometry: .init(rearX: 279 / 1536, frontX: 1228 / 1536, rearY: 777 / 1024, frontY: 776 / 1024, radius: 216 / 1536), availability: .locked()),
        Rider(id: "polar", name: "Bjorn", subtitle: "Polar bear · Electric trail", assetName: "polar-electric", geometry: .init(rearX: 291 / 1536, frontX: 1228 / 1536, rearY: 797 / 1024, frontY: 797 / 1024, radius: 207.5 / 1536), availability: .locked()),
        Rider(id: "flamingo", name: "Pinky", subtitle: "Flamingo · Retro scooter", assetName: "flamingo-scooter", geometry: .init(rearX: 360 / 1536, frontX: 1219 / 1536, rearY: 854 / 1024, frontY: 854 / 1024, radius: 149 / 1536), availability: .locked()),
        Rider(id: "toucan", name: "Rio", subtitle: "Toucan · Sunshine moped", assetName: "toucan-moped", geometry: .init(rearX: 352 / 1536, frontX: 1218 / 1536, rearY: 784 / 1024, frontY: 784 / 1024, radius: 212 / 1536), availability: .locked()),
        Rider(id: "raccoon", name: "Bandit", subtitle: "Raccoon · Scrambler", assetName: "raccoon-scrambler", geometry: .init(rearX: 285 / 1536, frontX: 1254 / 1536, rearY: 774 / 1024, frontY: 774 / 1024, radius: 226 / 1536), availability: .locked()),
        Rider(id: "axolotl", name: "Bubbles", subtitle: "Axolotl · Mini dirtbike", assetName: "axolotl-mini", geometry: .init(rearX: 330 / 1536, frontX: 1257 / 1536, rearY: 788 / 1024, frontY: 789 / 1024, radius: 203 / 1536), availability: .locked())
    ]

    /// The complete catalog is visible, but only validated, unlocked riders can start a run.
    static var playableRiders: [Rider] { riders.filter { $0.availability.isUnlocked } }

    static let worlds: [World] = [
        .init(id: "canyon", name: "Canyon", subtitle: "Red rock & desert dust", assetName: "canyon-backdrop", sky: .hex(0x99D9EF), earth: .hex(0xD77740), deepEarth: .hex(0x703D2E), edge: .hex(0xFBD190), accent: .hex(0xFFB369), availability: .available),
        .init(id: "japan", name: "Japan Mountains", subtitle: "Pines, peaks & falling petals", assetName: "japan-mountains", sky: .hex(0xC4E9EE), earth: .hex(0x638767), deepEarth: .hex(0x263E4B), edge: .hex(0xC4E8A9), accent: .hex(0xF9B7D7), availability: .locked()),
        .init(id: "highway", name: "American Sunset", subtitle: "Golden hour on the open road", assetName: "american-sunset", sky: .hex(0xEFA299), earth: .hex(0x555268), deepEarth: .hex(0x25273E), edge: .hex(0xF1CA93), accent: .hex(0xFFCE8D), availability: .locked()),
        .init(id: "jungle", name: "Tropical Jungle", subtitle: "Wild trails & fireflies", assetName: "tropical-jungle", sky: .hex(0x53CDE9), earth: .hex(0x417D48), deepEarth: .hex(0x1C352E), edge: .hex(0xB4E967), accent: .hex(0xC1F178), availability: .locked()),
        .init(id: "arctic", name: "Arctic Aurora", subtitle: "Fresh snow under northern lights", assetName: "arctic-aurora", sky: .hex(0x163E75), earth: .hex(0x9FCCE7), deepEarth: .hex(0x314D85), edge: .hex(0xF2FCFF), accent: .hex(0x89F5E1), availability: .locked()),
        .init(id: "mine", name: "Old Gold Mine", subtitle: "Rolling carts & glowing lanterns", assetName: "abandoned-mine", sky: .hex(0x172731), earth: .hex(0x4B3A2E), deepEarth: .hex(0x16191D), edge: .hex(0xB8A487), accent: .hex(0xFFD078), availability: .locked()),
        .init(id: "sanfrancisco", name: "San Francisco", subtitle: "Rolling fog & the Golden Gate", assetName: "san-francisco", sky: .hex(0x8BCEE0), earth: .hex(0x206881), deepEarth: .hex(0x123D55), edge: .hex(0xFFBE77), accent: .hex(0xFF9B68), availability: .locked()),
        .init(id: "paris", name: "Paris", subtitle: "Warm cobblestones & city lights", assetName: "paris", sky: .hex(0xDFB6D2), earth: .hex(0x9C8295), deepEarth: .hex(0x3B3E5C), edge: .hex(0xFFE0AA), accent: .hex(0xFFE4B0), availability: .locked()),
        .init(id: "clouds", name: "Cloud Nine", subtitle: "Floating trails above the world", assetName: "cloud-nine", sky: .hex(0x65C7EC), earth: .hex(0xFFFFFF), deepEarth: .hex(0xBAAFEA), edge: .white, accent: .hex(0xFCE6FF), availability: .locked())
    ]

    static var playableWorlds: [World] { worlds.filter(\.isPlayable) }

    static func rider(_ id: String) -> Rider { riders.first { $0.id == id } ?? riders[0] }
    static func world(_ id: String) -> World { worlds.first { $0.id == id } ?? worlds[0] }
}

@MainActor
enum GameAssets {
    private static let images: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 80 * 1024 * 1024
        return cache
    }()

    static func url(named name: String, extension ext: String = "png") -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "GameAssets")
            ?? Bundle.main.url(forResource: name, withExtension: ext)
    }

    static func image(named name: String) -> UIImage? {
        if let cached = images.object(forKey: name as NSString) { return cached }
        guard let path = url(named: name), let image = UIImage(contentsOfFile: path.path) else { return nil }
        let cost = (image.cgImage?.bytesPerRow ?? 0) * (image.cgImage?.height ?? 0)
        images.setObject(image, forKey: name as NSString, cost: cost)
        return image
    }

    static func texture(named name: String) -> SKTexture? {
        guard let image = image(named: name) else { return nil }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
}

extension UIColor {
    static func hex(_ rgb: UInt32, alpha: CGFloat = 1) -> UIColor {
        UIColor(red: CGFloat((rgb >> 16) & 255) / 255, green: CGFloat((rgb >> 8) & 255) / 255, blue: CGFloat(rgb & 255) / 255, alpha: alpha)
    }
}
