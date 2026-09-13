import XCTest
@testable import CrocoCrossCore

final class StuntTests: XCTestCase {
    func testDisplayedComboBonusMatchesTheScoringContractAndStaysBounded() {
        XCTAssertEqual(GameSimulation.flipBonus(for: 1), 1_000)
        XCTAssertEqual(GameSimulation.flipBonus(for: 2), 3_000)
        XCTAssertEqual(GameSimulation.flipBonus(for: 3), 7_000)
        XCTAssertEqual(GameSimulation.flipBonus(for: 0), 0)
        XCTAssertEqual(GameSimulation.flipBonus(for: -1), 0)
        XCTAssertEqual(GameSimulation.flipBonus(for: Int.max), 65_535_000)
    }

    func testTurnsInEitherDirectionWaitForASafeLandingAndBankOnlyOnce() {
        for direction in [-1.0, 1] {
            for turns in 1 ... 3 {
                var tracker = StuntTracker()
                let ticks = 90 * turns, delta = direction * Double.pi * 2 / 90
                var angle = 0.0
                for _ in 0 ..< ticks {
                    angle += delta
                    XCTAssertEqual(tracker.advance(delta: delta, orientation: atan2(sin(angle), cos(angle)), airborne: true, safeContact: false), 0)
                }
                for _ in 0 ..< 7 {
                    XCTAssertEqual(tracker.advance(delta: 0, orientation: 0, airborne: false, safeContact: true), 0)
                }
                XCTAssertEqual(tracker.advance(delta: 0, orientation: 0, airborne: false, safeContact: true), turns)
                XCTAssertEqual(tracker.advance(delta: 0, orientation: 0, airborne: false, safeContact: true), 0)
            }
        }
    }

    func testRockingAndInvertedOrCrashedLandingsDoNotAwardPoints() {
        var tracker = StuntTracker(), angle = 0.0
        for tick in 0 ..< 300 {
            let delta = tick % 60 < 30 ? 0.04 : -0.04
            angle += delta
            XCTAssertEqual(tracker.advance(delta: delta, orientation: angle, airborne: true, safeContact: false), 0)
        }
        for _ in 0 ..< 20 { XCTAssertEqual(tracker.advance(delta: 0, orientation: 0, airborne: false, safeContact: true), 0) }
        for tick in 0 ..< 90 {
            let theta = Double(tick + 1) * .pi * 2 / 90
            XCTAssertEqual(tracker.advance(delta: .pi * 2 / 90, orientation: atan2(sin(theta), cos(theta)), airborne: true, safeContact: false), 0)
        }
        for _ in 0 ..< 20 { XCTAssertEqual(tracker.advance(delta: 0, orientation: .pi, airborne: false, safeContact: false), 0) }
        tracker.clear()
        for _ in 0 ..< 20 { XCTAssertEqual(tracker.advance(delta: 0, orientation: 0, airborne: false, safeContact: true), 0) }
    }

    func testPhysicalFlipBanksScoreAfterLanding() {
        var c = PhysicsConfiguration(); c.terrainStyle = .flat
        var state = SimulationState(mode: .weekly, seed: 1)
        state.bike.position = .init(x: 3, y: 16)
        state.bike.velocity.x = 8; state.bike.angularVelocity = 6
        var sim = GameSimulation(state: state, configuration: c)
        var awards = 0
        for _ in 0 ..< 120 * 5 {
            let lean = sim.state.elapsed > 0.4 && sim.state.bike.angularVelocity > 0.05 ? -1.0 : 0
            for event in sim.step(input: .init(lean: lean)) {
                if case let .flip(count) = event {
                    XCTAssertTrue(sim.state.bike.grounded)
                    awards += count
                }
            }
        }
        XCTAssertEqual(sim.state.status, .active)
        XCTAssertEqual(sim.state.flips, 1)
        XCTAssertEqual(awards, 1)
        XCTAssertEqual(sim.state.score, Int(floor(sim.state.distance * 10)) + 1_000)
    }

    func testSeededRampsAllowARealFlipAndSafeReceptionWithTheTwoAppPedals() {
        for (seed, chosenFlight): (UInt32, Int) in [(3, 3), (8, 5), (11, 3)] {
            var sim = GameSimulation(mode: .weekly, seed: seed)
            var wasGrounded = true, flight = 0, attempting = false
            var unwrappedAngle = 0.0, priorAngle = 0.0, maxClearance = 0.0
            var airTicks = 0, awarded = 0, awardTick: Int?, landingDistance = 0.0
            for _ in 0 ..< 120 * 45 {
                let bike = sim.state.bike
                if wasGrounded && !bike.grounded {
                    flight += 1
                    if flight == chosenFlight {
                        attempting = true; unwrappedAngle = bike.angle; priorAngle = bike.angle
                    }
                }
                var input = TestRider.controls(sim, speed: 16)
                if attempting && !bike.grounded {
                    unwrappedAngle += atan2(sin(bike.angle - priorAngle), cos(bike.angle - priorAngle))
                    priorAngle = bike.angle; airTicks += 1
                    maxClearance = max(maxClearance, bike.position.y - sim.terrainHeight(at: bike.position.x) - sim.configuration.restingRideHeight)
                    let error = Double.pi * 2 - 0.2 - unwrappedAngle
                    let stoppingAngle = bike.angularVelocity * abs(bike.angularVelocity) / (2 * 4.1)
                    let lean = error > 1.2 ? (error > stoppingAngle + 0.06 ? 1.0 : -1.0)
                        : min(1, max(-1, error * 6 - bike.angularVelocity * 2.2))
                    input = .init(throttle: max(0, lean), brake: max(0, -lean), lean: lean)
                }
                XCTAssertEqual(input.lean, input.throttle - input.brake)
                wasGrounded = bike.grounded
                for event in sim.step(input: input) {
                    if case let .flip(count) = event {
                        XCTAssertTrue(sim.state.bike.grounded, "A flight alone must never award the combo.")
                        awarded += count; awardTick = sim.state.tick; landingDistance = sim.state.distance
                    }
                }
                if attempting && sim.state.bike.grounded { attempting = false }
                if sim.state.status != .active { break }
                if let awardTick, sim.state.tick >= awardTick + 120 * 3 { break }
            }
            XCTAssertEqual(awarded, 1, "seed=\(seed)")
            XCTAssertEqual(sim.state.flips, 1)
            XCTAssertEqual(sim.state.status, .active, "The rider must keep riding for three seconds after reception.")
            XCTAssertGreaterThan(sim.state.distance, landingDistance + 10)
            XCTAssertGreaterThan(airTicks, 200)
            XCTAssertGreaterThan(maxClearance, 3.5)
            XCTAssertEqual(sim.state.score, Int(floor(sim.state.distance * 10)) + GameSimulation.flipBonus(for: 1))
        }
    }
}
