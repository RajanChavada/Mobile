import SwiftUI

struct SignInSheet: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
            VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                Text("Join to save this spot")
                    .sipTitle()
                Text("Sign in to log venues, follow friends, and build your passport.")
                    .sipLabel()
            }

            SipButton(title: "Continue with Apple", isLoading: store.isSigningIn) {
                Task { await store.signIn(with: .apple) }
            }

            SipButton(title: "Continue with Google", isLoading: store.isSigningIn, style: .secondary) {
                Task { await store.signIn(with: .google) }
            }

            SipButton(title: "Not now", style: .secondary) {
                store.dismissSignIn()
            }
        }
        .padding(.top, Spacing.md.rawValue)
        .padding(.bottom, Spacing.sm.rawValue)
    }
}
