import SpriteKit

/// A visual gate only. No collision body; the core owns the exact finish coordinate.
@MainActor
final class FinishLineNode: SKNode {
    private let lightChecks = SKShapeNode()
    private let darkChecks = SKShapeNode()
    private let flag = SKNode()

    override init() {
        super.init()
        for node in [lightChecks, darkChecks] {
            node.strokeColor = .clear
            node.alpha = 0.25
            addChild(node)
        }
        lightChecks.fillColor = .white
        darkChecks.fillColor = .hex(0x102522)
        addChild(flag)
        let pole = SKShapeNode(rectOf: CGSize(width: 5, height: 244), cornerRadius: 2)
        pole.fillColor = .hex(0xF5F0DA)
        pole.strokeColor = .hex(0x152C27)
        pole.lineWidth = 1.5
        pole.position.y = 122
        flag.addChild(pole)
        for row in 0..<3 {
            for column in 0..<5 {
                let square = SKSpriteNode(color: (row + column).isMultiple(of: 2) ? .white : .hex(0x152C27),
                                          size: CGSize(width: 20, height: 20))
                square.position = CGPoint(x: 13 + column * 20, y: 232 - row * 20)
                flag.addChild(square)
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func display(x: CGFloat, groundY: CGFloat, viewportHeight: CGFloat, ppm: CGFloat) {
        position = CGPoint(x: x, y: groundY)
        flag.setScale(ppm / 64)
        // Extend to the top of the viewport even when a jump puts the road off-screen.
        let cell = max(8, ppm * 0.32)
        let top = max(viewportHeight - groundY + cell, 244 * ppm / 64)
        let bottom = max(-cell, -groundY - cell)
        let white = CGMutablePath()
        let black = CGMutablePath()
        let firstRow = Int(floor(bottom / cell))
        let lastRow = Int(ceil(top / cell))
        for row in firstRow..<lastRow {
            for column in 0..<2 {
                let rect = CGRect(x: CGFloat(column - 1) * cell, y: CGFloat(row) * cell,
                                  width: cell, height: cell)
                ((row + column).isMultiple(of: 2) ? white : black).addRect(rect)
            }
        }
        lightChecks.path = white
        darkChecks.path = black
    }
}
