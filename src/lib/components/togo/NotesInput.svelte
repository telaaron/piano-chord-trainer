<script lang="ts">
	// Tap the phrase back on a keyboard. Graded as a pitch-class SET, so order and
	// octave don't matter — only which notes were in the line.

	import { t } from '$lib/i18n';
	import PianoKeyboard from '$lib/components/PianoKeyboard.svelte';
	import { playNote } from '$lib/services/audio';

	interface Props {
		onanswer: (pitchClasses: number[]) => void;
		locked?: boolean;
	}

	let { onanswer, locked = false }: Props = $props();

	const CHROMATIC_NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

	let selected = $state(new Set<number>());

	/** Keyboard chromatic index → Tone.js note name (index 0 is C3). */
	function chrIdxToNoteName(chrIdx: number): string {
		return CHROMATIC_NOTE_NAMES[chrIdx % 12] + (3 + Math.floor(chrIdx / 12));
	}

	function toggle(chrIdx: number) {
		if (locked) return;
		playNote(chrIdxToNoteName(chrIdx), '4n');
		const pc = chrIdx % 12;
		const next = new Set(selected);
		if (next.has(pc)) next.delete(pc);
		else next.add(pc);
		selected = next;
	}

	function clear() {
		selected = new Set();
	}

	function submit() {
		onanswer([...selected]);
	}
</script>

<div class="flex flex-col gap-3">
	<p class="text-center text-[var(--text-sm)] text-[var(--text-muted)]">{t('togo.notes_hint')}</p>

	<PianoKeyboard
		chordData={null}
		showVoicing={false}
		interactive={!locked}
		onKeyClick={toggle}
		selectedPitchClasses={selected}
	/>

	<div class="flex gap-2">
		<button
			type="button"
			onclick={clear}
			disabled={locked || selected.size === 0}
			class="min-h-[var(--tap-min)] flex-1 rounded-[var(--radius)] border border-[var(--border)] bg-[var(--bg-card)] px-4 font-medium text-[var(--text-muted)] transition hover:text-[var(--text)] disabled:opacity-40"
		>
			{t('togo.notes_clear')}
		</button>
		<button
			type="button"
			onclick={submit}
			disabled={locked || selected.size === 0}
			class="min-h-[var(--tap-min)] flex-[2] rounded-[var(--radius)] bg-[var(--primary)] px-4 font-semibold text-white shadow-[var(--shadow-md)] transition hover:brightness-105 disabled:opacity-50"
		>
			{t('togo.notes_check')}
		</button>
	</div>
</div>
