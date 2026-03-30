import SwiftUI

struct PassportScreen: View {
    @EnvironmentObject private var store: AppStore
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            ColorToken.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
                    Text("Monthly stamps")
                        .sipTitle()

                    if store.stamps.isEmpty {
                        Text("Log a spot in a new neighbourhood to earn your first stamp")
                            .sipLabel()
                            .padding(Spacing.lg.rawValue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ColorToken.surface)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.lg.rawValue, style: .continuous))
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm.rawValue) {
                            ForEach(store.stamps) { stamp in
                                stampCard(stamp)
                            }
                        }
                        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: store.stamps.count)
                    }

                    SipButton(title: "View city leaderboard", style: .secondary) {
                        showPaywall = true
                    }
                }
                .padding(.horizontal, Spacing.page.rawValue)
                .padding(.top, Spacing.md.rawValue)
            }
        }
        .overlay {
            PaywallSheet(isPresented: $showPaywall)
        }
        .navigationTitle("Passport")
    }

    private func stampCard(_ stamp: PassportStamp) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(stamp.city)
                .sipBody()
            Text(stamp.neighbourhood)
                .sipLabel()
            Text(formattedMonth(stamp.month))
                .sipLabel()
        }
        .padding(Spacing.md.rawValue)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(stamp.unlocked ? ColorToken.surface : ColorToken.surfaceMuted)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous)
                .stroke(stamp.unlocked ? ColorToken.accent : ColorToken.border, lineWidth: 1)
        }
    }

    private func formattedMonth(_ raw: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: raw) else { return raw }

        let output = DateFormatter()
        output.dateFormat = "MMMM yyyy"
        return output.string(from: date)
    }
}
