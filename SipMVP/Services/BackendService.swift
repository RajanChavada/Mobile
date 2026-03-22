import Foundation

struct BootstrapPayload {
    let venues: [Venue]
    let feed: [SipLog]
    let users: [UserProfile]
    let stamps: [PassportStamp]
}

protocol BackendService {
    func bootstrap(city: String, session: UserSession?) async throws -> BootstrapPayload
    func signIn(with provider: AuthProvider) async throws -> UserSession
    func completeOnboarding(session: UserSession, input: OnboardingInput) async throws -> UserProfile
    func submitLog(session: UserSession, draft: DraftLog) async throws -> SipLog
    func setFollow(session: UserSession, targetUserID: UUID, shouldFollow: Bool) async throws
    func fetchFeed(session: UserSession) async throws -> [SipLog]
    func fetchPassport(session: UserSession) async throws -> [PassportStamp]
}
