import Foundation
import XCTest
@testable import CrocoCrossCore

final class RiderLandingTests: XCTestCase {
    func testFastUprightLandingsKeepLifeAndBoundRiderPose() throws {
        var skimmedGround = false
        var poses: [String: SimulationState] = [:]
        for speed in [12.0, 20, 28] {
            for descent in [-8.0, -16, -24] {
                let sim = flatFixture(speed: speed, height: 1.5, descent: descent)
                for tick in 0..<360 {
                    let events = sim.step(input: .neutral)
                    if events.contains(.crashed) {
                        XCTAssertGreaterThan(abs(sim.state.bike.angle), .pi / 4,
                                             "A straight impact must not lose a life")
                        break
                    }
                    XCTAssertEqual(sim.state.lives, 1)
                    XCTAssertEqual(sim.state.status, .active)
                    skimmedGround = skimmedGround || sim.diagnostics.chassisContact
                    assertHipLimit(sim)
                    if speed == 20 && descent == -16 {
                        if tick == 0 { poses["airborne"] = sim.state }
                        if sim.state.bike.rear.compression > 0.35 && poses["impact"] == nil { poses["impact"] = sim.state }
                        if tick == 359 { poses["settled"] = sim.state }
                    }
                }
                if descent >= -16 { XCTAssertEqual(sim.state.status, .active) }
            }
        }
        XCTAssertTrue(skimmedGround, "This regression must exercise a real skid-plate contact")
        if let output = ProcessInfo.processInfo.environment["CROCO_QA_POSES"] {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(poses).write(to: URL(fileURLWithPath: output))
        }
    }

    func testAlternatingPedalsKeepPhysicalHipWithinAnatomicalLimits() {
        let sim = flatFixture(speed: 16, height: 35, descent: 0, spin: 5)
        for tick in 0..<240 {
            let lean = (tick / 24).isMultiple(of: 2) ? 1.0 : -1.0
            sim.step(input: .init(throttle: max(0, lean), brake: max(0, -lean), lean: lean))
            assertFinite(sim)
            if sim.state.rider.isAttached { assertHipLimit(sim) }
        }
    }

    private func assertHipLimit(_ sim: GameSimulation, file: StaticString = #filePath, line: UInt = #line) {
        let rider = sim.state.rider
        XCTAssertLessThan(abs(wrapped(rider.torso.angle - rider.pelvis.angle)), 0.40, file: file, line: line)
    }
}
