import Foundation
import XCTest
@testable import CrocoCrossCore

final class JungleTerrainTests: XCTestCase {
    private var configuration: PhysicsConfiguration {
        var value = PhysicsConfiguration(); value.terrainStyle = .junglePlatforms; return value
    }
    private let seeds: [UInt32] = [0, 1, 3, 42, 913, .max]

    func testLargeGapsIncludeRaisedReceptionsAndContinuousDeterministicGuides() throws {
        var widths = Set<Double>(), raised = 0, gaps = 0, steepClimbs = 0, steepDescents = 0
        var launchSlopes = Set<Int>(), receivingSlopes = Set<Int>(), platformLengths = Set<Int>()
        for seed in seeds {
            let terrain = TerrainGenerator(seed: seed, style: .junglePlatforms)
            let restored = try JSONDecoder().decode(TerrainGenerator.self, from: JSONEncoder().encode(terrain))
            let spans = terrain.solidSpans(from: -10, to: 2_024)
            XCTAssertEqual(spans.first?.lowerBound, -10)
            XCTAssertEqual(spans.last?.upperBound, 2_024)
            XCTAssertGreaterThan(spans.count, 14)
            XCTAssertEqual(restored.solidSpans(from: -10, to: 2_024), spans)
            for index in 0..<spans.count - 1 {
                let left = spans[index], right = spans[index + 1]
                let width = right.lowerBound - left.upperBound
                widths.insert(width); gaps += 1
                XCTAssertTrue((14...40).contains(width))
                XCTAssertTrue(terrain.isSolid(at: left.upperBound))
                XCTAssertTrue(terrain.isSolid(at: right.lowerBound))
                XCTAssertFalse(terrain.isSolid(at: (left.upperBound + right.lowerBound) / 2))
                XCTAssertTrue(terrain.solidSpans(from: left.upperBound + 0.01, to: right.lowerBound - 0.01).isEmpty)
                let rise = terrain.height(at: right.lowerBound) - terrain.height(at: left.upperBound)
                XCTAssertGreaterThanOrEqual(rise, -10.500001)
                XCTAssertLessThanOrEqual(rise, 4.000001)
                if rise > 0.9 { raised += 1 }
                if [16.0, 24].contains(width) {
                    XCTAssertEqual(terrain.slope(at: left.upperBound), 0, accuracy: 0.000001)
                    XCTAssertLessThan(rise, -4)
                    for offset in stride(from: 0.0, through: 12, by: 1) {
                        XCTAssertEqual(terrain.height(at: left.upperBound - offset), terrain.height(at: left.upperBound), accuracy: 0.000001)
                    }
                } else {
                    XCTAssertGreaterThan(terrain.slope(at: left.upperBound), 0.3)
                }
                launchSlopes.insert(Int((terrain.slope(at: left.upperBound) * 1_000).rounded()))
                receivingSlopes.insert(Int((terrain.slope(at: right.lowerBound) * 1_000).rounded()))
                if index > 0 {
                    XCTAssertGreaterThan(left.upperBound - left.lowerBound, 70)
                    platformLengths.insert(Int(left.upperBound - left.lowerBound))
                }
            }
            for x in stride(from: 0.0, through: 2_024, by: 0.125) {
                XCTAssertEqual(terrain.height(at: x), restored.height(at: x))
                let derivative = (terrain.height(at: x + 0.0001) - terrain.height(at: x - 0.0001)) / 0.0002
                XCTAssertEqual(terrain.slope(at: x), derivative, accuracy: 0.000002)
                if terrain.isSolid(at: x) {
                    XCTAssertLessThan(abs(terrain.slope(at: x)), 1.5)
                    steepClimbs += terrain.slope(at: x) > 0.5 ? 1 : 0
                    steepDescents += terrain.slope(at: x) < -0.5 ? 1 : 0
                }
            }
        }
        XCTAssertEqual(widths, [14, 16, 18, 22, 24, 26, 30, 34, 38, 40])
        XCTAssertGreaterThanOrEqual(launchSlopes.count, 5)
        XCTAssertGreaterThanOrEqual(receivingSlopes.count, 5)
        XCTAssertGreaterThan(platformLengths.max()! - platformLengths.min()!, 50)
        XCTAssertGreaterThan(Double(raised) / Double(gaps), 0.30)
        XCTAssertGreaterThan(steepClimbs, 1_000)
        XCTAssertGreaterThan(steepDescents, 1_000)
        let terrain = TerrainGenerator(seed: 42, style: .junglePlatforms)
        XCTAssertTrue(terrain.solidSpans(from: .nan, to: 100).isEmpty)
        XCTAssertTrue(terrain.solidSpans(from: 0, to: .infinity).isEmpty)
        XCTAssertTrue(terrain.solidSpans(from: 10, to: 0).isEmpty)
        XCTAssertFalse(terrain.isSolid(at: .nan))
    }

    func testExceptionalCrossingsStayOccasionalAndLeaveRecoveryRoom() {
        var exceptionalWidths = Set<Double>()
        for seed in seeds {
            let terrain = TerrainGenerator(seed: seed, style: .junglePlatforms)
            let spans = terrain.solidSpans(from: 0, to: 8_000)
            for index in 0..<spans.count - 1 {
                let width = spans[index + 1].lowerBound - spans[index].upperBound
                if width > 34 {
                    exceptionalWidths.insert(width)
                    XCTAssertEqual(index % 6, 5, "Only one exceptional jump in six sections")
                    XCTAssertGreaterThanOrEqual(index, 5, "Keep the opening sequence accessible")
                    XCTAssertGreaterThan(spans[index].upperBound - spans[index].lowerBound, 60)
                    XCTAssertGreaterThan(spans[index + 1].upperBound - spans[index + 1].lowerBound, 60)
                    XCTAssertGreaterThanOrEqual(terrain.height(at: spans[index + 1].lowerBound)
                        - terrain.height(at: spans[index].upperBound), -1.000001)
                } else {
                    XCTAssertNotEqual(index % 6, 5)
                }
            }
        }
        XCTAssertEqual(exceptionalWidths, [38, 40])
    }

    func testContinuousCoursesRetainTheirWholeCollisionSurface() {
        for style: PhysicsConfiguration.TerrainStyle in [.hills, .japanMountains, .flat] {
            let terrain = TerrainGenerator(seed: 42, style: style)
            XCTAssertEqual(terrain.solidSpans(from: -128, to: 2_624), [.init(lowerBound: -128, upperBound: 2_624)])
            for x in stride(from: -128.0, through: 2_624, by: 0.5) { XCTAssertTrue(terrain.isSolid(at: x)) }
        }
    }

    private func fixture(seed: UInt32 = 42, x: Double, speed: Double = 0, height: Double? = nil) -> GameSimulation {
        let terrain = TerrainGenerator(seed: seed, style: .junglePlatforms)
        let angle = atan(terrain.slope(at: x))
        var state = SimulationState(mode: .endless, seed: seed)
        state.bike.position = .init(x: x, y: height ?? terrain.height(at: x) + configuration.restingRideHeight / cos(angle))
        state.bike.angle = angle
        state.bike.velocity = .init(x: cos(angle) * speed, y: sin(angle) * speed)
        return GameSimulation(state: state, configuration: configuration)
    }

    func testFallingThroughRealVoidCostsOneLifeAndRespawnsWithSixtyMetreApproach() {
        let sim = fixture(x: 89)
        XCTAssertFalse(sim.terrainIsSolid(at: sim.state.bike.position.x))
        var crashEvents = 0
        for _ in 0..<360 {
            crashEvents += sim.step(input: .neutral).filter { $0 == .crashed }.count
            XCTAssertFalse(sim.state.bike.grounded, "The guide across a hole must not support the wheels.")
            assertFinite(sim)
            if sim.state.status == .recovering { break }
        }
        XCTAssertEqual(crashEvents, 1)
        XCTAssertEqual(sim.state.lives, 2)
        XCTAssertEqual(sim.state.status, .recovering)
        XCTAssertFalse(sim.state.rider.isAttached)
        let earned = sim.state
        var respawns = 0
        for _ in 0..<216 {
            let events = sim.step(input: .neutral)
            respawns += events.filter { $0 == .respawned }.count
            XCTAssertFalse(events.contains(.crashed))
            XCTAssertEqual(sim.state.lives, 2)
            XCTAssertEqual(sim.state.score, earned.score)
        }
        XCTAssertEqual(respawns, 1)
        XCTAssertEqual(sim.state.status, .active)
        XCTAssertTrue(sim.state.rider.isAttached)
        let x = sim.state.bike.position.x
        XCTAssertLessThanOrEqual(x, 20.01)
        XCTAssertEqual(sim.terrainSolidSpans(from: x - 1, to: x + 59), [.init(lowerBound: x - 1, upperBound: x + 59)])
        XCTAssertEqual(hypot(sim.state.bike.velocity.x, sim.state.bike.velocity.y), 3.5, accuracy: 0.01)
        var rider = SimpleJungleRider()
        for _ in 0..<1_600 { sim.step(input: rider.controls(sim, speed: 24)) }
        XCTAssertGreaterThan(sim.state.bike.position.x, 103)
        XCTAssertEqual(sim.state.lives, 2)
    }

    func testVoidTerminalCrashCannotRepeatOrAwardAnUnlandedFlip() {
        var state = SimulationState(mode: .weekly, seed: 42)
        state.bike.position = .init(x: 89, y: -15)
        state.bike.angularVelocity = -6
        let sim = GameSimulation(state: state, configuration: configuration)
        var crashes = 0
        for _ in 0..<600 { crashes += sim.step(input: .neutral).filter { $0 == .crashed }.count }
        XCTAssertEqual(crashes, 1)
        XCTAssertEqual(sim.state.status, .crashed)
        XCTAssertEqual(sim.state.lives, 0)
        XCTAssertEqual(sim.state.flips, 0)
    }

    func testPreparedBinaryControlsTraverseSeveralRaisedAndWideJumps() {
        for seed: UInt32 in [1, 42, 913] {
            let sim = GameSimulation(mode: .weekly, seed: seed, configuration: configuration)
            var rider = SimpleJungleRider(), crashes = 0
            for _ in 0..<7_200 {
                crashes += sim.step(input: rider.controls(sim, speed: 24)).filter { $0 == .crashed }.count
            }
            assertFinite(sim)
            XCTAssertEqual(crashes, 0, "seed=\(seed)")
            XCTAssertGreaterThan(sim.state.distance, 950, "seed=\(seed)")
        }
    }

    func testPassiveThrottleAndGroundThrottleCoastNeedLandingAttitudeControl() {
        for coastInAir in [false, true] {
            let sim = GameSimulation(mode: .weekly, seed: 42, configuration: configuration)
            var held = ControlInput.neutral, crossedRim = false, crashes = 0
            for _ in 0..<2_400 {
                if sim.state.tick.isMultiple(of: 12) {
                    held = coastInAir && !sim.state.bike.grounded ? .neutral : .init(throttle: 1, brake: 0, lean: 1)
                }
                crashes += sim.step(input: held).filter { $0 == .crashed }.count
                crossedRim = crossedRim || sim.state.bike.position.x > 98
                if crashes > 0 { break }
            }
            XCTAssertTrue(crossedRim, "This failure must be the landing, not a stalled approach.")
            XCTAssertEqual(crashes, 1)
            XCTAssertLessThan(sim.state.bike.position.x, 135)
        }
    }

    func testLongGapRequiresMomentumEvenWithIdenticalAirControls() {
        let terrain = TerrainGenerator(seed: 42, style: .junglePlatforms)
        let spans = terrain.solidSpans(from: 0, to: 500)
        XCTAssertEqual(spans[3].lowerBound - spans[2].upperBound, 34)
        for (target, shouldLand) in [(18.0, false), (24.0, true)] {
            let sim = fixture(x: spans[2].upperBound - 60, speed: 3.5)
            let result = crossGap(sim, lip: spans[2].upperBound, landing: spans[3].lowerBound, speed: target)
            XCTAssertEqual(result.landed, shouldLand, "target speed=\(target)")
            XCTAssertEqual(sim.state.lives, shouldLand ? 3 : 2)
        }
    }

    func testSixtyMetreRecoveryApproachCanReachEveryMotifFromNormalRespawnSpeed() {
        for seed in seeds {
            let terrain = TerrainGenerator(seed: seed, style: .junglePlatforms)
            let spans = terrain.solidSpans(from: 0, to: 1_700)
            for index in 0..<12 {
                let lip = spans[index].upperBound, landing = spans[index + 1].lowerBound
                let sim = fixture(seed: seed, x: lip - 60, speed: 3.5)
                let result = crossGap(sim, lip: lip, landing: landing, speed: 24)
                let context = "seed=\(seed), ledge=\(lip), gap=\(landing - lip)"
                XCTAssertTrue(result.landed, context)
                XCTAssertTrue(result.aboveRim, "Reception must pass above the real cliff: \(context)")
                XCTAssertEqual(sim.state.lives, 3, context)
            }
        }
    }

    func testShortRollingCrossingAndSteepPopProduceDifferentPhysicalFlights() {
        let terrain = TerrainGenerator(seed: 42, style: .junglePlatforms)
        let spans = terrain.solidSpans(from: 0, to: 4_000)
        guard let short = (0..<spans.count - 1).first(where: { spans[$0 + 1].lowerBound - spans[$0].upperBound == 14 }),
              let pop = (1..<spans.count - 1).first(where: { spans[$0 + 1].lowerBound - spans[$0].upperBound == 18 }) else {
            XCTFail("The mixed route must retain low rollers and steep pops"); return
        }
        XCTAssertEqual(spans[short + 1].lowerBound - spans[short].upperBound, 14)
        XCTAssertEqual(spans[pop + 1].lowerBound - spans[pop].upperBound, 18)
        let rolling = crossGap(fixture(x: spans[short].upperBound - 60, speed: 3.5),
                               lip: spans[short].upperBound, landing: spans[short + 1].lowerBound, speed: 24)
        let vertical = crossGap(fixture(x: spans[pop].upperBound - 60, speed: 3.5),
                                lip: spans[pop].upperBound, landing: spans[pop + 1].lowerBound, speed: 24)
        XCTAssertTrue(rolling.landed && vertical.landed)
        XCTAssertGreaterThan(rolling.launchVelocity.x, vertical.launchVelocity.x + 4)
        XCTAssertGreaterThan(vertical.launchVelocity.y, rolling.launchVelocity.y + 4)
        XCTAssertGreaterThan(vertical.peakAboveLip, rolling.peakAboveLip + 3)
        XCTAssertGreaterThan(vertical.airborneTicks, rolling.airborneTicks + 50)
    }

    func testFlatDeparturesHaveDifferentDropsAndNaturalHorizontalFlights() {
        var drops = Set<Int>()
        for seed in seeds {
            let terrain = TerrainGenerator(seed: seed, style: .junglePlatforms)
            let spans = terrain.solidSpans(from: 0, to: 1_700)
            for index in [3, 6, 9] {
                let lip = spans[index].upperBound, landing = spans[index + 1].lowerBound
                let width = landing - lip
                XCTAssertTrue([16.0, 24].contains(width))
                let result = crossGap(fixture(seed: seed, x: lip - 60, speed: 3.5), lip: lip, landing: landing, speed: 24)
                XCTAssertTrue(result.landed && result.aboveRim, "seed=\(seed), width=\(width)")
                XCTAssertLessThan(abs(result.launchVelocity.y), 0.8, "The departure must be horizontal, without an upward impulse")
                XCTAssertLessThan(result.peakAboveLip, 1.0)
                drops.insert(Int(((terrain.height(at: lip) - terrain.height(at: landing)) * 10).rounded()))
            }
        }
        XCTAssertEqual(drops, [55, 105])
        let terrain = TerrainGenerator(seed: 42, style: .junglePlatforms)
        let spans = terrain.solidSpans(from: 0, to: 650)
        let lip = spans[3].upperBound, landing = spans[4].lowerBound
        XCTAssertFalse(crossGap(fixture(x: lip - 60, speed: 3.5), lip: lip, landing: landing, speed: 14).landed,
                       "The long drop must still need sufficient momentum")
    }

    private struct GapResult {
        var landed = false, aboveRim = false
        var launchVelocity = Vector2()
        var peakAboveLip = 0.0
        var airborneTicks = 0
    }

    private func crossGap(_ sim: GameSimulation, lip: Double, landing: Double, speed: Double) -> GapResult {
        var rider = SimpleJungleRider(), result = GapResult()
        for _ in 0..<3_000 {
            let previousX = sim.state.bike.position.x
            sim.step(input: rider.controls(sim, speed: speed))
            let bike = sim.state.bike
            if previousX < lip && bike.position.x >= lip { result.launchVelocity = bike.velocity }
            if bike.position.x >= lip && !bike.grounded {
                result.airborneTicks += 1
                result.peakAboveLip = max(result.peakAboveLip, bike.position.y - sim.terrainHeight(at: lip))
            }
            if previousX < landing && bike.position.x >= landing {
                let edgeHeight = sim.terrainHeight(at: landing)
                result.aboveRim = min(bike.rear.position.y, bike.front.position.y) - configuration.wheelRadius > edgeHeight
            }
            if sim.state.lives < 3 { return result }
            if bike.position.x > landing + 5 && bike.grounded { result.landed = true; return result }
        }
        return result
    }

    #if DEBUG
    func testJungleUIFixturesAreRealApproachAndHighJumpWithControllableReceptions() {
        for highJump in [false, true] {
            let sim = GameSimulation.jungleCourseFixtureForTesting(highJump: highJump)
            XCTAssertEqual(sim.configuration.terrainStyle, .junglePlatforms)
            XCTAssertEqual(sim.state.seed, 42)
            XCTAssertEqual(sim.state.status, .active)
            XCTAssertEqual(sim.state.lives, 3)
            let spans = sim.terrainSolidSpans(from: 0, to: 500)
            if highJump {
                XCTAssertGreaterThan(sim.state.bike.position.x, spans[2].upperBound)
                XCTAssertLessThan(sim.state.bike.position.x, spans[3].lowerBound)
                XCTAssertFalse(sim.state.bike.grounded)
                XCTAssertLessThanOrEqual(sim.state.bike.velocity.y, 0)
            } else {
                XCTAssertTrue((spans[0].upperBound - 4..<spans[0].upperBound - 3).contains(sim.state.bike.position.x))
                XCTAssertGreaterThan(sim.state.bike.velocity.x, 10)
            }
            let landing = spans[highJump ? 3 : 1].lowerBound
            var rider = SimpleJungleRider(), landed = false
            for _ in 0..<900 {
                sim.step(input: rider.controls(sim, speed: 24))
                if sim.state.bike.position.x > landing + 5 && sim.state.bike.grounded { landed = true; break }
                if sim.state.lives < 3 { break }
            }
            XCTAssertTrue(landed)
            XCTAssertEqual(sim.state.lives, 3)
            XCTAssertEqual(sim.state.status, .active)
        }
    }
    #endif

    func testAirborneGapRebasePreservesPoseAndDoesNotCreateGround() {
        let reference = fixture(x: 89, speed: 0, height: 12)
        let shifted = fixture(x: 89, speed: 0, height: 12)
        let before = shifted.state
        shifted.rebaseForTesting(by: .init(x: 256, y: -256))
        XCTAssertEqual(shifted.state, before)
        for _ in 0..<90 {
            reference.step(input: .neutral); shifted.step(input: .neutral)
            XCTAssertFalse(shifted.state.bike.grounded)
            XCTAssertEqual(shifted.state.bike.position.x, reference.state.bike.position.x, accuracy: 0.01)
            XCTAssertEqual(shifted.state.bike.position.y, reference.state.bike.position.y, accuracy: 0.01)
            XCTAssertEqual(shifted.state.bike.velocity.y, reference.state.bike.velocity.y, accuracy: 0.01)
        }
    }
}

/// App-style 100 ms binary pedal holds, reacting only to current speed, pitch
/// and spin. No future terrain, predicted trajectory or simulation-state edits.
/// This proves physical reachability; it does not measure human enjoyment.
private struct SimpleJungleRider {
    private var held = ControlInput.neutral
    mutating func controls(_ simulation: GameSimulation, speed: Double) -> ControlInput {
        guard simulation.state.tick.isMultiple(of: 12) else { return held }
        let bike = simulation.state.bike
        if bike.grounded {
            let slope = (simulation.terrainHeight(at: bike.position.x + 0.1) - simulation.terrainHeight(at: bike.position.x - 0.1)) / 0.2
            let error = atan2(sin(bike.angle - atan(slope)), cos(bike.angle - atan(slope)))
            let brake = bike.velocity.x > speed + 1 || (error > 0.28 && bike.velocity.x > 1) ? 1.0 : 0
            let throttle = brake == 0 && bike.velocity.x < speed && error < 0.25 ? 1.0 : 0
            held = .init(throttle: throttle, brake: brake, lean: throttle - brake)
        } else {
            let error = atan2(sin(-0.08 - bike.angle), cos(-0.08 - bike.angle))
            let effort = error * 2.2 - bike.angularVelocity * 0.8
            let throttle = effort > 0.22 ? 1.0 : 0, brake = effort < -0.22 ? 1.0 : 0
            held = .init(throttle: throttle, brake: brake, lean: throttle - brake)
        }
        return held
    }
}
