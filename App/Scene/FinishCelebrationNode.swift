import SpriteKit

/// Two bounded paper-confetti jets, independent of the physical world and score.
@MainActor
final class FinishCelebrationNode: SKNode {
    private let pieces: [SKSpriteNode] = (0..<80).map { index in
        let colors: [UIColor] = [.hex(0xC2FA4D), .hex(0xFFCB66), .hex(0x5DDACB), .white]
        return SKSpriteNode(color: colors[index % colors.count],
                            size: CGSize(width: 5 + index % 5, height: 3 + index % 3))
    }

    override init() {
        super.init()
        pieces.forEach { addChild($0) }
        isHidden = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(elapsed: Double?, size: CGSize, reducedMotion: Bool) {
        guard let elapsed, elapsed < 5 else { isHidden = true; return }
        isHidden = false
        let fade = CGFloat(min(1, max(0, (5 - elapsed) / 1.1)))
        for (index, piece) in pieces.enumerated() {
            let side: CGFloat = index.isMultiple(of: 2) ? 1 : -1
            let t = CGFloat(elapsed) - CGFloat(index % 10) * 0.035
            piece.isHidden = t < 0 || (reducedMotion && index >= 12)
            guard !piece.isHidden else { continue }
            if reducedMotion {
                // A quiet, stationary sprinkle around the success badge.
                let angle = CGFloat(index) * .pi / 6
                piece.position = CGPoint(x: size.width / 2 + cos(angle) * min(145, size.width * 0.36),
                                         y: size.height * 0.68 + sin(angle) * 42)
                piece.zRotation = angle
                piece.xScale = 1
                piece.alpha = fade * 0.65
            } else {
                let launchX = size.width * (side > 0 ? 0.08 : 0.92)
                let vx = side * size.width * (0.13 + CGFloat(index * 17 % 23) / 100)
                let vy = size.height * (0.49 + CGFloat(index * 13 % 19) / 100)
                piece.position = CGPoint(x: launchX + vx * t * 0.7 + sin(t * 4 + CGFloat(index)) * 8,
                                         y: size.height * 0.18 + vy * t - size.height * 0.14 * t * t)
                piece.zRotation = CGFloat(index) + t * side * (2 + CGFloat(index % 4))
                piece.xScale = 0.25 + abs(cos(t * 5 + CGFloat(index))) * 0.75
                piece.alpha = min(1, t * 12) * fade * 0.9
            }
        }
    }
}
