import CrocoCrossCore
import SpriteKit
import UIKit

/// Presentation only: the five physical poses have independent world transforms.
/// The two-segment limbs never feed a force or correction back into Box2D.
@MainActor
final class RoccoRig: SKNode {
    private struct Piece {
        let node: SKNode
        let artwork: RoccoArtwork.Loaded
    }

    private struct Chain {
        let upper: Piece
        let lower: Piece
        let foot: Piece?
        let bend: CGFloat
        let depthOffset: CGPoint
    }

    private let artworkRoot = SKNode()
    private var pieces: [RoccoArtwork.Part: Piece] = [:]
    private var renderPieces: [Piece] = []
    private var arms: [Chain] = []
    private var legs: [Chain] = []
    private var wheelPieces: [Piece] = []
    private var configured = false
    private var shownLean: CGFloat = 0
    private var shownShift: CGFloat = 0
    private var previousSeconds: Double?
    private var previousSeed: UInt32?
    private var previousTick = 0
    private var wasAttached = true

    override init() {
        super.init()
        addChild(artworkRoot)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(_ state: SimulationState, rider: Rider, pointsPerMetre ppm: CGFloat,
                 project: (Vector2) -> CGPoint, reducedMotion: Bool, seconds: Double) {
        if !configured { configure() }
        guard let bike = pieces[.bike], let pelvis = pieces[.pelvis], let torso = pieces[.torso] else { return }
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
            let targetLean = min(CGFloat(0.35), max(-0.35, atan2(sin(relative), cos(relative))))
            let delta = Vector2(x: state.rider.pelvis.position.x - state.bike.position.x,
                                y: state.rider.pelvis.position.y - state.bike.position.y)
            let targetShift = min(CGFloat(0.14), max(-0.14,
                CGFloat(delta.x * cos(state.bike.angle) + delta.y * sin(state.bike.angle))))
            let elapsed = seconds - (previousSeconds ?? seconds)
            let reset = previousSeconds == nil || previousSeed != state.seed || state.tick < previousTick ||
                !wasAttached || elapsed < 0 || elapsed > 0.25
            if reset { shownLean = targetLean; shownShift = targetShift }
            else if elapsed > 0 {
                let dt = CGFloat(elapsed), blend = 1 - exp(-dt / 0.065)
                shownLean += min(2.5 * dt, max(-2.5 * dt, (targetLean - shownLean) * blend))
                shownShift += min(0.8 * dt, max(-0.8 * dt, (targetShift - shownShift) * blend))
            }
            pelvisAngle = chassisAngle
            torsoAngle = chassisAngle + shownLean
            pelvisPosition = offset(chassisPosition, CGPoint(x: shownShift, y: 0.10), angle: chassisAngle, ppm: ppm)
            let waist = landmark(.spine, on: pelvis, position: pelvisPosition, angle: pelvisAngle, ppm: ppm)
            let torsoWaist = torso.artwork.local(.spine)
            torsoPosition = offset(waist, CGPoint(x: -torsoWaist.x, y: -torsoWaist.y), angle: torsoAngle, ppm: ppm)
        }
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
        for chain in arms {
            let root = offset(shoulder, chain.depthOffset, angle: torsoAngle, ppm: ppm)
            if state.rider.isAttached {
                articulate(chain, from: root, to: offset(grip, chain.depthOffset, angle: chassisAngle, ppm: ppm), ppm: ppm)
            } else {
                relax(chain, from: root, bodyAngle: torsoAngle, spin: state.rider.torso.angularVelocity,
                      ppm: ppm, reducedMotion: reducedMotion, phase: seconds)
            }
        }
        for chain in legs {
            let root = offset(hip, chain.depthOffset, angle: pelvisAngle, ppm: ppm)
            if state.rider.isAttached, let foot = chain.foot {
                let support = offset(footpeg, chain.depthOffset, angle: chassisAngle, ppm: ppm)
                let sole = foot.artwork.local(.contact)
                let ankle = offset(support, CGPoint(x: -sole.x, y: -sole.y), angle: chassisAngle, ppm: ppm)
                articulate(chain, from: root, to: ankle, ppm: ppm)
                // The ankle articulates independently: bending a knee never
                // forces the painted boot's sole to point down through the peg.
                place(foot, at: ankle, angle: chassisAngle, ppm: ppm)
            } else {
                relax(chain, from: root, bodyAngle: pelvisAngle, spin: state.rider.pelvis.angularVelocity,
                      ppm: ppm, reducedMotion: reducedMotion, phase: seconds + 0.7)
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

    private func configure() {
        guard RoccoArtwork.Part.allCases.allSatisfy({ RoccoArtwork.load($0) != nil }) else { return }
        for (part, depth) in [(RoccoArtwork.Part.bike, 1.0), (.pelvis, 1.2), (.torso, 1.3),
                              (.fork, 0.7), (.swingarm, 0.3)] {
            if let piece = makePiece(part, depth: depth) { pieces[part] = piece }
        }
        for (far, offset) in [(true, CGPoint(x: -0.035, y: 0.025)), (false, CGPoint.zero)] {
            if let upper = makePiece(.upperArm, depth: far ? 0.8 : 1.7),
               let lower = makePiece(.forearm, depth: far ? 0.81 : 1.71) {
                arms.append(Chain(upper: upper, lower: lower, foot: nil, bend: -1, depthOffset: offset))
            }
            if let upper = makePiece(.thigh, depth: far ? 0.2 : 1.5),
               let lower = makePiece(.calf, depth: far ? 0.21 : 1.51),
               let foot = makePiece(.boot, depth: far ? 0.22 : 1.52) {
                legs.append(Chain(upper: upper, lower: lower, foot: foot, bend: 1, depthOffset: offset))
            }
        }
        for _ in 0 ..< 2 {
            if let wheel = makePiece(.wheel, depth: 0.5) { wheelPieces.append(wheel) }
        }
        configured = true
    }

    private func makePiece(_ part: RoccoArtwork.Part, depth: CGFloat) -> Piece? {
        guard let art = RoccoArtwork.load(part) else { return nil }
        let sprite = SKSpriteNode(texture: art.texture)
        let pivot = art.entry.point(.pivot)
        sprite.anchorPoint = CGPoint(x: pivot.x, y: 1 - pivot.y)
        sprite.size = art.sourceSize
        sprite.zRotation = art.neutralRotation
        let node = SKNode()
        node.zPosition = depth
        if part == .pelvis {
            let crop = SKCropNode()
            let painted = SKNode()
            painted.addChild(sprite)
            let edge: CGFloat = 0.82
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
        if piece.artwork.entry.part == .upperArm { piece.node.yScale *= 1.65 }
    }

    private func landmark(_ name: RoccoArtwork.Anchor, on piece: Piece, position: CGPoint,
                          angle: CGFloat, ppm: CGFloat) -> CGPoint {
        offset(position, piece.artwork.local(name), angle: angle, ppm: ppm)
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

    private func relax(_ chain: Chain, from root: CGPoint, bodyAngle: CGFloat, spin: Double,
                       ppm: CGFloat, reducedMotion: Bool, phase: Double) {
        // These are cosmetic appendages attached to the physical pelvis/torso.
        // Detached limbs are not extra collision bodies or an independent ragdoll.
        let followThrough = reducedMotion ? 0 : CGFloat(tanh(spin * 0.2)) * 0.16
        let flutter = reducedMotion ? 0 : CGFloat(sin(phase * 3)) * 0.025
        let upperAngle = bodyAngle - .pi / 2 + chain.bend * 0.30 + followThrough
        let lowerAngle = upperAngle + chain.bend * 0.45 + flutter
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
