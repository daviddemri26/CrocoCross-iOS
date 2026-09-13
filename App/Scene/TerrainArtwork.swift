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

    static func forWorld(_ id: String) -> TerrainStyle {
        switch id {
        case "canyon": .init(roadDepth: 0.25, roadTile: 1.4, earthTile: 5.6, depthShade: 0.19)
        case "japan": .init(roadDepth: 0.24, roadTile: 1.3, earthTile: 4.8, depthShade: 0.24)
        case "highway": .init(roadDepth: 0.24, roadTile: 1.6, earthTile: 5.4, depthShade: 0.23)
        case "jungle": .init(roadDepth: 0.25, roadTile: 1.2, earthTile: 4.6, depthShade: 0.12)
        case "arctic": .init(roadDepth: 0.30, roadTile: 1.7, earthTile: 5.4, depthShade: 0.18)
        case "mine": .init(roadDepth: 0.23, roadTile: 1.4, earthTile: 4.8, depthShade: 0.23)
        case "sanfrancisco": .init(roadDepth: 0.24, roadTile: 1.6, earthTile: 5.2, depthShade: 0.22)
        case "paris": .init(roadDepth: 0.30, roadTile: 1.8, earthTile: 5.4, depthShade: 0.22)
        default: .init(roadDepth: 0.20, roadTile: 2.2, earthTile: 3.8, depthShade: 0.06)
        }
    }
}

/// A small pool of terrain-conforming strips. Texture coordinates stay anchored to
/// the course, including when a strip is recycled or the camera changes scale.
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
                 ground: (Double) -> CGFloat) {
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
        let depth = surface ? style.roadDepth : world.id == "clouds" ? 1.1 : max(16, ceil(size.height / ppm) + 12)
        for (index, strip) in strips.enumerated() {
            strip.isHidden = index >= count
            guard index < count else { continue }
            strip.texture = artwork
            strip.usesArtwork = artwork != nil
            strip.color = surface ? world.edge : world.earth
            strip.colorBlendFactor = artwork == nil ? 1 : 0
            strip.display(start: Double(first + index) * span, span: span, left: left,
                          depth: depth, tile: surface ? style.roadTile : style.earthTile,
                          shade: surface ? 0 : style.depthShade, blendEdges: !surface, ppm: ppm, ground: ground)
        }
    }
}

@MainActor
private final class MaterialStrip: SKSpriteNode {
    private static let columns = 36
    private let mapping = SKUniform(name: "u_mapping", vectorFloat4: .zero)
    private let shading = SKUniform(name: "u_shading", vectorFloat2: .zero)
    private var materialShader: SKShader?
    var usesArtwork = true {
        didSet { if usesArtwork != oldValue { shader = usesArtwork ? materialShader : nil } }
    }

    init() {
        super.init(texture: nil, color: .clear, size: .zero)
        anchorPoint = .zero
        // The fine road grain can mirror. Large earth surfaces blend shifted edge
        // samples instead: seamless without the conspicuous symmetry of mirroring.
        shader = SKShader(source: """
        void main() {
            vec2 metres = vec2(u_mapping.x + v_tex_coord.x * u_mapping.y,
                               (1.0 - v_tex_coord.y) * u_mapping.z);
            vec2 tiled = metres / u_mapping.w;
            vec4 paint;
            if (u_shading.y > 0.5) {
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
        """, uniforms: [mapping, shading])
        materialShader = shader
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(start: Double, span: Double, left: Double, depth: CGFloat,
                 tile: CGFloat, shade: Float, blendEdges: Bool, ppm: CGFloat, ground: (Double) -> CGFloat) {
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
        let phase = start.truncatingRemainder(dividingBy: Double(tile * 2))
        mapping.vectorFloat4Value = SIMD4(Float(phase), Float(span), Float(depth), Float(tile))
        shading.vectorFloat2Value = SIMD2(shade, blendEdges ? 1 : 0)
    }
}
