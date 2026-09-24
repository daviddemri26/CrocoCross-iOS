import Foundation
import CoreGraphics

/// The first contact owns a pedal until that contact ends or the session cancels it.
/// Moves deliberately have no transition: the first contact point stays fixed.
struct PedalContactState<TouchID: Equatable> {
    private(set) var owner: TouchID?
    private(set) var origin: CGPoint?

    mutating func begin(_ id: TouchID, at point: CGPoint) -> Bool {
        guard owner == nil else { return false }
        owner = id
        origin = point
        return true
    }

    mutating func end(_ id: TouchID) -> Bool {
        guard owner == id else { return false }
        reset()
        return true
    }

    mutating func reset() {
        owner = nil
        origin = nil
    }
}

/// Keep the smaller artwork inside its safe-area-respecting contact zone, clear of Pause.
struct PedalGeometry {
    let bounds: CGRect
    let diameter: CGFloat
    let right: Bool

    var side: CGFloat { max(0, min(diameter, min(bounds.width, bounds.height)) - 8) }
    var restingPoint: CGPoint {
        clamp(CGPoint(x: right ? bounds.maxX - diameter / 2 : bounds.minX + diameter / 2,
                      y: bounds.maxY - diameter / 2))
    }

    func clamp(_ point: CGPoint) -> CGPoint {
        let inset = side / 2 + 4
        return CGPoint(x: max(bounds.minX + inset, min(bounds.maxX - inset, point.x)),
                       y: max(bounds.minY + inset, min(bounds.maxY - inset, point.y)))
    }
}

#if canImport(UIKit)
import SwiftUI
import UIKit

/// Broad thumb zones with first-contact artwork and independent binary hold/release input.
struct PedalControl: UIViewRepresentable {
    var right: Bool
    var diameter: CGFloat = 112
    var enabled = true
    var resetToken = 0
    var changed: (Bool) -> Void
    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    func makeUIView(context: Context) -> PedalView {
        let view = PedalView()
        view.right = right
        view.diameter = diameter
        view.changed = changed
        return view
    }

    func updateUIView(_ view: PedalView, context: Context) {
        view.changed = changed
        view.right = right
        view.diameter = diameter
        view.reducedMotion = reducedMotion
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
    var right = false { didSet { if right != oldValue { configureArtwork() } } }
    var changed: ((Bool) -> Void)?
    var resetToken = 0
    var reducedMotion = UIAccessibility.isReduceMotionEnabled {
        didSet { if reducedMotion != oldValue { updateFeedback(animated: false) } }
    }
    var diameter: CGFloat = 112 { didSet { if diameter != oldValue { setNeedsLayout() } } }
    private var contact = PedalContactState<ObjectIdentifier>()
    private var previousSize = CGSize.zero
    private var geometry: PedalGeometry { .init(bounds: bounds, diameter: diameter, right: right) }
    private var held = false
    private let face = UIView()
    private let artwork = UIImageView()
    private let surface = CAGradientLayer()
    private let bevel = CAGradientLayer()
    private let bevelMask = CAShapeLayer()
    private let innerEdge = CAShapeLayer()
    private let activeRing = CAShapeLayer()
    private let ripple = CAShapeLayer()
    private var accent: UIColor { .hex(right ? 0xC2FA4C : 0xFF8A42) }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        isMultipleTouchEnabled = true
        isExclusiveTouch = false
        isAccessibilityElement = true
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification, object: nil)
        face.isUserInteractionEnabled = false
        face.layer.shadowColor = UIColor.black.cgColor
        face.layer.shadowOpacity = 0.30
        face.layer.shadowRadius = 7
        face.layer.shadowOffset = CGSize(width: 0, height: 4)
        surface.colors = [UIColor.hex(0x315A60).cgColor, UIColor.hex(0x142E36).cgColor, UIColor.hex(0x08191F).cgColor]
        surface.locations = [0, 0.38, 1]
        surface.startPoint = CGPoint(x: 0.15, y: 0)
        surface.endPoint = CGPoint(x: 0.85, y: 1)
        bevel.colors = [UIColor.hex(0xD4E3DD).cgColor, UIColor.hex(0x54757B).cgColor,
                        UIColor.hex(0x1B363D).cgColor, UIColor.hex(0x8BA7A5).cgColor]
        bevel.locations = [0, 0.35, 0.68, 1]
        bevel.startPoint = .zero
        bevel.endPoint = CGPoint(x: 1, y: 1)
        bevelMask.fillColor = UIColor.clear.cgColor
        bevelMask.strokeColor = UIColor.black.cgColor
        bevelMask.lineWidth = 3
        bevel.mask = bevelMask
        innerEdge.fillColor = UIColor.clear.cgColor
        innerEdge.strokeColor = UIColor.white.withAlphaComponent(0.12).cgColor
        innerEdge.lineWidth = 0.8
        activeRing.fillColor = UIColor.clear.cgColor
        activeRing.lineWidth = 1.8
        activeRing.shadowRadius = 6
        activeRing.shadowOffset = .zero
        ripple.fillColor = UIColor.clear.cgColor
        ripple.lineWidth = 1.4
        ripple.opacity = 0
        layer.addSublayer(ripple)
        addSubview(face)
        face.layer.addSublayer(surface)
        face.layer.addSublayer(bevel)
        face.layer.addSublayer(innerEdge)
        face.layer.addSublayer(activeRing)
        artwork.contentMode = .scaleAspectFit
        face.addSubview(artwork)
        configureArtwork()
        updateFeedback(animated: false)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func applicationWillResignActive() { release() }

    private func configureArtwork() {
        artwork.image = GameAssets.image(named: right ? "control-throttle" : "control-brake")
        accessibilityIdentifier = right ? "throttle" : "brake"
        accessibilityLabel = right ? "Throttle" : "Brake"
        accessibilityHint = "Hold for full power. Lift to release. Double-tap with VoiceOver to hold or release."
        activeRing.strokeColor = accent.cgColor
        activeRing.shadowColor = accent.cgColor
        ripple.strokeColor = accent.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if previousSize != .zero && previousSize != bounds.size { release() }
        previousSize = bounds.size
        let side = geometry.side
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        face.bounds = CGRect(x: 0, y: 0, width: side, height: side)
        face.center = contact.origin.map(geometry.clamp) ?? geometry.restingPoint
        let circle = CGPath(ellipseIn: face.bounds.insetBy(dx: 2, dy: 2), transform: nil)
        face.layer.shadowPath = circle
        for shape in [surface, bevel, innerEdge, activeRing] { shape.frame = face.bounds }
        surface.cornerRadius = side / 2
        bevelMask.frame = face.bounds
        bevelMask.path = circle
        activeRing.path = CGPath(ellipseIn: face.bounds.insetBy(dx: 3, dy: 3), transform: nil)
        innerEdge.path = CGPath(ellipseIn: face.bounds.insetBy(dx: 7, dy: 7), transform: nil)
        ripple.bounds = CGRect(x: 0, y: 0, width: side, height: side)
        ripple.position = face.center
        ripple.path = CGPath(ellipseIn: ripple.bounds, transform: nil)
        artwork.frame = face.bounds.insetBy(dx: side * 0.075, dy: side * 0.075)
        CATransaction.commit()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isUserInteractionEnabled, let touch = touches.first,
              contact.begin(ObjectIdentifier(touch), at: touch.location(in: self)) else { return }
        setHeld(true, animated: true)
    }
    // Sliding never changes power, artwork position or the owning touch.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.contains(where: { contact.end(ObjectIdentifier($0)) }) { release(animated: true) }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.contains(where: { contact.end(ObjectIdentifier($0)) }) { release() }
    }
    override func didMoveToWindow() { if window == nil { release() } }

    override func accessibilityActivate() -> Bool {
        guard isUserInteractionEnabled, contact.owner == nil else { return false }
        setHeld(!held, animated: true)
        return true
    }

    func release(animated: Bool = false) {
        contact.reset()
        setHeld(false, animated: animated)
    }
    private func setHeld(_ pressed: Bool, animated: Bool) {
        if held != pressed {
            held = pressed
            // Simulation input changes immediately; animation never delays a release.
            changed?(pressed)
        }
        updateFeedback(animated: animated)
    }
    private func updateFeedback(animated: Bool) {
        accessibilityTraits = held ? [.button, .selected] : [.button]
        accessibilityValue = held ? "Pressed" : "Released"
        let oldPosition = face.layer.presentation()?.position ?? face.layer.position
        let targetPosition = contact.origin.map(geometry.clamp) ?? geometry.restingPoint
        let oldScale = (face.layer.presentation()?.value(forKeyPath: "transform.scale") as? CGFloat)
            ?? (face.layer.value(forKeyPath: "transform.scale") as? CGFloat) ?? 1
        face.layer.removeAllAnimations()
        activeRing.removeAllAnimations()
        ripple.removeAllAnimations()
        let target: CGFloat = held && !reducedMotion ? 0.935 : 1
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        face.center = targetPosition
        ripple.position = targetPosition
        face.layer.setValue(target, forKeyPath: "transform.scale")
        activeRing.opacity = held ? 1 : 0.16
        activeRing.shadowOpacity = held ? 0.65 : 0
        ripple.opacity = 0
        surface.opacity = held ? 0.84 : 1
        CATransaction.commit()
        guard !reducedMotion else { return }
        if animated {
            let settle = CABasicAnimation(keyPath: "position")
            settle.fromValue = NSValue(cgPoint: oldPosition)
            settle.toValue = NSValue(cgPoint: targetPosition)
            settle.duration = held ? 0.16 : 0.22
            settle.timingFunction = CAMediaTimingFunction(name: .easeOut)
            face.layer.add(settle, forKey: "placement")
            let spring = CASpringAnimation(keyPath: "transform.scale")
            spring.fromValue = oldScale
            spring.toValue = target
            spring.mass = 1
            spring.stiffness = held ? 550 : 380
            spring.damping = held ? 30 : 18
            spring.initialVelocity = 0
            spring.duration = spring.settlingDuration
            face.layer.add(spring, forKey: "press")
            if held {
                let expand = CABasicAnimation(keyPath: "transform.scale")
                expand.fromValue = 1; expand.toValue = 1.16
                let fade = CABasicAnimation(keyPath: "opacity")
                fade.fromValue = 0.50; fade.toValue = 0
                let wave = CAAnimationGroup()
                wave.animations = [expand, fade]
                wave.duration = 0.32
                wave.timingFunction = CAMediaTimingFunction(name: .easeOut)
                ripple.add(wave, forKey: "touch")
            }
        }
        if held {
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 1; pulse.toValue = 0.58
            pulse.duration = 0.9
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            activeRing.add(pulse, forKey: "hold")
        }
    }
}

#endif
