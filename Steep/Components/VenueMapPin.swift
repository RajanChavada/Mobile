import SwiftUI

struct VenueMapPin: View {
    let venue: Venue
    let isSelected: Bool

    var body: some View {
        VStack(spacing: Spacing.xs.rawValue) {
            if isSelected {
                Text(venue.name)
                    .sipLabel()
                    .padding(.horizontal, Spacing.sm.rawValue)
                    .padding(.vertical, Spacing.xs.rawValue)
                    .background(ColorToken.surface)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule().stroke(ColorToken.border, lineWidth: 1)
                    }
            }

            Image(systemName: iconName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(ColorToken.textOnAccent)
                .frame(width: isSelected ? 38 : 30, height: isSelected ? 38 : 30)
                .background(isSelected ? ColorToken.accent : ColorToken.matcha)
                .clipShape(Circle())
                .shadow(color: ColorToken.shadow, radius: 6, y: 3)
        }
    }

    private var iconName: String {
        switch venue.category {
        case .coffee: return "cup.and.saucer.fill"
        case .matcha: return "leaf.fill"
        case .both: return "circle.hexagongrid.fill"
        case .other: return "mappin"
        }
    }
}
