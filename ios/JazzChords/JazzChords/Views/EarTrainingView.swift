// Ear training — hear a chord, tap its notes on the keyboard, then check.
// The chord symbol stays hidden until reveal. Mirrors the web ear-training flow.

import SwiftUI
import MusicEngine

struct EarTrainingView: View {
    @Environment(\.palette) private var palette
    @Bindable var store: TrainerStore
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: Theme.space4) {
            topBar

            Spacer(minLength: 0)

            // Prompt / reveal
            VStack(spacing: Theme.space2) {
                if store.earRevealed, let d = store.currentData {
                    Text(convertChordNotation(d.chord, store.notationSystem))
                        .font(Display.chord(56))
                        .foregroundStyle(store.earResult == true ? palette.accentGreen : palette.text)
                    Text(store.earResult == true ? "Correct" : "Not quite")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(store.earResult == true ? palette.accentGreen : palette.accentRed)
                } else {
                    Image(systemName: "ear.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(palette.primary)
                        .symbolRenderingMode(.hierarchical)
                    Text("What chord is this?")
                        .font(Display.headline(20))
                        .foregroundStyle(palette.text)
                    Button { store.earPlayChord() } label: {
                        Label("Play again", systemImage: "speaker.wave.2.fill")
                    }.tint(palette.primary)
                }
            }

            // Keyboard — tap to build the guess; reveals expected on check.
            PianoKeyboard(
                chordData: store.currentData,
                accidentalPref: store.accidentals,
                showVoicing: store.earRevealed,
                forceOctaves: store.sessionOctaves,
                interactive: !store.earRevealed,
                selectedPitchClasses: store.earGuess,
                onKeyTap: { chr in if !store.earRevealed { store.earToggle(chr) } }
            )

            Spacer(minLength: 0)

            // Action
            if store.earRevealed {
                primaryButton(store.currentIdx >= store.actualTotalChords - 1 ? "Finish" : "Next") {
                    store.earNext()
                }
            } else {
                primaryButton("Check", disabled: store.earGuess.isEmpty) {
                    UISelectionFeedbackGenerator().selectionChanged()
                    store.earCheck()
                }
            }
        }
        .padding(Theme.space4)
        .navigationBarBackButtonHidden()
        .onAppear { store.earPlayChord() }
    }

    private var topBar: some View {
        VStack(spacing: Theme.space2) {
            HStack {
                Text("\(store.currentIdx + 1) / \(store.actualTotalChords)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(palette.textMuted)
                Spacer()
                Button { onClose() } label: { Image(systemName: "xmark.circle.fill") }
                    .foregroundStyle(palette.textDim)
            }
            ProgressView(value: store.progress).tint(palette.primary)
        }
    }

    private func primaryButton(_ label: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.space4)
                .background(disabled ? palette.bgMuted : palette.primary, in: RoundedRectangle(cornerRadius: Theme.radius))
                .foregroundStyle(disabled ? palette.textDim : palette.primaryText)
        }
        .disabled(disabled)
    }
}
