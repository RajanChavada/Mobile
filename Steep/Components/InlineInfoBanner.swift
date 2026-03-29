import SwiftUI

struct InlineInfoBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(ColorToken.warning)
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
                .stroke(ColorToken.border, lineWidth: 1)
        }
    }
}
