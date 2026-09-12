import SwiftUI
import UIKit

/// UIKit owns touch identity and cancellation, including interruption by system gestures.
struct PedalControl: UIViewRepresentable {
    var right: Bool
    var enabled: Bool = true
    var resetToken: Int = 0
    var changed: (Double) -> Void
    func makeUIView(context: Context) -> PedalView {
        let view = PedalView()
        view.right = right; view.changed = changed
        view.accessibilityIdentifier = right ? "throttle" : "brake"
        view.accessibilityLabel = right ? "Accelerate and lean back" : "Brake and lean forward"
        return view
    }
    func updateUIView(_ view: PedalView, context: Context) {
        view.changed = changed
        if !enabled || view.resetToken != resetToken { view.release(); view.resetToken = resetToken }
        view.isUserInteractionEnabled = enabled
    }
    static func dismantleUIView(_ view: PedalView, coordinator: ()) { view.release() }
}

final class PedalView: UIView {
    var right = false
    var changed: ((Double) -> Void)?
    var resetToken = 0
    private var activeTouch: UITouch?
    private var startY: CGFloat = 0
    private var value: Double = 0
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false; isMultipleTouchEnabled = false
        isAccessibilityElement = true; accessibilityTraits = [.button]
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch; startY = touch.location(in: self).y; set(1)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let dy = touch.location(in: self).y - startY
        set(max(0.12, min(1, 1 - Double(dy) / 90)))
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { release() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { release() }
    override func didMoveToWindow() { if window == nil { release() } }
    func release() { activeTouch = nil; set(0) }
    private func set(_ value: Double) { self.value = value; changed?(value); setNeedsDisplay() }
    override func draw(_ rect: CGRect) {
        let panel = UIBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerRadius: 25)
        let lime = UIColor(red: 0.76, green: 0.98, blue: 0.30, alpha: 1)
        (value > 0 ? lime : UIColor(red: 0.05, green: 0.13, blue: 0.15, alpha: 0.88)).setFill()
        panel.fill()
        (value > 0 ? lime : UIColor.white.withAlphaComponent(0.3)).setStroke()
        panel.lineWidth = 1.5; panel.stroke()
        let color = value > 0 ? UIColor(red: 0.04, green: 0.11, blue: 0.10, alpha: 1) : .white
        let symbol = UIImage(systemName: right ? "arrow.right" : "arrow.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 27, weight: .bold))?.withTintColor(color, renderingMode: .alwaysOriginal)
        symbol?.draw(in: CGRect(x: rect.midX - 16, y: 14, width: 32, height: 26))
        let text = right ? "THROTTLE" : "BRAKE"
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.monospacedSystemFont(ofSize: 10, weight: .bold), .foregroundColor: color]
        let size = (text as NSString).size(withAttributes: attributes)
        (text as NSString).draw(at: CGPoint(x: rect.midX - size.width / 2, y: 49), withAttributes: attributes)
        if value > 0 {
            UIColor.black.withAlphaComponent(0.25).setFill()
            UIBezierPath(roundedRect: CGRect(x: 16, y: rect.height - 10, width: (rect.width - 32) * value, height: 3), cornerRadius: 1.5).fill()
        }
    }
}
