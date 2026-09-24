import SpriteKit
import UIKit

/// One source of truth for every separated rider rig. Coordinates use the PNG's
/// top-left origin; pivots and attachment landmarks stay normalized when artwork
/// is re-exported at another resolution. The renderer never edits the source PNGs.
@MainActor
enum RiderRigArtwork {
    enum Part: String, CaseIterable {
        case bike, torso, pelvis, fork, swingarm, wheel
        case upperArm = "upper-arm", forearm, thigh, calf, boot
    }

    enum Anchor: String {
        case pivot, rearAxle, frontAxle, grip, footpeg, steeringTop, swingPivot
        case shoulder, hip, spine, proximal, distal, contact
    }

    struct Span {
        let from: CGPoint
        let to: CGPoint
        let metres: CGFloat
    }

    struct Entry {
        let part: Part
        let sourceSize: CGSize
        let visibleBounds: CGRect
        let landmarks: [Anchor: CGPoint]
        let calibration: Span
        /// The source's reference direction, measured in source image coordinates.
        /// Chassis art uses its axle line; limbs use their two joint centres.
        let orientation: Span?

        func point(_ anchor: Anchor) -> CGPoint {
            precondition(landmarks[anchor] != nil, "Missing rider rig landmark: \(part).\(anchor)")
            return landmarks[anchor]!
        }

        func metresPerPixel(in size: CGSize) -> CGFloat {
            let a = calibration.from, b = calibration.to
            return calibration.metres / max(1, hypot((b.x - a.x) * size.width, (b.y - a.y) * size.height))
        }

        func neutralRotation(in size: CGSize) -> CGFloat {
            guard let orientation else { return 0 }
            return -atan2(-(orientation.to.y - orientation.from.y) * size.height,
                          (orientation.to.x - orientation.from.x) * size.width)
        }
    }

    struct Profile {
        let pelvisCentre: CGPoint
        let torsoCentre: CGPoint
        let retainDetachPose: Bool
        let bootFollowsCalf: Bool
        let bootAngleOffset: CGFloat
        let upperArmThickness: CGFloat
        let pelvisCropMaxX: CGFloat?
        let farArmOffset: CGPoint
        let farLegOffset: CGPoint
        let maxTorsoLean: CGFloat
        let maxPelvisShift: CGFloat
        let smoothingTime: CGFloat
        let maxLeanSpeed: CGFloat
        let maxShiftSpeed: CGFloat
        let depths: [String: CGFloat]

        func depth(_ name: String, default fallback: CGFloat) -> CGFloat { depths[name] ?? fallback }
    }

    struct Manifest {
        let parts: [Part: Entry]
        let profile: Profile
    }

    static func supports(_ riderID: String) -> Bool { directory(for: riderID) != nil }

    private static func directory(for riderID: String) -> String? {
        switch riderID {
        case "croco": "RoccoRig"
        case "shiba": "ShibaRig"
        default: nil
        }
    }

    private static func prefix(for riderID: String) -> String { riderID == "croco" ? "rocco" : riderID }
    private static var manifests: [String: Manifest] = [:]

    /// The same manifest is consumed by scripts/check-rocco-assets.swift.
    /// Rocco's historical adjustments stay confined to its profile; new riders
    /// use their own calibration without inheriting its cropping or muscle scale.
    static func manifest(for riderID: String) -> Manifest? {
        if let cached = manifests[riderID] { return cached }
        guard let directory = directory(for: riderID) else { return nil }
        guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json", subdirectory: "GameAssets/" + directory),
              let data = try? Data(contentsOf: url), let document = try? JSONDecoder().decode(Document.self, from: data),
              document.schemaVersion == 1 else {
            assertionFailure("The bundled \(riderID) rig manifest is missing or invalid. Run scripts/check-rocco-assets.swift --rider \(riderID).")
            return nil
        }
        var entries: [Part: Entry] = [:]
        for source in document.parts {
            guard let part = Part(rawValue: source.part) else { continue }
            let landmarks = Dictionary(uniqueKeysWithValues: source.landmarks.compactMap { key, value in
                Anchor(rawValue: key).map { ($0, value.point) }
            })
            entries[part] = Entry(part: part, sourceSize: CGSize(width: source.sourceSize.width, height: source.sourceSize.height),
                                  visibleBounds: source.visibleBounds.rect, landmarks: landmarks, calibration: source.calibration.span, orientation: source.orientation?.span)
        }
        let p = document.presentation
        let rocco = riderID == "croco"
        let profile = Profile(pelvisCentre: document.rig?.pelvisCentre.point ?? CGPoint(x: 0, y: 0.10),
                              torsoCentre: document.rig?.torsoCentre?.point ?? CGPoint(x: 0, y: 0.36),
                              retainDetachPose: p?.retainDetachPose ?? false,
                              bootFollowsCalf: p?.bootFollowsCalf ?? false,
                              bootAngleOffset: p?.bootAngleOffset ?? 0,
                              upperArmThickness: p?.upperArmThickness ?? (rocco ? 1.8 : 1),
                              pelvisCropMaxX: p?.pelvisCropMaxX ?? (rocco ? 0.82 : nil),
                              farArmOffset: p?.farArmOffset?.point ?? CGPoint(x: rocco ? 0.045 : 0.025, y: -0.015),
                              farLegOffset: p?.farLegOffset?.point ?? CGPoint(x: -0.035, y: 0.025),
                              maxTorsoLean: p?.maxTorsoLean ?? 0.35,
                              maxPelvisShift: p?.maxPelvisShift ?? 0.14,
                              smoothingTime: p?.smoothingTime ?? 0.065,
                              maxLeanSpeed: p?.maxLeanSpeed ?? 2.5,
                              maxShiftSpeed: p?.maxShiftSpeed ?? 0.8,
                              depths: p?.depths ?? [:])
        guard Part.allCases.allSatisfy({ entries[$0] != nil }), profile.upperArmThickness > 0,
              profile.smoothingTime > 0, profile.maxTorsoLean >= 0, profile.maxPelvisShift >= 0 else {
            assertionFailure("Incomplete or invalid \(riderID) rig configuration.")
            return nil
        }
        let manifest = Manifest(parts: entries, profile: profile)
        manifests[riderID] = manifest
        return manifest
    }

    private struct Document: Decodable {
        let schemaVersion: Int
        let rig: SourceRig?
        let presentation: SourcePresentation?
        let parts: [SourceEntry]
    }
    private struct SourceRig: Decodable { let pelvisCentre: SourcePoint; let torsoCentre: SourcePoint? }
    private struct SourcePresentation: Decodable {
        let retainDetachPose: Bool?
        let bootFollowsCalf: Bool?
        let bootAngleOffset: CGFloat?
        let upperArmThickness: CGFloat?
        let pelvisCropMaxX: CGFloat?
        let farArmOffset: SourcePoint?
        let farLegOffset: SourcePoint?
        let maxTorsoLean: CGFloat?
        let maxPelvisShift: CGFloat?
        let smoothingTime: CGFloat?
        let maxLeanSpeed: CGFloat?
        let maxShiftSpeed: CGFloat?
        let depths: [String: CGFloat]?
    }
    private struct SourcePoint: Decodable {
        let x: CGFloat, y: CGFloat
        var point: CGPoint { CGPoint(x: x, y: y) }
    }
    private struct SourceSize: Decodable { let width: CGFloat, height: CGFloat }
    private struct SourceRect: Decodable {
        let x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat
        var rect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
    }
    private struct SourceSpan: Decodable {
        let from: SourcePoint, to: SourcePoint, metres: CGFloat
        var span: Span { Span(from: from.point, to: to.point, metres: metres) }
    }
    private struct SourceEntry: Decodable {
        let part: String
        let sourceSize: SourceSize
        let visibleBounds: SourceRect
        let landmarks: [String: SourcePoint]
        let calibration: SourceSpan
        let orientation: SourceSpan?
    }

    struct Loaded {
        let entry: Entry
        let texture: SKTexture
        let sourceSize: CGSize
        var metresPerPixel: CGFloat { entry.metresPerPixel(in: sourceSize) }
        var neutralRotation: CGFloat { entry.neutralRotation(in: sourceSize) }

        func local(_ anchor: Anchor) -> CGPoint {
            let p = entry.point(anchor), pivot = entry.point(.pivot)
            let x = (p.x - pivot.x) * sourceSize.width * metresPerPixel
            let y = -(p.y - pivot.y) * sourceSize.height * metresPerPixel
            let angle = neutralRotation
            return CGPoint(x: x * cos(angle) - y * sin(angle), y: x * sin(angle) + y * cos(angle))
        }
    }

    private static var cache: [String: [Part: Loaded]] = [:]

    static func load(_ part: Part, riderID: String = "croco") -> Loaded? {
        if let cached = cache[riderID]?[part] { return cached }
        guard let directory = directory(for: riderID), let entry = manifest(for: riderID)?.parts[part] else {
            assertionFailure("\(riderID) manifest is missing \(part.rawValue).")
            return nil
        }
        let assetName = prefix(for: riderID) + "-" + part.rawValue
        guard
              let url = Bundle.main.url(forResource: assetName, withExtension: "png", subdirectory: "GameAssets/" + directory),
              let image = UIImage(contentsOfFile: url.path) else {
            assertionFailure("Missing rider sprite: \(assetName).")
            return nil
        }
        guard image.size == entry.sourceSize else {
            assertionFailure("\(assetName) canvas \(image.size) differs from manifest \(entry.sourceSize). Recalibrate the manifest.")
            return nil
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        let loaded = Loaded(entry: entry, texture: texture, sourceSize: image.size)
        cache[riderID, default: [:]][part] = loaded
        return loaded
    }
}

// Kept for local diagnostics written against the original Rocco implementation.
typealias RoccoArtwork = RiderRigArtwork
