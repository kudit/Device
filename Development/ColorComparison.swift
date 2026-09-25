import Foundation
import Color

/// Measures per-channel color distance in the normalized 0...1 range.
/// Averaging RGBA distance keeps the result intuitive: 0 is identical and 1
/// is maximally different across every channel.
public extension KuColor {
    func delta(_ other: Self) -> CGFloat {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        guard getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
              other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return 1 }
        return (abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2) + abs(a1 - a2)) / 4
    }
}
