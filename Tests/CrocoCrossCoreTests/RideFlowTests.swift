import Foundation
import XCTest
@testable import CrocoCrossCore

final class RideFlowTests: XCTestCase {
    private func wheelie() -> GameSimulation {
        let c = flatConfiguration, angle = 0.4
        let loaded = c.unloadedAxleOffset - c.suspensionTravel * c.suspensionSag
        let height = c.wheelRadius + loaded * cos(angle) + c.wheelbase * 0.5 * sin(angle)
        let sim = flatFixture(height: height, descent: 0, angle: angle, spin: 0.5)
        for _ in 0..<3 { sim.step(input: .neutral) }
        return sim
    }
    private func stance(angle: Double, configuration: PhysicsConfiguration? = nil) -> GameSimulation {
        let c = flatConfiguration
        let loaded = c.unloadedAxleOffset - c.suspensionTravel * c.suspensionSag
        let height = c.wheelRadius + loaded * cos(angle) + c.wheelbase * 0.5 * abs(sin(angle))
        let sim = flatFixture(height: height, descent: 0, angle: angle, configuration: configuration)
        for _ in 0..<3 { sim.step(input: .neutral) }
        return sim
    }

    func testDriveBuildsSpeedAndTransfersLoadWithoutImmediateFlatGroundCrash() {
        let hard = GameSimulation(mode: .weekly, seed: 42, configuration: flatConfiguration)
        let metered = GameSimulation(mode: .weekly, seed: 42, configuration: flatConfiguration)
        var hardAngle = 0.0, meteredAngle = 0.0
        for _ in 0..<1_200 {
            hard.step(input: .init(throttle: 1, lean: 1)); metered.step(input: .init(throttle: 0.38))
            hardAngle = max(hardAngle, hard.state.bike.angle); meteredAngle = max(meteredAngle, metered.state.bike.angle)
        }
        XCTAssertGreaterThan(hardAngle, meteredAngle + 0.04)
        XCTAssertLessThan(meteredAngle, 0.15)
        XCTAssertEqual(metered.state.status, .active); XCTAssertEqual(hard.state.status, .active)
        XCTAssertGreaterThan(metered.state.bike.velocity.x, 15)
        XCTAssertGreaterThan(hard.state.bike.velocity.x, metered.state.bike.velocity.x)
    }

    func testReleasingThrottleRecoversAnExistingWheelie() {
        let sim = wheelie()
        for _ in 0..<600 { sim.step(input: .neutral) }
        XCTAssertEqual(sim.state.status, .active)
        XCTAssertLessThan(abs(sim.state.bike.angle), 0.08)
        XCTAssertTrue(sim.state.bike.rear.contact && sim.state.bike.front.contact)
    }

    func testBothPedalsCatchWheelieWhileThrottleRemainsHeld() {
        let both = wheelie(), gas = wheelie()
        XCTAssertTrue(both.state.bike.rear.contact); XCTAssertFalse(both.state.bike.front.contact)
        var frontTouch: Int?
        for tick in 1...240 {
            both.step(input: .init(throttle: 1, brake: 1)); gas.step(input: .init(throttle: 1, lean: 1))
            if both.state.bike.front.contact && frontTouch == nil { frontTouch = tick }
            if tick == 1 { XCTAssertLessThan(both.state.bike.angularVelocity, gas.state.bike.angularVelocity) }
        }
        XCTAssertNotNil(frontTouch); XCTAssertLessThan(frontTouch ?? 241, 120)
        XCTAssertEqual(both.state.status, .active); XCTAssertGreaterThan(both.state.bike.throttle, 0.99)
        XCTAssertTrue(both.state.bike.rear.contact && both.state.bike.front.contact)
        XCTAssertLessThan(abs(both.state.bike.angle), 0.1)
    }

    func testEitherSingleWheelAllowsBothBalanceDirections() {
        for angle in [-0.4, 0.4] {
            let left = stance(angle: angle), neutral = stance(angle: angle), right = stance(angle: angle)
            XCTAssertEqual(neutral.state.bike.rear.contact, angle > 0)
            XCTAssertEqual(neutral.state.bike.front.contact, angle < 0)
            for _ in 0..<6 {
                left.step(input: .init(lean: -1)); neutral.step(input: .neutral); right.step(input: .init(lean: 1))
            }
            XCTAssertLessThan(left.state.bike.angularVelocity, neutral.state.bike.angularVelocity - 0.03)
            XCTAssertGreaterThan(right.state.bike.angularVelocity, neutral.state.bike.angularVelocity + 0.03)
        }
    }

    func testExtraLeftEffortOnlyActsInRearSupportedWheelie() {
        var standard = flatConfiguration; standard.forwardWheelieBalance = 1
        for angle in [-0.4, 0.4] {
            for lean in [-1.0, 1.0] {
                let boosted = stance(angle: angle), reference = stance(angle: angle, configuration: standard)
                for _ in 0..<6 { boosted.step(input: .init(lean: lean)); reference.step(input: .init(lean: lean)) }
                if angle > 0 && lean < 0 {
                    XCTAssertLessThan(boosted.state.bike.angularVelocity, reference.state.bike.angularVelocity - 0.01)
                } else {
                    XCTAssertEqual(boosted.state.bike.angle, reference.state.bike.angle, accuracy: 0.00001)
                }
            }
        }
    }

    func testAirPedalsRotateWithoutPropellingAssembly() {
        let neutral = flatFixture(height: 20, descent: 2, angle: 0.25)
        let gas = flatFixture(height: 20, descent: 2, angle: 0.25)
        let brake = flatFixture(height: 20, descent: 2, angle: 0.25)
        let both = flatFixture(height: 20, descent: 2, angle: 0.25)
        for _ in 0..<36 {
            neutral.step(input: .neutral); gas.step(input: .init(throttle: 1, lean: 1))
            brake.step(input: .init(brake: 1, lean: -1)); both.step(input: .init(throttle: 1, brake: 1))
        }
        XCTAssertGreaterThan(gas.state.bike.angle, neutral.state.bike.angle + 0.1)
        XCTAssertLessThan(brake.state.bike.angle, neutral.state.bike.angle - 0.1)
        // Wheel braking exchanges angular momentum with the chassis even when net lean is zero.
        XCTAssertLessThan(abs(both.state.bike.angle - neutral.state.bike.angle), 0.15)
        for sim in [gas, brake, both] {
            XCTAssertEqual(sim.diagnostics.centerOfMassVelocity.x, neutral.diagnostics.centerOfMassVelocity.x, accuracy: 0.003)
            XCTAssertEqual(sim.diagnostics.centerOfMassVelocity.y, neutral.diagnostics.centerOfMassVelocity.y, accuracy: 0.003)
            XCTAssertFalse(sim.state.bike.grounded)
        }
    }

    func testFullBrakeStopsWithoutPitchOverOrSustainedReverse() {
        for speed in [12.0, 16, 20] {
            let sim = flatFixture(speed: speed, height: flatConfiguration.restingRideHeight, descent: 0)
            var peakPitch = 0.0, peakX = sim.state.bike.position.x, rollback = 0.0
            for _ in 0..<480 {
                sim.step(input: .init(brake: 1, lean: -1))
                peakPitch = max(peakPitch, abs(sim.state.bike.angle)); peakX = max(peakX, sim.state.bike.position.x)
                rollback = max(rollback, peakX - sim.state.bike.position.x)
            }
            XCTAssertLessThan(rollback, 0.15) // Includes the rider's 12cm posture shift while the tires stop.
            XCTAssertEqual(sim.state.status, .active)
            XCTAssertLessThan(abs(sim.state.bike.velocity.x), 0.1); XCTAssertLessThan(peakPitch, 0.5)
            XCTAssertTrue(sim.state.bike.rear.contact && sim.state.bike.front.contact)
        }
    }

    func testTerrainCorpusFlowsWithActualBinaryPedalHolds() {
        for speed in [12.0, 16] {
            for seed: UInt32 in 1...12 {
                let sim = GameSimulation(mode: .endless, seed: seed)
                var rider = PulsedTestRider(), crashes = 0, jumps = 0, previouslyGrounded = false
                var longestFlight = 0, flight = 0
                for _ in 0..<7_200 {
                    let input = rider.controls(sim, speed: speed)
                    XCTAssertTrue([0.0, 1].contains(input.throttle)); XCTAssertTrue([0.0, 1].contains(input.brake))
                    crashes += sim.step(input: input).filter { $0 == .crashed }.count
                    if previouslyGrounded && !sim.state.bike.grounded { jumps += 1 }
                    flight = sim.state.bike.grounded ? 0 : flight + 1
                    longestFlight = max(longestFlight, flight); previouslyGrounded = sim.state.bike.grounded
                }
                let context = "seed=\(seed), target=\(speed)"
                XCTAssertEqual(crashes, 0, context); XCTAssertEqual(sim.state.status, .active, context)
                XCTAssertEqual(sim.state.lives, 3, context); XCTAssertGreaterThan(jumps, 4, context)
                XCTAssertGreaterThan(longestFlight, 150, context)
                XCTAssertGreaterThan(sim.state.distance, speed == 12 ? 650 : 730, context)
            }
        }
    }
    func testForwardBalanceSupplementsRealWheelBraking() {
        let combined = wheelie(), brakeOnly = wheelie()
        for _ in 0..<6 {
            combined.step(input: .init(brake: 1, lean: -1))
            brakeOnly.step(input: .init(brake: 1))
        }
        XCTAssertLessThan(combined.state.bike.angularVelocity, brakeOnly.state.bike.angularVelocity - 0.03)
    }

    func testRiderActuallyMovesRelativeToBikeWhenBalancing() {
        let left = flatFixture(height: 20, descent: 2), right = flatFixture(height: 20, descent: 2)
        for _ in 0..<48 { left.step(input: .init(lean: -1)); right.step(input: .init(lean: 1)) }
        let a = rotated(left.state.rider.pelvis.position - left.state.bike.position, by: -left.state.bike.angle)
        let b = rotated(right.state.rider.pelvis.position - right.state.bike.position, by: -right.state.bike.angle)
        XCTAssertGreaterThan(a.x, 0.06); XCTAssertLessThan(b.x, -0.06)
        XCTAssertTrue(left.state.rider.isAttached && right.state.rider.isAttached)
        XCTAssertLessThanOrEqual(left.diagnostics.attachmentForce, 150 * 9.81 * 6 + 1)
    }

    func testBothPedalsAddBrakingEffortWhileRollingBackward() {
        var stopTicks: [Int] = [], distances: [Double] = [], initialSpeeds: [Double] = []
        for throttle in [0.0, 1.0] {
            let sim = flatFixture(speed: -5, height: flatConfiguration.restingRideHeight, descent: 0)
            var stop = 240
            for tick in 1...240 {
                sim.step(input: .init(throttle: throttle, brake: 1))
                if tick == 24 { initialSpeeds.append(sim.diagnostics.centerOfMassVelocity.x) }
                if sim.state.bike.velocity.x > -0.1 { stop = tick; break }
            }
            stopTicks.append(stop); distances.append(3 - sim.state.bike.position.x)
            XCTAssertEqual(sim.state.status, .active)
        }
        // Stronger deceleration produces more nose-up load transfer. The final
        // chassis settling can last a few ticks longer while travel is shorter.
        XCTAssertGreaterThan(initialSpeeds[1], initialSpeeds[0] + 0.3)
        XCTAssertLessThanOrEqual(stopTicks[1], stopTicks[0] + 12)
        XCTAssertLessThanOrEqual(distances[1], distances[0] + 0.01)
    }

}
