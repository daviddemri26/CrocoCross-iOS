import Foundation
import XCTest
@testable import CrocoCrossCore

final class PhysicsTests: XCTestCase {
    func testPinnedBackendAndFixedStepContract() {
        XCTAssertEqual(GameSimulation.engineVersion, "box2d-1")
        XCTAssertEqual(GameSimulation.backendVersion, "3.1.1")
        XCTAssertEqual(GameSimulation.timeStep, 1.0 / 120)
        XCTAssertEqual(PhysicsConfiguration.substeps, 4)
        XCTAssertEqual(GameSimulation.weeklyDistance, 4_000)
    }

    func testCompleteRigHasFiveBodiesAndCorrectMassAndCenter() {
        let sim = flatFixture(height: flatConfiguration.restingRideHeight, descent: 0)
        XCTAssertEqual(sim.diagnostics.bodyCount - sim.diagnostics.terrainChunkCount, 5)
        XCTAssertEqual(sim.diagnostics.totalMass, 150, accuracy: 0.0001)
        XCTAssertEqual(sim.diagnostics.centerOfMass.x, sim.state.bike.position.x, accuracy: 0.001)
        XCTAssertEqual(sim.diagnostics.centerOfMass.y, sim.state.bike.position.y, accuracy: 0.001)
        XCTAssertTrue(sim.state.rider.isAttached)
    }

    func testParkedBikeSettlesAtMeasuredSagWithoutBalanceAssistance() {
        let sim = flatFixture(speed: 0, height: flatConfiguration.restingRideHeight, descent: 0)
        for _ in 0..<2_400 { sim.step(input: .neutral) }
        XCTAssertEqual(sim.state.status, .active)
        XCTAssertEqual(sim.state.bike.position.y, 0.814, accuracy: 0.004)
        XCTAssertEqual(sim.state.bike.rear.compression, 0.38 * 0.30, accuracy: 0.004)
        XCTAssertEqual(sim.state.bike.front.compression, 0.38 * 0.30, accuracy: 0.004)
        XCTAssertEqual(sim.state.bike.angle, 0, accuracy: 0.001)
        XCTAssertEqual(sim.state.bike.position.x, 3, accuracy: 0.002)
        XCTAssertTrue(sim.state.bike.rear.contact && sim.state.bike.front.contact)
    }

    func testReplayProducesIdenticalSnapshotsInIndependentWorlds() throws {
        let a = GameSimulation(mode: .endless, seed: 51)
        let b = GameSimulation(mode: .endless, seed: 51)
        var rider = PulsedTestRider()
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        for tick in 0..<7_200 {
            let input = rider.controls(a, speed: 12)
            XCTAssertEqual(a.step(input: input), b.step(input: input))
            if tick % 120 == 0 { XCTAssertEqual(try encoder.encode(a.state), try encoder.encode(b.state)) }
        }
        XCTAssertEqual(a.diagnostics.rebaseCount, b.diagnostics.rebaseCount)
    }

    func testWorldsAreIsolatedAndSnapshotsRemainValues() {
        let a = GameSimulation(mode: .endless, seed: 4, configuration: flatConfiguration)
        let b = GameSimulation(mode: .endless, seed: 4, configuration: flatConfiguration)
        let before = b.state
        for _ in 0..<240 { a.step(input: .init(throttle: 0.4)) }
        XCTAssertEqual(b.state.bike.position, before.bike.position)
        XCTAssertEqual(b.state.tick, 0)
        XCTAssertGreaterThan(a.state.distance, 1)
        for _ in 0..<240 { b.step(input: .neutral) }
        XCTAssertEqual(before.bike.position.x, 3)
        XCTAssertEqual(b.state.distance, 0, accuracy: 0.01)
    }

    func testSnapshotsRoundTripWithoutSerializingASolver() throws {
        let sim = GameSimulation(mode: .endless, seed: 7)
        for _ in 0..<240 { sim.step(input: .init(throttle: 0.3)) }
        let data = try JSONEncoder().encode(sim.state)
        let decoded = try JSONDecoder().decode(SimulationState.self, from: data)
        XCTAssertEqual(decoded.bike.position, sim.state.bike.position)
        XCTAssertEqual(decoded.rider, sim.state.rider)
        XCTAssertEqual(decoded.tick, sim.state.tick)
        XCTAssertLessThan(data.count, 4_096)
    }

    func testConfigurationRejectsNonfiniteAndImpossibleValues() {
        XCTAssertTrue(flatConfiguration.isValid)
        var c = flatConfiguration; c.mass = 0; XCTAssertFalse(c.isValid)
        c = flatConfiguration; c.gravity = .nan; XCTAssertFalse(c.isValid)
        c = flatConfiguration; c.suspensionTravel = 1; XCTAssertFalse(c.isValid)
        c = flatConfiguration; c.rearBrakeShare = 1.1; XCTAssertFalse(c.isValid)
        c = flatConfiguration; c.unloadedAxleOffset = 1e300; XCTAssertFalse(c.isValid)
        c = flatConfiguration; c.unloadedAxleOffset = 1e20; c.suspensionTravel = 1e19; XCTAssertFalse(c.isValid)
    }

    func testMalformedInputsStayFinite() {
        let sim = GameSimulation(mode: .endless, seed: 42, configuration: flatConfiguration)
        for _ in 0..<120 { sim.step(input: .init(throttle: .nan, brake: .infinity, lean: -.infinity)) }
        assertFinite(sim)
        XCTAssertEqual(sim.state.status, .active)
        XCTAssertEqual(sim.state.bike.throttle, 0)
    }

    func testAirborneCoastingConservesAssemblyMomentumUnderGravity() {
        for angle in [-0.6, 0.6] {
            let sim = flatFixture(height: 20, descent: 4, angle: angle)
            let momentum = sim.diagnostics.angularMomentum
            for _ in 0..<60 { sim.step(input: .neutral) }
            XCTAssertEqual(sim.diagnostics.centerOfMassVelocity.y, 4 - 9.81 * 0.5, accuracy: 0.001)
            XCTAssertEqual(sim.diagnostics.angularMomentum, momentum, accuracy: 0.12)
            XCTAssertEqual(sim.state.bike.angle, angle, accuracy: 0.025)
            XCTAssertFalse(sim.state.bike.grounded)
        }
    }

    func testRiderPostureIsRelativeToBikeAndDoesNotTargetWorldUpright() {
        let sim = flatFixture(height: 30, descent: 0, angle: 0.6)
        for _ in 0..<60 { sim.step(input: .neutral) }
        let pelvisLocal = rotated(sim.state.rider.pelvis.position - sim.state.bike.position, by: -sim.state.bike.angle)
        XCTAssertEqual(pelvisLocal.x, 0, accuracy: 0.025)
        XCTAssertEqual(pelvisLocal.y, 0.1, accuracy: 0.025)
        XCTAssertGreaterThan(sim.state.bike.angle, 0.5)
    }

    func testHeadImpactDetachesOnceAndPresentationIsBounded() {
        let sim = flatFixture(speed: 5, height: 2, descent: -3, angle: .pi)
        var crashes = 0
        for _ in 0..<360 {
            crashes += sim.step(input: .neutral).filter { $0 == .crashed }.count
            if sim.state.status == .crashed { break }
        }
        XCTAssertEqual(crashes, 1); XCTAssertEqual(sim.state.lives, 0)
        XCTAssertFalse(sim.state.rider.isAttached)
        let crash = sim.state
        for _ in 0..<216 { sim.stepPresentation() }
        XCTAssertNotEqual(sim.state.rider.torso.position, crash.rider.torso.position)
        XCTAssertEqual(sim.state.tick, crash.tick); XCTAssertEqual(sim.state.distance, crash.distance)
        XCTAssertEqual(sim.state.score, crash.score); XCTAssertEqual(sim.state.lives, crash.lives)
        let end = sim.state
        for _ in 0..<240 { sim.stepPresentation(); XCTAssertTrue(sim.step(input: .init(throttle: 1)).isEmpty) }
        XCTAssertEqual(sim.state.rider, end.rider); XCTAssertEqual(sim.state.bike.position, end.bike.position)
    }

    func testRecoveringContinuesMotionWithoutAddingScoreThenRespawnsAttached() {
        var initial = SimulationState(mode: .endless, seed: 3)
        initial.bike.position = .init(x: 3, y: 2); initial.bike.angle = .pi
        initial.bike.velocity = .init(x: 5, y: -3)
        let sim = GameSimulation(state: initial, configuration: flatConfiguration)
        for _ in 0..<360 {
            sim.step(input: .neutral)
            if sim.state.status == .recovering { break }
        }
        XCTAssertEqual(sim.state.status, .recovering)
        let crash = sim.state
        for _ in 0..<60 { sim.step(input: .init(throttle: 1, lean: 1)) }
        XCTAssertFalse(sim.state.rider.isAttached)
        XCTAssertNotEqual(sim.state.rider.torso.position, crash.rider.torso.position)
        XCTAssertEqual(sim.state.score, crash.score); XCTAssertEqual(sim.state.distance, crash.distance)
        XCTAssertEqual(sim.state.lives, 2)
        var respawns = 0
        for _ in 0..<156 { respawns += sim.step(input: .neutral).filter { $0 == .respawned }.count }
        XCTAssertEqual(respawns, 1); XCTAssertEqual(sim.state.status, .active)
        XCTAssertTrue(sim.state.rider.isAttached); XCTAssertEqual(sim.state.lives, 2)
    }

    func testAllThreeLivesAreSpentOnceAndEarnedProgressPersists() {
        let sim = GameSimulation(mode: .endless, seed: 41)
        var deaths = 0, respawns = 0, score = 0, distance = 0.0
        for _ in 0..<14_400 {
            for event in sim.step(input: .init(throttle: 1, lean: 1)) {
                if event == .crashed { deaths += 1 }; if event == .respawned { respawns += 1 }
            }
            XCTAssertGreaterThanOrEqual(sim.state.score, score); XCTAssertGreaterThanOrEqual(sim.state.distance, distance)
            score = sim.state.score; distance = sim.state.distance
            if sim.state.status == .crashed { break }
        }
        XCTAssertEqual(deaths, 3); XCTAssertEqual(respawns, 2); XCTAssertEqual(sim.state.lives, 0)
        XCTAssertEqual(sim.state.status, .crashed)
    }

    func testDistanceMarkersAndFinishSharePublishedOriginAndAwardOnce() {
        let start = PhysicsConfiguration.courseStartX
        let initial = GameSimulation(mode: .weekly, seed: 2, configuration: flatConfiguration)
        XCTAssertEqual(initial.state.bike.position.x, start); XCTAssertEqual(initial.state.distance, 0)
        var state = initial.state
        state.bike.position.x = start + 100
        let marker = GameSimulation(state: state, configuration: flatConfiguration)
        marker.step(input: .neutral)
        XCTAssertEqual(marker.state.distance, 100, accuracy: 0.0001)
        state.bike.position.x = start + 4_000 - 0.04; state.bike.velocity.x = 12; state.distance = 3_999.96
        let finish = GameSimulation(state: state, configuration: flatConfiguration)
        XCTAssertEqual(finish.step(input: .neutral).filter { $0 == .finished }.count, 1)
        XCTAssertEqual(finish.state.status, .finished); XCTAssertEqual(finish.state.distance, 4_000)
        XCTAssertEqual(finish.state.score, 41_000); XCTAssertTrue(finish.step(input: .neutral).isEmpty)
    }

    func testWeeklyCourseRemainsCompletableWithNoTimeLimit() {
        for seed: UInt32 in [3, 8, 11] {
            let sim = GameSimulation(mode: .weekly, seed: seed)
            var rider = PulsedTestRider()
            for _ in 0..<84_000 {
                sim.step(input: rider.controls(sim, speed: 12))
                if sim.state.status != .active { break }
            }
            XCTAssertEqual(sim.state.status, .finished)
            XCTAssertEqual(sim.state.distance, 4_000); XCTAssertEqual(sim.state.lives, 1)
            XCTAssertGreaterThan(sim.state.elapsed, 150); XCTAssertGreaterThanOrEqual(sim.state.score, 41_000)
            XCTAssertGreaterThan(sim.diagnostics.rebaseCount, 5)
        }
    }

    func testLongEndlessRideKeepsBoundedWorldAndSnapshotSize() throws {
        let sim = GameSimulation(mode: .endless, seed: 42, configuration: flatConfiguration)
        var warmBytes = 0, peakBytes = 0
        for tick in 0..<120 * 3_600 {
            sim.step(input: .init(throttle: 0.38))
            if tick % 1_200 == 0 {
                let bytes = sim.diagnostics.allocatedByteCount
                if tick >= 7_200 && warmBytes == 0 { warmBytes = bytes }
                if warmBytes > 0 {
                    peakBytes = max(peakBytes, bytes)
                    XCTAssertGreaterThan(bytes, 0)
                    XCTAssertLessThanOrEqual(bytes, warmBytes + 128 * 1_024,
                                             "One isolated world must reuse allocations after the first simulated minute.")
                }
                XCTAssertLessThanOrEqual(sim.diagnostics.bodyCount, 13)
                XCTAssertLessThanOrEqual(sim.diagnostics.terrainChunkCount, 8)
                XCTAssertLessThan(try JSONEncoder().encode(sim.state).count, 4_096)
                assertFinite(sim)
            }
        }
        XCTAssertEqual(sim.state.status, .active); XCTAssertEqual(sim.state.lives, 3)
        XCTAssertGreaterThan(sim.state.distance, 60_000); XCTAssertGreaterThan(sim.diagnostics.rebaseCount, 15)
        print("Box2D endurance: distance=\(sim.state.distance)m, rebases=\(sim.diagnostics.rebaseCount), warmBytes=\(warmBytes), peakBytes=\(peakBytes), finalBytes=\(sim.diagnostics.allocatedByteCount)")
    }
    func testConfiguredInertiaIsMeasuredAboutCompleteAssemblyCenter() {
        let sim = flatFixture(speed: 12, height: 20, descent: 4, spin: 2)
        XCTAssertEqual(sim.diagnostics.pitchInertia, flatConfiguration.inertia, accuracy: 0.002)
        XCTAssertEqual(sim.diagnostics.centerOfMassVelocity.x, 12, accuracy: 0.00001)
        XCTAssertEqual(sim.diagnostics.centerOfMassVelocity.y, 4, accuracy: 0.00001)
    }

    func testDetachingInFlightAddsNoLinearOrAngularImpulse() {
        var b = BikeState(); b.position = .init(x: 3, y: 20)
        b.velocity = .init(x: 12, y: 4); b.angle = 0.4; b.angularVelocity = 2
        let world = Box2DBikeWorld(configuration: flatConfiguration, terrain: .init(seed: 3, style: .flat), bike: b)
        for _ in 0..<12 { world.advance(input: .neutral) }
        let before = world.diagnostics
        world.detach(); world.advance(input: .init(throttle: 1, brake: 1, lean: 1))
        XCTAssertFalse(world.rider.isAttached)
        XCTAssertEqual(world.diagnostics.centerOfMassVelocity.x, before.centerOfMassVelocity.x, accuracy: 0.001)
        XCTAssertEqual(world.diagnostics.centerOfMassVelocity.y, before.centerOfMassVelocity.y - 9.81 / 120, accuracy: 0.001)
        XCTAssertEqual(world.diagnostics.angularMomentum, before.angularMomentum, accuracy: 0.05)
        XCTAssertEqual(world.diagnostics.attachmentForce, 0)
    }

}
