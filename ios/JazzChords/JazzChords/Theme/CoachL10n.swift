// CoachL10n — localized strings for the Auto-Mode ("Coach") UI (de + en).
//
// The rest of the iOS app is English-only inline; the Coach is the first feature
// that ships both languages, so it carries a small self-contained table keyed by
// the engine's i18n keys (CoachLabelKeys / CoachSayKeys / CoachFeedbackKeys) plus
// a handful of UI-chrome keys. Texts are content-identical to the web source of
// truth (src/lib/i18n/{en,de}.ts, `coach:` block + `quickstart.coach_*`).
//
// Language selection follows the device's preferred language (de → German, else
// English), matching how a native app localizes without a String Catalog. Params
// are interpolated `{name}`-style exactly like the web `t(key, params)` helper,
// and raw voicing values are localized the same way as web `localizeCoachParams`.

import Foundation
import MusicEngine

enum CoachL10n {
    /// True when the device's top preferred language is German.
    static var isGerman: Bool {
        (Locale.preferredLanguages.first ?? "en").lowercased().hasPrefix("de")
    }

    // ─── Interpolation ──────────────────────────────────────
    // Mirrors web `t(key, params)`: look up the raw template, then replace
    // every `{name}` occurrence with its param value.

    /// Localize an engine i18n key, interpolating `{param}` placeholders.
    /// Voicing params arrive as raw values (e.g. "shell") and are localized here,
    /// mirroring the web `localizeCoachParams` step.
    static func t(_ key: String, _ params: [String: String] = [:]) -> String {
        let table = isGerman ? de : en
        var out = table[key] ?? key
        for (name, rawValue) in localizeParams(params) {
            out = out.replacingOccurrences(of: "{\(name)}", with: rawValue)
        }
        return out
    }

    /// Localize a raw voicing value ("shell", "rootless-a", …) for coach labels.
    static func voicingLabel(_ raw: String) -> String {
        guard let v = VoicingType(rawValue: raw) else { return raw }
        let table = isGerman ? deVoicings : enVoicings
        return table[v] ?? raw
    }

    /// One-line "what notes" explanation of a voicing — so the player knows what
    /// to play from a name like E♭9. Mirrors web settings.voicing_*_sub.
    static func voicingSub(_ v: VoicingType) -> String {
        let en: [VoicingType: String] = [
            .root: "Root + all notes from bottom.", .shell: "Root + 3rd + 7th only.",
            .halfShell: "3rd/7th around the root.", .full: "All notes in jazz order: 1-7-3-5.",
            .rootlessA: "3–5–7–9 · Bill Evans style.", .rootlessB: "7–9–3–5 · complement to Type A.",
            .inversion1: "3rd on bottom.", .inversion2: "5th on bottom.", .inversion3: "7th on bottom.",
        ]
        let de: [VoicingType: String] = [
            .root: "Grundton + alle Töne von unten.", .shell: "Nur Grundton + Terz + Septime.",
            .halfShell: "Terz/Septime um den Grundton.", .full: "Alle Töne in Jazz-Reihenfolge: 1-7-3-5.",
            .rootlessA: "3–5–7–9 · Bill-Evans-Stil.", .rootlessB: "7–9–3–5 · Ergänzung zu Typ A.",
            .inversion1: "Terz im Bass.", .inversion2: "Quinte im Bass.", .inversion3: "Septime im Bass.",
        ]
        return (isGerman ? de : en)[v] ?? ""
    }

    /// Copy of `params` with any `voicing` value translated (web `localizeCoachParams`).
    private static func localizeParams(_ params: [String: String]) -> [String: String] {
        var out = params
        if let v = out["voicing"] { out["voicing"] = voicingLabel(v) }
        // The key-tier ('easy'|'med'|'all') becomes a localized suffix like " (easy keys)".
        if let tier = out["tier"] { out["tier"] = t("coach.tier.\(tier)") }
        return out
    }

    // ─── UI chrome keys (not from the engine) ───────────────

    static let heroTitle = "quickstart.coach_hero_title"
    static let heroSub = "quickstart.coach_hero_sub"
    static let pickYourself = "quickstart.pick_yourself"
    static let transitionContinue = "coach.transition.tap_continue"
    static let feedbackTitle = "coach.feedback.title"
    static let feedbackAgain = "coach.feedback.again"
    static let feedbackDone = "coach.feedback.done"
    static let feedbackKeepGoing = "coach.feedback.keep_going"
    static let feedbackEnoughToday = "coach.feedback.enough_today"
    static let verdictExcellent = "coach.verdict.excellent"
    static let verdictStruggling = "coach.verdict.struggling"
    static let verdictStartEasier = "coach.verdict.start_easier"
    static let valvePrompt = "coach.valve.prompt"
    static let valveTooEasy = "coach.valve.too_easy"
    static let valveJustRight = "coach.valve.just_right"
    static let valveTooHard = "coach.valve.too_hard"
    static let valveThanks = "coach.valve.thanks"
    static let privacyTitle = "settings.privacy"
    static let privacyDesc = "settings.privacy_desc"
    static let privacyToggle = "settings.privacy_toggle_label"

    /// Short "done" confirmation for a finished block (transition screen).
    static func blockDone(_ kind: BlockKind) -> String { t("coach.done.\(kind.rawValue)") }

    // ─── Voicing tables (mirror web settings.voicing_*) ─────

    private static let enVoicings: [VoicingType: String] = [
        .root: "Root Position", .shell: "Shell Voicing", .halfShell: "Half Shell",
        .full: "Full Voicing", .rootlessA: "Rootless A", .rootlessB: "Rootless B",
        .inversion1: "1st Inversion", .inversion2: "2nd Inversion", .inversion3: "3rd Inversion",
    ]
    private static let deVoicings: [VoicingType: String] = [
        .root: "Grundstellung", .shell: "Shell Voicing", .halfShell: "Half-Shell",
        .full: "Volle Besetzung", .rootlessA: "Rootless A", .rootlessB: "Rootless B",
        .inversion1: "1. Umkehrung", .inversion2: "2. Umkehrung", .inversion3: "3. Umkehrung",
    ]

    // ─── String tables (content-identical to web coach: block) ──

    private static let en: [String: String] = [
        // Block announcements (transition screen).
        "coach.block.warmup": "Warm up with {voicing}",
        "coach.block.review": "Refresh {count} chords",
        "coach.block.focus": "Focus: {root} in {voicing}",
        "coach.block.new": "New: {quality} in {voicing}",
        "coach.block.apply": "Apply: {voicing} in a progression",
        "coach.block.calibrate": "A quick check of where you stand",
        // Block done (short confirmation, no params).
        "coach.done.warmup": "Warmed up",
        "coach.done.review": "Refreshed",
        "coach.done.focus": "Focus done",
        "coach.done.new": "New material practiced",
        "coach.done.apply": "Applied",
        "coach.done.calibrate": "Check done",
        // Coach announcement on the hero button.
        "coach.say.calibrate": "First a quick check — {chords} chords, then we begin.",
        "coach.say.short": "Today: refresh {voicing} and dig into {quality} — {minutes} minutes.",
        "coach.say.full": "Today: warm up, firm up {focusRoot}, and {quality} in {voicing} is new — {minutes} minutes.",
        "coach.say.reviewOnly": "Just a refresh today — {minutes} minutes and you're back on track.",
        // Teacher feedback after the session. {tier} names the key stage so
        // "already have it" and "next goal" never sound contradictory.
        "coach.fb.promoted": "{quality} in {voicing} {tier} sits now — cleanly mastered.",
        "coach.fb.held": "We'll take another pass at {quality} in {voicing} {tier} — it's coming.",
        "coach.fb.demoted": "Easing {quality} in {voicing} {tier} down a step — no worries.",
        "coach.fb.improved": "Noticeably faster: avg {avgMs} ms per chord.",
        "coach.fb.placed": "You already have {quality} in {voicing} {tier} — skipped ahead.",
        "coach.fb.nextGoal": "Next goal: {quality} in {voicing} {tier}.",
        "coach.fb.calibrated": "Check done — {placed} building blocks already in place.",
        // Key-stage suffix used in fb.* strings — reads as a parenthetical.
        "coach.tier.easy": "(easy keys)",
        "coach.tier.med": "(more keys)",
        "coach.tier.all": "(all 12 keys)",
        // UI chrome.
        "coach.transition.tap_continue": "Continue",
        "coach.feedback.title": "Your lesson",
        "coach.feedback.again": "Again",
        "coach.feedback.done": "Done",
        "coach.feedback.keep_going": "Keep going",
        "coach.feedback.enough_today": "Enough for today",
        "coach.verdict.excellent": "Nailed it — that was fast and clean.",
        "coach.verdict.struggling": "That one was tough. Want to ease off?",
        "coach.verdict.start_easier": "Yes, start easier",
        "coach.valve.prompt": "How did that feel?",
        "coach.valve.too_easy": "Too easy",
        "coach.valve.just_right": "Just right",
        "coach.valve.too_hard": "Too hard",
        "coach.valve.thanks": "Noted for next time.",
        "quickstart.coach_hero_title": "Keep practicing",
        "quickstart.coach_hero_sub": "Your coach builds today's session.",
        "quickstart.pick_yourself": "Pick it yourself",
        "settings.privacy": "Anonymous Usage Data",
        "settings.privacy_desc": "Helps us improve the practice coach — fully anonymous, no personal data, and you can turn it off anytime.",
        "settings.privacy_toggle_label": "Share anonymous usage data",
    ]

    private static let de: [String: String] = [
        "coach.block.warmup": "Aufwärmen mit {voicing}",
        "coach.block.review": "{count} Akkorde auffrischen",
        "coach.block.focus": "Fokus: {root} in {voicing}",
        "coach.block.new": "Neu: {quality} in {voicing}",
        "coach.block.apply": "Anwenden: {voicing} in Progression",
        "coach.block.calibrate": "Kurzer Check, wo du stehst",
        "coach.done.warmup": "Aufgewärmt",
        "coach.done.review": "Aufgefrischt",
        "coach.done.focus": "Fokus geschafft",
        "coach.done.new": "Neues geübt",
        "coach.done.apply": "Angewendet",
        "coach.done.calibrate": "Check erledigt",
        "coach.say.calibrate": "Erst ein kurzer Check — {chords} Akkorde, dann geht’s los.",
        "coach.say.short": "Heute: {voicing} auffrischen und {quality} vertiefen — {minutes} Minuten.",
        "coach.say.full": "Heute: aufwärmen, {focusRoot} festigen und {quality} in {voicing} neu — {minutes} Minuten.",
        "coach.say.reviewOnly": "Heute nur auffrischen — {minutes} Minuten, dann bist du wieder auf Kurs.",
        "coach.fb.promoted": "{quality} in {voicing} {tier} sitzt jetzt — sauber gemeistert.",
        "coach.fb.held": "{quality} in {voicing} {tier} üben wir nochmal, das kommt.",
        "coach.fb.demoted": "{quality} in {voicing} {tier} nehmen wir eine Stufe zurück — kein Stress.",
        "coach.fb.improved": "Spürbar schneller: Ø {avgMs} ms pro Akkord.",
        "coach.fb.placed": "{quality} in {voicing} {tier} kannst du schon — übersprungen.",
        "coach.fb.nextGoal": "Nächstes Ziel: {quality} in {voicing} {tier}.",
        "coach.fb.calibrated": "Check fertig — {placed} Bausteine sitzen schon.",
        "coach.tier.easy": "(leichte Tonarten)",
        "coach.tier.med": "(mehr Tonarten)",
        "coach.tier.all": "(alle 12 Tonarten)",
        "coach.transition.tap_continue": "Weiter",
        "coach.feedback.title": "Deine Stunde",
        "coach.feedback.again": "Nochmal",
        "coach.feedback.done": "Fertig",
        "coach.feedback.keep_going": "Weiter geht's",
        "coach.feedback.enough_today": "Für heute genug",
        "coach.verdict.excellent": "Sitzt — das war schnell und sauber.",
        "coach.verdict.struggling": "Das war zäh. Sollen wir es leichter angehen?",
        "coach.verdict.start_easier": "Ja, leichter starten",
        "coach.valve.prompt": "Wie war das für dich?",
        "coach.valve.too_easy": "Zu leicht",
        "coach.valve.just_right": "Passt",
        "coach.valve.too_hard": "Zu schwer",
        "coach.valve.thanks": "Merke ich mir für nächstes Mal.",
        "quickstart.coach_hero_title": "Weiter üben",
        "quickstart.coach_hero_sub": "Dein Coach stellt die Session zusammen.",
        "quickstart.pick_yourself": "Selbst wählen",
        "settings.privacy": "Anonyme Nutzungsdaten",
        "settings.privacy_desc": "Hilft uns, den Übungs-Coach zu verbessern — komplett anonym, ohne Personendaten, jederzeit abschaltbar.",
        "settings.privacy_toggle_label": "Anonyme Nutzungsdaten teilen",
    ]
}
