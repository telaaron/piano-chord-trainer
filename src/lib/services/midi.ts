// Web MIDI API service – connects to MIDI keyboards, tracks active notes, validates chords

import { noteToSemitone } from '$lib/engine';

export type MidiConnectionState = 'disconnected' | 'connecting' | 'connected' | 'unsupported' | 'denied';

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
type DisconnectToastCallback = (deviceName: string) => void;

export class MidiService {
	private access: MIDIAccess | null = null;
	/** Currently held MIDI note numbers (0–127) */
	private _activeNotes = new Set<number>();
	private _state: MidiConnectionState = 'disconnected';
	private _devices: MidiDevice[] = [];
	private _selectedDeviceId: string | null = null;

	// Debounce note-off events to avoid accidental double-triggers
	private _debounceMs = 30;
	private _noteTimers = new Map<number, ReturnType<typeof setTimeout>>();

	// Callbacks
	private onNoteChange: NoteCallback | null = null;
	private onConnectionChange: ConnectionCallback | null = null;
	private onDeviceListChange: DeviceListCallback | null = null;
	private onDisconnectToast: DisconnectToastCallback | null = null;

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

	/** Called when a connected device disconnects mid-session */
	onDisconnect(cb: DisconnectToastCallback): void {
		this.onDisconnectToast = cb;
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
				this.access.onstatechange = (e) => this.handleStateChange(e as MIDIConnectionEvent);
			// Auto-select first device if available
			if (this._devices.length > 0 && !this._selectedDeviceId) {
				this.selectDevice(this._devices[0].id);
			} else {
				this.setState('connected');
			}

			return true;
		} catch (err) {
			// DOMException with name 'SecurityError' means the user denied the permission prompt
			if (err instanceof DOMException && err.name === 'SecurityError') {
				this.setState('denied');
			} else {
				console.warn('MIDI access error:', err);
				this.setState('disconnected');
			}
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
		this._noteTimers.forEach((t) => clearTimeout(t));
		this._noteTimers.clear();
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

	/**
	 * Inversion-aware match: like lenient, but also checks that the lowest
	 * played MIDI note matches the expected bass pitch class.
	 * `expectedBassNote` is the note name that should be on the bottom (e.g. "E" for 1st inversion of C).
	 */
	checkChordWithBass(expectedNotes: string[], expectedBassNote: string): ChordMatchResult {
		const result = this.checkChordLenient(expectedNotes);

		if (!result.correct || this._activeNotes.size === 0) return result;

		// Find the lowest MIDI note currently held
		let lowestMidi = Infinity;
		for (const mn of this._activeNotes) {
			if (mn < lowestMidi) lowestMidi = mn;
		}

		const lowestPitchClass = lowestMidi % 12;
		const expectedBassPc = noteToSemitone(expectedBassNote);

		if (expectedBassPc === -1 || lowestPitchClass === expectedBassPc) {
			return result; // Bass matches
		}

		// Correct pitch classes but wrong bass note
		return {
			...result,
			correct: false,
		};
	}

	// ─── Private ────────────────────────────────────────────────

	private handleMessage(event: MIDIMessageEvent): void {
		const data = event.data;
		if (!data || data.length < 2) return;

		const status = data[0] & 0xf0;
		const note = data[1];
		const velocity = data.length > 2 ? data[2] : 0;

		if (status === 0x90 && velocity > 0) {
			// Note On — cancel any pending note-off debounce for this pitch
			const existing = this._noteTimers.get(note);
			if (existing) {
				clearTimeout(existing);
				this._noteTimers.delete(note);
			}
			this._activeNotes.add(note);
			this.onNoteChange?.(this._activeNotes);
		} else if (status === 0x80 || (status === 0x90 && velocity === 0)) {
			// Note Off — debounce to avoid rapid re-trigger artifacts
			const existing = this._noteTimers.get(note);
			if (existing) clearTimeout(existing);

			const timer = setTimeout(() => {
				this._activeNotes.delete(note);
				this._noteTimers.delete(note);
				this.onNoteChange?.(this._activeNotes);
			}, this._debounceMs);

			this._noteTimers.set(note, timer);
		}
	}

	private handleStateChange(event: MIDIConnectionEvent): void {
		const port = event.port;

		if (port?.type === 'input' && port.state === 'disconnected') {
			const disconnectedDevice = this._devices.find((d) => d.id === port.id);
			const deviceName = disconnectedDevice?.name ?? 'MIDI device';

			if (this._selectedDeviceId === port.id) {
				this.onDisconnectToast?.(deviceName);
				this._selectedDeviceId = null;
			}
		}

		this.refreshDeviceList();
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
		this._noteTimers.forEach((t) => clearTimeout(t));
		this._noteTimers.clear();
		this._activeNotes.clear();
		this.onNoteChange?.(this._activeNotes);
	}
}
