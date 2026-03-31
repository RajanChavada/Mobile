import Foundation

struct AppConfiguration {
    let supabaseURL: URL?
    let supabasePublishableKey: String?
    let supabaseAuthRedirectURL: URL?
    let supabaseSecret: String?
    let hasClientGoogleKey: Bool

    static let shared = AppConfiguration()

    init(environment: [String: String] = ProcessInfo.processInfo.environment) {
        let bundle = Bundle.main.infoDictionary ?? [:]

        let rawURL = Self.resolvedValue(
            environment["SUPABASE_URL"],
            bundle["SUPABASE_URL"] as? String
        )
        if let rawURL, !rawURL.isEmpty {
            supabaseURL = URL(string: rawURL)
        } else {
            supabaseURL = nil
        }

        supabasePublishableKey = Self.resolvedValue(
            environment["SUPABASE_PUBLISHABLE"],
            bundle["SUPABASE_PUBLISHABLE"] as? String
        )
        if let redirectValue = Self.resolvedValue(
            environment["SUPABASE_AUTH_REDIRECT_URL"],
            bundle["SUPABASE_AUTH_REDIRECT_URL"] as? String
        ) {
            supabaseAuthRedirectURL = URL(string: redirectValue)
        } else {
            supabaseAuthRedirectURL = nil
        }
        supabaseSecret = Self.resolvedValue(
            environment["SUPABASE_SECRET"],
            bundle["SUPABASE_SECRET"] as? String
        )
        hasClientGoogleKey = Self.resolvedValue(
            environment["GOOGLE_MAPS_API"] ?? environment["GOOGLE_API_KEY"],
            bundle["GOOGLE_MAPS_API"] as? String ?? bundle["GOOGLE_API_KEY"] as? String
        ) != nil
    }

    var canUseSupabase: Bool {
        supabaseURL != nil && !(supabasePublishableKey?.isEmpty ?? true)
    }

    var needsSecretWarning: Bool {
        !(supabaseSecret?.isEmpty ?? true)
    }

    private static func resolvedValue(_ primary: String?, _ fallback: String?) -> String? {
        let value = (primary?.isEmpty == false ? primary : fallback)?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, !value.isEmpty else { return nil }
        // If build settings were not resolved, Xcode leaves placeholders like $(SUPABASE_URL)
        if value.hasPrefix("$(") && value.hasSuffix(")") {
            return nil
        }
        return value
    }
}
