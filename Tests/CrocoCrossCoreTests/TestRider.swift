import Foundation
@testable import CrocoCrossCore

/// Test-only anticipation of terrain and pitch. Every input obeys the app's two-pedal
/// contract. No position, velocity, suspension or angular state is changed by this rider.
enum TestRider {
    static func controls(_ sim: GameSimulation, speed: Double) -> ControlInput {
        let b = sim.state.bike
        let slope = (sim.terrainHeight(at: b.position.x + 0.1) - sim.terrainHeight(at: b.position.x - 0.1)) / 0.2
        var target = atan(slope)
        if !b.grounded {
            var landingX = b.position.x
            for _ in 0..<3 {
                let height = max(0, b.position.y - sim.terrainHeight(at: landingX) - 0.83)
                let time = max(0.05, min(3.5, (b.velocity.y + sqrt(b.velocity.y * b.velocity.y + 2 * 9.81 * height)) / 9.81))
                landingX = b.position.x + b.velocity.x * time
            }
            target = atan((sim.terrainHeight(at: landingX + 0.1) - sim.terrainHeight(at: landingX - 0.1)) / 0.2)
        }
        let error = atan2(sin(target - b.angle), cos(target - b.angle))
        let lean = b.grounded ? 0 : min(1, max(-1, error * 6 - b.angularVelocity * 2.2))
        let acceleration = (speed - b.velocity.x) * 1.5 + 9.81 * slope
        var throttle = min(0.95, max(0, acceleration * sim.configuration.mass / sim.configuration.maximumDriveForce))
        if b.angle - atan(slope) > 0.15 { throttle = min(0.15, throttle) }
        var brake = acceleration < -1 ? min(0.6, -acceleration * sim.configuration.mass / sim.configuration.brakeForce) : 0
        if b.grounded && b.angle - atan(slope) > 0.12 {
            brake = max(brake, min(0.85, max(0, (b.angle - atan(slope)) * 3 + b.angularVelocity * 0.6)))
            throttle = min(throttle, 0.15)
        }
        // A brake opposes travel: while rolling backwards it cannot lower a wheelie.
        // Let the front settle, then accelerate again rather than holding the rear brake.
        if b.grounded && b.velocity.x < 1 && b.angle - atan(slope) > 0.12 {
            throttle = 0; brake = 0
        }
        if !b.grounded {
            throttle = max(0, lean); brake = max(0, -lean)
        }
        return .init(throttle: throttle, brake: brake, lean: throttle - brake)
    }
}
