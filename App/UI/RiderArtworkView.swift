import SwiftUI

/// A single Canvas per visible cell; shared cached layers keep all nine previews inexpensive.
/// Wheel rotors turn independently while the original forks and tyre artwork remain still.
struct RiderArtworkView: View {
    let riderID: String
    var animated: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reducedMotion

    var body: some View {
        let rider = GameCatalog.rider(riderID)
        let layers = RiderArtwork.layers(for: rider)
        TimelineView(.animation(minimumInterval: 1 / 24, paused: !animated || reducedMotion)) { timeline in
            Canvas { context, size in
                guard let layers else { return }
                let time = animated && !reducedMotion ? timeline.date.timeIntervalSinceReferenceDate : 0
                let scale = min(size.width / layers.size.width, size.height / layers.size.height)
                context.translateBy(
                    x: (size.width - layers.size.width * scale) / 2,
                    y: (size.height - layers.size.height * scale) / 2)
                context.scaleBy(x: scale, y: scale)
                for wheel in layers.wheels {
                    var wheelContext = context
                    wheelContext.translateBy(x: wheel.centre.x, y: wheel.centre.y)
                    let d = wheel.diameter
                    if let tyre = wheel.tyre {
                        wheelContext.draw(Image(uiImage: tyre), in: CGRect(x: -d / 2, y: -d / 2, width: d, height: d))
                    }
                    wheelContext.rotate(by: .radians(time * 0.65))
                    let rotorDiameter = wheel.tyre == nil ? d : d * 0.725
                    wheelContext.draw(
                        Image(uiImage: wheel.rotor),
                        in: CGRect(
                            x: -rotorDiameter / 2, y: -rotorDiameter / 2,
                            width: rotorDiameter, height: rotorDiameter))
                }
                // A tiny breath pivots around the axle, leaving tyre contact fixed.
                var bodyContext = context
                let pivotY = layers.wheels.map(\.centre.y).reduce(0, +) / 2
                bodyContext.translateBy(x: 0, y: pivotY)
                bodyContext.scaleBy(x: 1, y: 1 + sin(time * 2.1) * 0.002)
                bodyContext.translateBy(x: 0, y: -pivotY)
                bodyContext.draw(Image(uiImage: layers.body), in: CGRect(origin: .zero, size: layers.body.size))
                for wheel in layers.wheels {
                    let d = wheel.tyre == nil ? wheel.diameter : wheel.diameter * 0.11
                    context.draw(
                        Image(uiImage: wheel.hardware),
                        in: CGRect(x: wheel.centre.x - d / 2, y: wheel.centre.y - d / 2, width: d, height: d))
                }
            }
        }
        .accessibilityLabel("\(rider.name), \(rider.subtitle)")
        .accessibilityAddTraits(.isImage)
    }
}
