// Appearance — the player's light/dark choice (Settings › Darstellung).
// "Wie iPhone" follows the system; the choice is stored in UserDefaults.

import SwiftUI
import Observation

enum Appearance: String, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { rawValue }

    /// Unknown or missing stored values fall back to following the system.
    init(stored: String?) {
        self = stored.flatMap(Appearance.init(rawValue:)) ?? .system
    }

    /// The scheme to force, or nil to follow the system.
    nonisolated static func scheme(_ appearance: Appearance) -> ColorScheme? {
        switch appearance {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var label: String {
        switch self {
        case .light: return SettingsText.t("Light", "Hell")
        case .dark: return SettingsText.t("Dark", "Dunkel")
        case .system: return SettingsText.t("Like iPhone", "Wie iPhone")
        }
    }
}

@MainActor @Observable
final class AppearanceStore {
    static let shared = AppearanceStore()
    private static let key = "appearance"

    var appearance: Appearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Self.key) }
    }

    var scheme: ColorScheme? { Appearance.scheme(appearance) }

    private init() {
        appearance = Appearance(stored: UserDefaults.standard.string(forKey: Self.key))
    }
}
