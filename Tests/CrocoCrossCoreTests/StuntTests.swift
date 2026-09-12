import XCTest
@testable import CrocoCrossCore

final class StuntTests: XCTestCase {
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
}
