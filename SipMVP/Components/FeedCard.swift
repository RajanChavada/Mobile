import SwiftUI

struct FeedCard: View {
    let log: SipLog
    let author: UserProfile?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            HStack(spacing: Spacing.sm.rawValue) {
                if let author {
                    UserAvatar(profile: author, size: 38)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.username)
                        .sipBody()
                    Text(log.venueName)
                        .sipLabel()
                }
                Spacer()
                Text(log.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .sipLabel()
            }

            HStack(spacing: Spacing.sm.rawValue) {
                Image(systemName: "drop.fill")
                    .foregroundStyle(ColorToken.accent)
                Text("\(log.rating)/5")
                    .sipBody()
                    .monospacedDigit()
                if log.isPendingSync {
                    Text("Syncing")
                        .sipLabel()
                        .padding(.horizontal, Spacing.sm.rawValue)
                        .padding(.vertical, Spacing.xs.rawValue)
                        .background(ColorToken.surfaceMuted)
                        .clipShape(Capsule())
                }
            }

            if !log.note.isEmpty {
                Text(log.note)
                    .sipBody()
                    .foregroundStyle(ColorToken.textSecondary)
                    .lineLimit(3)
            }
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
