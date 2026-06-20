// LessonPlayerView — walks a lesson's steps (theory → practice → challenge).
// Theory: shows the example chord/interval on the keyboard with audio.
// Practice: a guided pass through the pool (reveal + advance).
// Challenge: a timed pass; the average is checked against masteryThresholdMs.
// On finish, the lesson is marked complete + mastery recomputed/persisted.

import SwiftUI
import MusicEngine

struct LessonPlayerView: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    let course: Course
    let lesson: Lesson

    @State private var stepIdx = 0
    @State private var poolIdx = 0
    @State private var challengeStart: TimeInterval = 0
    @State private var challengeAvgMs: Double?

    var body: some View {
        VStack(spacing: Theme.space5) {
            // progress through steps
            HStack(spacing: Theme.space2) {
                ForEach(0..<lesson.steps.count, id: \.self) { i in
                    Capsule()
                        .fill(i <= stepIdx ? palette.primary : palette.bgMuted)
                        .frame(height: 4)
                }
            }
            Spacer()
            stepBody
            Spacer()
            Button { advance() } label: {
                Text(buttonLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.space4)
                    .background(palette.primary)
                    .foregroundStyle(palette.primaryText)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
            }
        }
        .padding(Theme.space4)
        .screenBackground()
        .navigationTitle(lessonTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } }
        }
    }

    private var currentStep: LessonStep { lesson.steps[stepIdx] }

    @ViewBuilder
    private var stepBody: some View {
        switch currentStep {
        case .theory(let t):
            theoryView(t)
        case .practice(let p):
            poolDrillView(chords: poolChords(p), label: "Practice")
        case .challenge(let c):
            poolDrillView(chords: challengeChords(c), label: "Challenge · beat \(Int(c.masteryThresholdMs / 1000))s/chord")
        }
    }

    // MARK: Step views

    private func theoryView(_ t: TheoryStep) -> some View {
        VStack(spacing: Theme.space4) {
            Text("Theory")
                .font(.caption.weight(.semibold)).tracking(1)
                .foregroundStyle(palette.primary)
            if let chord = t.exampleChord {
                let data = chordWithNotes(root: chord.root, quality: chord.quality, voicing: chord.voicing)
                Text(data.chord)
                    .font(Display.chord(50))
                    .foregroundStyle(palette.text)
                PianoKeyboard(chordData: data, accidentalPref: .both, showVoicing: true)
                Button { AudioEngine.shared.playChord(data.voicing) } label: {
                    Label("Hear it", systemImage: "speaker.wave.2.fill")
                }.tint(palette.primary)
            } else if let iv = t.exampleInterval {
                Text("\(iv.root) → \(iv.target)")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(palette.text)
                Text(iv.label).foregroundStyle(palette.textMuted)
                Button {
                    AudioEngine.shared.playNote(iv.root, octave: 4)
                    AudioEngine.shared.playNote(iv.target, octave: 4)
                } label: { Label("Hear it", systemImage: "speaker.wave.2.fill") }
                    .tint(palette.primary)
            }
            Text("Tap continue when you've got it.")
                .font(.footnote).foregroundStyle(palette.textDim)
        }
    }

    private func poolDrillView(chords: [ChordWithNotes], label: String) -> some View {
        let data = poolIdx < chords.count ? chords[poolIdx] : chords.last
        return VStack(spacing: Theme.space4) {
            Text(label)
                .font(.caption.weight(.semibold)).tracking(1)
                .foregroundStyle(palette.primary)
            Text("\(min(poolIdx + 1, chords.count)) / \(chords.count)")
                .font(.caption.monospacedDigit()).foregroundStyle(palette.textDim)
            if let data {
                Text(data.chord)
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(palette.text)
                PianoKeyboard(chordData: data, accidentalPref: .both, showVoicing: true)
            }
        }
    }

    // MARK: Pools

    private func poolChords(_ p: PracticeStep) -> [ChordWithNotes] {
        (p.chordPool ?? []).map { chordWithNotes(root: $0.root, quality: $0.quality, voicing: $0.voicing) }
    }
    private func challengeChords(_ c: ChallengeStep) -> [ChordWithNotes] {
        c.keys.map { chordWithNotes(root: $0, quality: c.quality, voicing: c.voicing) }
    }

    private func chordWithNotes(root: String, quality: String, voicing: VoicingType) -> ChordWithNotes {
        let notes = getChordNotes(root, quality, .both)
        let voicingArr = getVoicingNotes(notes, voicing, root, .both)
        return ChordWithNotes(chord: "\(root)\(CHORD_NOTATIONS[.standard]?[quality] ?? quality)",
                              root: root, type: quality, notes: notes, voicing: voicingArr)
    }

    // MARK: Flow

    private var buttonLabel: String {
        switch currentStep {
        case .theory: return "Continue"
        case .practice(let p):
            let n = poolChords(p).count
            return poolIdx >= n - 1 ? "Done practicing" : "Next"
        case .challenge(let c):
            let n = challengeChords(c).count
            return poolIdx >= n - 1 ? "Finish lesson" : "Next"
        }
    }

    private func advance() {
        UISelectionFeedbackGenerator().selectionChanged()
        switch currentStep {
        case .theory:
            nextStep()
        case .practice(let p):
            let chords = poolChords(p)
            if poolIdx < chords.count - 1 {
                poolIdx += 1
                AudioEngine.shared.playChord(chords[poolIdx].voicing)
            } else {
                nextStep()
            }
        case .challenge(let c):
            let chords = challengeChords(c)
            if poolIdx == 0 { challengeStart = Date().timeIntervalSince1970 }
            if poolIdx < chords.count - 1 {
                poolIdx += 1
                AudioEngine.shared.playChord(chords[poolIdx].voicing)
            } else {
                let elapsed = (Date().timeIntervalSince1970 - challengeStart) * 1000
                challengeAvgMs = chords.isEmpty ? nil : elapsed / Double(chords.count)
                finishLesson()
            }
        }
    }

    private func nextStep() {
        if stepIdx < lesson.steps.count - 1 {
            stepIdx += 1
            poolIdx = 0
            // Auto-play first chord of a drill step.
            if case .practice(let p) = currentStep, let first = poolChords(p).first {
                AudioEngine.shared.playChord(first.voicing)
            } else if case .challenge(let c) = currentStep, let first = challengeChords(c).first {
                AudioEngine.shared.playChord(first.voicing)
            }
        } else {
            finishLesson()
        }
    }

    private func finishLesson() {
        CourseProgressStore.shared.completeLesson(course: course, lessonId: lesson.id, challengeAvgMs: challengeAvgMs)
        dismiss()
    }

    private var lessonTitle: String {
        lesson.id.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
}
