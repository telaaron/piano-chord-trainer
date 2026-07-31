// Settings — sound, input, notation, theme, language. M1: bound to local @State;
// M2/M3 persist these via the AppStore and feed the trainer/audio engine.

import SwiftUI
import MusicEngine

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var notationSystem: NotationSystem = .international
    @State private var notationStyle: NotationStyle = .standard
    @State private var accidentals: AccidentalPreference = .both
    @State private var soundPreset = "grand-piano"
    @State private var showBluetooth = false
    @State private var telemetryEnabled = TelemetryService.shared.isEnabled

    private let soundPresets = ["grand-piano", "electric-piano", "vibraphone", "organ", "synth-pad"]

    var body: some View {
        Form {
            Section(CoachL10n.t("settings.notation")) {
                Picker(CoachL10n.t("settings.notation_system"), selection: $notationSystem) {
                    Text(CoachL10n.t("settings.notation_system_international")).tag(NotationSystem.international)
                    Text(CoachL10n.t("settings.notation_system_german")).tag(NotationSystem.german)
                }
                Picker(CoachL10n.t("settings.chord_notation_title"), selection: $notationStyle) {
                    Text(CoachL10n.t("settings.notation_standard")).tag(NotationStyle.standard)
                    Text(CoachL10n.t("settings.notation_symbols")).tag(NotationStyle.symbols)
                    Text(CoachL10n.t("settings.notation_short")).tag(NotationStyle.short)
                }
                Picker(CoachL10n.t("settings.accidentals"), selection: $accidentals) {
                    Text(CoachL10n.t("settings.accidentals_both")).tag(AccidentalPreference.both)
                    Text(CoachL10n.t("settings.accidentals_sharps")).tag(AccidentalPreference.sharps)
                    Text(CoachL10n.t("settings.accidentals_flats")).tag(AccidentalPreference.flats)
                }
            }

            Section(CoachL10n.t("settings.sound")) {
                Picker(CoachL10n.t("settings.instrument"), selection: $soundPreset) {
                    ForEach(soundPresets, id: \.self) { p in
                        Text(presetLabel(p)).tag(p)
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
        // Manual UIKit present (.formSheet) — CABTMIDICentralViewController crashes
        // if loaded at a zero-frame, which a SwiftUI sheet causes.
        .background(BluetoothMIDIPresenter(isPresented: $showBluetooth))
        .navigationTitle(CoachL10n.t("settings.open_settings"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(CoachL10n.t("ui.done")) { dismiss() }
            }
        }
    }

    /// Instrument names are translated ("Flügel"), not id-humanized.
    private func presetLabel(_ id: String) -> String { CoachL10n.t("sound.\(id)") }
}
