import SwiftUI
import MapKit

struct MapScreen: View {
    @EnvironmentObject private var store: AppStore

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var searchText: String = ""
    @State private var selectedCategory: VenueCategory? = nil

    var body: some View {
        ZStack(alignment: .top) {
            ColorToken.background.ignoresSafeArea()

            VStack(spacing: Spacing.md.rawValue) {
                searchBar
                categoryFilter

                Map(coordinateRegion: $region, annotationItems: filteredVenues) { venue in
                    MapAnnotation(coordinate: venue.coordinate) {
                        Button {
                            store.openVenueDetail(venue)
                        } label: {
                            VenueMapPin(venue: venue, isSelected: store.selectedVenue?.id == venue.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .environment(\.colorScheme, .light)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg.rawValue, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.lg.rawValue, style: .continuous)
                        .stroke(ColorToken.border, lineWidth: 1)
                }
                .frame(height: 310)

                if filteredVenues.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.sm.rawValue) {
                            ForEach(filteredVenues) { venue in
                                Button {
                                    store.openVenueDetail(venue)
                                } label: {
                                    venueRow(venue)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: filteredVenues.count)
                    }
                }
            }
            .padding(.horizontal, Spacing.page.rawValue)
            .padding(.top, Spacing.md.rawValue)
        }
        .overlay {
            SipBottomSheet(isPresented: venueSheetPresented, detent: 470) {
                if let venue = store.selectedVenue {
                    VenueDetailSheet(venue: venue)
                }
            }
        }
        .onAppear {
            centerRegionIfNeeded()
        }
        .onChange(of: store.venues.count) { _ in
            centerRegionIfNeeded()
        }
        .navigationTitle("Map")
    }

    private var filteredVenues: [Venue] {
        store.venues
            .filter { venue in
                if let selectedCategory {
                    switch selectedCategory {
                    case .coffee:
                        return venue.category == .coffee || venue.category == .both
                    case .matcha:
                        return venue.category == .matcha || venue.category == .both
                    case .both:
                        return true
                    case .other:
                        return venue.category == .other
                    }
                }
                return true
            }
            .filter { venue in
                let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else { return true }
                return venue.name.localizedCaseInsensitiveContains(query)
                    || venue.address.localizedCaseInsensitiveContains(query)
                    || venue.city.localizedCaseInsensitiveContains(query)
            }
    }

    private var venueSheetPresented: Binding<Bool> {
        Binding(
            get: { store.selectedVenue != nil },
            set: { isPresented in
                if !isPresented {
                    store.selectedVenue = nil
                }
            }
        )
    }

    private var searchBar: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(ColorToken.textSecondary)
            TextField("Search venues or city", text: $searchText)
                .textInputAutocapitalization(.words)
        }
        .padding(Spacing.md.rawValue)
        .background(ColorToken.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        }
    }

    private var categoryFilter: some View {
        HStack(spacing: Spacing.sm.rawValue) {
            ForEach([VenueCategory.coffee, .matcha, .both], id: \.self) { category in
                Button {
                    selectedCategory = selectedCategory == category ? nil : category
                } label: {
                    Text(category.rawValue.capitalized)
                        .sipLabel()
                        .padding(.horizontal, Spacing.sm.rawValue)
                        .padding(.vertical, Spacing.xs.rawValue)
                        .background(selectedCategory == category ? ColorToken.accent : ColorToken.surface)
                        .foregroundStyle(selectedCategory == category ? ColorToken.textOnAccent : ColorToken.textPrimary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm.rawValue) {
            Text("We're still discovering this city")
                .sipBody()
            Text("Pull to refresh or try another city")
                .sipLabel()

            if !trimmedQuery.isEmpty {
                SipButton(title: "Add \"\(trimmedQuery)\"") {
                    let input = CreateVenueInput(
                        name: trimmedQuery,
                        address: trimmedQuery,
                        city: store.city,
                        latitude: region.center.latitude,
                        longitude: region.center.longitude,
                        category: selectedCategory ?? .both
                    )
                    store.requestProtectedAction(.createVenue(input: input))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg.rawValue)
        .background(ColorToken.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg.rawValue, style: .continuous))
    }

    private func venueRow(_ venue: Venue) -> some View {
        HStack(spacing: Spacing.md.rawValue) {
            Circle()
                .fill(venue.category == .matcha ? ColorToken.matcha : ColorToken.accent)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 2) {
                Text(venue.name)
                    .sipBody()
                Text(venue.address)
                    .sipLabel()
                    .lineLimit(1)
            }
            Spacer()
            RatingBadge(text: String(format: "%.1f", venue.averageRating), emphasized: true)
        }
        .padding(Spacing.md.rawValue)
        .background(ColorToken.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous)
                .stroke(ColorToken.border, lineWidth: 1)
        }
    }

    private func centerRegionIfNeeded() {
        guard let first = filteredVenues.first else { return }
        region.center = first.coordinate
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
