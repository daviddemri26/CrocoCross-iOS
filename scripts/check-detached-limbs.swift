import Foundation
import CrocoCrossCore

@main struct CheckDetachedLimbs {
    struct Failure: Error, CustomStringConvertible {
        let description: String
        init(_ message: String) { description = message }
    }
    struct Sample: Codable {
        let name: String
        let hz: Int
        let isLeg: Bool
        let side: Double
        let reducedMotion: Bool
        let minimumBend: Double
        let maximumBend: Double
        let minimumRoot: Double
        let maximumRoot: Double
        let upperTravel: Double
        let lowerTravel: Double
        let maximumFrameMotion: Double
        let maximumReachFraction: Double
        let finalUpper: Double
        let finalLower: Double
    }
    struct Comparison: Codable {
        let name: String
        let isLeg: Bool
        let side: Double
        let reducedMotion: Bool
        let upper30vs120: Double
        let lower30vs120: Double
        let upper60vs120: Double
        let lower60vs120: Double
    }
    struct Report: Codable {
        let passed: Bool
        let trajectories: Int
        let testedFrames: Int
        let initialPoseCases: Int
        let minimumBendDegrees: Double
        let maximumReachFraction: Double
        let maximumFrameMotion: Double
        let minimumNormalTravelComparedWithOldFlutter: Double
        let samples: [Sample]
        let frequencyComparisons: [Comparison]
        let notes: [String]
    }

    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if !condition() { throw Failure(message) }
    }
    static func wrap(_ angle: Double) -> Double { atan2(sin(angle), cos(angle)) }
    static func body(_ name: String, at t: Double) -> RigidBodyState {
        switch name {
        case "ballistic":
            return .init(velocity: .init(x: 8, y: 10 - 9.81 * t), angle: 0.25 + 1.2 * t, angularVelocity: 1.2)
        case "impact":
            return .init(velocity: t < 1 ? .init(x: 14, y: -18) : .init(x: -3 * exp(-(t - 1)), y: 3 * exp(-2 * (t - 1))),
                         angle: 0.25 + 4 * t, angularVelocity: 4)
        case "positive-spin":
            return .init(velocity: .init(x: 20 * cos(t), y: t < 1.5 ? -12 : 8), angle: 0.25 + 18 * t, angularVelocity: 18)
        case "negative-spin":
            return .init(velocity: .init(x: -18 * sin(t), y: t < 1.5 ? -16 : 4), angle: 0.25 - 22 * t, angularVelocity: -22)
        default:
            let sign = Int(floor(t * 4)) % 2 == 0 ? 1.0 : -1.0
            return .init(velocity: .init(x: 50 * sign, y: -45 * sign), angle: 0.25 + 40 * t, angularVelocity: 40)
        }
    }
    static func lengths(_ isLeg: Bool) -> (Double, Double) { isLeg ? (0.43, 0.42) : (0.31, 0.27) }

    static func trajectory(name: String, hz: Int, isLeg: Bool, side: Double, reduced: Bool) throws -> Sample {
        let initialBody = body(name, at: 0), sign = isLeg ? -1.0 : 1.0
        let initialUpper = initialBody.angle - 1.25 + side * 0.1
        let initialLower = initialUpper + sign * 0.75
        var motion = DetachedLimbMotion(upper: initialUpper, lower: initialLower, body: initialBody, side: side)
        let (upperLength, lowerLength) = lengths(isLeg)
        var minimumBend = Double.infinity, maximumBend = -Double.infinity
        var minimumRoot = Double.infinity, maximumRoot = -Double.infinity
        var upperTravel = 0.0, lowerTravel = 0.0, maximumFrameMotion = 0.0, maximumReach = 0.0
        let minRoot = isLeg ? -2.8 : -3.5, maxRoot = isLeg ? 0.65 : 1.2
        let centre = (minRoot + maxRoot) / 2
        for frame in 1...(hz * 4) {
            let t = Double(frame) / Double(hz), sample = body(name, at: t)
            let oldUpper = motion.upper, oldLower = motion.lower
            motion.advance(dt: 1 / Double(hz), body: sample, bodyAngle: sample.angle,
                           upperLength: upperLength, lowerLength: lowerLength, isLeg: isLeg, side: side, reducedMotion: reduced)
            let label = "\(name) \(hz)Hz leg=\(isLeg) side=\(side) reduced=\(reduced) frame=\(frame)"
            try expect(motion.upper.isFinite && motion.lower.isFinite, "Non-finite angles: " + label)
            let bend = wrap(motion.lower - motion.upper) * sign
            let root = centre + wrap(motion.upper - sample.angle - centre)
            try expect(bend >= 0.015 - 1e-9 && bend <= (isLeg ? 2.45 : 2.65) + 1e-9, "Hinge direction/limit violated: \(bend) " + label)
            try expect(root >= minRoot - 1e-9 && root <= maxRoot + 1e-9, "Root limit violated: \(root) " + label)
            minimumBend = min(minimumBend, bend); maximumBend = max(maximumBend, bend)
            minimumRoot = min(minimumRoot, root); maximumRoot = max(maximumRoot, root)
            let upperStep = abs(wrap(motion.upper - oldUpper)), lowerStep = abs(wrap(motion.lower - oldLower))
            upperTravel += upperStep; lowerTravel += lowerStep
            maximumFrameMotion = max(maximumFrameMotion, upperStep, lowerStep)
            let reach = sqrt(upperLength * upperLength + lowerLength * lowerLength + 2 * upperLength * lowerLength * cos(bend))
            maximumReach = max(maximumReach, reach / (upperLength + lowerLength))
        }
        try expect(upperTravel > 0.25 && lowerTravel > 0.25, "Motion stayed near the old 0.025-radian flutter: \(name)")
        return Sample(name: name, hz: hz, isLeg: isLeg, side: side, reducedMotion: reduced,
                      minimumBend: minimumBend, maximumBend: maximumBend, minimumRoot: minimumRoot, maximumRoot: maximumRoot,
                      upperTravel: upperTravel, lowerTravel: lowerTravel, maximumFrameMotion: maximumFrameMotion,
                      maximumReachFraction: maximumReach, finalUpper: motion.upper, finalLower: motion.lower)
    }

    static func main() throws {
        let output = CommandLine.arguments.dropFirst().first ?? "/tmp/crococross-detached-limbs-report.json"
        var poseCases = 0
        for isLeg in [false, true] {
            for side in [-1.0, 1.0] {
                for reduced in [false, true] {
                    for angle in [-2.5, -0.4, 0.0, 1.1, 3.0] {
                        let rigid = RigidBodyState(velocity: .init(x: 12, y: -4), angle: angle, angularVelocity: -7)
                        let upper = angle - 1.1, lower = upper + (isLeg ? -0.8 : 0.8)
                        let original = DetachedLimbMotion(upper: upper, lower: lower, body: rigid, side: side)
                        try expect(original.upper == upper && original.lower == lower, "Initializer changed the release pose")
                        for dt in [0, -1, Double.nan, .infinity] {
                            var frozen = original, expected = original
                            frozen.advance(dt: dt, body: .init(velocity: .init(x: 999, y: -999), angle: 2, angularVelocity: 999), bodyAngle: 3,
                                           upperLength: 0.4, lowerLength: 0.4, isLeg: isLeg, side: side, reducedMotion: reduced)
                            try expect(frozen.upper == upper && frozen.lower == lower, "Zero/invalid dt changed the pose")
                            frozen.advance(dt: 1 / 60, body: rigid, bodyAngle: angle, upperLength: 0.4, lowerLength: 0.4, isLeg: isLeg, side: side, reducedMotion: reduced)
                            expected.advance(dt: 1 / 60, body: rigid, bodyAngle: angle, upperLength: 0.4, lowerLength: 0.4, isLeg: isLeg, side: side, reducedMotion: reduced)
                            try expect(frozen.upper == expected.upper && frozen.lower == expected.lower, "Zero/invalid dt changed hidden integration state")
                        }
                        var capped = original, short = original
                        capped.advance(dt: 5, body: rigid, bodyAngle: angle, upperLength: 0.4, lowerLength: 0.4, isLeg: isLeg, side: side, reducedMotion: reduced)
                        short.advance(dt: 0.1, body: rigid, bodyAngle: angle, upperLength: 0.4, lowerLength: 0.4, isLeg: isLeg, side: side, reducedMotion: reduced)
                        try expect(capped.upper == short.upper && capped.lower == short.lower, "Long frame did not cap to 0.1 seconds")
                        poseCases += 1
                    }
                }
            }
        }
        var samples: [Sample] = [], comparisons: [Comparison] = []
        for name in ["ballistic", "impact", "positive-spin", "negative-spin", "stress-impacts"] {
            for isLeg in [false, true] {
                for side in [-1.0, 1.0] {
                    for reduced in [false, true] {
                        let run = try [30, 60, 120].map { try trajectory(name: name, hz: $0, isLeg: isLeg, side: side, reduced: reduced) }
                        samples += run
                        comparisons.append(Comparison(name: name, isLeg: isLeg, side: side, reducedMotion: reduced,
                                                      upper30vs120: abs(wrap(run[0].finalUpper - run[2].finalUpper)),
                                                      lower30vs120: abs(wrap(run[0].finalLower - run[2].finalLower)),
                                                      upper60vs120: abs(wrap(run[1].finalUpper - run[2].finalUpper)),
                                                      lower60vs120: abs(wrap(run[1].finalLower - run[2].finalLower))))
                    }
                }
            }
        }
        for isLeg in [false, true] {
            for side in [-1.0, 1.0] {
                for reduced in [false, true] {
                    let matching = samples.filter { $0.isLeg == isLeg && $0.side == side && $0.reducedMotion == reduced }
                    try expect(matching.contains { $0.maximumReachFraction >= 0.9999 }, "Near-full extension was never reached for leg=\(isLeg), side=\(side), reduced=\(reduced)")
                }
            }
        }
        let minimumTravel = samples.filter { !$0.reducedMotion }.map { min($0.upperTravel, $0.lowerTravel) }.min()!
        let report = Report(passed: true, trajectories: samples.count, testedFrames: samples.reduce(0) { $0 + $1.hz * 4 },
                            initialPoseCases: poseCases, minimumBendDegrees: samples.map(\.minimumBend).min()! * 180 / .pi,
                            maximumReachFraction: samples.map(\.maximumReachFraction).max()!, maximumFrameMotion: samples.map(\.maximumFrameMotion).max()!,
                            minimumNormalTravelComparedWithOldFlutter: minimumTravel / 0.025,
                            samples: samples, frequencyComparisons: comparisons,
                            notes: ["Pure production model test; no renderer, physics or simulator was modified.",
                                    "The model's lower bend limit is 0.015 rad (0.859 degrees): near-full reach, not mathematically zero bend.",
                                    "Frame-rate deltas are measured, not hidden by a loose equality assertion. Root-limit impacts are nonlinear.",
                                    "Travel/0.025 compares accumulated motion with old flutter amplitude, not an amplitude-equivalent ratio."])
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(report).write(to: URL(fileURLWithPath: output), options: .atomic)
        print("PASS: \(samples.count) production-model trajectories, \(report.testedFrames) frames, \(poseCases) release cases; finite bounded angles, directional hinge limits, frozen dt and near-full extension. JSON: \(output)")
    }
}
