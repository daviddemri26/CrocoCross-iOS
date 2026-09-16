import Foundation
import CBox2D

func bounded(_ value: Double, _ lower: Double, _ upper: Double) -> Double {
    value.isFinite ? min(upper, max(lower, value)) : 0
}
func wrapped(_ angle: Double) -> Double { atan2(sin(angle), cos(angle)) }
func rotated(_ vector: Vector2, by angle: Double) -> Vector2 {
    .init(x: vector.x * cos(angle) - vector.y * sin(angle), y: vector.x * sin(angle) + vector.y * cos(angle))
}
extension Vector2 {
    static func + (a: Self, b: Self) -> Self { .init(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: Self, b: Self) -> Self { .init(x: a.x - b.x, y: a.y - b.y) }
    static func * (a: Self, b: Double) -> Self { .init(x: a.x * b, y: a.y * b) }
    func dot(_ other: Self) -> Double { x * other.x + y * other.y }
    func cross(_ other: Self) -> Double { x * other.y - y * other.x }
    var b2: b2Vec2 { b2Vec2(x: Float(x), y: Float(y)) }
    init(_ value: b2Vec2) { self.init(x: Double(value.x), y: Double(value.y)) }
}
