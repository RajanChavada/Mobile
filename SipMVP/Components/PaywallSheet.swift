import SwiftUI

struct PaywallSheet: View {
    @Binding var isPresented: Bool

    var body: some View {
        SipBottomSheet(isPresented: $isPresented, detent: 420) {
            VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
                Text("Unlock Sip Pass")
                    .sipTitle()

                priceRow(tier: .free, features: "1 photo/log")
                priceRow(tier: .sipPass, features: "Unlimited photos, pro badge")
                priceRow(tier: .curator, features: "All Sip Pass + curator features")

                SipButton(title: "Get Sip Pass") {
                    isPresented = false
                }
            }
            .padding(.top, Spacing.sm.rawValue)
        }
    }

    private func priceRow(tier: SubscriptionTier, features: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(tier.displayName)
                    .sipBody()
                Text(features)
                    .sipLabel()
            }
            Spacer()
            Text(tier.monthlyPriceLabel)
                .sipPrice()
        }
        .padding(Spacing.md.rawValue)
        .background(ColorToken.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        }
    }
}
