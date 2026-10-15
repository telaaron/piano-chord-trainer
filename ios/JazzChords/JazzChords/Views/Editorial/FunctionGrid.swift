// Under the trainer chord: each voicing tone with its function
// (D Grundton · F Terz · C Septime). After an attempt, played tones turn gold
// and missing ones get a dashed red outline.

import SwiftUI
import MusicEngine

enum ToneState: Equatable { case ok, missing, open }

struct FunctionTone: Identifiable, Equatable {
    /// Position in the voicing — a voicing may repeat a note.
    let index: Int
    let note: String
    let function: String
    let state: ToneState
    var id: Int { index }
}

struct FunctionGrid: View {
    @Environment(\.palette) private var palette
    let tones: [FunctionTone]

    /// Derive tone states. `held` are MIDI note numbers; a tone is `.ok` when
    /// its pitch class is held. Before a result is shown everything is `.open`.
    nonisolated static func tones(voicingNotes: [String], labels: [String], held: Set<Int>, showResult: Bool) -> [FunctionTone] {
        let heldPCs = Set(held.map { (($0 % 12) + 12) % 12 })
        return voicingNotes.enumerated().map { i, note in
            let function = i < labels.count ? labels[i] : ""
            guard showResult else { return FunctionTone(index: i, note: note, function: function, state: .open) }
            let pc = noteToSemitone(asciiAccidentals(note))
            let state: ToneState = pc >= 0 && heldPCs.contains(pc) ? .ok : .missing
            return FunctionTone(index: i, note: note, function: function, state: state)
        }
    }

    /// The notes the grid judges: live input when MIDI/mic is on, otherwise the
    /// tap-guess (pitch classes, placed at C4). The guess survives grading,
    /// when the store has already left tap mode.
    nonisolated static func held(inputActive: Bool, heldNotes: Set<Int>, tapGuess: Set<Int>) -> Set<Int> {
        inputActive ? heldNotes : Set(tapGuess.map { 60 + $0 })
    }

    /// MusicEngine spells notes with ASCII accidentals ("Eb"); display text uses ♭/♯.
    nonisolated private static func asciiAccidentals(_ note: String) -> String {
        note.replacingOccurrences(of: "♭", with: "b").replacingOccurrences(of: "♯", with: "#")
    }

    var body: some View {
        HStack(spacing: Theme.space2) {
            ForEach(tones) { tone in
                VStack(spacing: 2) {
                    Text(tone.note)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(noteColor(tone.state))
                    Text(tone.function)
                        .font(.caption)
                        .foregroundStyle(tone.state == .missing ? palette.action : palette.inkMuted)
                }
                .frame(maxWidth: .infinity, minHeight: 54)
                .overlay {
                    if tone.state == .missing {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(palette.action, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(.top, Theme.space3)
        .overlay(alignment: .top) { Rectangle().fill(palette.ink).frame(height: 1) }
    }

    private func noteColor(_ state: ToneState) -> Color {
        switch state {
        case .ok: return palette.music
        case .missing: return palette.action
        case .open: return palette.ink
        }
    }
}

#Preview("Function grid") {
    FunctionGrid(tones: FunctionGrid.tones(voicingNotes: ["D", "F", "C"],
                                           labels: ["Grundton", "Terz", "Septime"],
                                           held: [50, 60], showResult: true))
        .frame(width: 270)
        .padding(20)
        .background(Palette.dark.canvas)
        .environment(\.palette, .dark)
}
