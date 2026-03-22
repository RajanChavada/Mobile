import SwiftUI

struct MainTabShell: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $store.selectedTab) {
                NavigationStack { MapScreen() }
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                    .tag(AppTab.map)

                NavigationStack { FeedScreen() }
                    .tabItem {
                        Label("Feed", systemImage: "text.bubble")
                    }
                    .tag(AppTab.feed)

                NavigationStack { PassportScreen() }
                    .tabItem {
                        Label("Passport", systemImage: "bookmark")
                    }
                    .tag(AppTab.passport)

                NavigationStack {
                    ProfileScreen()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                NavigationLink("Plans") {
                                    SubscriptionView()
                                }
                                .tint(ColorToken.textPrimary)
                            }
                        }
                }
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(AppTab.profile)
            }

            VStack(spacing: 0) {
                if store.isOffline {
                    OfflineIndicator()
                }

                if let inlineInfo = store.inlineInfo {
                    InlineInfoBanner(message: inlineInfo)
                        .padding(.horizontal, Spacing.page.rawValue)
                        .padding(.top, Spacing.sm.rawValue)
                        .onTapGesture {
                            store.dismissInlineInfo()
                        }
                }

                if let inlineError = store.inlineError {
                    InlineErrorBanner(message: inlineError)
                        .padding(.horizontal, Spacing.page.rawValue)
                        .padding(.top, Spacing.sm.rawValue)
                        .onTapGesture {
                            store.dismissInlineError()
                        }
                }

                Spacer()

                HStack {
                    Spacer()
                    Button {
                        store.beginLog(from: nil)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(ColorToken.textOnAccent)
                            .frame(width: 64, height: 64)
                            .background(ColorToken.accent)
                            .clipShape(Circle())
                            .shadow(color: ColorToken.shadow, radius: 10, y: 4)
                    }
                    .buttonStyle(.plain)
                    .offset(y: -14)
                    Spacer()
                }
            }
        }
        .overlay {
            ZStack {
                SipBottomSheet(isPresented: $store.isSignInSheetPresented, detent: 330) {
                    SignInSheet()
                }

                SipBottomSheet(isPresented: $store.isOnboardingPresented, detent: 460) {
                    OnboardingFlowView()
                }

                SipBottomSheet(isPresented: $store.isQuickLogPresented, detent: 560) {
                    QuickLogSheet()
                }
            }
        }
    }
}
