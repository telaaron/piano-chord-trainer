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

            Section {
                Text("More settings (input device, theme, language) arrive with the trainer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
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
