// Root navigation. Adaptive per HIG: iPhone (compact) → tab bar; iPad (regular)
// → sidebar / split view. Tabs are the four peer sections; Settings is a sheet.

import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case today, practice, learn, progress
    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return CoachL10n.t("nav.today")
        case .practice: return CoachL10n.t("nav.practice")
        case .learn: return CoachL10n.t("nav.learn")
        case .progress: return CoachL10n.t("nav.progress")
        }
    }

    var systemImage: String {
        switch self {
        case .today: return "sun.max"
        case .practice: return "pianokeys"
        case .learn: return "book"
        case .progress: return "chart.line.uptrend.xyaxis"
        }
    }
}

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.colorScheme) private var scheme
    @State private var selection: AppSection = .today
    @State private var sidebarSelection: AppSection? = .today
    @State private var showSettings = false
    @State private var habits = HabitStore.shared
    @State private var showOnboarding = !HabitStore.shared.profile.onboardingDone

    var body: some View {
        Group {
            if hSize == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        .environment(\.palette, Theme.palette(for: scheme))
        .sheet(isPresented: $showSettings) {
            NavigationStack { SettingsView() }
                .presentationDetents(hSize == .regular ? [.large] : [.medium, .large])
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView { showOnboarding = false }
                .environment(\.palette, Theme.palette(for: scheme))
        }
    }

    // iPhone: tab bar (≤5 items, HIG).
    private var iPhoneLayout: some View {
        TabView(selection: $selection) {
            ForEach(AppSection.allCases) { section in
                NavigationStack {
                    sectionView(section)
                        .toolbar { settingsToolbarItem }
                }
                .tabItem { Label(section.title, systemImage: section.systemImage) }
                .tag(section)
            }
        }
    }

    // iPad: sidebar + detail.
    private var iPadLayout: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $sidebarSelection) { section in
                Label(section.title, systemImage: section.systemImage).tag(section)
            }
            .navigationTitle("jazzchords")
            .toolbar { settingsToolbarItem }
        } detail: {
            NavigationStack { sectionView(sidebarSelection ?? .today) }
        }
    }

    @ToolbarContentBuilder
    private var settingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button { showSettings = true } label: { Image(systemName: "gearshape") }
                .accessibilityLabel(CoachL10n.t("settings.open_settings"))
        }
    }

    @ViewBuilder
    private func sectionView(_ section: AppSection) -> some View {
        switch section {
        case .today: TodayView()
        case .practice: PracticeView()
        case .learn: LearnView()
        case .progress: ProgressView_()
        }
    }
}
