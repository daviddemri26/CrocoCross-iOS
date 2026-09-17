import Foundation

/// An unbounded strip of alternating paintings. Shared edge pixels line up at
/// each reflection, so camera travel never saturates and never exposes a gap.
struct BackgroundPanorama {
    struct Tile {
        let centre: Double
        let mirrored: Bool
    }
    static func tiles(viewportWidth: Double, tileWidth: Double, travel: Double) -> [Tile] {
        guard tileWidth > 0, tileWidth.isFinite, travel.isFinite else { return [] }
        let offset = travel * 8 // Far scenery moves at 8 screen points per metre.
        let first = Int(floor(offset / tileWidth))
        return (-1...1).map { delta in
            let index = first + delta
            return Tile(centre: viewportWidth / 2 + Double(index) * tileWidth - offset,
                        mirrored: !index.isMultiple(of: 2))
        }
    }
}
