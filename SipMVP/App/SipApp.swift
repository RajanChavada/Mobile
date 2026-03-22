import SwiftUI

@main
struct SipApp: App {
    @StateObject private var store = AppStore(configuration: .shared)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
