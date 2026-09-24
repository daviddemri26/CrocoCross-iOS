import Foundation
import XCTest
@testable import CrocoCrossCore

#if DEBUG
final class FrontflipFixtureTests: XCTestCase {
    func testFrontflipUIFixtureEmitsOneRealSafeReceptionInBothModes() {
        for mode: RunMode in [.weekly, .endless] {
            let simulation = GameSimulation.frontflipFixtureForTesting(mode: mode)
            var unwrapped = 0.0, previous = simulation.state.bike.angle
            var creditedBackflips = 0, creditedFrontflips = 0, awardEvents = 0
            XCTAssertEqual(simulation.state.mode, mode)
            XCTAssertEqual(simulation.state.flips, 0)
            for _ in 0..<120 * 5 {
                let bike = simulation.state.bike
                unwrapped += atan2(sin(bike.angle - previous), cos(bike.angle - previous))
                previous = bike.angle
                let error = -Double.pi * 2 - unwrapped
                let stopping = bike.angularVelocity * abs(bike.angularVelocity) / (2 * 4.1)
                let lean = bike.grounded ? 0 : error < -1.2 ? (error < stopping - 0.06 ? -1.0 : 1.0)
                    : min(1, max(-1, error * 6 - bike.angularVelocity * 2.2))
                for event in simulation.step(input: .init(lean: lean)) {
                    if case let .flip(count) = event {
                        XCTAssertTrue(simulation.state.bike.grounded)
                        XCTAssertTrue(simulation.state.rider.isAttached)
                        XCTAssertEqual(count, 1)
                        creditedBackflips += simulation.landedBackflips
                        creditedFrontflips += simulation.landedFrontflips
                        awardEvents += 1
                    }
                    XCTAssertNotEqual(event, .crashed)
                }
            }
            assertFinite(simulation)
            XCTAssertEqual(simulation.state.status, .active)
            XCTAssertEqual(simulation.state.flips, 1)
            XCTAssertEqual(awardEvents, 1)
            XCTAssertEqual(creditedBackflips, 0)
            XCTAssertEqual(creditedFrontflips, 1)
        }
    }
}
#endif
