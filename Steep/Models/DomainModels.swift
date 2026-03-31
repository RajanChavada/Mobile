import Foundation
import CoreLocation

enum AppTab: Hashable {
    case map
    case feed
    case passport
    case profile
}

enum DrinkPreference: String, Codable, CaseIterable, Identifiable {
    case coffee
    case matcha
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coffee: return "Coffee"
        case .matcha: return "Matcha"
        case .both: return "Both"
        }
    }
}

enum VenueCategory: String, Codable, CaseIterable, Identifiable {
    case coffee
    case matcha
    case both
    case other

    var id: String { rawValue }
}

enum SubscriptionTier: String, Codable, CaseIterable {
    case free
    case sipPass = "sip_pass"
    case curator

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .sipPass: return "Sip Pass"
        case .curator: return "Curator"
        }
    }

    var monthlyPriceLabel: String {
        switch self {
        case .free: return "$0"
        case .sipPass: return "$4.99/mo"
        case .curator: return "$8.99/mo"
        }
    }
}

enum AuthProvider {
    case apple
    case google
}

enum ThemeOption: String, Codable, CaseIterable, Identifiable {
    case warm
    case blossom
    case matcha

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

enum AuthState {
    case guest
    case authenticated(UserSession)

    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
}

struct UserSession {
    let accessToken: String
    let refreshToken: String?
    var user: UserProfile
}

struct UserProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var username: String
    var displayName: String
    var avatarURL: URL?
    var city: String
    var preference: DrinkPreference
    var tier: SubscriptionTier
    var contributionXP: Int
    var followerCount: Int
    var followingCount: Int
}

struct Venue: Identifiable, Codable, Equatable {
    let id: UUID
    let placeID: String
    var name: String
    var address: String
    var city: String
    var latitude: Double
    var longitude: Double
    var category: VenueCategory
    var averageRating: Double
    var reviewCount: Int
    var isActive: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct SipLog: Identifiable, Codable, Equatable {
    let id: UUID
    let userID: UUID
    let venueID: UUID
    var venueName: String
    var username: String
    var rating: Int
    var note: String
    var drinkType: DrinkPreference
    var isPublic: Bool
    var photoURLs: [URL]
    var createdAt: Date
    var isPendingSync: Bool
}

struct PassportStamp: Identifiable, Codable, Equatable {
    let id: UUID
    let city: String
    let neighbourhood: String
    let month: String
    let unlocked: Bool
}

struct OnboardingInput: Codable {
    let preference: DrinkPreference
    let city: String
    let theme: ThemeOption
    let enableProximity: Bool

    enum CodingKeys: String, CodingKey {
        case preference
        case city
        case theme
        case enableProximity = "enable_proximity"
    }
}

struct DraftLog: Codable {
    let temporaryID: UUID
    let venue: Venue
    let rating: Int
    let note: String
    let drinkType: DrinkPreference
    let imageData: [Data]
    let isPublic: Bool
}

struct CreateVenueInput: Codable {
    let name: String
    let address: String
    let city: String
    let latitude: Double
    let longitude: Double
    let category: VenueCategory
}

enum ProtectedAction {
    case log(venue: Venue?)
    case follow(userID: UUID)
    case saveVenue(venueID: UUID)
    case createVenue(input: CreateVenueInput)
}

enum AppError: LocalizedError {
    case unauthenticated
    case missingConfiguration(String)
    case network(String)
    case unsupported(String)

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "You need to be signed in for this action."
        case .missingConfiguration(let key):
            return "Missing configuration: \(key)."
        case .network(let message):
            return message
        case .unsupported(let message):
            return message
        }
    }
}
