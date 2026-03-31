import Foundation
import Supabase

final class SupabaseBackendService: BackendService {
    private let client: SupabaseClient
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let configuration: AppConfiguration

    init(configuration: AppConfiguration = .shared) {
        guard let url = configuration.supabaseURL,
              let key = configuration.supabasePublishableKey else {
            fatalError("Supabase configuration missing")
        }
        self.configuration = configuration
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func bootstrap(city: String, session: UserSession?) async throws -> BootstrapPayload {
        let allVenues: [Venue] = try await client.from("venues")
            .select("*")
            .execute()
            .value
        let normalizedCity = city.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let filtered = normalizedCity.isEmpty
            ? allVenues
            : allVenues.filter { $0.city.lowercased().contains(normalizedCity) }
        let active = allVenues.filter { $0.isActive }
        let activeFiltered = filtered.filter { $0.isActive }
        let venues = !activeFiltered.isEmpty ? activeFiltered : (!filtered.isEmpty ? filtered : active)

        async let feedTask: [SipLog] = (try? fetchPublicFeed()) ?? []
        async let usersTask: [UserProfile] = (try? fetchUsers()) ?? []
        async let stampsTask: [PassportStamp] = {
            guard let authSession = session else { return [] }
            return (try? fetchPassport(session: authSession)) ?? []
        }()

        return BootstrapPayload(
            venues: venues,
            feed: await feedTask,
            users: await usersTask,
            stamps: await stampsTask
        )
    }

    func restoreSession() async throws -> UserSession? {
        do {
            let session = try await client.auth.session
            return try await appSession(from: session)
        } catch {
            return nil
        }
    }

    func handleIncomingURL(_ url: URL) {
        Task {
            _ = try? await client.auth.session(from: url)
        }
    }
    
    func signIn(with provider: AuthProvider) async throws -> UserSession {
        let authSession =
        if let redirectTo = configuration.supabaseAuthRedirectURL {
            try await client.auth.signInWithOAuth(
                provider: provider == .apple ? .apple : .google,
                redirectTo: redirectTo
            )
        } else {
            try await client.auth.signInWithOAuth(
                provider: provider == .apple ? .apple : .google
            )
        }

        return try await appSession(from: authSession)
    }

    func completeOnboarding(session: UserSession, input: OnboardingInput) async throws -> UserProfile {
        return try await client.from("profiles")
            .update(input)
            .eq("id", value: session.user.id)
            .select()
            .single()
            .execute()
            .value
    }

    func createVenue(session: UserSession, input: CreateVenueInput) async throws -> Venue {
        _ = session
        let payload = CreateVenueDTO(from: input)
        return try await client.from("venues")
            .insert(payload)
            .select("*")
            .single()
            .execute()
            .value
    }

    func submitLog(session: UserSession, draft: DraftLog) async throws -> SipLog {
        let logDTO = SubmitLogDTO(from: draft, userID: session.user.id, username: session.user.username)
        
        return try await client.from("logs")
            .insert(logDTO)
            .select("*, venues(*), users(*)")
            .single()
            .execute()
            .value
    }

    func setFollow(session: UserSession, targetUserID: UUID, shouldFollow: Bool) async throws {
        if shouldFollow {
            let followDTO = FollowDTO(followerID: session.user.id, followingID: targetUserID)
            try await client.from("follows")
                .insert(followDTO)
                .execute()
        } else {
            try await client.from("follows")
                .delete()
                .eq("follower_id", value: session.user.id)
                .eq("following_id", value: targetUserID)
                .execute()
        }
    }

    func fetchFeed(session: UserSession) async throws -> [SipLog] {
        _ = session
        return try await fetchPublicFeed()
    }

    private func fetchPublicFeed() async throws -> [SipLog] {
        return try await client.from("logs")
            .select("*, venues(*), users(*)")
            .eq("is_public", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    private func fetchUsers() async throws -> [UserProfile] {
        return try await client.from("profiles")
            .select("*")
            .limit(10)
            .execute()
            .value
    }

    func fetchPassport(session: UserSession) async throws -> [PassportStamp] {
        return try await client.from("passport_stamps")
            .select("*")
            .eq("user_id", value: session.user.id)
            .execute()
            .value
    }

    private func appSession(from session: Session) async throws -> UserSession {
        let profile = try await fetchProfileOrFallback(userID: session.user.id, email: session.user.email)
        return UserSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            user: profile
        )
    }

    private func fetchProfileOrFallback(userID: UUID, email: String?) async throws -> UserProfile {
        do {
            return try await client.from("profiles")
                .select("*")
                .eq("id", value: userID)
                .single()
                .execute()
                .value
        } catch {
            let handleSeed = email?.split(separator: "@").first.map(String.init) ?? "sipuser"
            let username = handleSeed
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
            return UserProfile(
                id: userID,
                username: username,
                displayName: username.capitalized,
                avatarURL: nil,
                city: "Toronto",
                preference: .both,
                tier: .free,
                contributionXP: 0,
                followerCount: 0,
                followingCount: 0
            )
        }
    }
}

private struct SubmitLogDTO: Codable {
    let userID: UUID
    let venueID: UUID
    let venueName: String
    let username: String
    let rating: Int
    let note: String
    let drinkType: String
    let isPublic: Bool

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case venueID = "venue_id"
        case venueName = "venue_name"
        case username
        case rating
        case note
        case drinkType = "drink_type"
        case isPublic = "is_public"
    }

    init(from draft: DraftLog, userID: UUID, username: String) {
        self.userID = userID
        self.venueID = draft.venue.id
        self.venueName = draft.venue.name
        self.username = username
        self.rating = draft.rating
        self.note = draft.note
        self.drinkType = draft.drinkType.rawValue
        self.isPublic = draft.isPublic
    }
}

private struct CreateVenueDTO: Codable {
    let placeID: String
    let name: String
    let address: String
    let city: String
    let latitude: Double
    let longitude: Double
    let category: String
    let averageRating: Double
    let reviewCount: Int
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case placeID = "place_id"
        case name
        case address
        case city
        case latitude
        case longitude
        case category
        case averageRating = "average_rating"
        case reviewCount = "review_count"
        case isActive = "is_active"
    }

    init(from input: CreateVenueInput) {
        placeID = "user-\(UUID().uuidString.lowercased())"
        name = input.name
        address = input.address
        city = input.city
        latitude = input.latitude
        longitude = input.longitude
        category = input.category.rawValue
        averageRating = 0
        reviewCount = 0
        isActive = true
    }
}

private struct FollowDTO: Codable {
    let followerID: UUID
    let followingID: UUID

    enum CodingKeys: String, CodingKey {
        case followerID = "follower_id"
        case followingID = "following_id"
    }
}
