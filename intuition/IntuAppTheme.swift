import SwiftUI

enum IntuAppTheme {

    // MARK: - Base (dark finance assistant vibe)

    static let background = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.06, blue: 0.09),
            Color(red: 0.07, green: 0.08, blue: 0.13),
            Color(red: 0.04, green: 0.05, blue: 0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let surface = Color(red: 0.10, green: 0.12, blue: 0.18)
    static let surfaceSoft = Color(red: 0.12, green: 0.14, blue: 0.21)

    // MARK: - Accents

    static let accent = Color(red: 0.40, green: 0.80, blue: 0.98)     // cool cyan
    static let accentSoft = Color(red: 0.55, green: 0.45, blue: 0.98) // violet
    static let mint = Color(red: 0.42, green: 0.92, blue: 0.72)       // mint
    static let gold = Color(red: 0.98, green: 0.82, blue: 0.40)       // gold
    static let coral = Color(red: 0.98, green: 0.55, blue: 0.68)      // coral

    // MARK: - Text

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.72)
    static let textMuted = Color.white.opacity(0.45)

    // MARK: - Effects

    static let glowSoft = Color.white.opacity(0.16)
    static let glowStrong = Color.white.opacity(0.32)

    // MARK: - Helpers

    static func accentGradient(_ a: Color, _ b: Color) -> LinearGradient {
        LinearGradient(
            colors: [a, b],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func glowCircle(color: Color, radius: CGFloat = 20) -> some View {
        Circle()
            .fill(color)
            .blur(radius: radius)
            .opacity(0.65)
    }
}
