import AppKit
import SpriteKit
import Metal
import ImageIO
import UniformTypeIdentifiers
import CrocoCrossCore

@main struct NativePreview {
    @MainActor static func main() throws {
        precondition(CommandLine.arguments.count == 3, "Usage: Preview croco|shiba output-directory")
        _ = NSApplication.shared
        let rider = Rider(id: CommandLine.arguments[1])
        let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else {
            throw NSError(domain: "RiderPreview", code: 1, userInfo: [NSLocalizedDescriptionKey: "Native previews require a Metal device and a macOS WindowServer session"])
        }
        let size = CGSize(width: 1800, height: 1500)
        let renderer = SKRenderer(device: device)
        let scene = SKScene(size: size)
        scene.backgroundColor = NSColor(calibratedWhite: 0.84, alpha: 1)
        for row in 0..<30 {
            for column in 0..<36 where (row + column).isMultiple(of: 2) {
                let square = SKSpriteNode(color: NSColor(calibratedWhite: 0.74, alpha: 1), size: CGSize(width: 50, height: 50))
                square.position = CGPoint(x: column * 50 + 25, y: row * 50 + 25)
                square.zPosition = -10
                scene.addChild(square)
            }
        }
        renderer.scene = scene
        let ppm: CGFloat = 530
        let project: (Vector2) -> CGPoint = { CGPoint(x: 900 + CGFloat($0.x) * ppm, y: 620 + CGFloat($0.y) * ppm) }
        let physics = PhysicsConfiguration()
        func state(angle: Double = 0, lean: Double = 0, shift: Double = 0, compression: Double = 0,
                   attached: Bool = true, tick: Int = 0) -> SimulationState {
            func rotated(_ x: Double, _ y: Double) -> Vector2 {
                Vector2(x: x * cos(angle) - y * sin(angle), y: x * sin(angle) + y * cos(angle))
            }
            var s = SimulationState(mode: .endless, seed: 42)
            s.tick = tick
            s.bike.angle = angle
            let axleY = -(physics.unloadedAxleOffset - physics.suspensionTravel * physics.suspensionSag) + compression
            s.bike.rear.position = rotated(-physics.wheelbase / 2, axleY)
            s.bike.front.position = rotated(physics.wheelbase / 2, axleY)
            s.bike.rear.angle = angle - Double(tick) * 0.055
            s.bike.front.angle = angle - Double(tick) * 0.055
            s.rider.isAttached = attached
            s.rider.pelvis.position = rotated(shift, attached ? 0.10 : 0.44)
            s.rider.torso.position = rotated(shift + (attached ? 0 : 0.15), attached ? 0.36 : 0.83)
            s.rider.pelvis.angle = angle + (attached ? 0 : -0.4)
            s.rider.torso.angle = angle + lean + (attached ? 0 : 0.5)
            return s
        }
        var summary: [String: Any] = ["rider": rider.id, "renderer": "production SpriteKit rig via AppKit image adapter"]
        var maximumHandError: CGFloat = 0, maximumFootError: CGFloat = 0, maximumWaistError: CGFloat = 0
        var maximumAnkleError: CGFloat = 0, maximumCuffAngleError: CGFloat = 0
        var minimumBootAngle: CGFloat = .infinity, maximumBootAngle: CGFloat = -.infinity
        #if RIG_DIAGNOSTICS
        func measure(_ rig: RoccoRig) {
            guard let d = rig.attachmentDiagnostics() else { return }
            precondition(d.handErrorsMetres.count == 2 && d.footErrorsMetres.count == 2)
            maximumHandError = max(maximumHandError, d.handErrorsMetres.max() ?? 0)
            maximumFootError = max(maximumFootError, d.footErrorsMetres.max() ?? 0)
            maximumWaistError = max(maximumWaistError, d.waistErrorMetres)
            maximumAnkleError = max(maximumAnkleError, d.ankleErrorsMetres.max() ?? 0)
            maximumCuffAngleError = max(maximumCuffAngleError, d.bootToCalfAngleErrors.max() ?? 0)
            minimumBootAngle = min(minimumBootAngle, d.bootAngles.min() ?? 0)
            maximumBootAngle = max(maximumBootAngle, d.bootAngles.max() ?? 0)
        }
        #endif
        let poses: [(String, SimulationState)] = [
            ("neutral", state()), ("wheelie", state(angle: 0.7, lean: -0.15, shift: -0.06)),
            ("air", state(angle: 0.2, lean: 0.18, shift: 0.06, compression: -0.08)),
            ("landing", state(angle: -0.12, lean: -0.20, shift: -0.09, compression: 0.10)),
            ("inverted", state(angle: .pi, lean: 0.1)),
            ("detached", state(angle: 2.5, lean: 0.2, attached: false)),
        ]
        var poseBounds: [String: [String: Double]] = [:]
        for (name, s) in poses {
            let rig = RoccoRig()
            scene.addChild(rig)
            rig.display(s, rider: rider, pointsPerMetre: ppm, project: project, reducedMotion: false, seconds: 0)
            let bounds = rig.visibleBounds(in: scene)
            precondition(!bounds.isNull && bounds.width > 300 && bounds.height > 200)
            poseBounds[name] = ["x": bounds.minX, "y": bounds.minY, "width": bounds.width, "height": bounds.height]
            #if RIG_DIAGNOSTICS
            measure(rig)
            #endif
            fit(rig, in: scene)
            renderer.update(atTime: 1)
            let image = render(renderer, device: device, queue: queue, size: size)
            try save(image, to: output.appendingPathComponent(name + ".png"))
            rig.removeFromParent()
        }
        summary["poseBounds"] = poseBounds
        #if RIG_DIAGNOSTICS
        let rig = RoccoRig()
        scene.addChild(rig)
        let profile = RiderRigArtwork.manifest(for: rider.id)!.profile
        var previousLean: CGFloat?
        var maxLeanStep: CGFloat = 0
        // Two full rotations pass through both +/-pi boundaries while all four
        // painted contacts and the waist are measured from real node transforms.
        for frame in 0..<180 {
            let phase = Double(frame) / 179 * .pi * 4
            let angle = atan2(sin(phase), cos(phase))
            let s = state(angle: angle, lean: sin(phase * 0.8) * Double(profile.maxTorsoLean) * 0.85,
                          shift: cos(phase * 0.8) * Double(profile.maxPelvisShift) * 0.85,
                          compression: sin(phase * 1.7) * 0.08, tick: frame * 2)
            rig.position = .zero
            rig.setScale(1)
            rig.display(s, rider: rider, pointsPerMetre: ppm, project: project,
                        reducedMotion: false, seconds: Double(frame) / 60)
            measure(rig)
            let lean = rig.attachmentDiagnostics()!.torsoLean
            if let previousLean { maxLeanStep = max(maxLeanStep, abs(lean - previousLean)) }
            previousLean = lean
            if [30, 60, 90, 120, 150].contains(frame) {
                fit(rig, in: scene)
                renderer.update(atTime: Double(frame) / 60 + 2)
                try save(render(renderer, device: device, queue: queue, size: size),
                         to: output.appendingPathComponent(String(format: "motion-%03d.png", frame)))
            }
        }
        precondition(maximumHandError < 0.0015, "A palm left its grip: \(maximumHandError)m")
        precondition(maximumFootError < 0.0001, "A sole left its peg: \(maximumFootError)m")
        precondition(maximumWaistError < 0.0001, "Torso and pelvis separated: \(maximumWaistError)m")
        precondition(maxLeanStep <= profile.maxLeanSpeed / 60 + 0.00001, "Lean snapped around +/-pi")
        summary["motionFrames"] = 180
        summary["maximumHandErrorMetres"] = maximumHandError
        summary["maximumFootErrorMetres"] = maximumFootError
        summary["maximumWaistErrorMetres"] = maximumWaistError
        summary["maximumLeanStepRadians"] = maxLeanStep
        if profile.bootFollowsCalf {
            precondition(maximumAnkleError < 0.0001, "The shin left the boot cuff")
            precondition(maximumCuffAngleError < 0.000001, "The shin no longer enters the boot from above")
        }
        summary["boots"] = ["followsCalf": profile.bootFollowsCalf,
                            "maximumShinToCuffErrorMetres": maximumAnkleError,
                            "maximumCuffAngleErrorRadians": maximumCuffAngleError,
                            "minimumAngleFromChassisDegrees": minimumBootAngle * 180 / .pi,
                            "maximumAngleFromChassisDegrees": maximumBootAngle * 180 / .pi] as [String: Any]
        rig.removeFromParent()
        if profile.retainDetachPose {
            let transitionRig = RoccoRig()
            scene.addChild(transitionRig)
            var attached = state(angle: 0.30, lean: -0.15, shift: -0.04, tick: 240)
            attached.rider.pelvis.angle += 0.08
            transitionRig.display(attached, rider: rider, pointsPerMetre: ppm, project: project,
                                  reducedMotion: false, seconds: 4)
            // Change the input again so both visual filters lag the physical pose
            // at release. This catches retaining only a static calibration offset.
            attached = state(angle: 0.30, lean: 0.19, shift: 0.07, tick: 242)
            attached.rider.pelvis.angle += 0.08
            transitionRig.display(attached, rider: rider, pointsPerMetre: ppm, project: project,
                                  reducedMotion: false, seconds: 4 + 1.0 / 60)
            let before = transitionRig.bodyTransforms()
            renderer.update(atTime: 10)
            try save(render(renderer, device: device, queue: queue, size: size), to: output.appendingPathComponent("detach-before.png"))
            var detached = attached
            detached.rider.isAttached = false
            detached.tick += 2
            transitionRig.display(detached, rider: rider, pointsPerMetre: ppm, project: project,
                                  reducedMotion: false, seconds: 4 + 2.0 / 60)
            let after = transitionRig.bodyTransforms()
            var releaseError: CGFloat = 0, releaseAngleError: CGFloat = 0
            for key in ["pelvis", "torso"] {
                releaseError = max(releaseError, hypot(after[key]!.position.x - before[key]!.position.x,
                                                       after[key]!.position.y - before[key]!.position.y) / ppm)
                let angle = after[key]!.angle - before[key]!.angle
                releaseAngleError = max(releaseAngleError, abs(atan2(sin(angle), cos(angle))))
            }
            precondition(releaseError < 0.000001 && releaseAngleError < 0.000001, "Body artwork jumped at detachment")
            renderer.update(atTime: 11)
            try save(render(renderer, device: device, queue: queue, size: size), to: output.appendingPathComponent("detach-after.png"))
            let movedPPM: CGFloat = 385
            let movedProject: (Vector2) -> CGPoint = { CGPoint(x: 600 + CGFloat($0.x) * movedPPM, y: 640 + CGFloat($0.y) * movedPPM) }
            detached.tick += 2
            detached.rider.pelvis.position.x += 0.12
            detached.rider.pelvis.position.y += 0.08
            detached.rider.pelvis.angle += 0.31
            detached.rider.torso.position.x += 0.16
            detached.rider.torso.position.y += 0.10
            detached.rider.torso.angle -= 0.27
            transitionRig.display(detached, rider: rider, pointsPerMetre: movedPPM, project: movedProject,
                                  reducedMotion: false, seconds: 4 + 3.0 / 60)
            let moved = transitionRig.bodyTransforms()
            var followError: CGFloat = 0
            for (key, oldPhysical, newPhysical) in [("pelvis", attached.rider.pelvis, detached.rider.pelvis),
                                                    ("torso", attached.rider.torso, detached.rider.torso)] {
                let oldCentre = project(oldPhysical.position), newCentre = movedProject(newPhysical.position)
                let dx = (before[key]!.position.x - oldCentre.x) / ppm, dy = (before[key]!.position.y - oldCentre.y) / ppm
                let turn = CGFloat(newPhysical.angle - oldPhysical.angle)
                let expected = CGPoint(x: newCentre.x + (dx * cos(turn) - dy * sin(turn)) * movedPPM,
                                       y: newCentre.y + (dx * sin(turn) + dy * cos(turn)) * movedPPM)
                followError = max(followError, hypot(moved[key]!.position.x - expected.x, moved[key]!.position.y - expected.y) / movedPPM)
                let turnError = moved[key]!.angle - before[key]!.angle - turn
                precondition(abs(atan2(sin(turnError), cos(turnError))) < 0.000001)
            }
            precondition(followError < 0.000001, "Detached offsets changed with camera movement or body rotation")
            renderer.update(atTime: 12)
            try save(render(renderer, device: device, queue: queue, size: size), to: output.appendingPathComponent("detach-follow.png"))
            // A different seed/tick resets stale filtered offsets to the authored
            // neutral calibration when the first visible frame is detached.
            var newRun = state(attached: false)
            newRun.seed = 99
            transitionRig.display(newRun, rider: rider, pointsPerMetre: ppm, project: project,
                                  reducedMotion: false, seconds: 0)
            let reset = transitionRig.bodyTransforms()
            for (key, physical, centre, height) in [("pelvis", newRun.rider.pelvis, profile.pelvisCentre, CGFloat(0.10)),
                                                   ("torso", newRun.rider.torso, profile.torsoCentre, CGFloat(0.36))] {
                let p = project(physical.position), angle = CGFloat(physical.angle), dx = centre.x, dy = centre.y - height
                let expected = CGPoint(x: p.x + (dx * cos(angle) - dy * sin(angle)) * ppm,
                                       y: p.y + (dx * sin(angle) + dy * cos(angle)) * ppm)
                precondition(hypot(reset[key]!.position.x - expected.x, reset[key]!.position.y - expected.y) / ppm < 0.000001)
            }
            var reattached = state(lean: -0.08, shift: 0.02, tick: 4)
            reattached.seed = 99
            transitionRig.display(reattached, rider: rider, pointsPerMetre: ppm, project: project,
                                  reducedMotion: false, seconds: 4.0 / 120)
            let reattachedBefore = transitionRig.bodyTransforms()
            reattached.rider.isAttached = false
            reattached.tick += 2
            transitionRig.display(reattached, rider: rider, pointsPerMetre: ppm, project: project,
                                  reducedMotion: false, seconds: 6.0 / 120)
            let reattachedAfter = transitionRig.bodyTransforms()
            for key in ["pelvis", "torso"] {
                precondition(hypot(reattachedBefore[key]!.position.x - reattachedAfter[key]!.position.x,
                                   reattachedBefore[key]!.position.y - reattachedAfter[key]!.position.y) / ppm < 0.000001)
            }
            summary["detachment"] = ["maximumReleasePositionErrorMetres": releaseError,
                                      "maximumReleaseAngleErrorRadians": releaseAngleError,
                                      "maximumPhysicalFollowErrorMetres": followError,
                                      "cameraChangeAndRunResetPassed": true] as [String: Any]
            transitionRig.removeFromParent()
        }
        // Frozen simulation ticks still advance the cosmetic fall clock. The
        // second rig sees different camera/scenery values at every identical step.
        func wrapped(_ angle: Double) -> Double { atan2(sin(angle), cos(angle)) }
        func angleError(_ a: [RoccoRig.LimbDiagnostics], _ b: [RoccoRig.LimbDiagnostics]) -> Double {
            precondition(a.count == 4 && b.count == 4)
            return zip(a, b).map { max(abs(wrapped($0.upperAngle - $1.upperAngle)),
                                      abs(wrapped($0.lowerAngle - $1.lowerAngle))) }.max()!
        }
        var fallReports: [[String: Any]] = []
        for reduced in [false, true] {
            let fallRig = RoccoRig(), cameraRig = RoccoRig()
            scene.addChild(fallRig)
            var release = state(angle: 0.30, lean: 0.14, shift: 0.04, tick: 400)
            release.rider.pelvis.angularVelocity = 3.0
            release.rider.torso.angularVelocity = 3.4
            release.rider.pelvis.velocity = Vector2(x: 1.2, y: 1.4)
            release.rider.torso.velocity = release.rider.pelvis.velocity
            for sample in [fallRig, cameraRig] {
                sample.display(release, rider: rider, pointsPerMetre: ppm, project: project,
                               reducedMotion: reduced, seconds: 20, motionSeconds: 0)
            }
            let seeded = fallRig.limbDiagnostics()
            release.rider.isAttached = false
            for sample in [fallRig, cameraRig] {
                sample.display(release, rider: rider, pointsPerMetre: ppm, project: project,
                               reducedMotion: reduced, seconds: 21, motionSeconds: 0)
            }
            let seedError = angleError(seeded, fallRig.limbDiagnostics())
            precondition(seedError < 1e-9, "Release lost the attached limb angles")
            var maxJointError: CGFloat = 0, maxCameraError = 0.0, maxFreezeError = 0.0
            var minimumFlex = Array(repeating: Double.infinity, count: 4)
            var maximumFlex = Array(repeating: -Double.infinity, count: 4)
            var frames: [[String: Any]] = []
            for frame in 1...120 {
                let t = Double(frame) / 60
                var falling = release // tick deliberately remains 400 for the entire fall
                falling.bike = state(angle: 0.30 + t * 1.2, tick: 400).bike
                falling.rider.pelvis.position.x += 0.40 * t
                falling.rider.pelvis.position.y += 1.4 * t - 0.9 * t * t
                falling.rider.pelvis.angle += 3.0 * t
                falling.rider.pelvis.velocity = Vector2(x: 0.40, y: 1.4 - 1.8 * t)
                falling.rider.torso.position = Vector2(
                    x: falling.rider.pelvis.position.x - sin(3.0 * t) * 0.26,
                    y: falling.rider.pelvis.position.y + cos(3.0 * t) * 0.26)
                falling.rider.torso.angle += 3.0 * t + 0.18 * sin(t * 2)
                falling.rider.torso.angularVelocity = 3.0 + 0.36 * cos(t * 2)
                falling.rider.torso.velocity = Vector2(
                    x: 0.40 - cos(3.0 * t) * 0.78,
                    y: 1.4 - 1.8 * t - sin(3.0 * t) * 0.78)
                fallRig.position = .zero
                fallRig.setScale(1)
                fallRig.display(falling, rider: rider, pointsPerMetre: ppm, project: project,
                                reducedMotion: reduced, seconds: 21 + t, motionSeconds: t)
                let d = fallRig.limbDiagnostics()
                let bodies = fallRig.bodyTransforms()
                let cameraPPM: CGFloat = 340 + CGFloat(frame % 13) * 11
                let cameraProject: (Vector2) -> CGPoint = {
                    CGPoint(x: 420 + CGFloat(frame) * 3 + CGFloat($0.x) * cameraPPM,
                            y: 700 - CGFloat(frame) + CGFloat($0.y) * cameraPPM)
                }
                cameraRig.display(falling, rider: rider, pointsPerMetre: cameraPPM, project: cameraProject,
                                  reducedMotion: reduced, seconds: 100 + t * 3, motionSeconds: t)
                maxCameraError = max(maxCameraError, angleError(d, cameraRig.limbDiagnostics()))
                // Scenic time changes alone must not advance any detached limb.
                fallRig.display(falling, rider: rider, pointsPerMetre: ppm, project: project,
                                reducedMotion: reduced, seconds: 21 + t + 0.005, motionSeconds: t)
                maxFreezeError = max(maxFreezeError, angleError(d, fallRig.limbDiagnostics()))
                for (index, limb) in d.enumerated() {
                    maxJointError = max(maxJointError, limb.rootErrorMetres, limb.jointErrorMetres, limb.ankleErrorMetres)
                    let leg = index >= 2
                    let parent = Double(bodies[leg ? "pelvis" : "torso"]!.angle)
                    let low = leg ? -2.8 : -3.5, high = leg ? 0.65 : 1.2
                    let centre = (low + high) / 2
                    let relative = centre + wrapped(limb.upperAngle - parent - centre)
                    let flex = wrapped(limb.lowerAngle - limb.upperAngle) * (leg ? -1 : 1)
                    precondition(relative >= low - 1e-6 && relative <= high + 1e-6, "Detached root exceeded its limit")
                    precondition(flex >= 0.015 - 1e-6 && flex <= (leg ? 2.45 : 2.65) + 1e-6, "Detached hinge exceeded its limit")
                    minimumFlex[index] = min(minimumFlex[index], flex)
                    maximumFlex[index] = max(maximumFlex[index], flex)
                }
                if frame.isMultiple(of: 10) {
                    let bounds = fallRig.visibleBounds(in: scene)
                    precondition(!bounds.isNull && bounds.width.isFinite && bounds.height.isFinite)
                    frames.append(["frame": frame, "motionSeconds": t, "tick": falling.tick,
                                   "upperAngles": d.map(\.upperAngle), "lowerAngles": d.map(\.lowerAngle),
                                   "bounds": [bounds.minX, bounds.minY, bounds.width, bounds.height]])
                    if !reduced {
                        fit(fallRig, in: scene)
                        renderer.update(atTime: 30 + t)
                        try save(render(renderer, device: device, queue: queue, size: size),
                                 to: output.appendingPathComponent(String(format: "fall-%03d.png", frame)))
                    }
                }
            }
            let flexRanges = zip(maximumFlex, minimumFlex).map { $0 - $1 }
            precondition(flexRanges.allSatisfy { $0 > 0.10 }, "Detached limbs remained rigid")
            precondition(maxJointError < 1e-6, "Detached limb joints separated")
            precondition(maxCameraError < 1e-9 && maxFreezeError < 1e-9, "Camera or scenic time changed fall motion")
            // Reattachment seeds fresh angles and speeds; a second release must
            // behave exactly like a new rig, with no residual first-fall motion.
            let freshRig = RoccoRig()
            var again = state(angle: -0.40, lean: -0.12, shift: 0.03, tick: 401)
            again.rider.pelvis.angularVelocity = -2.4
            again.rider.torso.angularVelocity = -3.1
            fallRig.position = .zero
            fallRig.setScale(1)
            for sample in [fallRig, freshRig] {
                sample.display(again, rider: rider, pointsPerMetre: ppm, project: project,
                               reducedMotion: reduced, seconds: 23.02, motionSeconds: 2.02)
            }
            precondition(angleError(fallRig.limbDiagnostics(), freshRig.limbDiagnostics()) < 1e-9,
                         "Reattachment retained old fall angles")
            again.rider.isAttached = false
            var repeatError = 0.0
            for step in 0...12 {
                let t = 2.02 + Double(step) / 60
                for sample in [fallRig, freshRig] {
                    sample.display(again, rider: rider, pointsPerMetre: ppm, project: project,
                                   reducedMotion: reduced, seconds: 23.02 + Double(step) / 60, motionSeconds: t)
                }
                repeatError = max(repeatError, angleError(fallRig.limbDiagnostics(), freshRig.limbDiagnostics()))
            }
            precondition(repeatError < 1e-9, "Repeated release retained stale motion")
            fallReports.append(["reducedMotion": reduced, "frames": 120, "durationSeconds": 2,
                                "frozenTick": 400, "releaseAngleErrorRadians": seedError,
                                "maximumJointErrorMetres": maxJointError,
                                "maximumCameraAngleErrorRadians": maxCameraError,
                                "maximumFrozenClockAngleErrorRadians": maxFreezeError,
                                "maximumRepeatedReleaseAngleErrorRadians": repeatError,
                                "hingeMotionRangesRadians": flexRanges, "samples": frames])
            fallRig.removeFromParent()
        }
        summary["dynamicDetachedMotion"] = fallReports
        guard let catalog = RiderRigPreview.image(for: rider),
              let catalogCG = catalog.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            preconditionFailure("Missing cached catalog snapshot")
        }
        precondition(catalog === RiderRigPreview.image(for: rider), "Catalog snapshot was not cached")
        try save(catalogCG, to: output.appendingPathComponent("catalog.png"))
        summary["catalogSize"] = ["width": catalogCG.width, "height": catalogCG.height]
        #endif
        summary["status"] = "passed"
        let json = try JSONSerialization.data(withJSONObject: summary, options: [.prettyPrinted, .sortedKeys])
        try json.write(to: output.appendingPathComponent("contacts-and-bounds.json"))
        print(String(data: json, encoding: .utf8)!)
    }

    @MainActor static func fit(_ rig: RoccoRig, in scene: SKScene) {
        let bounds = rig.visibleBounds(in: scene)
        let scale = min(1, (scene.size.width - 140) / bounds.width, (scene.size.height - 140) / bounds.height)
        rig.setScale(scale)
        let scaled = rig.visibleBounds(in: scene)
        rig.position = CGPoint(x: scene.size.width / 2 - scaled.midX, y: scene.size.height / 2 - scaled.midY)
    }

    @MainActor static func render(_ renderer: SKRenderer, device: MTLDevice, queue: MTLCommandQueue, size: CGSize) -> CGImage {
        let width = Int(size.width), height = Int(size.height)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared
        let texture = device.makeTexture(descriptor: descriptor)!
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0.84, green: 0.84, blue: 0.84, alpha: 1)
        let buffer = queue.makeCommandBuffer()!
        renderer.render(withViewport: CGRect(origin: .zero, size: size), commandBuffer: buffer, renderPassDescriptor: pass)
        buffer.commit(); buffer.waitUntilCompleted()
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        texture.getBytes(&pixels, bytesPerRow: width * 4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
    }

    static func save(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            throw NSError(domain: "RiderPreview", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot write \(url.path)"])
        }
        CGImageDestinationAddImage(destination, image, nil)
        precondition(CGImageDestinationFinalize(destination))
    }
}
