// MicInput — polyphonic microphone chord detection. Mirrors the flow of
// src/lib/services/audio-input.ts: mic tap → ring buffer → periodic analysis with
// an energy gate + a playback-suppression window → detected pitch set → callback.
//
// The detector is pluggable (PitchDetector). M4 ships an FFT peak-picking
// detector (vDSP) that works today; the Spotify basic-pitch model, once
// converted to CoreML, conforms to the same protocol and drops in with no
// changes to this pipeline or the trainer.

import Foundation
import Observation
import AVFoundation
import Accelerate
import MusicEngine

/// A detector turns a mono PCM frame (at `sampleRate`) into MIDI note numbers.
protocol PitchDetector: AnyObject {
    /// Preferred input sample rate (Hz). The pipeline resamples to this.
    var preferredSampleRate: Double { get }
    /// Detect sounding MIDI notes in the buffer. Empty = silence/none.
    func detect(_ samples: [Float], sampleRate: Double) -> Set<Int>
}

enum MicState: String { case idle, requesting, listening, denied, unsupported }

@MainActor
@Observable
final class MicInput {
    static let shared = MicInput()

    private(set) var state: MicState = .idle
    private(set) var activeNotes: Set<Int> = []
    private(set) var level: Double = 0

    var onNotesChanged: ((Set<Int>) -> Void)?

    /// Swap to the CoreML basic-pitch detector when available.
    var detector: PitchDetector = FFTPitchDetector()

    private let engine = AVAudioEngine()
    private let analysisQueue = DispatchQueue(label: "mic.analysis")
    private var ring = [Float](repeating: 0, count: 0)
    private var writeIdx = 0
    private var filled = false
    private var nativeRate: Double = 44100
    private var timer: Timer?
    private var analyzing = false
    private var suppressUntil: TimeInterval = 0
    private let energyThreshold: Float = 0.0013
    private var silenceCycles = 0

    private init() {}

    // MARK: Lifecycle

    func start() {
        guard state != .listening else { return }
        state = .requesting
        #if os(iOS)
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                if granted { self.beginCapture() } else { self.state = .denied }
            }
        }
        #else
        beginCapture()
        #endif
    }

    private func beginCapture() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
        try? session.setActive(true)
        #endif

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        nativeRate = format.sampleRate
        ring = [Float](repeating: 0, count: Int(nativeRate * 2)) // 2s
        writeIdx = 0; filled = false

        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            self?.append(buffer)
        }
        do {
            try engine.start()
            state = .listening
            timer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
                self?.analyzeTick()
            }
        } catch {
            state = .unsupported
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        engine.inputNode.removeTap(onBus: 0)
        if engine.isRunning { engine.stop() }
        activeNotes = []
        onNotesChanged?(activeNotes)
        state = .idle
    }

    /// Mute detection briefly when we play audio (avoid self-triggering).
    func suppress(_ seconds: TimeInterval = 2.5) {
        suppressUntil = CACurrentMediaTime() + seconds
        if !activeNotes.isEmpty { activeNotes = []; onNotesChanged?(activeNotes) }
    }

    // MARK: Capture

    private nonisolated func append(_ buffer: AVAudioPCMBuffer) {
        guard let ch = buffer.floatChannelData?[0] else { return }
        let n = Int(buffer.frameLength)
        // Copy to a value array on the audio thread (pointer can't cross actors).
        let chunk = Array(UnsafeBufferPointer(start: ch, count: n))
        Task { @MainActor in self.writeRing(chunk) }
    }

    private func writeRing(_ data: [Float]) {
        for v in data {
            ring[writeIdx] = v
            writeIdx += 1
            if writeIdx >= ring.count { writeIdx = 0; filled = true }
        }
    }

    // MARK: Analysis

    private func rms() -> Float {
        var sum: Float = 0
        vDSP_measqv(ring, 1, &sum, vDSP_Length(ring.count))
        return sqrt(sum)
    }

    private func analyzeTick() {
        if analyzing { return }
        if CACurrentMediaTime() < suppressUntil { return }

        let energy = rms()
        level = Double(min(1, energy * 20))

        if energy < energyThreshold {
            silenceCycles += 1
            if silenceCycles > 4 && !activeNotes.isEmpty {
                activeNotes = []; onNotesChanged?(activeNotes)
            }
            return
        }
        silenceCycles = 0

        // Linearize the circular buffer.
        let snapshot: [Float]
        if filled {
            snapshot = Array(ring[writeIdx...] + ring[..<writeIdx])
        } else {
            snapshot = Array(ring[..<writeIdx])
        }
        let rate = nativeRate
        let det = detector
        analyzing = true
        analysisQueue.async { [weak self] in
            let resampled = MicInput.resample(snapshot, from: rate, to: det.preferredSampleRate)
            let notes = det.detect(resampled, sampleRate: det.preferredSampleRate)
            Task { @MainActor in
                guard let self else { return }
                self.activeNotes = notes
                self.onNotesChanged?(notes)
                self.analyzing = false
            }
        }
    }

    /// Simple linear resample (good enough for pitch; basic-pitch needs 22050 Hz).
    nonisolated static func resample(_ input: [Float], from: Double, to: Double) -> [Float] {
        if abs(from - to) < 1 || input.isEmpty { return input }
        let ratio = to / from
        let outCount = Int(Double(input.count) * ratio)
        var out = [Float](repeating: 0, count: outCount)
        for i in 0..<outCount {
            let src = Double(i) / ratio
            let i0 = Int(src)
            let frac = Float(src - Double(i0))
            let a = input[min(i0, input.count - 1)]
            let b = input[min(i0 + 1, input.count - 1)]
            out[i] = a + (b - a) * frac
        }
        return out
    }
}
