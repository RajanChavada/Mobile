import Foundation
import Supabase

final class SupabaseBackendService: BackendService {
    private let client: SupabaseClient
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

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
        let authSession = try requireAuthenticatedSession(session)
        
        return try await withThrowingTaskGroup(of: BootstrapPayloadPart.self) { group in
            group.addTask {
                let venues: [Venue] = try await self.client.from("venues")
                    .select("*")
                    .eq("city", value: city)
                    .execute()
                    .value
                return .venues(venues)
            }
            
            group.addTask {
                let feed = try await self.fetchFeed(session: authSession)
                return .feed(feed)
            }
            
            group.addTask {
                let stamps = try await self.fetchPassport(session: authSession)
                return .stamps(stamps)
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
        _ = provider
        throw AppError.unsupported("Wire Sign in with Apple/Google through Supabase Auth SDK in app target.")
    }

    func completeOnboarding(session: UserSession, input: OnboardingInput) async throws -> UserProfile {
        let profileData: [String: AnyJSON] = [
            "preference": .string(input.preference.rawValue),
            "city": .string(input.city),
            "theme": .string(input.theme.rawValue),
            "enable_proximity": .boolean(input.enableProximity)
        ]
        
        return try await client.from("profiles")
            .update(profileData)
            .eq("id", value: session.user.id)
            .select()
            .single()
            .execute()
            .value
    }

    func submitLog(session: UserSession, draft: DraftLog) async throws -> SipLog {
        // In a real app, you'd upload photos to Supabase Storage first.
        // For this refactor, we'll focus on the log record insertion.
        let logData: [String: AnyJSON] = [
            "user_id": .string(session.user.id.uuidString),
            "venue_id": .string(draft.venue.id.uuidString),
            "rating": .integer(draft.rating),
            "note": .string(draft.note),
            "drink_type": .string(draft.drinkType.rawValue),
            "is_public": .boolean(draft.isPublic),
            "venue_name": .string(draft.venue.name),
            "username": .string(session.user.username)
        ]
        
        return try await client.from("logs")
            .insert(logData)
            .select("*, venues(*), users(*)")
            .single()
            .execute()
            .value
    }

    func setFollow(session: UserSession, targetUserID: UUID, shouldFollow: Bool) async throws {
        if shouldFollow {
            let followData: [String: AnyJSON] = [
                "follower_id": .string(session.user.id.uuidString),
                "following_id": .string(targetUserID.uuidString)
            ]
            try await client.from("follows")
                .insert(followData)
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

    private func requireAuthenticatedSession(_ session: UserSession?) throws -> UserSession {
        guard let session else {
            throw AppError.unauthenticated
        }
        return session
    }

    // authedFunction removed in favor of Supabase SDK
}
