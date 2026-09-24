#if DEBUG
extension GameSimulation {
    /// Real airborne frontflip setup for offline UI tests. The normal solver,
    /// safe-landing gate and directional stunt counter still earn the unlock.
    public static func frontflipFixtureForTesting(mode: RunMode) -> GameSimulation {
        var configuration = PhysicsConfiguration()
        configuration.terrainStyle = .flat
        var state = SimulationState(mode: mode, seed: 1)
        state.bike.position = .init(x: 3, y: 16)
        state.bike.velocity.x = 8
        state.bike.angularVelocity = -6
        return GameSimulation(state: state, configuration: configuration)
    }
}
#endif
