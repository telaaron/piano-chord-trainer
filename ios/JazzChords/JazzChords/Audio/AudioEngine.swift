// AudioEngine — chord/note playback via AVAudioEngine.
// Replaces the web app's Tone.js. M2 uses a built-in polyphonic synth voice
// (additive sine + ADSR) so audio works with no bundled asset; a sampled grand
// piano SoundFont is swapped in at M5. Note→octave placement mirrors
// audio.ts notesToToneNames (ascending from octave 3).

import Foundation
import AVFoundation
import MusicEngine

/// Sound presets — parity with audio.ts SoundPreset (timbre approximated by
/// partial mix + envelope until the SF2 lands).
enum SoundPreset: String, CaseIterable, Sendable {
    case grandPiano = "grand-piano"
    case electricPiano = "electric-piano"
    case vibraphone
    case organ
    case synthPad

    var label: String {
        switch self {
        case .grandPiano: return "Grand Piano"
        case .electricPiano: return "Electric Piano"
        case .vibraphone: return "Vibraphone"
        case .organ: return "Organ"
        case .synthPad: return "Synth Pad"
        }
    }
}

/// One sounding voice: a set of partials with a shared ADSR envelope.
private final class Voice {
    var midiNote: Int
    var phase: [Double]
    var partials: [(mult: Double, amp: Double)]
    var freq: Double
    // ADSR (seconds / level)
    var attack: Double
    var decay: Double
    var sustain: Double
    var release: Double
    var age: Double = 0       // seconds since note-on
    var releasedAt: Double?   // age at which release began
    var done = false

    init(midiNote: Int, freq: Double, partials: [(Double, Double)], a: Double, d: Double, s: Double, r: Double) {
        self.midiNote = midiNote
        self.freq = freq
        self.partials = partials
        self.phase = Array(repeating: 0, count: partials.count)
        self.attack = a; self.decay = d; self.sustain = s; self.release = r
    }

    func envelope() -> Double {
        if let rel = releasedAt {
            let t = age - rel
            if t >= release { done = true; return 0 }
            // start from the level at release time (approx sustain) → 0
            return sustain * (1 - t / release)
        }
        if age < attack { return age / attack }
        if age < attack + decay {
            let t = (age - attack) / decay
            return 1 - (1 - sustain) * t
        }
        return sustain
    }
}

final class AudioEngine: @unchecked Sendable {
    static let shared = AudioEngine()

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!
    private let reverb = AVAudioUnitReverb()
    private let sampler = AVAudioUnitSampler()   // sampled grand piano (SoundFont)
    private let sampleRate: Double = 44100

    private let lock = NSLock()
    private var voices: [Voice] = []
    private var preset: SoundPreset = .grandPiano
    private var started = false
    private var samplerLoaded = false
    /// MIDI notes currently sounding on the sampler (so we can release them).
    private var samplerActive: Set<UInt8> = []

    /// Grand piano uses the sampled SoundFont; other presets use the synth voice.
    private var useSampler: Bool { preset == .grandPiano && samplerLoaded }

    private init() {
        setupGraph()
        loadSoundFont()
    }

    private func loadSoundFont() {
        guard let url = Bundle.main.url(forResource: "FluidR3Mono_GM", withExtension: "sf3") else { return }
        do {
            // Program 0 = Acoustic Grand Piano (GM), melodic bank.
            try sampler.loadSoundBankInstrument(at: url, program: 0,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB))
            samplerLoaded = true
        } catch {
            print("[AudioEngine] SoundFont load failed: \(error)")
        }
    }

    // MARK: Graph

    private func setupGraph() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let frames = Int(frameCount)
            let dt = 1.0 / self.sampleRate

            self.lock.lock()
            let voices = self.voices
            self.lock.unlock()

            for frame in 0..<frames {
                var sample = 0.0
                for v in voices where !v.done {
                    let env = v.envelope()
                    if env <= 0 { continue }
                    var s = 0.0
                    for i in 0..<v.partials.count {
                        s += sin(v.phase[i]) * v.partials[i].amp
                        v.phase[i] += 2 * Double.pi * v.freq * v.partials[i].mult * dt
                        if v.phase[i] > 2 * Double.pi { v.phase[i] -= 2 * Double.pi }
                    }
                    sample += s * env
                    v.age += dt
                }
                // soft clip + headroom for polyphony
                sample = tanh(sample * 0.3)
                for buffer in abl {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = Float(sample)
                }
            }

            // reap finished voices
            self.lock.lock()
            self.voices.removeAll { $0.done }
            self.lock.unlock()

            return noErr
        }

        engine.attach(sourceNode)
        engine.attach(sampler)
        engine.attach(reverb)
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 18
        engine.connect(sourceNode, to: reverb, format: format)
        engine.connect(sampler, to: reverb, format: nil)
        engine.connect(reverb, to: engine.mainMixerNode, format: format)
    }

    // MARK: Session / lifecycle

    func start() {
        guard !started else { return }
        configureSession()
        do {
            try engine.start()
            started = true
        } catch {
            print("[AudioEngine] start failed: \(error)")
        }
    }

    private func configureSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
    }

    func setPreset(_ preset: SoundPreset) {
        lock.lock(); self.preset = preset; lock.unlock()
    }

    // MARK: Playback

    /// Play a chord voicing (bare note names, e.g. ["C","E","B"]). Releases the
    /// previous chord first, matching the web's monophonic-chord behavior.
    func playChord(_ notes: [String]) {
        start()
        let midi = Self.notesToMidi(notes)
        if useSampler {
            releaseSampler()
            for m in midi { let n = UInt8(clamping: m); sampler.startNote(n, withVelocity: 90, onChannel: 0); samplerActive.insert(n) }
            return
        }
        lock.lock()
        for v in voices where v.releasedAt == nil { v.releasedAt = v.age }
        for m in midi { voices.append(makeVoice(m)) }
        lock.unlock()
    }

    /// Play a single note by pitch name + octave.
    func playNote(_ note: String, octave: Int = 4) {
        start()
        let pc = noteToSemitone(note)
        guard pc != -1 else { return }
        playMidi(pc + (octave + 1) * 12)
    }

    /// Play a single absolute MIDI note (used by the on-screen keyboard taps).
    func playMidi(_ midiNote: Int) {
        start()
        if useSampler {
            let n = UInt8(clamping: midiNote)
            sampler.startNote(n, withVelocity: 90, onChannel: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.sampler.stopNote(n, onChannel: 0)
                self?.samplerActive.remove(n)
            }
            return
        }
        lock.lock(); voices.append(makeVoice(midiNote)); lock.unlock()
    }

    /// Release everything (chord change / stop).
    func stopAll() {
        if useSampler { releaseSampler() }
        lock.lock()
        for v in voices where v.releasedAt == nil { v.releasedAt = v.age }
        lock.unlock()
    }

    private func releaseSampler() {
        for n in samplerActive { sampler.stopNote(n, onChannel: 0) }
        samplerActive.removeAll()
    }

    // MARK: Voice factory

    private func makeVoice(_ midiNote: Int) -> Voice {
        let freq = 440.0 * pow(2.0, (Double(midiNote) - 69.0) / 12.0)
        let (partials, a, d, s, r) = Self.timbre(for: preset)
        return Voice(midiNote: midiNote, freq: freq, partials: partials, a: a, d: d, s: s, r: r)
    }

    /// Partial mix + ADSR per preset (approximations of the Tone.js presets).
    private static func timbre(for preset: SoundPreset) -> (partials: [(Double, Double)], a: Double, d: Double, s: Double, r: Double) {
        switch preset {
        case .grandPiano:
            return ([(1, 1.0), (2, 0.5), (3, 0.25), (4, 0.12), (6, 0.06)], 0.004, 0.9, 0.18, 0.5)
        case .electricPiano:
            return ([(1, 1.0), (2, 0.3), (3.01, 0.6), (5, 0.15)], 0.005, 0.8, 0.2, 0.7)
        case .vibraphone:
            return ([(1, 1.0), (4, 0.5), (9, 0.18)], 0.001, 1.4, 0.1, 1.2)
        case .organ:
            return ([(1, 0.9), (2, 0.7), (3, 0.5), (4, 0.3), (6, 0.15)], 0.01, 0.1, 0.9, 0.1)
        case .synthPad:
            return ([(1, 0.8), (2, 0.4), (0.5, 0.3)], 0.2, 0.5, 0.6, 1.2)
        }
    }

    // MARK: Note → MIDI mapping (mirrors audio.ts notesToToneNames: ascending from octave 3)

    static func notesToMidi(_ notes: [String]) -> [Int] {
        var result: [Int] = []
        var octave = 3
        var prevSemi = -1
        for note in notes {
            let semi = noteToSemitone(note)
            if semi == -1 { continue }
            if prevSemi != -1 && semi <= prevSemi { octave += 1 }
            // MIDI: C-1 = 0 → midi = pc + (octave+1)*12
            result.append(semi + (octave + 1) * 12)
            prevSemi = semi
        }
        return result
    }
}
