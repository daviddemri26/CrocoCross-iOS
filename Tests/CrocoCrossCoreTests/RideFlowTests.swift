import Foundation
import XCTest
@testable import CrocoCrossCore

final class RideFlowTests: XCTestCase {
    private var flat: PhysicsConfiguration {
        var configuration = PhysicsConfiguration()
        configuration.terrainStyle = .flat
        return configuration
    }

    private func fixture(speed: Double = 12, height: Double = 2, descent: Double = -2,
                         angle: Double = 0, spin: Double = 0) -> GameSimulation {
        var state = SimulationState(mode: .weekly, seed: 3)
        state.bike.position = .init(x: 3, y: height)
        state.bike.velocity = .init(x: speed, y: descent)
        state.bike.angle = angle
        state.bike.angularVelocity = spin
        return GameSimulation(state: state, configuration: flat)
    }

    /// Put the lower tire at a known clearance without editing the solver's contacts.
    private func oneWheelFixture(angle: Double, clearance: Double = -0.04,
                                 spin: Double = 0) -> GameSimulation {
        let height = flat.wheelRadius + clearance + flat.unloadedAxleOffset * cos(angle)
            + flat.wheelbase * 0.5 * abs(sin(angle))
        return fixture(height: height, descent: 0, angle: angle, spin: spin)
    }

    private func pedals(gas: Bool, brake: Bool) -> ControlInput {
        let gasValue = gas ? 1.0 : 0.0
        let brakeValue = brake ? 1.0 : 0.0
        return .init(throttle: gasValue, brake: brakeValue, lean: gasValue - brakeValue)
    }

    func testFastAngledLandingsKeepMomentumAndDissipateBounceWithoutThrottle() {
        for speed in [12.0, 16, 20] {
            for angle in [-20.0, 20.0].map({ $0 * .pi / 180 }) {
                // -8 m/s covers a hard descent in addition to an ordinary jump.
                for descent in [-2.0, -8.0] {
                    var simulation = fixture(speed: speed, descent: descent, angle: angle)
                    var firstContact: Int?
                    var longestRebound = 0, reboundTicks = 0
                    var maximumReboundSpeed = 0.0
                    let context = "speed=\(speed), pitch=\(angle), descent=\(descent)"
                    for tick in 0 ..< 240 {
                        let previousSpeed = simulation.state.bike.velocity.x
                        simulation.step(input: .neutral)
                        let bike = simulation.state.bike
                        XCTAssertLessThanOrEqual(bike.velocity.x, previousSpeed + 0.000001,
                                                 "A flat landing must not inject forward momentum: \(context)")
                        if firstContact == nil && bike.grounded { firstContact = tick }
                        if firstContact != nil {
                            maximumReboundSpeed = max(maximumReboundSpeed, bike.velocity.y)
                            reboundTicks = bike.grounded ? 0 : reboundTicks + 1
                            longestRebound = max(longestRebound, reboundTicks)
                        }
                    }
                    XCTAssertNotNil(firstContact, context)
                    XCTAssertEqual(simulation.state.status, .active, context)
                    XCTAssertGreaterThan(simulation.state.bike.velocity.x, speed * 0.80,
                                         "Landing and two seconds of coasting must retain useful speed: \(context)")
                    XCTAssertLessThan(maximumReboundSpeed, 2.5, "Suspension must absorb the impact: \(context)")
                    XCTAssertLessThanOrEqual(longestRebound, 24, "No second prolonged flight after landing: \(context)")
                    XCTAssertTrue(simulation.state.bike.rear.contact && simulation.state.bike.front.contact, context)
                    XCTAssertLessThan(abs(simulation.state.bike.velocity.y), 0.1, context)
                    XCTAssertLessThan(abs(simulation.state.bike.angle), 0.06, context)
                }
            }
        }
    }

    func testCoastingStillFollowsGravityWithNoAutomaticUprightTarget() {
        for angle in [-0.6, 0.6] {
            var simulation = fixture(height: 20, descent: 4, angle: angle)
            for _ in 0 ..< 60 { simulation.step(input: .neutral) }
            XCTAssertEqual(simulation.state.bike.velocity.y, 4 - flat.gravity * 0.5, accuracy: 0.000001)
            XCTAssertEqual(simulation.state.bike.angle, angle, accuracy: 0.000001)
            XCTAssertEqual(simulation.state.bike.angularVelocity, 0, accuracy: 0.000001)
            XCTAssertLessThan(simulation.state.bike.velocity.x, 12)
            XCTAssertFalse(simulation.state.bike.grounded)
        }
    }

    func testEitherSingleWheelAllowsBothDirectionsOfRiderBalance() {
        for angle in [-0.4, 0.4] {
            let initial = oneWheelFixture(angle: angle)
            XCTAssertEqual(initial.state.bike.rear.contact, angle > 0)
            XCTAssertEqual(initial.state.bike.front.contact, angle < 0)
            var forward = initial, neutral = initial, backward = initial
            forward.step(input: .init(lean: -1))
            neutral.step(input: .neutral)
            backward.step(input: .init(lean: 1))
            XCTAssertLessThan(forward.state.bike.angularVelocity, neutral.state.bike.angularVelocity - 0.01)
            XCTAssertGreaterThan(backward.state.bike.angularVelocity, neutral.state.bike.angularVelocity + 0.01)
            XCTAssertEqual(forward.state.status, .active)
            XCTAssertEqual(backward.state.status, .active)
        }
    }

    func testRiderBalanceStaysContinuousAcrossFirstTireContact() {
        for angle in [-0.4, 0.4] {
            var responses: [Double] = []
            for clearance in [-0.004, 0.004] {
                let initial = oneWheelFixture(angle: angle, clearance: clearance)
                XCTAssertEqual(initial.state.bike.grounded, clearance < 0)
                var leaning = initial, neutral = initial
                leaning.step(input: .init(lean: 1))
                neutral.step(input: .neutral)
                responses.append(leaning.state.bike.angularVelocity - neutral.state.bike.angularVelocity)
            }
            XCTAssertGreaterThan(responses[0], 0.01, "First touch must retain the free wheel's rider authority.")
            XCTAssertEqual(responses[0], responses[1], accuracy: 0.001,
                           "An 8 mm change across first contact must not switch all air control off.")
        }
    }

    func testBrakeAndForwardBalanceSettleARearWheelWheelieSoonerThanBrakeAlone() {
        let initial = oneWheelFixture(angle: 0.4, spin: 0.5)
        var combined = initial, brakeOnly = initial
        var combinedTouch: Int?, brakeOnlyTouch: Int?
        var combinedPeak = initial.state.bike.angle, brakeOnlyPeak = combinedPeak
        for tick in 1 ... 180 {
            // Release after the front lands: continuing to lean forward on a
            // raised rear wheel is a new rider command, not automatic recovery.
            combined.step(input: combinedTouch == nil ? pedals(gas: false, brake: true) : .neutral)
            brakeOnly.step(input: brakeOnlyTouch == nil ? .init(brake: 1) : .neutral)
            combinedPeak = max(combinedPeak, combined.state.bike.angle)
            brakeOnlyPeak = max(brakeOnlyPeak, brakeOnly.state.bike.angle)
            if combinedTouch == nil && combined.state.bike.front.contact { combinedTouch = tick }
            if brakeOnlyTouch == nil && brakeOnly.state.bike.front.contact { brakeOnlyTouch = tick }
            if tick == 1 {
                XCTAssertLessThan(combined.state.bike.angularVelocity, brakeOnly.state.bike.angularVelocity - 0.01)
            }
        }
        XCTAssertNotNil(combinedTouch)
        XCTAssertNotNil(brakeOnlyTouch)
        XCTAssertLessThan(combinedTouch ?? 181, brakeOnlyTouch ?? 181)
        XCTAssertLessThan(combinedPeak, brakeOnlyPeak)
        XCTAssertEqual(combined.state.status, .active)
        XCTAssertTrue(combined.state.bike.rear.contact && combined.state.bike.front.contact)
        XCTAssertLessThan(abs(combined.state.bike.angle), 0.06)
    }

    func testAllFourBinaryPedalStatesHaveExpectedAirborneBehavior() {
        var neutral = fixture(height: 20, descent: 2, angle: 0.25)
        var gas = neutral, brake = neutral, both = neutral
        for _ in 0 ..< 24 {
            neutral.step(input: pedals(gas: false, brake: false))
            gas.step(input: pedals(gas: true, brake: false))
            brake.step(input: pedals(gas: false, brake: true))
            both.step(input: pedals(gas: true, brake: true))
        }
        XCTAssertGreaterThan(gas.state.bike.angle, neutral.state.bike.angle + 0.05)
        XCTAssertLessThan(brake.state.bike.angle, neutral.state.bike.angle - 0.05)
        XCTAssertEqual(both.state.bike.angle, neutral.state.bike.angle, accuracy: 0.000001)
        for simulation in [gas, brake, both] {
            XCTAssertFalse(simulation.state.bike.grounded)
            XCTAssertEqual(simulation.state.bike.velocity, neutral.state.bike.velocity,
                           "Airborne pedals rotate the bike; they must not propel or brake its flight.")
        }
    }

    func testSimultaneousFullPedalsCatchAFullThrottleWheelie() {
        var initial = GameSimulation(mode: .weekly, seed: 3, configuration: flat)
        for _ in 0 ..< 240 {
            initial.step(input: pedals(gas: true, brake: false))
            if initial.state.bike.angle >= 0.4 { break }
        }
        XCTAssertEqual(initial.state.status, .active)
        XCTAssertTrue(initial.state.bike.rear.contact)
        XCTAssertFalse(initial.state.bike.front.contact)
        XCTAssertGreaterThan(initial.state.bike.angularVelocity, 0)
        var both = initial, gasOnly = initial
        var frontTouch: Int?
        for tick in 1 ... 240 {
            both.step(input: pedals(gas: true, brake: true))
            gasOnly.step(input: pedals(gas: true, brake: false))
            if both.state.bike.front.contact && frontTouch == nil { frontTouch = tick }
            if tick == 1 {
                XCTAssertLessThan(both.state.bike.angularVelocity, gasOnly.state.bike.angularVelocity - 0.025)
            }
        }
        XCTAssertNotNil(frontTouch)
        XCTAssertLessThan(frontTouch ?? 241, 120, "Both pedals must recover within one second without releasing gas.")
        XCTAssertEqual(both.state.status, .active)
        XCTAssertGreaterThan(both.state.bike.throttle, 0.99)
        XCTAssertTrue(both.state.bike.rear.contact && both.state.bike.front.contact)
        XCTAssertLessThan(abs(both.state.bike.angle), 0.1)
    }

    func testFullBrakePedalStopsFastGroundedBikeWithoutPitchOverOrSustainedRollback() {
        for speed in [12.0, 16, 20] {
            var simulation = fixture(speed: speed, height: flat.restingRideHeight, descent: 0)
            var peakPitch = 0.0
            var peakX = simulation.state.bike.position.x, rollback = 0.0
            for _ in 0 ..< 480 {
                simulation.step(input: pedals(gas: false, brake: true))
                peakPitch = max(peakPitch, abs(simulation.state.bike.angle))
                peakX = max(peakX, simulation.state.bike.position.x)
                rollback = max(rollback, peakX - simulation.state.bike.position.x)
            }
            // Suspension and pitch can move the centre of mass slightly backward
            // at a stop; braking must not turn that settling into reverse travel.
            XCTAssertLessThan(rollback, 0.05, "Initial speed \(speed)")
            XCTAssertEqual(simulation.state.status, .active, "Initial speed \(speed)")
            XCTAssertLessThan(abs(simulation.state.bike.velocity.x), 0.1)
            XCTAssertLessThan(peakPitch, 0.5)
            XCTAssertTrue(simulation.state.bike.rear.contact && simulation.state.bike.front.contact)
        }
    }
}
