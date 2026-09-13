import SwiftUI
import UIKit

/// Each view owns a whole lower corner, so a thumb never has to find a small button.
struct PedalControl: UIViewRepresentable {
    var right: Bool
    var enabled = true
    var resetToken = 0
    var changed: (Double) -> Void

    func makeUIView(context: Context) -> PedalView {
        let view = PedalView()
        view.right = right
        view.changed = changed
        view.accessibilityIdentifier = right ? "throttle" : "brake"
        view.accessibilityLabel = right ? "Throttle" : "Brake"
        view.accessibilityHint =
            "Touch anywhere in this lower corner. Slide down to reduce, up to increase. Double-tap with VoiceOver to hold or release."
        return view
    }

    func updateUIView(_ view: PedalView, context: Context) {
        view.changed = changed
        if !enabled || view.resetToken != resetToken {
            view.release()
            view.resetToken = resetToken
        }
        view.isUserInteractionEnabled = enabled
        view.accessibilityElementsHidden = !enabled
    }

    static func dismantleUIView(_ view: PedalView, coordinator: ()) { view.release() }
}

final class PedalView: UIView {
    var right = false
    var changed: ((Double) -> Void)?
    var resetToken = 0
    private var activeTouch: UITouch?
    private var origin = CGPoint.zero
    private var thumb = CGPoint.zero
    private var value = 0.0
    private var held = false
    private let ink = UIColor(red: 0.04, green: 0.10, blue: 0.12, alpha: 1)
    private var accent: UIColor {
        right
            ? UIColor(red: 0.76, green: 0.98, blue: 0.30, alpha: 1) : UIColor(red: 1, green: 0.54, blue: 0.26, alpha: 1)
    }
    private var restingPoint: CGPoint { CGPoint(x: right ? bounds.maxX - 69 : 69, y: bounds.maxY - 59) }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isMultipleTouchEnabled = true
        isAccessibilityElement = true
        accessibilityTraits = [.button, .adjustable]
        accessibilityValue = "0%"
        contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch
        origin = touch.location(in: self)
        thumb = origin
        held = true
        set(right ? 0.9 : 1)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        thumb = touch.location(in: self)
        // Shorten the travel close to the bottom edge; full modulation stays possible.
        let available = window.map { $0.bounds.maxY - convert(origin, to: $0).y - 2 } ?? (bounds.maxY - origin.y)
        let travel = max(1, min(120, available))
        set((right ? 0.9 : 1) - Double(thumb.y - origin.y) / travel)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let activeTouch, touches.contains(activeTouch) { release() }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let activeTouch, touches.contains(activeTouch) { release() }
    }
    override func didMoveToWindow() { if window == nil { release() } }

    override func accessibilityActivate() -> Bool {
        if held {
            release()
        } else {
            origin = restingPoint
            thumb = origin
            held = true
            set(right ? 0.9 : 1)
        }
        return true
    }
    override func accessibilityIncrement() {
        held = true
        thumb = restingPoint
        set(value + 0.1)
    }
    override func accessibilityDecrement() {
        thumb = restingPoint
        set(value - 0.1)
        held = value > 0
        setNeedsDisplay()
    }

    func release() {
        activeTouch = nil
        held = false
        if value != 0 { set(0) } else { setNeedsDisplay() }
    }
    private func set(_ proposed: Double) {
        value = proposed.isFinite ? max(0, min(1, proposed)) : 0
        accessibilityValue = "\(Int((value * 100).rounded()))%"
        changed?(value)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let p = held ? thumb : restingPoint
        // The grip follows the finger, including a drag outside its original zone.
        let center = CGPoint(x: max(42, min(bounds.maxX - 42, p.x)), y: max(42, min(bounds.maxY - 42, p.y)))
        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0, height: 4), blur: 12, color: UIColor.black.withAlphaComponent(0.45).cgColor)
        ink.withAlphaComponent(held ? 0.96 : 0.86).setFill()
        UIBezierPath(ovalIn: CGRect(x: center.x - 39, y: center.y - 39, width: 78, height: 78)).fill()
        context.restoreGState()
        let ring = UIBezierPath(
            arcCenter: center, radius: 35, startAngle: -.pi * 0.8, endAngle: .pi * 0.8, clockwise: true)
        UIColor.white.withAlphaComponent(0.16).setStroke()
        ring.lineWidth = 3
        ring.stroke()
        if held {
            let gauge = UIBezierPath(
                arcCenter: center, radius: 35, startAngle: -.pi * 0.8, endAngle: -.pi * 0.8 + .pi * 1.6 * value,
                clockwise: true)
            accent.setStroke()
            gauge.lineWidth = 4
            gauge.lineCapStyle = .round
            gauge.stroke()
        }
        context.saveGState()
        context.translateBy(x: center.x, y: center.y - 5)
        if right { drawGrip() } else { drawBrake() }
        context.restoreGState()
        label(
            right ? "GAS" : "BRAKE", at: CGPoint(x: center.x, y: center.y + 20), size: 9, color: held ? accent : .white)
        if held { drawSlider(near: center) }
    }

    private func drawSlider(near center: CGPoint) {
        // Keep the gauge on the inward side of the thumb, visible around its silhouette.
        let x = max(15, min(bounds.maxX - 15, center.x + (right ? -56 : 56)))
        let height: CGFloat = min(128, bounds.height - 64)
        let top = max(27, min(bounds.maxY - height - 24, origin.y - height * 0.1))
        ink.withAlphaComponent(0.92).setFill()
        UIBezierPath(roundedRect: CGRect(x: x - 12, y: top - 12, width: 24, height: height + 24), cornerRadius: 12)
            .fill()
        UIColor.white.withAlphaComponent(0.18).setFill()
        UIBezierPath(roundedRect: CGRect(x: x - 3, y: top, width: 6, height: height), cornerRadius: 3).fill()
        let level = top + height * (1 - value)
        accent.setFill()
        UIBezierPath(roundedRect: CGRect(x: x - 3, y: level, width: 6, height: height * value), cornerRadius: 3).fill()
        UIBezierPath(roundedRect: CGRect(x: x - 9, y: level - 4, width: 18, height: 8), cornerRadius: 4).fill()
        ink.withAlphaComponent(0.96).setFill()
        UIBezierPath(roundedRect: CGRect(x: x - 17, y: top - 28, width: 34, height: 18), cornerRadius: 9).fill()
        label("\(Int((value * 100).rounded()))", at: CGPoint(x: x, y: top - 24), size: 10, color: accent)
    }

    private func drawGrip() {
        let grip = UIBezierPath(roundedRect: CGRect(x: -20, y: -9, width: 36, height: 18), cornerRadius: 5)
        accent.setFill()
        grip.fill()
        ink.withAlphaComponent(0.65).setStroke()
        for x in stride(from: -14, through: 10, by: 6) {
            let rib = UIBezierPath()
            rib.move(to: CGPoint(x: x, y: -6))
            rib.addLine(to: CGPoint(x: x, y: 6))
            rib.lineWidth = 2
            rib.stroke()
        }
        accent.setStroke()
        let bar = UIBezierPath()
        bar.move(to: CGPoint(x: 16, y: 0))
        bar.addLine(to: CGPoint(x: 22, y: 0))
        bar.addQuadCurve(to: CGPoint(x: 29, y: -15), controlPoint: CGPoint(x: 27, y: 0))
        bar.lineWidth = 4
        bar.lineCapStyle = .round
        UIColor(white: 0.82, alpha: 1).setStroke()
        bar.stroke()
        let cap = UIBezierPath(roundedRect: CGRect(x: -23, y: -11, width: 5, height: 22), cornerRadius: 2)
        UIColor(white: 0.82, alpha: 1).setFill()
        cap.fill()
        accent.setStroke()
        let twist = UIBezierPath(
            arcCenter: CGPoint(x: -3, y: 0), radius: 24, startAngle: -.pi * 0.7, endAngle: -.pi * 0.15, clockwise: true)
        twist.lineWidth = 2
        twist.stroke()
        let arrow = UIBezierPath()
        arrow.move(to: CGPoint(x: 12, y: -17))
        arrow.addLine(to: CGPoint(x: 19, y: -11))
        arrow.addLine(to: CGPoint(x: 10, y: -10))
        arrow.lineWidth = 2
        arrow.lineJoinStyle = .round
        arrow.stroke()
    }

    private func drawBrake() {
        accent.setStroke()
        let disc = UIBezierPath(ovalIn: CGRect(x: -18, y: -16, width: 30, height: 30))
        disc.lineWidth = 3
        disc.stroke()
        let hub = UIBezierPath(ovalIn: CGRect(x: -7, y: -5, width: 8, height: 8))
        hub.lineWidth = 2
        hub.stroke()
        for i in 0..<6 {
            let a = CGFloat(i) * .pi / 3
            accent.setFill()
            UIBezierPath(ovalIn: CGRect(x: -4 + cos(a) * 10, y: -2 + sin(a) * 10, width: 2, height: 2)).fill()
        }
        let lever = UIBezierPath()
        lever.move(to: CGPoint(x: 19, y: -17))
        lever.addLine(to: CGPoint(x: 20, y: -3))
        lever.addQuadCurve(to: CGPoint(x: 9, y: 18), controlPoint: CGPoint(x: 19, y: 12))
        lever.lineWidth = held ? 5 : 4
        lever.lineCapStyle = .round
        lever.stroke()
    }

    private func label(_ text: String, at point: CGPoint, size: CGFloat, color: UIColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: size, weight: .heavy), .foregroundColor: color,
        ]
        let width = (text as NSString).size(withAttributes: attributes).width
        (text as NSString).draw(at: CGPoint(x: point.x - width / 2, y: point.y), withAttributes: attributes)
    }
}
