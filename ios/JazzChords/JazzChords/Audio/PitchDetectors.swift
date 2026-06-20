// Pitch detectors. Two implementations behind the PitchDetector protocol:
//
// 1. FFTPitchDetector — works today. vDSP magnitude spectrum + harmonic-product
//    peak picking → MIDI notes. Good for clear piano chords; weaker than ML on
//    dense/quiet voicings. This is what ships in M4.
//
// 2. CoreMLBasicPitchDetector — the target. Conforms to the same protocol so it
//    drops into MicInput unchanged once the Spotify basic-pitch TFJS model is
//    converted to a bundled .mlmodel. Until then it returns empty.

import Foundation
import Accelerate
import CoreML

// MARK: FFT detector

final class FFTPitchDetector: PitchDetector {
    let preferredSampleRate: Double = 22050

    private let log2n: vDSP_Length = 14          // 16384-point FFT
    private let n: Int
    private let fft: FFTSetup
    private var window: [Float]

    init() {
        n = 1 << Int(log2n)
        fft = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2))!
        window = [Float](repeating: 0, count: n)
        vDSP_hann_window(&window, vDSP_Length(n), Int32(vDSP_HANN_NORM))
    }

    deinit { vDSP_destroy_fftsetup(fft) }

    func detect(_ samples: [Float], sampleRate: Double) -> Set<Int> {
        guard samples.count >= n else { return [] }
        // Use the most recent n samples.
        var frame = Array(samples.suffix(n))
        vDSP_vmul(frame, 1, window, 1, &frame, 1, vDSP_Length(n))

        // Real FFT → magnitude spectrum.
        var real = frame
        var imag = [Float](repeating: 0, count: n)
        var mags = [Float](repeating: 0, count: n / 2)
        real.withUnsafeMutableBufferPointer { rp in
            imag.withUnsafeMutableBufferPointer { ip in
                var split = DSPSplitComplex(realp: rp.baseAddress!, imagp: ip.baseAddress!)
                frame.withUnsafeBytes {
                    vDSP_ctoz($0.bindMemory(to: DSPComplex.self).baseAddress!, 2, &split, 1, vDSP_Length(n / 2))
                }
                vDSP_fft_zrip(fft, &split, 1, log2n, FFTDirection(FFT_FORWARD))
                vDSP_zvmags(&split, 1, &mags, 1, vDSP_Length(n / 2))
            }
        }

        // Peak floor relative to the max bin.
        var maxMag: Float = 0
        vDSP_maxv(mags, 1, &maxMag, vDSP_Length(mags.count))
        if maxMag <= 0 { return [] }
        let floor = maxMag * 0.06

        let binHz = Float(sampleRate) / Float(n)
        var noteEnergy: [Int: Float] = [:]

        // Collect spectral peaks → fold into MIDI notes; fundamentals reinforced
        // by harmonics (lightweight harmonic-product idea).
        for bin in 2..<(mags.count - 1) {
            let m = mags[bin]
            if m < floor { continue }
            if m <= mags[bin - 1] || m < mags[bin + 1] { continue } // local peak
            let freq = Float(bin) * binHz
            if freq < 60 || freq > 2000 { continue }
            let midi = Int((69 + 12 * log2(freq / 440)).rounded())
            noteEnergy[midi, default: 0] += m
            // Reinforce the sub-octave (catch harmonics that aren't the fundamental).
            let subMidi = midi - 12
            if subMidi >= 36 { noteEnergy[subMidi, default: 0] += m * 0.25 }
        }

        guard let strongest = noteEnergy.values.max(), strongest > 0 else { return [] }
        let keepThreshold = strongest * 0.2
        let notes = noteEnergy.filter { $0.value >= keepThreshold }.map { $0.key }
        // Cap to a plausible chord size (avoid harmonic confetti).
        return Set(notes.sorted { noteEnergy[$0]! > noteEnergy[$1]! }.prefix(6))
    }
}

// MARK: CoreML basic-pitch (drop-in target)

/// Wraps the converted Spotify basic-pitch CoreML model. Bundle
/// `BasicPitch.mlmodelc` and set MicInput.shared.detector to an instance.
final class CoreMLBasicPitchDetector: PitchDetector {
    let preferredSampleRate: Double = 22050
    private let model: MLModel?

    init() {
        // Loaded lazily; nil until the model is added to the bundle.
        if let url = Bundle.main.url(forResource: "BasicPitch", withExtension: "mlmodelc") {
            model = try? MLModel(contentsOf: url)
        } else {
            model = nil
        }
    }

    var isAvailable: Bool { model != nil }

    func detect(_ samples: [Float], sampleRate: Double) -> Set<Int> {
        // TODO(M4-followup): feed `samples` to the basic-pitch CoreML model,
        // post-process frames/onsets with the audio-input.ts thresholds
        // (onsetThresh 0.5, frameThresh 0.3, amplitude > 0.15) → MIDI notes.
        // Returns empty until the model is bundled.
        return []
    }
}
