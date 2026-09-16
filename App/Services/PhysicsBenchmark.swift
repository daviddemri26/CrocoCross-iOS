import CrocoCrossCore
import Darwin
import Foundation
import UIKit

/// An opt-in, offline device measurement of the production solver. It does not
/// replace gameplay physics or run during ordinary launches or UI tests.
@MainActor
enum PhysicsBenchmark {
    private static var hasRun = false
    private static let warmupCount = 1_000
    private static let measuredCount = 10_000
    private static let seeds: [UInt32] = [42, 913, 2_026, 81_731]

    @discardableResult
    static func runIfRequested() -> Bool {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("-physics-benchmark"), arguments.contains("-ui-testing") else { return false }
        guard !hasRun else { return true }
        hasRun = true

        // Keeping the measurement synchronous prevents SpriteKit frames from
        // interleaving with this loop. Creation/reset, input and file IO are untimed.
        var warmup = GameSimulation(mode: .weekly, seed: seeds[0])
        var warmupResets = 0
        for index in 0..<warmupCount {
            resetIfNeeded(&warmup, resets: &warmupResets)
            warmup.step(input: input(for: warmup.state.tick, sequence: index / 720))
        }

        var simulation = GameSimulation(mode: .weekly, seed: seeds[0])
        var resets = 0
        var samples: [Double] = []
        samples.reserveCapacity(measuredCount)
        var maximumDistance = 0.0
        var maximumTerrainChunks = 0
        var maximumBodyCount = 0
        let clock = ContinuousClock()
        let thermalStateBefore = ProcessInfo.processInfo.thermalState.rawValue
        for index in 0..<measuredCount {
            resetIfNeeded(&simulation, resets: &resets)
            let controls = input(for: simulation.state.tick, sequence: index / 720)
            let start = clock.now
            simulation.step(input: controls)
            let duration = start.duration(to: clock.now).components
            samples.append(Double(duration.seconds) * 1_000 + Double(duration.attoseconds) / 1e15)
            maximumDistance = max(maximumDistance, simulation.state.distance)
            maximumTerrainChunks = max(maximumTerrainChunks, simulation.diagnostics.terrainChunkCount)
            maximumBodyCount = max(maximumBodyCount, simulation.diagnostics.bodyCount)
        }
        let sorted = samples.sorted()
        let median = (sorted[measuredCount / 2 - 1] + sorted[measuredCount / 2]) * 0.5
        let p95 = sorted[Int(ceil(Double(measuredCount) * 0.95)) - 1]
        #if DEBUG
        let buildConfiguration = "Debug"
        #else
        let buildConfiguration = "Release"
        #endif
        #if targetEnvironment(simulator)
        let environment = "simulator"
        #else
        let environment = "physical-device"
        #endif
        var hardware = utsname()
        uname(&hardware)
        let hardwareIdentifier = withUnsafeBytes(of: hardware.machine) {
            String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self)
        }
        let report = Report(
            generatedAt: Date(), engineVersion: GameSimulation.engineVersion,
            backendVersion: GameSimulation.backendVersion, environment: environment,
            deviceModel: UIDevice.current.model, hardwareIdentifier: hardwareIdentifier,
            systemVersion: UIDevice.current.systemVersion, buildConfiguration: buildConfiguration,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            appBuild: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown",
            warmupSteps: warmupCount, measuredSteps: samples.count, warmupResets: warmupResets,
            measuredResets: resets, seeds: seeds, simulationTimeStep: GameSimulation.timeStep,
            solverSubsteps: Int(PhysicsConfiguration.substeps),
            medianMilliseconds: median, p95Milliseconds: p95, maxMilliseconds: sorted.last!,
            p95UnderOneMillisecond: p95 < 1,
            maximumDistanceMetres: maximumDistance, maximumTerrainChunks: maximumTerrainChunks,
            maximumBodyCount: maximumBodyCount, thermalStateBefore: thermalStateBefore,
            thermalStateAfter: ProcessInfo.processInfo.thermalState.rawValue,
            lowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled
        )
        do {
            let directory = try FileManager.default.url(
                for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let url = directory.appendingPathComponent("physics-benchmark.json")
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(report).write(to: url, options: .atomic)
            print("Physics benchmark complete: \(url.path); p95=\(p95) ms, \(samples.count) real steps")
        } catch {
            print("Physics benchmark could not write its report: \(error)")
        }
        return true
    }

    private static func resetIfNeeded(_ simulation: inout GameSimulation, resets: inout Int) {
        guard simulation.state.status == .crashed || simulation.state.status == .finished else { return }
        resets += 1
        simulation = GameSimulation(mode: .weekly, seed: seeds[resets % seeds.count])
    }

    private static func input(for tick: Int, sequence: Int) -> ControlInput {
        let phase = tick % 720
        let throttle = phase < 480 || phase >= 650 ? 1.0 : 0.0
        let brake = (560..<620).contains(phase) || (sequence % 3 == 2 && (210..<230).contains(phase)) ? 1.0 : 0.0
        return ControlInput(throttle: throttle, brake: brake, lean: throttle - brake)
    }

    private struct Report: Encodable {
        let schemaVersion = 1
        let measurement = "Production GameSimulation.step only; synchronous without rendering; world resets, input and file IO excluded"
        let inputScript = "binary-pedals-v1: 720-tick gas/coast/brake cycle with periodic simultaneous pedals"
        let percentileMethod = "nearest-rank p95; arithmetic middle-pair median"
        let generatedAt: Date
        let engineVersion, backendVersion, environment: String
        let deviceModel, hardwareIdentifier, systemVersion, buildConfiguration, appVersion, appBuild: String
        let warmupSteps, measuredSteps, warmupResets, measuredResets: Int
        let seeds: [UInt32]
        let simulationTimeStep: Double
        let solverSubsteps: Int
        let medianMilliseconds, p95Milliseconds, maxMilliseconds: Double
        let p95UnderOneMillisecond: Bool
        let maximumDistanceMetres: Double
        let maximumTerrainChunks, maximumBodyCount, thermalStateBefore, thermalStateAfter: Int
        let lowPowerModeEnabled: Bool
    }
}
