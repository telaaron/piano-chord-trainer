// OnboardingView — first-launch ritual: pick a daily goal + preferred time,
// then drop into Today. Writes HabitProfile.onboardingDone so it shows once.
// A calm, paged flow (HIG onboarding), brand amber accent.

import SwiftUI
import MusicEngine

struct OnboardingView: View {
    @Environment(\.palette) private var palette
    var onFinish: () -> Void

    @State private var page = 0
    @State private var goalMinutes = 5
    @State private var preferredTime: TimeOfDay = .evening

    private let goals = [2, 5, 10, 15, 20]

    var body: some View {
        VStack(spacing: Theme.space6) {
            Spacer()
            TabView(selection: $page) {
                welcomePage.tag(0)
                goalPage.tag(1)
                timePage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(maxHeight: 460)

            Button {
                if page < 2 { withAnimation { page += 1 } } else { finish() }
            } label: {
                Text(CoachL10n.t(page < 2 ? "ui.continue" : "habit.onboard_start"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.space4)
                    .background(palette.primary)
                    .foregroundStyle(palette.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
            }
            .padding(.horizontal, Theme.space4)
            .padding(.bottom, Theme.space5)
        }
        .screenBackground()
    }

    private var welcomePage: some View {
        VStack(spacing: Theme.space4) {
            ZStack {
                Circle().fill(palette.primary.opacity(0.12)).frame(width: 132, height: 132)
                Image(systemName: "pianokeys")
                    .font(.system(size: 60, weight: .regular))
                    .foregroundStyle(palette.primary)
                    .symbolRenderingMode(.hierarchical)
            }
            Text("jazzchords")
                .font(Display.title(38))
                .foregroundStyle(palette.text)
            Text(CoachL10n.t("onboarding.tagline"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.textMuted)
                .padding(.horizontal, Theme.space6)
        }
    }

    private var goalPage: some View {
        VStack(spacing: Theme.space5) {
            Text(CoachL10n.t("habit.onboard_daily"))
                .font(Display.headline(24)).foregroundStyle(palette.text)
            Text(CoachL10n.t("habit.onboard_time_title"))
                .font(.subheadline).foregroundStyle(palette.textMuted)
                .multilineTextAlignment(.center)
            VStack(spacing: Theme.space2) {
                ForEach(goals, id: \.self) { m in
                    // Counted noun: "1 Minute" / "5 Minuten".
                    selectRow(title: CoachL10n.plural("count.minutes", m), selected: goalMinutes == m) { goalMinutes = m }
                }
            }
            .padding(.horizontal, Theme.space5)
        }
    }

    private var timePage: some View {
        VStack(spacing: Theme.space5) {
            Text(CoachL10n.t("habit.onboard_when_title"))
                .font(Display.headline(24)).foregroundStyle(palette.text)
            VStack(spacing: Theme.space2) {
                selectRow(title: CoachL10n.t("habit.onboard_morning"), selected: preferredTime == .morning) { preferredTime = .morning }
                selectRow(title: CoachL10n.t("habit.onboard_afternoon"), selected: preferredTime == .afternoon) { preferredTime = .afternoon }
                selectRow(title: CoachL10n.t("habit.onboard_evening"), selected: preferredTime == .evening) { preferredTime = .evening }
            }
            .padding(.horizontal, Theme.space5)
        }
    }

    private func selectRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(palette.text)
                Spacer()
                if selected { Image(systemName: "checkmark").foregroundStyle(palette.primary) }
            }
            .padding(Theme.space4)
            .background(selected ? palette.primary.opacity(0.15) : palette.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius)
                    .stroke(selected ? palette.primary : palette.border, lineWidth: selected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        }
        .buttonStyle(.plain)
    }

    private func finish() {
        HabitStore.shared.completeOnboarding(dailyGoalMinutes: goalMinutes, preferredTime: preferredTime)
        onFinish()
    }
}
