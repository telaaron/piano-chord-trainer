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
    /// Tap handler: (chromaticIndex). When nil, taps still preview audio.
    var onKeyTap: ((Int) -> Void)? = nil

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
        .aspectRatio(octaves == .three ? 5.4 : 4.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radius))
    }

    // MARK: Keys

    private func whiteKey(chrIdx: Int, width: CGFloat, height: CGFloat) -> some View {
        let active = layout.activeIndices.contains(chrIdx)
        let root = active && isRootKey(chrIdx)
        let flash = flashPC == chrIdx % 12
        let selected = interactive && selectedPitchClasses.contains(chrIdx % 12)

        return ZStack(alignment: .bottom) {
            Rectangle()
                .fill(whiteFill(active: active, selected: selected, flash: flash))
                .overlay(Rectangle().stroke(palette.keyWhiteBorder, lineWidth: 0.5))
            if root {
                Circle().fill(.white).frame(width: 8, height: 8).padding(.bottom, 8)
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture { tap(chrIdx) }
    }

    private func blackKey(key: BlackKey, height: CGFloat, width: CGFloat) -> some View {
        let active = layout.activeIndices.contains(key.idx)
        let root = active && isRootKey(key.idx)
        let flash = flashPC == key.idx % 12
        let selected = interactive && selectedPitchClasses.contains(key.idx % 12)

        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3)
                .fill(blackFill(active: active, selected: selected, flash: flash))
            if root {
                Circle().fill(.white).frame(width: 6, height: 6).padding(.bottom, 4)
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture { tap(key.idx) }
    }

    // MARK: Fills

    private func whiteFill(active: Bool, selected: Bool, flash: Bool) -> Color {
        if selected { return palette.primary.opacity(0.85) }
        if flash { return palette.accentGreen.opacity(0.7) }
        if active { return palette.primary }
        return palette.keyWhite
    }

    private func blackFill(active: Bool, selected: Bool, flash: Bool) -> Color {
        if selected { return palette.primary }
        if flash { return palette.accentGreen }
        if active { return palette.primary }
        return palette.keyBlack
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
