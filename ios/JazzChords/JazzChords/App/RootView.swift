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

/// Shared chrome state: Heute opens Settings from its profile circle
/// (the navigation bar is hidden on tab roots in the editorial design).
@MainActor @Observable
final class AppChrome {
    var showSettings = false
}

/// The one entry to Settings: the profile circle on Heute (spec §1).
struct SettingsEntryButton: View {
    @Environment(AppChrome.self) private var chrome

    var body: some View {
        ProfileCircleButton(email: AccountStore.shared.email) { chrome.showSettings = true }
    }
}

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var selection: AppSection = .today
    @State private var sidebarSelection: AppSection? = .today
    @State private var chrome = AppChrome()
    @State private var appearance = AppearanceStore.shared
    @State private var habits = HabitStore.shared
    @State private var showOnboarding = !HabitStore.shared.profile.onboardingDone

    var body: some View {
        // Brand faces read the content size from here (see Display.contentSize);
        // children render after this body, so they see the current value.
        let _ = (Display.contentSize = UIContentSizeCategory(typeSize))
        Group {
            if hSize == .regular {
                iPadLayout
            } else {
                iPhoneLayout
            }
        }
        // Rebuild on a Dynamic Type change so frozen brand fonts re-resolve.
        .id(typeSize)
        .environment(\.palette, Theme.palette(for: scheme))
        .environment(chrome)
        .tint(Theme.palette(for: scheme).action)
        .sheet(isPresented: $chrome.showSettings) {
            NavigationStack { SettingsView() }
                .environment(\.palette, Theme.palette(for: scheme))
                // Opaque: a translucent sheet lets the content behind bleed through.
                .presentationBackground(Theme.palette(for: scheme).canvas)
                .presentationDetents([.large])
                .preferredColorScheme(appearance.scheme)
        }
        .preferredColorScheme(appearance.scheme)
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
                        // Tab roots carry their own EditorialHeader + settings button.
                        .toolbar(.hidden, for: .navigationBar)
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
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Theme.palette(for: scheme).canvas)
            .safeAreaInset(edge: .top) {
                Text("JazzChords")
                    .font(Display.serif(28))
                    .foregroundStyle(Theme.palette(for: scheme).ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.space4)
            }
        } detail: {
            NavigationStack {
                sectionView(sidebarSelection ?? .today)
                    // Keep the bar (it carries the sidebar toggle) but empty and
                    // transparent; the EditorialHeader has the title and settings.
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.hidden, for: .navigationBar)
            }
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
