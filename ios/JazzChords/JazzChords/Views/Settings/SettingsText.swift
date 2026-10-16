// Copy for the settings sheet and the account card (row F, spec §2). Uses the
// app-wide language decision so it switches together with everything else.

import Foundation

enum SettingsText {
    static func t(_ en: String, _ de: String) -> String { CoachL10n.isGerman ? de : en }

    static var title: String { t("Settings", "Einstellungen") }
    static var done: String { CoachL10n.t("ui.done") }

    // Account card
    static var accountEyebrow: String { t("YOUR ACCOUNT", "DEIN KONTO") }
    static var accountPitch: String {
        t("Pick up exactly where you left off — on iPhone, iPad and in the browser.",
          "Auf iPhone, iPad und im Browser genau da weitermachen, wo du warst.")
    }
    static var signInEmail: String { t("Sign in with e-mail", "Mit E-Mail anmelden") }
    static var sameAccount: String { t("Same account as on jazzchords.app", "Gleiches Konto wie auf jazzchords.app") }
    static var signOut: String { t("Sign out", "Abmelden") }
    static var deleteAccount: String { t("Delete account", "Konto löschen") }
    static var deleteConfirmTitle: String { t("Delete your account?", "Konto wirklich löschen?") }
    static var deleteConfirmMessage: String {
        t("Your account and synced progress are deleted for good. Progress on this device stays.",
          "Dein Konto und der synchronisierte Fortschritt werden endgültig gelöscht. Der Fortschritt auf diesem Gerät bleibt.")
    }
    static func synced(at time: String) -> String { t("Synced · last \(time)", "Synchronisiert · zuletzt \(time)") }
    static var syncing: String { t("Syncing…", "Synchronisiere…") }
    static var offline: String { t("Offline, will catch up", "Offline, wird nachgeholt") }
    static var notSynced: String { t("Not synced yet", "Noch nicht synchronisiert") }

    // Sections
    static var practice: String { t("PRACTICE", "ÜBEN") }
    static var reminder: String { t("REMINDER", "ERINNERUNG") }
    static var appearance: String { t("APPEARANCE", "DARSTELLUNG") }
    static var privacy: String { t("PRIVACY", "DATENSCHUTZ") }
    static var about: String { t("ABOUT JAZZCHORDS", "ÜBER JAZZCHORDS") }

    // Rows
    static var notationSystem: String { t("Note names", "Notennamen") }
    static var chordNotation: String { t("Chord symbols", "Akkord-Schreibweise") }
    static var accidentals: String { t("Accidentals", "Vorzeichen") }
    static var sound: String { t("Sound", "Klang") }
    static var connectKeyboard: String { t("Connect keyboard", "Keyboard verbinden") }
    static var bluetooth: String { "Bluetooth" }
    static var reminderToggle: String { t("Daily practice reminder", "Täglich ans Üben erinnern") }
    static var reminderTime: String { t("Time", "Uhrzeit") }
    static var telemetryToggle: String { t("Help improve anonymously", "Anonym beim Verbessern helfen") }
    static var telemetryNote: String {
        t("Only anonymous practice data, never personal data. Change it any time.",
          "Nur anonyme Übungsdaten, keine Personendaten. Jederzeit änderbar.")
    }
    static var help: String { t("Help & contact", "Hilfe & Kontakt") }
    static var privacyPolicy: String { t("Privacy policy", "Datenschutzerklärung") }
    static var imprint: String { t("Imprint", "Impressum") }
    static var footer: String { t("JazzChords · made for players, not exams", "JazzChords · gemacht für Spieler, nicht für Prüfungen") }

    static var profileLabel: String { t("Profile and settings", "Profil und Einstellungen") }

    // E-mail sign-in
    static var email: String { t("E-mail", "E-Mail") }
    static var password: String { t("Password", "Passwort") }
    static var signIn: String { t("Sign in", "Anmelden") }
    static var createAccount: String { t("Create account", "Konto erstellen") }
    static var haveAccount: String { t("I already have an account", "Ich habe schon ein Konto") }
    static var newHere: String { t("New here? Create an account", "Neu hier? Konto erstellen") }
    static var cancel: String { t("Cancel", "Abbrechen") }
}
