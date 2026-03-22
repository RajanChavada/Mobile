import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var store: AppStore

    @State private var step: Int = 0
    @State private var preference: DrinkPreference = .both
    @State private var city: String = "Toronto"
    @State private var theme: ThemeOption = .warm
    @State private var enableProximity: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg.rawValue) {
            Text("Set up Sip")
                .sipTitle()

            if step == 0 {
                preferenceStep
            } else if step == 1 {
                cityStep
            } else {
                themeStep
            }

            HStack(spacing: Spacing.md.rawValue) {
                if step > 0 {
                    SipButton(title: "Back", style: .secondary, fullWidth: false) {
                        step -= 1
                    }
                }

                SipButton(title: step == 2 ? "Finish" : "Next") {
                    if step < 2 {
                        step += 1
                    } else {
                        Task {
                            await store.completeOnboarding(
                                OnboardingInput(
                                    preference: preference,
                                    city: city,
                                    theme: theme,
                                    enableProximity: enableProximity
                                )
                            )
                        }
                    }
                }
            }
        }
        .padding(.top, Spacing.sm.rawValue)
    }

    private var preferenceStep: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            Text("What do you usually sip?")
                .sipBody()

            HStack(spacing: Spacing.sm.rawValue) {
                ForEach(DrinkPreference.allCases) { option in
                    Button {
                        preference = option
                    } label: {
                        Text(option.title)
                            .sipBody()
                            .padding(.vertical, Spacing.sm.rawValue)
                            .frame(maxWidth: .infinity)
                            .background(preference == option ? ColorToken.accent : ColorToken.surface)
                            .foregroundStyle(preference == option ? ColorToken.textOnAccent : ColorToken.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var cityStep: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            Text("Where are you based?")
                .sipBody()

            TextField("City", text: $city)
                .textInputAutocapitalization(.words)
                .padding(Spacing.md.rawValue)
                .background(ColorToken.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.md.rawValue, style: .continuous)
                        .stroke(ColorToken.border, lineWidth: 1)
                }
        }
    }

    private var themeStep: some View {
        VStack(alignment: .leading, spacing: Spacing.md.rawValue) {
            Text("Pick your aesthetic")
                .sipBody()

            HStack(spacing: Spacing.sm.rawValue) {
                ForEach(ThemeOption.allCases) { option in
                    Button {
                        theme = option
                    } label: {
                        ThemePreviewCard(option: option, isSelected: theme == option)
                    }
                    .buttonStyle(.plain)
                }
            }

            Toggle(isOn: $enableProximity) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Discover spots nearby")
                        .sipBody()
                    Text("Location is used only if enabled")
                        .sipLabel()
                }
            }
            .toggleStyle(.switch)
        }
    }
}
