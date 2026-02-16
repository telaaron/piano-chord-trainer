<script lang="ts">
	import {
		WHITE_KEY_COUNT,
		BLACK_KEYS,
		whiteKeyChromaticIndex,
		getActiveKeyIndices,
		isRootIndex,
		noteToSemitone,
		type AccidentalPreference,
	} from '$lib/engine';
	import type { ChordWithNotes } from '$lib/engine';

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
	}

	let {
		chordData = null,
		accidentalPref = 'sharps',
		showVoicing = true,
		mini = false,
		midiActiveNotes = new Set<number>(),
		midiExpectedPitchClasses = new Set<number>(),
		midiEnabled = false,
	}: Props = $props();

	const activeIndices = $derived(
		chordData && showVoicing ? getActiveKeyIndices(chordData, accidentalPref) : new Set<number>(),
	);

	/** Reduce MIDI note numbers to chromatic keyboard indices (0–23) */
	const midiKeyIndices = $derived.by(() => {
		if (!midiEnabled || midiActiveNotes.size === 0) return new Set<number>();
		const set = new Set<number>();
		for (const mn of midiActiveNotes) {
			// Map MIDI note to our 2-octave keyboard starting at C3 (MIDI 48)
			// We show octave 3 and 4: MIDI 48–71
			const offset = mn - 48;
			if (offset >= 0 && offset < 24) set.add(offset);
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
		return !!chordData && isRootIndex(chrIdx, chordData.root);
	}

	/** Is this key currently held via MIDI? Uses exact position, not pitch class */
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
</script>

<div class="select-none {mini ? 'px-1' : 'px-1 sm:px-4'}">
	<!-- Aspect ratio wrapper -->
	<div class="relative w-full {mini ? 'pb-[22%]' : 'pb-[25%] sm:pb-[22%]'}">
		<div class="absolute inset-0">
			<!-- White keys -->
			<div class="flex h-full w-full shadow-md rounded-b-lg overflow-hidden">
					{#each Array(WHITE_KEY_COUNT) as _, i}
					{@const chrIdx = whiteKeyChromaticIndex(i)}
					{@const active = isActive(chrIdx)}
					{@const root = active && isRoot(chrIdx)}
					{@const midi = midiColor(chrIdx, false)}
					<div
						class="flex-1 h-full border-r border-[var(--key-white-border)] last:border-r-0 relative transition-colors duration-100
						{midi
							? midi
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
			{#each BLACK_KEYS as key}
				{@const active = isActive(key.idx)}
				{@const root = active && isRoot(key.idx)}
				{@const midi = midiColor(key.idx, true)}
				<div
					class="absolute top-0 h-[60%] {mini ? 'w-[5%]' : 'w-[4.5%]'} -translate-x-1/2 rounded-b-md z-10 shadow-md transition-colors duration-100
					{midi
						? midi
						: active
							? root
								? 'bg-[var(--primary)] border-2 border-white/50'
								: 'bg-[var(--accent-purple)] border border-purple-700'
							: 'bg-gradient-to-b from-[#333] to-[#111] border-x border-b border-black/40'}"
					style="left: {(key.pos * 100) / WHITE_KEY_COUNT}%;"
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
