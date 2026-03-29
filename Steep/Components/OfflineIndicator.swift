import SwiftUI

struct OfflineIndicator: View {
    var body: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            Image(systemName: "wifi.slash")
            Text("Offline mode")
                .sipLabel()
        }
        .padding(.horizontal, Spacing.lg.rawValue)
        .padding(.vertical, Spacing.sm.rawValue)
        .background(ColorToken.warning)
        .foregroundStyle(ColorToken.textOnAccent)
        .clipShape(Capsule())
        .padding(.top, Spacing.sm.rawValue)
    }
}
