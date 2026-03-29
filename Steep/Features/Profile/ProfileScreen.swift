import SwiftUI

struct ProfileScreen: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            ColorToken.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
                    if let user = store.currentUser {
                        HStack(spacing: Spacing.md.rawValue) {
                            UserAvatar(profile: user, size: 68)
                            VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                                Text(user.displayName)
                                    .sipTitle()
                                Text("@\(user.username)")
                                    .sipLabel()
                            }
                            Spacer()
                        }

                        HStack(spacing: Spacing.md.rawValue) {
                            metric("Logs", value: store.feed.filter { $0.userID == user.id }.count)
                            metric("Followers", value: user.followerCount)
                            metric("Following", value: user.followingCount)
                        }

                        Text("Contribution XP")
                            .sipLabel()
                        ProgressView(value: Double(user.contributionXP), total: 200)
                            .tint(ColorToken.accent)

                        profileLogs(for: user)
                    } else {
                        guestProfile
                    }
                }
                .padding(.horizontal, Spacing.page.rawValue)
                .padding(.top, Spacing.md.rawValue)
            }
        }
        .navigationTitle("Profile")
    }

    private var guestProfile: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            Text("Join Sip")
                .sipTitle()
            Text("Sign in to build your profile, follow people, and unlock passport progress.")
                .sipLabel()
            SipButton(title: "Sign in") {
                store.requestProtectedAction(.saveVenue(venueID: UUID()))
            }
        }
        .padding(Spacing.lg.rawValue)
        .background(ColorToken.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg.rawValue, style: .continuous))
    }

    private func metric(_ title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .sipTitle()
                .monospacedDigit()
            Text(title)
                .sipLabel()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md.rawValue)
        .background(ColorToken.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
    }

    private func profileLogs(for user: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm.rawValue) {
            Text("Recent logs")
                .sipBody()

            let mine = store.feed.filter { $0.userID == user.id }
            if mine.isEmpty {
                Text("Your first sip is waiting. Start exploring.")
                    .sipLabel()
                    .padding(Spacing.md.rawValue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ColorToken.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
            } else {
                ForEach(mine) { log in
                    FeedCard(log: log, author: user)
                }
            }
        }
    }
}
