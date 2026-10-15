// PianoKeyboard — 2 or 3 octave keyboard. Highlights the active voicing keys
// (+ a white root dot) and supports tap-to-play / tap-to-select. Geometry mirrors
// the web PianoKeyboard.svelte: white keys flex-fill; black keys positioned at
// (pos / whiteKeyCount) of the width, half-height, centered on the boundary.

import SwiftUI
import MusicEngine

struct PianoKeyboard: View {
    @Environment(\.palette) private var palette

    var chordData: ChordWithNotes?
    var accidentalPref: AccidentalPreference = .sharps
    var showVoicing: Bool = true
    /// Force octave count (prevents zoom across a session).
    var forceOctaves: OctaveCount? = nil
    /// Interactive: taps select pitch classes (ear training) instead of just previewing.
    var interactive: Bool = false
    /// Pitch classes the user has selected (ear-training guess).
    var selectedPitchClasses: Set<Int> = []
    /// Live input: MIDI/mic notes currently held (chromatic-index space from C3).
    var heldNotes: Set<Int> = []
    /// Expected pitch classes — held notes are colored green if expected, red if not.
    var expectedPitchClasses: Set<Int> = []
    /// Show the MIDI/mic green/red overlay.
    var showInput: Bool = false
    /// Tap handler: (chromaticIndex). When nil, taps still preview audio.
    var onKeyTap: ((Int) -> Void)? = nil
    /// Cap the rendered keyboard height (iPad: let it grow much taller than the
    /// aspect ratio alone would allow on a wide screen).
    var maxHeight: CGFloat = 200
    /// After a wrong attempt: outline voicing keys that were not played.
    var showMissing: Bool = false

    /// Chromatic indices (C3 = 0) currently held via input.
    private var heldKeyIndices: Set<Int> {
        guard showInput else { return [] }
        var set = Set<Int>()
        for mn in heldNotes {
            let offset = mn - 48 // keyboard starts at C3 (MIDI 48)
            if offset >= 0 { set.insert(offset) }
        }
        return set
    }

    @State private var flashPC: Int? = nil

    private var layout: KeyboardLayout {
        guard let chordData, showVoicing else {
            return KeyboardLayout(activeIndices: [], octaves: forceOctaves ?? .two)
        }
        let result = getKeyboardLayout(chordData, accidentalPref)
        if let forceOctaves, forceOctaves.rawValue > result.octaves.rawValue {
            return KeyboardLayout(activeIndices: result.activeIndices, octaves: forceOctaves)
        }
        return result
    }

    private var octaves: OctaveCount { layout.octaves }
    private var whiteKeyCount: Int { octaves == .three ? 21 : 14 }
    private var blackKeys: [BlackKey] { generateBlackKeys(octaves) }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let whiteW = w / CGFloat(whiteKeyCount)

            ZStack(alignment: .topLeading) {
                // White keys
                HStack(spacing: 0) {
                    ForEach(0..<whiteKeyCount, id: \.self) { i in
                        let chrIdx = whiteKeyChromaticIndex(i)
                        whiteKey(chrIdx: chrIdx, width: whiteW, height: h)
                    }
                }

                // Black keys
                ForEach(blackKeys, id: \.idx) { key in
                    let x = (CGFloat(key.pos) / CGFloat(whiteKeyCount)) * w
                    let bw = whiteW * (octaves == .three ? 0.6 : 0.62)
                    blackKey(key: key, height: h * 0.6, width: bw)
                        .position(x: x, y: h * 0.3)
                }
            }
        }
        .padding(.top, 2)
        .background(palette.keyBed)
        .aspectRatio(octaves == .three ? 5.4 : 4.0, contentMode: .fit)
        .frame(maxHeight: maxHeight)
    }

    // MARK: Keys

    private func whiteKey(chrIdx: Int, width: CGFloat, height: CGFloat) -> some View {
        let r = role(chrIdx, active: layout.activeIndices.contains(chrIdx))
        let root = layout.activeIndices.contains(chrIdx) && isRootKey(chrIdx)
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: 6, bottomTrailingRadius: 6)

        return ZStack(alignment: .bottom) {
            shape
                .fill(fill(chrIdx, role: r, isBlack: false))
                .overlay {
                    if r == .missing {
                        shape.strokeBorder(palette.action, lineWidth: 2.5)
                    }
                }
                .padding(.horizontal, 1)
            if root {
                Circle().fill(palette.keyBed.opacity(0.55)).frame(width: 7, height: 7).padding(.bottom, 9)
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture { tap(chrIdx) }
    }

    private func blackKey(key: BlackKey, height: CGFloat, width: CGFloat) -> some View {
        let r = role(key.idx, active: layout.activeIndices.contains(key.idx))
        let root = layout.activeIndices.contains(key.idx) && isRootKey(key.idx)
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: 4, bottomTrailingRadius: 4)

        return ZStack(alignment: .bottom) {
            shape
                .fill(fill(key.idx, role: r, isBlack: true))
                .overlay {
                    if r == .missing {
                        shape.strokeBorder(palette.action, lineWidth: 2.5)
                    }
                }
            if root {
                Circle().fill(palette.keyBed.opacity(0.55)).frame(width: 6, height: 6).padding(.bottom, 5)
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture { tap(key.idx) }
    }

    // MARK: Roles & fills

    enum KeyRole: Equatable {
        case idle, voicing, selected, missing
        case held(correct: Bool)
    }

    /// What a key shows. `held` are chromatic indices (C3 = 0), `expected` pitch
    /// classes. Live input wins; then the tap-guess selection; then a voicing
    /// key — marked missing after a wrong attempt when it was not played.
    static func role(chrIdx: Int, active: Bool, held: Set<Int>, expected: Set<Int>,
                     selected: Bool, showInput: Bool, showMissing: Bool) -> KeyRole {
        if showInput, held.contains(chrIdx) {
            return .held(correct: expected.contains(chrIdx % 12))
        }
        if selected { return .selected }
        if active {
            return showMissing ? .missing : .voicing
        }
        return .idle
    }

    /// Gold for played, expected and selected keys; red for a wrong held key.
    static func fill(for role: KeyRole, isBlack: Bool, palette: Palette) -> Color {
        switch role {
        case .held(correct: false): return palette.action
        case .held(correct: true), .voicing, .selected: return palette.musicFill
        case .idle, .missing: return isBlack ? palette.keyBlack : palette.keyWhite
        }
    }

    private func role(_ chrIdx: Int, active: Bool) -> KeyRole {
        Self.role(chrIdx: chrIdx, active: active, held: heldKeyIndices, expected: expectedPitchClasses,
                  selected: interactive && selectedPitchClasses.contains(chrIdx % 12),
                  showInput: showInput, showMissing: showMissing)
    }

    private func fill(_ chrIdx: Int, role: KeyRole, isBlack: Bool) -> Color {
        if flashPC == chrIdx % 12, role == .idle { return palette.musicFill.opacity(0.7) }
        return Self.fill(for: role, isBlack: isBlack, palette: palette)
    }

    private func isRootKey(_ chrIdx: Int) -> Bool {
        guard let chordData else { return false }
        return isRootIndex(chrIdx, chordData.root, chordData.voicing)
    }

    // MARK: Interaction

    private func tap(_ chrIdx: Int) {
        // Preview audio (keyboard starts at C3 = MIDI 48).
        AudioEngine.shared.playMidi(48 + chrIdx)
        onKeyTap?(chrIdx)
        // brief flash
        flashPC = chrIdx % 12
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if flashPC == chrIdx % 12 { flashPC = nil }
        }
    }
}
