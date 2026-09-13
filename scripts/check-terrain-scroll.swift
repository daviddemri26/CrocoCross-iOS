import Foundation
import ImageIO
import CoreGraphics

/// Compare the same underground material points after camera motion. A screen-fixed
/// texture or a recycled strip changing phase would produce large differences.
@main struct TerrainScrollChecks {
    struct Pixels {
        let width: Int
        let height: Int
        var bytes: [UInt8]
        init(_ url: URL) {
            let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
            width = image.width; height = image.height
            bytes = [UInt8](repeating: 0, count: width * height * 4)
            let w = width, h = height
            bytes.withUnsafeMutableBytes { buffer in
                let context = CGContext(data: buffer.baseAddress, width: w, height: h,
                    bitsPerComponent: 8, bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
                context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            }
        }
        func value(x: Double, y: Int, channel: Int) -> Double {
            let a = Int(floor(x)), mix = x - floor(x)
            return Double(bytes[(y * width + a) * 4 + channel]) * (1 - mix)
                + Double(bytes[(y * width + a + 1) * 4 + channel]) * mix
        }
    }

    static func main() throws {
        let root = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "artifacts/terrain-review/renders")
        let files = try JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent("report.json"))) as! [[String: Any]]
        precondition(files.count == 54 && files.allSatisfy { $0["roadLoaded"] as? Bool == true && $0["earthLoaded"] as? Bool == true }, "Missing material or render")
        var report: [[String: Any]] = []
        for world in ["canyon", "japan", "highway", "jungle", "arctic", "mine", "sanfrancisco", "paris"] {
            for orientation in ["landscape", "portrait"] {
                let a = Pixels(root.appendingPathComponent("\(world)-\(orientation)-0.png"))
                for frame in 1...2 {
                    let b = Pixels(root.appendingPathComponent("\(world)-\(orientation)-\(frame).png"))
                    let points: Double = orientation == "landscape" ? 1180 : 402
                    let ppm: Double = orientation == "landscape" ? 48 : 36
                    let shift = 0.7 * Double(frame) * ppm * Double(a.width) / points
                    var difference = 0.0, count = 0
                    // Deep terrain only: excludes road silhouette, riders, sky and vignettes.
                    for y in stride(from: Int(Double(a.height) * 0.88), to: Int(Double(a.height) * 0.96), by: 7) {
                        for x in stride(from: 8, to: a.width - Int(ceil(shift)) - 8, by: 7) {
                            for channel in 0..<3 {
                                difference += abs(a.value(x: Double(x) + shift, y: y, channel: channel)
                                                  - b.value(x: Double(x), y: y, channel: channel))
                                count += 1
                            }
                        }
                    }
                    let mean = difference / Double(count)
                    report.append(["world": world, "orientation": orientation, "frame": frame, "meanChannelDifference": mean])
                    precondition(mean < 3, "Material slipped or changed: \(world) \(orientation) frame \(frame), error \(mean)")
                }
            }
        }
        print(String(decoding: try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self))
        fputs("PASS: 18 textures loaded in 54 renders; 32 camera translations preserve ground detail\n", stderr)
    }
}
