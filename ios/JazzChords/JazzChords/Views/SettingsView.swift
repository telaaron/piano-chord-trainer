// Settings — the one central place for account and preferences (row F, spec §2),
// reached from the profile circle on Heute. Notation and sound live in
// SavedSettings (the trainer's persisted prefs): every change is written through
// at once, and the sound preset is applied to the audio engine immediately.
// All storage keys are unchanged; only the presentation is new.

import SwiftUI
import MusicEngine

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette
    @Environment(\.openURL) private var openURL

    /// Account state and actions; wired by the account layer.
    var account = AccountCardModel()
    /// E-mail sign-in; returns an error message to show, or nil on success.
    var emailSubmit: (String, String, Bool) async -> String? = { _, _, _ in
        SettingsText.t("Sign-in is not connected yet.", "Die Anmeldung ist noch nicht verbunden.")
    }

    @State private var settings = ProgressStore.loadSettings()
    @State private var appearance = AppearanceStore.shared
    @State private var showBluetooth = false
    @State private var showEmailSignIn = false
    @State private var telemetryEnabled = TelemetryService.shared.isEnabled
    @State private var reminderOn = ReminderScheduler.shared.isEnabled
    @State private var reminderTime = Self.date(from: ReminderScheduler.shared.time)
    @State private var reminderDenied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space5) {
                EditorialHeader(title: SettingsText.title)

                AccountCard(model: accountModel)

                section(SettingsText.practice) {
                    menuRow(icon: "textformat", title: SettingsText.chordNotation,
                            value: notationLabel(settings.notation)) {
                        Picker(SettingsText.chordNotation, selection: $settings.notation) {
                            Text(CoachL10n.t("settings.notation_standard")).tag(NotationStyle.standard)
                            Text(CoachL10n.t("settings.notation_symbols")).tag(NotationStyle.symbols)
                            Text(CoachL10n.t("settings.notation_short")).tag(NotationStyle.short)
                        }
                    }
                    divider
                    menuRow(icon: "character.book.closed", title: SettingsText.notationSystem,
                            value: settings.notationSystem == .german
                                ? CoachL10n.t("settings.notation_system_german")
                                : CoachL10n.t("settings.notation_system_international")) {
                        Picker(SettingsText.notationSystem, selection: $settings.notationSystem) {
                            Text(CoachL10n.t("settings.notation_system_international")).tag(NotationSystem.international)
                            Text(CoachL10n.t("settings.notation_system_german")).tag(NotationSystem.german)
                        }
                    }
                    divider
                    menuRow(icon: "number", title: SettingsText.accidentals,
                            value: accidentalsLabel(settings.accidentals)) {
                        Picker(SettingsText.accidentals, selection: $settings.accidentals) {
                            Text(CoachL10n.t("settings.accidentals_both")).tag(AccidentalPreference.both)
                            Text(CoachL10n.t("settings.accidentals_sharps")).tag(AccidentalPreference.sharps)
                            Text(CoachL10n.t("settings.accidentals_flats")).tag(AccidentalPreference.flats)
                        }
                    }
                    divider
                    menuRow(icon: "speaker.wave.2", title: SettingsText.sound,
                            value: presetLabel(settings.soundPreset)) {
                        Picker(SettingsText.sound, selection: $settings.soundPreset) {
                            ForEach(SoundPreset.allCases, id: \.rawValue) { p in
                                Text(presetLabel(p.rawValue)).tag(p.rawValue)
                            }
                        }
                    }
                    divider
                    Button {
                        MIDIInput.shared.start()
                        showBluetooth = true
                    } label: {
                        row(icon: "pianokeys", title: SettingsText.connectKeyboard) {
                            valueText(MIDIInput.shared.devices.first?.name ?? SettingsText.bluetooth)
                            chevron
                        }
                    }
                    .buttonStyle(.plain)
                }

                section(SettingsText.reminder) {
                    row(icon: "bell", tint: .red, title: SettingsText.reminderToggle) {
                        Toggle(SettingsText.reminderToggle, isOn: $reminderOn)
                            .labelsHidden()
                            .tint(palette.action)
                    }
                    if reminderOn {
                        divider
                        row(icon: nil, title: SettingsText.reminderTime) {
                            DatePicker(SettingsText.reminderTime, selection: $reminderTime,
                                       displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                    }
                } footer: {
                    if reminderDenied {
                        Button(CoachL10n.t("reminder.settings_denied")) {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                openURL(url)
                            }
                        }
                        .font(.footnote)
                        .tint(palette.action)
                    }
                }

                section(SettingsText.appearance) {
                    Picker(SettingsText.appearance, selection: $appearance.appearance) {
                        ForEach(Appearance.allCases) { a in Text(a.label).tag(a) }
                    }
                    .pickerStyle(.segmented)
                    .padding(Theme.space3)
                }

                section(SettingsText.privacy) {
                    row(icon: "lock.shield", tint: .slate, title: SettingsText.telemetryToggle) {
                        Toggle(SettingsText.telemetryToggle, isOn: $telemetryEnabled)
                            .labelsHidden()
                            .tint(palette.action)
                    }
                } footer: {
                    Text(SettingsText.telemetryNote)
                }

                section(SettingsText.about) {
                    linkRow(SettingsText.help, "https://jazzchords.app/feedback")
                    divider
                    linkRow(SettingsText.privacyPolicy, "https://jazzchords.app/privacy")
                    divider
                    linkRow(SettingsText.imprint, "https://jazzchords.app/impressum")
                } footer: {
                    Text(SettingsText.footer)
                        .font(Display.serif(16, italic: true, relativeTo: .footnote))
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.space3)
                }
            }
            .padding(.horizontal, Theme.space5 - 4)
            .padding(.bottom, Theme.space6)
        }
        .background(palette.canvas)
        .task {
            // Notifications may have been revoked in iOS Settings since reminders were turned on.
            await ReminderScheduler.shared.refreshAuthorization()
            reminderDenied = ReminderScheduler.shared.isEnabled && ReminderScheduler.shared.authorization == .denied
        }
        .onChange(of: settings) { _, new in
            ProgressStore.saveSettings(new)
            AudioEngine.shared.setPreset(SoundPreset(rawValue: new.soundPreset) ?? .grandPiano)
        }
        .onChange(of: reminderOn) { _, on in
            Task {
                if on {
                    let granted = await ReminderScheduler.shared.enable(at: Self.reminderTime(from: reminderTime), source: "settings")
                    reminderDenied = !granted
                    if !granted { reminderOn = false }
                    // Switched off again while the permission answer was pending.
                    else if !reminderOn { await ReminderScheduler.shared.disable() }
                } else if ReminderScheduler.shared.isEnabled {
                    await ReminderScheduler.shared.disable()
                }
            }
        }
        .onChange(of: reminderTime) { _, d in
            Task { await ReminderScheduler.shared.setTime(Self.reminderTime(from: d)) }
        }
        .onChange(of: telemetryEnabled) { _, on in
            TelemetryService.shared.setEnabled(on)
        }
        // Manual UIKit present — CABTMIDICentralViewController crashes inside a SwiftUI sheet.
        .background(BluetoothMIDIPresenter(isPresented: $showBluetooth))
        .sheet(isPresented: $showEmailSignIn) {
            NavigationStack { EmailSignInView(submit: emailSubmit) }
                .environment(\.palette, palette)
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Spacer()
                Button(SettingsText.done) { dismiss() }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(palette.ink)
                    .padding(.horizontal, Theme.space4)
                    .frame(minHeight: 44)
                    .glassControl(in: Capsule())
            }
            .padding(.horizontal, Theme.space5 - 4)
            .padding(.top, Theme.space3)
        }
    }

    private var accountModel: AccountCardModel {
        var m = account
        let open = m.openEmailSignIn
        m.openEmailSignIn = { open(); showEmailSignIn = true }
        return m
    }

    // MARK: Building blocks

    private var divider: some View {
        Rectangle().fill(palette.hairline).frame(height: 0.5).padding(.leading, 58)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(palette.inkMuted)
    }

    private func valueText(_ s: String) -> some View {
        Text(s).font(.body).foregroundStyle(palette.inkMuted).lineLimit(1)
    }

    private func section<Content: View, Footer: View>(
        _ title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        let rows = content()
        return VStack(alignment: .leading, spacing: Theme.space2) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(palette.inkMuted)
                .padding(.leading, Theme.space4)
                .accessibilityAddTraits(.isHeader)
            TrackGroup { rows }
            footer()
                .font(.footnote)
                .foregroundStyle(palette.inkMuted)
                .padding(.horizontal, Theme.space4)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        section(title, content: content) { EmptyView() }
    }

    private func row<Trailing: View>(icon: String?, tint: IconTile.Tint = .gold, title: String,
                                     @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: Theme.space3) {
            if let icon {
                IconTile(systemImage: icon, tint: tint)
            } else {
                Color.clear.frame(width: 30, height: 1)
            }
            Text(title)
                .font(.body)
                .foregroundStyle(palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            Spacer(minLength: Theme.space2)
            trailing()
        }
        .padding(.horizontal, Theme.space4)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    private func menuRow<P: View>(icon: String, title: String, value: String,
                                  @ViewBuilder picker: () -> P) -> some View {
        Menu {
            picker()
        } label: {
            row(icon: icon, title: title) {
                valueText(value)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(palette.inkMuted)
            }
        }
        .buttonStyle(.plain)
    }

    private func linkRow(_ title: String, _ url: String) -> some View {
        Button {
            if let u = URL(string: url) { openURL(u) }
        } label: {
            HStack {
                Text(title).font(.body).foregroundStyle(palette.ink)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(palette.inkMuted)
            }
            .padding(.horizontal, Theme.space4)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: Labels

    private func notationLabel(_ n: NotationStyle) -> String {
        switch n {
        case .standard: return CoachL10n.t("settings.notation_standard")
        case .symbols: return CoachL10n.t("settings.notation_symbols")
        case .short: return CoachL10n.t("settings.notation_short")
        }
    }

    private func accidentalsLabel(_ a: AccidentalPreference) -> String {
        switch a {
        case .both: return CoachL10n.t("settings.accidentals_both")
        case .sharps: return CoachL10n.t("settings.accidentals_sharps")
        case .flats: return CoachL10n.t("settings.accidentals_flats")
        }
    }

    /// Instrument names are translated ("Flügel"), not id-humanized.
    private func presetLabel(_ id: String) -> String { CoachL10n.t("sound.\(id)") }

    private static func date(from t: ReminderTime) -> Date {
        Calendar.current.date(bySettingHour: t.hour, minute: t.minute, second: 0, of: Date()) ?? Date()
    }

    private static func reminderTime(from d: Date) -> ReminderTime {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return ReminderTime(hour: c.hour ?? 19, minute: c.minute ?? 0) ?? .default(for: .evening)
    }
}
