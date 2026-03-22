import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack {
            ColorToken.background.ignoresSafeArea()

            if store.isLoading && store.venues.isEmpty {
                ProgressView("Loading Sip")
                    .tint(ColorToken.accent)
            } else {
                MainTabShell()
            }
        }
        .task {
            await store.start()
        }
    }
}
