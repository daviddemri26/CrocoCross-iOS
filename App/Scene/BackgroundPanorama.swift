import Foundation

/// A camera-driven strip of paintings. Reflection preserves the Canyon's shared
/// edge pixels; a painting authored to wrap can repeat without reversing landmarks.
struct BackgroundPanorama {
    enum Repetition { case reflected, seamless }
    static let japanEdgeBlend = 0.08

    struct Tile: Equatable {
        let index: Int
        let centre: Double
        let mirrored: Bool
    }

    struct Layout: Equatable {
        let width: Double
        let height: Double
        let stride: Double
        let centreY: Double
        let tiles: [Tile]
    }

    static func tiles(viewportWidth: Double, tileWidth: Double, travel: Double,
                      initialCentre: Double? = nil, repetition: Repetition = .reflected) -> [Tile] {
        guard tileWidth > 0, tileWidth.isFinite, travel.isFinite else { return [] }
        let offset = travel * 8 // Far scenery moves at 8 screen points per metre.
        let centre = initialCentre ?? viewportWidth / 2
        let phase = initialCentre.map { offset + viewportWidth / 2 - $0 } ?? offset
        let first = Int(floor(phase / tileWidth))
        return (-1...1).map { delta in
            let index = first + delta
            return Tile(index: index, centre: centre + Double(index) * tileWidth - offset,
                        mirrored: repetition == .reflected && !index.isMultiple(of: 2))
        }
    }

    /// Independent of motorcycle zoom: changing speed or following a fall must
    /// not resize distant mountains. Three overscanned tiles cover either direction.
    static func japan(viewportWidth: Double, viewportHeight: Double,
                      textureWidth: Double, textureHeight: Double,
                      cameraTravel: Double, cameraHeight: Double,
                      reducedMotion: Bool, isPreview: Bool) -> Layout {
        let aspect = max(1, textureWidth) / max(1, textureHeight)
        let height = max(viewportHeight * 1.60, viewportHeight + 64,
                         (viewportWidth + 4) / aspect)
        let width = max(viewportWidth + 4, height * aspect)
        let still = reducedMotion || isPreview
        let vertical = still ? 0 : min(24, max(-24, cameraHeight * -0.8))
        // Place the main summit in the initial view; continued travel reveals
        // the rest of the panorama instead of stopping at a small pixel limit.
        let initialCentre = viewportWidth * 0.68 - (0.51 - 0.5) * width
        let summitFromBottom = 0.77
        let desiredY = viewportHeight * 0.82 - (summitFromBottom - 0.5) * height + vertical
        let centreY = min(height / 2 - 2, max(viewportHeight + 2 - height / 2, desiredY))
        // Overlap only the forested outer edges. The renderer fades the next
        // painting in over its opaque neighbour, avoiding reflected landmarks.
        let stride = width * (1 - japanEdgeBlend)
        return Layout(width: width, height: height, stride: stride, centreY: centreY,
                      tiles: tiles(viewportWidth: viewportWidth, tileWidth: stride,
                                   travel: still ? 0 : cameraTravel, initialCentre: initialCentre,
                                   repetition: .seamless))
    }
}
