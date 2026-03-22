import SwiftUI

enum ColorToken {
    static let background = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let surface = Color(red: 1.0, green: 0.99, blue: 0.97)
    static let surfaceMuted = Color(red: 0.95, green: 0.92, blue: 0.88)

    static let textPrimary = Color(red: 0.19, green: 0.15, blue: 0.13)
    static let textSecondary = Color(red: 0.39, green: 0.33, blue: 0.29)
    static let textOnAccent = Color.white

    static let accent = Color(red: 0.83, green: 0.49, blue: 0.33)
    static let accentSoft = Color(red: 0.94, green: 0.80, blue: 0.69)
    static let matcha = Color(red: 0.48, green: 0.63, blue: 0.44)

    static let positive = Color(red: 0.24, green: 0.60, blue: 0.35)
    static let warning = Color(red: 0.80, green: 0.50, blue: 0.12)
    static let danger = Color(red: 0.78, green: 0.27, blue: 0.28)

    static let border = Color(red: 0.85, green: 0.80, blue: 0.74)
    static let shadow = Color(red: 0.19, green: 0.15, blue: 0.13).opacity(0.14)
}
