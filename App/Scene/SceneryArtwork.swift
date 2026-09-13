import ImageIO
import SpriteKit
import UIKit

/// Original painted PNGs are bundled, decoded at sprite resolution and cached.
/// No procedural stand-ins or frame animation: movement only transforms the artwork.
@MainActor
enum SceneryArtwork {
    private static let cache: NSCache<NSString, SKTexture> = {
        let cache = NSCache<NSString, SKTexture>()
        cache.totalCostLimit = 20 * 1024 * 1024
        return cache
    }()

    static func texture(world: String, layer: SceneryLayer, variant: Int) -> SKTexture? {
        let filename = layer == .wayside ? "wayside" : "\(layer.rawValue)-\(variant)"
        let key = "\(world)/\(filename)" as NSString
        if let texture = cache.object(forKey: key) { return texture }
        guard let url = Bundle.main.url(forResource: filename, withExtension: "png",
                                        subdirectory: "GameAssets/Scenery/\(world)"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: 384,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceShouldCacheImmediately: true,
              ] as CFDictionary) else { return nil }
        // Ignore only transparent padding, so the wayside image's painted base meets the road.
        // This is a runtime texture crop; the generated source file remains untouched.
        let trimmed = trimTransparentPadding(image)
        let texture = SKTexture(cgImage: trimmed)
        texture.filteringMode = .linear
        texture.usesMipmaps = true
        cache.setObject(texture, forKey: key, cost: trimmed.width * trimmed.height * 4 * 4 / 3)
        return texture
    }

    private static func trimTransparentPadding(_ image: CGImage) -> CGImage {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let bounds: CGRect? = pixels.withUnsafeMutableBytes { bytes in
            guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
            else { return nil }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            let data = bytes.bindMemory(to: UInt8.self)
            var minX = width, minY = height, maxX = -1, maxY = -1
            for y in 0..<height {
                for x in 0..<width where data[(y * width + x) * 4 + 3] > 8 {
                    minX = min(minX, x); minY = min(minY, y)
                    maxX = max(maxX, x); maxY = max(maxY, y)
                }
            }
            guard maxX >= minX, maxY >= minY else { return nil }
            return CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        }
        return bounds.flatMap { image.cropping(to: $0) } ?? image
    }
}

@MainActor
final class SceneryActor: SKSpriteNode {
    private var artworkID = ""

    init() { super.init(texture: nil, color: .clear, size: .zero) }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(world: String, layer: SceneryLayer, variant: Int, width: CGFloat, maxHeight: CGFloat) {
        let key = "\(world)/\(layer.rawValue)/\(variant)"
        if artworkID != key {
            artworkID = key
            texture = SceneryArtwork.texture(world: world, layer: layer, variant: variant)
        }
        guard let texture else { isHidden = true; return }
        let dimensions = texture.size()
        let scale = min(width / max(1, dimensions.width), maxHeight / max(1, dimensions.height))
        size = CGSize(width: dimensions.width * scale, height: dimensions.height * scale)
        isHidden = false
    }
}
