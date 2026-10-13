<!--
  The JazzChords mark: four tilted piano keys, the same drawing as the
  app icon (static/brand/app-icon.svg) without its tile. The keys take
  currentColor; the black keys are cut out with a mask (in the group's
  rotated space) so whatever sits behind the mark shows through.
-->
<script lang="ts">
	let { size = 22 }: { size?: number } = $props();
	const uid = $props.id();
	const maskId = `brand-cut-${uid}`;
</script>

<svg viewBox="0 0 100 100" width={size} height={size} aria-hidden="true">
	<defs>
		<mask id={maskId}>
			<rect width="100" height="100" fill="#fff" />
			<g fill="#000">
				<rect x="21.25" y="12" width="12" height="42" rx="4" />
				<rect x="43.75" y="12" width="12" height="42" rx="4" />
				<rect x="66.25" y="12" width="12" height="42" rx="4" />
			</g>
		</mask>
	</defs>
	<g transform="rotate(-9 50 50)" fill="currentColor" mask="url(#{maskId})">
		<rect x="6.5" y="12" width="19.5" height="76" rx="5" />
		<rect x="29" y="12" width="19.5" height="76" rx="5" />
		<rect x="51.5" y="12" width="19.5" height="76" rx="5" />
		<rect x="74" y="12" width="19.5" height="76" rx="5" />
	</g>
</svg>
