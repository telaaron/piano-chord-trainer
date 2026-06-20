// Metronome — accented click on beat 1, 40–240 BPM, with a (beat, time) callback
// for In-Time mode. Mirrors audio.ts startMetronome: the callback fires per beat
// with the audio-clock time so chords can be scheduled exactly on the beat.
//
// M2 implementation: a dedicated AVAudioEngine renders short click transients via
// an AVAudioSourceNode driven by a sample-counter, so click timing is
// sample-accurate. The beat callback is delivered on the main actor.

import Foundation
import AVFoundation

@MainActor
final class Metronome {
    static let shared = Metronome()

    private let engine = AVAudioEngine()
    private var source: AVAudioSourceNode!
    private let sampleRate: Double = 44100

    private let lock = NSLock()
    private var running = false
    private var bpm: Double = 80
    private var beatsPerBar = 4
    private var samplesPerBeat = 0
    private var sampleCounter = 0
    private var beatIndex = 0           // 0-based count of beats emitted
    private var clickPhase = 0          // samples into the current click transient (0 = idle)
    private var clickIsAccent = false

    /// (currentBeat 1...beatsPerBar, audioTimeSeconds)
    var onBeat: ((Int, Double) -> Void)?

    private init() {
        setup()
    }

    private func setup() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        source = AVAudioSourceNode { [weak self] _, _, frameCount, abl -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(abl)
            let frames = Int(frameCount)

            self.lock.lock()
            defer { self.lock.unlock() }

            for frame in 0..<frames {
                if self.running {
                    if self.sampleCounter <= 0 {
                        // Beat boundary — emit a beat + arm a click.
                        self.beatIndex += 1
                        let beat = ((self.beatIndex - 1) % self.beatsPerBar) + 1
                        self.clickIsAccent = (beat == 1)
                        self.clickPhase = 1
                        self.sampleCounter = self.samplesPerBeat
                        let now = CACurrentMediaTime()
                        if let cb = self.onBeat {
                            Task { @MainActor in cb(beat, now) }
                        }
                    }
                    self.sampleCounter -= 1
                }

                var sample = 0.0
                if self.clickPhase > 0 {
                    let dur = 1800 // samples (~40ms) click
                    let t = Double(self.clickPhase)
                    let freq = self.clickIsAccent ? 1500.0 : 1000.0
                    let env = max(0, 1 - t / Double(dur))
                    sample = sin(2 * Double.pi * freq * t / self.sampleRate) * env * 0.5
                    self.clickPhase += 1
                    if self.clickPhase > dur { self.clickPhase = 0 }
                }

                for buffer in buffers {
                    let ptr = buffer.mData!.assumingMemoryBound(to: Float.self)
                    ptr[frame] = Float(sample)
                }
            }
            return noErr
        }
        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
    }

    func start(bpm: Double, beatsPerBar: Int = 4, onBeat: ((Int, Double) -> Void)? = nil) {
        self.onBeat = onBeat
        lock.lock()
        self.bpm = clampBpm(bpm)
        self.beatsPerBar = beatsPerBar
        self.samplesPerBeat = Int(sampleRate * 60.0 / self.bpm)
        self.sampleCounter = 0
        self.beatIndex = 0
        self.clickPhase = 0
        self.running = true
        lock.unlock()

        if !engine.isRunning {
            #if os(iOS)
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
            #endif
            try? engine.start()
        }
    }

    func stop() {
        lock.lock(); running = false; clickPhase = 0; lock.unlock()
    }

    func setBpm(_ bpm: Double) {
        lock.lock()
        self.bpm = clampBpm(bpm)
        self.samplesPerBeat = Int(sampleRate * 60.0 / self.bpm)
        lock.unlock()
    }

    var isRunning: Bool {
        lock.lock(); defer { lock.unlock() }; return running
    }

    private func clampBpm(_ v: Double) -> Double { max(40, min(240, v)) }
}
