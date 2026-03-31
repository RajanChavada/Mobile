import Foundation
import Supabase

final class SupabaseBackendService: BackendService {
    private let client: SupabaseClient
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let authFallback: BackendService = MockBackendService()

    init(configuration: AppConfiguration = .shared) {
        guard let url = configuration.supabaseURL,
              let key = configuration.supabasePublishableKey else {
            fatalError("Supabase configuration missing")
        }
        
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func bootstrap(city: String, session: UserSession?) async throws -> BootstrapPayload {
        return try await withThrowingTaskGroup(of: BootstrapPayloadPart.self) { group in
            group.addTask {
                let venues: [Venue] = try await self.client.from("venues")
                    .select("*")
                    .execute()
                    .value
                let normalizedCity = city.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let filtered = normalizedCity.isEmpty
                    ? venues
                    : venues.filter { $0.city.lowercased().contains(normalizedCity) }
                let active = venues.filter { $0.isActive }
                let activeFiltered = filtered.filter { $0.isActive }

                if !activeFiltered.isEmpty { return .venues(activeFiltered) }
                if !filtered.isEmpty { return .venues(filtered) }
                return .venues(active.isEmpty ? venues : active)
            }
            
            group.addTask {
                let feed = try await self.fetchPublicFeed()
                return .feed(feed)
            }
            
            if let authSession = session, !authSession.accessToken.hasPrefix("mock_") {
                group.addTask {
                    let stamps = try await self.fetchPassport(session: authSession)
                    return .stamps(stamps)
                }
            }
            
            // For V1, we might just fetch the current user and some "suggested" users
            group.addTask {
                let users: [UserProfile] = try await self.client.from("profiles")
                    .select("*")
                    .limit(10)
                    .execute()
                    .value
                return .users(users)
            }
            
            var venues: [Venue] = []
            var feed: [SipLog] = []
            var users: [UserProfile] = []
            var stamps: [PassportStamp] = []
            
            for try await part in group {
                switch part {
                case .venues(let v): venues = v
                case .feed(let f): feed = f
                case .users(let u): users = u
                case .stamps(let s): stamps = s
                }
            }
            
            return BootstrapPayload(venues: venues, feed: feed, users: users, stamps: stamps)
        }
    }
    
    private enum BootstrapPayloadPart {
        case venues([Venue])
        case feed([SipLog])
        case users([UserProfile])
        case stamps([PassportStamp])
    }

    func signIn(with provider: AuthProvider) async throws -> UserSession {
        // OAuth callback wiring is pending; keep the UI flow functional meanwhile.
        return try await authFallback.signIn(with: provider)
    }

    func completeOnboarding(session: UserSession, input: OnboardingInput) async throws -> UserProfile {
        if session.accessToken.hasPrefix("mock_") {
            return try await authFallback.completeOnboarding(session: session, input: input)
        }
        return try await client.from("profiles")
            .update(input)
            .eq("id", value: session.user.id)
            .select()
            .single()
            .execute()
            .value
    }

    func submitLog(session: UserSession, draft: DraftLog) async throws -> SipLog {
        if session.accessToken.hasPrefix("mock_") {
            return try await authFallback.submitLog(session: session, draft: draft)
        }

        let logDTO = SubmitLogDTO(from: draft, userID: session.user.id, username: session.user.username)
        
        return try await client.from("logs")
            .insert(logDTO)
            .select("*, venues(*), users(*)")
            .single()
            .execute()
            .value
    }

    func setFollow(session: UserSession, targetUserID: UUID, shouldFollow: Bool) async throws {
        if session.accessToken.hasPrefix("mock_") {
            try await authFallback.setFollow(session: session, targetUserID: targetUserID, shouldFollow: shouldFollow)
            return
        }

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

    func fetchPassport(session: UserSession) async throws -> [PassportStamp] {
        return try await client.from("passport_stamps")
            .select("*")
            .eq("user_id", value: session.user.id)
            .execute()
            .value
    }

    // authedFunction removed in favor of Supabase SDK
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

private struct FollowDTO: Codable {
    let followerID: UUID
    let followingID: UUID

    enum CodingKeys: String, CodingKey {
        case followerID = "follower_id"
        case followingID = "following_id"
    }
}
