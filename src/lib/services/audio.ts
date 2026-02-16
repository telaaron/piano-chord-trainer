// Audio playback using Tone.js – plays chord voicings with a piano sampler
import * as Tone from 'tone';

let synth: Tone.PolySynth | null = null;
let started = false;

/** Ensure AudioContext is started (must be called from user gesture) */
async function ensureStarted(): Promise<void> {
	if (!started) {
		await Tone.start();
		started = true;
	}
}

function getSynth(): Tone.PolySynth {
	if (!synth) {
		synth = new Tone.PolySynth(Tone.Synth, {
			oscillator: { type: 'triangle8' },
			envelope: {
				attack: 0.02,
				decay: 0.3,
				sustain: 0.4,
				release: 1.2,
			},
			volume: -8,
		}).toDestination();
		synth.maxPolyphony = 8;
	}
	return synth;
}

/**
 * Map note names (e.g. "C", "Db", "F#") to Tone.js-friendly names with octave.
 * Assumes voicing notes are in ascending order starting around middle C (C4).
 */
function notesToToneNames(notes: string[]): string[] {
	const noteOrder = ['C', 'C#', 'Db', 'D', 'D#', 'Eb', 'E', 'Fb', 'E#', 'F', 'F#', 'Gb', 'G', 'G#', 'Ab', 'A', 'A#', 'Bb', 'B', 'Cb', 'B#'];

	function semitone(note: string): number {
		const map: Record<string, number> = {
			'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
			'E': 4, 'Fb': 4, 'E#': 5, 'F': 5, 'F#': 6, 'Gb': 6,
			'G': 7, 'G#': 8, 'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10,
			'B': 11, 'Cb': 11, 'B#': 0
		};
		return map[note] ?? 0;
	}

	const result: string[] = [];
	let octave = 4;
	let prevSemi = -1;

	for (const note of notes) {
		const semi = semitone(note);
		if (prevSemi !== -1 && semi <= prevSemi) {
			octave++;
		}
		result.push(`${note}${octave}`);
		prevSemi = semi;
	}

	return result;
}

/**
 * Play a chord voicing.
 * @param notes - Array of note names like ["C", "E", "G", "B"]
 * @param duration - Duration string (e.g. "2n" = half note, "1n" = whole note)
 */
export async function playChord(notes: string[], duration: string = '2n'): Promise<void> {
	await ensureStarted();
	const s = getSynth();
	const toneNotes = notesToToneNames(notes);
	s.triggerAttackRelease(toneNotes, duration);
}

/**
 * Play a single note.
 * @param note - Note name with octave, e.g. "C4"
 */
export async function playNote(note: string, duration: string = '8n'): Promise<void> {
	await ensureStarted();
	const s = getSynth();
	s.triggerAttackRelease(note, duration);
}

/** Release all playing notes */
export function stopAll(): void {
	if (synth) {
		synth.releaseAll();
	}
}

/** Clean up synth */
export function disposeAudio(): void {
	if (synth) {
		synth.dispose();
		synth = null;
	}
}

// ─── Metronome ──────────────────────────────────────────────

let metronomeLoop: Tone.Loop | null = null;
let metronomeSynth: Tone.MembraneSynth | null = null;
let metronomeRunning = false;
let beatCount = 0;
let onBeatCallback: ((beat: number) => void) | null = null;

function getMetronomeSynth(): Tone.MembraneSynth {
	if (!metronomeSynth) {
		metronomeSynth = new Tone.MembraneSynth({
			pitchDecay: 0.008,
			octaves: 2,
			envelope: {
				attack: 0.001,
				decay: 0.1,
				sustain: 0,
				release: 0.05,
			},
			volume: -12,
		}).toDestination();
	}
	return metronomeSynth;
}

/**
 * Start metronome at given BPM.
 * @param bpm - Beats per minute
 * @param beatsPerBar - Time signature numerator (default 4)
 * @param onBeat - Callback fired on each beat with beat number (1-based)
 */
export async function startMetronome(
	bpm: number,
	beatsPerBar: number = 4,
	onBeat?: (beat: number) => void,
): Promise<void> {
	await ensureStarted();
	stopMetronome();

	Tone.getTransport().bpm.value = bpm;
	beatCount = 0;
	onBeatCallback = onBeat ?? null;

	const click = getMetronomeSynth();

	metronomeLoop = new Tone.Loop((time) => {
		beatCount++;
		const currentBeat = ((beatCount - 1) % beatsPerBar) + 1;

		// Accent on beat 1
		if (currentBeat === 1) {
			click.triggerAttackRelease('C3', '32n', time);
		} else {
			click.triggerAttackRelease('C4', '32n', time);
		}

		if (onBeatCallback) {
			// Schedule callback slightly after audio for visual sync
			Tone.getDraw().schedule(() => {
				onBeatCallback!(currentBeat);
			}, time);
		}
	}, '4n');

	metronomeLoop.start(0);
	Tone.getTransport().start();
	metronomeRunning = true;
}

/** Stop metronome */
export function stopMetronome(): void {
	if (metronomeLoop) {
		metronomeLoop.stop();
		metronomeLoop.dispose();
		metronomeLoop = null;
	}
	Tone.getTransport().stop();
	beatCount = 0;
	metronomeRunning = false;
	onBeatCallback = null;
}

/** Check if metronome is running */
export function isMetronomeRunning(): boolean {
	return metronomeRunning;
}

/** Update metronome BPM live */
export function setMetronomeBpm(bpm: number): void {
	Tone.getTransport().bpm.value = bpm;
}

/** Dispose all audio resources */
export function disposeAll(): void {
	stopMetronome();
	disposeAudio();
	if (metronomeSynth) {
		metronomeSynth.dispose();
		metronomeSynth = null;
	}
}
