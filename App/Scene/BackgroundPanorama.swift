import Foundation

/// A camera-driven strip of paintings. Reflection preserves the Canyon's shared
/// edge pixels; a painting authored to wrap can repeat without reversing landmarks.
struct BackgroundPanorama {
    enum Repetition { case reflected, seamless }
    static let japanEdgeBlend = 0.08
    static let jungleCropX = 0.28
    static let jungleCropWidth = 0.50
    static let jungleEdgeBlend = 0.16
    static let junglePointsPerMetre = 5.0

    /// Global body coordinates survive physics rebasing and do not include the
    /// view's zoom-dependent camera offset. Rotation/resizing preserves travel.
    struct WorldMotion {
        private var originX = 0.0
        private var originY = 0.0
        private var seed: UInt32?
        private var lastTick = 0
        private var wasPreview = false
        private(set) var travel = 0.0
        private(set) var height = 0.0

        mutating func update(x: Double, y: Double, seed: UInt32, tick: Int, isPreview: Bool) {
            if self.seed != seed || tick < lastTick || wasPreview != isPreview {
                originX = x
                originY = y
            }
            travel = x - originX
            height = y - originY
            self.seed = seed
            lastTick = tick
            wasPreview = isPreview
        }
    }

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
                      initialCentre: Double? = nil, repetition: Repetition = .reflected,
                      pointsPerMetre: Double = 8) -> [Tile] {
        guard tileWidth > 0, tileWidth.isFinite, travel.isFinite else { return [] }
        let offset = travel * pointsPerMetre
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

    /// A close forest panorama behind the world-space scenery. The painting's
    /// size and linear travel never depend on motorcycle zoom or camera fitting.
    static func jungle(viewportWidth: Double, viewportHeight: Double,
                       textureWidth: Double, textureHeight: Double,
                       worldTravel: Double, worldHeight: Double,
                       reducedMotion: Bool, isPreview: Bool) -> Layout {
        let aspect = max(1, textureWidth) / max(1, textureHeight)
        let height = max(viewportHeight * 2.40, viewportHeight + 128,
                         (viewportWidth + 4) / aspect)
        let width = max(viewportWidth + 4, height * aspect)
        let still = reducedMotion || isPreview
        let vertical = still ? 0 : min(64, max(-64, worldHeight * -1.6))
        let peakX = (0.57 - jungleCropX) / jungleCropWidth
        let initialCentre = viewportWidth * 0.70 - (peakX - 0.5) * width
        // Keep the main peak in the upper part of either viewport. Cropping
        // the nearby foliage makes the mountain and waterfall feel much larger.
        let desiredY = viewportHeight * 0.86 - (0.88 - 0.5) * height + vertical
        let centreY = min(height / 2 - 2, max(viewportHeight + 2 - height / 2, desiredY))
        // Use only the central landscape, excluding the painting's framing
        // palms. Its forested edges blend without mirroring mountain landmarks.
        let stride = width * (1 - jungleEdgeBlend)
        return Layout(width: width, height: height, stride: stride, centreY: centreY,
                      tiles: tiles(viewportWidth: viewportWidth, tileWidth: stride,
                                   travel: still ? 0 : worldTravel, initialCentre: initialCentre,
                                   repetition: .seamless, pointsPerMetre: junglePointsPerMetre))
    }
}
