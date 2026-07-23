import { sveltekit } from '@sveltejs/kit/vite';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [tailwindcss(), sveltekit()],
	server: {
		watch: {
			// ios/ (Xcode project) and docs/ are not part of the web build —
			// without this, every Swift/doc save triggers a full page reload in dev
			ignored: ['**/ios/**', '**/docs/**', '**/supabase/**']
		}
	}
});
