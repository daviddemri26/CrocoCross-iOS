import Foundation
import ImageIO
import CoreGraphics

@main struct SceneryAssetChecks {
    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "App/Resources/GameAssets/Scenery")
        let worlds = ["canyon", "japan", "highway", "jungle", "arctic", "mine", "sanfrancisco", "paris", "clouds"]
        let names = ["ground-1", "ground-2", "ground-3", "sky-1", "sky-2", "wayside"]
        var report: [[String: Any]] = []
        for world in worlds {
            for name in names {
                let url = root.appendingPathComponent(world).appendingPathComponent(name + ".png")
                guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let original = CGImageSourceCreateImageAtIndex(source, 0, nil),
                      [.first, .last, .premultipliedFirst, .premultipliedLast].contains(original.alphaInfo),
                      let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                        kCGImageSourceCreateThumbnailFromImageAlways: true,
                        kCGImageSourceThumbnailMaxPixelSize: 128,
                      ] as CFDictionary) else { fatalError("Missing or non-alpha PNG: \(url.path)") }
                let width = image.width, height = image.height
                var pixels = [UInt8](repeating: 0, count: width * height * 4)
                pixels.withUnsafeMutableBytes { bytes in
                    let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                        bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
                    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
                }
                let alpha = stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] }
                let transparent = Double(alpha.filter { $0 < 8 }.count) / Double(alpha.count)
                let solid = Double(alpha.filter { $0 > 200 }.count) / Double(alpha.count)
                precondition(transparent > 0.05 && solid > 0.02, "Invalid cutout \(world)/\(name)")
                report.append(["asset": "\(world)/\(name)", "width": original.width,
                               "height": original.height, "transparentFraction": transparent])
            }
        }
        let json = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        print(String(decoding: json, as: UTF8.self))
        fputs("PASS: all 54 original PNGs load and contain real transparency\n", stderr)
    }
}
