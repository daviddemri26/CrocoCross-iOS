import Foundation
import CoreGraphics

@main struct FlexibleControlChecks {
    static func main() {
        var brake = PedalContactState<Int>()
        var throttle = PedalContactState<Int>()
        let first = CGPoint(x: 90, y: 65)
        precondition(throttle.begin(1, at: first))
        precondition(throttle.owner == 1 && throttle.origin == first)
        for point in [CGPoint(x: 10, y: 200), CGPoint(x: 1200, y: -40)] {
            precondition(!throttle.begin(2, at: point), "Another finger cannot steal the first-contact anchor")
            precondition(throttle.owner == 1 && throttle.origin == first)
        }
        precondition(brake.begin(2, at: CGPoint(x: 60, y: 85)), "Both thumbs must be independently owned")
        precondition(!throttle.end(2) && throttle.owner == 1, "Releasing the other finger cannot release throttle")
        precondition(brake.end(2) && brake.owner == nil && brake.origin == nil)
        precondition(throttle.owner == 1 && throttle.origin == first)
        precondition(throttle.end(1) && throttle.owner == nil && throttle.origin == nil)
        precondition(!throttle.end(1), "An already-finished contact cannot emit another release")
        precondition(throttle.begin(3, at: CGPoint(x: 70, y: 120)))
        precondition(brake.begin(4, at: CGPoint(x: 80, y: 140)))
        throttle.reset(); brake.reset()
        precondition(throttle.owner == nil && brake.owner == nil && throttle.origin == nil && brake.origin == nil,
                     "Pause/cancel/background reset must clear both ownership and visual anchors")
        precondition(!throttle.end(3) && !brake.end(4), "Old UIKit ends after a session reset must be harmless")
        precondition(throttle.begin(5, at: first), "A fresh touch must work after reset")

        var layouts = 0
        for (width, height, wide) in [(320.0, 548.0, false), (390, 763, false), (402, 788, false),
                                     (748, 369, true), (1138, 810, true), (834, 1136, false)] {
            let diameter = wide ? 124.0 : 112
            let zoneHeight = wide ? min(190, max(144, height * 0.42)) : min(240, max(180, height * 0.30))
            let zoneWidth = (width - (wide ? 56 : 32) - 64) / 2
            for right in [false, true] {
                let bounds = CGRect(x: 0, y: 0, width: zoneWidth, height: zoneHeight)
                let geometry = PedalGeometry(bounds: bounds, diameter: diameter, right: right)
                precondition(geometry.side <= diameter - 8)
                precondition(bounds.width * bounds.height > diameter * diameter,
                             "The contact area must be substantially larger than the visual button")
                let rest = geometry.restingPoint
                precondition(rest.y == bounds.maxY - diameter / 2)
                for point in [rest, .zero, CGPoint(x: bounds.maxX, y: bounds.maxY),
                              CGPoint(x: -200, y: 900), CGPoint(x: 900, y: -200),
                              CGPoint(x: bounds.midX, y: 65)] {
                    let anchor = geometry.clamp(point)
                    let image = CGRect(x: anchor.x - geometry.side / 2, y: anchor.y - geometry.side / 2,
                                       width: geometry.side, height: geometry.side)
                    precondition(bounds.contains(image), "Artwork must stay in its safe zone and outside Pause")
                    precondition(geometry.clamp(anchor) == anchor, "Repeated layouts cannot drift the first-contact anchor")
                }
                let firstPoint = CGPoint(x: bounds.midX, y: 65)
                let anchor = geometry.clamp(firstPoint)
                precondition(anchor.y < rest.y - 10, "A touch above the resting artwork must visibly move it")
                precondition(geometry.restingPoint == rest, "Release must return to the original resting point")
                layouts += 1
            }
        }
        print("PASS: independent two-thumb ownership, first-contact anchor, unrelated-touch rejection, release/reset safety, and \(layouts) safe portrait/landscape phone/tablet geometries")
    }
}
