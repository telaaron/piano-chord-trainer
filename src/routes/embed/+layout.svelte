<script lang="ts">
	let { children } = $props();
</script>

<!--
  Embed layout — inherits app.css from root layout.
  Nav/footer suppression is handled in the root +layout.svelte via isEmbedRoute.
  This layout gives embed pages a full-height, scrollless container
  suitable for iframe embedding at any size from 400px to full-width.
-->
<div class="w-full min-h-dvh flex flex-col overflow-hidden">
	{@render children()}
</div>
