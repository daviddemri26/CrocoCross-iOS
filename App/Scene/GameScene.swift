import CrocoCrossCore
import SpriteKit
import UIKit

@MainActor
final class GameScene: SKScene {
    static let homePanelWidth: CGFloat = 440
    static let minimumWideHomeWidth: CGFloat = 700

    var onFrame: ((Double) -> Void)?
    var isPreview = false
    var isCrashPaused = false
    var finishCelebrationElapsed: Double?
    private var finishStartScale: CGFloat = 0
    private var crashElapsed: Double = 0
    private var crashStartScale: CGFloat = 0

    private let backgroundTiles = (0..<3).map { _ in SKSpriteNode() }
    private lazy var japanPanoramaShader: SKShader = {
        let shader = SKShader(source: """
            void main() {
                float fade = smoothstep(0.0, u_edgeWidth, v_tex_coord.x);
                gl_FragColor = texture2D(u_texture, v_tex_coord) * fade;
            }
            """)
        shader.uniforms = [SKUniform(name: "u_edgeWidth", float: Float(BackgroundPanorama.japanEdgeBlend))]
        return shader
    }()
    private var backgroundOriginX: Double?
    private lazy var junglePanoramaShader: SKShader = {
        let shader = SKShader(source: """
            void main() {
                float localX = (v_tex_coord.x - u_cropX) / u_cropWidth;
                float fade = smoothstep(0.0, u_edgeWidth, localX);
                gl_FragColor = texture2D(u_texture, v_tex_coord) * fade;
            }
            """)
        // SpriteKit supplies parent UVs for SKTexture(rect:in:), so fading
        // must use coordinates local to the cropped panorama.
        shader.uniforms = [
            SKUniform(name: "u_edgeWidth", float: Float(BackgroundPanorama.jungleEdgeBlend)),
            SKUniform(name: "u_cropX", float: Float(BackgroundPanorama.jungleCropX)),
            SKUniform(name: "u_cropWidth", float: Float(BackgroundPanorama.jungleCropWidth))
        ]
        return shader
    }()
    private var jungleBackgroundMotion = BackgroundPanorama.WorldMotion()
    private let atmosphere = AmbientNode()
    private let wayside = WaysideNode()
    private let track = TrackNode()
    private let foreground = ForegroundSceneryNode()
    private let bike = BikeNode()
    private let effects = RideEffectsNode()
    private let finish = FinishLineNode()
    private let celebration = FinishCelebrationNode()
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
    private var presentingCrash = false
    private var cameraNeedsRespawnReset = false
    private var jungleCamera = JungleCamera()
    private var worldID = ""
    private var scenerySeed = GameScene.makeScenerySeed()
    private var textureSize = CGSize(width: 16, height: 9)

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = GameCatalog.worlds[0].sky
        isUserInteractionEnabled = false
        for tile in backgroundTiles {
            tile.zPosition = -20
            addChild(tile)
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
        // Foreground art is independent of the terrain mask and in front of
        // the complete rider rig, whose children extend above the bike's z = 5.
        foreground.zPosition = 10
        addChild(foreground)
        dust.zPosition = 4
        configureDust()
        addChild(dust)
        finish.zPosition = 3
        addChild(finish)
        celebration.zPosition = 14
        addChild(celebration)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func update(_ currentTime: TimeInterval) {
        let elapsed = lastTime.map { max(0, currentTime - $0) } ?? 1.0 / 60
        lastTime = currentTime
        frameDuration = min(elapsed, 0.05)
        scenicTime += frameDuration
        onFrame?(elapsed)
    }

    func display(state: SimulationState, terrain: (Double) -> Double,
                 characterID: String, worldID: String, reducedMotion: Bool, riderMotionSeconds: Double? = nil,
                 terrainSolidSpans: ((Double, Double) -> [TerrainSpan])? = nil,
                 terrainIsSolid: ((Double) -> Bool)? = nil) {
        guard size.width > 0, size.height > 0 else { return }
        let startsNewRun = lastSeed != nil && (lastSeed != state.seed || state.tick < lastTick)
        if startsNewRun || lastPreview != isPreview {
            scenerySeed = Self.makeScenerySeed()
            scenicTime = 0
        }
        if isPreview {
            restoreBikeAfterRespawn()
        } else if startsNewRun {
            restoreBikeAfterRespawn()
        }
        let finalExplosion = !isPreview && state.mode == .endless && state.status == .crashed
        presentingCrash = !isPreview && (state.status == .recovering || state.status == .crashed)
        let victoryFall = !isPreview && state.status == .finished && !state.rider.isAttached
        let followingRider = presentingCrash || victoryFall
        bike.isHidden = finalExplosion
        effects.zPosition = finalExplosion ? 12 : 8
        let world = GameCatalog.world(worldID)
        if self.worldID != world.id { configureWorld(world) }
        let landscape = size.width > size.height
        let widePreview = size.width >= Self.minimumWideHomeWidth
        // Scale from usable dimensions, never from a particular device model.
        // Faster travel needs more reaction distance, especially in portrait.
        let speedFraction = min(1, max(0, CGFloat(abs(state.bike.velocity.x)) / 22))
        // Jungle stays close to the rider even when the receiving bank is offscreen.
        let platformCourse = world.id == "jungle"
        let junglePlaying = platformCourse && !isPreview && !followingRider && state.status == .active
        let playAnchor = (landscape ? CGFloat(0.30) : 0.28) - speedFraction * (landscape ? 0.06 : 0.04)
        let visibleMetres: CGFloat = landscape ? 19 + speedFraction * 9 : 10 + speedFraction * 5
        let playScale: CGFloat = platformCourse
            ? JungleCamera.ridingScale(width: size.width, height: size.height, speed: state.bike.velocity.x)
            : min(64, max(23, min(size.width / visibleMetres, size.height / 13))) * 1.18
        // Match the SwiftUI home's 440-point menu column, including narrow regular windows.
        let previewContentWidth = max(1, size.width - Self.homePanelWidth)
        let previewVerticalFraction: CGFloat = widePreview ? 0.38 : 0.55
        // Milo sits upright: leave his cap and face below the portrait home logo.
        // Keep the road anchor and the separate wide-layout preview unchanged.
        let portraitRiderScale: CGFloat = characterID == "monkey" ? 0.80 : 1
        let previewWidthWheelbase = widePreview ? min(240, previewContentWidth * 0.46)
            : min(185, size.width * 0.43) * portraitRiderScale
        // The tallest silhouette fits within 1.2 wheelbases above the road.
        // Preserve the current size whenever it also leaves 24 points of headroom.
        let previewHeightWheelbase = max(1, (size.height * (1 - previewVerticalFraction) - 24) / 1.2)
        let previewWheelbase = min(previewWidthWheelbase, previewHeightWheelbase)
        var desiredScale = isPreview ? previewWheelbase / CGFloat(PhysicsConfiguration().wheelbase) : playScale
        let presentationReset = lastSeed != state.seed || state.tick < lastTick || lastPreview != isPreview || lastViewportSize != size
        let reset = presentationReset || cameraNeedsRespawnReset
        // Follow the rider as the bike separates. Zoom is based on crash time,
        // not the bike slowing down, and remains gentle and bounded.
        if platformCourse && finalExplosion && crashStartScale > 0 {
            // Keep the last crossing's view behind the terminal explosion too.
            desiredScale = crashStartScale
        } else if presentingCrash && !finalExplosion {
            if !isCrashPaused { crashElapsed += frameDuration }
            let progress = reducedMotion ? 0 : min(1, crashElapsed / 3.2)
            let smooth = progress * progress * (3 - 2 * progress)
            desiredScale = max(platformCourse ? 0.1 : 23, crashStartScale) * (1 + CGFloat(smooth) * 0.38)
        } else if state.status == .finished && finishStartScale > 0 {
            // Keep the winning jump's framing as the bike coasts and slows down.
            desiredScale = finishStartScale
        }
        if reset || renderScale == 0 { renderScale = desiredScale }
        else { renderScale += (desiredScale - renderScale) * min(1, frameDuration * 2.8) }
        var ppm = renderScale
        let previewCentre = widePreview ? Self.homePanelWidth + previewContentWidth / 2 : size.width / 2
        let horizontalFraction: CGFloat = isPreview ? previewCentre / size.width : followingRider ? 0.5 : playAnchor
        let followedX = followingRider && !finalExplosion ? state.rider.torso.position.x : state.bike.position.x
        let desiredX = followedX - Double(size.width * horizontalFraction / ppm)
        let ahead = terrain(state.bike.position.x + (landscape ? 5 : 3))
        let near = terrain(state.bike.position.x)
        let highestBody = followingRider ? max(state.bike.position.y, state.rider.torso.position.y) : state.bike.position.y
        let followedHeight = max(near * 0.6 + ahead * 0.4, highestBody - (landscape ? 2.4 : 3.2))
        let verticalFraction: CGFloat = isPreview ? previewVerticalFraction : (landscape ? 0.40 : 0.39)
        var desiredY = followingRider && !finalExplosion
            ? state.rider.torso.position.y - Double(size.height * 0.50 / ppm)
            : (isPreview ? near : followedHeight) - Double(size.height * verticalFraction / ppm)
        if !isPreview && world.id == "jungle" && terrainSolidSpans != nil {
            // The continuous height profile is a camera guide, even over a void.
            // Show a short fall without following a ragdoll down an endless chasm.
            let courseCameraY = near * 0.6 + ahead * 0.4 - Double(size.height * verticalFraction / ppm)
            desiredY = max(desiredY, courseCameraY - (landscape ? 2.0 : 2.6))
        }
        if reset {
            cameraX = desiredX
            cameraY = desiredY
            // A checkpoint respawn resets only the following camera, retaining
            // the background's existing course origin.
            if presentationReset { backgroundOriginX = cameraX }
            cameraNeedsRespawnReset = false
            dust.resetSimulation()
        } else {
            cameraX += (desiredX - cameraX) * min(1, frameDuration * 11)
            cameraY += (desiredY - cameraY) * min(1, frameDuration * 4)
        }
        if junglePlaying {
            let view = jungleCamera.update(bike: state.bike, width: size.width, height: size.height,
                anchor: playAnchor, deltaTime: frameDuration, reset: reset)
            renderScale = view.scale
            ppm = renderScale
            cameraX = view.x
            cameraY = view.y
        } else {
            jungleCamera = .init()
        }
        lastSeed = state.seed
        lastTick = state.tick
        lastPreview = isPreview
        lastViewportSize = size
        let left = cameraX
        var bottom = cameraY
        func ground(_ x: Double) -> CGFloat { CGFloat(terrain(x) - bottom) * ppm }
        func project(_ p: Vector2) -> CGPoint { CGPoint(x: CGFloat(p.x - left) * ppm, y: CGFloat(p.y - bottom) * ppm) }
        func supportsFootprint(_ lower: Double, _ upper: Double) -> Bool {
            if let terrainSolidSpans {
                // A complete footprint must belong to one connected platform.
                // Checking just a sprite's centre or corners can miss a narrow gap.
                return terrainSolidSpans(lower, upper).contains {
                    $0.lowerBound <= lower && $0.upperBound >= upper
                }
            }
            guard let terrainIsSolid else { return true }
            let samples = max(1, Int(ceil((upper - lower) / 0.1)))
            return (0...samples).allSatisfy {
                terrainIsSolid(lower + (upper - lower) * Double($0) / Double(samples))
            }
        }

        // Pose once, then use the complete rig's bounds to preserve headroom
        // during large jumps. The common translation keeps every wheel attached.
        bike.position = .zero
        bike.display(state, rider: GameCatalog.rider(characterID), pointsPerMetre: ppm, project: project, terrain: terrain, reducedMotion: reducedMotion, seconds: scenicTime, isPreview: isPreview, motionSeconds: riderMotionSeconds)
        if !isPreview && !followingRider {
            let ceiling = size.height - min(size.height * 0.20, landscape ? 80 : 120)
            let excess = max(0, bike.visibleFrame.maxY - ceiling)
            if excess > 0 {
                cameraY += Double(excess / ppm)
                bottom = cameraY
                bike.position.y = -excess
            }
        }

        // Terrain, scenery and effects share the final projection for this frame.
        if world.id == "jungle" {
            jungleBackgroundMotion.update(x: state.bike.position.x, y: state.bike.position.y,
                                          seed: state.seed, tick: state.tick, isPreview: isPreview)
        }
        displayBackground(reducedMotion: reducedMotion)
        // A large home hero occupies the sky band. Keep its silhouette clear;
        // the background painting still supplies the preview's sky.
        atmosphere.isHidden = isPreview
        if !isPreview {
            atmosphere.display(world: world, size: size, cameraX: cameraX, seconds: scenicTime,
                               reducedMotion: reducedMotion, seed: scenerySeed)
        }
        wayside.display(world: world, size: size, left: cameraX, ppm: ppm, seed: scenerySeed, ground: ground,
                        supportsFootprint: supportsFootprint)
        let visibleSpans = terrainSolidSpans?(left - 1, left + Double(size.width / ppm) + 1)
        track.display(world: world, size: size, left: cameraX, ppm: ppm, seconds: scenicTime,
                      reducedMotion: reducedMotion, seed: scenerySeed, ground: ground, solidSpans: visibleSpans)
        foreground.isHidden = isPreview
        if !isPreview {
            foreground.display(world: world, size: size, left: cameraX, ppm: ppm, seconds: scenicTime,
                               reducedMotion: reducedMotion, seed: scenerySeed, ground: ground,
                               supportsFootprint: supportsFootprint)
        }
        effects.display(time: scenicTime, ppm: ppm, world: world, reducedMotion: reducedMotion, project: project)
        let rear = project(state.bike.rear.position)
        dust.position = CGPoint(x: rear.x, y: rear.y - ppm * 0.28)
        let rearHasGround = terrainIsSolid?(state.bike.rear.position.x) ?? true
        dust.particleBirthRate = !reducedMotion && state.status == .active && state.bike.rear.contact && rearHasGround ? CGFloat(min(30, abs(state.bike.velocity.x) * 2)) : 0
        dust.particleColor = world.edge
        dust.particleSpeed = ppm * (0.45 + CGFloat(abs(state.bike.velocity.x)) * 0.22)
        dust.particleScale = ppm / 320

        let courseOrigin = PhysicsConfiguration.courseStartX
        let finishX = courseOrigin + PhysicsConfiguration.weeklyDistance
        finish.isHidden = isPreview || state.mode != .weekly || abs(finishX - cameraX) > Double(size.width / ppm) + 4
        if !finish.isHidden {
            finish.display(x: CGFloat(finishX - left) * ppm, groundY: ground(finishX),
                           viewportHeight: size.height, ppm: ppm)
        }
        celebration.display(elapsed: finishCelebrationElapsed, size: size, reducedMotion: reducedMotion)
    }

    func playFinish() {
        finishStartScale = renderScale
        dust.particleBirthRate = 0
        dust.resetSimulation()
    }

    /// Intensity is normalized to 0...1. The session owns the matching audio event.
    func playCrash(at position: Vector2, impact: Double = 1, finalExplosion: Bool = false) {
        presentingCrash = true
        crashElapsed = 0
        crashStartScale = renderScale
        dust.particleBirthRate = 0
        dust.resetSimulation()
        // Effects use scenic time at real speed, independently of slow-motion bodies.
        bike.isHidden = finalExplosion
        effects.zPosition = finalExplosion ? 12 : 8
        effects.play(at: position, intensity: finalExplosion ? 1 : min(0.55, impact * 0.3),
                     landing: !finalExplosion, time: scenicTime)
    }

    func playLanding(at position: Vector2, intensity: Double) {
        guard !presentingCrash else { return }
        // Core impact is the approach speed in metres per second.
        let strength = min(1, max(0, intensity / 12))
        bike.reactToLanding(intensity: strength)
        guard strength > 0.12 else { return }
        effects.play(at: position, intensity: strength, landing: true, time: scenicTime)
    }

    /// Explicit respawns and presentation resets restore the complete rig.
    /// The next active frame places the complete rig at its new physical wheel centres.
    func restoreBikeAfterRespawn() {
        guard presentingCrash else { return }
        presentingCrash = false
        // Consume this once in the next display with a valid viewport.
        cameraNeedsRespawnReset = true
        bike.isHidden = false
        bike.resetAnimation()
    }

    /// New runs and the home preview reset presentation state.
    /// Existing crash bodies are replaced by the simulation's fresh starting snapshot.
    func clearTransientEffects() {
        effects.clear()
        finishCelebrationElapsed = nil
        finishStartScale = 0
        celebration.isHidden = true
        restoreBikeAfterRespawn()
        bike.resetAnimation()
        dust.particleBirthRate = 0
        dust.resetSimulation()
    }

    private func configureWorld(_ world: World) {
        worldID = world.id
        backgroundOriginX = nil
        jungleBackgroundMotion = .init()
        backgroundColor = world.sky
        // The catalog keeps its composed thumbnail; the Japanese scene uses a
        // wider painting authored for continuous travel and a larger scale.
        var texture = (world.id == "japan" ? GameAssets.texture(named: "japan-panorama") : nil)
            ?? GameAssets.texture(named: world.assetName)
        if world.id == "jungle", let painting = texture {
            // Reuse the source painting without its foreground framing palms.
            // This is a GPU subtexture; the approved source PNG is unchanged.
            texture = SKTexture(rect: CGRect(x: BackgroundPanorama.jungleCropX, y: 0,
                                            width: BackgroundPanorama.jungleCropWidth, height: 1), in: painting)
        }
        textureSize = texture?.size() ?? CGSize(width: 16, height: 9)
        backgroundTiles.forEach {
            $0.texture = texture
            $0.shader = world.id == "japan" ? japanPanoramaShader
                : world.id == "jungle" ? junglePanoramaShader : nil
            $0.zPosition = -20
        }
    }

    private func displayBackground(reducedMotion: Bool) {
        if worldID == "jungle" {
            let layout = BackgroundPanorama.jungle(
                viewportWidth: size.width, viewportHeight: size.height,
                textureWidth: textureSize.width, textureHeight: textureSize.height,
                worldTravel: jungleBackgroundMotion.travel, worldHeight: jungleBackgroundMotion.height,
                reducedMotion: reducedMotion, isPreview: isPreview)
            for (slot, pair) in zip(backgroundTiles, layout.tiles).enumerated() {
                let (node, tile) = pair
                node.isHidden = false
                node.zPosition = -20 + CGFloat(slot) * 0.01
                node.size = CGSize(width: layout.width + 1, height: layout.height)
                node.xScale = tile.mirrored ? -1 : 1
                node.position = CGPoint(x: tile.centre, y: layout.centreY)
            }
            return
        }
        if worldID == "canyon" {
            let aspect = max(1, textureSize.width) / max(1, textureSize.height)
            let height = max(size.height * 1.50, (size.width + 4) / aspect)
            let width = max(size.width + 4, height * aspect)
            if backgroundOriginX == nil { backgroundOriginX = cameraX }
            let travel = reducedMotion || isPreview ? 0 : cameraX - (backgroundOriginX ?? cameraX)
            let tiles = BackgroundPanorama.tiles(viewportWidth: size.width, tileWidth: width, travel: travel)
            let vertical = reducedMotion ? 0 : min(24, max(-24, CGFloat(cameraY) * -0.8))
            for (node, tile) in zip(backgroundTiles, tiles) {
                node.isHidden = false
                node.size = CGSize(width: width + 1, height: height)
                node.xScale = tile.mirrored ? -1 : 1
                node.position = CGPoint(x: tile.centre, y: height / 2 - 28 + vertical)
            }
            return
        }
        if worldID == "japan" {
            if backgroundOriginX == nil { backgroundOriginX = cameraX }
            let layout = BackgroundPanorama.japan(
                viewportWidth: size.width, viewportHeight: size.height,
                textureWidth: textureSize.width, textureHeight: textureSize.height,
                cameraTravel: cameraX - (backgroundOriginX ?? cameraX), cameraHeight: cameraY,
                reducedMotion: reducedMotion, isPreview: isPreview)
            for (slot, pair) in zip(backgroundTiles, layout.tiles).enumerated() {
                let (node, tile) = pair
                node.isHidden = false
                // The right painting fades over an opaque left neighbour. This
                // ordering is stable across pooled-node reuse and reverse travel.
                node.zPosition = -20 + CGFloat(slot) * 0.01
                node.size = CGSize(width: layout.width + 1, height: layout.height)
                node.xScale = tile.mirrored ? -1 : 1
                node.position = CGPoint(x: tile.centre, y: layout.centreY)
            }
            return
        }
        for (index, tile) in backgroundTiles.enumerated() { tile.isHidden = index > 0 }

        // One painting avoids mirrored landmarks and artificial joins. Overscan
        // covers both axes, including a high jump with the road below the view.
        let aspect = max(1, textureSize.width) / max(1, textureSize.height)
        let overscan: CGFloat = 32
        // In portrait, show both Golden Gate towers instead of cropping into the
        // Palace of Fine Arts. Overscan still covers every camera position.
        let bayPortrait = worldID == "sanfrancisco" && size.height > size.width
        let scenicHeight = size.height * (bayPortrait ? 1.08 : (size.width > size.height ? 1.30 : 1.45))
        let height = max(scenicHeight, size.height + overscan * 2,
                         (size.width + overscan * 2) / aspect)
        let width = height * aspect
        if backgroundOriginX == nil { backgroundOriginX = cameraX }
        // The far landscape settles gently within its margin, with no wrap,
        // reversal or position change caused by the motorcycle's changing zoom.
        let travel = (cameraX - backgroundOriginX!) / 120
        let horizontalParallax: CGFloat = reducedMotion ? 0 : CGFloat(tanh(travel)) * 24
        let verticalParallax: CGFloat = reducedMotion ? 0 : min(30, max(-30, CGFloat(cameraY) * -1.2))
        var centreX = size.width / 2
        var centreY = height / 2 - overscan + verticalParallax
        if bayPortrait {
            centreX = size.width / 2 - (0.247 - 0.5) * width
        } else if worldID == "paris" {
            centreX = size.width / 2 - (0.526 - 0.5) * width
            // The Eiffel Tower reaches near the source's top edge. Top-align this
            // painting so the summit stays whole, including during camera lifts.
            centreY = size.height + 2 - height / 2
        }
        centreX = min(width / 2 - 8, max(size.width + 8 - width / 2,
                                       centreX - horizontalParallax))
        centreY = min(height / 2 - 2, max(size.height + 2 - height / 2, centreY))
        for tile in backgroundTiles {
            tile.size = CGSize(width: width, height: height)
            tile.position = CGPoint(x: centreX, y: centreY)
            tile.xScale = 1
        }
    }

    private static func makeScenerySeed() -> UInt64 {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ui-testing"), let flag = arguments.firstIndex(of: "-scenery-seed"),
           arguments.indices.contains(flag + 1), let value = UInt64(arguments[flag + 1]) {
            return value
        }
        #endif
        return UInt64.random(in: UInt64.min...UInt64.max)
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

}
