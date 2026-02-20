// Voice Leading Engine — analyze note movements between consecutive chords
// Pure TypeScript, no DOM, no side effects.

import { noteToSemitone, NOTES_FLATS, NOTES_SHARPS, type AccidentalPreference } from './notes';

// ─── Types ──────────────────────────────────────────────────

export interface VoiceMovement {
	/** Source note name, e.g. "E" */
	from: string;
	/** Target note name, e.g. "Eb" */
	to: string;
	/** Signed semitone movement (negative = down, positive = up) */
	semitones: number;
	/** True if the note stays (semitones === 0) */
	stays: boolean;
}

export interface VoiceLeadingInfo {
	/** Notes of the source chord */
	fromNotes: string[];
	/** Notes of the target chord */
	toNotes: string[];
	/** Per-voice movement assignments */
	movements: VoiceMovement[];
	/** Notes that stay in place (common tones) */
	commonTones: string[];
	/** Sum of absolute semitone movements — lower = smoother voice leading */
	totalMovement: number;
}

// ─── Helpers ────────────────────────────────────────────────

/**
 * Compute the shortest signed distance between two pitch classes (0–11).
 * Range: -6 … +6  (prefers the shorter path)
 */
function signedSemitoneDist(fromPC: number, toPC: number): number {
	let diff = ((toPC - fromPC) % 12 + 12) % 12; // 0..11
	if (diff > 6) diff -= 12; // fold to -5..6
	return diff;
}

/**
 * Solve the optimal assignment of `from` voices → `to` voices
 * minimising total absolute semitone movement.
 *
 * For small voice counts (≤ 6) we brute-force all permutations.
 * Jazz voicings rarely exceed 4-5 notes, so this is fine.
 */
function optimalAssignment(fromPCs: number[], toPCs: number[]): number[] {
	const n = Math.min(fromPCs.length, toPCs.length);
	// If arrays differ in size, pad the shorter with -1 (unmatched)
	const fromArr = fromPCs.slice(0, n);
	const toArr = toPCs.slice(0, n);

	let bestPerm: number[] = [];
	let bestCost = Infinity;

	// Generate all permutations of indices 0..n-1
	const indices = Array.from({ length: n }, (_, i) => i);

	function permute(arr: number[], start: number) {
		if (start === arr.length) {
			let cost = 0;
			for (let i = 0; i < arr.length; i++) {
				cost += Math.abs(signedSemitoneDist(fromArr[i], toArr[arr[i]]));
			}
			if (cost < bestCost) {
				bestCost = cost;
				bestPerm = [...arr];
			}
			return;
		}
		for (let i = start; i < arr.length; i++) {
			[arr[start], arr[i]] = [arr[i], arr[start]];
			permute(arr, start + 1);
			[arr[start], arr[i]] = [arr[i], arr[start]];
		}
	}

	permute(indices, 0);
	return bestPerm;
}

// ─── Main API ───────────────────────────────────────────────

/**
 * Analyze voice leading from one set of notes to another.
 *
 * Both arrays should be note names (e.g. ["D","F","C"]).
 * The algorithm finds the assignment that minimizes total movement
 * and reports common tones, per-voice movements, and total cost.
 */
export function analyzeVoiceLeading(fromNotes: string[], toNotes: string[]): VoiceLeadingInfo {
	if (fromNotes.length === 0 || toNotes.length === 0) {
		return { fromNotes, toNotes, movements: [], commonTones: [], totalMovement: 0 };
	}

	const fromPCs = fromNotes.map(noteToSemitone);
	const toPCs = toNotes.map(noteToSemitone);

	// Match size: if unequal, match the smaller count
	const matchLen = Math.min(fromPCs.length, toPCs.length);
	const fromSlice = fromPCs.slice(0, matchLen);
	const toSlice = toPCs.slice(0, matchLen);
	const fromSliceNames = fromNotes.slice(0, matchLen);
	const toSliceNames = toNotes.slice(0, matchLen);

	const perm = optimalAssignment(fromSlice, toSlice);

	const movements: VoiceMovement[] = [];
	const commonTones: string[] = [];
	let totalMovement = 0;

	for (let i = 0; i < matchLen; i++) {
		const toIdx = perm[i];
		const semitones = signedSemitoneDist(fromSlice[i], toSlice[toIdx]);
		const stays = semitones === 0;
		movements.push({
			from: fromSliceNames[i],
			to: toSliceNames[toIdx],
			semitones,
			stays,
		});
		if (stays) {
			commonTones.push(fromSliceNames[i]);
		}
		totalMovement += Math.abs(semitones);
	}

	// Handle extra notes in the longer array (new/dropped voices)
	if (toNotes.length > matchLen) {
		for (let i = matchLen; i < toNotes.length; i++) {
			movements.push({ from: '', to: toNotes[i], semitones: 0, stays: false });
		}
	}
	if (fromNotes.length > matchLen) {
		for (let i = matchLen; i < fromNotes.length; i++) {
			movements.push({ from: fromNotes[i], to: '', semitones: 0, stays: false });
		}
	}

	return { fromNotes, toNotes, movements, commonTones, totalMovement };
}

/**
 * Format voice leading info as a human-readable string.
 * E.g. "F stays, C → B (↓1)"
 */
export function formatVoiceLeading(info: VoiceLeadingInfo): string {
	if (info.movements.length === 0) return '';

	const parts: string[] = [];
	for (const m of info.movements) {
		if (!m.from || !m.to) continue; // dropped/added voices
		if (m.stays) {
			parts.push(`${m.from} stays`);
		} else {
			const arrow = m.semitones < 0 ? '↓' : '↑';
			parts.push(`${m.from} → ${m.to} (${arrow}${Math.abs(m.semitones)})`);
		}
	}
	return parts.join(', ');
}

// ─── Voice-Led Voicing Computation ──────────────────────────

/**
 * Given a previous voicing (note names) and the target chord's note names,
 * compute the optimal rearrangement of the target notes that minimises
 * total voice movement.
 *
 * Jazz voice leading principle: each voice in the previous chord moves
 * to the nearest available note in the new chord. Common tones stay,
 * other voices move by the smallest possible interval.
 *
 * This function works with pitch classes (not absolute MIDI notes)
 * because the PianoKeyboard component maps notes to pitch classes anyway.
 * The returned array has the same length as the previous voicing
 * (excess target notes are appended).
 *
 * @param prevVoicing - note names of the previous chord's voicing (e.g. ["C","E","B"])
 * @param targetNotes - note names of the new chord's voicing in standard order (e.g. ["D","F#","C"])
 * @param pref - accidental preference for note naming
 * @returns rearranged target notes with optimal voice assignments
 */
export function computeVoiceLeadVoicing(
	prevVoicing: string[],
	targetNotes: string[],
	_pref: AccidentalPreference = 'both',
): string[] {
	if (prevVoicing.length === 0) return targetNotes;
	if (targetNotes.length === 0) return targetNotes;

	const prevPCs = prevVoicing.map(noteToSemitone).filter(pc => pc !== -1);
	const targetPCs = targetNotes.map(noteToSemitone).filter(pc => pc !== -1);

	if (prevPCs.length === 0 || targetPCs.length === 0) return targetNotes;

	const n = Math.min(prevPCs.length, targetPCs.length);
	const prevSlice = prevPCs.slice(0, n);
	const targetSlice = targetPCs.slice(0, n);
	const targetNameSlice = targetNotes.slice(0, n);

	// Find the permutation of targetSlice that minimises total movement
	const perm = optimalAssignment(prevSlice, targetSlice);

	// Build the rearranged voicing: each voice in prevVoicing maps to the
	// best-matching target note.
	const result: string[] = new Array(n);
	for (let i = 0; i < n; i++) {
		result[i] = targetNameSlice[perm[i]];
	}

	// Append any leftover target notes (if target has more notes)
	for (let i = n; i < targetNotes.length; i++) {
		result.push(targetNotes[i]);
	}

	return result;
}
