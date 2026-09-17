import Foundation

/// Tracks unwrapped flight orientation. Only a safe reception can bank pending turns.
struct StuntTracker: Codable, Sendable {
    private var active = false
    private var armed = false
    private var angle = 0.0
    private var sector = 0
    private var forwardTravel = 0.0
    private var backwardTravel = 0.0
    private var airTicks = 0
    private var gapTicks = 0
    private var landingTicks = 0
    private var pending = 0
    private var pendingBackflips = 0
    private var pendingFrontflips = 0
    private(set) var landedBackflips = 0
    private(set) var landedFrontflips = 0

    mutating func clear() { self = StuntTracker() }

    var isValid: Bool {
        [angle, forwardTravel, backwardTravel].allSatisfy { $0.isFinite && abs($0) < 1e9 } &&
        forwardTravel >= 0 && backwardTravel >= 0 && sector > -1_000_000_000 && sector < 1_000_000_000 &&
        [airTicks, gapTicks, landingTicks, pending, pendingBackflips, pendingFrontflips, landedBackflips, landedFrontflips].allSatisfy { $0 >= 0 && $0 < 1_000_000_000 }
    }

    mutating func advance(delta: Double, orientation: Double, airborne: Bool, safeContact: Bool, terminal: Bool = false) -> Int {
        let tau = Double.pi * 2
        let upright = cos(orientation) >= cos(Double.pi * 75 / 180)
        if !active {
            guard airborne else { return 0 }
            active = true; angle = orientation - delta
            sector = Int((angle / tau).rounded()); armed = cos(angle) >= cos(Double.pi * 75 / 180)
        }
        angle += delta
        if !armed {
            if upright { armed = true; sector = Int((angle / tau).rounded()) }
        } else if airborne || gapTicks > 0 {
            forwardTravel = max(0, forwardTravel + delta)
            backwardTravel = max(0, backwardTravel - delta)
            let tolerance = Double.pi * 75 / 180
            let excursion = Double.pi * 240 / 180
            let forward = angle >= Double(sector + 1) * tau - tolerance && forwardTravel >= excursion
            let backward = angle <= Double(sector - 1) * tau + tolerance && backwardTravel >= excursion
            if upright && (forward || backward) {
                sector += forward ? 1 : -1
                forwardTravel = 0; backwardTravel = 0; pending += 1
                // Positive world rotation raises the front wheel: a backflip.
                if forward { pendingBackflips += 1 } else { pendingFrontflips += 1 }
            }
        }
        if airborne {
            airTicks += 1; gapTicks += 1
            if gapTicks > 8 { landingTicks = 0 }
        } else {
            gapTicks = 0
            landingTicks = safeContact ? landingTicks + 1 : 0
            if landingTicks >= 8 || (terminal && safeContact) {
                let count = airTicks >= 12 ? pending : 0
                let back = count > 0 ? pendingBackflips : 0
                let front = count > 0 ? pendingFrontflips : 0
                clear()
                landedBackflips = back; landedFrontflips = front
                return count
            }
        }
        return 0
    }
}
