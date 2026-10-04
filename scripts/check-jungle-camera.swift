// Compile with the real core module and App/Scene/JungleCamera.swift after swift build.
// Replays ordinary pedal-controlled rides through the production presentation controller.
import Foundation
import CrocoCrossCore

private struct Rider {
    var held = ControlInput.neutral
    mutating func input(_ sim: GameSimulation) -> ControlInput {
        guard sim.state.tick.isMultiple(of: 12) else { return held }
        let b = sim.state.bike
        if b.grounded {
            let pitch = atan((sim.terrainHeight(at: b.position.x + 0.1) - sim.terrainHeight(at: b.position.x - 0.1)) / 0.2)
            let error = atan2(sin(b.angle - pitch), cos(b.angle - pitch))
            let brake = b.velocity.x > 25 || (error > 0.28 && b.velocity.x > 1) ? 1.0 : 0
            let throttle = brake == 0 && b.velocity.x < 24 && error < 0.25 ? 1.0 : 0
            held = .init(throttle: throttle, brake: brake, lean: throttle - brake)
        } else {
            let error = atan2(sin(-0.08 - b.angle), cos(-0.08 - b.angle))
            let effort = error * 2.2 - b.angularVelocity * 0.8
            let throttle = effort > 0.22 ? 1.0 : 0, brake = effort < -0.22 ? 1.0 : 0
            held = .init(throttle: throttle, brake: brake, lean: throttle - brake)
        }
        return held
    }
}

@main struct JungleCameraChecks {
    static func main() throws {
        var config = PhysicsConfiguration(); config.terrainStyle = .junglePlatforms
        var report: [[String: Any]] = []
        var problems: [String] = []
        for seed: UInt32 in [0, 1, 3, 7, 42, 913, .max] {
            let sim = GameSimulation(mode: .weekly, seed: seed, configuration: config)
            let terrain = TerrainGenerator(seed: seed, style: .junglePlatforms)
            var states: [BikeState] = [], rider = Rider()
            for _ in 0..<10_800 {
                states.append(sim.state.bike)
                sim.step(input: rider.input(sim))
                if sim.state.status != .active { break }
            }
            for (width, height) in [(390.0, 844.0), (402, 874), (834, 1194), (1194, 834)] {
                for fps in [30, 60, 120] {
                    var camera = JungleCamera(), previous: JungleCamera.Frame?, previousRate = 0.0
                    var maxOut = 0.0, maxIn = 0.0, maxAcceleration = 0.0
                    var voidFrames = 0, hiddenBankFrames = 0, hiddenRiderFrames = 0
                    var worstBankX = 0.0, worstBankFloor = 0.0, worstRiderTop = 0.0
                    var maximumRiderStep = 0.0, previousRider = Vector2()
                    var minimumScale = Double.infinity, maximumVisibleMetres = 0.0
                    let landscape = width > height, dt = 1.0 / Double(fps)
                    let floor = min(height * 0.38, landscape ? 158.0 : 184.0)
                    let ceiling = height - min(height * 0.20, landscape ? 80.0 : 120.0)
                    for index in stride(from: 0, to: states.count, by: 120 / fps) {
                        let b = states[index], fraction = min(1, abs(b.velocity.x) / 22)
                        let anchor = (landscape ? 0.30 : 0.28) - fraction * (landscape ? 0.06 : 0.04)
                        let view = camera.update(bike: b, width: width, height: height,
                            anchor: anchor, deltaTime: dt, reset: index == 0)
                        minimumScale = min(minimumScale, view.scale)
                        maximumVisibleMetres = max(maximumVisibleMetres, width / view.scale)
                        let rider = Vector2(x: (b.position.x - view.x) * view.scale, y: (b.position.y - view.y) * view.scale)
                        if let previous {
                            let rate = log(view.scale / previous.scale) / dt
                            maxOut = max(maxOut, -rate); maxIn = max(maxIn, rate)
                            maxAcceleration = max(maxAcceleration, abs(rate - previousRate) / dt)
                            maximumRiderStep = max(maximumRiderStep, hypot(rider.x - previousRider.x, rider.y - previousRider.y))
                            previousRate = rate
                        }
                        if !terrain.isSolid(at: b.position.x), !b.grounded {
                            voidFrames += 1
                            let bank = terrain.solidSpans(from: b.position.x, to: b.position.x + 80).first!.lowerBound
                            let bankX = (bank - view.x) * view.scale
                            let bankY = (terrain.height(at: bank) - view.y) * view.scale
                            worstBankX = max(worstBankX, bankX - width * 0.96)
                            worstBankFloor = max(worstBankFloor, floor - bankY)
                            worstRiderTop = max(worstRiderTop, rider.y + 3 * view.scale - ceiling)
                            if bankX < 0 || bankX > width || bankY < floor - 20 || bankY > ceiling { hiddenBankFrames += 1 }
                            if rider.x - 1.7 * view.scale < 0 || rider.x + 1.7 * view.scale > width
                                || rider.y + 3 * view.scale > ceiling + 8 || rider.y - 1.3 * view.scale < floor - 20 { hiddenRiderFrames += 1 }
                        }
                        previous = view; previousRider = rider
                    }
                    let context = "seed=\(seed), \(Int(width))x\(Int(height)), \(fps)fps"
                    if maxOut > 0.480001 || maxIn > 0.220001 || maxAcceleration > 0.900001 || hiddenRiderFrames > 0
                        || minimumScale < 25.5 || maximumVisibleMetres > (landscape ? 26 : 20) {
                        problems.append("\(context): out=\(maxOut), in=\(maxIn), hidden rider=\(hiddenRiderFrames), scale=\(minimumScale), view metres=\(maximumVisibleMetres)")
                    }
                    report.append(["seed": seed, "width": width, "height": height, "fps": fps,
                        "minimumScale": minimumScale, "maximumVisibleMetres": maximumVisibleMetres,
                        "frames": (states.count + 120 / fps - 1) / (120 / fps), "voidFrames": voidFrames,
                        "maxLogZoomOutPerSecond": maxOut, "maxLogZoomInPerSecond": maxIn,
                        "maxLogZoomAcceleration": maxAcceleration, "maximumRiderScreenStep": maximumRiderStep,
                        "hiddenBankFrames": hiddenBankFrames, "hiddenRiderFrames": hiddenRiderFrames,
                        "bankRightMarginExcess": worstBankX, "bankFloorDeficit": worstBankFloor,
                        "riderCeilingExcess": worstRiderTop])
                }
            }
        }
        let data = try JSONSerialization.data(withJSONObject: ["runs": report, "failures": problems], options: [.prettyPrinted, .sortedKeys])
        print(String(decoding: data, as: UTF8.self))
        if !problems.isEmpty {
            for message in problems.prefix(6) { fputs(message + "\n", stderr) }
            exit(1)
        }
        fputs("PASS: \(report.count) production camera replays at 30/60/120 fps; bounded zoom, close framing and visible rider; offscreen receiving banks allowed\n", stderr)
    }
}
