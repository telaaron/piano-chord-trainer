// Web MIDI API service – connects to MIDI keyboards, tracks active notes, validates chords

import { noteToSemitone } from '$lib/engine';

/**
 * Detect iOS / iPadOS — all browsers on iOS use WebKit (no Web MIDI API).
 * iPadOS 13+ masquerades as Mac but has touch support.
 */
export function isIOSorIPadOS(): boolean {
	if (typeof navigator === 'undefined') return false;
	const ua = navigator.userAgent;
	if (/iPhone|iPod|iPad/.test(ua)) return true;
	// iPadOS 13+ reports as "Macintosh" but has multi-touch
	if (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1) return true;
	return false;
}

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
type NoteOnCallback = (note: number, velocity: number) => void;
type NoteOffCallback = (note: number) => void;
type CCCallback = (cc: number, value: number) => void;
type ConnectionCallback = (state: MidiConnectionState) => void;
type DeviceListCallback = (devices: MidiDevice[]) => void;
type DisconnectToastCallback = (deviceName: string) => void;

const MIDI_DEVICE_KEY = 'midi-selected-device';
const MIDI_HIDDEN_KEY = 'midi-hidden-devices';

/** Known virtual / system MIDI port name patterns to auto-hide. */
const VIRTUAL_PORT_PATTERNS = [
	/^session \d+$/i,           // macOS IAC Driver default ports
	/^iac driver/i,             // macOS IAC Driver
	/^midi through port/i,      // Linux ALSA virtual port
	/^microsoft gs wavetable/i, // Windows built-in synth
];

export class MidiService {
	private access: MIDIAccess | null = null;
	/** Currently held MIDI note numbers (0–127) */
	private _activeNotes = new Set<number>();
	private _state: MidiConnectionState = 'disconnected';
	private _devices: MidiDevice[] = [];
	private _selectedDeviceId: string | null = null;
	private _hiddenDeviceIds = new Set<string>();

	// Debounce note-off events to avoid accidental double-triggers
	private _debounceMs = 30;
	private _noteTimers = new Map<number, ReturnType<typeof setTimeout>>();

	// Guard against concurrent init() calls
	private _initPromise: Promise<boolean> | null = null;
	private _destroyed = false;

	// Callbacks
	private onNoteChange: NoteCallback | null = null;
	private onNoteOnChange: NoteOnCallback | null = null;
	private onNoteOffChange: NoteOffCallback | null = null;
	private onCCChange: CCCallback | null = null;
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

	get hiddenDeviceIds(): ReadonlySet<string> {
		return this._hiddenDeviceIds;
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

	/** Called on each individual Note-On event (for live sound playback) */
	onNoteOn(cb: NoteOnCallback): void {
		this.onNoteOnChange = cb;
	}

	/** Called on each individual Note-Off event (for live sound playback) */
	onNoteOff(cb: NoteOffCallback): void {
		this.onNoteOffChange = cb;
	}

	/** Called on MIDI CC messages (e.g. sustain pedal CC 64) */
	onCC(cb: CCCallback): void {
		this.onCCChange = cb;
	}

	/** Called when a connected device disconnects mid-session */
	onDisconnect(cb: DisconnectToastCallback): void {
		this.onDisconnectToast = cb;
	}

	// ─── Lifecycle ──────────────────────────────────────────────

	/** Request MIDI access. Returns true if API is available.
	 *  Safe to call multiple times — concurrent calls share the same promise,
	 *  and re-calling after a successful init reuses the existing MIDIAccess. */
	async init(): Promise<boolean> {
		if (typeof navigator === 'undefined' || !navigator.requestMIDIAccess) {
			this.setState('unsupported');
			return false;
		}

		// Reuse existing access if still valid (e.g. called from setupGame after onMount already inited)
		if (this.access && !this._destroyed) {
			this.refreshDeviceList();
			if (this._devices.length > 0 && !this._selectedDeviceId) {
				this.selectDevice(this._devices[0].id);
			}
			return true;
		}

		// Deduplicate concurrent init() calls
		if (this._initPromise) return this._initPromise;

		this._initPromise = this._doInit();
		try {
			return await this._initPromise;
		} finally {
			this._initPromise = null;
		}
	}

	private async _doInit(): Promise<boolean> {
		this._destroyed = false;
		this.setState('connecting');

		// Restore hidden device list
		try {
			const raw = localStorage.getItem(MIDI_HIDDEN_KEY);
			if (raw) this._hiddenDeviceIds = new Set(JSON.parse(raw));
		} catch { /* noop */ }

		// Restore last selected device
		try {
			const saved = localStorage.getItem(MIDI_DEVICE_KEY);
			if (saved) this._selectedDeviceId = saved;
		} catch { /* noop */ }

		try {
			this.access = await navigator.requestMIDIAccess({ sysex: false });

			// Guard: init may have been called and then destroy() fired while awaiting
			if (this._destroyed) {
				this.access = null;
				return false;
			}

			this.access.onstatechange = (e) => this.handleStateChange(e as MIDIConnectionEvent);
			this.refreshDeviceList();

			// Restore saved device or auto-select first available
			if (this._selectedDeviceId && this._devices.find((d) => d.id === this._selectedDeviceId)) {
				this.selectDevice(this._selectedDeviceId);
			} else if (this._devices.length > 0) {
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

		// Persist selection
		try { localStorage.setItem(MIDI_DEVICE_KEY, deviceId); } catch { /* noop */ }

		if (!this.access) return;

		const input = this.access.inputs.get(deviceId);
		if (input) {
			input.onmidimessage = (e) => this.handleMessage(e);
			this.setState('connected');
		}
	}

	/** Hide a device (remove from visible list). Persisted in localStorage. */
	hideDevice(deviceId: string): void {
		this._hiddenDeviceIds.add(deviceId);
		try {
			localStorage.setItem(MIDI_HIDDEN_KEY, JSON.stringify([...this._hiddenDeviceIds]));
		} catch { /* noop */ }

		// If the hidden device was selected, clear selection
		if (this._selectedDeviceId === deviceId) {
			this.detachListeners();
			this._selectedDeviceId = null;
			try { localStorage.removeItem(MIDI_DEVICE_KEY); } catch { /* noop */ }
		}

		// Refresh so callbacks see the new filtered list
		this.refreshDeviceList();
	}

	/** Unhide a device */
	unhideDevice(deviceId: string): void {
		this._hiddenDeviceIds.delete(deviceId);
		try {
			localStorage.setItem(MIDI_HIDDEN_KEY, JSON.stringify([...this._hiddenDeviceIds]));
		} catch { /* noop */ }
		this.refreshDeviceList();
	}

	/** Unhide all devices */
	unhideAll(): void {
		this._hiddenDeviceIds.clear();
		try { localStorage.removeItem(MIDI_HIDDEN_KEY); } catch { /* noop */ }
		this.refreshDeviceList();
	}

	/** Clean up everything */
	destroy(): void {
		this._destroyed = true;
		this.detachListeners();
		this._activeNotes.clear();
		this._noteTimers.forEach((t) => clearTimeout(t));
		this._noteTimers.clear();
		this.access = null;
		this._initPromise = null;
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
		const result = this.checkChord(expectedNotes);

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
			this.onNoteOnChange?.(note, velocity);
			this.onNoteChange?.(this._activeNotes);
		} else if (status === 0x80 || (status === 0x90 && velocity === 0)) {
			// Note Off — fire immediately for sound engine (no debounce needed for release)
			this.onNoteOffChange?.(note);

			// Debounce for activeNotes set (chord validation) to avoid rapid re-trigger artifacts
			const existing = this._noteTimers.get(note);
			if (existing) clearTimeout(existing);

			const timer = setTimeout(() => {
				this._activeNotes.delete(note);
				this._noteTimers.delete(note);
				this.onNoteChange?.(this._activeNotes);
			}, this._debounceMs);

			this._noteTimers.set(note, timer);
		} else if (status === 0xB0) {
			// Control Change (CC) — e.g. sustain pedal (CC 64)
			this.onCCChange?.(note, velocity);  // note = CC number, velocity = value
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
			// Skip hidden devices
			if (this._hiddenDeviceIds.has(input.id)) return;
			// Skip known virtual / system ports
			const name = input.name || '';
			if (VIRTUAL_PORT_PATTERNS.some((p) => p.test(name))) return;
			newDevices.push({
				id: input.id,
				name: name || `MIDI Input ${input.id}`,
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
