import UIKit

/// Cached source artwork layers shared by SpriteKit and lightweight SwiftUI previews.
@MainActor
enum RiderArtwork {
    struct Wheel {
        let centre: CGPoint
        let diameter: CGFloat
        let tyre: UIImage?
        let rotor: UIImage
        let hardware: UIImage
    }
    struct Layers {
        let body: UIImage
        let wheels: [Wheel]
        let size: CGSize
    }
    private static var cache: [String: Layers] = [:]

    static func layers(for rider: Rider) -> Layers? {
        if let value = cache[rider.id] { return value }
        guard let image = GameAssets.image(named: rider.assetName) else { return nil }
        let g = rider.geometry
        let centres = [
            CGPoint(x: g.rearX * image.size.width, y: g.rearY * image.size.height),
            CGPoint(x: g.frontX * image.size.width, y: g.frontY * image.size.height),
        ]
        let scale = image.size.width / 1536
        let artwork = RotorArtwork.riders[rider.id] ?? []
        let body =
            g.hasPaintedWheels ? bodyTexture(image, centres: centres, radii: artwork.map { $0.radius * scale }) : image
        let radius = hypot(centres[1].x - centres[0].x, centres[1].y - centres[0].y) * 0.32 / 1.58
        let wheels = centres.enumerated().compactMap { index, centre -> Wheel? in
            if g.hasPaintedWheels {
                guard artwork.indices.contains(index) else { return nil }
                let art = artwork[index]
                return Wheel(
                    centre: centre, diameter: art.radius * scale * 2, tyre: nil,
                    rotor: rotorTexture(image, centre: centre, artwork: art),
                    hardware: hardwareTexture(image, centre: centre, artwork: art))
            }
            return Wheel(
                centre: centre, diameter: radius * 2, tyre: generatedTyre(),
                rotor: generatedSpokes(), hardware: generatedHub())
        }
        let height = max(image.size.height, centres.map { $0.y + radius + 5 }.max() ?? 0)
        let value = Layers(body: body, wheels: wheels, size: CGSize(width: image.size.width, height: height))
        cache[rider.id] = value
        return value
    }

    // Runtime texture assembly leaves the source assets intact and happens once per selection.
    private static func bodyTexture(_ image: UIImage, centres: [CGPoint], radii: [CGFloat]) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: image.size, format: format).image { context in
            image.draw(at: .zero)
            context.cgContext.setBlendMode(.clear)
            for (centre, radius) in zip(centres, radii) {
                context.cgContext.fillEllipse(
                    in: CGRect(x: centre.x - radius, y: centre.y - radius, width: radius * 2, height: radius * 2))
            }
        }
        return rendered
    }

    private static func rotorTexture(_ image: UIImage, centre: CGPoint, artwork: RotorArtwork) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).image { context in
            let cg = context.cgContext
            let scale = 128 / (artwork.radius * image.size.width / 1536)
            cg.translateBy(x: 128, y: 128)
            let start = artwork.sectorStart * .pi / 180
            let arc = .pi * 2 / CGFloat(artwork.sectors)
            for sector in 0..<artwork.sectors {
                cg.saveGState()
                cg.rotate(by: CGFloat(sector) * arc)
                cg.move(to: .zero)
                cg.addArc(
                    center: .zero, radius: 128, startAngle: start - 0.002, endAngle: start + arc + 0.002,
                    clockwise: false)
                cg.closePath()
                cg.clip()
                image.draw(
                    in: CGRect(
                        x: -centre.x * scale, y: -centre.y * scale, width: image.size.width * scale,
                        height: image.size.height * scale))
                cg.restoreGState()
            }
        }
    }

    private static func hardwareTexture(_ image: UIImage, centre: CGPoint, artwork: RotorArtwork) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).image { context in
            let cg = context.cgContext
            cg.addEllipse(in: CGRect(x: 0, y: 0, width: 256, height: 256))
            cg.clip()
            let sourceScale = image.size.width / 1536
            let scale = 128 / (artwork.radius * sourceScale)
            let mask = CGMutablePath()
            for polygon in artwork.hardware {
                for (index, p) in polygon.enumerated() {
                    let point = CGPoint(
                        x: 128 + (p.x * sourceScale - centre.x) * scale, y: 128 + (p.y * sourceScale - centre.y) * scale
                    )
                    if index == 0 { mask.move(to: point) } else { mask.addLine(to: point) }
                }
                mask.closeSubpath()
            }
            let hubRadius = artwork.hub * sourceScale * scale
            mask.addEllipse(
                in: CGRect(x: 128 - hubRadius, y: 128 - hubRadius, width: hubRadius * 2, height: hubRadius * 2))
            cg.addPath(mask)
            cg.clip()
            image.draw(
                in: CGRect(
                    x: 128 - centre.x * scale, y: 128 - centre.y * scale, width: image.size.width * scale,
                    height: image.size.height * scale))
        }
    }

    private static func generatedSpokes() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128), format: format).image { context in
            let cg = context.cgContext
            cg.setStrokeColor(UIColor.hex(0xB9D0C5).cgColor)
            cg.setLineWidth(5)
            cg.strokeEllipse(in: CGRect(x: 5, y: 5, width: 118, height: 118))
            cg.setLineWidth(2)
            for index in 0..<12 {
                let angle = CGFloat(index) * .pi / 6
                cg.move(to: CGPoint(x: 64, y: 64))
                cg.addLine(to: CGPoint(x: 64 + cos(angle) * 57, y: 64 + sin(angle) * 57))
            }
            cg.strokePath()
        }
    }

    private static func generatedTyre() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format).image { context in
            let cg = context.cgContext
            cg.setFillColor(UIColor.hex(0x101A17).cgColor)
            cg.fillEllipse(in: CGRect(x: 0, y: 0, width: 256, height: 256))
            cg.setStrokeColor(UIColor.hex(0x3D4943).cgColor)
            cg.setLineWidth(3)
            cg.strokeEllipse(in: CGRect(x: 17, y: 17, width: 222, height: 222))
            cg.setStrokeColor(UIColor.hex(0x070D0A).cgColor)
            cg.setLineWidth(4)
            cg.strokeEllipse(in: CGRect(x: 28, y: 28, width: 200, height: 200))
            cg.translateBy(x: 128, y: 128)
            for index in 0..<36 {
                cg.saveGState()
                cg.rotate(by: CGFloat(index) * .pi / 18)
                cg.setFillColor(UIColor.hex(index.isMultiple(of: 2) ? 0x29342E : 0x080F0C).cgColor)
                cg.fill(CGRect(x: -3.5, y: 116, width: 7, height: 9))
                cg.restoreGState()
            }
        }
    }

    private static func generatedHub() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 48, height: 48), format: format).image { context in
            let cg = context.cgContext
            cg.setFillColor(UIColor.hex(0xF08A45).cgColor)
            cg.fillEllipse(in: CGRect(x: 0, y: 0, width: 48, height: 48))
            cg.setFillColor(UIColor.hex(0xC2D2C9).cgColor)
            cg.fillEllipse(in: CGRect(x: 13, y: 13, width: 22, height: 22))
            cg.setFillColor(UIColor.hex(0x293A31).cgColor)
            cg.fillEllipse(in: CGRect(x: 20, y: 20, width: 8, height: 8))
        }
    }
}
