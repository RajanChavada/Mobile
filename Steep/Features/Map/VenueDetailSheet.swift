import SwiftUI

struct VenueDetailSheet: View {
    @EnvironmentObject private var store: AppStore

    let venue: Venue

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            Text(venue.name)
                .sipTitle()

            Text(venue.address)
                .sipLabel()

            HStack(spacing: Spacing.md.rawValue) {
                Label(venue.category.rawValue.capitalized, systemImage: "tag")
                RatingBadge(text: String(format: "%.1f", venue.averageRating), emphasized: true)
                Label("\(venue.reviewCount)", systemImage: "person.2")
                    .monospacedDigit()
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(ColorToken.textSecondary)

            SipButton(title: "Log this spot") {
                store.beginLog(from: venue)
            }

            Divider()

            Text("Recent logs")
                .sipBody()

            if logsForVenue.isEmpty {
                Text("No logs yet. Be the first.")
                    .sipLabel()
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm.rawValue) {
                        ForEach(logsForVenue.prefix(3)) { log in
                            FeedCard(log: log, author: store.author(for: log))
                        }
                    }
                }
            }
        }
        .padding(.top, Spacing.sm.rawValue)
    }

    private var logsForVenue: [SipLog] {
        store.feed.filter { $0.venueID == venue.id && $0.isPublic }
    }
}
