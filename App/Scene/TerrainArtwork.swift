import ImageIO
import SpriteKit
import UIKit

/// The source paintings stay intact; only appropriately sized GPU textures are cached.
@MainActor
enum TerrainArtwork {
    private static let cache: NSCache<NSString, SKTexture> = {
        let cache = NSCache<NSString, SKTexture>()
        cache.totalCostLimit = 24 * 1024 * 1024
        return cache
    }()

    static func texture(world: String, surface: Bool) -> SKTexture? {
        let name = surface ? "road" : "earth"
        let key = "\(world)/\(name)" as NSString
        if let texture = cache.object(forKey: key) { return texture }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png",
                                        subdirectory: "GameAssets/Terrain/\(world)"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 768,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
              ] as CFDictionary) else { return nil }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        texture.usesMipmaps = true
        cache.setObject(texture, forKey: key, cost: image.width * image.height * 4 * 4 / 3)
        return texture
    }
}

/// Material dimensions are in world metres, so camera zoom never enlarges the grain.
struct TerrainStyle {
    let roadDepth: CGFloat
    let roadTile: CGFloat
    let earthTile: CGFloat
    let depthShade: Float

    /// A restrained highlight matching each painted riding surface.
    static func roadEdge(for id: String) -> UIColor {
        let colors: [String: UInt32] = [
            "canyon": 0xF5C889, "japan": 0xEAA078, "highway": 0xE6E3CC,
            "jungle": 0xE6D68C, "arctic": 0xF5FEFF, "mine": 0xB8CCD3,
            "sanfrancisco": 0xF88D63, "paris": 0xECE0C9, "clouds": 0xB7A1CF,
        ]
        return .hex(colors[id] ?? 0xFFF8ED)
    }

    static func forWorld(_ id: String) -> TerrainStyle {
        switch id {
        case "canyon": .init(roadDepth: 0.40, roadTile: 3.2, earthTile: 18, depthShade: 0.04)
        case "japan": .init(roadDepth: 0.40, roadTile: 3.2, earthTile: 18, depthShade: 0.04)
        case "highway": .init(roadDepth: 0.46, roadTile: 3.6, earthTile: 18, depthShade: 0.04)
        case "jungle": .init(roadDepth: 0.46, roadTile: 3.0, earthTile: 18, depthShade: 0.04)
        case "arctic": .init(roadDepth: 0.44, roadTile: 3.2, earthTile: 18, depthShade: 0.04)
        case "mine": .init(roadDepth: 0.42, roadTile: 3.6, earthTile: 18, depthShade: 0.04)
        case "sanfrancisco": .init(roadDepth: 0.48, roadTile: 3.0, earthTile: 18, depthShade: 0.04)
        case "paris": .init(roadDepth: 0.44, roadTile: 2.8, earthTile: 6, depthShade: 0.04)
        default: .init(roadDepth: 0.44, roadTile: 3.2, earthTile: 18, depthShade: 0.04)
        }
    }
}

/// Terrain-conforming image strips. Road, foreground painting and decorative
/// vignettes stay attached to the course while the camera moves.
@MainActor
final class TerrainMaterialNode: SKNode {
    private var strips: [MaterialStrip] = []
    private let surface: Bool
    private var worldID = ""
    private var artwork: SKTexture?
    private let span: Double = 6

    init(surface: Bool) {
        self.surface = surface
        super.init()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(world: World, size: CGSize, left: Double, ppm: CGFloat,
                 parallax: Double = 1, ground: (Double) -> CGFloat) {
        if worldID != world.id {
            worldID = world.id
            artwork = TerrainArtwork.texture(world: world.id, surface: surface)
        }
        let style = TerrainStyle.forWorld(world.id)
        let first = Int(floor(left / span))
        let last = Int(floor((left + Double(size.width / ppm)) / span))
        let count = last - first + 1
        while strips.count < count {
            let strip = MaterialStrip()
            strips.append(strip)
            addChild(strip)
        }
        // Fixed depth, quantized in metres, covers the viewport while keeping the
        // material mapping independent of the visible screen height.
        let depth = surface ? style.roadDepth : max(16, ceil(size.height / ppm) + 12)
        for (index, strip) in strips.enumerated() {
            strip.isHidden = index >= count
            guard index < count else { continue }
            strip.texture = artwork
            strip.usesArtwork = artwork != nil
            strip.color = surface ? world.edge : world.earth
            strip.colorBlendFactor = artwork == nil ? 1 : 0
            strip.display(start: Double(first + index) * span, span: span, left: left,
                          depth: depth, tile: surface ? style.roadTile : style.earthTile,
                          shade: surface ? 0 : style.depthShade, blendEdges: !surface,
                          parallax: surface ? 1 : parallax, fullHeight: surface,
                          ppm: ppm, ground: ground)
        }
    }
}

@MainActor
private final class MaterialStrip: SKSpriteNode {
    private static let columns = 36
    private let mapping = SKUniform(name: "u_mapping", vectorFloat4: .zero)
    private let shading = SKUniform(name: "u_shading", vectorFloat2: .zero)
    private let road = SKUniform(name: "u_road", float: 0)
    private var materialShader: SKShader?
    var usesArtwork = true {
        didSet { if usesArtwork != oldValue { shader = usesArtwork ? materialShader : nil } }
    }

    init() {
        super.init(texture: nil, color: .clear, size: .zero)
        anchorPoint = .zero
        // Each road painting fills the entire thin ribbon. Mirroring only along
        // the course joins its edges without cropping borders or flipping it upside down.
        // Broad foreground paintings blend shifted samples near their edges.
        shader = SKShader(source: """
        void main() {
            vec2 metres = vec2(u_mapping.x + v_tex_coord.x * u_mapping.y,
                               (1.0 - v_tex_coord.y) * u_mapping.z);
            vec2 tiled = metres / u_mapping.w;
            vec4 paint;
            if (u_road > 0.5) {
                float along = 1.0 - abs(mod(tiled.x, 2.0) - 1.0);
                paint = texture2D(u_texture, vec2(along, v_tex_coord.y));
            } else if (u_shading.y > 0.5) {
                vec2 uv = fract(tiled);
                vec2 shifted = fract(uv + 0.5);
                vec2 weight = smoothstep(vec2(0.0), vec2(0.20), uv)
                            * smoothstep(vec2(0.0), vec2(0.20), 1.0 - uv);
                vec4 low = mix(texture2D(u_texture, shifted),
                               texture2D(u_texture, vec2(uv.x, shifted.y)), weight.x);
                vec4 high = mix(texture2D(u_texture, vec2(shifted.x, uv.y)),
                                texture2D(u_texture, uv), weight.x);
                paint = mix(low, high, weight.y);
            } else {
                vec2 uv = 1.0 - abs(mod(tiled, 2.0) - 1.0);
                paint = texture2D(u_texture, uv);
            }
            float shade = 1.0 - u_shading.x * (1.0 - exp(-metres.y / 5.0));
            gl_FragColor = vec4(paint.rgb * shade, paint.a);
        }
        """, uniforms: [mapping, shading, road])
        materialShader = shader
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(start: Double, span: Double, left: Double, depth: CGFloat,
                 tile: CGFloat, shade: Float, blendEdges: Bool, parallax: Double, fullHeight: Bool,
                 ppm: CGFloat, ground: (Double) -> CGFloat) {
        let heights = (0...Self.columns).map { ground(start + span * Double($0) / Double(Self.columns)) }
        let low = heights.min()!, high = heights.max()!
        let height = depth * ppm + high - low
        position = CGPoint(x: CGFloat(start - left) * ppm, y: low - depth * ppm)
        size = CGSize(width: CGFloat(span) * ppm, height: height)
        var source: [SIMD2<Float>] = [], destination: [SIMD2<Float>] = []
        for row in 0...1 {
            for column in 0...Self.columns {
                let x = Float(column) / Float(Self.columns)
                source.append(SIMD2(x, Float(row)))
                destination.append(SIMD2(x, Float((heights[column] - low + CGFloat(row) * depth * ppm) / height)))
            }
        }
        warpGeometry = SKWarpGeometryGrid(columns: Self.columns, rows: 1,
                                         sourcePositions: source, destinationPositions: destination)
        // Keep float precision on long runs; mirrored tiles repeat every 2 * tile.
        let materialX = SceneryMotion.coordinate(screenMetres: start - left, camera: left, factor: parallax)
        let phase = materialX.truncatingRemainder(dividingBy: Double(tile * 2))
        mapping.vectorFloat4Value = SIMD4(Float(phase), Float(span), Float(depth), Float(tile))
        shading.vectorFloat2Value = SIMD2(shade, blendEdges ? 1 : 0)
        road.floatValue = fullHeight ? 1 : 0
    }
}
