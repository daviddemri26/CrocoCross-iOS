import CrocoCrossCore
import SpriteKit
import UIKit

@MainActor
final class GameScene: SKScene {
    static let homePanelWidth: CGFloat = 440
    static let minimumWideHomeWidth: CGFloat = 700

    var onFrame: ((Double) -> Void)?
    var isPreview = false

    private let backgroundTiles = (0..<3).map { _ in SKSpriteNode() }
    private let lampTiles = (0..<3).map { _ in SKNode() }
    private let atmosphere = AmbientNode()
    private let wayside = WaysideNode()
    private let track = TrackNode()
    private let bike = BikeNode()
    private let effects = RideEffectsNode()
    private let finish = SKNode()
    private let distanceLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    private let dust = SKEmitterNode()
    private var lastTime: TimeInterval?
    private var frameDuration = 1.0 / 60
    private var scenicTime: Double = 0
    private var cameraX: Double = 0
    private var cameraY: Double = 0
    private var lastSeed: UInt32?
    private var lastTick: Int = 0
    private var lastPreview = false
    private var renderScale: CGFloat = 0
    private var lastViewportSize: CGSize = .zero
    private var bikeHiddenByCrash = false
    private var worldID = ""
    private var scenerySeed = UInt64.random(in: UInt64.min...UInt64.max)
    private var textureSize = CGSize(width: 16, height: 9)

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = GameCatalog.worlds[0].sky
        isUserInteractionEnabled = false
        for (index, tile) in backgroundTiles.enumerated() {
            tile.zPosition = -20
            addChild(tile)
            lampTiles[index].zPosition = -19
            addChild(lampTiles[index])
        }
        atmosphere.zPosition = -10
        addChild(atmosphere)
        wayside.zPosition = -1
        addChild(wayside)
        track.zPosition = 0
        addChild(track)
        bike.zPosition = 5
        addChild(bike)
        effects.zPosition = 8
        addChild(effects)
        dust.zPosition = 4
        configureDust()
        addChild(dust)
        finish.zPosition = 3
        makeFinish()
        addChild(finish)
        distanceLabel.zPosition = 1
        distanceLabel.fontSize = 10
        distanceLabel.fontColor = UIColor.white.withAlphaComponent(0.55)
        addChild(distanceLabel)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    #if DEBUG
    override func didMove(to view: SKView) {
        if let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("-terrain-review") }) {
            let world = argument.split(separator: "=", maxSplits: 1).dropFirst().first.map(String.init)
            DispatchQueue.main.async { TerrainReviewExporter.export(in: view, worldID: world) }
            return
        }
        guard let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("-scenery-review") }) else { return }
        let world = argument.split(separator: "=", maxSplits: 1).dropFirst().first.map(String.init)
        DispatchQueue.main.async { SceneryReviewExporter.export(in: view, worldID: world) }
    }
    #endif

    override func update(_ currentTime: TimeInterval) {
        let elapsed = lastTime.map { max(0, currentTime - $0) } ?? 1.0 / 60
        lastTime = currentTime
        frameDuration = min(elapsed, 0.05)
        scenicTime += frameDuration
        onFrame?(elapsed)
    }

    func display(state: SimulationState, terrain: (Double) -> Double,
                 characterID: String, worldID: String, reducedMotion: Bool) {
        guard size.width > 0, size.height > 0 else { return }
        let startsNewRun = lastSeed != nil && (lastSeed != state.seed || state.tick < lastTick)
        if startsNewRun || lastPreview != isPreview {
            scenerySeed = UInt64.random(in: UInt64.min...UInt64.max)
            scenicTime = 0
        }
        if isPreview {
            restoreBikeAfterRespawn()
        } else if state.status == .recovering || state.status == .crashed {
            // Keep the complete rig hidden throughout recovery and terminal crash presentation.
            hideBikeAfterCrash()
        } else if startsNewRun {
            restoreBikeAfterRespawn()
        }
        let world = GameCatalog.world(worldID)
        if self.worldID != world.id { configureWorld(world) }
        let landscape = size.width > size.height
        let widePreview = size.width >= Self.minimumWideHomeWidth
        // Scale from usable dimensions, never from a particular device model.
        // Faster travel needs more reaction distance, especially in portrait.
        let speedFraction = min(1, max(0, CGFloat(abs(state.bike.velocity.x)) / 22))
        let visibleMetres: CGFloat = landscape ? 19 + speedFraction * 9 : 10 + speedFraction * 5
        let playScale = min(64, max(23, min(size.width / visibleMetres, size.height / 13)))
        // Match the SwiftUI home's 440-point menu column, including narrow regular windows.
        let previewContentWidth = max(1, size.width - Self.homePanelWidth)
        let previewWheelbase = widePreview ? min(240, previewContentWidth * 0.46) : min(185, size.width * 0.43)
        let desiredScale = isPreview ? previewWheelbase / CGFloat(PhysicsConfiguration().wheelbase) : playScale
        let reset = lastSeed != state.seed || state.tick < lastTick || lastPreview != isPreview || lastViewportSize != size
        // The core stops velocity at impact. Holding the last camera also prevents
        // that speed change from zooming or sliding the explosion under the HUD.
        let holdCrashCamera = bikeHiddenByCrash && !reset && renderScale > 0
        if reset || renderScale == 0 { renderScale = desiredScale }
        else if !holdCrashCamera { renderScale += (desiredScale - renderScale) * min(1, frameDuration * 2.8) }
        let ppm = renderScale
        let playAnchor = (landscape ? CGFloat(0.30) : 0.28) - speedFraction * (landscape ? 0.06 : 0.04)
        let previewCentre = widePreview ? Self.homePanelWidth + previewContentWidth / 2 : size.width / 2
        let horizontalFraction: CGFloat = isPreview ? previewCentre / size.width : playAnchor
        let desiredX = state.bike.position.x - Double(size.width * horizontalFraction / ppm)
        let ahead = terrain(state.bike.position.x + (landscape ? 5 : 3))
        let near = terrain(state.bike.position.x)
        let followedHeight = max(near * 0.6 + ahead * 0.4, state.bike.position.y - (landscape ? 2.4 : 3.2))
        let verticalFraction: CGFloat = isPreview ? (widePreview ? 0.38 : 0.55) : (landscape ? 0.40 : 0.39)
        let desiredY = (isPreview ? near : followedHeight) - Double(size.height * verticalFraction / ppm)
        if reset {
            cameraX = desiredX
            cameraY = desiredY
            dust.resetSimulation()
        } else if !holdCrashCamera {
            cameraX += (desiredX - cameraX) * min(1, frameDuration * 11)
            cameraY += (desiredY - cameraY) * min(1, frameDuration * 4)
        }
        lastSeed = state.seed
        lastTick = state.tick
        lastPreview = isPreview
        lastViewportSize = size
        let left = cameraX, bottom = cameraY
        func ground(_ x: Double) -> CGFloat { CGFloat(terrain(x) - bottom) * ppm }
        func project(_ p: Vector2) -> CGPoint { CGPoint(x: CGFloat(p.x - left) * ppm, y: CGFloat(p.y - bottom) * ppm) }

        displayBackground(world: world, ppm: ppm, reducedMotion: reducedMotion)
        atmosphere.display(world: world, size: size, cameraX: cameraX, seconds: scenicTime,
                           reducedMotion: reducedMotion, seed: scenerySeed)
        wayside.display(world: world, size: size, left: cameraX, ppm: ppm, seed: scenerySeed, ground: ground)
        track.display(world: world, size: size, left: cameraX, ppm: ppm, seconds: scenicTime,
                      reducedMotion: reducedMotion, seed: scenerySeed, ground: ground)
        if !bikeHiddenByCrash {
            bike.display(state, rider: GameCatalog.rider(characterID), pointsPerMetre: ppm, project: project, terrain: terrain, reducedMotion: reducedMotion, seconds: scenicTime, isPreview: isPreview)
        }
        effects.display(time: scenicTime, ppm: ppm, world: world, reducedMotion: reducedMotion, project: project)
        let rear = project(state.bike.rear.position)
        dust.position = CGPoint(x: rear.x, y: rear.y - ppm * 0.28)
        dust.particleBirthRate = !bikeHiddenByCrash && !reducedMotion && state.status == .active && state.bike.rear.contact ? CGFloat(min(30, abs(state.bike.velocity.x) * 2)) : 0
        dust.particleColor = world.edge
        dust.particleSpeed = ppm * (0.45 + CGFloat(abs(state.bike.velocity.x)) * 0.22)
        dust.particleScale = ppm / 320

        let courseOrigin = PhysicsConfiguration.courseStartX
        let finishX = courseOrigin + PhysicsConfiguration.weeklyDistance
        finish.isHidden = isPreview || state.mode != .weekly || abs(finishX - cameraX) > Double(size.width / ppm) + 4
        finish.position = CGPoint(x: CGFloat(finishX - left) * ppm, y: ground(finishX))
        finish.setScale(ppm / 64)
        let markerDistance = max(0, ceil((left - courseOrigin + 2) / 100) * 100)
        let markerX = courseOrigin + markerDistance
        distanceLabel.text = "\(Int(markerDistance)) M"
        distanceLabel.isHidden = isPreview
        distanceLabel.position = CGPoint(x: CGFloat(markerX - left) * ppm, y: ground(markerX) - ppm * 0.65)
    }

    /// Intensity is normalized to 0...1. The session owns the matching audio event.
    func playCrash(at position: Vector2, impact: Double = 1) {
        hideBikeAfterCrash()
        effects.play(at: position, intensity: impact, landing: false, time: scenicTime)
    }

    func playLanding(at position: Vector2, intensity: Double) {
        guard !bikeHiddenByCrash else { return }
        // Core impact is the approach speed in metres per second.
        let strength = min(1, max(0, intensity / 12))
        bike.reactToLanding(intensity: strength)
        guard strength > 0.12 else { return }
        effects.play(at: position, intensity: strength, landing: true, time: scenicTime)
    }

    /// Explicit respawns and presentation resets restore the complete rig.
    /// The next active frame places the complete rig at its new physical wheel centres.
    func restoreBikeAfterRespawn() {
        guard bikeHiddenByCrash else { return }
        bikeHiddenByCrash = false
        bike.isHidden = false
        bike.resetAnimation()
    }

    /// New runs and the home preview reset presentation state.
    /// If the simulation is still recovering, `display` keeps the rig hidden before rendering.
    func clearTransientEffects() {
        effects.clear()
        restoreBikeAfterRespawn()
        bike.resetAnimation()
        dust.particleBirthRate = 0
        dust.resetSimulation()
    }

    private func hideBikeAfterCrash() {
        guard !bikeHiddenByCrash else { return }
        bikeHiddenByCrash = true
        // The common parent contains chassis, both complete wheels, hardware and shadow.
        bike.isHidden = true
        dust.particleBirthRate = 0
        dust.resetSimulation()
    }

    private func configureWorld(_ world: World) {
        worldID = world.id
        backgroundColor = world.sky
        let texture = GameAssets.texture(named: world.assetName)
        textureSize = texture?.size() ?? CGSize(width: 16, height: 9)
        backgroundTiles.forEach { $0.texture = texture }
        lampTiles.forEach { tile in
            tile.removeAllChildren()
            guard world.id == "mine" else { return }
            for _ in 0..<4 {
                let glow = SKShapeNode(circleOfRadius: 8)
                glow.fillColor = UIColor.hex(0xFFD078, alpha: 0.24)
                glow.strokeColor = .clear
                glow.glowWidth = 24
                glow.blendMode = .add
                tile.addChild(glow)
            }
        }
    }

    private func displayBackground(world: World, ppm: CGFloat, reducedMotion: Bool) {
        let landscape = size.width > size.height
        // The floating cloud trail exposes the full viewport below it. Overscan
        // by 32 points on both edges so vertical parallax cannot reveal a seam.
        let floatingTrail = world.id == "clouds"
        let height = floatingTrail ? size.height + 64 : size.height * (landscape ? 1.03 : 0.82)
        let width = height * textureSize.width / max(1, textureSize.height)
        let offset = CGFloat(cameraX) * ppm * 0.14
        let tileIndex = Int(floor(offset / width))
        let fractional = offset - CGFloat(tileIndex) * width
        let verticalParallax = min(30, max(-30, CGFloat(cameraY) * -1.2))
        let centreY = (floatingTrail ? size.height / 2 : size.height - height / 2) + verticalParallax
        let lamps: [(CGFloat, CGFloat)] = [(0.083, 0.802), (0.269, 0.711), (0.675, 0.741), (0.900, 0.718)]
        for index in 0..<3 {
            let tile = backgroundTiles[index]
            tile.size = CGSize(width: width + 1, height: height)
            tile.position = CGPoint(x: CGFloat(index - 1) * width - fractional + width / 2, y: centreY)
            let mirrored = (tileIndex + index - 1).isMultiple(of: 2)
            tile.xScale = mirrored ? 1 : -1
            lampTiles[index].position = tile.position
            for (lampIndex, lamp) in lampTiles[index].children.enumerated() {
                let point = lamps[lampIndex]
                lamp.position = CGPoint(x: (point.0 - 0.5) * width * (mirrored ? 1 : -1), y: (point.1 - 0.5) * height)
                let phase = scenicTime * 2.1 + Double(lampIndex) * 2.39
                // Slow, local variation respects Reduce Motion and avoids flashing effects.
                lamp.alpha = reducedMotion ? 0.8 : 0.65 + 0.2 * sin(phase) + 0.06 * sin(phase * 3.7)
            }
        }
    }

    private func configureDust() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24), format: format).image { context in
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 2, y: 2, width: 20, height: 20))
        }
        dust.particleTexture = SKTexture(image: image)
        dust.particleBirthRate = 0
        dust.particleLifetime = 0.45
        dust.particleLifetimeRange = 0.18
        dust.emissionAngle = .pi * 0.75
        dust.emissionAngleRange = .pi * 0.5
        dust.particleAlpha = 0.28
        dust.particleAlphaSpeed = -0.6
        dust.particleScaleSpeed = 0.25
        dust.particleColorBlendFactor = 1
        dust.targetNode = self
        dust.numParticlesToEmit = 0
    }

    private func makeFinish() {
        let pole = SKShapeNode(rectOf: CGSize(width: 0.055 * 64, height: 2.4 * 64))
        pole.fillColor = .hex(0xF5F0DA)
        pole.strokeColor = .clear
        pole.position.y = 1.2 * 64
        finish.addChild(pole)
        for row in 0..<3 {
            for column in 0..<5 {
                let square = SKShapeNode(rectOf: CGSize(width: 0.16 * 64, height: 0.16 * 64))
                square.strokeColor = .clear
                square.fillColor = (row + column).isMultiple(of: 2) ? .white : .hex(0x152C27)
                square.position = CGPoint(x: (0.11 + CGFloat(column) * 0.16) * 64, y: (2.25 - CGFloat(row) * 0.16) * 64)
                finish.addChild(square)
            }
        }
    }
}
