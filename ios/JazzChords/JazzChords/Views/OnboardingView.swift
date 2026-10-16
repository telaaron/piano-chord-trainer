// OnboardingView — first-launch ritual: pick a daily goal + preferred time,
// opt in (or not) to anonymous usage data, then drop into Today. Writes
// HabitProfile.onboardingDone so it shows once.
// A calm, paged flow (HIG onboarding), brand amber accent.

import SwiftUI
import MusicEngine

struct OnboardingView: View {
    @Environment(\.palette) private var palette
    var onFinish: () -> Void

    @State private var page = 0
    @State private var goalMinutes = 5
    @State private var preferredTime: TimeOfDay = .evening
    /// Anonymous usage data is opt-in: nothing is preselected, and skipping the
    /// choice counts as "no".
    @State private var shareUsage: Bool?

    private let goals = [2, 5, 10, 15, 20]
    private let lastPage = 3

    var body: some View {
        VStack(spacing: Theme.space6) {
            // The pager fills the screen and centres each page, so the content
            // sits at eye level instead of under a block of empty space.
            TabView(selection: $page) {
                welcomePage.tag(0)
                goalPage.tag(1)
                timePage.tag(2)
                usagePage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(maxHeight: .infinity)

            Button {
                if page < lastPage { withAnimation { page += 1 } } else { finish() }
            } label: {
                Text(CoachL10n.t(page < lastPage ? "ui.continue" : "habit.onboard_start"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.space4)
                    .background(palette.action)
                    .foregroundStyle(palette.onAction)
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
                Circle().fill(palette.action.opacity(0.12)).frame(width: 132, height: 132)
                Image(systemName: "pianokeys")
                    .font(.system(size: 60, weight: .regular))
                    .foregroundStyle(palette.action)
                    .symbolRenderingMode(.hierarchical)
            }
            Text("jazzchords")
                .font(Display.title(38))
                .foregroundStyle(palette.ink)
            Text(CoachL10n.t("onboarding.tagline"))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.inkMuted)
                .padding(.horizontal, Theme.space6)
        }
    }

    private var goalPage: some View {
        VStack(spacing: Theme.space5) {
            Text(CoachL10n.t("habit.onboard_daily"))
                .font(Display.headline(24)).foregroundStyle(palette.ink)
            Text(CoachL10n.t("habit.onboard_time_title"))
                .font(.subheadline).foregroundStyle(palette.inkMuted)
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
                .font(Display.headline(24)).foregroundStyle(palette.ink)
            VStack(spacing: Theme.space2) {
                selectRow(title: CoachL10n.t("habit.onboard_morning"), selected: preferredTime == .morning) { preferredTime = .morning }
                selectRow(title: CoachL10n.t("habit.onboard_afternoon"), selected: preferredTime == .afternoon) { preferredTime = .afternoon }
                selectRow(title: CoachL10n.t("habit.onboard_evening"), selected: preferredTime == .evening) { preferredTime = .evening }
            }
            .padding(.horizontal, Theme.space5)
        }
    }

    private var usagePage: some View {
        VStack(spacing: Theme.space5) {
            Text(CoachL10n.t("onboarding.usage_title"))
                .font(Display.headline(24)).foregroundStyle(palette.ink)
                .multilineTextAlignment(.center)
            Text(CoachL10n.t(CoachL10n.privacyDesc))
                .font(.subheadline).foregroundStyle(palette.inkMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.space5)
            VStack(spacing: Theme.space2) {
                selectRow(title: CoachL10n.t("onboarding.usage_yes"), selected: shareUsage == true) { shareUsage = true }
                selectRow(title: CoachL10n.t("onboarding.usage_no"), selected: shareUsage == false) { shareUsage = false }
            }
            .padding(.horizontal, Theme.space5)
        }
    }

    private func selectRow(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).foregroundStyle(palette.ink)
                Spacer()
                if selected { Image(systemName: "checkmark").foregroundStyle(palette.action) }
            }
            .padding(Theme.space4)
            .background(selected ? palette.action.opacity(0.15) : palette.group)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius)
                    .stroke(selected ? palette.action : palette.hairline, lineWidth: selected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
        }
        .buttonStyle(.plain)
    }

    private func finish() {
        TelemetryService.shared.setEnabled(shareUsage == true)
        HabitStore.shared.completeOnboarding(dailyGoalMinutes: goalMinutes, preferredTime: preferredTime)
        onFinish()
    }
}
