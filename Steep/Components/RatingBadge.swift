import SwiftUI

struct RatingBadge: View {
    let text: String
    var emphasized: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "drop.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ColorToken.accent)
            Text(text)
                .sipBody()
                .monospacedDigit()
                .foregroundStyle(emphasized ? ColorToken.textPrimary : ColorToken.textSecondary)
        }
    }
}
