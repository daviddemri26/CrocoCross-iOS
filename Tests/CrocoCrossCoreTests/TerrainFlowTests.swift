import Foundation
import XCTest
@testable import CrocoCrossCore

final class TerrainFlowTests: XCTestCase {
    private let seeds: [UInt32] = [0, 1, 3, 42, 913, .max]

    func testCoursesMixHillSizesAndLeaveLongDescendingReceptions() {
        for seed in seeds {
            let terrain = TerrainGenerator(seed: seed)
            let start = TerrainGenerator.entryLength
            let end = start + GameSimulation.weeklyDistance
            var descending = 0, climbing = 0, sampleCount = 0
            var descendingRun = 0.0, shortestReception = Double.infinity
            var followingCrest = false, wasClimbing = false, receptions = 0
            var maximumSlope = 0.0, maximumCompressionCurvature = 0.0
            for x in stride(from: start, through: end, by: 0.1) {
                let slope = terrain.slope(at: x)
                sampleCount += 1
                if slope < 0 { descending += 1 }
                if slope > 0.15 { climbing += 1; wasClimbing = true }
                maximumSlope = max(maximumSlope, abs(slope))
                let curvature = (terrain.slope(at: x + 0.001) - terrain.slope(at: x - 0.001)) / 0.002
                maximumCompressionCurvature = max(maximumCompressionCurvature, curvature)
                if slope < 0 && wasClimbing {
                    followingCrest = true; wasClimbing = false
                }
                if followingCrest {
                    if slope < 0 {
                        descendingRun += 0.1
                    } else {
                        shortestReception = min(shortestReception, descendingRun)
                        receptions += 1; descendingRun = 0; followingCrest = false
                    }
                }
            }
            XCTAssertGreaterThan(Double(descending) / Double(sampleCount), 0.70, "seed=\(seed)")
            XCTAssertGreaterThan(Double(climbing) / Double(sampleCount), 0.10, "Real ramps must remain among the descents.")
            XCTAssertLessThan(maximumSlope, 0.95, "Approaches and receptions must avoid walls.")
            XCTAssertLessThan(maximumCompressionCurvature, 0.25, "Valleys must turn the bike gradually, without a sharp suspension load.")
            XCTAssertGreaterThan(Double(receptions) / GameSimulation.weeklyDistance * 1_000, 27.5,
                                 "Keep the same minimum reception density on the shorter course")
            XCTAssertGreaterThan(shortestReception, 12, "Each crest needs a sustained downhill reception before the next climb.")
            XCTAssertEqual(terrain.height(at: start + 60 * TerrainGenerator.sectionLength) - terrain.height(at: start),
                           -60 * TerrainGenerator.sectionLength * TerrainGenerator.descentGrade, accuracy: 0.000001)
        }
    }

    func testSeededGroupsKeepLowMediumAndTallBumpsWithoutLongRepetitiveRuns() {
        for seed in seeds {
            let terrain = TerrainGenerator(seed: seed)
            let start = TerrainGenerator.entryLength
            let startHeight = terrain.height(at: start)
            // The first four sections introduce the full height progressively.
            for group in 2 ..< 34 {
                var peaks: [Double] = []
                for section in (1 + group * 3) ... (3 + group * 3) {
                    let sectionStart = start + Double(section) * TerrainGenerator.sectionLength
                    let peak = stride(from: sectionStart, through: sectionStart + TerrainGenerator.sectionLength, by: 0.1)
                        .map { x in terrain.height(at: x) - startHeight + (x - start) * TerrainGenerator.descentGrade }.max()!
                    peaks.append(peak)
                }
                peaks.sort()
                XCTAssertLessThan(peaks[0], 3.1, "Every group needs a low flowing stretch, seed=\(seed).")
                XCTAssertGreaterThan(peaks[1], 4.0)
                XCTAssertLessThan(peaks[1], 5.8)
                XCTAssertGreaterThan(peaks[2], 5.6, "Every group needs a genuine tall takeoff, seed=\(seed).")
                XCTAssertLessThan(peaks[2], 7.5)
            }
        }
    }

    func testHeightSlopeAndCurvatureStayContinuousAcrossEveryKnotAndSection() {
        let epsilon = 0.0001
        for seed in seeds {
            let terrain = TerrainGenerator(seed: seed)
            // Every knot is at an integer offset, including all section/entry joins.
            for x in stride(from: 12.0, through: 24 + 30 * TerrainGenerator.sectionLength, by: 1) {
                let left = terrain.height(at: x - epsilon)
                let right = terrain.height(at: x + epsilon)
                XCTAssertEqual(right - left, 2 * epsilon * terrain.slope(at: x), accuracy: 0.0000001)
                XCTAssertEqual(terrain.slope(at: x - epsilon), terrain.slope(at: x + epsilon), accuracy: 0.0002)
                let leftCurvature = (terrain.slope(at: x - epsilon) - terrain.slope(at: x - 2 * epsilon)) / epsilon
                let rightCurvature = (terrain.slope(at: x + 2 * epsilon) - terrain.slope(at: x + epsilon)) / epsilon
                XCTAssertEqual(leftCurvature, rightCurvature, accuracy: 0.001, "Curvature discontinuity at \(x), seed=\(seed).")
            }
        }
    }

    func testAnalyticalSlopeMatchesHeightAndSamplingOrderDoesNotChangeCourse() throws {
        for seed in seeds {
            let terrain = TerrainGenerator(seed: seed)
            let restored = try JSONDecoder().decode(TerrainGenerator.self, from: JSONEncoder().encode(terrain))
            let positions = Array(stride(from: 11.8, through: 4_024, by: 0.371)) + [1_000_000.123, 10_000_000.25]
            let forward = positions.map { terrain.height(at: $0) }
            for (index, x) in positions.enumerated().reversed() {
                XCTAssertEqual(restored.height(at: x), forward[index])
                let gradient = (terrain.height(at: x + 0.001) - terrain.height(at: x - 0.001)) / 0.002
                XCTAssertEqual(terrain.slope(at: x), gradient, accuracy: 0.000002)
            }
            let flat = TerrainGenerator(seed: seed, style: .flat)
            for x in [-100.0, 0, 24, 1_000, .infinity, -.infinity, .nan] {
                XCTAssertEqual(flat.height(at: x), 0)
                XCTAssertEqual(flat.slope(at: x), 0)
            }
            for x in [Double.infinity, -Double.infinity, .nan] {
                XCTAssertEqual(terrain.height(at: x), 0)
                XCTAssertEqual(terrain.slope(at: x), 0)
            }
        }
    }
}
