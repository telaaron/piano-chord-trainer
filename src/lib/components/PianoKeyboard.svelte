<script lang="ts">
	import {
		WHITE_KEY_COUNT,
		BLACK_KEYS,
		whiteKeyChromaticIndex,
		getActiveKeyIndices,
		isRootIndex,
		type AccidentalPreference,
	} from '$lib/engine';
	import type { ChordWithNotes } from '$lib/engine';

	interface Props {
		chordData?: ChordWithNotes | null;
		accidentalPref?: AccidentalPreference;
		showVoicing?: boolean;
		/** Compact size for results list */
		mini?: boolean;
	}

	let {
		chordData = null,
		accidentalPref = 'sharps',
		showVoicing = true,
		mini = false,
	}: Props = $props();

	const activeIndices = $derived(
		chordData && showVoicing ? getActiveKeyIndices(chordData, accidentalPref) : new Set<number>(),
	);

	function isActive(chrIdx: number): boolean {
		return activeIndices.has(chrIdx);
	}

	function isRoot(chrIdx: number): boolean {
		return !!chordData && isRootIndex(chrIdx, chordData.root);
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
					<div
						class="flex-1 h-full border-r border-[var(--key-white-border)] last:border-r-0 relative transition-colors duration-100
						{active
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
				<div
					class="absolute top-0 h-[60%] {mini ? 'w-[5%]' : 'w-[4.5%]'} -translate-x-1/2 rounded-b-md z-10 shadow-md transition-colors duration-100
					{active
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
