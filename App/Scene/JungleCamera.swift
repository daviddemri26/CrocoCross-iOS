import Foundation
import CrocoCrossCore

/// A close rider-following view. Gap width and receiving-bank height never
/// change zoom: the far side may enter the frame only as the rider approaches.
struct JungleCamera {
    struct Frame {
        let scale: Double
        let x: Double
        let y: Double
    }

    private var frame: Frame?
    private var zoomVelocity = 0.0

    static func ridingScale(width: Double, height: Double, speed: Double) -> Double {
        let fraction = min(1, abs(speed) / 22)
        let visibleMetres = (width > height ? 24.0 : 17.0) + fraction * 5
        return min(64, max(22, min(width / visibleMetres, height / 14))) * 1.18
    }

    mutating func update(bike: BikeState, width: Double, height: Double,
                         anchor: Double, deltaTime: Double, reset: Bool) -> Frame {
        if reset { self = .init() }
        let dt = min(0.05, max(0, deltaTime))
        let x = bike.position.x, y = bike.position.y
        let desiredScale = Self.ridingScale(width: width, height: height, speed: bike.velocity.x)
        let scale: Double
        if let previous = frame {
            let logarithm = log(previous.scale), destination = log(desiredScale)
            let requested = min(0.22, max(-0.48, (destination - logarithm) * 3.2))
            zoomVelocity += min(0.9 * dt, max(-0.9 * dt, requested - zoomVelocity))
            // Brake progressively even when the moving target crosses the
            // current scale; resetting velocity there would introduce a jerk.
            scale = exp(logarithm + zoomVelocity * dt)
        } else {
            scale = desiredScale
        }

        let desiredX = x - width * anchor / scale
        // Follow the flight itself, with a small vertical lead, rather than
        // pulling toward the invisible ground or the distant receiving bank.
        let verticalLead = min(1.8, max(-1.2, bike.velocity.y * 0.13))
        let desiredY = y + verticalLead - height * 0.44 / scale
        var cameraX = desiredX, cameraY = desiredY
        if let previous = frame {
            // Keep the rider's screen position as the pivot for gradual zoom.
            let pivotX = x - (x - previous.x) * previous.scale / scale
            let pivotY = y - (y - previous.y) * previous.scale / scale
            cameraX = pivotX + (desiredX - pivotX) * (1 - exp(-7 * dt))
            cameraY = pivotY + (desiredY - pivotY) * (1 - exp(-5 * dt))
        }
        let result = Frame(scale: scale, x: cameraX, y: cameraY)
        frame = result
        return result
    }
}
