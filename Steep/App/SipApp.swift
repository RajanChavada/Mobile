import SwiftUI

@main
struct SipApp: App {
    @StateObject private var store = AppStore(configuration: .shared)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    Task {
                        await store.handleOpenURL(url)
                    }
                }
        }
    }
}
