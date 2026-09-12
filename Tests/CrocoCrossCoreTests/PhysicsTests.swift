import Foundation
import XCTest
@testable import CrocoCrossCore

final class PhysicsTests: XCTestCase {
    func testWeeklyCourseIsCompletableOnRealSeededHillsWithBoundedRiderInputs() {
        // This test-only rider anticipates the landing slope and meters the pedals.
        // It never modifies simulation state or supplies an automatic balance force.
        for targetSpeed in [12.0, 16] {
            for seed: UInt32 in [3, 8, 11] {
                var sim = GameSimulation(mode: .weekly, seed: seed)
                for _ in 0 ..< 120 * 700 {
                    let b = sim.state.bike
                    let slope = (sim.terrainHeight(at: b.position.x + 0.1) - sim.terrainHeight(at: b.position.x - 0.1)) / 0.2
                    var target = atan(slope)
                    if !b.grounded {
                        var landingX = b.position.x
                        for _ in 0 ..< 3 {
                            let height = max(0, b.position.y - sim.terrainHeight(at: landingX) - 0.83)
                            let time = max(0.05, min(2.0, (b.velocity.y + sqrt(b.velocity.y * b.velocity.y + 2 * 9.81 * height)) / 9.81))
                            landingX = b.position.x + b.velocity.x * time
                        }
                        target = atan((sim.terrainHeight(at: landingX + 0.1) - sim.terrainHeight(at: landingX - 0.1)) / 0.2)
                    }
                    let error = atan2(sin(target - b.angle), cos(target - b.angle))
                    let lean = b.grounded ? 0 : min(1, max(-1, error * 6 - b.angularVelocity * 2.2))
                    let acceleration = (targetSpeed - b.velocity.x) * 1.5 + 9.81 * slope
                    var throttle = min(0.95, max(0, acceleration * sim.configuration.mass / sim.configuration.maximumDriveForce))
                    if b.angle - atan(slope) > 0.15 { throttle = min(0.15, throttle) }
                    let brake = acceleration < -1 ? min(0.6, -acceleration * sim.configuration.mass / sim.configuration.brakeForce) : 0
                    sim.step(input: .init(throttle: throttle, brake: brake, lean: lean))
                    if sim.state.status != .active { break }
                }
                XCTAssertEqual(sim.state.status, .finished, "seed=\(seed), target=\(targetSpeed)m/s")
                XCTAssertEqual(sim.state.distance, 4_000)
                XCTAssertEqual(sim.state.lives, 1)
                XCTAssertGreaterThan(sim.state.elapsed, 150)
                XCTAssertGreaterThanOrEqual(sim.state.score, 41_000)
            }
        }
    }
    func testThrottleReleaseRecoversAWheelie() {
        var sim = GameSimulation(mode: .weekly, seed: 3, configuration: flat)
        var released = false, maximumAngle = 0.0
        for _ in 0 ..< 120 * 5 {
            if sim.state.bike.angle > 0.3 { released = true }
            sim.step(input: .init(throttle: released ? 0 : 1))
            maximumAngle = max(maximumAngle, sim.state.bike.angle)
        }
        XCTAssertTrue(released)
        XCTAssertGreaterThan(maximumAngle, 0.3)
        XCTAssertEqual(sim.state.status, .active)
        XCTAssertLessThan(abs(sim.state.bike.angle), 0.08)
        XCTAssertTrue(sim.state.bike.rear.contact && sim.state.bike.front.contact)
    }

    func testSeededRideCorpusHasNaturalJumpsAndRecoverableRoutes() {
        var survivingRides = 0, totalJumps = 0
        for seed: UInt32 in 1 ... 12 {
            var sim = GameSimulation(mode: .endless, seed: seed)
            var jumps = 0, priorGrounded = true
            for _ in 0 ..< 120 * 60 {
                let bike = sim.state.bike
                let slope = atan((sim.terrainHeight(at: bike.position.x + 4) - sim.terrainHeight(at: bike.position.x)) / 4)
                let error = atan2(sin(slope - bike.angle), cos(slope - bike.angle))
                let lean = bike.grounded ? 0 : min(1, max(-1, error * 3 - bike.angularVelocity * 1.4))
                let throttle = bike.angle > 0.25 ? 0.2 : 0.6
                sim.step(input: .init(throttle: throttle, lean: lean))
                if priorGrounded && !sim.state.bike.grounded { jumps += 1 }
                priorGrounded = sim.state.bike.grounded
                XCTAssertTrue(sim.state.bike.position.x.isFinite && sim.state.bike.velocity.y.isFinite)
                if sim.state.status == .crashed { break }
            }
            XCTAssertGreaterThan(sim.state.distance, 150, "A cautious rider can clear the introduction on seed \(seed).")
            XCTAssertGreaterThan(jumps, 1)
            survivingRides += sim.state.status == .active ? 1 : 0
            totalJumps += jumps
        }
        XCTAssertGreaterThanOrEqual(survivingRides, 8, "A simple test rider can recover ordinary landings; failures remain possible.")
        XCTAssertGreaterThan(totalJumps, 100)
    }
    private var flat: PhysicsConfiguration {
        var c = PhysicsConfiguration(); c.terrainStyle = .flat; return c
    }

    func testParkedBikeSettlesWithoutBalanceAssistance() {
        var sim = GameSimulation(mode: .endless, seed: 42, configuration: flat)
        let y = sim.state.bike.position.y
        for _ in 0 ..< 120 * 20 { sim.step(input: .neutral) }
        XCTAssertEqual(sim.state.status, .active)
        XCTAssertEqual(sim.state.bike.position.y, y, accuracy: 0.003)
        XCTAssertEqual(sim.state.bike.angle, 0, accuracy: 0.0001)
        XCTAssertEqual(sim.state.bike.position.x, 3, accuracy: 0.0001)
        XCTAssertTrue(sim.state.bike.rear.contact && sim.state.bike.front.contact)
    }

    func testUniversalPedalsDoNotAddArtificialGroundLean() {
        var throttleOnly = GameSimulation(mode: .endless, seed: 42, configuration: flat)
        var universal = throttleOnly
        for _ in 0 ..< 120 * 3 {
            throttleOnly.step(input: .init(throttle: 0.38))
            universal.step(input: .init(throttle: 0.38, lean: 0.38))
        }
        XCTAssertEqual(throttleOnly.state.bike.position, universal.state.bike.position)
        XCTAssertEqual(throttleOnly.state.bike.angle, universal.state.bike.angle)
    }

    func testBrakingAndMalformedInputRemainStable() {
        var sim = GameSimulation(mode: .endless, seed: 42, configuration: flat)
        for _ in 0 ..< 120 * 3 { sim.step(input: .init(throttle: 0.38)) }
        let movingSpeed = sim.state.bike.velocity.x
        for _ in 0 ..< 120 * 3 { sim.step(input: .init(brake: 1, lean: -1)) }
        XCTAssertLessThan(abs(sim.state.bike.velocity.x), 0.1)
        XCTAssertGreaterThan(movingSpeed, 8)
        XCTAssertEqual(sim.state.status, .active)
        for _ in 0 ..< 120 { sim.step(input: .init(throttle: .nan, brake: .infinity, lean: -.infinity)) }
        XCTAssertTrue(sim.isValidSavedState)
        XCTAssertEqual(sim.state.status, .active)
    }

    func testRearDriveTransfersWeightAndHardThrottleRaisesFront() {
        var hard = GameSimulation(mode: .weekly, seed: 42, configuration: flat)
        var metered = hard
        var lifted = false, hardAngle = 0.0, meteredAngle = 0.0
        for _ in 0 ..< 120 * 3 {
            hard.step(input: .init(throttle: 1))
            metered.step(input: .init(throttle: 0.38))
            hardAngle = max(hardAngle, hard.state.bike.angle)
            meteredAngle = max(meteredAngle, metered.state.bike.angle)
            lifted = lifted || (hard.state.bike.rear.contact && !hard.state.bike.front.contact && hard.state.bike.angle > 0.15)
        }
        XCTAssertTrue(lifted, "Rear traction must raise the front without a lean input or scripted wheelie.")
        XCTAssertGreaterThan(hardAngle, meteredAngle + 0.1)
        XCTAssertLessThan(meteredAngle, 0.15)
        XCTAssertEqual(metered.state.status, .active)
        XCTAssertGreaterThan(metered.state.bike.velocity.x, 8)
    }

    func testAirborneCoastingHasGravityAndNoAutomaticUprightTorque() {
        var state = SimulationState(mode: .weekly, seed: 3)
        state.bike.position = .init(x: 3, y: 15)
        state.bike.velocity = .init(x: 8, y: 4)
        state.bike.angle = 0.48
        var sim = GameSimulation(state: state, configuration: flat)
        for _ in 0 ..< 60 { sim.step(input: .neutral) }
        XCTAssertEqual(sim.state.bike.velocity.y, 4 - flat.gravity * 0.5, accuracy: 0.00001)
        XCTAssertEqual(sim.state.bike.angle, 0.48, accuracy: 0.00001)
        XCTAssertFalse(sim.state.bike.grounded)
        XCTAssertEqual(sim.state.flips, 0)
    }

    func testAngledLandingsAreAbsorbedBySuspension() {
        for angle in [-0.35, 0.35] {
            var state = SimulationState(mode: .weekly, seed: 3)
            state.bike.position = .init(x: 3, y: 2.0)
            state.bike.velocity = .init(x: 7, y: -2)
            state.bike.angle = angle
            var sim = GameSimulation(state: state, configuration: flat)
            for _ in 0 ..< 120 * 4 { sim.step(input: .neutral) }
            XCTAssertEqual(sim.state.status, .active)
            XCTAssertLessThan(abs(sim.state.bike.angle), 0.15)
            XCTAssertTrue(sim.state.bike.grounded)
        }
    }

    func testHeadFirstImpactCrashesAndTerminalStateFreezes() {
        var state = SimulationState(mode: .weekly, seed: 2)
        state.bike.position = .init(x: 3, y: 2)
        state.bike.angle = .pi
        state.bike.velocity.y = -3
        var sim = GameSimulation(state: state, configuration: flat)
        for _ in 0 ..< 120 * 3 { sim.step(input: .neutral) }
        XCTAssertEqual(sim.state.status, .crashed)
        XCTAssertEqual(sim.state.lives, 0)
        let frozen = sim.state
        for _ in 0 ..< 120 { XCTAssertTrue(sim.step(input: .init(throttle: 1)).isEmpty) }
        XCTAssertEqual(sim.state.tick, frozen.tick)
        XCTAssertEqual(sim.state.bike.position, frozen.bike.position)
    }

    func testTerrainSectionsJoinAndSeedsRepeat() {
        let a = TerrainGenerator(seed: 913), b = TerrainGenerator(seed: 913), other = TerrainGenerator(seed: 914)
        var differs = false
        for index in 0 ..< 150 {
            let boundary = TerrainGenerator.entryLength + Double(index) * TerrainGenerator.sectionLength
            XCTAssertEqual(a.height(at: boundary - 0.0001), a.height(at: boundary + 0.0001), accuracy: 0.0001)
            XCTAssertEqual(a.slope(at: boundary - 0.001), a.slope(at: boundary + 0.001), accuracy: 0.001)
            for offset in stride(from: 0.0, to: 64, by: 3) {
                let x = boundary + offset
                XCTAssertEqual(a.height(at: x), b.height(at: x))
                XCTAssertTrue(a.height(at: x).isFinite)
                XCTAssertLessThan(abs(a.slope(at: x)), 1.5)
                differs = differs || a.height(at: x) != other.height(at: x)
            }
        }
        XCTAssertTrue(differs)
    }

    func testWeeklyHasFourKilometersAndNoOldTimeLimit() {
        var sim = GameSimulation(mode: .weekly, seed: 42, configuration: flat)
        var finishedEvents = 0
        for _ in 0 ..< 120 * 600 {
            let events = sim.step(input: .init(throttle: 0.38))
            finishedEvents += events.filter { if case .finished = $0 { true } else { false } }.count
            if sim.state.status != .active { break }
        }
        XCTAssertEqual(sim.state.status, .finished)
        XCTAssertEqual(sim.state.distance, 4_000)
        XCTAssertGreaterThan(sim.state.elapsed, 150)
        XCTAssertEqual(sim.state.lives, 1)
        XCTAssertEqual(sim.state.score, 41_000)
        XCTAssertEqual(finishedEvents, 1)
    }

    func testDistanceMarkersAndFinishShareThePublishedCourseOrigin() {
        let start = PhysicsConfiguration.courseStartX
        let initial = GameSimulation(mode: .weekly, seed: 2, configuration: flat)
        XCTAssertEqual(initial.state.bike.position.x, start)
        XCTAssertEqual(initial.state.distance, 0)

        var markerState = initial.state
        markerState.bike.position.x = start + 100
        var marker = GameSimulation(state: markerState, configuration: flat)
        marker.step(input: .neutral)
        XCTAssertEqual(marker.state.distance, 100, accuracy: 0.00001)
        XCTAssertEqual(marker.state.score, 1_000)

        let finishX = start + PhysicsConfiguration.weeklyDistance
        var approachState = initial.state
        approachState.bike.position.x = finishX - 0.04
        approachState.bike.velocity.x = 12
        approachState.distance = PhysicsConfiguration.weeklyDistance - 0.04
        var approach = GameSimulation(state: approachState, configuration: flat)
        XCTAssertLessThan(approach.state.bike.position.x, finishX)
        let events = approach.step(input: .neutral)
        XCTAssertGreaterThanOrEqual(approach.state.bike.position.x, finishX)
        XCTAssertEqual(approach.state.distance, PhysicsConfiguration.weeklyDistance)
        XCTAssertEqual(approach.state.status, .finished)
        XCTAssertEqual(events.filter { if case .finished = $0 { true } else { false } }.count, 1)
    }

    func testSaveRestorePreservesExactFutureAndFixedStructure() throws {
        var sim = GameSimulation(mode: .endless, seed: 51)
        for _ in 0 ..< 120 * 6 { sim.step(input: .init(throttle: 0.38)) }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        var restored = try JSONDecoder().decode(GameSimulation.self, from: encoder.encode(sim))
        for tick in 0 ..< 120 * 20 {
            let input = ControlInput(throttle: tick % 80 < 60 ? 0.4 : 0.2, lean: tick % 80 < 30 ? -0.2 : 0)
            sim.step(input: input); restored.step(input: input)
        }
        XCTAssertEqual(try encoder.encode(sim), try encoder.encode(restored))
        XCTAssertLessThan(try encoder.encode(sim).count, 4_096)
    }

    func testAllThreeLivesAreSpentOnceAndRespawnKeepsEarnedDistance() {
        var sim = GameSimulation(mode: .endless, seed: 41)
        var deaths = 0, respawns = 0, bestScore = 0, bestDistance = 0.0
        for _ in 0 ..< 120 * 120 {
            for event in sim.step(input: .init(throttle: 1, lean: 1)) {
                if case .crashed = event { deaths += 1 }
                if case .respawned = event { respawns += 1 }
            }
            XCTAssertGreaterThanOrEqual(sim.state.score, bestScore)
            XCTAssertGreaterThanOrEqual(sim.state.distance, bestDistance)
            bestScore = sim.state.score; bestDistance = sim.state.distance
            if sim.state.status == .crashed { break }
        }
        XCTAssertEqual(deaths, 3)
        XCTAssertEqual(respawns, 2)
        XCTAssertEqual(sim.state.lives, 0)
        XCTAssertEqual(sim.state.status, .crashed)
        XCTAssertGreaterThanOrEqual(sim.state.score, Int(floor(sim.state.distance * 10)))
    }

    func testOneHourEndlessRideKeepsFixedSaveStructure() throws {
        var sim = GameSimulation(mode: .endless, seed: 42, configuration: flat)
        let initial = try JSONSerialization.jsonObject(with: JSONEncoder().encode(sim)) as! [String: Any]
        var samples = 0
        for tick in 0 ..< 120 * 60 * 60 {
            sim.step(input: .init(throttle: 0.38))
            if tick % (120 * 60) == 0 {
                let data = try JSONEncoder().encode(sim)
                let snapshot = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                XCTAssertEqual(Set(initial.keys), Set(snapshot.keys))
                XCTAssertLessThan(data.count, 4_096)
                samples += 1
            }
        }
        XCTAssertEqual(samples, 60)
        XCTAssertEqual(sim.state.status, .active)
        XCTAssertGreaterThan(sim.state.distance, 60_000)
        XCTAssertEqual(sim.state.lives, 3)
    }

    func testCorruptOrIncompatibleSaveIsRejected() throws {
        let sim = GameSimulation(mode: .weekly, seed: 1)
        let encoded = try JSONEncoder().encode(sim)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object["saveVersion"] = "future-engine"
        XCTAssertThrowsError(try JSONDecoder().decode(GameSimulation.self, from: JSONSerialization.data(withJSONObject: object)))
        object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var config = try XCTUnwrap(object["configuration"] as? [String: Any]); config["mass"] = 0; object["configuration"] = config
        XCTAssertThrowsError(try JSONDecoder().decode(GameSimulation.self, from: JSONSerialization.data(withJSONObject: object)))
        object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var state = try XCTUnwrap(object["state"] as? [String: Any]); state["status"] = "recovering"; object["state"] = state
        XCTAssertThrowsError(try JSONDecoder().decode(GameSimulation.self, from: JSONSerialization.data(withJSONObject: object)))
    }
}
