import XCTest
@testable import CrocoCrossCore

final class FinishPresentationTests: XCTestCase {
    private func approach(height: Double, angle: Double = 0, speed: Double = 12) -> GameSimulation {
        var configuration = PhysicsConfiguration()
        configuration.terrainStyle = .flat
        var state = SimulationState(mode: .weekly, seed: 42)
        state.bike.position = .init(x: PhysicsConfiguration.courseStartX + GameSimulation.weeklyDistance - 0.02, y: height)
        state.bike.velocity = .init(x: speed, y: 0)
        state.bike.angle = angle
        state.tick = 24_000
        state.distance = GameSimulation.weeklyDistance - 0.02
        state.score = Int(floor(state.distance * 10))
        return GameSimulation(state: state, configuration: configuration)
    }

    private func assertResultUnchanged(_ simulation: GameSimulation, from finish: SimulationState,
                                       file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(simulation.state.status, .finished, file: file, line: line)
        XCTAssertEqual(simulation.state.score, finish.score, file: file, line: line)
        XCTAssertEqual(simulation.state.tick, finish.tick, file: file, line: line)
        XCTAssertEqual(simulation.state.elapsed, finish.elapsed, file: file, line: line)
        XCTAssertEqual(simulation.state.distance, 2_600, file: file, line: line)
        XCTAssertEqual(simulation.state.flips, finish.flips, file: file, line: line)
        XCTAssertEqual(simulation.state.lives, 1, file: file, line: line)
    }

    func testGroundFinishCoastsForFiveSecondsWithoutChangingResult() {
        let simulation = approach(height: PhysicsConfiguration().restingRideHeight)
        XCTAssertEqual(simulation.step(input: .neutral).filter { $0 == .finished }.count, 1)
        let finish = simulation.state
        XCTAssertEqual(finish.score, 27_000)
        XCTAssertEqual(Double(GameSimulation.finishPresentationSteps) * GameSimulation.timeStep /
                       GameSimulation.finishPresentationSpeed, GameSimulation.finishPresentationDuration, accuracy: 0.0001)
        for _ in 0..<GameSimulation.finishPresentationSteps {
            XCTAssertTrue(simulation.step(input: .init(throttle: 1, brake: 1, lean: 1)).isEmpty)
            simulation.stepPresentation(maximumSteps: GameSimulation.finishPresentationSteps)
            assertResultUnchanged(simulation, from: finish)
        }
        XCTAssertGreaterThan(simulation.state.bike.position.x, finish.bike.position.x + 5)
        XCTAssertTrue(simulation.state.rider.isAttached)
        XCTAssertEqual(simulation.state.bike.throttle, 0)
        let end = simulation.state
        for _ in 0..<600 { simulation.stepPresentation(maximumSteps: 10_000) }
        XCTAssertEqual(simulation.state, end, "The celebration has a hard physical budget")
    }

    func testAirborneFinishPreservesMomentumAndLandsWithoutExtraPoints() {
        let simulation = approach(height: 6)
        XCTAssertTrue(simulation.step(input: .neutral).contains(.finished))
        let finish = simulation.state
        XCTAssertFalse(finish.bike.grounded)
        XCTAssertEqual(finish.bike.velocity.x, 12, accuracy: 0.02, "The finish gate must not brake or boost the bike")
        for _ in 0..<60 { simulation.stepPresentation(maximumSteps: 300) }
        XCTAssertGreaterThan(simulation.state.bike.position.x, finish.bike.position.x + 5)
        XCTAssertLessThan(simulation.state.bike.position.y, finish.bike.position.y)
        for _ in 0..<240 { simulation.stepPresentation(maximumSteps: 300) }
        assertResultUnchanged(simulation, from: finish)
        XCTAssertTrue(simulation.state.bike.grounded)
    }

    func testHeadFirstFallAfterLineDetachesButKeepsVictory() {
        let simulation = approach(height: 4, angle: .pi)
        let events = simulation.step(input: .neutral)
        XCTAssertTrue(events.contains(.finished))
        XCTAssertFalse(events.contains(.crashed))
        let finish = simulation.state
        XCTAssertTrue(finish.rider.isAttached)
        var detachedAt: Vector2?
        for _ in 0..<300 {
            simulation.stepPresentation(maximumSteps: 300)
            if !simulation.state.rider.isAttached && detachedAt == nil {
                detachedAt = simulation.state.rider.torso.position
            }
            assertResultUnchanged(simulation, from: finish)
        }
        XCTAssertNotNil(detachedAt, "A post-finish head impact still releases the physical rider")
        XCTAssertNotEqual(simulation.state.rider.torso.position, detachedAt)
        XCTAssertTrue(simulation.state.rider.torso.position.x.isFinite)
        XCTAssertTrue(simulation.step(input: .neutral).isEmpty)
    }

    func testPresentationCannotAdvanceAnUnfinishedRide() {
        let simulation = approach(height: 4)
        let before = simulation.state
        for _ in 0..<300 { simulation.stepPresentation(maximumSteps: 300) }
        XCTAssertEqual(simulation.state, before)
    }
}
