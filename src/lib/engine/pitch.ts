// ══════════════════════════════════════════════════════════════════════════════
// Monophonic pitch detection (YIN, de Cheveigné & Kawahara 2002).
//
// For one voice singing one note: no model, no download, a few milliseconds of
// maths per frame. Chords on a piano still go through basic-pitch
// (services/audio-input.ts); this is for the sing rounds.
// ══════════════════════════════════════════════════════════════════════════════

export interface PitchResult {
	/** Fundamental frequency in Hz. */
	freq: number;
	/** 0–1, how periodic the frame is (1 − YIN's aperiodicity). */
	clarity: number;
	/** Root-mean-square level of the frame. */
	rms: number;
}

export interface PitchOptions {
	/** Lowest frequency searched (Hz). Default 70 (below a bass's low C#2). */
	minFreq?: number;
	/** Highest frequency searched (Hz). Default 1100 (above a soprano's C6). */
	maxFreq?: number;
	/** YIN absolute threshold: lower is stricter. Default 0.15. */
	threshold?: number;
	/** Frames quieter than this RMS are silence. Default 0.01. */
	minRms?: number;
}

/** MIDI note number (fractional) for a frequency. */
export function freqToMidi(freq: number): number {
	return 69 + 12 * Math.log2(freq / 440);
}

/**
 * Pitch of one frame of mono audio, or null when the frame is silent or not
 * periodic enough to be a sung note. The frame must hold at least two periods
 * of `minFreq` (≈ 30 ms at the default 70 Hz).
 */
export function detectPitch(
	samples: Float32Array,
	sampleRate: number,
	{ minFreq = 70, maxFreq = 1100, threshold = 0.15, minRms = 0.01 }: PitchOptions = {},
): PitchResult | null {
	const n = samples.length;
	let sumSq = 0;
	for (let i = 0; i < n; i++) sumSq += samples[i] * samples[i];
	const rms = Math.sqrt(sumSq / n);
	if (rms < minRms) return null;

	const minTau = Math.max(2, Math.floor(sampleRate / maxFreq));
	const maxTau = Math.min(Math.floor(sampleRate / minFreq), Math.floor(n / 2));
	if (maxTau <= minTau) return null;
	const w = n - maxTau;

	// Difference function d(τ) and its cumulative-mean-normalised form d'(τ).
	const cmnd = new Float32Array(maxTau + 1);
	cmnd[0] = 1;
	let running = 0;
	for (let tau = 1; tau <= maxTau; tau++) {
		let d = 0;
		for (let i = 0; i < w; i++) {
			const diff = samples[i] - samples[i + tau];
			d += diff * diff;
		}
		running += d;
		cmnd[tau] = running === 0 ? 1 : (d * tau) / running;
	}

	// First dip under the threshold, followed down to its local minimum. Taking
	// the first (not the deepest) dip is what keeps YIN off the octave below.
	let tau = -1;
	for (let t = minTau; t <= maxTau; t++) {
		if (cmnd[t] < threshold) {
			while (t + 1 <= maxTau && cmnd[t + 1] < cmnd[t]) t++;
			tau = t;
			break;
		}
	}
	if (tau < 0) return null;

	// Parabolic interpolation around the minimum for sub-sample precision.
	let refined = tau;
	if (tau > 1 && tau < maxTau) {
		const a = cmnd[tau - 1];
		const b = cmnd[tau];
		const c = cmnd[tau + 1];
		const denom = a + c - 2 * b;
		if (denom !== 0) refined = tau + (a - c) / (2 * denom);
	}

	return { freq: sampleRate / refined, clarity: 1 - cmnd[tau], rms };
}

/**
 * Turns a stream of per-frame pitches into notes. A sung note scoops, wobbles
 * and starts with a consonant; it only counts once the same semitone has held
 * for `frames` frames in a row (at ~50 ms per frame, 4 frames ≈ 200 ms).
 */
export class NoteStabilizer {
	private candidate: number | null = null;
	private count = 0;

	constructor(private readonly frames = 4) {}

	/** Feed one frame's MIDI pitch (fractional) or null; returns the held note or null. */
	push(midi: number | null): number | null {
		if (midi === null) {
			this.candidate = null;
			this.count = 0;
			return null;
		}
		const note = Math.round(midi);
		if (note === this.candidate) this.count++;
		else {
			this.candidate = note;
			this.count = 1;
		}
		return this.count >= this.frames ? note : null;
	}
}
