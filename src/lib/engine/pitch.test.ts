import { describe, it, expect } from 'vitest';
import { detectPitch, freqToMidi, NoteStabilizer } from './pitch';

const SR = 48000;

/** A sung-like tone: harmonics, optional vibrato, optional noise. */
function voice(
	freq: number,
	{ ms = 60, vibrato = 0, harmonics = [1, 0.7, 0.5, 0.3, 0.2], noise = 0, seed = 1 } = {},
): Float32Array {
	const n = Math.round((SR * ms) / 1000);
	const out = new Float32Array(n);
	let phase = 0;
	let s = seed;
	const rand = () => ((s = (s * 16807) % 2147483647) / 2147483647) * 2 - 1;
	for (let i = 0; i < n; i++) {
		const t = i / SR;
		const f = freq * 2 ** ((vibrato * Math.sin(2 * Math.PI * 5.5 * t)) / 12);
		phase += (2 * Math.PI * f) / SR;
		let v = 0;
		harmonics.forEach((a, h) => (v += a * Math.sin((h + 1) * phase)));
		out[i] = 0.3 * v + noise * rand();
	}
	return out;
}

const hz = (midi: number) => 440 * 2 ** ((midi - 69) / 12);

describe('detectPitch (YIN)', () => {
	it('finds the note of a sung tone across a singing range', () => {
		for (const midi of [43, 48, 52, 55, 60, 64, 67, 72, 76]) {
			const r = detectPitch(voice(hz(midi)), SR);
			expect(r, `midi ${midi}`).not.toBeNull();
			expect(Math.round(freqToMidi(r!.freq))).toBe(midi);
		}
	});

	it('is not fooled into an octave by a weak fundamental', () => {
		// Many voices put more energy in the 2nd harmonic than the fundamental.
		const r = detectPitch(voice(hz(55), { harmonics: [0.4, 1, 0.6, 0.3] }), SR);
		expect(Math.round(freqToMidi(r!.freq))).toBe(55);
	});

	it('copes with vibrato and some room noise', () => {
		const r = detectPitch(voice(hz(62), { vibrato: 0.3, noise: 0.03 }), SR);
		expect(Math.round(freqToMidi(r!.freq))).toBe(62);
	});

	it('works on the 2048-sample frames an AnalyserNode hands out at 44.1 kHz', () => {
		for (const midi of [43, 60, 79]) {
			const f = hz(midi);
			const frame = new Float32Array(2048).map((_, i) => 0.3 * Math.sin((2 * Math.PI * f * i) / 44100));
			expect(Math.round(freqToMidi(detectPitch(frame, 44100)!.freq))).toBe(midi);
		}
	});

	it('reports nothing for noise or silence', () => {
		let s = 7;
		const noise = new Float32Array(2880).map(() => ((s = (s * 16807) % 2147483647) / 2147483647) * 2 - 1);
		expect(detectPitch(noise, SR)).toBeNull();
		expect(detectPitch(new Float32Array(2880), SR)).toBeNull();
	});
});

describe('freqToMidi', () => {
	it('maps A4 to 69 and C4 to 60', () => {
		expect(freqToMidi(440)).toBeCloseTo(69, 5);
		expect(freqToMidi(261.6256)).toBeCloseTo(60, 3);
	});
});

describe('NoteStabilizer', () => {
	it('reports a note only once it has held for enough frames', () => {
		const st = new NoteStabilizer(3);
		expect(st.push(60.1)).toBeNull();
		expect(st.push(59.8)).toBeNull();
		expect(st.push(60.2)).toBe(60);
		expect(st.push(60)).toBe(60);
	});

	it('ignores a scoop through neighbouring notes', () => {
		const st = new NoteStabilizer(3);
		const out = [57.6, 58.4, 59.3, 60, 60.1, 60].map((m) => st.push(m));
		expect(out.filter((x) => x !== null)).toEqual([60]);
	});

	it('drops the note on silence', () => {
		const st = new NoteStabilizer(2);
		st.push(64);
		expect(st.push(64)).toBe(64);
		expect(st.push(null)).toBeNull();
		expect(st.push(64)).toBeNull();
	});
});
