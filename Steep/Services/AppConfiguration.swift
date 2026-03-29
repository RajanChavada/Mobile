import Foundation

struct AppConfiguration {
    let supabaseURL: URL?
    let supabasePublishableKey: String?
    let supabaseSecret: String?
    let hasClientGoogleKey: Bool

    static let shared = AppConfiguration()

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        if let rawURL = environment["SUPABASE_URL"] {
            supabaseURL = URL(string: rawURL)
        } else {
            supabaseURL = nil
        }

        supabasePublishableKey = environment["SUPABASE_PUBLISHABLE"]
        supabaseSecret = environment["SUPABASE_SECRET"]
        hasClientGoogleKey = (environment["GOOGLE_MAPS_API"] ?? environment["GOOGLE_API_KEY"]) != nil
    }

    var canUseSupabase: Bool {
        supabaseURL != nil && !(supabasePublishableKey?.isEmpty ?? true)
    }

    var needsSecretWarning: Bool {
        !(supabaseSecret?.isEmpty ?? true)
    }
}
