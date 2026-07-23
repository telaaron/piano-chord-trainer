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
            Section("Notation") {
                Picker("System", selection: $notationSystem) {
                    Text("International").tag(NotationSystem.international)
                    Text("German (H/B)").tag(NotationSystem.german)
                }
                Picker("Style", selection: $notationStyle) {
                    Text("Standard").tag(NotationStyle.standard)
                    Text("Symbols (Δ7)").tag(NotationStyle.symbols)
                    Text("Short").tag(NotationStyle.short)
                }
                Picker("Accidentals", selection: $accidentals) {
                    Text("Both").tag(AccidentalPreference.both)
                    Text("Sharps").tag(AccidentalPreference.sharps)
                    Text("Flats").tag(AccidentalPreference.flats)
                }
            }

            Section("Sound") {
                Picker("Instrument", selection: $soundPreset) {
                    ForEach(soundPresets, id: \.self) { p in
                        Text(presetLabel(p)).tag(p)
                    }
                }
            }

            Section("MIDI") {
                Button {
                    MIDIInput.shared.start()
                    showBluetooth = true
                } label: {
                    Label("Connect Bluetooth keyboard", systemImage: "pianokeys")
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
                Text("Hardware MIDI works in the trainer (set Input → MIDI). Microphone recognition and more settings arrive soon.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        // Manual UIKit present (.formSheet) — CABTMIDICentralViewController crashes
        // if loaded at a zero-frame, which a SwiftUI sheet causes.
        .background(BluetoothMIDIPresenter(isPresented: $showBluetooth))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func presetLabel(_ id: String) -> String {
        id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
}
