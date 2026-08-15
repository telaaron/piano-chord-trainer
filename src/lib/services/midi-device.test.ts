import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { MidiService } from './midi';

/**
 * Device selection must never leave the app listening to a port that sends
 * nothing. With two keyboards plugged in, restoring a saved id that belonged to
 * the other one did exactly that: keys pressed, no chord registered, and no hint
 * as to why — the selection looked valid because it had been recorded anyway.
 */

const g = globalThis as Record<string, unknown>;

/** A MIDIInput stub: only what selectDevice touches. */
function port(id: string, name: string) {
	return { id, name, onmidimessage: null as unknown };
}

/** Minimal MIDIAccess whose `inputs` is a Map, as the real API provides. */
function access(ports: ReturnType<typeof port>[]) {
	return {
		inputs: new Map(ports.map((p) => [p.id, p])),
		onstatechange: null as unknown,
	};
}

function makeStorage(): Storage {
	const map = new Map<string, string>();
	return {
		get length() {
			return map.size;
		},
		key: (i: number) => [...map.keys()][i] ?? null,
		getItem: (k: string) => map.get(k) ?? null,
		setItem: (k: string, v: string) => void map.set(k, v),
		removeItem: (k: string) => void map.delete(k),
		clear: () => map.clear(),
	} as Storage;
}

describe('MIDI device selection', () => {
	beforeEach(() => {
		g.localStorage = makeStorage();
	});
	afterEach(() => {
		delete g.localStorage;
		delete g.navigator;
	});

	it('reports failure instead of silently selecting a port that is not there', () => {
		const svc = new MidiService();
		// Two devices present; ask for a third that is not.
		(svc as unknown as { access: unknown }).access = access([
			port('a', 'Keyboard A'),
			port('b', 'Keyboard B'),
		]);

		expect(svc.selectDevice('gone')).toBe(false);
		// And it must not have recorded the dead selection.
		expect(svc.selectedDeviceId).not.toBe('gone');
	});

	it('does not persist a selection that could not be attached', () => {
		const svc = new MidiService();
		(svc as unknown as { access: unknown }).access = access([port('a', 'Keyboard A')]);

		svc.selectDevice('gone');
		// A persisted bad id would survive every reload and re-break the app.
		expect(localStorage.getItem('midi-selected-device')).not.toBe('gone');
	});

	it('attaches a real device and reports success', () => {
		const svc = new MidiService();
		const a = port('a', 'Keyboard A');
		(svc as unknown as { access: unknown }).access = access([a]);

		expect(svc.selectDevice('a')).toBe(true);
		expect(svc.selectedDeviceId).toBe('a');
		expect(typeof a.onmidimessage).toBe('function');
		expect(localStorage.getItem('midi-selected-device')).toBe('a');
	});

	it('switching devices detaches the previous port', () => {
		const svc = new MidiService();
		const a = port('a', 'Keyboard A');
		const b = port('b', 'Keyboard B');
		(svc as unknown as { access: unknown }).access = access([a, b]);

		svc.selectDevice('a');
		expect(typeof a.onmidimessage).toBe('function');

		svc.selectDevice('b');
		expect(a.onmidimessage).toBeNull();
		expect(typeof b.onmidimessage).toBe('function');
	});
});
