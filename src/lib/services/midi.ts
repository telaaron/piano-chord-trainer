// Web MIDI API service – connects to MIDI keyboards, tracks active notes, validates chords

import { noteToSemitone } from '$lib/engine';

export type MidiConnectionState = 'disconnected' | 'connecting' | 'connected' | 'unsupported';

export interface MidiDevice {
	id: string;
	name: string;
}

export interface ChordMatchResult {
	/** All expected notes are held (possibly in any octave) */
	correct: boolean;
	/** Semitones expected but not yet held */
	missing: number[];
	/** Semitones held but not in the chord */
	extra: number[];
	/** 0–1 ratio of how many expected notes are held */
	accuracy: number;
}

type NoteCallback = (activeNotes: Set<number>) => void;
type ConnectionCallback = (state: MidiConnectionState) => void;
type DeviceListCallback = (devices: MidiDevice[]) => void;

export class MidiService {
	private access: MIDIAccess | null = null;
	/** Currently held MIDI note numbers (0–127) */
	private _activeNotes = new Set<number>();
	private _state: MidiConnectionState = 'disconnected';
	private _devices: MidiDevice[] = [];
	private _selectedDeviceId: string | null = null;

	// Callbacks
	private onNoteChange: NoteCallback | null = null;
	private onConnectionChange: ConnectionCallback | null = null;
	private onDeviceListChange: DeviceListCallback | null = null;

	/** Currently held MIDI note numbers */
	get activeNotes(): ReadonlySet<number> {
		return this._activeNotes;
	}

	get state(): MidiConnectionState {
		return this._state;
	}

	get devices(): readonly MidiDevice[] {
		return this._devices;
	}

	get selectedDeviceId(): string | null {
		return this._selectedDeviceId;
	}

	// ─── Event registration ────────────────────────────────────
	onNotes(cb: NoteCallback): void {
		this.onNoteChange = cb;
	}

	onConnection(cb: ConnectionCallback): void {
		this.onConnectionChange = cb;
	}

	onDevices(cb: DeviceListCallback): void {
		this.onDeviceListChange = cb;
	}

	// ─── Lifecycle ──────────────────────────────────────────────

	/** Request MIDI access. Returns true if API is available. */
	async init(): Promise<boolean> {
		if (typeof navigator === 'undefined' || !navigator.requestMIDIAccess) {
			this.setState('unsupported');
			return false;
		}

		this.setState('connecting');

		try {
			this.access = await navigator.requestMIDIAccess({ sysex: false });
			this.refreshDeviceList();
			this.access.onstatechange = () => this.refreshDeviceList();

			// Auto-select first device if available
			if (this._devices.length > 0 && !this._selectedDeviceId) {
				this.selectDevice(this._devices[0].id);
			} else {
				this.setState('connected');
			}

			return true;
		} catch (err) {
			console.warn('MIDI access denied:', err);
			this.setState('disconnected');
			return false;
		}
	}

	/** Select a specific MIDI input device */
	selectDevice(deviceId: string): void {
		// Detach old listeners
		this.detachListeners();
		this._selectedDeviceId = deviceId;

		if (!this.access) return;

		const input = this.access.inputs.get(deviceId);
		if (input) {
			input.onmidimessage = (e) => this.handleMessage(e);
			this.setState('connected');
		}
	}

	/** Clean up everything */
	destroy(): void {
		this.detachListeners();
		this._activeNotes.clear();
		this.access = null;
		this.setState('disconnected');
	}

	// ─── Chord matching ─────────────────────────────────────────

	/**
	 * Check if the currently held MIDI notes match the expected chord.
	 * Tolerant: octave-agnostic comparison (pitch classes mod 12).
	 */
	checkChord(expectedNotes: string[]): ChordMatchResult {
		const expectedSemitones = new Set<number>();
		for (const note of expectedNotes) {
			const st = noteToSemitone(note);
			if (st !== -1) expectedSemitones.add(st);
		}

		// Reduce active MIDI notes to pitch classes (0–11)
		const activePitchClasses = new Set<number>();
		for (const midiNote of this._activeNotes) {
			activePitchClasses.add(midiNote % 12);
		}

		const missing: number[] = [];
		const matched: number[] = [];

		for (const expected of expectedSemitones) {
			if (activePitchClasses.has(expected)) {
				matched.push(expected);
			} else {
				missing.push(expected);
			}
		}

		const extra: number[] = [];
		for (const active of activePitchClasses) {
			if (!expectedSemitones.has(active)) {
				extra.push(active);
			}
		}

		const total = expectedSemitones.size;
		const accuracy = total > 0 ? matched.length / total : 0;

		return {
			correct: missing.length === 0 && extra.length === 0,
			missing,
			extra,
			accuracy,
		};
	}

	/**
	 * Lenient match: all expected notes are held, extra notes tolerated.
	 * Useful for players who add extensions or octave doublings.
	 */
	checkChordLenient(expectedNotes: string[]): ChordMatchResult {
		const result = this.checkChord(expectedNotes);
		return {
			...result,
			correct: result.missing.length === 0,
		};
	}

	// ─── Private ────────────────────────────────────────────────

	private handleMessage(event: MIDIMessageEvent): void {
		const data = event.data;
		if (!data || data.length < 3) return;

		const status = data[0] & 0xf0;
		const note = data[1];
		const velocity = data[2];

		if (status === 0x90 && velocity > 0) {
			// Note On
			this._activeNotes.add(note);
			this.onNoteChange?.(this._activeNotes);
		} else if (status === 0x80 || (status === 0x90 && velocity === 0)) {
			// Note Off
			this._activeNotes.delete(note);
			this.onNoteChange?.(this._activeNotes);
		}
	}

	private refreshDeviceList(): void {
		if (!this.access) return;

		const newDevices: MidiDevice[] = [];
		this.access.inputs.forEach((input) => {
			newDevices.push({
				id: input.id,
				name: input.name || `MIDI Input ${input.id}`,
			});
		});

		this._devices = newDevices;
		this.onDeviceListChange?.(newDevices);

		// If selected device disappeared, try first available
		if (this._selectedDeviceId && !newDevices.find((d) => d.id === this._selectedDeviceId)) {
			if (newDevices.length > 0) {
				this.selectDevice(newDevices[0].id);
			} else {
				this._selectedDeviceId = null;
				this.setState('connected'); // API works, just no device
			}
		}
	}

	private detachListeners(): void {
		if (!this.access || !this._selectedDeviceId) return;
		const input = this.access.inputs.get(this._selectedDeviceId);
		if (input) input.onmidimessage = null;
	}

	private setState(state: MidiConnectionState): void {
		this._state = state;
		this.onConnectionChange?.(state);
	}

	/** Release all held notes (e.g. on chord change) */
	releaseAll(): void {
		this._activeNotes.clear();
		this.onNoteChange?.(this._activeNotes);
	}
}
