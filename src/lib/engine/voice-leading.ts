// Voice Leading Engine — analyze note movements between consecutive chords
// Pure TypeScript, no DOM, no side effects.

import { noteToSemitone, NOTES_FLATS, NOTES_SHARPS, type AccidentalPreference } from './notes';

// ─── Types ──────────────────────────────────────────────────

/**
 * Voice Leading exercise mode:
 * - 'guided'         — Nachspielen: keyboard shows the optimal inversion, player copies it
 * - 'find-inversion' — Umkehrung finden: chord name + voicing type shown, player must find closest inversion via MIDI
 * - 'free'           — Frei: only chord name shown, any voicing type accepted, scored by movement distance
 */
export type VoiceLeadingMode = 'guided' | 'find-inversion' | 'free';

/**
 * Result of validating a player's MIDI input against the expected voice-led chord.
 */
export interface VLValidationResult {
	/** Was the attempt valid (correct pitch classes)? */
	valid: boolean;
	/** 'optimal' = tightest inversion, 'correct' = right notes/wrong inversion, 'wrong' = wrong notes */
	grade: 'optimal' | 'correct' | 'wrong';
	/** Total semitone movement from previous chord (lower = better) */
	playerMovement: number;
	/** The optimal (minimum) movement achievable */
	optimalMovement: number;
}

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
 * Place pitch classes in ascending order (same logic as keyboard.ts placeAscending).
 * Returns chromatic indices where each note is above the previous.
 */
function placeAscending(pitchClasses: number[]): number[] {
	const indices: number[] = [];
	let prevIdx = -1;
	for (const pc of pitchClasses) {
		let kbIdx = pc;
		if (prevIdx !== -1) {
			while (kbIdx <= prevIdx) kbIdx += 12;
		}
		indices.push(kbIdx);
		prevIdx = kbIdx;
	}
	return indices;
}

/**
 * Compute the signed distance between two chromatic indices (actual keyboard positions).
 * Preserves octave information — Bb3(10) → Bb4(22) = +12, not 0.
 */
function chromaticDist(fromIdx: number, toIdx: number): number {
	return toIdx - fromIdx;
}

// ─── Main API ───────────────────────────────────────────────

/**
 * Analyze voice leading from one set of notes to another.
 *
 * Both arrays should be note names (e.g. ["D","F","C"]).
 * The algorithm places both voicings on the keyboard (via placeAscending)
 * and compares actual chromatic positions — so a common tone is only
 * detected when it's at the same keyboard position (same octave),
 * not just the same pitch class in a different octave.
 */
export function analyzeVoiceLeading(fromNotes: string[], toNotes: string[]): VoiceLeadingInfo {
	if (fromNotes.length === 0 || toNotes.length === 0) {
		return { fromNotes, toNotes, movements: [], commonTones: [], totalMovement: 0 };
	}

	const fromPCs = fromNotes.map(noteToSemitone);
	const toPCs = toNotes.map(noteToSemitone);

	// Place on keyboard to get actual chromatic indices (octave-aware)
	const fromIndices = placeAscending(fromPCs.filter(pc => pc !== -1));
	const toIndices = placeAscending(toPCs.filter(pc => pc !== -1));

	const matchLen = Math.min(fromIndices.length, toIndices.length);

	// For voice-led voicings the notes are already in optimal order
	// (position i in from maps to position i in to), so we do a direct
	// positional comparison rather than permutation search.
	const movements: VoiceMovement[] = [];
	const commonTones: string[] = [];
	let totalMovement = 0;

	for (let i = 0; i < matchLen; i++) {
		const dist = chromaticDist(fromIndices[i], toIndices[i]);
		const stays = dist === 0; // Same chromatic index = same key on keyboard
		movements.push({
			from: fromNotes[i],
			to: toNotes[i],
			semitones: dist,
			stays,
		});
		if (stays) {
			commonTones.push(fromNotes[i]);
		}
		totalMovement += Math.abs(dist);
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
 * find the **rotation** (inversion) of the target notes that minimises
 * total voice movement on the actual keyboard.
 *
 * Key insight: `placeAscending()` maps a note-name array to keyboard
 * positions deterministically (the array order sets bottom-to-top).
 * Each rotation of the target array produces a different inversion with
 * different keyboard positions. We score every rotation against the
 * previous chord's keyboard positions and pick the tightest voice leading.
 *
 * Example — G7 shell [G,B,F] at keys [7,11,17] → Dm7 shell [D,F,C]:
 *   Rot 0 [D,F,C] → [2,5,12]  → score 16 (big jump down)
 *   Rot 1 [F,C,D] → [5,12,14] → score 6  ← best! F stays near G, C near B, D near F
 *   Rot 2 [C,D,F] → [0,2,5]   → score 28 (way too low)
 *
 * @param prevVoicing - note names of the previous chord's voicing
 * @param targetNotes - note names of the new chord in standard voicing order
 * @returns rotated target notes array for optimal voice leading
 */
export function computeVoiceLeadVoicing(
	prevVoicing: string[],
	targetNotes: string[],
	_pref: AccidentalPreference = 'both',
): string[] {
	if (prevVoicing.length === 0) return targetNotes;
	if (targetNotes.length === 0) return targetNotes;

	// Compute actual keyboard positions of previous voicing
	const prevPCs = prevVoicing.map(noteToSemitone).filter(pc => pc !== -1);
	if (prevPCs.length === 0) return targetNotes;
	const prevPositions = placeAscending(prevPCs);

	// Filter valid target notes
	const validTargets = targetNotes.filter(n => noteToSemitone(n) !== -1);
	const n = validTargets.length;
	if (n === 0) return targetNotes;

	let bestRotation = validTargets;
	let bestScore = Infinity;

	// Try all rotations (inversions) of the target voicing
	for (let r = 0; r < n; r++) {
		const rotated = [...validTargets.slice(r), ...validTargets.slice(0, r)];
		const rotatedPCs = rotated.map(noteToSemitone);
		const positions = placeAscending(rotatedPCs);

		// Score: positional voice matching (voice 1→1, 2→2, etc.)
		// This gives proper voice-leading where common tones stay on the same key
		const matchLen = Math.min(prevPositions.length, positions.length);
		let score = 0;
		for (let i = 0; i < matchLen; i++) {
			score += Math.abs(positions[i] - prevPositions[i]);
		}

		// Extra voices in target: penalise distance from previous chord's range centre
		if (positions.length > matchLen) {
			const prevCenter = (prevPositions[0] + prevPositions[prevPositions.length - 1]) / 2;
			for (let i = matchLen; i < positions.length; i++) {
				score += Math.abs(positions[i] - prevCenter);
			}
		}

		if (score < bestScore) {
			bestScore = score;
			bestRotation = rotated;
		}
	}

	return bestRotation;
}

// ─── VL Mode Helpers ────────────────────────────────────────

/**
 * Generate all rotations (inversions) of a note array.
 * E.g. [D,F,C] → [[D,F,C], [F,C,D], [C,D,F]]
 */
export function getAllRotations(notes: string[]): string[][] {
	const n = notes.length;
	if (n === 0) return [notes];
	const rotations: string[][] = [];
	for (let r = 0; r < n; r++) {
		rotations.push([...notes.slice(r), ...notes.slice(0, r)]);
	}
	return rotations;
}

/**
 * Compute the total voice-leading movement from a previous voicing to
 * a set of played MIDI notes (sorted ascending by pitch).
 *
 * @param prevVoicing  - note names of the previous chord's voicing
 * @param playedMidi   - MIDI note numbers the player pressed (sorted ascending)
 * @returns total semitone movement (sum of absolute differences, position-matched)
 */
export function scorePlayerMovement(
	prevVoicing: string[],
	playedMidi: number[],
): number {
	if (prevVoicing.length === 0 || playedMidi.length === 0) return 0;

	const prevPCs = prevVoicing.map(noteToSemitone).filter(pc => pc !== -1);
	const prevPositions = placeAscending(prevPCs);

	// playedMidi is already absolute MIDI notes — normalise to keyboard-relative
	// The keyboard starts at C3 (MIDI 48) but we just need relative distances,
	// so use the raw MIDI values directly for movement scoring.
	const sorted = [...playedMidi].sort((a, b) => a - b);
	const matchLen = Math.min(prevPositions.length, sorted.length);

	// Offset: align the prevPositions range to MIDI space
	// prevPositions are 0-based chromatic indices from C3 (MIDI 48)
	const midiBase = 48;
	let total = 0;
	for (let i = 0; i < matchLen; i++) {
		total += Math.abs(sorted[i] - (prevPositions[i] + midiBase));
	}
	return total;
}

/**
 * Validate a player's MIDI input for "Find the Inversion" mode (Mode B).
 *
 * Checks whether the played pitch classes match the voicing's pitch classes,
 * then grades as optimal/correct/wrong based on movement distance.
 *
 * @param playedMidi      - MIDI note numbers currently pressed
 * @param voicingNotes    - the base voicing notes (e.g. shell of Dm7 = [D,F,C])
 * @param prevVoicing     - note names of the previous chord's voicing
 * @param optimalVoicing  - the optimal rotation computed by computeVoiceLeadVoicing
 * @returns VLValidationResult
 */
export function validateFindInversion(
	playedMidi: number[],
	voicingNotes: string[],
	prevVoicing: string[],
	optimalVoicing: string[],
): VLValidationResult {
	if (playedMidi.length === 0) {
		return { valid: false, grade: 'wrong', playerMovement: 0, optimalMovement: 0 };
	}

	// Expected pitch classes (same for all rotations of a voicing)
	const expectedPCs = new Set(voicingNotes.map(noteToSemitone).filter(pc => pc !== -1));
	// Played pitch classes
	const playedPCs = new Set(playedMidi.map(m => m % 12));

	// Check: do played PCs match expected PCs?
	if (playedPCs.size !== expectedPCs.size) {
		return { valid: false, grade: 'wrong', playerMovement: 0, optimalMovement: 0 };
	}
	for (const pc of expectedPCs) {
		if (!playedPCs.has(pc)) {
			return { valid: false, grade: 'wrong', playerMovement: 0, optimalMovement: 0 };
		}
	}

	// Pitch classes match — compute movement scores
	const playerMovement = scorePlayerMovement(prevVoicing, playedMidi);
	const optimalMovement = scorePlayerMovement(prevVoicing, optimalToMidi(optimalVoicing));

	// Grade: if within 2 semitones of optimal → 'optimal', else 'correct'
	const grade = playerMovement <= optimalMovement + 2 ? 'optimal' : 'correct';

	return { valid: true, grade, playerMovement, optimalMovement };
}

/**
 * Validate a player's MIDI input for "Free" mode (Mode C).
 *
 * Accepts any pitch-class set that matches a valid voicing of the chord.
 * Scores purely by movement distance from the previous chord.
 *
 * @param playedMidi      - MIDI note numbers currently pressed
 * @param validPCSets     - array of valid pitch-class sets (one per voicing type)
 * @param prevVoicing     - note names of the previous chord's voicing
 * @returns VLValidationResult (grade is always 'optimal' or 'wrong' — no penalty for voicing choice)
 */
export function validateFreeVoicing(
	playedMidi: number[],
	validPCSets: Set<number>[],
	prevVoicing: string[],
): VLValidationResult {
	if (playedMidi.length === 0) {
		return { valid: false, grade: 'wrong', playerMovement: 0, optimalMovement: 0 };
	}

	const playedPCs = new Set(playedMidi.map(m => m % 12));

	// Check against each valid PC set
	const matchesAny = validPCSets.some(expected => {
		if (playedPCs.size !== expected.size) return false;
		for (const pc of expected) {
			if (!playedPCs.has(pc)) return false;
		}
		return true;
	});

	if (!matchesAny) {
		return { valid: false, grade: 'wrong', playerMovement: 0, optimalMovement: 0 };
	}

	const playerMovement = scorePlayerMovement(prevVoicing, playedMidi);

	return { valid: true, grade: 'optimal', playerMovement, optimalMovement: 0 };
}

/**
 * Convert a voicing (note names) to approximate MIDI note numbers
 * using placeAscending + a MIDI base of C3 = 48.
 */
function optimalToMidi(voicing: string[]): number[] {
	const pcs = voicing.map(noteToSemitone).filter(pc => pc !== -1);
	const positions = placeAscending(pcs);
	return positions.map(p => p + 48); // C3 base
}
