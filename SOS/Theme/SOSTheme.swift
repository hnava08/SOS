import SwiftUI

enum SOSTheme {
    static let primaryRed = Color(red: 0.82, green: 0.09, blue: 0.12)
    static let darkRed = Color(red: 0.65, green: 0.05, blue: 0.08)
    static let lightRed = Color(red: 0.95, green: 0.88, blue: 0.88)
    static let accentRed = Color(red: 0.92, green: 0.15, blue: 0.18)
    static let routeRed = Color(red: 0.85, green: 0.12, blue: 0.15)

    static let cardBackground = Color.white
    static let secondaryText = Color(red: 0.35, green: 0.35, blue: 0.38)
    static let shadow = Color.black.opacity(0.12)

    static let headerGradient = LinearGradient(
        colors: [primaryRed, darkRed],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let highContrastHeader = LinearGradient(
        colors: [.black, Color(red: 0.15, green: 0.15, blue: 0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func header(highContrast: Bool) -> LinearGradient {
        highContrast ? highContrastHeader : headerGradient
    }

    static func primary(highContrast: Bool) -> Color {
        highContrast ? .black : primaryRed
    }

    static func secondaryLabel(highContrast: Bool) -> Color {
        highContrast ? Color(white: 0.2) : secondaryText
    }
}
