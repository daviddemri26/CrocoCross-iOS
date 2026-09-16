import Foundation
import XCTest
@testable import CrocoCrossCore

final class LandingStabilityTests: XCTestCase {
    private var flat: PhysicsConfiguration {
        var c = PhysicsConfiguration(); c.terrainStyle = .flat; return c
    }

    private func initial(speed: Double = 16, height: Double = 2, descent: Double = -8,
                         angle: Double = 0, spin: Double = 0) -> SimulationState {
        var state = SimulationState(mode: .weekly, seed: 3)
        state.bike.position = .init(x: 3, y: height)
        state.bike.velocity = .init(x: speed, y: descent)
        state.bike.angle = angle; state.bike.angularVelocity = spin
        return state
    }

    func testAlmostLevelHardLandingsDoNotKickTheRearUp() {
        for speed in [12.0, 16, 20] {
            for angle in [-0.02, 0, 0.02] {
                for descent in [-8.0, -12, -16] {
                    var sim = GameSimulation(state: initial(speed: speed, descent: descent, angle: angle), configuration: flat)
                    var touched = false, peakSpin = 0.0, rebound = 0.0, peakPitch = 0.0, rearAirTicks = 0
                    var compression = 0.0
                    for _ in 0 ..< 180 {
                        let beforeSpeed = sim.state.bike.velocity.x
                        sim.step(input: .neutral)
                        let bike = sim.state.bike
                        touched = touched || bike.grounded
                        if touched {
                            peakSpin = max(peakSpin, abs(bike.angularVelocity))
                            rebound = max(rebound, bike.velocity.y)
                            peakPitch = max(peakPitch, abs(bike.angle))
                            compression = max(compression, bike.rear.compression, bike.front.compression)
                            if bike.front.contact && !bike.rear.contact { rearAirTicks += 1 }
                        }
                        XCTAssertLessThanOrEqual(bike.velocity.x, beforeSpeed + 0.000001)
                    }
                    let context = "speed=\(speed), angle=\(angle), descent=\(descent)"
                    XCTAssertTrue(touched, context)
                    XCTAssertEqual(sim.state.status, .active, context)
                    XCTAssertLessThan(peakSpin, 1.2, "Nearly simultaneous tire impacts must not create a pitch impulse: \(context)")
                    XCTAssertLessThan(peakPitch, 0.05, context)
                    XCTAssertLessThan(rebound, 1.2, context)
                    XCTAssertLessThanOrEqual(rearAirTicks, 2, context)
                    XCTAssertGreaterThan(sim.state.bike.velocity.x, speed * 0.90, context)
                    XCTAssertTrue(sim.state.bike.front.contact && sim.state.bike.rear.contact, context)
                    if descent <= -12 {
                        XCTAssertGreaterThan(compression, 0.37, "The regression must exercise the suspension stops.")
                    }
                }
            }
        }
    }

    func testLevelBottomStopsDoNotPickADirectionAtZeroForwardSpeed() {
        for descent in [-12.0, -16, -20] {
            var sim = GameSimulation(state: initial(speed: 0, height: 0.55, descent: descent), configuration: flat)
            for _ in 0 ..< 180 {
                sim.step(input: .neutral)
                XCTAssertEqual(sim.state.bike.angle, 0, accuracy: 0.0000001)
                XCTAssertEqual(sim.state.bike.angularVelocity, 0, accuracy: 0.0000001)
                XCTAssertEqual(sim.state.bike.velocity.x, 0, accuracy: 0.0000001)
            }
            XCTAssertEqual(sim.state.status, .active)
            XCTAssertTrue(sim.state.bike.front.contact && sim.state.bike.rear.contact)
        }
    }

    func testPassiveSuspensionAndPairedStopsDoNotAddEnergy() {
        func energy(_ sim: GameSimulation) -> Double {
            let b = sim.state.bike, c = sim.configuration
            return 0.5 * c.mass * (b.velocity.x * b.velocity.x + b.velocity.y * b.velocity.y)
                + 0.5 * c.inertia * b.angularVelocity * b.angularVelocity
                + c.mass * c.gravity * b.position.y
                + 0.5 * c.springRate * (b.rear.compression * b.rear.compression + b.front.compression * b.front.compression)
        }
        for angle in [-0.7, -0.35, 0, 0.35, 0.7] {
            for descent in [-15.0, -10, -5, 0, 5] {
                for spin in [-5.0, 0, 5] {
                    var sim = GameSimulation(state: initial(height: 3, descent: descent, angle: angle, spin: spin), configuration: flat)
                    var previous = energy(sim)
                    for _ in 0 ..< 600 {
                        sim.step(input: .neutral)
                        let current = energy(sim)
                        XCTAssertLessThanOrEqual(current, previous + 0.00001)
                        previous = current
                        if sim.state.status != .active { break }
                    }
                }
            }
        }
    }

    func testExtraForwardEffortIsLimitedToRearSupportedWheelies() {
        let current = flat
        var originalEffort = current; originalEffort.forwardWheelieBalance = 1
        for stance in ["rear", "front", "both", "air"] {
            let angle = stance == "rear" ? 0.45 : stance == "front" ? -0.45 : 0
            let height = stance == "air" ? 10 : current.wheelRadius + current.unloadedAxleOffset * cos(angle)
                + current.wheelbase * 0.5 * abs(sin(angle)) - 0.06
            let state = initial(height: height, descent: 0, angle: angle)
            for lean in [-1.0, 0, 1] {
                var boosted = GameSimulation(state: state, configuration: current)
                var reference = GameSimulation(state: state, configuration: originalEffort)
                boosted.step(input: .init(lean: lean))
                reference.step(input: .init(lean: lean))
                if stance == "rear" && lean < 0 {
                    var coasting = GameSimulation(state: state, configuration: current)
                    coasting.step(input: .neutral)
                    let originalResponse = coasting.state.bike.angularVelocity - reference.state.bike.angularVelocity
                    let boostedResponse = coasting.state.bike.angularVelocity - boosted.state.bike.angularVelocity
                    XCTAssertGreaterThan(boostedResponse, originalResponse * 1.7)
                    XCTAssertLessThan(boostedResponse, originalResponse * 1.9)
                } else {
                    XCTAssertEqual(boosted.state.bike.angle, reference.state.bike.angle, stance)
                    XCTAssertEqual(boosted.state.bike.velocity, reference.state.bike.velocity, stance)
                }
            }
        }
    }

    func testForwardWheelieEffortFadesSmoothlyAsRearSupportDisappears() {
        var referenceConfig = flat; referenceConfig.forwardWheelieBalance = 1
        let angle = 0.45
        var extras: [Double] = []
        for compression in [-0.002, 0, 0.002] {
            let height = flat.wheelRadius + flat.unloadedAxleOffset * cos(angle)
                + flat.wheelbase * 0.5 * sin(angle) - compression
            let state = initial(height: height, descent: 0, angle: angle)
            var boosted = GameSimulation(state: state, configuration: flat)
            var reference = GameSimulation(state: state, configuration: referenceConfig)
            boosted.step(input: .init(lean: -1)); reference.step(input: .init(lean: -1))
            extras.append(reference.state.bike.angularVelocity - boosted.state.bike.angularVelocity)
        }
        XCTAssertEqual(extras[0], 0, accuracy: 0.00001)
        XCTAssertLessThan(abs(extras[2] - extras[0]), 0.0003, "No torque jump at first rear-wheel contact.")
    }
}
