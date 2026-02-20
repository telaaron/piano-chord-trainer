<script lang="ts">
	import {
		WHITE_KEY_COUNT,
		BLACK_KEYS,
		OCTAVE_CONFIGS,
		generateBlackKeys,
		whiteKeyChromaticIndex,
		getActiveKeyIndices,
		getKeyboardLayout,
		isRootIndex,
		noteToSemitone,
		type AccidentalPreference,
		type OctaveCount,
	} from '$lib/engine';
	import type { ChordWithNotes } from '$lib/engine';
	import type { VoiceLeadingInfo } from '$lib/engine';

	interface Props {
		chordData?: ChordWithNotes | null;
		accidentalPref?: AccidentalPreference;
		showVoicing?: boolean;
		/** Compact size for results list */
		mini?: boolean;
		/** MIDI: set of currently held MIDI note numbers (0–127) */
		midiActiveNotes?: ReadonlySet<number>;
		/** MIDI: set of expected pitch classes (0–11) for correct/wrong coloring */
		midiExpectedPitchClasses?: ReadonlySet<number>;
		/** MIDI: whether to show MIDI overlay colors */
		midiEnabled?: boolean;
		/** Voice leading info from previous chord */
		voiceLeading?: VoiceLeadingInfo | null;
		/** Whether to show voice leading indicators */
		showVoiceLeading?: boolean;
	}

	let {
		chordData = null,
		accidentalPref = 'sharps',
		showVoicing = true,
		mini = false,
		midiActiveNotes = new Set<number>(),
		midiExpectedPitchClasses = new Set<number>(),
		midiEnabled = false,
		voiceLeading = null,
		showVoiceLeading = false,
	}: Props = $props();

	/** Compute layout: which keys are active + how many octaves needed */
	const layout = $derived.by(() => {
		if (!chordData || !showVoicing) return { activeIndices: new Set<number>(), octaves: 2 as OctaveCount };
		if (mini) {
			// Mini keyboards always use 2 octaves (compact fallback)
			return { activeIndices: getActiveKeyIndices(chordData, accidentalPref), octaves: 2 as OctaveCount };
		}
		return getKeyboardLayout(chordData, accidentalPref);
	});

	const activeIndices = $derived(layout.activeIndices);
	const octaves = $derived(layout.octaves);
	const whiteKeyCount = $derived(OCTAVE_CONFIGS[octaves].whiteKeys);
	const chromaticCount = $derived(OCTAVE_CONFIGS[octaves].chromaticCount);
	const blackKeys = $derived(mini ? BLACK_KEYS : generateBlackKeys(octaves));

	/** Reduce MIDI note numbers to chromatic keyboard indices */
	const midiKeyIndices = $derived.by(() => {
		if (!midiEnabled || midiActiveNotes.size === 0) return new Set<number>();
		const set = new Set<number>();
		for (const mn of midiActiveNotes) {
			// Map MIDI note to our keyboard starting at C3 (MIDI 48)
			const offset = mn - 48;
			if (offset >= 0 && offset < chromaticCount) set.add(offset);
		}
		return set;
	});

	/** Pitch classes of currently held MIDI notes */
	const midiPitchClasses = $derived.by(() => {
		if (!midiEnabled) return new Set<number>();
		const set = new Set<number>();
		for (const mn of midiActiveNotes) set.add(mn % 12);
		return set;
	});

	function isActive(chrIdx: number): boolean {
		return activeIndices.has(chrIdx);
	}

	function isRoot(chrIdx: number): boolean {
		return !!chordData && isRootIndex(chrIdx, chordData.root, chordData.voicing);
	}

	/** Is this key currently held via MIDI? */
	function isMidiHeld(chrIdx: number): boolean {
		if (!midiEnabled) return false;
		return midiKeyIndices.has(chrIdx);
	}

	/** MIDI color: green = correct note, red = wrong note */
	function midiColor(chrIdx: number, isBlack: boolean): string | null {
		if (!midiEnabled || !isMidiHeld(chrIdx)) return null;
		const pc = chrIdx % 12;
		if (midiExpectedPitchClasses.has(pc)) {
			return isBlack ? 'bg-[var(--accent-green)] border-2 border-green-300/50' : 'bg-[var(--accent-green)]';
		}
		return isBlack ? 'bg-[var(--accent-red)] border-2 border-red-300/50' : 'bg-[var(--accent-red)]';
	}

	/** Voice leading: pitch classes of common tones (notes that stay) */
	const vlCommonPCs = $derived.by(() => {
		if (!showVoiceLeading || !voiceLeading) return new Set<number>();
		const set = new Set<number>();
		for (const note of voiceLeading.commonTones) {
			const st = noteToSemitone(note);
			if (st !== -1) set.add(st);
		}
		return set;
	});

	/** Voice leading: pitch classes of notes that moved away (old positions) */
	const vlDepartedPCs = $derived.by(() => {
		if (!showVoiceLeading || !voiceLeading) return new Set<number>();
		const set = new Set<number>();
		for (const m of voiceLeading.movements) {
			if (!m.stays && m.from) {
				const st = noteToSemitone(m.from);
				if (st !== -1) set.add(st);
			}
		}
		return set;
	});

	/** Voice leading: pitch classes of notes that arrived (new positions) */
	const vlArrivedPCs = $derived.by(() => {
		if (!showVoiceLeading || !voiceLeading) return new Set<number>();
		const set = new Set<number>();
		for (const m of voiceLeading.movements) {
			if (!m.stays && m.to) {
				const st = noteToSemitone(m.to);
				if (st !== -1) set.add(st);
			}
		}
		return set;
	});

	/** Get voice leading color class for a key */
	function vlColor(chrIdx: number, isBlack: boolean): string | null {
		if (!showVoiceLeading || !voiceLeading) return null;
		const pc = chrIdx % 12;
		if (vlCommonPCs.has(pc) && activeIndices.has(chrIdx)) {
			// Common tone — bold golden highlight (must be very visible)
			return isBlack
				? 'bg-amber-500 border-2 border-amber-300 shadow-[0_0_8px_rgba(245,158,11,0.6)]'
				: 'bg-amber-400 ring-2 ring-amber-500 ring-inset shadow-[0_0_10px_rgba(245,158,11,0.4)]';
		}
		if (vlArrivedPCs.has(pc) && activeIndices.has(chrIdx)) {
			// Arrived note (moved here) — subtle blue tint to distinguish from common tones
			return isBlack
				? 'bg-sky-600 border-2 border-sky-400'
				: 'bg-sky-300 ring-2 ring-sky-500 ring-inset';
		}
		return null;
	}
</script>

<div class="select-none {mini ? 'px-1' : 'px-1 sm:px-4'}">
	<!-- Aspect ratio wrapper -->
	<div class="relative w-full {mini ? 'pb-[22%]' : octaves === 3 ? 'pb-[18%] sm:pb-[15%]' : 'pb-[25%] sm:pb-[22%]'}">
		<div class="absolute inset-0">
			<!-- White keys -->
			<div class="flex h-full w-full shadow-md rounded-b-lg overflow-hidden">
					{#each Array(whiteKeyCount) as _, i}
					{@const chrIdx = whiteKeyChromaticIndex(i)}
					{@const active = isActive(chrIdx)}
					{@const root = active && isRoot(chrIdx)}
					{@const midi = midiColor(chrIdx, false)}
					{@const vl = vlColor(chrIdx, false)}
					<div
						class="flex-1 h-full border-r border-[var(--key-white-border)] last:border-r-0 relative transition-colors duration-100
						{midi
							? midi
							: vl
								? vl
								: active
									? root
										? 'bg-[var(--primary)]'
										: 'bg-[var(--primary)]/80'
									: 'bg-[var(--key-white)] hover:brightness-95'}"
					>
						{#if root}
							<div class="absolute bottom-2 inset-x-0 flex justify-center">
								<div class="{mini ? 'w-1.5 h-1.5' : 'w-2 h-2'} rounded-full bg-white"></div>
							</div>
						{/if}
					</div>
				{/each}
			</div>

			<!-- Black keys -->
			{#each blackKeys as key}
				{@const active = isActive(key.idx)}
				{@const root = active && isRoot(key.idx)}
				{@const midi = midiColor(key.idx, true)}
				{@const vl = vlColor(key.idx, true)}
				<div
					class="absolute top-0 h-[60%] {mini ? 'w-[5%]' : octaves === 3 ? 'w-[3%]' : 'w-[4.5%]'} -translate-x-1/2 rounded-b-md z-10 shadow-md transition-colors duration-100
					{midi
						? midi
						: vl
							? vl
							: active
								? root
									? 'bg-[var(--primary)] border-2 border-white/50'
									: 'bg-[var(--primary)]/80 border border-[var(--primary-hover)]'
								: 'bg-gradient-to-b from-[#333] to-[#111] border-x border-b border-black/40'}"
					style="left: {(key.pos * 100) / whiteKeyCount}%;"
				>
					{#if root}
						<div class="absolute bottom-1 inset-x-0 flex justify-center">
							<div class="{mini ? 'w-1 h-1' : 'w-1.5 h-1.5'} rounded-full bg-white"></div>
						</div>
					{/if}
				</div>
			{/each}
		</div>
	</div>
</div>
