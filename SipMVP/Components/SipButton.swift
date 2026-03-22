import SwiftUI

enum SipButtonStyle {
    case primary
    case secondary
    case destructive
}

struct SipButton: View {
    let title: String
    var isLoading: Bool = false
    var style: SipButtonStyle = .primary
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm.rawValue) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                }
                Text(title)
                    .sipBody()
                    .foregroundStyle(foregroundColor)
                    .lineLimit(1)
            }
            .padding(.vertical, Spacing.md.rawValue)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
        }
        .disabled(isLoading)
        .buttonStyle(.plain)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return ColorToken.accent
        case .secondary: return ColorToken.surface
        case .destructive: return ColorToken.danger
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary, .destructive: return .clear
        case .secondary: return ColorToken.border
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .destructive: return ColorToken.textOnAccent
        case .secondary: return ColorToken.textPrimary
        }
    }
}
