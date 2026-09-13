import SwiftUI

/*
 ISC License

 Copyright (c) 2026 Lucide Icons and Contributors

 Permission to use, copy, modify, and/or distribute this software for any
 purpose with or without fee is hereby granted, provided that the above
 copyright notice and this permission notice appear in all copies.

 THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/// The original Riders menu symbol: Lucide `Bike`, version 1.31.0.
/// Matches its 24-point SVG viewBox and rounded, two-point strokes.
struct LegacyRiderIcon: View {
    var size: CGFloat = 22

    var body: some View {
        LegacyRiderShape()
            .stroke(style: StrokeStyle(lineWidth: size / 12, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct LegacyRiderShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // SVG circles: (18.5,17.5,r3.5), (5.5,17.5,r3.5), (15,5,r1).
        path.addEllipse(in: CGRect(x: 15, y: 14, width: 7, height: 7))
        path.addEllipse(in: CGRect(x: 2, y: 14, width: 7, height: 7))
        path.addEllipse(in: CGRect(x: 14, y: 4, width: 2, height: 2))
        // SVG path: M12 17.5V14l-3-3 4-3 2 3h2.
        path.move(to: CGPoint(x: 12, y: 17.5))
        path.addLine(to: CGPoint(x: 12, y: 14))
        path.addLine(to: CGPoint(x: 9, y: 11))
        path.addLine(to: CGPoint(x: 13, y: 8))
        path.addLine(to: CGPoint(x: 15, y: 11))
        path.addLine(to: CGPoint(x: 17, y: 11))
        let scale = min(rect.width, rect.height) / 24
        return path.applying(
            CGAffineTransform(
                a: scale, b: 0, c: 0, d: scale,
                tx: rect.midX - 12 * scale, ty: rect.midY - 12 * scale
            ))
    }
}

extension LegacyRiderIcon {
    static let license = """
        ISC License

        Copyright (c) 2026 Lucide Icons and Contributors

        Permission to use, copy, modify, and/or distribute this software for any
        purpose with or without fee is hereby granted, provided that the above
        copyright notice and this permission notice appear in all copies.

        THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
        WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
        MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
        ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
        WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
        ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
        OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
        """
}
