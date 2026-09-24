#!/usr/bin/env swift
import Foundation
import CoreGraphics
import ImageIO

// Run from the repository root: swift scripts/check-rocco-assets.swift [root] [--rider croco|shiba]
// The no-argument Rocco command remains compatible. Reads the renderer manifest; never rewrites PNGs.
struct Point: Decodable {
    let x: Double, y: Double
    static func + (a: Point, b: Point) -> Point { Point(x: a.x + b.x, y: a.y + b.y) }
    func rotated(_ angle: Double) -> Point {
        Point(x: x * cos(angle) - y * sin(angle), y: x * sin(angle) + y * cos(angle))
    }
    func distance(to other: Point) -> Double { hypot(other.x - x, other.y - y) }
}
struct Bounds: Decodable { let x: Double, y: Double, width: Double, height: Double }
struct Size: Decodable { let width: Int, height: Int }
struct Span: Decodable { let from: Point, to: Point, metres: Double }
struct Part: Decodable {
    let part: String, assetName: String
    let sourceSize: Size
    let visibleBounds: Bounds
    let landmarks: [String: Point]
    let calibration: Span
    let orientation: Span?
    var scale: Double {
        calibration.metres / hypot((calibration.to.x - calibration.from.x) * Double(sourceSize.width),
                                   (calibration.to.y - calibration.from.y) * Double(sourceSize.height))
    }
    var rotation: Double {
        guard let orientation else { return 0 }
        return -atan2(-(orientation.to.y - orientation.from.y) * Double(sourceSize.height),
                       (orientation.to.x - orientation.from.x) * Double(sourceSize.width))
    }
    func local(_ name: String) -> Point {
        precondition(landmarks[name] != nil, "Missing \(part).\(name) landmark")
        let p = landmarks[name]!, pivot = landmarks["pivot"]!
        return Point(x: (p.x - pivot.x) * Double(sourceSize.width) * scale,
                     y: -(p.y - pivot.y) * Double(sourceSize.height) * scale).rotated(rotation)
    }
}
struct Rig: Decodable {
    let wheelbaseMetres: Double
    let pelvisCentre: Point, torsoCentre: Point
    let pelvisTravel: Double, torsoAngleTravel: Double
}
struct Presentation: Decodable {
    let bootFollowsCalf: Bool?
    let bootAngleOffset: Double?
    let retainDetachPose: Bool?
    let maxTorsoLean: Double?, maxPelvisShift: Double?, upperArmThickness: Double?, pelvisCropMaxX: Double?
    let farArmOffset: Point?, farLegOffset: Point?
    let smoothingTime: Double?, maxLeanSpeed: Double?, maxShiftSpeed: Double?
    let depths: [String: Double]?
}
struct Manifest: Decodable {
    let schemaVersion: Int, rig: Rig, parts: [Part]
    let presentation: Presentation?
}

func check(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw NSError(domain: "RiderAssetCheck", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
}

func symmetricSamples(limit: Double, step: Double) -> [Double] {
    var values = Array(stride(from: -limit, through: limit, by: step))
    if let last = values.last, abs(last - limit) < 0.000000001 {
        values[values.count - 1] = limit
    } else { values.append(limit) }
    return values
}

do {
    var arguments = Array(CommandLine.arguments.dropFirst())
    var riderID = "croco"
    if let flag = arguments.firstIndex(of: "--rider") {
        try check(arguments.indices.contains(flag + 1), "--rider requires croco or shiba")
        riderID = arguments[flag + 1]
        arguments.removeSubrange(flag ... flag + 1)
    }
    try check(["croco", "rocco", "shiba"].contains(riderID), "Supported rigs: croco, shiba")
    try check(arguments.count <= 1, "Usage: check-rocco-assets.swift [root] [--rider croco|shiba]")
    let rocco = riderID != "shiba"
    let prefix = rocco ? "rocco" : "shiba"
    let root = URL(fileURLWithPath: arguments.first ?? FileManager.default.currentDirectoryPath)
    let directory = root.appendingPathComponent("App/Resources/GameAssets/" + (rocco ? "RoccoRig" : "ShibaRig"), isDirectory: true)
    let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: directory.appendingPathComponent("manifest.json")))
    try check(manifest.schemaVersion == 1, "Unsupported rider manifest version")
    let required: Set<String> = ["bike", "torso", "pelvis", "upper-arm", "forearm", "thigh", "calf", "boot", "fork", "swingarm", "wheel"]
    try check(Set(manifest.parts.map(\.part)).isSuperset(of: required), "Missing required rider parts")
    try check(Set(manifest.parts.map(\.part)).count == manifest.parts.count, "Duplicate part identifiers")
    let requiredAnchors: [String: Set<String>] = [
        "bike": ["pivot", "rearAxle", "frontAxle", "grip", "footpeg", "steeringTop", "swingPivot"],
        "torso": ["pivot", "shoulder", "spine"], "pelvis": ["pivot", "hip", "spine"],
        "upper-arm": ["pivot", "proximal", "distal"], "forearm": ["pivot", "proximal", "distal", "contact"],
        "thigh": ["pivot", "proximal", "distal"], "calf": ["pivot", "proximal", "distal"],
        "boot": ["pivot", "contact"], "fork": ["pivot", "proximal", "distal"],
        "swingarm": ["pivot", "proximal", "distal"], "wheel": ["pivot"],
    ]
    let presentation = manifest.presentation
    let maxLean = presentation?.maxTorsoLean ?? 0.35
    let maxShift = presentation?.maxPelvisShift ?? 0.14
    let bootAngleOffset = presentation?.bootAngleOffset ?? 0
    try check(bootAngleOffset.isFinite && abs(bootAngleOffset) <= .pi, "Invalid boot angle offset")
    for value in [maxLean, maxShift, presentation?.upperArmThickness ?? 1,
                  presentation?.smoothingTime ?? 0.065, presentation?.maxLeanSpeed ?? 2.5,
                  presentation?.maxShiftSpeed ?? 0.8] {
        try check(value.isFinite && value > 0, "Presentation limits must be finite and positive")
    }
    if let crop = presentation?.pelvisCropMaxX {
        try check(crop.isFinite && crop > 0 && crop <= 1, "Invalid pelvis crop")
    }
    if !rocco {
        try check(abs(maxLean - manifest.rig.torsoAngleTravel) < 0.000001 &&
                  abs(maxShift - manifest.rig.pelvisTravel) < 0.000001,
                  "Kenji validation envelope must match presentation motion limits")
    }
    var report: [[String: Any]] = []
    for part in manifest.parts {
        try check(part.assetName == prefix + "-" + part.part, "Unexpected source path for \(part.part)")
        try check(Set(part.landmarks.keys).isSuperset(of: requiredAnchors[part.part] ?? ["pivot"]),
                  "Missing required \(part.part) landmarks")
        if let proximal = part.landmarks["proximal"], let distal = part.landmarks["distal"] {
            try check(part.landmarks["pivot"]!.distance(to: proximal) < 0.000001 &&
                      part.calibration.from.distance(to: proximal) < 0.000001 &&
                      part.calibration.to.distance(to: distal) < 0.000001,
                      "\(part.part) pivot/calibration must use the same joint centres")
            guard let orientation = part.orientation else {
                throw NSError(domain: "RiderAssetCheck", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing \(part.part) orientation"])
            }
            try check(orientation.from.distance(to: proximal) < 0.000001 && orientation.to.distance(to: distal) < 0.000001,
                      "\(part.part) orientation does not match its joints")
        }
        if part.part == "forearm" {
            try check(part.landmarks["contact"]!.distance(to: part.landmarks["distal"]!) < 0.000001,
                      "The forearm distal joint must be its palm contact")
        }
        for point in Array(part.landmarks.values) + [part.calibration.from, part.calibration.to] {
            try check(point.x.isFinite && point.y.isFinite && (0...1).contains(point.x) && (0...1).contains(point.y),
                      "Landmark outside the source canvas: \(part.part)")
        }
        try check(part.scale.isFinite && part.scale > 0 && part.calibration.metres > 0 && part.calibration.metres < 3,
                  "Invalid calibration for \(part.part)")
        let url = directory.appendingPathComponent(part.assetName + ".png")
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil), let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw NSError(domain: "RiderAssetCheck", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot read \(url.path)"])
        }
        try check(image.width == part.sourceSize.width && image.height == part.sourceSize.height,
                  "\(part.part) source dimensions changed; recalibrate the manifest")
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        pixels.withUnsafeMutableBytes { bytes in
            let context = CGContext(data: bytes.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                    bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        let bounds = part.visibleBounds
        try check(bounds.x >= 0 && bounds.y >= 0 && bounds.width > 0 && bounds.height > 0 &&
                  bounds.x + bounds.width <= 1.000001 && bounds.y + bounds.height <= 1.000001,
                  "Invalid visible bounds for \(part.part)")
        var minX = width, minY = height, maxX = 0, maxY = 0
        for y in 0 ..< height {
            for x in 0 ..< width where pixels[(y * width + x) * 4 + 3] >= 16 {
                minX = min(minX, x); minY = min(minY, y); maxX = max(maxX, x); maxY = max(maxY, y)
            }
        }
        try check(abs(bounds.x * Double(width) - Double(max(0, minX - 2))) < 0.01 &&
                  abs(bounds.y * Double(height) - Double(max(0, minY - 2))) < 0.01 &&
                  abs((bounds.x + bounds.width) * Double(width) - Double(min(width, maxX + 3))) < 0.01 &&
                  abs((bounds.y + bounds.height) * Double(height) - Double(min(height, maxY + 3))) < 0.01,
                  "Painted bounds changed for \(part.part); recalibrate camera bounds")
        var transparent = 0, visible = 0
        var minimumAlpha: UInt8 = 255, maximumAlpha: UInt8 = 0
        for index in stride(from: 3, to: pixels.count, by: 4) {
            let alpha = pixels[index]
            transparent += alpha == 0 ? 1 : 0
            visible += alpha >= 128 ? 1 : 0
            minimumAlpha = min(minimumAlpha, alpha); maximumAlpha = max(maximumAlpha, alpha)
        }
        try check(minimumAlpha == 0 && maximumAlpha >= 240, "\(part.part) lacks usable transparent/visible pixels")
        try check(transparent > width * height / 10 && visible > width * height / 100,
                  "\(part.part) is empty or has a baked opaque background")
        let corners = [0, width - 1, (height - 1) * width, height * width - 1]
        try check(corners.allSatisfy { pixels[$0 * 4 + 3] <= 2 }, "\(part.part) has an opaque canvas corner")
        if part.part == "wheel" {
            try check(abs(part.calibration.metres - 0.64) < 0.00001, "Wheel diameter must stay 0.64m")
            let pivot = part.landmarks["pivot"]!
            var spokeArea = 0, spokeHoles = 0
            for y in 0 ..< height {
                for x in 0 ..< width {
                    let radius = hypot(Double(x) - pivot.x * Double(width), Double(y) - pivot.y * Double(height)) * part.scale
                    if (0.12 ... 0.19).contains(radius) {
                        spokeArea += 1
                        if pixels[(y * width + x) * 4 + 3] == 0 { spokeHoles += 1 }
                    }
                }
            }
            try check(spokeHoles > spokeArea / 2, "Wheel spokes contain a baked background")
        }
        report.append(["part": part.part, "width": width, "height": height,
                       "transparentFraction": Double(transparent) / Double(width * height),
                       "metresPerPixel": part.scale])
    }
    let parts = Dictionary(uniqueKeysWithValues: manifest.parts.map { ($0.part, $0) })
    let bike = parts["bike"]!, pelvis = parts["pelvis"]!, torso = parts["torso"]!
    try check(abs(bike.local("rearAxle").distance(to: bike.local("frontAxle")) - manifest.rig.wheelbaseMetres) < 0.0001,
              "Artwork no longer matches the physical wheelbase")
    let farArm = presentation?.farArmOffset ?? Point(x: rocco ? 0.045 : 0.025, y: -0.015)
    let farLeg = presentation?.farLegOffset ?? Point(x: -0.035, y: 0.025)
    for point in [farArm, farLeg, manifest.rig.pelvisCentre, manifest.rig.torsoCentre] {
        try check(point.x.isFinite && point.y.isFinite, "Invalid body or depth offset")
    }
    let pelvisSpine = manifest.rig.pelvisCentre + pelvis.local("spine")
    let torsoSpine = manifest.rig.torsoCentre + torso.local("spine")
    try check(pelvisSpine.distance(to: torsoSpine) < 0.002, "Torso and pelvis artwork do not meet at their physical spine joint")
    var armReach = 0.0, legReach = 0.0, testedPoses = 0
    let armA = parts["upper-arm"]!.calibration.metres, armB = parts["forearm"]!.calibration.metres
    let legA = parts["thigh"]!.calibration.metres, legB = parts["calf"]!.calibration.metres
    let sole = parts["boot"]!.local("contact")
    let followsCalf = presentation?.bootFollowsCalf ?? false
    let effectiveLegB = followsCalf ? hypot(legB - sole.y, sole.x) : legB
    let ankle = followsCalf ? bike.local("footpeg") : bike.local("footpeg") + Point(x: -sole.x, y: -sole.y).rotated(bootAngleOffset)
    for translation in symmetricSamples(limit: manifest.rig.pelvisTravel, step: 0.01) {
        for angle in symmetricSamples(limit: manifest.rig.torsoAngleTravel, step: 0.025) {
            let shift = Point(x: translation, y: 0)
            let spine = pelvisSpine + shift
            let centreToSpine = torso.local("spine")
            let centre = spine + Point(x: -centreToSpine.x, y: -centreToSpine.y).rotated(angle)
            let shoulder = centre + torso.local("shoulder").rotated(angle)
            let hip = manifest.rig.pelvisCentre + shift + pelvis.local("hip")
            for armOffset in [Point(x: 0, y: 0), farArm] {
                let armDistance = (shoulder + armOffset.rotated(angle)).distance(to: bike.local("grip") + armOffset)
                try check(armDistance < armA + armB - 0.00001 && armDistance > abs(armA - armB),
                          "Unreachable handlebar within rider posture envelope at shift \(translation), lean \(angle)")
                armReach = max(armReach, armDistance)
            }
            for legOffset in [Point(x: 0, y: 0), farLeg] {
                let legDistance = (hip + legOffset).distance(to: ankle + legOffset)
                try check(legDistance < legA + effectiveLegB - 0.00001 && legDistance > abs(legA - effectiveLegB),
                          "Unreachable footpeg within rider posture envelope")
                legReach = max(legReach, legDistance)
            }
            testedPoses += 1
        }
    }
    let result: [String: Any] = ["status": "passed", "rider": riderID, "assets": report, "postureSamples": testedPoses,
                                "testedTorsoLean": manifest.rig.torsoAngleTravel, "testedPelvisShift": manifest.rig.pelvisTravel,
                                "maximumArmReach": armReach, "maximumLegReach": legReach,
                                "armLength": armA + armB, "legLength": legA + legB,
                                "effectiveLegReach": legA + effectiveLegB, "bootFollowsCalf": followsCalf]
    print(String(data: try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]), encoding: .utf8)!)
} catch {
    FileHandle.standardError.write(Data(("Rider asset check failed: \(error.localizedDescription)\n").utf8))
    exit(1)
}
