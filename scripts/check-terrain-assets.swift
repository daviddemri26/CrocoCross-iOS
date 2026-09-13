import Foundation
import ImageIO
import CoreGraphics

@main struct TerrainAssetChecks {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "App/Resources/GameAssets/Terrain")
        let worlds = ["canyon", "japan", "highway", "jungle", "arctic", "mine", "sanfrancisco", "paris", "clouds"]
        let names = ["road", "earth"]
        var report: [[String: Any]] = []
        for world in worlds {
            for name in names {
                let url = root.appendingPathComponent(world).appendingPathComponent(name + ".png")
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let original = CGImageSourceCreateImageAtIndex(source, 0, nil),
                      let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceThumbnailMaxPixelSize: 128,
                      ] as CFDictionary) else { fatalError("Missing or invalid PNG: \(url.path)") }
                let width = image.width, height = image.height
                var pixels = [UInt8](repeating: 0, count: width * height * 4)
                pixels.withUnsafeMutableBytes { bytes in
                    let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                        bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
                    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
                }
                let alpha = stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] }
                precondition(original.width >= 1024 && original.height >= 1024, "Undersized texture \(world)/\(name)")
                precondition(original.width == original.height, "Non-square material \(world)/\(name)")
                precondition(alpha.allSatisfy { $0 == 255 }, "Transparent material \(world)/\(name)")
                report.append(["asset": "\(world)/\(name)", "width": original.width,
                               "height": original.height, "opaque": true])
            }
        }
        let json = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        print(String(decoding: json, as: UTF8.self))
        fputs("PASS: all 18 square original PNGs load at full resolution and are opaque\n", stderr)
    }
}
