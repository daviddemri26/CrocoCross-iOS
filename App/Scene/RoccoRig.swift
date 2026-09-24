import CrocoCrossCore
import SpriteKit
import UIKit

/// Presentation only: the five physical poses have independent world transforms.
/// The two-segment limbs never feed a force or correction back into Box2D.
@MainActor
final class RiderRig: SKNode {
    private struct Piece {
        let node: SKNode
        let artwork: RiderRigArtwork.Loaded
    }

    private final class Chain {
        let upper: Piece
        let lower: Piece
        let foot: Piece?
        let bend: CGFloat
        let depthOffset: CGPoint
        var motion: DetachedLimbMotion?

        init(upper: Piece, lower: Piece, foot: Piece?, bend: CGFloat, depthOffset: CGPoint) {
            self.upper = upper; self.lower = lower; self.foot = foot
            self.bend = bend; self.depthOffset = depthOffset
        }
    }

    private let artworkRoot = SKNode()
    private var pieces: [RiderRigArtwork.Part: Piece] = [:]
    private var renderPieces: [Piece] = []
    private var arms: [Chain] = []
    private var legs: [Chain] = []
    private var wheelPieces: [Piece] = []
    private var currentRiderID = ""
    private var profile: RiderRigArtwork.Profile!
    private var shownLean: CGFloat = 0
    private var shownShift: CGFloat = 0
    private var previousMotionSeconds: Double?
    private var previousSeconds: Double?
    private var previousSeed: UInt32?
    private var previousTick = 0
    private var wasAttached = true
    private struct BodyOffset {
        let position: CGPoint
        let angle: CGFloat
    }
    private var attachedPelvisOffset: BodyOffset?
    private var attachedTorsoOffset: BodyOffset?

    override init() {
        super.init()
        addChild(artworkRoot)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(_ state: SimulationState, rider: Rider, pointsPerMetre ppm: CGFloat,
                 project: (Vector2) -> CGPoint, reducedMotion: Bool, seconds: Double, motionSeconds: Double? = nil) {
        if currentRiderID != rider.id { configure(rider.id) }
        guard let bike = pieces[.bike], let pelvis = pieces[.pelvis], let torso = pieces[.torso] else { return }
        let motionTime = motionSeconds ?? seconds
        if previousSeed != state.seed || state.tick < previousTick || motionTime < (previousMotionSeconds ?? motionTime) {
            for chain in arms + legs { chain.motion = nil }
            previousMotionSeconds = nil
            attachedPelvisOffset = nil; attachedTorsoOffset = nil
        }
        let chassisPosition = project(state.bike.position)
        let chassisAngle = CGFloat(state.bike.angle)
        var pelvisPosition = project(state.rider.pelvis.position)
        var torsoPosition = project(state.rider.torso.position)
        var pelvisAngle = CGFloat(state.rider.pelvis.angle)
        var torsoAngle = CGFloat(state.rider.torso.angle)
        if state.rider.isAttached {
            // Filter only posture relative to the motorcycle, never the bike's
            // rotation. Rebuild the shared waist anchor so interpolation cannot
            // pull the two painted halves apart or swing through +/-pi.
            let relative = torsoAngle - chassisAngle
            let targetLean = min(profile.maxTorsoLean, max(-profile.maxTorsoLean, atan2(sin(relative), cos(relative))))
            let delta = Vector2(x: state.rider.pelvis.position.x - state.bike.position.x,
                                y: state.rider.pelvis.position.y - state.bike.position.y)
            let targetShift = min(profile.maxPelvisShift, max(-profile.maxPelvisShift,
                CGFloat(delta.x * cos(state.bike.angle) + delta.y * sin(state.bike.angle))))
            let elapsed = seconds - (previousSeconds ?? seconds)
            let reset = previousSeconds == nil || previousSeed != state.seed || state.tick < previousTick ||
                !wasAttached || elapsed < 0 || elapsed > 0.25
            if reset { shownLean = targetLean; shownShift = targetShift }
            else if elapsed > 0 {
                let dt = CGFloat(elapsed), blend = 1 - exp(-dt / profile.smoothingTime)
                shownLean += min(profile.maxLeanSpeed * dt, max(-profile.maxLeanSpeed * dt, (targetLean - shownLean) * blend))
                shownShift += min(profile.maxShiftSpeed * dt, max(-profile.maxShiftSpeed * dt, (targetShift - shownShift) * blend))
            }
            pelvisAngle = chassisAngle
            torsoAngle = chassisAngle + shownLean
            pelvisPosition = offset(chassisPosition, CGPoint(x: profile.pelvisCentre.x + shownShift, y: profile.pelvisCentre.y), angle: chassisAngle, ppm: ppm)
            let waist = landmark(.spine, on: pelvis, position: pelvisPosition, angle: pelvisAngle, ppm: ppm)
            let torsoWaist = torso.artwork.local(.spine)
            torsoPosition = offset(waist, CGPoint(x: -torsoWaist.x, y: -torsoWaist.y), angle: torsoAngle, ppm: ppm)
            if profile.retainDetachPose {
                // Record in each physical body's local coordinate system, in
                // metres. Camera movement/zoom cannot become a ragdoll offset.
                let pelvisWorld = offset(CGPoint(x: state.bike.position.x, y: state.bike.position.y),
                                         CGPoint(x: profile.pelvisCentre.x + shownShift, y: profile.pelvisCentre.y),
                                         angle: chassisAngle, ppm: 1)
                let waistWorld = offset(pelvisWorld, pelvis.artwork.local(.spine), angle: pelvisAngle, ppm: 1)
                let torsoWorld = offset(waistWorld, CGPoint(x: -torsoWaist.x, y: -torsoWaist.y), angle: torsoAngle, ppm: 1)
                attachedPelvisOffset = bodyOffset(presentation: pelvisWorld, angle: pelvisAngle, physical: state.rider.pelvis)
                attachedTorsoOffset = bodyOffset(presentation: torsoWorld, angle: torsoAngle, physical: state.rider.torso)
            }
        } else if profile.retainDetachPose {
            // Keep the last attached art pose relative to the released physical
            // body, including its filtered lean/shift. There is no launch, force
            // or correction: subsequent translation/rotation is entirely physical.
            let pelvisOffset = attachedPelvisOffset ?? BodyOffset(
                position: CGPoint(x: profile.pelvisCentre.x, y: profile.pelvisCentre.y - 0.10), angle: 0)
            let torsoOffset = attachedTorsoOffset ?? BodyOffset(
                position: CGPoint(x: profile.torsoCentre.x, y: profile.torsoCentre.y - 0.36), angle: 0)
            pelvisPosition = offset(pelvisPosition, pelvisOffset.position, angle: pelvisAngle, ppm: ppm)
            torsoPosition = offset(torsoPosition, torsoOffset.position, angle: torsoAngle, ppm: ppm)
            pelvisAngle += pelvisOffset.angle
            torsoAngle += torsoOffset.angle
        }
        let motionDelta = max(0, motionTime - (previousMotionSeconds ?? motionTime))
        previousMotionSeconds = motionTime
        previousSeconds = seconds; previousSeed = state.seed; previousTick = state.tick
        wasAttached = state.rider.isAttached
        place(bike, at: chassisPosition, angle: chassisAngle, ppm: ppm)
        place(pelvis, at: pelvisPosition, angle: pelvisAngle, ppm: ppm)
        place(torso, at: torsoPosition, angle: torsoAngle, ppm: ppm)

        // Render scale depends only on physical dimensions and camera scale;
        // suspension separation never stretches the motorcycle artwork.
        for (index, wheel) in [state.bike.rear, state.bike.front].enumerated() {
            if wheelPieces.indices.contains(index) {
                place(wheelPieces[index], at: project(wheel.position), angle: CGFloat(wheel.angle), ppm: ppm)
            }
        }

        let grip = landmark(.grip, on: bike, position: chassisPosition, angle: chassisAngle, ppm: ppm)
        let footpeg = landmark(.footpeg, on: bike, position: chassisPosition, angle: chassisAngle, ppm: ppm)
        let shoulder = landmark(.shoulder, on: torso, position: torsoPosition, angle: torsoAngle, ppm: ppm)
        let hip = landmark(.hip, on: pelvis, position: pelvisPosition, angle: pelvisAngle, ppm: ppm)
        for (index, chain) in arms.enumerated() {
            let root = offset(shoulder, chain.depthOffset, angle: torsoAngle, ppm: ppm)
            if state.rider.isAttached {
                articulate(chain, from: root, to: offset(grip, chain.depthOffset, angle: chassisAngle, ppm: ppm), ppm: ppm)
            } else {
                relax(chain, from: root, bodyAngle: torsoAngle, body: state.rider.torso,
                      ppm: ppm, reducedMotion: reducedMotion, dt: motionDelta, side: index == 0 ? -1 : 1)
            }
        }
        for (index, chain) in legs.enumerated() {
            let root = offset(hip, chain.depthOffset, angle: pelvisAngle, ppm: ppm)
            if state.rider.isAttached, let foot = chain.foot {
                let support = offset(footpeg, chain.depthOffset, angle: chassisAngle, ppm: ppm)
                if profile.bootFollowsCalf {
                    articulateSupportedFoot(chain, from: root, support: support, ppm: ppm)
                } else {
                    let sole = foot.artwork.local(.contact)
                    let bootAngle = chassisAngle + profile.bootAngleOffset
                    let ankle = offset(support, CGPoint(x: -sole.x, y: -sole.y), angle: bootAngle, ppm: ppm)
                    articulate(chain, from: root, to: ankle, ppm: ppm)
                    // The ankle can flex at the authored top-cuff pivot. Kenji's
                    // modest boot pitch and Rocco's level sole both stay supported.
                    place(foot, at: ankle, angle: bootAngle, ppm: ppm)
                }
            } else {
                relax(chain, from: root, bodyAngle: pelvisAngle, body: state.rider.pelvis,
                      ppm: ppm, reducedMotion: reducedMotion, dt: motionDelta, side: index == 0 ? -1 : 1)
            }
        }

        if state.rider.isAttached {
            for (chains, body) in [(arms, state.rider.torso), (legs, state.rider.pelvis)] {
                for (index, chain) in chains.enumerated() {
                    chain.motion = DetachedLimbMotion(upper: Double(chain.upper.node.zRotation),
                        lower: Double(chain.lower.node.zRotation), body: body, side: index == 0 ? -1 : 1)
                }
            }
        }

        let steering = landmark(.steeringTop, on: bike, position: chassisPosition, angle: chassisAngle, ppm: ppm)
        let swing = landmark(.swingPivot, on: bike, position: chassisPosition, angle: chassisAngle, ppm: ppm)
        if let swingarm = pieces[.swingarm] {
            placeLink(swingarm, from: swing, to: project(state.bike.rear.position), ppm: ppm)
        }
        if let fork = pieces[.fork] {
            placeLink(fork, from: steering, to: project(state.bike.front.position), ppm: ppm)
        }
    }

    /// Painted bounds for camera framing. Transparent source canvas padding
    /// must not push the camera away from the rider during a rotation.
    func visibleBounds(in reference: SKNode) -> CGRect {
        var result = CGRect.null
        for piece in renderPieces {
            let art = piece.artwork
            let bounds = art.entry.visibleBounds
            let pivot = art.entry.point(.pivot)
            for x in [bounds.minX, bounds.maxX] {
                for y in [bounds.minY, bounds.maxY] {
                    let pixel = CGPoint(x: (x - pivot.x) * art.sourceSize.width,
                                        y: -(y - pivot.y) * art.sourceSize.height)
                    let oriented = offset(.zero, pixel, angle: art.neutralRotation, ppm: 1)
                    let point = piece.node.convert(oriented, to: reference)
                    result = result.union(CGRect(origin: point, size: .zero))
                }
            }
        }
        return result
    }

    #if DEBUG
    /// Read-only measurements from the actual SpriteKit transforms, used by the
    /// native preview harness to check both palms, soles and the shared waist.
    struct AttachmentDiagnostics {
        let handErrorsMetres: [CGFloat]
        let footErrorsMetres: [CGFloat]
        let waistErrorMetres: CGFloat
        let ankleErrorsMetres: [CGFloat]
        let bootToCalfAngleErrors: [CGFloat]
        let bootAngles: [CGFloat]
        let torsoLean: CGFloat
    }

    struct BodyTransform {
        let position: CGPoint
        let angle: CGFloat
    }

    func bodyTransforms() -> [String: BodyTransform] {
        Dictionary(uniqueKeysWithValues: [RiderRigArtwork.Part.pelvis, .torso].compactMap { part in
            pieces[part].map { (part.rawValue, BodyTransform(position: $0.node.position, angle: $0.node.zRotation)) }
        })
    }

    struct LimbDiagnostics {
        let upperAngle: Double
        let lowerAngle: Double
        let rootErrorMetres: CGFloat
        let jointErrorMetres: CGFloat
        let ankleErrorMetres: CGFloat
    }

    func limbDiagnostics() -> [LimbDiagnostics] {
        guard let bike = pieces[.bike], let torso = pieces[.torso], let pelvis = pieces[.pelvis] else { return [] }
        let ppm = bike.node.xScale / bike.artwork.metresPerPixel
        func error(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) / ppm }
        return [(arms, torso, RiderRigArtwork.Anchor.shoulder), (legs, pelvis, .hip)].flatMap { chains, body, anchor in
            chains.map { chain in
                let root = offset(landmark(anchor, on: body, position: body.node.position,
                                           angle: body.node.zRotation, ppm: ppm), chain.depthOffset,
                                  angle: body.node.zRotation, ppm: ppm)
                let joint = offset(chain.upper.node.position,
                                   CGPoint(x: chain.upper.artwork.entry.calibration.metres, y: 0),
                                   angle: chain.upper.node.zRotation, ppm: ppm)
                let ankle = offset(chain.lower.node.position,
                                   CGPoint(x: chain.lower.artwork.entry.calibration.metres, y: 0),
                                   angle: chain.lower.node.zRotation, ppm: ppm)
                return LimbDiagnostics(upperAngle: Double(chain.upper.node.zRotation), lowerAngle: Double(chain.lower.node.zRotation),
                                       rootErrorMetres: error(root, chain.upper.node.position),
                                       jointErrorMetres: error(joint, chain.lower.node.position),
                                       ankleErrorMetres: chain.foot.map { error(ankle, $0.node.position) } ?? 0)
            }
        }
    }

    func attachmentDiagnostics() -> AttachmentDiagnostics? {
        guard wasAttached, let bike = pieces[.bike], let torso = pieces[.torso], let pelvis = pieces[.pelvis] else { return nil }
        let ppm = bike.node.xScale / bike.artwork.metresPerPixel
        guard ppm > 0 else { return nil }
        func rendered(_ anchor: RiderRigArtwork.Anchor, on piece: Piece) -> CGPoint {
            let local = piece.artwork.local(anchor), scale = piece.artwork.metresPerPixel
            return piece.node.convert(CGPoint(x: local.x / scale, y: local.y / scale), to: artworkRoot)
        }
        func error(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) / ppm }
        let grip = rendered(.grip, on: bike), peg = rendered(.footpeg, on: bike)
        let hands = arms.map { chain in
            error(rendered(.contact, on: chain.lower), offset(grip, chain.depthOffset, angle: bike.node.zRotation, ppm: ppm))
        }
        let feet = legs.compactMap { chain -> CGFloat? in
            guard let foot = chain.foot else { return nil }
            return error(rendered(.contact, on: foot), offset(peg, chain.depthOffset, angle: bike.node.zRotation, ppm: ppm))
        }
        let ankles = legs.compactMap { chain -> CGFloat? in
            guard let foot = chain.foot else { return nil }
            return error(rendered(.distal, on: chain.lower), rendered(.pivot, on: foot))
        }
        let cuffAngles = legs.compactMap { chain -> CGFloat? in
            guard let foot = chain.foot else { return nil }
            let relative = foot.node.zRotation - chain.lower.node.zRotation - .pi / 2
            return abs(atan2(sin(relative), cos(relative)))
        }
        let bootAngles = legs.compactMap { chain -> CGFloat? in
            guard let foot = chain.foot else { return nil }
            let relative = foot.node.zRotation - bike.node.zRotation
            return atan2(sin(relative), cos(relative))
        }
        let relative = torso.node.zRotation - bike.node.zRotation
        return AttachmentDiagnostics(handErrorsMetres: hands, footErrorsMetres: feet,
                                     waistErrorMetres: error(rendered(.spine, on: torso), rendered(.spine, on: pelvis)),
                                     ankleErrorsMetres: ankles, bootToCalfAngleErrors: cuffAngles, bootAngles: bootAngles,
                                     torsoLean: atan2(sin(relative), cos(relative)))
    }
    #endif

    private func configure(_ riderID: String) {
        artworkRoot.removeAllChildren()
        pieces.removeAll(); renderPieces.removeAll(); arms.removeAll(); legs.removeAll(); wheelPieces.removeAll()
        currentRiderID = ""
        previousMotionSeconds = nil; previousSeconds = nil; previousSeed = nil; previousTick = 0; wasAttached = true
        shownLean = 0; shownShift = 0
        attachedPelvisOffset = nil; attachedTorsoOffset = nil
        guard let manifest = RiderRigArtwork.manifest(for: riderID),
              RiderRigArtwork.Part.allCases.allSatisfy({ RiderRigArtwork.load($0, riderID: riderID) != nil }) else { return }
        currentRiderID = riderID
        profile = manifest.profile
        for (part, depth) in [(RiderRigArtwork.Part.bike, 1.0), (.pelvis, 1.2), (.torso, 1.3),
                              (.fork, 0.7), (.swingarm, 0.3)] {
            if let piece = makePiece(part, depth: profile.depth(part.rawValue, default: depth)) { pieces[part] = piece }
        }
        for far in [true, false] {
            let side = far ? "far" : "near"
            if let upper = makePiece(.upperArm, depth: profile.depth(side + "UpperArm", default: far ? 0.8 : 1.7)),
               let lower = makePiece(.forearm, depth: profile.depth(side + "Forearm", default: far ? 0.81 : 1.71)) {
                arms.append(Chain(upper: upper, lower: lower, foot: nil, bend: -1,
                                  depthOffset: far ? profile.farArmOffset : .zero))
            }
            if let upper = makePiece(.thigh, depth: profile.depth(side + "Thigh", default: far ? 0.2 : 1.5)),
               let lower = makePiece(.calf, depth: profile.depth(side + "Calf", default: far ? 0.21 : 1.51)),
               let foot = makePiece(.boot, depth: profile.depth(side + "Boot", default: far ? 0.22 : 1.52)) {
                legs.append(Chain(upper: upper, lower: lower, foot: foot, bend: 1,
                                  depthOffset: far ? profile.farLegOffset : .zero))
            }
        }
        for _ in 0 ..< 2 {
            if let wheel = makePiece(.wheel, depth: profile.depth("wheel", default: 0.5)) { wheelPieces.append(wheel) }
        }
    }

    private func makePiece(_ part: RiderRigArtwork.Part, depth: CGFloat) -> Piece? {
        guard let art = RiderRigArtwork.load(part, riderID: currentRiderID) else { return nil }
        let sprite = SKSpriteNode(texture: art.texture)
        let pivot = art.entry.point(.pivot)
        sprite.anchorPoint = CGPoint(x: pivot.x, y: 1 - pivot.y)
        sprite.size = art.sourceSize
        sprite.zRotation = art.neutralRotation
        let node = SKNode()
        node.zPosition = depth
        if part == .pelvis, let edge = profile.pelvisCropMaxX {
            let crop = SKCropNode()
            let painted = SKNode()
            painted.addChild(sprite)
            let mask = SKSpriteNode(color: .white, size: CGSize(width: art.sourceSize.width * edge,
                                                                height: art.sourceSize.height))
            mask.anchorPoint = CGPoint(x: 0, y: 0)
            mask.position = CGPoint(x: -pivot.x * art.sourceSize.width,
                                    y: -(1 - pivot.y) * art.sourceSize.height)
            crop.maskNode = mask
            crop.addChild(painted)
            node.addChild(crop)
        } else { node.addChild(sprite) }
        artworkRoot.addChild(node)
        let piece = Piece(node: node, artwork: art)
        renderPieces.append(piece)
        return piece
    }

    private func place(_ piece: Piece, at point: CGPoint, angle: CGFloat, ppm: CGFloat) {
        piece.node.position = point
        piece.node.zRotation = angle
        piece.node.setScale(ppm * piece.artwork.metresPerPixel)
        // Increase muscle thickness without moving shoulder/elbow joint centres.
        if piece.artwork.entry.part == .upperArm { piece.node.yScale *= profile.upperArmThickness }
    }

    private func landmark(_ name: RiderRigArtwork.Anchor, on piece: Piece, position: CGPoint,
                          angle: CGFloat, ppm: CGFloat) -> CGPoint {
        offset(position, piece.artwork.local(name), angle: angle, ppm: ppm)
    }

    private func bodyOffset(presentation: CGPoint, angle: CGFloat, physical: RigidBodyState) -> BodyOffset {
        let delta = CGPoint(x: presentation.x - physical.position.x, y: presentation.y - physical.position.y)
        let relative = angle - CGFloat(physical.angle)
        return BodyOffset(position: offset(.zero, delta, angle: -CGFloat(physical.angle), ppm: 1),
                          angle: atan2(sin(relative), cos(relative)))
    }

    private func offset(_ point: CGPoint, _ local: CGPoint, angle: CGFloat, ppm: CGFloat) -> CGPoint {
        CGPoint(x: point.x + (local.x * cos(angle) - local.y * sin(angle)) * ppm,
                y: point.y + (local.x * sin(angle) + local.y * cos(angle)) * ppm)
    }

    private func articulate(_ chain: Chain, from root: CGPoint, to target: CGPoint, ppm: CGFloat) {
        let a = chain.upper.artwork.entry.calibration.metres * ppm
        let b = chain.lower.artwork.entry.calibration.metres * ppm
        let dx = target.x - root.x, dy = target.y - root.y
        let distance = hypot(dx, dy)
        let reach = min(a + b - 0.001, max(abs(a - b) + 0.001, distance))
        let direction = atan2(dy, dx)
        let bend = acos(min(1, max(-1, (a * a + reach * reach - b * b) / (2 * a * reach))))
        let upperAngle = direction + chain.bend * bend
        let joint = CGPoint(x: root.x + cos(upperAngle) * a, y: root.y + sin(upperAngle) * a)
        let reachableTarget = CGPoint(x: root.x + cos(direction) * reach, y: root.y + sin(direction) * reach)
        place(chain.upper, at: root, angle: upperAngle, ppm: ppm)
        place(chain.lower, at: joint, angle: atan2(reachableTarget.y - joint.y, reachableTarget.x - joint.x), ppm: ppm)
    }

    /// Solve hip -> knee -> sole as two segments. The second effective segment
    /// combines the calf with the rotated cuff-to-sole offset. This puts the shin
    /// through the top of the boot while keeping the sole exactly on its support.
    private func articulateSupportedFoot(_ chain: Chain, from root: CGPoint, support: CGPoint, ppm: CGFloat) {
        guard let foot = chain.foot else { return }
        let calf = chain.lower.artwork.entry.calibration.metres
        let sole = foot.artwork.local(.contact)
        let effective = CGPoint(x: calf - sole.y, y: sole.x)
        let a = chain.upper.artwork.entry.calibration.metres * ppm
        let b = hypot(effective.x, effective.y) * ppm
        let dx = support.x - root.x, dy = support.y - root.y
        let distance = hypot(dx, dy)
        let reach = min(a + b - 0.001, max(abs(a - b) + 0.001, distance))
        let direction = atan2(dy, dx)
        let bend = acos(min(1, max(-1, (a * a + reach * reach - b * b) / (2 * a * reach))))
        let upperAngle = direction + chain.bend * bend
        let knee = offset(root, CGPoint(x: a / ppm, y: 0), angle: upperAngle, ppm: ppm)
        let reachableSupport = offset(root, CGPoint(x: reach / ppm, y: 0), angle: direction, ppm: ppm)
        let lowerAngle = atan2(reachableSupport.y - knee.y, reachableSupport.x - knee.x) - atan2(effective.y, effective.x)
        let ankle = offset(knee, CGPoint(x: calf, y: 0), angle: lowerAngle, ppm: ppm)
        place(chain.upper, at: root, angle: upperAngle, ppm: ppm)
        place(chain.lower, at: knee, angle: lowerAngle, ppm: ppm)
        place(foot, at: ankle, angle: lowerAngle + .pi / 2, ppm: ppm)
    }

    private func relax(_ chain: Chain, from root: CGPoint, bodyAngle: CGFloat, body: RigidBodyState,
                       ppm: CGFloat, reducedMotion: Bool, dt: Double, side: Double) {
        if chain.motion == nil {
            let upper = Double(bodyAngle) - .pi / 2 + side * 0.2
            chain.motion = DetachedLimbMotion(upper: upper, lower: upper - Double(chain.bend) * 0.3,
                                             body: body, side: side)
        }
        chain.motion?.advance(dt: dt, body: body, bodyAngle: Double(bodyAngle),
                              upperLength: Double(chain.upper.artwork.entry.calibration.metres),
                              lowerLength: Double(chain.lower.artwork.entry.calibration.metres),
                              isLeg: chain.foot != nil, side: side, reducedMotion: reducedMotion)
        let upperAngle = CGFloat(chain.motion!.upper)
        let lowerAngle = CGFloat(chain.motion!.lower)
        let length = chain.upper.artwork.entry.calibration.metres * ppm
        let joint = CGPoint(x: root.x + cos(upperAngle) * length, y: root.y + sin(upperAngle) * length)
        place(chain.upper, at: root, angle: upperAngle, ppm: ppm)
        place(chain.lower, at: joint, angle: lowerAngle, ppm: ppm)
        if let foot = chain.foot {
            let calfLength = chain.lower.artwork.entry.calibration.metres * ppm
            let ankle = CGPoint(x: joint.x + cos(lowerAngle) * calfLength, y: joint.y + sin(lowerAngle) * calfLength)
            place(foot, at: ankle, angle: lowerAngle + .pi / 2, ppm: ppm)
        }
    }

    private func placeLink(_ piece: Piece, from start: CGPoint, to end: CGPoint, ppm: CGFloat) {
        let distance = hypot(end.x - start.x, end.y - start.y)
        place(piece, at: start, angle: atan2(end.y - start.y, end.x - start.x), ppm: ppm)
        // Suspension links follow each physical axle along their own length.
        // The painted tube width, chassis scale and tire radius stay unchanged.
        let fit = distance / max(0.001, piece.artwork.entry.calibration.metres * ppm)
        piece.node.xScale *= fit
    }
}

// Compatibility for existing rendering diagnostics.
typealias RoccoRig = RiderRig

/// Catalog artwork is a cached neutral pose of the same parts used in gameplay.
/// Snapshot once per rider, never once per cell or animation frame.
@MainActor
enum RiderRigPreview {
    private static var cache: [String: UIImage] = [:]

    static func image(for rider: Rider) -> UIImage? {
        if let image = cache[rider.id] { return image }
        guard RiderRigArtwork.supports(rider.id),
              RiderRigArtwork.manifest(for: rider.id) != nil else { return nil }
        let physics = PhysicsConfiguration()
        var state = SimulationState(mode: .endless, seed: 0)
        let axleY = -(physics.unloadedAxleOffset - physics.suspensionTravel * physics.suspensionSag)
        state.bike.rear.position = Vector2(x: -physics.wheelbase / 2, y: axleY)
        state.bike.front.position = Vector2(x: physics.wheelbase / 2, y: axleY)
        let ppm: CGFloat = 420
        let scene = SKScene(size: CGSize(width: 1600, height: 1200))
        scene.backgroundColor = .clear
        let rig = RiderRig()
        scene.addChild(rig)
        rig.display(state, rider: rider, pointsPerMetre: ppm,
                    project: { CGPoint(x: CGFloat($0.x) * ppm, y: CGFloat($0.y) * ppm) },
                    reducedMotion: true, seconds: 0)
        let bounds = rig.visibleBounds(in: scene).insetBy(dx: -8, dy: -8)
        guard !bounds.isNull, bounds.width > 0, bounds.height > 0 else { return nil }
        let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
        view.allowsTransparency = true
        view.presentScene(scene)
        guard let texture = view.texture(from: rig, crop: bounds) else { return nil }
        let image = UIImage(cgImage: texture.cgImage())
        cache[rider.id] = image
        return image
    }
}
