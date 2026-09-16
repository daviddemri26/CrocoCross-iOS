import Foundation
import XCTest
@testable import CrocoCrossCore

final class OriginLifecycleTests: XCTestCase {
    func testRebaseOnEitherSingleWheelPreservesTheWholeRig() {
        let c = flatConfiguration
        let loadedOffset = c.unloadedAxleOffset - c.suspensionTravel * c.suspensionSag
        for angle in [-0.4, 0.4] {
            let height = c.wheelRadius + loadedOffset * cos(angle) + c.wheelbase * 0.5 * abs(sin(angle))
            let reference = flatFixture(height: height, descent: 0, angle: angle)
            let shifted = flatFixture(height: height, descent: 0, angle: angle)
            for _ in 0..<3 { reference.step(input: .neutral); shifted.step(input: .neutral) }
            XCTAssertEqual(shifted.state.bike.rear.contact, angle > 0)
            XCTAssertEqual(shifted.state.bike.front.contact, angle < 0)
            let before = shifted.state
            shifted.rebaseForTesting(by: .init(x: 256, y: -256))
            XCTAssertEqual(shifted.state, before)
            for _ in 0..<120 {
                reference.step(input: .neutral); shifted.step(input: .neutral)
                assertRig(shifted.state, matches: reference.state)
                assertWorldIsBounded(shifted)
            }
            XCTAssertEqual(shifted.state.status, .active)
            XCTAssertTrue(shifted.state.bike.rear.contact && shifted.state.bike.front.contact)
        }
    }

    func testRebaseAtFullSuspensionCompressionDoesNotReleaseAnExtraImpulse() {
        let reference = flatFixture(speed: 12, height: 1.5, descent: -10)
        let shifted = flatFixture(speed: 12, height: 1.5, descent: -10)
        var reachedLimit = false
        for _ in 0..<120 {
            reference.step(input: .neutral); shifted.step(input: .neutral)
            if max(shifted.state.bike.rear.compression, shifted.state.bike.front.compression)
                >= shifted.configuration.suspensionTravel {
                reachedLimit = true
                break
            }
        }
        XCTAssertTrue(reachedLimit, "The real wheel-joint limit must be loaded before translating the world.")
        XCTAssertEqual(shifted.state.status, .active)
        XCTAssertTrue(shifted.state.bike.rear.contact && shifted.state.bike.front.contact)
        let before = shifted.state
        shifted.rebaseForTesting(by: .init(x: 256, y: -256))
        XCTAssertEqual(shifted.state, before)
        var wheelPhase = [0.0, 0.0]
        for _ in 0..<240 {
            let oldSpinDifference = [shifted.state.bike.rear.angularVelocity - reference.state.bike.rear.angularVelocity,
                                     shifted.state.bike.front.angularVelocity - reference.state.bike.front.angularVelocity]
            reference.step(input: .neutral); shifted.step(input: .neutral)
            let spinDifference = [shifted.state.bike.rear.angularVelocity - reference.state.bike.rear.angularVelocity,
                                  shifted.state.bike.front.angularVelocity - reference.state.bike.front.angularVelocity]
            // Small Float differences in wheel speed legitimately accumulate rotor phase.
            // Still reject any phase jump that is not explained by those measured speeds.
            for index in 0..<2 {
                wheelPhase[index] += (oldSpinDifference[index] + spinDifference[index]) * 0.5 * GameSimulation.timeStep
            }
            assertRig(shifted.state, matches: reference.state, wheelPhase: wheelPhase)
            assertWorldIsBounded(shifted)
        }
        XCTAssertEqual(shifted.state.status, .active)
        XCTAssertTrue(shifted.state.bike.rear.contact && shifted.state.bike.front.contact)
    }

    func testReverseCoastingCrossesChunkSeamsAndRebasesWithoutAContactKick() {
        let sim = flatFixture(speed: -20, height: flatConfiguration.restingRideHeight, descent: 0, x: 14)
        var seams = 0, rebases = 0
        var previousStep = sim.state
        for tick in 0..<4_800 {
            let before = sim.state
            let origin = sim.diagnostics.origin
            sim.step(input: .neutral)
            XCTAssertEqual(sim.state.status, .active)
            if tick % 120 == 0 { assertWorldIsBounded(sim) }
            let crossedSeam = floor(before.bike.position.x / 64) != floor(sim.state.bike.position.x / 64)
            let rebased = origin != sim.diagnostics.origin
            if crossedSeam { seams += 1 }
            if rebased { rebases += 1 }
            if crossedSeam || rebased {
                XCTAssertTrue(sim.state.bike.rear.contact && sim.state.bike.front.contact)
                assertSteadyCoastingStep(sim.state, after: before, following: previousStep)
            }
            previousStep = before
        }
        XCTAssertGreaterThanOrEqual(seams, 8)
        XCTAssertGreaterThanOrEqual(rebases, 1)
        XCTAssertLessThan(sim.diagnostics.origin.x, 0)
        XCTAssertLessThan(sim.state.bike.position.x, -512)
        XCTAssertLessThan(sim.state.bike.velocity.x, -10)
        XCTAssertEqual(sim.state.lives, 1)
    }

    func testDistantCrashRespawnsFiveAttachedBodiesAtItsCheckpoint() {
        let c = flatConfiguration, checkpoint = 50_000.0
        var initial = SimulationState(mode: .endless, seed: 3)
        initial.bike.position = .init(x: checkpoint, y: 2)
        initial.bike.velocity = .init(x: 5, y: -3)
        initial.bike.angle = .pi
        initial.distance = checkpoint - PhysicsConfiguration.courseStartX
        initial.score = Int(floor(initial.distance * 10))
        let sim = GameSimulation(state: initial, configuration: c)
        for _ in 0..<360 {
            sim.step(input: .neutral)
            assertWorldIsBounded(sim)
            if sim.state.status == .recovering { break }
        }
        XCTAssertEqual(sim.state.status, .recovering)
        XCTAssertFalse(sim.state.rider.isAttached)
        XCTAssertEqual(sim.state.lives, 2)
        let earned = sim.state
        var respawns = 0
        for _ in 0..<216 {
            respawns += sim.step(input: .neutral).filter { $0 == .respawned }.count
            XCTAssertEqual(sim.state.distance, earned.distance)
            XCTAssertEqual(sim.state.score, earned.score)
            XCTAssertEqual(sim.state.lives, 2)
            assertWorldIsBounded(sim)
        }
        XCTAssertEqual(respawns, 1)
        XCTAssertEqual(sim.state.status, .active)
        XCTAssertTrue(sim.state.rider.isAttached)
        XCTAssertEqual(sim.state.bike.position.x, checkpoint, accuracy: 0.001)
        XCTAssertLessThan(abs(sim.state.bike.position.x - sim.diagnostics.origin.x), 256)

        // A fresh nearby rig provides an independent reference for every respawn pose,
        // including wheel spin and both rider bodies, without restoring solver caches.
        var localState = SimulationState(mode: .endless, seed: 3)
        localState.bike.position = .init(x: 3, y: c.restingRideHeight)
        localState.bike.velocity.x = 3.5
        let reference = GameSimulation(state: localState, configuration: c)
        assertRig(sim.state, matches: reference.state, xOffset: checkpoint - 3)
        for _ in 0..<180 {
            sim.step(input: .neutral); reference.step(input: .neutral)
            assertRig(sim.state, matches: reference.state, xOffset: checkpoint - 3)
            assertWorldIsBounded(sim)
        }
        XCTAssertTrue(sim.state.bike.rear.contact && sim.state.bike.front.contact)
        XCTAssertEqual(sim.state.lives, 2)
    }

    private func poses(_ state: SimulationState) -> [RigidBodyState] {
        [
            .init(position: state.bike.position, velocity: state.bike.velocity,
                  angle: state.bike.angle, angularVelocity: state.bike.angularVelocity),
            .init(position: state.bike.rear.position, velocity: state.bike.rear.velocity,
                  angle: state.bike.rear.angle, angularVelocity: state.bike.rear.angularVelocity),
            .init(position: state.bike.front.position, velocity: state.bike.front.velocity,
                  angle: state.bike.front.angle, angularVelocity: state.bike.front.angularVelocity),
            state.rider.pelvis, state.rider.torso
        ]
    }

    private func assertRig(_ actual: SimulationState, matches expected: SimulationState, xOffset: Double = 0,
                           wheelPhase: [Double] = [0, 0],
                           file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.status, expected.status, file: file, line: line)
        XCTAssertEqual(actual.rider.isAttached, expected.rider.isAttached, file: file, line: line)
        XCTAssertEqual(actual.bike.rear.contact, expected.bike.rear.contact, file: file, line: line)
        XCTAssertEqual(actual.bike.front.contact, expected.bike.front.contact, file: file, line: line)
        for (index, pair) in zip(poses(actual), poses(expected)).enumerated() {
            let (a, b) = pair
            let context = "body \(index)"
            XCTAssertEqual(a.position.x - xOffset, b.position.x, accuracy: 0.004, context, file: file, line: line)
            XCTAssertEqual(a.position.y, b.position.y, accuracy: 0.004, context, file: file, line: line)
            XCTAssertEqual(a.velocity.x, b.velocity.x, accuracy: 0.03, context, file: file, line: line)
            XCTAssertEqual(a.velocity.y, b.velocity.y, accuracy: 0.03, context, file: file, line: line)
            let phase = index == 1 || index == 2 ? wheelPhase[index - 1] : 0
            XCTAssertEqual(wrapped(a.angle - b.angle - phase), 0, accuracy: 0.005, context, file: file, line: line)
            XCTAssertEqual(a.angularVelocity, b.angularVelocity, accuracy: 0.05, context, file: file, line: line)
        }
    }

    private func assertSteadyCoastingStep(_ actual: SimulationState, after previous: SimulationState,
                                         following earlier: SimulationState,
                                         file: StaticString = #filePath, line: UInt = #line) {
        for (index, pair) in zip(poses(actual), poses(previous)).enumerated() {
            let (a, b) = pair
            let old = poses(earlier)[index]
            let context = "body \(index) crossing seam/origin"
            // Compare consecutive integrated displacements. A contact solver's position
            // correction means its reported velocity is not a forward-Euler pose oracle.
            XCTAssertEqual(a.position.x - b.position.x, b.position.x - old.position.x,
                           accuracy: 0.002, context, file: file, line: line)
            XCTAssertEqual(a.position.y - b.position.y, b.position.y - old.position.y,
                           accuracy: 0.002, context, file: file, line: line)
            XCTAssertEqual(a.velocity.x, b.velocity.x, accuracy: 0.02, context, file: file, line: line)
            XCTAssertEqual(a.velocity.y, b.velocity.y, accuracy: 0.02, context, file: file, line: line)
            XCTAssertEqual(wrapped((a.angle - b.angle) - (b.angle - old.angle)),
                           0, accuracy: 0.002, context, file: file, line: line)
            XCTAssertEqual(a.angularVelocity, b.angularVelocity, accuracy: 0.04, context, file: file, line: line)
        }
    }

    private func assertWorldIsBounded(_ sim: GameSimulation, file: StaticString = #filePath, line: UInt = #line) {
        assertFinite(sim, file: file, line: line)
        XCTAssertEqual(sim.diagnostics.bodyCount - sim.diagnostics.terrainChunkCount, 5, file: file, line: line)
        XCTAssertLessThanOrEqual(sim.diagnostics.terrainChunkCount, 8, file: file, line: line)
        XCTAssertLessThanOrEqual(sim.diagnostics.bodyCount, 13, file: file, line: line)
    }
}
