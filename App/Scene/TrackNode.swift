import CrocoCrossCore
import SpriteKit
import UIKit

@MainActor
final class TrackNode: SKNode {
    private let crop = SKCropNode()
    private let mask = SKShapeNode()
    private let earth = TerrainMaterialNode(surface: false)
    private let road = TerrainMaterialNode(surface: true)
    private let cliffShade = SKShapeNode()
    private let cliffFace = SKShapeNode()
    private let cliffMoss = SKShapeNode()
    private let edgeShadow = SKShapeNode()
    private let edge = SKShapeNode()
    private var currentID = ""

    override init() {
        super.init()
        mask.fillColor = .white
        mask.strokeColor = .clear
        crop.maskNode = mask
        addChild(crop)
        crop.addChild(earth)
        crop.addChild(road)
        // Cut-face accents stay within the same mask as the existing paintings.
        // None can extend into the empty gap or create a false riding surface.
        for node in [cliffShade, cliffFace, cliffMoss] {
            node.strokeColor = .clear
            crop.addChild(node)
        }
        addChild(edgeShadow)
        addChild(edge)
        edge.fillColor = .clear
        edge.lineCap = .round
        edgeShadow.fillColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(world: World, size: CGSize, left: Double, ppm: CGFloat, seconds: Double,
                 reducedMotion: Bool, seed: UInt64, ground: (Double) -> CGFloat,
                 solidSpans: [TerrainSpan]? = nil) {
        if currentID != world.id { configure(world) }
        let sampleCount = max(90, Int(size.width / 4))
        let surface = CGMutablePath(), outline = CGMutablePath()
        let shade = CGMutablePath(), rock = CGMutablePath(), moss = CGMutablePath()
        let right = left + Double(size.width / ppm)
        let spans = solidSpans ?? [TerrainSpan(lowerBound: left, upperBound: right)]
        let separated = world.id == "jungle" && solidSpans != nil
        for span in spans {
            let lower = max(left, span.lowerBound), upper = min(right, span.upperBound)
            guard upper > lower else { continue }
            let startX = CGFloat(lower - left) * ppm, endX = CGFloat(upper - left) * ppm
            let count = max(1, Int(ceil(Double(sampleCount) * (upper - lower) / (right - left))))
            for sample in 0...count {
                let fraction = Double(sample) / Double(count)
                let wx = lower + (upper - lower) * fraction
                let point = CGPoint(x: CGFloat(wx - left) * ppm, y: ground(wx))
                if sample == 0 { surface.move(to: point); outline.move(to: point) }
                else { surface.addLine(to: point); outline.addLine(to: point) }
            }
            // Each platform closes independently. The sky/background remains
            // visible all the way down a gap, including below the road ribbon.
            surface.addLine(to: CGPoint(x: endX, y: -size.height))
            surface.addLine(to: CGPoint(x: startX, y: -size.height))
            surface.closeSubpath()
            if separated {
                let width = min(CGFloat(upper - lower) * ppm * 0.35, ppm * 0.48)
                if span.lowerBound > left && span.lowerBound < right {
                    appendCliff(x: startX, top: ground(lower), bottom: -size.height, inward: 1,
                                width: width, ppm: ppm, shade: shade, rock: rock, moss: moss)
                }
                if span.upperBound > left && span.upperBound < right {
                    appendCliff(x: endX, top: ground(upper), bottom: -size.height, inward: -1,
                                width: width, ppm: ppm, shade: shade, rock: rock, moss: moss)
                }
            }
        }
        mask.path = surface
        cliffShade.path = shade
        cliffFace.path = rock
        cliffMoss.path = moss
        cliffShade.isHidden = !separated
        cliffFace.isHidden = !separated
        cliffMoss.isHidden = !separated
        earth.display(world: world, size: size, left: left, ppm: ppm,
                      parallax: SceneryMotion.foregroundFactor(reducedMotion: reducedMotion), ground: ground)
        road.display(world: world, size: size, left: left, ppm: ppm, ground: ground)
        edgeShadow.path = outline
        edgeShadow.lineWidth = max(1.5, ppm * 0.05)
        edge.path = outline
        edge.lineWidth = max(0.8, ppm * 0.025)
        // Butt caps terminate exactly at collision boundaries; rounded caps can
        // look like a tiny invisible bridge into an otherwise empty gap.
        edge.lineCap = separated ? .butt : .round
        edgeShadow.lineCap = .butt
    }

    private func appendCliff(x: CGFloat, top: CGFloat, bottom: CGFloat, inward: CGFloat,
                             width: CGFloat, ppm: CGFloat, shade: CGMutablePath,
                             rock: CGMutablePath, moss: CGMutablePath) {
        guard top > bottom, width > 0 else { return }
        shade.addRect(CGRect(x: min(x, x + inward * width), y: bottom, width: width, height: max(0, top - bottom)))
        // The irregular inner boundary suggests a rocky cut while the outer edge
        // remains exactly vertical, matching the end of physical support.
        rock.move(to: CGPoint(x: x, y: top - ppm * 0.16))
        let step = max(1, ppm * 0.48)
        let layers = max(1, Int(ceil((top - bottom) / step)))
        for layer in 0...layers {
            let depth = min(top - bottom, CGFloat(layer) * step)
            let inset = width * (layer.isMultiple(of: 3) ? 0.72 : layer.isMultiple(of: 2) ? 0.48 : 0.58)
            rock.addLine(to: CGPoint(x: x + inward * inset, y: top - depth))
        }
        rock.addLine(to: CGPoint(x: x, y: bottom))
        rock.closeSubpath()
        moss.move(to: CGPoint(x: x, y: top))
        moss.addLine(to: CGPoint(x: x + inward * width, y: top))
        moss.addLine(to: CGPoint(x: x + inward * width * 0.58, y: top - ppm * 0.13))
        moss.addLine(to: CGPoint(x: x + inward * width * 0.32, y: top - ppm * 0.42))
        moss.addLine(to: CGPoint(x: x, y: top - ppm * 0.27))
        moss.closeSubpath()
    }

    private func configure(_ world: World) {
        currentID = world.id
        edge.strokeColor = TerrainStyle.roadEdge(for: world.id).withAlphaComponent(0.72)
        edgeShadow.strokeColor = world.deepEarth.withAlphaComponent(0.65)
        cliffShade.fillColor = world.deepEarth.withAlphaComponent(0.84)
        cliffFace.fillColor = .hex(0x738B63).withAlphaComponent(0.88)
        cliffMoss.fillColor = .hex(0xABC76A)
    }
}
