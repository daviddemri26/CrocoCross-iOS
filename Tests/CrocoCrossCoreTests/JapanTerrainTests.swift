import Foundation
import XCTest
@testable import CrocoCrossCore

final class JapanTerrainTests: XCTestCase {
    private let seeds: [UInt32] = [0, 1, 3, 42, 913, .max]

    private struct Geometry {
        var descendingFraction = 0.0
        var maximumSlope = 0.0
        var compressionCurvature = 0.0
        var crestCurvature = 0.0
        var shortestReception = Double.infinity
        var receptions = 0
    }

    private func geometry(_ terrain: TerrainGenerator) -> Geometry {
        var result = Geometry(), descending = 0, samples = 0
        var hasClimbed = false, receptionLength = 0.0
        for x in stride(from: TerrainGenerator.entryLength, through: 2_624, by: 0.1) {
            let slope = terrain.slope(at: x)
            let curvature = (terrain.slope(at: x + 0.001) - terrain.slope(at: x - 0.001)) / 0.002
            result.maximumSlope = max(result.maximumSlope, abs(slope))
            result.compressionCurvature = max(result.compressionCurvature, curvature)
            result.crestCurvature = max(result.crestCurvature, -curvature)
            samples += 1
            if slope < 0 { descending += 1 }
            if slope > 0.15 { hasClimbed = true }
            if hasClimbed && slope < 0 { receptionLength += 0.1 }
            if receptionLength > 0 && slope >= 0 {
                result.shortestReception = min(result.shortestReception, receptionLength)
                result.receptions += 1
                receptionLength = 0; hasClimbed = false
            }
        }
        result.descendingFraction = Double(descending) / Double(samples)
        return result
    }

    func testMountainRidgesAreSharperWithSafeSlopesAndSustainedReceptions() {
        for seed in seeds {
            let canyon = geometry(TerrainGenerator(seed: seed))
            let japan = geometry(TerrainGenerator(seed: seed, style: .japanMountains))
            XCTAssertGreaterThan(japan.crestCurvature, canyon.crestCurvature * 1.75)
            XCTAssertGreaterThan(japan.receptions, canyon.receptions)
            XCTAssertGreaterThan(japan.descendingFraction, 0.68)
            XCTAssertLessThan(japan.maximumSlope, 0.85)
            XCTAssertLessThan(japan.compressionCurvature, 0.26)
            XCTAssertGreaterThan(japan.shortestReception, 14)
        }
    }

    func testMostMountainCrownsAreNoticeablyNarrowerThanCanyon() {
        func crownWidths(_ terrain: TerrainGenerator, sectionLength: Double) -> [Double] {
            let entry = TerrainGenerator.entryLength
            let baseline = terrain.height(at: entry)
            return (7..<40).compactMap { section in
                let start = entry + Double(section) * sectionLength
                let offsets = stride(from: start, through: start + sectionLength, by: 0.05).map {
                    terrain.height(at: $0) - baseline + ($0 - entry) * TerrainGenerator.descentGrade
                }
                let peak = offsets.max()!
                // Medium/tall main crowns only; remove the shared downhill baseline.
                guard peak > 4 else { return nil }
                return Double(offsets.filter { $0 >= peak * 0.85 }.count) * 0.05
            }.sorted()
        }
        for seed in seeds {
            let canyon = crownWidths(TerrainGenerator(seed: seed), sectionLength: TerrainGenerator.sectionLength)
            let japan = crownWidths(TerrainGenerator(seed: seed, style: .japanMountains),
                                    sectionLength: TerrainGenerator.japanSectionLength)
            XCTAssertGreaterThan(japan.count, 15)
            for quantile in [0.25, 0.5, 0.75] {
                let japanWidth = japan[Int(Double(japan.count - 1) * quantile)]
                let canyonWidth = canyon[Int(Double(canyon.count - 1) * quantile)]
                XCTAssertLessThan(japanWidth, canyonWidth * 0.72,
                                  "The shape difference must cover the distribution, not one sharp spike: seed=\(seed), quantile=\(quantile)")
            }
        }
    }

    func testEveryMountainGroupHasLowMediumAndHighRidgesAfterStableIntroduction() {
        let start = TerrainGenerator.entryLength, length = TerrainGenerator.japanSectionLength
        for seed in seeds {
            let terrain = TerrainGenerator(seed: seed, style: .japanMountains)
            let canyon = TerrainGenerator(seed: seed)
            for x in stride(from: -10.0, through: start, by: 0.25) {
                XCTAssertEqual(terrain.height(at: x), canyon.height(at: x))
                XCTAssertEqual(terrain.slope(at: x), canyon.slope(at: x))
            }
            let baseline = terrain.height(at: start)
            func peak(_ section: Int) -> Double {
                let x0 = start + Double(section) * length
                return stride(from: x0, through: x0 + length, by: 0.1).map {
                    terrain.height(at: $0) - baseline + ($0 - start) * TerrainGenerator.descentGrade
                }.max()!
            }
            XCTAssertLessThan(peak(0), 2.0, "The opening must be a low confidence-building ridge.")
            for group in 2..<15 {
                let peaks = (1 + group * 3 ... 3 + group * 3).map(peak).sorted()
                XCTAssertLessThan(peaks[0], 2.8)
                XCTAssertGreaterThan(peaks[1], 4.2); XCTAssertLessThan(peaks[1], 5.5)
                XCTAssertGreaterThan(peaks[2], 5.8); XCTAssertLessThan(peaks[2], 7.6)
            }
            XCTAssertEqual(terrain.height(at: start + length * 40) - baseline,
                           -length * 40 * TerrainGenerator.descentGrade, accuracy: 0.000001)
        }
    }

    func testMountainContactsStayContinuousAndSamplingIsDeterministic() throws {
        let epsilon = 0.0001
        for seed in seeds {
            let terrain = TerrainGenerator(seed: seed, style: .japanMountains)
            let restored = try JSONDecoder().decode(TerrainGenerator.self, from: JSONEncoder().encode(terrain))
            XCTAssertEqual(restored.style, .japanMountains)
            // Cover every integer and half-metre profile knot and all section joins.
            for x in stride(from: 12.0, through: 24 + 45 * TerrainGenerator.japanSectionLength, by: 0.5) {
                XCTAssertEqual(terrain.height(at: x + epsilon) - terrain.height(at: x - epsilon),
                               2 * epsilon * terrain.slope(at: x), accuracy: 0.0000001)
                XCTAssertEqual(terrain.slope(at: x - epsilon), terrain.slope(at: x + epsilon), accuracy: 0.0002)
                let left = (terrain.slope(at: x - epsilon) - terrain.slope(at: x - 2 * epsilon)) / epsilon
                let right = (terrain.slope(at: x + 2 * epsilon) - terrain.slope(at: x + epsilon)) / epsilon
                XCTAssertEqual(left, right, accuracy: 0.002, "seed=\(seed), knot=\(x)")
            }
            let positions = Array(stride(from: 11.8, through: 2_624, by: 0.371)) + [1_000_000.123, 10_000_000.25]
            let heights = positions.map { terrain.height(at: $0) }
            for (index, x) in positions.enumerated().reversed() {
                XCTAssertEqual(restored.height(at: x), heights[index])
                XCTAssertEqual(terrain.slope(at: x),
                               (terrain.height(at: x + 0.001) - terrain.height(at: x - 0.001)) / 0.002,
                               accuracy: 0.000002)
            }
            for x in [Double.infinity, -.infinity, .nan] {
                XCTAssertEqual(terrain.height(at: x), 0); XCTAssertEqual(terrain.slope(at: x), 0)
            }
        }
    }

    func testMountainTakeoffsAllowABackflipAndContinuedSafeRiding() {
        var configuration = PhysicsConfiguration(); configuration.terrainStyle = .japanMountains
        for seed: UInt32 in [3, 8, 11] {
            let simulation = GameSimulation(mode: .endless, seed: seed, configuration: configuration)
            var attempted = false, attempting = false, takeoffTicks = 0
            var unwrappedAngle = 0.0, priorAngle = 0.0, maxClearance = 0.0
            var airTicks = 0, awarded = 0, awardTick: Int?, landingDistance = 0.0
            for _ in 0..<120 * 45 {
                let bike = simulation.state.bike
                takeoffTicks = bike.grounded ? 0 : takeoffTicks + 1
                if !bike.grounded && takeoffTicks >= 8 && !attempted && predictedFlightDuration(simulation) >= 2.1 {
                    attempted = true; attempting = true
                    unwrappedAngle = bike.angle; priorAngle = bike.angle
                }
                var input = TestRider.controls(simulation, speed: 16)
                if attempting && !bike.grounded {
                    unwrappedAngle += atan2(sin(bike.angle - priorAngle), cos(bike.angle - priorAngle))
                    priorAngle = bike.angle; airTicks += 1
                    maxClearance = max(maxClearance, bike.position.y - simulation.terrainHeight(at: bike.position.x)
                        - simulation.configuration.restingRideHeight)
                    let error = Double.pi * 2 - 0.2 - unwrappedAngle
                    let stopping = bike.angularVelocity * abs(bike.angularVelocity) / (2 * 4.1)
                    let lean = error > 1.2 ? (error > stopping + 0.06 ? 1.0 : -1.0)
                        : min(1, max(-1, error * 6 - bike.angularVelocity * 2.2))
                    input = .init(throttle: max(0, lean), brake: max(0, -lean), lean: lean)
                }
                XCTAssertEqual(input.lean, input.throttle - input.brake)
                for event in simulation.step(input: input) {
                    if case let .flip(count) = event {
                        XCTAssertTrue(simulation.state.bike.grounded)
                        XCTAssertEqual(simulation.landedFrontflips, 0)
                        XCTAssertEqual(simulation.landedBackflips, count)
                        awarded += count; awardTick = simulation.state.tick
                        landingDistance = simulation.state.distance
                    }
                }
                if attempting && simulation.state.bike.grounded { attempting = false }
                if simulation.state.status != .active { break }
                if let awardTick, simulation.state.tick >= awardTick + 120 * 3 { break }
            }
            let context = "seed=\(seed), distance=\(simulation.state.distance), clearance=\(maxClearance)"
            print("JAPAN-FLIP \(context), awarded=\(awarded), status=\(simulation.state.status)")
            XCTAssertTrue(attempted, context)
            XCTAssertEqual(awarded, 1, context)
            XCTAssertEqual(simulation.state.status, .active, context)
            XCTAssertEqual(simulation.state.lives, 3, context)
            XCTAssertGreaterThan(simulation.state.distance, landingDistance + 10, context)
            XCTAssertGreaterThan(airTicks, 200, context)
            XCTAssertGreaterThan(maxClearance, 3.5, context)
        }
    }

    private func predictedFlightDuration(_ simulation: GameSimulation) -> Double {
        let bike = simulation.state.bike
        for time in stride(from: 0.1, through: 4.0, by: 0.025) {
            let x = bike.position.x + bike.velocity.x * time
            let y = bike.position.y + bike.velocity.y * time - simulation.configuration.gravity * time * time / 2
            if y <= simulation.terrainHeight(at: x) + simulation.configuration.restingRideHeight { return time }
        }
        return 4
    }

    func testMountainCorpusRemainsRideableWithActualBinaryPedalHolds() {
        var configuration = PhysicsConfiguration(); configuration.terrainStyle = .japanMountains
        for speed in [12.0, 16] {
            for seed: UInt32 in 1...12 {
                let sim = GameSimulation(mode: .endless, seed: seed, configuration: configuration)
                var rider = PulsedTestRider(), crashes = 0, jumps = 0, grounded = false
                var longestFlight = 0, flight = 0, substantialJumps = 0
                var flightClearance = 0.0
                for _ in 0..<7_200 {
                    crashes += sim.step(input: rider.controls(sim, speed: speed)).filter { $0 == .crashed }.count
                    if grounded && !sim.state.bike.grounded { jumps += 1 }
                    if sim.state.bike.grounded {
                        if flight >= 36 && flightClearance > 0.6 { substantialJumps += 1 }
                        flight = 0; flightClearance = 0
                    } else {
                        flight += 1
                        flightClearance = max(flightClearance, sim.state.bike.position.y
                            - sim.terrainHeight(at: sim.state.bike.position.x) - sim.configuration.restingRideHeight)
                    }
                    longestFlight = max(longestFlight, flight); grounded = sim.state.bike.grounded
                }
                let context = "seed=\(seed), target=\(speed)"
                print("JAPAN-RIDE \(context), distance=\(sim.state.distance), crashes=\(crashes), jumps=\(jumps), substantialJumps=\(substantialJumps), longestFlight=\(Double(longestFlight) / 120)")
                assertFinite(sim)
                XCTAssertEqual(crashes, 0, context); XCTAssertEqual(sim.state.status, .active, context)
                XCTAssertEqual(sim.state.lives, 3, context); XCTAssertGreaterThan(jumps, 4, context)
                XCTAssertGreaterThan(longestFlight, 150, context)
                XCTAssertGreaterThan(substantialJumps, 5, "Ground contact chatter must not count as meaningful jumps: " + context)
                XCTAssertGreaterThan(sim.state.distance, speed == 12 ? 630 : 700, context)
            }
        }
    }
}
