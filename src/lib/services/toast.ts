// Global toast notification service
// Uses callback pattern (no Svelte stores) — consistent with auth.ts

export type ToastType = 'success' | 'error' | 'warning' | 'info';

export interface Toast {
	id: string;
	type: ToastType;
	message: string;
	/** Optional action button */
	action?: { label: string; onClick: () => void };
	/** Duration in ms — 0 = persist until dismissed. Default: 4000 */
	duration?: number;
}

type ToastCallback = (toasts: Toast[]) => void;

const callbacks: ToastCallback[] = [];
let toasts: Toast[] = [];

function notify() {
	for (const cb of callbacks) cb([...toasts]);
}

function generateId() {
	return Math.random().toString(36).slice(2, 9);
}

export function onToastChange(cb: ToastCallback): () => void {
	callbacks.push(cb);
	cb([...toasts]);
	return () => {
		const i = callbacks.indexOf(cb);
		if (i !== -1) callbacks.splice(i, 1);
	};
}

export function toast(
	message: string,
	type: ToastType = 'info',
	options?: { duration?: number; action?: Toast['action'] },
): string {
	const id = generateId();
	const duration = options?.duration ?? (type === 'error' ? 6000 : 4000);
	const t: Toast = { id, type, message, action: options?.action, duration };
	toasts = [t, ...toasts].slice(0, 5); // max 5 at once
	notify();

	if (duration > 0) {
		setTimeout(() => dismissToast(id), duration);
	}
	return id;
}

export function dismissToast(id: string) {
	toasts = toasts.filter((t) => t.id !== id);
	notify();
}

// Convenience wrappers
export const toastSuccess = (msg: string, opts?: Parameters<typeof toast>[2]) =>
	toast(msg, 'success', opts);
export const toastError = (msg: string, opts?: Parameters<typeof toast>[2]) =>
	toast(msg, 'error', opts);
export const toastWarning = (msg: string, opts?: Parameters<typeof toast>[2]) =>
	toast(msg, 'warning', opts);
export const toastInfo = (msg: string, opts?: Parameters<typeof toast>[2]) =>
	toast(msg, 'info', opts);
