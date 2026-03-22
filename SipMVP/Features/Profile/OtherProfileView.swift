import SwiftUI

struct OtherProfileView: View {
    @EnvironmentObject private var store: AppStore

    let user: UserProfile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
                HStack(spacing: Spacing.md.rawValue) {
                    UserAvatar(profile: user, size: 64)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName)
                            .sipTitle()
                        Text("@\(user.username)")
                            .sipLabel()
                    }
                    Spacer()
                }

                HStack(spacing: Spacing.md.rawValue) {
                    Text("Followers \(user.followerCount)")
                        .sipLabel()
                        .monospacedDigit()
                    Text("Following \(user.followingCount)")
                        .sipLabel()
                        .monospacedDigit()
                }

                SipButton(title: store.isFollowing(userID: user.id) ? "Following" : "Follow", style: store.isFollowing(userID: user.id) ? .secondary : .primary) {
                    Task {
                        await store.setFollow(userID: user.id, shouldFollow: !store.isFollowing(userID: user.id))
                    }
                }
            }
            .padding(.horizontal, Spacing.page.rawValue)
            .padding(.top, Spacing.md.rawValue)
        }
        .background(ColorToken.background.ignoresSafeArea())
        .navigationTitle(user.displayName)
    }
}
