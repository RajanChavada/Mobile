import SwiftUI

struct ThemePreviewCard: View {
    let option: ThemeOption
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous)
                .fill(gradient)
                .frame(height: 84)
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(ColorToken.textOnAccent)
                            .padding(Spacing.sm.rawValue)
                    }
                }
            Text(option.title)
                .sipLabel()
                .foregroundStyle(ColorToken.textPrimary)
        }
        .padding(Spacing.sm.rawValue)
        .background(ColorToken.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous)
                .stroke(isSelected ? ColorToken.accent : ColorToken.border, lineWidth: 1)
        }
    }

    private var gradient: LinearGradient {
        switch option {
        case .warm:
            return LinearGradient(colors: [ColorToken.accentSoft, ColorToken.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blossom:
            return LinearGradient(colors: [ColorToken.surfaceMuted, ColorToken.accentSoft], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .matcha:
            return LinearGradient(colors: [ColorToken.matcha.opacity(0.6), ColorToken.matcha], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
