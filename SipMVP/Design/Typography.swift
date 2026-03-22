import SwiftUI

private struct SipTypographyModifier: ViewModifier {
    let font: Font
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(color)
    }
}

extension View {
    func sipDisplay() -> some View {
        modifier(SipTypographyModifier(font: .system(size: 32, weight: .bold, design: .rounded), color: ColorToken.textPrimary))
    }

    func sipTitle() -> some View {
        modifier(SipTypographyModifier(font: .system(size: 22, weight: .semibold, design: .rounded), color: ColorToken.textPrimary))
    }

    func sipBody() -> some View {
        modifier(SipTypographyModifier(font: .system(size: 16, weight: .regular, design: .rounded), color: ColorToken.textPrimary))
    }

    func sipLabel() -> some View {
        modifier(SipTypographyModifier(font: .system(size: 13, weight: .medium, design: .rounded), color: ColorToken.textSecondary))
    }

    func sipPrice() -> some View {
        modifier(SipTypographyModifier(font: .system(size: 20, weight: .bold, design: .rounded), color: ColorToken.textPrimary))
            .monospacedDigit()
    }
}
