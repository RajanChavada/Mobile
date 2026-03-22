import Foundation

final class SupabaseBackendService: BackendService {
    private let configuration: AppConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(configuration: AppConfiguration = .shared, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func bootstrap(city: String, session: UserSession?) async throws -> BootstrapPayload {
        let authSession = try requireAuthenticatedSession(session)
        let body = BootstrapRequest(city: city)
        return try await authedFunction(
            path: "bootstrap",
            payload: body,
            token: authSession.accessToken,
            response: BootstrapDTO.self
        ).toDomain
    }

    func signIn(with provider: AuthProvider) async throws -> UserSession {
        _ = provider
        throw AppError.unsupported("Wire Sign in with Apple/Google through Supabase Auth SDK in app target.")
    }

    func completeOnboarding(session: UserSession, input: OnboardingInput) async throws -> UserProfile {
        let payload = CompleteOnboardingRequest(input: input)
        let response: UserProfile = try await authedFunction(path: "complete-onboarding", payload: payload, token: session.accessToken, response: UserProfile.self)
        return response
    }

    func submitLog(session: UserSession, draft: DraftLog) async throws -> SipLog {
        let payload = SubmitLogDTO(from: draft)
        return try await authedFunction(path: "submit-log", payload: payload, token: session.accessToken, response: SipLog.self)
    }

    func setFollow(session: UserSession, targetUserID: UUID, shouldFollow: Bool) async throws {
        let payload = SetFollowRequest(targetUserID: targetUserID, shouldFollow: shouldFollow)
        let _: EmptyResponse = try await authedFunction(path: "set-follow", payload: payload, token: session.accessToken, response: EmptyResponse.self)
    }

    func fetchFeed(session: UserSession) async throws -> [SipLog] {
        let response: FeedDTO = try await authedFunction(path: "feed", payload: EmptyRequest(), token: session.accessToken, response: FeedDTO.self)
        return response.items
    }

    func fetchPassport(session: UserSession) async throws -> [PassportStamp] {
        let response: PassportDTO = try await authedFunction(path: "passport", payload: EmptyRequest(), token: session.accessToken, response: PassportDTO.self)
        return response.stamps
    }

    private func requireAuthenticatedSession(_ session: UserSession?) throws -> UserSession {
        guard let session else {
            throw AppError.unauthenticated
        }
        return session
    }

    private func authedFunction<Response: Decodable>(
        path: String,
        payload: some Encodable,
        token: String,
        response: Response.Type
    ) async throws -> Response {
        guard let baseURL = configuration.supabaseURL else {
            throw AppError.missingConfiguration("SUPABASE_URL")
        }

        guard let publishableKey = configuration.supabasePublishableKey, !publishableKey.isEmpty else {
            throw AppError.missingConfiguration("SUPABASE_PUBLISHABLE")
        }

        let endpoint = baseURL.appending(path: "functions/v1/\(path)")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.httpBody = try encoder.encode(payload)

        let (data, urlResponse) = try await session.data(for: request)

        guard let http = urlResponse as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown network error"
            throw AppError.network(message)
        }

        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }

        return try decoder.decode(Response.self, from: data)
    }
}

private struct EmptyResponse: Codable {}
private struct EmptyRequest: Codable {}

private struct BootstrapRequest: Codable {
    let city: String
}

private struct CompleteOnboardingRequest: Codable {
    let preference: String
    let city: String
    let theme: String
    let enableProximity: Bool

    init(input: OnboardingInput) {
        preference = input.preference.rawValue
        city = input.city
        theme = input.theme.rawValue
        enableProximity = input.enableProximity
    }
}

private struct SetFollowRequest: Codable {
    let targetUserID: String
    let shouldFollow: Bool

    enum CodingKeys: String, CodingKey {
        case targetUserID = "target_user_id"
        case shouldFollow = "should_follow"
    }

    init(targetUserID: UUID, shouldFollow: Bool) {
        self.targetUserID = targetUserID.uuidString
        self.shouldFollow = shouldFollow
    }
}

private struct SubmitLogDTO: Codable {
    let venueID: UUID
    let rating: Int
    let note: String
    let drinkType: DrinkPreference
    let isPublic: Bool

    init(from draft: DraftLog) {
        venueID = draft.venue.id
        rating = draft.rating
        note = draft.note
        drinkType = draft.drinkType
        isPublic = draft.isPublic
    }
}

private struct FeedDTO: Codable {
    let items: [SipLog]
}

private struct PassportDTO: Codable {
    let stamps: [PassportStamp]
}

private struct BootstrapDTO: Codable {
    let venues: [Venue]
    let feed: [SipLog]
    let users: [UserProfile]
    let stamps: [PassportStamp]

    var toDomain: BootstrapPayload {
        BootstrapPayload(venues: venues, feed: feed, users: users, stamps: stamps)
    }
}
