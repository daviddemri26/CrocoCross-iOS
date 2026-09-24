import AppKit
import CoreGraphics

// Minimal adapter: the production renderer only needs a rider ID and UIKit's
// image spelling. No rendering, articulation or calibration is replaced here.
struct Rider { let id: String }
typealias UIImage = NSImage
typealias UIColor = NSColor
extension NSImage {
    convenience init(cgImage: CGImage) { self.init(cgImage: cgImage, size: .zero) }
}
