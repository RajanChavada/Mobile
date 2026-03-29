import SwiftUI

struct SubscriptionView: View {
    @State private var showPurchaseInline = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
                Text("Choose your tier")
                    .sipTitle()

                tierCard(.free, bullets: "Unlimited logs, 1 photo/log")
                tierCard(.sipPass, bullets: "Unlimited photos, premium themes, leaderboard")
                tierCard(.curator, bullets: "All Sip Pass + curated lists + custom pins")

                SipButton(title: "Continue with Apple IAP") {
                    showPurchaseInline = true
                }

                if showPurchaseInline {
                    InlineErrorBanner(message: "StoreKit purchase wiring is pending in this scratch MVP.")
                }
            }
            .padding(.horizontal, Spacing.page.rawValue)
            .padding(.top, Spacing.md.rawValue)
        }
        .background(ColorToken.background.ignoresSafeArea())
        .navigationTitle("Subscription")
    }

    private func tierCard(_ tier: SubscriptionTier, bullets: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            HStack {
                Text(tier.displayName)
                    .sipBody()
                Spacer()
                Text(tier.monthlyPriceLabel)
                    .sipPrice()
            }
            Text(bullets)
                .sipLabel()
        }
        .padding(Spacing.lg.rawValue)
        .background(ColorToken.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg.rawValue, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.lg.rawValue, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        }
    }
}
