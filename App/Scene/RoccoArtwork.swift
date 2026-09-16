import SpriteKit
import UIKit

/// One source of truth for the separated Rocco sprites. Coordinates use the PNG's
/// top-left origin; pivots and attachment landmarks stay normalized when artwork
/// is re-exported at another resolution. The renderer never edits the source PNGs.
@MainActor
enum RoccoArtwork {
    enum Part: String, CaseIterable {
        case bike, torso, pelvis, fork, swingarm, wheel
        case upperArm = "upper-arm", forearm, thigh, calf, boot
        var assetName: String { "rocco-" + rawValue }
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
            precondition(landmarks[anchor] != nil, "Missing Rocco landmark: \(part).\(anchor)")
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

    /// The same manifest is consumed by scripts/check-rocco-assets.swift.
    /// Art calibration is data, so changing an image does not change the rig math.
    static let manifest: [Part: Entry] = {
        guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json", subdirectory: "GameAssets/RoccoRig"),
              let data = try? Data(contentsOf: url), let document = try? JSONDecoder().decode(Document.self, from: data),
              document.schemaVersion == 1 else {
            assertionFailure("The bundled Rocco rig manifest is missing or invalid. Run scripts/check-rocco-assets.swift.")
            return [:]
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
        return entries
    }()

    private struct Document: Decodable { let schemaVersion: Int; let parts: [SourceEntry] }
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

    private static var cache: [Part: Loaded] = [:]

    static func load(_ part: Part) -> Loaded? {
        if let cached = cache[part] { return cached }
        guard let entry = manifest[part] else {
            assertionFailure("Rocco manifest is missing \(part.rawValue).")
            return nil
        }
        guard
              let url = Bundle.main.url(forResource: part.assetName, withExtension: "png", subdirectory: "GameAssets/RoccoRig"),
              let image = UIImage(contentsOfFile: url.path) else {
            assertionFailure("Missing Rocco sprite: \(part.assetName).")
            return nil
        }
        guard image.size == entry.sourceSize else {
            assertionFailure("\(part.assetName) canvas \(image.size) differs from manifest \(entry.sourceSize). Recalibrate the manifest.")
            return nil
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        let loaded = Loaded(entry: entry, texture: texture, sourceSize: image.size)
        cache[part] = loaded
        return loaded
    }
}
