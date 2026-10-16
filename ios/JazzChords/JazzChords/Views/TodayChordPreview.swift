// The chord row on Heute: which chords today's coach plan is about, and a small
// sheet that shows a chord's voicing on the keyboard without starting a session.
// Chords are representative (sessions draw their keys at start), not a replay.

import SwiftUI
import MusicEngine

enum TodayChordPreview {
    /// Up to `max` chords for the plan's focus block (`.focus`/`.new`, else the
    /// first block). Progression modes give their first chords; otherwise the
    /// block's focus roots × qualities. Nothing to show → `[]` (row hidden).
    static func chords(for plan: CoachPlan, max: Int = 3) -> [ChordWithNotes] {
        guard let block = focusBlock(of: plan) else { return [] }
        let s = block.settings

        if s.progressionMode != .random && s.progressionMode != .custom {
            let progression = generateProgression(s.progressionMode, s.accidentals, s.notation, max)
            return progression.chords.prefix(max).map {
                make(root: $0.root, quality: $0.quality, display: $0.display, settings: s)
            }
        }

        guard let qualities = block.focusQualities, !qualities.isEmpty else { return [] }
        let roots = block.focusRoots?.isEmpty == false ? block.focusRoots! : ["C"]
        var result: [ChordWithNotes] = []
        for root in roots {
            for display in qualities {
                let quality = displayToQuality(display, s.notation)
                let suffix = CHORD_NOTATIONS[s.notation]?[quality] ?? display
                result.append(make(root: root, quality: quality, display: root + suffix, settings: s))
                if result.count == max { return result }
            }
        }
        return result
    }

    /// True when the row is a real succession (a progression block), so arrows
    /// are honest. Focus/calibration chords are dealt at random at start: show
    /// them as examples, not as a sequence.
    static func isSequence(for plan: CoachPlan) -> Bool {
        guard let block = focusBlock(of: plan) else { return false }
        let mode = block.settings.progressionMode
        return mode != .random && mode != .custom
    }

    /// True when the block has no roots: chords are dealt in random keys, so
    /// the row names qualities only ("Δ7 · 7 · –7"), not a key it won't use.
    static func isAnyKey(for plan: CoachPlan) -> Bool {
        guard let block = focusBlock(of: plan), !isSequence(for: plan) else { return false }
        return block.focusRoots?.isEmpty ?? true
    }

    struct Step: Equatable {
        let kind: BlockKind
        let chords: Int
    }

    /// Today's units in session order ("Aufwärmen 4 · Fokus 8 · Neu 6").
    /// Only today: the coach re-plans after every session.
    static func steps(for plan: CoachPlan) -> [Step] {
        plan.blocks.map { Step(kind: $0.kind, chords: $0.targetChords) }
    }

    private static func focusBlock(of plan: CoachPlan) -> CoachBlock? {
        plan.blocks.first(where: { $0.kind == .focus || $0.kind == .new }) ?? plan.blocks.first
    }

    private static func make(root: String, quality: String, display: String, settings s: PracticePlanSettings) -> ChordWithNotes {
        let notes = getChordNotes(root, quality, s.accidentals)
        let voicing = getVoicingNotes(notes, s.voicing, root, s.accidentals)
        return ChordWithNotes(chord: display, root: root, type: quality, notes: notes, voicing: voicing)
    }
}

/// Bottom sheet: the chord in Real Book handwriting, its voicing on the
/// keyboard, and a play button. No session, no telemetry.
struct ChordPreviewSheet: View {
    @Environment(\.palette) private var palette
    let chord: ChordWithNotes

    var body: some View {
        VStack(spacing: Theme.space4) {
            Text(Notation.chord(chord.chord))
                .font(Display.chord(44, relativeTo: .title1))
                .foregroundStyle(palette.ink)
            PianoKeyboard(chordData: chord, showVoicing: true, maxHeight: 120)
            PrimaryCapsule(title: Strings.listen, systemImage: "speaker.wave.2.fill") {
                AudioEngine.shared.playChord(chord.voicing)
            }
            .padding(.horizontal, Theme.space4)
        }
        .padding(.vertical, Theme.space5)
        .frame(maxWidth: .infinity)
        .background(palette.canvas.ignoresSafeArea())
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }
}
