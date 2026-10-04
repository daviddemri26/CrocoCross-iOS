import Foundation

/// A closed horizontal interval occupied by real ground. Intervals are clipped
/// to the requested view; the open space between consecutive intervals is void.
public struct TerrainSpan: Equatable, Sendable {
    public let lowerBound: Double
    public let upperBound: Double
    public init(lowerBound: Double, upperBound: Double) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
}

/// Independent sections have matching height, slope and curvature at their boundaries.
/// Sampling far ahead neither allocates preceding sections nor advances a random generator.
public struct TerrainGenerator: Codable, Sendable {
    public static let sectionLength = 64.0
    public static let japanSectionLength = 60.0
    public static let jungleSectionLength = 132.0
    public static let jungleDescentGrade = 0.10
    public static let entryLength = 24.0
    /// Descending run-outs let gravity carry speed through the course. All jumps
    /// still come from the terrain and tire contact; no launch impulse is needed.
    public static let descentGrade = 0.16
    private static let entryHeight = -0.5 * descentGrade * (entryLength - 12)
    public let seed: UInt32
    public let style: PhysicsConfiguration.TerrainStyle

    public init(seed: UInt32, style: PhysicsConfiguration.TerrainStyle = .hills) {
        self.seed = seed
        self.style = style
    }

    public func height(at x: Double) -> Double { sample(at: x).height }

    /// Evaluate the same smooth curve as height, rather than differencing nearby
    /// samples. The contact normal stays continuous even at profile boundaries.
    public func slope(at x: Double) -> Double { sample(at: x).slope }

    public func isSolid(at x: Double) -> Bool {
        guard x.isFinite else { return false }
        guard style == .junglePlatforms, x >= Self.entryLength else { return true }
        let section = floor((x - Self.entryLength) / Self.jungleSectionLength)
        let local = x - Self.entryLength - section * Self.jungleSectionLength
        let gap = jungleGap(section: section)
        return local <= gap.lowerBound || local >= gap.upperBound
    }

    public func solidSpans(from lower: Double, to upper: Double) -> [TerrainSpan] {
        guard lower.isFinite, upper.isFinite, lower < upper else { return [] }
        guard style == .junglePlatforms, upper > Self.entryLength else {
            return [.init(lowerBound: lower, upperBound: upper)]
        }
        var spans: [TerrainSpan] = []
        var cursor = lower
        var section = max(0, floor((lower - Self.entryLength) / Self.jungleSectionLength))
        while Self.entryLength + section * Self.jungleSectionLength < upper {
            let start = Self.entryLength + section * Self.jungleSectionLength
            let localGap = jungleGap(section: section)
            let gapStart = start + localGap.lowerBound, gapEnd = start + localGap.upperBound
            if gapEnd > lower && gapStart < upper {
                if cursor < gapStart { spans.append(.init(lowerBound: cursor, upperBound: min(gapStart, upper))) }
                cursor = max(cursor, gapEnd)
            }
            let next = section + 1
            guard next > section else { break }
            section = next
        }
        if cursor < upper { spans.append(.init(lowerBound: cursor, upperBound: upper)) }
        return spans
    }

    private func sample(at x: Double) -> (height: Double, slope: Double) {
        if style == .junglePlatforms { return jungleSample(at: x) }
        if style == .japanMountains { return japanSample(at: x) }
        guard style == .hills, x.isFinite, x > 12 else { return (0, 0) }
        if x < Self.entryLength {
            return Self.blend(t: (x - 12) / 12, y0: 0, y1: Self.entryHeight,
                              slope0: 0, slope1: -Self.descentGrade, width: 12)
        }
        let section = floor((x - Self.entryLength) / Self.sectionLength)
        let local = x - Self.entryLength - section * Self.sectionLength
        let index = UInt32(truncatingIfNeeded: Int64(min(section, Double(Int64.max / 2))))
        let hash = Self.mix(seed ^ ((index &+ 1) &* 0x9e37_79b9))
        // Seeded groups contain one low, medium and tall profile in shuffled order.
        // This keeps variety without long accidental runs of only one hill size.
        let courseIndex = index > 0 ? index - 1 : 0
        let groupHash = Self.mix(seed ^ ((courseIndex / 3 &+ 1) &* 0x632b_e5ab))
        let kind = Self.profileOrders[Int(groupHash % 6)][Int(courseIndex % 3)]
        let variant = Int((hash >> 16) & 1) * 3
        let profile = Self.profiles[section < 1 ? 0 : kind + variant]
        let introduction = min(1, 0.78 + section * 0.055)
        let scale = introduction * (0.94 + Double((hash >> 8) % 101) / 625)
        let base = Self.entryHeight - Self.descentGrade * (x - Self.entryLength)
        for i in 0 ..< profile.count - 1 {
            let a = profile[i], b = profile[i + 1]
            if local <= b.x {
                let shape = Self.blend(t: (local - a.x) / (b.x - a.x), y0: a.y, y1: b.y,
                                       slope0: a.slope, slope1: b.slope, width: b.x - a.x)
                // Zero offset, slope and curvature at either end preserve C2 joins
                // between differently shaped and scaled sections.
                return (base + shape.height * scale, -Self.descentGrade + shape.slope * scale)
            }
        }
        return (base, -Self.descentGrade)
    }

    private func jungleGap(section: Double) -> TerrainSpan {
        let index = UInt32(truncatingIfNeeded: Int64(min(section, Double(Int64.max / 2))))
        let hash = Self.mix(seed ^ ((index &+ 1) &* 0x51ed_270b))
        let kind = jungleKind(section: section)
        let lower: Double
        switch kind {
        case 0: lower = 68 + Double(hash % 9)
        case 1: lower = 58 + Double(hash % 9)
        case 2: lower = 48 + Double(hash % 9)
        case 5: lower = 42 + Double(hash % 9)
        case 6, 7: lower = 50 + Double(hash % 7)
        case 8, 9: lower = 54 + Double(hash % 7)
        default: lower = 54 + Double(hash % 11)
        }
        let width = section == 0 ? 18 : Self.jungleWidths[kind]
        let start = section == 0 ? 56 : lower
        return .init(lowerBound: start, upperBound: start + width)
    }

    private func jungleKind(section: Double) -> Int {
        let index = UInt32(truncatingIfNeeded: Int64(min(section, Double(Int64.max / 2))))
        let group = Self.mix(seed ^ ((index / 6 &+ 1) &* 0x683f_729d))
        // One exceptional crossing per six sections, after the opening jumps.
        // Keep the six ordinary motifs between these occasional longer flights.
        if index % 6 == 5 { return 6 + Int(group % 2) }
        // Horizontal departures alternate two drop depths among the ramp jumps.
        // The opening three jumps retain their existing approach and landmarks.
        if index >= 3 && index % 3 == 0 { return 8 + Int((index / 3 + group) % 2) }
        return Int((index &+ group % 6) % 6)
    }

    /// The guide remains continuous across the void for camera framing. Only
    /// solidSpans create terrain fixtures: this interpolated bridge never collides.
    private func jungleSample(at x: Double) -> (height: Double, slope: Double) {
        guard x.isFinite, x > 12 else { return (0, 0) }
        let grade = Self.jungleDescentGrade, entryHeight = -0.5 * grade * 12
        if x < Self.entryLength {
            return Self.blend(t: (x - 12) / 12, y0: 0, y1: entryHeight,
                              slope0: 0, slope1: -grade, width: 12)
        }
        let section = floor((x - Self.entryLength) / Self.jungleSectionLength)
        let local = x - Self.entryLength - section * Self.jungleSectionLength
        let gap = jungleGap(section: section)
        let index = UInt32(truncatingIfNeeded: Int64(min(section, Double(Int64.max / 2))))
        let hash = Self.mix(seed ^ ((index &+ 1) &* 0x74bf_36d1))
        let kind = jungleKind(section: section)
        let valley = section == 0 ? -2.0 : ((6...7).contains(kind) ? -7.0 : -2.0) - Double(hash % 5) * 0.3
        // The opening and established ramp profiles retain their launch shapes.
        // Flat departures have twelve metres of level surface before the edge.
        let ramp = Self.jungleRamps[section == 0 ? 4 : kind]
        let height = valley + ramp.last!.y
        let rise = section == 0 ? 1.5 : Self.jungleRises[kind]
        let landing = height + grade * (gap.upperBound - gap.lowerBound) + rise
        let landingSlope = section == 0 ? 0.10 : Self.jungleLandingSlopes[kind]
        let landingLength = section == 0 ? 8.0 : Self.jungleLandingLengths[kind]
        let rampStart = gap.lowerBound + ramp[0].x
        let a: Knot, b: Knot
        if local <= 12 {
            a = .init(0, 0, 0); b = .init(12, valley * 0.6, -0.08)
        } else if local <= rampStart {
            a = .init(12, valley * 0.6, -0.08); b = .init(rampStart, valley, 0)
        } else if local <= gap.lowerBound {
            var segment = 0
            while segment < ramp.count - 2 && local > gap.lowerBound + ramp[segment + 1].x { segment += 1 }
            let first = ramp[segment], second = ramp[segment + 1]
            a = .init(gap.lowerBound + first.x, valley + first.y, first.slope)
            b = .init(gap.lowerBound + second.x, valley + second.y, second.slope)
        } else if local <= gap.upperBound {
            a = .init(gap.lowerBound, height, ramp.last!.slope)
            b = .init(gap.upperBound, landing, landingSlope)
        } else if local <= gap.upperBound + landingLength {
            a = .init(gap.upperBound, landing, landingSlope)
            b = .init(gap.upperBound + landingLength, landing + landingSlope * landingLength, landingSlope)
        } else if section > 0 && kind == 5 {
            // After the shorter crossing, a shallow dip and roller interrupt the
            // big-jump cadence without reducing the following recovery runway.
            if local <= 90 {
                a = .init(gap.upperBound + landingLength, landing + landingSlope * landingLength, landingSlope)
                b = .init(90, -1.2, 0)
            } else if local <= 110 {
                a = .init(90, -1.2, 0); b = .init(110, 2.0, 0)
            } else {
                a = .init(110, 2.0, 0); b = .init(Self.jungleSectionLength, 0, 0)
            }
        } else {
            a = .init(gap.upperBound + landingLength, landing + landingSlope * landingLength, landingSlope)
            b = .init(Self.jungleSectionLength, 0, 0)
        }
        let shape = Self.blend(t: (local - a.x) / (b.x - a.x), y0: a.y, y1: b.y,
                               slope0: a.slope, slope1: b.slope, width: b.x - a.x)
        return (entryHeight - grade * (x - Self.entryLength) + shape.height, -grade + shape.slope)
    }

    /// Shorter mountain shoulders give each takeoff a clearer beat. The long
    /// descending side and rounded valleys leave time to land and settle before
    /// the next climb. Only ground geometry changes; tire and bike tuning do not.
    private func japanSample(at x: Double) -> (height: Double, slope: Double) {
        guard x.isFinite, x > 12 else { return (0, 0) }
        if x < Self.entryLength {
            return Self.blend(t: (x - 12) / 12, y0: 0, y1: Self.entryHeight,
                              slope0: 0, slope1: -Self.descentGrade, width: 12)
        }
        let section = floor((x - Self.entryLength) / Self.japanSectionLength)
        let local = x - Self.entryLength - section * Self.japanSectionLength
        let index = UInt32(truncatingIfNeeded: Int64(min(section, Double(Int64.max / 2))))
        let hash = Self.mix(seed ^ ((index &+ 1) &* 0x7f4a_7c15))
        let courseIndex = index > 0 ? index - 1 : 0
        let groupHash = Self.mix(seed ^ ((courseIndex / 3 &+ 1) &* 0x2c1b_3c6d))
        let kind = Self.profileOrders[Int(groupHash % 6)][Int(courseIndex % 3)]
        let variant = Int((hash >> 16) & 1) * 3
        let profile = Self.japanProfiles[section < 1 ? 0 : kind + variant]
        let introduction = min(1, 0.72 + section * 0.07)
        let scale = introduction * (0.96 + Double((hash >> 8) % 101) / 1_000)
        let base = Self.entryHeight - Self.descentGrade * (x - Self.entryLength)
        for i in 0 ..< profile.count - 1 {
            let a = profile[i], b = profile[i + 1]
            if local <= b.x {
                let shape = Self.blend(t: (local - a.x) / (b.x - a.x), y0: a.y, y1: b.y,
                                       slope0: a.slope, slope1: b.slope, width: b.x - a.x)
                return (base + shape.height * scale, -Self.descentGrade + shape.slope * scale)
            }
        }
        return (base, -Self.descentGrade)
    }

    private struct Knot: Sendable {
        let x: Double, y: Double, slope: Double
        init(_ x: Double, _ y: Double, _ slope: Double) { self.x = x; self.y = y; self.slope = slope }
    }

    private static let jungleWidths = [18.0, 22, 26, 30, 34, 14, 38, 40, 16, 24]
    private static let jungleRises = [3.0, 4, 1.0, -1, -2, 1, 1, -1, -5.5, -10.5]
    private static let jungleLandingSlopes = [-0.02, 0.22, -0.14, 0.10, 0.10, 0.02, 0.02, 0.02, 0.10, -0.04]
    private static let jungleLandingLengths = [12.0, 10, 14, 8, 8, 10, 10, 10, 12, 12]
    // Coordinates are relative to the launch lip and the acceleration hollow.
    // Offsets include the common descent grade; the physical lip angles span
    // a low flyer, a progressive climb, a steep pop and the long-gap launch.
    private static let jungleRamps: [[Knot]] = [
        [.init(-22, 0, 0), .init(-13, 1.4, 0.35), .init(-6, 4.8, 0.85), .init(0, 10.8, 1.18)],
        [.init(-34, 0, 0), .init(-22, 1.8, 0.34), .init(-10, 6.4, 0.60), .init(0, 13.5, 0.82)],
        [.init(-30, 0, 0), .init(-19, 1.0, 0.25), .init(-8, 3.7, 0.48), .init(0, 8.4, 0.86)],
        [.init(-24, 0, 0), .init(-14, 1.8, 0.36), .init(-6, 5.8, 0.80), .init(0, 11.2, 0.95)],
        [.init(-24, 0, 0), .init(-14, 1.8, 0.36), .init(-6, 5.8, 0.80), .init(0, 11.2, 0.95)],
        [.init(-16, 0, 0), .init(-9, 0.4, 0.14), .init(-4, 1.2, 0.28), .init(0, 2.8, 0.46)],
        [.init(-12, 0, 0), .init(-6, 0.25, 0.12), .init(-3, 0.9, 0.36), .init(0, 2.8, 0.92)],
        [.init(-12, 0, 0), .init(-6, 0.25, 0.12), .init(-3, 0.9, 0.36), .init(0, 2.8, 0.92)],
        [.init(-36, 0, 0), .init(-24, 2.4, 0.26), .init(-12, 5.4, 0.10), .init(0, 6.6, 0.10)],
        [.init(-36, 0, 0), .init(-24, 2.4, 0.26), .init(-12, 5.4, 0.10), .init(0, 6.6, 0.10)]
    ]

    // Broad crests and long downhill receptions alternate small rollers, medium
    // jumps and occasional taller takeoffs. A smaller second bump adds rhythm,
    // after enough descending ground for the suspension to settle. These are
    // offsets from the common downhill baseline, not absolute ramp heights.
    private static let profileOrders = [[0, 1, 2], [0, 2, 1], [1, 0, 2],
                                        [1, 2, 0], [2, 0, 1], [2, 1, 0]]
    private static let profiles: [[Knot]] = [
        // Gentle opening: two rollers with broad, shallow transitions.
        [.init(0, 0, 0), .init(5, -0.1, 0), .init(11, 1.5, 0.43), .init(16, 2.6, 0),
         .init(23, 1.0, -0.28), .init(32, -0.65, 0), .init(37, -0.35, 0.20),
         .init(42, 1.1, 0.25), .init(46, 1.5, 0), .init(55, 0.25, -0.10), .init(64, 0, 0)],
        // Medium jump followed by a long landing slope and a low roller.
        [.init(0, 0, 0), .init(4, -0.2, 0), .init(10, 1.6, 0.60), .init(14, 4.0, 0.60), .init(18, 4.45, -0.15),
         .init(29, 0.1, -0.30), .init(37, -0.8, 0), .init(42, -0.45, 0.20),
         .init(47, 1.0, 0.22), .init(51, 1.4, 0), .init(59, 0.2, -0.08), .init(64, 0, 0)],
        // Taller takeoff retains room for natural airtime and rotation.
        [.init(0, 0, 0), .init(4, -0.2, 0), .init(11, 2.3, 0.75), .init(15, 5.3, 0.75),
         .init(19, 5.9, -0.18), .init(34, 0.6, -0.40), .init(43, -0.65, 0),
         .init(48, -0.35, 0.20), .init(53, 1.2, 0.17), .init(57, 1.3, -0.04), .init(64, 0, 0)],
        // Low, more evenly sized bumps create a calmer descending stretch.
        [.init(0, 0, 0), .init(7, -0.25, 0), .init(13, 1.4, 0.43), .init(18, 2.4, -0.03),
         .init(27, 0.1, -0.26), .init(35, -0.75, 0), .init(40, -0.3, 0.22),
         .init(45, 1.5, 0.28), .init(49, 1.9, -0.04), .init(58, 0.15, -0.09), .init(64, 0, 0)],
        // A later crest changes timing without making its reception steeper.
        [.init(0, 0, 0), .init(6, -0.3, 0), .init(12, 1.74, 0.68), .init(16, 4.46, 0.68), .init(20, 4.9, -0.17),
         .init(32, 0.6, -0.40), .init(40, -0.7, 0), .init(45, -0.35, 0.20),
         .init(50, 1.2, 0.23), .init(54, 1.5, -0.04), .init(60, 0.2, -0.10), .init(64, 0, 0)],
        // A second high profile spreads the climb over a longer approach.
        [.init(0, 0, 0), .init(5, -0.15, 0.03), .init(12, 2.2, 0.70), .init(17, 5.7, 0.70),
         .init(21, 6.3, -0.17), .init(35, 0.9, -0.44), .init(44, -0.7, 0),
         .init(49, -0.25, 0.24), .init(54, 1.35, 0.16), .init(58, 1.3, -0.09), .init(64, 0, 0)]
    ]

    // Mountain ridges have compact, rounded summits, followed by a sustained
    // reception. Alternate early/late shoulders and a second smaller ridge to
    // change cadence without cliffs, steps or a sawtooth collision surface.
    private static let japanProfiles: [[Knot]] = [
        // Low split ridge: a short crown and a taller shoulder keep the opening readable.
        [.init(0, 0, 0), .init(5, -0.132, 0), .init(11, 1.54, 0.484), .init(13.5, 2.112, -0.264),
         .init(22, 0.176, -0.1936), .init(29, -0.484, 0), .init(35, -0.088, 0.1936),
         .init(40, 1.584, 0.308), .init(42, 1.804, -0.264), .init(52, 0.044, -0.0704), .init(60, 0, 0)],
        // The summit changes pitch over two metres, then opens into a long reception.
        [.init(0, 0, 0), .init(4, -0.132, 0), .init(10, 1.672, 0.6688), .init(14, 4.224, 0.6072),
         .init(16, 4.532, -0.4224), .init(28, 0.176, -0.2992), .init(36, -0.572, 0),
         .init(42, -0.044, 0.2112), .init(47, 1.672, 0.2728), .init(49, 1.848, -0.2376), .init(60, 0, 0)],
        // Tall narrow mountain, with no extra force at takeoff and a soft valley exit.
        [.init(0, 0, 0), .init(4, -0.132, 0), .init(11, 2.508, 0.748), .init(15.5, 5.852, 0.7216),
         .init(17.5, 6.204, -0.4576), .init(31, 0.528, -0.3696), .init(40, -0.572, 0),
         .init(46, -0.088, 0.2024), .init(51, 1.452, 0.22), .init(53, 1.584, -0.2024), .init(60, 0, 0)],
        // Uneven twin crowns vary the rhythm without compressing their landing run-outs.
        [.init(0, 0, 0), .init(5, -0.1584, 0), .init(11, 1.672, 0.5192), .init(13.5, 2.332, -0.2552),
         .init(23, 0.132, -0.2112), .init(30, -0.484, 0), .init(37, -0.044, 0.1936),
         .init(42, 1.672, 0.2992), .init(44, 1.848, -0.2464), .init(54, 0.0704, -0.0616), .init(60, 0, 0)],
        // A delayed medium crown moves the next decision point by several metres.
        [.init(0, 0, 0), .init(5, -0.176, 0), .init(12, 1.936, 0.6952), .init(16, 4.664, 0.6424),
         .init(18, 4.972, -0.4312), .init(31, 0.352, -0.2992), .init(39, -0.572, 0),
         .init(45, -0.0704, 0.2024), .init(49, 1.188, 0.22), .init(51, 1.32, -0.1936), .init(60, 0, 0)],
        // The highest ridge has a longer approach, not a steeper compression into the climb.
        [.init(0, 0, 0), .init(5, -0.132, 0), .init(12, 2.552, 0.7656), .init(17, 6.292, 0.7216),
         .init(19, 6.644, -0.4664), .init(34, 0.616, -0.3432), .init(42, -0.528, 0),
         .init(47, -0.044, 0.2024), .init(51, 1.1, 0.2112), .init(53, 1.232, -0.1936), .init(60, 0, 0)]
    ]

    /// Quintic Hermite interpolation with zero curvature at both knots.
    private static func blend(t: Double, y0: Double, y1: Double, slope0: Double, slope1: Double,
                              width: Double) -> (height: Double, slope: Double) {
        let delta = y1 - y0, v0 = slope0 * width, v1 = slope1 * width
        let c3 = 10 * delta - 6 * v0 - 4 * v1
        let c4 = -15 * delta + 8 * v0 + 7 * v1
        let c5 = 6 * delta - 3 * v0 - 3 * v1
        let height = y0 + t * (v0 + t * t * (c3 + t * (c4 + t * c5)))
        let slope = (v0 + t * t * (3 * c3 + t * (4 * c4 + t * 5 * c5))) / width
        return (height, slope)
    }

    private static func mix(_ value: UInt32) -> UInt32 {
        var h = value
        h ^= h >> 16; h = h &* 0x85eb_ca6b
        h ^= h >> 13; h = h &* 0xc2b2_ae35
        return h ^ (h >> 16)
    }
}
