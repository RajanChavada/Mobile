import Foundation

actor MockBackendService: BackendService {
    private var users: [UserProfile]
    private var venues: [Venue]
    private var feed: [SipLog]
    private var stamps: [PassportStamp]

    init() {
        let currentUser = UserProfile(
            id: UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF") ?? UUID(),
            username: "sipstarter",
            displayName: "Sip Starter",
            avatarURL: nil,
            city: "Toronto",
            preference: .both,
            tier: .free,
            contributionXP: 30,
            followerCount: 2,
            followingCount: 3
        )

        let friendA = UserProfile(
            id: UUID(),
            username: "matchamila",
            displayName: "Mila Park",
            avatarURL: nil,
            city: "Toronto",
            preference: .matcha,
            tier: .sipPass,
            contributionXP: 120,
            followerCount: 92,
            followingCount: 70
        )

        let friendB = UserProfile(
            id: UUID(),
            username: "coffeekai",
            displayName: "Kai Nguyen",
            avatarURL: nil,
            city: "Toronto",
            preference: .coffee,
            tier: .free,
            contributionXP: 55,
            followerCount: 13,
            followingCount: 25
        )

        let venueA = Venue(
            id: UUID(),
            placeID: "mock-place-1",
            name: "Roast Lane",
            address: "12 Queen St W",
            city: "Toronto",
            latitude: 43.6532,
            longitude: -79.3832,
            category: .coffee,
            averageRating: 4.4,
            reviewCount: 78,
            isActive: true
        )

        let venueB = Venue(
            id: UUID(),
            placeID: "mock-place-2",
            name: "Moss & Whisk",
            address: "88 Ossington Ave",
            city: "Toronto",
            latitude: 43.6471,
            longitude: -79.4226,
            category: .matcha,
            averageRating: 4.8,
            reviewCount: 41,
            isActive: true
        )

        users = [currentUser, friendA, friendB]
        venues = [venueA, venueB]

        feed = [
            SipLog(
                id: UUID(),
                userID: friendA.id,
                venueID: venueB.id,
                venueName: venueB.name,
                username: friendA.username,
                rating: 5,
                note: "Cloud matcha was unreal.",
                drinkType: .matcha,
                isPublic: true,
                photoURLs: [],
                createdAt: .now.addingTimeInterval(-3600),
                isPendingSync: false
            ),
            SipLog(
                id: UUID(),
                userID: friendB.id,
                venueID: venueA.id,
                venueName: venueA.name,
                username: friendB.username,
                rating: 4,
                note: "Great espresso, tiny patio.",
                drinkType: .coffee,
                isPublic: true,
                photoURLs: [],
                createdAt: .now.addingTimeInterval(-7800),
                isPendingSync: false
            )
        ]

        stamps = [
            PassportStamp(id: UUID(), city: "Toronto", neighbourhood: "Kensington", month: "2026-03", unlocked: true),
            PassportStamp(id: UUID(), city: "Toronto", neighbourhood: "Ossington", month: "2026-02", unlocked: true),
            PassportStamp(id: UUID(), city: "Toronto", neighbourhood: "Queen West", month: "2026-01", unlocked: false)
        ]
    }

    func bootstrap(city: String, session: UserSession?) async throws -> BootstrapPayload {
        try await Task.sleep(nanoseconds: 180_000_000)
        let filteredVenues = venues.filter { $0.city.localizedCaseInsensitiveContains(city) || city.isEmpty }
        return BootstrapPayload(
            venues: filteredVenues.isEmpty ? venues : filteredVenues,
            feed: feed.sorted { $0.createdAt > $1.createdAt },
            users: users,
            stamps: stamps
        )
    }

    func signIn(with provider: AuthProvider) async throws -> UserSession {
        try await Task.sleep(nanoseconds: 220_000_000)
        guard let current = users.first else {
            throw AppError.network("Could not load the user session.")
        }

        let providerPrefix = provider == .apple ? "apple" : "google"
        return UserSession(
            accessToken: "mock_\(providerPrefix)_token",
            refreshToken: "mock_refresh_token",
            user: current
        )
    }

    func completeOnboarding(session: UserSession, input: OnboardingInput) async throws -> UserProfile {
        try await Task.sleep(nanoseconds: 180_000_000)
        guard let index = users.firstIndex(where: { $0.id == session.user.id }) else {
            throw AppError.network("Could not update profile during onboarding.")
        }

        users[index].city = input.city
        users[index].preference = input.preference
        return users[index]
    }

    func submitLog(session: UserSession, draft: DraftLog) async throws -> SipLog {
        try await Task.sleep(nanoseconds: 240_000_000)

        if session.user.tier == .free && draft.imageData.count > 1 {
            throw AppError.network("Free tier supports 1 photo per log.")
        }

        var log = SipLog(
            id: UUID(),
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
            isPendingSync: false
        )

        feed.insert(log, at: 0)

        if let venueIndex = venues.firstIndex(where: { $0.id == draft.venue.id }) {
            let newCount = venues[venueIndex].reviewCount + 1
            let total = (venues[venueIndex].averageRating * Double(venues[venueIndex].reviewCount)) + Double(draft.rating)
            venues[venueIndex].reviewCount = newCount
            venues[venueIndex].averageRating = total / Double(newCount)
            log.venueName = venues[venueIndex].name
        }

        return log
    }

    func setFollow(session: UserSession, targetUserID: UUID, shouldFollow: Bool) async throws {
        _ = session
        try await Task.sleep(nanoseconds: 150_000_000)

        guard let targetIndex = users.firstIndex(where: { $0.id == targetUserID }) else {
            throw AppError.network("Could not find the profile.")
        }

        if shouldFollow {
            users[targetIndex].followerCount += 1
        } else {
            users[targetIndex].followerCount = max(0, users[targetIndex].followerCount - 1)
        }
    }

    func fetchFeed(session: UserSession) async throws -> [SipLog] {
        _ = session
        try await Task.sleep(nanoseconds: 90_000_000)
        return feed.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchPassport(session: UserSession) async throws -> [PassportStamp] {
        _ = session
        try await Task.sleep(nanoseconds: 90_000_000)
        return stamps
    }
}
