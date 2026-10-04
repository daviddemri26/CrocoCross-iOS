import Foundation
import XCTest
@testable import CrocoCrossCore

final class JungleCliffCollisionTests: XCTestCase {
    private var configuration: PhysicsConfiguration {
        var value = PhysicsConfiguration(); value.terrainStyle = .junglePlatforms; return value
    }

    func testCliffFacesStopBelowLedgeEntriesWithoutGrounding() {
        for seed: UInt32 in [0, 42] {
            let terrain = TerrainGenerator(seed: seed, style: .junglePlatforms)
            let spans = terrain.solidSpans(from: PhysicsConfiguration.courseStartX, to: 500)
            for (edge, direction) in [(spans[1].lowerBound, 1.0), (spans[0].upperBound, -1.0)] {
                var bike = BikeState()
                bike.position = .init(x: edge - 3 * direction, y: terrain.height(at: edge) - 1.5)
                bike.velocity.x = 12 * direction
                let world = Box2DBikeWorld(configuration: configuration, terrain: terrain, bike: bike)
                var wheelImpact = false, bodyImpact = false
                for _ in 0..<120 {
                    world.advance(input: .neutral)
                    XCTAssertLessThan((world.bike.position.x - edge) * direction, 0.05,
                                      "A missed jump cannot enter the rock from either cliff face")
                    XCTAssertFalse(world.bike.grounded, "A vertical wall is not a landed wheel")
                    wheelImpact = wheelImpact || world.diagnostics.frontNormalImpulse > 0 || world.diagnostics.rearNormalImpulse > 0
                    bodyImpact = bodyImpact || world.diagnostics.cliffBodyContact
                }
                XCTAssertTrue(wheelImpact)
                XCTAssertTrue(bodyImpact)
            }
        }
    }

    func testWheelGrazingTheReceivingLipCanLandWithoutBodyCliffContact() {
        let terrain = TerrainGenerator(seed: 42, style: .junglePlatforms)
        let bank = terrain.solidSpans(from: PhysicsConfiguration.courseStartX, to: 500)[1].lowerBound
        for margin in [-0.05, 0.15] {
            var bike = BikeState()
            bike.position = .init(x: bank - 2, y: terrain.height(at: bank) + configuration.restingRideHeight + margin)
            bike.velocity.x = 12
            let world = Box2DBikeWorld(configuration: configuration, terrain: terrain, bike: bike)
            var landedOnTop = false
            for _ in 0..<90 {
                world.advance(input: .neutral)
                XCTAssertFalse(world.diagnostics.cliffBodyContact, "A wheel catching the lip is not a rider/body wall impact")
                if world.bike.front.contact && world.bike.front.position.x >= bank {
                    landedOnTop = true
                    XCTAssertGreaterThan(world.bike.front.position.y - terrain.height(at: world.bike.front.position.x), 0.28)
                }
            }
            XCTAssertTrue(landedOnTop)
            XCTAssertGreaterThan(world.bike.position.x, bank + 3)
        }
    }

    func testBodyCliffImpactLosesOneLifeWithoutLandingOrFlipCredit() {
        let terrain = TerrainGenerator(seed: 42, style: .junglePlatforms)
        let bank = terrain.solidSpans(from: PhysicsConfiguration.courseStartX, to: 500)[1].lowerBound
        var state = SimulationState(mode: .endless, seed: 42)
        state.bike.position = .init(x: bank - 3, y: terrain.height(at: bank) - 1.5)
        state.bike.velocity.x = 12
        let simulation = GameSimulation(state: state, configuration: configuration)
        var crashes = 0
        for _ in 0..<120 {
            let events = simulation.step(input: .neutral)
            crashes += events.filter { $0 == .crashed }.count
            XCTAssertFalse(events.contains { if case .landed = $0 { return true }; return false })
            XCTAssertEqual(simulation.state.flips, 0)
            if simulation.state.status == .recovering { break }
        }
        XCTAssertEqual(crashes, 1)
        XCTAssertEqual(simulation.state.status, .recovering)
        XCTAssertEqual(simulation.state.lives, 2)
        XCTAssertGreaterThan(simulation.state.bike.position.y, terrain.height(at: bank) - 8,
                             "The wall impact must be detected before the deep-void cutoff")
        for _ in 0..<216 {
            XCTAssertFalse(simulation.step(input: .neutral).contains(.crashed))
        }
        XCTAssertEqual(simulation.state.status, .active)
        XCTAssertEqual(simulation.state.lives, 2)
    }

    func testSolidChunkBoundaryDoesNotBecomeACliff() {
        let terrain = TerrainGenerator(seed: 42, style: .junglePlatforms)
        let seam = stride(from: 64.0, through: 1_024, by: 64).first {
            terrain.solidSpans(from: $0 - 8, to: $0 + 8) == [.init(lowerBound: $0 - 8, upperBound: $0 + 8)]
                && abs(terrain.slope(at: $0)) < 0.2
        }!
        var bike = BikeState()
        let x = seam - 3, angle = atan(terrain.slope(at: x))
        bike.position = .init(x: x, y: terrain.height(at: x) + configuration.restingRideHeight / cos(angle))
        bike.angle = angle
        bike.velocity = .init(x: 10, y: 10 * terrain.slope(at: x))
        let world = Box2DBikeWorld(configuration: configuration, terrain: terrain, bike: bike)
        for _ in 0..<90 {
            world.advance(input: .neutral)
            XCTAssertFalse(world.diagnostics.cliffBodyContact)
        }
        XCTAssertGreaterThan(world.bike.position.x, seam + 2, "Neighbouring solid chunks remain one continuous surface")
    }
}
