import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published var authState: AuthState = .guest
    @Published var selectedTab: AppTab = .map

    @Published var venues: [Venue] = []
    @Published var feed: [SipLog] = []
    @Published var users: [UserProfile] = []
    @Published var stamps: [PassportStamp] = []

    @Published var selectedVenue: Venue?
    @Published var quickLogVenue: Venue?

    @Published var isSignInSheetPresented = false
    @Published var isOnboardingPresented = false
    @Published var isQuickLogPresented = false

    @Published var isLoading = false
    @Published var isSigningIn = false
    @Published var inlineError: String?
    @Published var inlineInfo: String?

    @Published var isOffline = false
    @Published var city: String = "Toronto"

    private var pendingProtectedAction: ProtectedAction?
    private var followState: [UUID: Bool] = [:]

    private let backend: BackendService
    private let guestSeedBackend: BackendService
    private let pendingQueue: PendingLogQueue
    private let networkMonitor: NetworkMonitor
    private var cancellables: Set<AnyCancellable> = []
    private var hasStarted = false

    init(
        configuration: AppConfiguration = .shared,
        backend: BackendService? = nil,
        pendingQueue: PendingLogQueue = PendingLogQueue(),
        networkMonitor: NetworkMonitor = NetworkMonitor()
    ) {
        if let backend {
            self.backend = backend
        } else if configuration.canUseSupabase {
            self.backend = SupabaseBackendService(configuration: configuration)
        } else {
            self.backend = MockBackendService()
        }
        guestSeedBackend = MockBackendService()

        self.pendingQueue = pendingQueue
        self.networkMonitor = networkMonitor

        networkMonitor.$isConnected
            .receive(on: RunLoop.main)
            .sink { [weak self] connected in
                self?.isOffline = !connected
                guard connected else { return }
                Task { await self?.flushPendingLogs() }
            }
            .store(in: &cancellables)

        if configuration.needsSecretWarning {
            inlineInfo = "SUPABASE_SECRET should stay server-only and never be shipped in the iOS app."
        } else if configuration.hasClientGoogleKey {
            inlineInfo = "Google Places key should live in Supabase Edge Function env only, not the app."
        }
    }

    var currentUser: UserProfile? {
        switch authState {
        case .guest:
            return nil
        case .authenticated(let session):
            return session.user
        }
    }

    var requiresOnboarding: Bool {
        isOnboardingPresented
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true
        networkMonitor.start()
        await pendingQueue.load()
        await bootstrap()
    }

    func bootstrap() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let selectedBackend: BackendService
            if authSession == nil, !(backend is MockBackendService) {
                selectedBackend = guestSeedBackend
            } else {
                selectedBackend = backend
            }

            let payload = try await selectedBackend.bootstrap(city: city, session: authSession)
            venues = payload.venues
            feed = payload.feed
            users = payload.users
            stamps = payload.stamps
            inlineError = nil
        } catch {
            inlineError = error.localizedDescription
        }
    }

    func requestProtectedAction(_ action: ProtectedAction) {
        guard authState.isAuthenticated else {
            pendingProtectedAction = action
            isSignInSheetPresented = true
            return
        }

        executeProtectedAction(action)
    }

    func signIn(with provider: AuthProvider) async {
        isSigningIn = true
        defer { isSigningIn = false }

        do {
            var session = try await backend.signIn(with: provider)
            // Required convention: run normalisation off the main thread.
            let normalized = await SalaryNormalisationService.normalise(session.user.username)
            session.user.username = normalized
            authState = .authenticated(session)
            isSignInSheetPresented = false
            isOnboardingPresented = true
            inlineError = nil
        } catch {
            inlineError = error.localizedDescription
        }
    }

    func completeOnboarding(_ input: OnboardingInput) async {
        guard var session = authSession else {
            inlineError = AppError.unauthenticated.localizedDescription
            return
        }

        do {
            let profile = try await backend.completeOnboarding(session: session, input: input)
            session.user = profile
            authState = .authenticated(session)
            city = profile.city
            isOnboardingPresented = false
            inlineError = nil
            await bootstrap()

            if let action = pendingProtectedAction {
                pendingProtectedAction = nil
                executeProtectedAction(action)
            }
        } catch {
            inlineError = error.localizedDescription
        }
    }

    func dismissSignIn() {
        isSignInSheetPresented = false
        pendingProtectedAction = nil
    }

    func openVenueDetail(_ venue: Venue) {
        selectedVenue = venue
    }

    func beginLog(from venue: Venue?) {
        requestProtectedAction(.log(venue: venue))
    }

    func submitLog(draft: DraftLog) async {
        guard let session = authSession else {
            requestProtectedAction(.log(venue: draft.venue))
            return
        }

        let optimistic = SipLog(
            id: draft.temporaryID,
            userID: session.user.id,
            venueID: draft.venue.id,
            venueName: draft.venue.name,
            username: session.user.username,
            rating: draft.rating,
            note: draft.note,
            drinkType: draft.drinkType,
            isPublic: draft.isPublic,
            photoURLs: [],
            createdAt: .now,
            isPendingSync: true
        )

        feed.insert(optimistic, at: 0)
        isQuickLogPresented = false

        if isOffline {
            do {
                try await pendingQueue.enqueue(draft)
                inlineError = "Saved offline. We will retry when you're back online."
            } catch {
                rollbackOptimisticLog(temporaryID: draft.temporaryID)
                inlineError = "Couldn't store this draft offline."
            }
            return
        }

        do {
            let posted = try await backend.submitLog(session: session, draft: draft)
            replaceOptimisticLog(temporaryID: draft.temporaryID, with: posted)
            inlineError = nil
        } catch {
            rollbackOptimisticLog(temporaryID: draft.temporaryID)
            do {
                try await pendingQueue.enqueue(draft)
                inlineError = "Couldn't post that one. It will retry when online."
            } catch {
                inlineError = error.localizedDescription
            }
        }
    }

    func setFollow(userID: UUID, shouldFollow: Bool) async {
        guard let session = authSession else {
            requestProtectedAction(.follow(userID: userID))
            return
        }

        let previous = isFollowing(userID: userID)
        followState[userID] = shouldFollow
        applyFollowerDelta(userID: userID, shouldFollow: shouldFollow)

        do {
            try await backend.setFollow(session: session, targetUserID: userID, shouldFollow: shouldFollow)
            inlineError = nil
        } catch {
            followState[userID] = previous
            applyFollowerDelta(userID: userID, shouldFollow: previous)
            inlineError = error.localizedDescription
        }
    }

    func isFollowing(userID: UUID) -> Bool {
        followState[userID] ?? false
    }

    func author(for log: SipLog) -> UserProfile? {
        users.first(where: { $0.id == log.userID })
    }

    func dismissInlineError() {
        inlineError = nil
    }

    func dismissInlineInfo() {
        inlineInfo = nil
    }

    private func executeProtectedAction(_ action: ProtectedAction) {
        switch action {
        case .log(let venue):
            quickLogVenue = venue
            isQuickLogPresented = true
        case .follow(let userID):
            Task { await setFollow(userID: userID, shouldFollow: true) }
        case .saveVenue:
            inlineError = "Save is not wired in this scratch MVP yet."
        }
    }

    private var authSession: UserSession? {
        if case let .authenticated(session) = authState {
            return session
        }
        return nil
    }

    private func replaceOptimisticLog(temporaryID: UUID, with posted: SipLog) {
        guard let index = feed.firstIndex(where: { $0.id == temporaryID }) else {
            feed.insert(posted, at: 0)
            return
        }
        feed[index] = posted
    }

    private func rollbackOptimisticLog(temporaryID: UUID) {
        feed.removeAll { $0.id == temporaryID }
    }

    private func applyFollowerDelta(userID: UUID, shouldFollow: Bool) {
        guard let index = users.firstIndex(where: { $0.id == userID }) else {
            return
        }

        if shouldFollow {
            users[index].followerCount += 1
        } else {
            users[index].followerCount = max(0, users[index].followerCount - 1)
        }
    }

    private func flushPendingLogs() async {
        guard let session = authSession else { return }
        let drafts = await pendingQueue.all()
        guard !drafts.isEmpty else { return }

        for draft in drafts {
            do {
                let posted = try await backend.submitLog(session: session, draft: draft)
                replaceOptimisticLog(temporaryID: draft.temporaryID, with: posted)
                try await pendingQueue.remove(draft.temporaryID)
            } catch {
                inlineError = "Some offline drafts are still waiting to sync."
                return
            }
        }
    }
}
