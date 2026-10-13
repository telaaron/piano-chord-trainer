// Settings — notation, sound, MIDI, reminder, privacy. Notation and sound live in
// SavedSettings (the trainer's persisted prefs): every change is written through
// at once, and the sound preset is applied to the audio engine immediately.

import SwiftUI
import MusicEngine

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.palette) private var palette

    @State private var settings = ProgressStore.loadSettings()
    @State private var showBluetooth = false
    @State private var telemetryEnabled = TelemetryService.shared.isEnabled
    @State private var reminderOn = ReminderScheduler.shared.isEnabled
    @State private var reminderTime = Self.date(from: ReminderScheduler.shared.time)
    @State private var reminderDenied = false


    var body: some View {
        Form {
            Section(CoachL10n.t("settings.notation")) {
                Picker(CoachL10n.t("settings.notation_system"), selection: $settings.notationSystem) {
                    Text(CoachL10n.t("settings.notation_system_international")).tag(NotationSystem.international)
                    Text(CoachL10n.t("settings.notation_system_german")).tag(NotationSystem.german)
                }
                Picker(CoachL10n.t("settings.chord_notation_title"), selection: $settings.notation) {
                    Text(CoachL10n.t("settings.notation_standard")).tag(NotationStyle.standard)
                    Text(CoachL10n.t("settings.notation_symbols")).tag(NotationStyle.symbols)
                    Text(CoachL10n.t("settings.notation_short")).tag(NotationStyle.short)
                }
                Picker(CoachL10n.t("settings.accidentals"), selection: $settings.accidentals) {
                    Text(CoachL10n.t("settings.accidentals_both")).tag(AccidentalPreference.both)
                    Text(CoachL10n.t("settings.accidentals_sharps")).tag(AccidentalPreference.sharps)
                    Text(CoachL10n.t("settings.accidentals_flats")).tag(AccidentalPreference.flats)
                }
            }

            Section(CoachL10n.t("settings.sound")) {
                Picker(CoachL10n.t("settings.instrument"), selection: $settings.soundPreset) {
                    ForEach(SoundPreset.allCases, id: \.rawValue) { p in
                        Text(presetLabel(p.rawValue)).tag(p.rawValue)
                    }
                }
            }

            Section(CoachL10n.t("settings.midi")) {
                Button {
                    MIDIInput.shared.start()
                    showBluetooth = true
                } label: {
                    Label(CoachL10n.t("settings.connect_bluetooth"), systemImage: "pianokeys")
                }
                if !MIDIInput.shared.devices.isEmpty {
                    ForEach(MIDIInput.shared.devices) { d in
                        Label(d.name, systemImage: "pianokeys.inverse")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Toggle(CoachL10n.t("reminder.settings_toggle"), isOn: $reminderOn)
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
                if reminderOn {
                    DatePicker(CoachL10n.t("reminder.settings_time"), selection: $reminderTime,
                               displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { _, d in
                            Task { await ReminderScheduler.shared.setTime(Self.reminderTime(from: d)) }
                        }
                }
                if reminderDenied {
                    Button(CoachL10n.t("reminder.settings_denied")) {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.footnote)
                }
            } header: {
                Text(CoachL10n.t("reminder.settings_title"))
            }

            Section(CoachL10n.t(CoachL10n.privacyTitle)) {
                Toggle(CoachL10n.t(CoachL10n.privacyToggle), isOn: $telemetryEnabled)
                    .onChange(of: telemetryEnabled) { _, on in
                        TelemetryService.shared.setEnabled(on)
                    }
                Text(CoachL10n.t(CoachL10n.privacyDesc))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Text(CoachL10n.t("settings.midi_footer"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            // Notifications may have been revoked in iOS Settings since reminders were turned on.
            await ReminderScheduler.shared.refreshAuthorization()
            reminderDenied = ReminderScheduler.shared.isEnabled && ReminderScheduler.shared.authorization == .denied
        }
        .onChange(of: settings) { _, new in
            ProgressStore.saveSettings(new)
            AudioEngine.shared.setPreset(SoundPreset(rawValue: new.soundPreset) ?? .grandPiano)
        }
        // Manual UIKit present (.formSheet) — CABTMIDICentralViewController crashes
        // if loaded at a zero-frame, which a SwiftUI sheet causes.
        .background(BluetoothMIDIPresenter(isPresented: $showBluetooth))
        .navigationTitle(CoachL10n.t("settings.open_settings"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(CoachL10n.t("ui.done")) { dismiss() }
                    .fontWeight(.semibold)
                    .tint(palette.text)
            }
        }
    }

    private static func date(from t: ReminderTime) -> Date {
        Calendar.current.date(bySettingHour: t.hour, minute: t.minute, second: 0, of: Date()) ?? Date()
    }

    private static func reminderTime(from d: Date) -> ReminderTime {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return ReminderTime(hour: c.hour ?? 19, minute: c.minute ?? 0) ?? .default(for: .evening)
    }

    /// Instrument names are translated ("Flügel"), not id-humanized.
    private func presetLabel(_ id: String) -> String { CoachL10n.t("sound.\(id)") }
}
