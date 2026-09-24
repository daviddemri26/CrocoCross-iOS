import Foundation
import CrocoCrossCore

/// Cosmetic two-link motion, in world radians/metres. It cannot apply forces to
/// Box2D or affect collisions, scoring or the rider's physical flight path.
struct DetachedLimbMotion {
    private(set) var upper: Double
    private(set) var lower: Double
    private var upperSpeed: Double
    private var lowerSpeed: Double
    private var previousVelocity: Vector2
    private var acceleration = Vector2()
    private var previousBodyAngle: Double

    init(upper: Double, lower: Double, body: RigidBodyState, side: Double) {
        self.upper = upper
        self.lower = lower
        // Release from the actual riding pose, carrying the body's rotation.
        upperSpeed = body.angularVelocity * (0.9 + side * 0.12)
        lowerSpeed = body.angularVelocity * (0.65 - side * 0.12)
        previousVelocity = body.velocity
        previousBodyAngle = body.angle
    }

    mutating func advance(dt: Double, body: RigidBodyState, bodyAngle: Double,
                          upperLength: Double, lowerLength: Double, isLeg: Bool,
                          side: Double, reducedMotion: Bool) {
        guard dt > 0, dt.isFinite else { return }
        // A resumed/hidden view must never integrate a large accumulated jump.
        let elapsed = min(dt, 0.1)
        let blend = 1 - exp(-elapsed * 24)
        acceleration.x += (clamp((body.velocity.x - previousVelocity.x) / elapsed, -35, 35) - acceleration.x) * blend
        acceleration.y += (clamp((body.velocity.y - previousVelocity.y) / elapsed, -35, 35) - acceleration.y) * blend
        previousVelocity = body.velocity
        // Gravity relative to the moving body: airborne limbs keep their inertia;
        // impact deceleration sends them swinging instead of pinning them down.
        let force = Vector2(x: -acceleration.x - body.velocity.x * 0.10,
                            y: -9.81 - acceleration.y - body.velocity.y * 0.06)
        let count = max(1, Int(ceil(elapsed * 240)))
        let h = elapsed / Double(count)
        let startAngle = previousBodyAngle
        let turn = wrapped(body.angle - startAngle)
        let visualOffset = wrapped(bodyAngle - body.angle)
        let damping = reducedMotion ? 2.8 : 0.85
        let response = reducedMotion ? 0.55 : 1.0
        let sign = isLeg ? -1.0 : 1.0
        for step in 1...count {
            let parent = startAngle + turn * Double(step) / Double(count) + visualOffset
            let flex = wrapped(lower - upper) * sign
            let restFlex = (isLeg ? 0.32 : 0.20) + side * 0.09
            let hinge = (restFlex - flex) * (isLeg ? 10 : 7) - (lowerSpeed - upperSpeed) * sign * 0.55
            let rest = parent - .pi / 2 + side * (isLeg ? 0.18 : 0.35)
            let gravityUpper = (cos(upper) * force.y - sin(upper) * force.x) / max(0.15, upperLength)
            let gravityLower = (cos(lower) * force.y - sin(lower) * force.x) / max(0.15, lowerLength)
            upperSpeed += (gravityUpper * response + wrapped(rest - upper) * (isLeg ? 3.5 : 1.8)
                           - hinge * sign * 0.32 - upperSpeed * damping) * h
            lowerSpeed += (gravityLower * response + hinge * sign - lowerSpeed * damping) * h
            upperSpeed = clamp(upperSpeed, -18, 18)
            lowerSpeed = clamp(lowerSpeed, -20, 20)
            upper += upperSpeed * h
            lower += lowerSpeed * h

            // Broad shoulders/hips; elbows and knees bend in their anatomical
            // direction. Soft restitution avoids a locked mechanical stop.
            let minRoot = isLeg ? -2.8 : -3.5
            let maxRoot = isLeg ? 0.65 : 1.2
            let centre = (minRoot + maxRoot) / 2
            let relative = centre + wrapped(upper - parent - centre)
            let bounded = clamp(relative, minRoot, maxRoot)
            if relative != bounded {
                upper += bounded - relative
                upperSpeed = body.angularVelocity - (upperSpeed - body.angularVelocity) * 0.15
            }
            let bend = wrapped(lower - upper) * sign
            let limit = clamp(bend, 0.015, isLeg ? 2.45 : 2.65)
            if bend != limit {
                lower += (limit - bend) * sign
                lowerSpeed = upperSpeed - (lowerSpeed - upperSpeed) * 0.18
            }
        }
        previousBodyAngle = body.angle
    }

    private func wrapped(_ angle: Double) -> Double { atan2(sin(angle), cos(angle)) }
    private func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double { min(high, max(low, value)) }
}
