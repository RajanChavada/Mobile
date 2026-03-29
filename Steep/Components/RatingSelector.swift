import SwiftUI

struct RatingSelector: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            ForEach(1...5, id: \.self) { value in
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        rating = value
                    }
                } label: {
                    Image(systemName: value <= rating ? "drop.fill" : "drop")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(value <= rating ? ColorToken.accent : ColorToken.surfaceMuted)
                        .scaleEffect(value == rating ? 1.12 : 1.0)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate \(value) out of 5")
            }
        }
    }
}
