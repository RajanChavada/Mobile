import SwiftUI

struct UserAvatar: View {
    let profile: UserProfile
    var size: CGFloat = 40

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let avatarURL = profile.avatarURL {
                    AsyncImage(url: avatarURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            initialsView
                        }
                    }
                } else {
                    initialsView
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(ColorToken.surface, lineWidth: 1.5))

            if profile.tier != .free {
                Circle()
                    .fill(ColorToken.accent)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: size * 0.12, weight: .bold))
                            .foregroundStyle(ColorToken.textOnAccent)
                    }
            }
        }
    }

    private var initialsView: some View {
        Circle()
            .fill(ColorToken.accentSoft)
            .overlay {
                Text(initials)
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .foregroundStyle(ColorToken.textPrimary)
            }
    }

    private var initials: String {
        let names = profile.displayName.split(separator: " ").prefix(2)
        return names.map { String($0.prefix(1)) }.joined().uppercased()
    }
}
