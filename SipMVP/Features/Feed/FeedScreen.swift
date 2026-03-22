import SwiftUI

struct FeedScreen: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            ColorToken.background.ignoresSafeArea()

            if store.feed.isEmpty {
                VStack(spacing: Spacing.sm.rawValue) {
                    Text("Nothing here yet")
                        .sipTitle()
                    Text("Follow people to see where they've been")
                        .sipLabel()
                }
                .padding(Spacing.page.rawValue)
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm.rawValue) {
                        ForEach(store.feed) { log in
                            FeedCard(log: log, author: store.author(for: log))
                        }
                    }
                    .padding(.horizontal, Spacing.page.rawValue)
                    .padding(.vertical, Spacing.md.rawValue)
                }
            }
        }
        .navigationTitle("Feed")
    }
}
