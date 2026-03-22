import SwiftUI

struct InlineErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(ColorToken.danger)
            Text(message)
                .sipLabel()
                .foregroundStyle(ColorToken.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(Spacing.md.rawValue)
        .background(ColorToken.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous)
                .stroke(ColorToken.danger.opacity(0.5), lineWidth: 1)
        }
    }
}
