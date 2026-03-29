import Foundation

struct SalaryNormalisationService {
    static func normalise(_ raw: String) async -> String {
        await Task.detached(priority: .utility) {
            raw
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }.value
    }
}
