import Foundation
import XCTest
@testable import CrocoCrossCore

final class LandingStabilityTests: XCTestCase {
    func testAlignedDropMatrixRetainsSpeedAndAbsorbsImpact() {
        for speed in [12.0, 16, 20] {
            for descent in [-2.0, -4, -8] {
                let sim = flatFixture(speed: speed, descent: descent)
                var touched = false, rebound = 0.0, peakPitch = 0.0
                for _ in 0..<360 {
                    sim.step(input: .neutral)
                    touched = touched || sim.state.bike.grounded
                    if touched {
                        rebound = max(rebound, sim.state.bike.velocity.y)
                        peakPitch = max(peakPitch, abs(sim.state.bike.angle))
                    }
                }
                let context = "vx=\(speed), vy=\(descent)"
                XCTAssertTrue(touched, context); XCTAssertEqual(sim.state.status, .active, context)
                XCTAssertGreaterThan(sim.state.bike.velocity.x, speed * 0.90, context)
                XCTAssertLessThan(rebound, 1.2, context); XCTAssertLessThan(peakPitch, 0.08, context)
                XCTAssertTrue(sim.state.bike.rear.contact && sim.state.bike.front.contact, context)
            }
        }
    }

    func testAngledDropMatrixIsRecoverableWithoutVelocityCorrection() {
        for speed in [12.0, 16, 20] {
            for descent in [-2.0, -4, -8] {
                for angle in [-20.0, 20].map({ $0 * .pi / 180 }) {
                    let sim = flatFixture(speed: speed, descent: descent, angle: angle)
                    var rebound = 0.0, touched = false
                    for _ in 0..<360 {
                        sim.step(input: .neutral); touched = touched || sim.state.bike.grounded
                        if touched { rebound = max(rebound, sim.state.bike.velocity.y) }
                    }
                    let context = "vx=\(speed), vy=\(descent), angle=\(angle)"
                    XCTAssertEqual(sim.state.status, .active, context)
                    XCTAssertGreaterThan(sim.state.bike.velocity.x, speed * 0.80, context)
                    XCTAssertLessThan(rebound, 1.2, context)
                    XCTAssertLessThan(abs(sim.state.bike.angle), 0.08, context)
                    XCTAssertTrue(sim.state.bike.rear.contact && sim.state.bike.front.contact, context)
                }
            }
        }
    }

    func testNearlySimultaneousContactsDoNotKickRearOverHead() {
        for angle in [-0.02, 0.02] {
            let sim = flatFixture(speed: 20, descent: -8, angle: angle)
            var spin = 0.0
            for _ in 0..<360 {
                sim.step(input: .neutral)
                if sim.state.bike.grounded { spin = max(spin, abs(sim.state.bike.angularVelocity)) }
            }
            XCTAssertLessThan(spin, 1.2); XCTAssertEqual(sim.state.status, .active)
            XCTAssertLessThan(abs(sim.state.bike.angle), 0.05)
        }
    }

    func testExtremeFallsStayFiniteAndCrashInsteadOfExploding() {
        for angle in [-0.7, 0, 0.7, .pi] {
            for descent in [-12.0, -20, -35] {
                let sim = flatFixture(speed: 20, height: 3, descent: descent, angle: angle, spin: 2)
                for _ in 0..<360 {
                    sim.step(input: .neutral); sim.stepPresentation(); assertFinite(sim)
                    XCTAssertLessThan(sim.diagnostics.kineticEnergy, 250_000)
                }
                XCTAssertTrue(sim.state.status == .active || sim.state.status == .crashed)
            }
        }
    }

    func testOriginTranslationPreservesAllVelocitiesImmediately() {
        let sim = flatFixture(height: 20, descent: 3, angle: 0.5, spin: 2)
        for _ in 0..<12 { sim.step(input: .neutral) }
        let before = sim.state
        sim.rebaseForTesting(by: .init(x: 256, y: -256))
        XCTAssertEqual(sim.state.bike.position, before.bike.position)
        XCTAssertEqual(sim.state.bike.velocity, before.bike.velocity)
        XCTAssertEqual(sim.state.bike.angularVelocity, before.bike.angularVelocity)
        XCTAssertEqual(sim.state.rider, before.rider)
        XCTAssertEqual(sim.diagnostics.rebaseCount, 1)
    }

    func testAirborneRebaseMatchesUnshiftedWorldWithinFloatTolerance() {
        let a = flatFixture(height: 20, descent: 3, angle: 0.5, spin: 2)
        let b = flatFixture(height: 20, descent: 3, angle: 0.5, spin: 2)
        for _ in 0..<12 { a.step(input: .neutral); b.step(input: .neutral) }
        b.rebaseForTesting(by: .init(x: 256, y: -256))
        for _ in 0..<60 { a.step(input: .neutral); b.step(input: .neutral) }
        XCTAssertEqual(a.state.bike.position.x, b.state.bike.position.x, accuracy: 0.003)
        XCTAssertEqual(a.state.bike.position.y, b.state.bike.position.y, accuracy: 0.003)
        XCTAssertEqual(a.state.bike.velocity.y, b.state.bike.velocity.y, accuracy: 0.01)
        XCTAssertEqual(a.state.bike.angle, b.state.bike.angle, accuracy: 0.003)
    }

    func testGroundedRebaseDoesNotCreateJumpOrLoseJointConstraints() {
        let sim = flatFixture(speed: 12, height: flatConfiguration.restingRideHeight, descent: 0)
        let reference = flatFixture(speed: 12, height: flatConfiguration.restingRideHeight, descent: 0)
        for _ in 0..<120 { sim.step(input: .neutral); reference.step(input: .neutral) }
        sim.rebaseForTesting(by: .init(x: 256, y: -256))
        var peakBounce = 0.0
        for _ in 0..<120 {
            sim.step(input: .neutral); reference.step(input: .neutral); peakBounce = max(peakBounce, sim.state.bike.velocity.y)
        }
        XCTAssertLessThan(peakBounce, 0.1)
        XCTAssertTrue(sim.state.bike.rear.contact && sim.state.bike.front.contact)
        XCTAssertEqual(sim.state.bike.position.y, reference.state.bike.position.y, accuracy: 0.003)
        XCTAssertLessThan(abs(sim.state.bike.angle), 0.005)
    }

    func testTerrainChunkSeamsAndNaturalRebaseRemainSmooth() {
        for x in [50.0, 114, 242, 498] {
            let sim = flatFixture(speed: 20, height: flatConfiguration.restingRideHeight, descent: 0, x: x)
            var peakBounce = 0.0, peakSpin = 0.0
            for tick in 0..<180 {
                sim.step(input: .neutral)
                if tick < 60 { continue } // Exclude the fixture's initial suspension relaxation before the seam.
                peakBounce = max(peakBounce, abs(sim.state.bike.velocity.y))
                peakSpin = max(peakSpin, abs(sim.state.bike.angularVelocity))
            }
            XCTAssertLessThan(peakBounce, 0.04, "x=\(x)"); XCTAssertLessThan(peakSpin, 0.04, "x=\(x)")
            XCTAssertGreaterThan(sim.state.bike.velocity.x, 19)
            XCTAssertEqual(sim.state.status, .active)
        }
    }
}
