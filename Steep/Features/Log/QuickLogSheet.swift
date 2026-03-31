import SwiftUI
import PhotosUI

struct QuickLogSheet: View {
    @EnvironmentObject private var store: AppStore

    @State private var selectedVenueID: UUID?
    @State private var rating: Int = 0
    @State private var note: String = ""
    @State private var drinkType: DrinkPreference = .both
    @State private var isPublic: Bool = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImageData: [Data] = []
    @State private var isSubmitting: Bool = false
    @State private var inlineError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            Text("Quick log")
                .sipTitle()

            venuePicker

            Text("Rating")
                .sipLabel()
            RatingSelector(rating: $rating)

            TextField("What stood out?", text: $note, axis: .vertical)
                .lineLimit(3)
                .padding(Spacing.md.rawValue)
                .background(ColorToken.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous)
                        .stroke(ColorToken.border, lineWidth: 1)
                }

            HStack {
                Picker("Drink", selection: $drinkType) {
                    ForEach(DrinkPreference.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            Toggle("Post publicly", isOn: $isPublic)
                .sipLabel()

            HStack(spacing: Spacing.sm.rawValue) {
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: maxPhotoCount,
                    matching: .images
                ) {
                    HStack(spacing: Spacing.sm.rawValue) {
                        Image(systemName: "photo.on.rectangle")
                        Text("Add photo")
                            .sipBody()
                    }
                    .padding(.horizontal, Spacing.md.rawValue)
                    .padding(.vertical, Spacing.sm.rawValue)
                    .background(ColorToken.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous)
                            .stroke(ColorToken.border, lineWidth: 1)
                    }
                }
                .disabled(store.currentUser == nil)

                Text("\(selectedImageData.count) selected")
                    .sipLabel()
                    .monospacedDigit()
            }

            if let inlineError {
                InlineErrorBanner(message: inlineError)
            }

            SipButton(title: "Post", isLoading: isSubmitting) {
                Task { await post() }
            }
        }
        .padding(.top, Spacing.sm.rawValue)
        .onAppear {
            selectedVenueID = store.quickLogVenue?.id ?? store.venues.first?.id
        }
        .onChange(of: selectedPhotoItems.count) { _ in
            Task { await loadSelectedPhotos() }
        }
    }

    private var venuePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
            Text("Venue")
                .sipLabel()
            Picker("Venue", selection: Binding(get: {
                selectedVenueID ?? store.venues.first?.id ?? UUID()
            }, set: { selectedVenueID = $0 })) {
                ForEach(store.venues) { venue in
                    Text(venue.name).tag(venue.id)
                }
            }
            .pickerStyle(.menu)
            .padding(Spacing.md.rawValue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorToken.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous)
                    .stroke(ColorToken.border, lineWidth: 1)
            }
        }
    }

    private var maxPhotoCount: Int {
        guard let tier = store.currentUser?.tier else {
            return 0
        }
        return tier == .free ? 1 : 10
    }

    private func loadSelectedPhotos() async {
        guard store.currentUser != nil else {
            inlineError = "Sign in to add photos."
            selectedPhotoItems = []
            selectedImageData = []
            return
        }

        if selectedPhotoItems.count > maxPhotoCount {
            inlineError = "Free supports one photo per log. Upgrade to add more."
            selectedPhotoItems = Array(selectedPhotoItems.prefix(maxPhotoCount))
        }

        var loaded: [Data] = []
        for item in selectedPhotoItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                loaded.append(data)
            }
        }
        selectedImageData = loaded
        inlineError = nil
    }

    private func post() async {
        guard rating > 0 else {
            inlineError = "Please add a rating."
            return
        }

        guard let venueID = selectedVenueID,
              let venue = store.venues.first(where: { $0.id == venueID }) else {
            inlineError = "Select a venue."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        await store.submitLog(
            draft: DraftLog(
                temporaryID: UUID(),
                venue: venue,
                rating: rating,
                note: note,
                drinkType: drinkType,
                imageData: selectedImageData,
                isPublic: isPublic
            )
        )
    }
}
