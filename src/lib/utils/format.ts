/** Format milliseconds as M:SS.cc */
export function formatTime(ms: number): string {
	const s = Math.floor(ms / 1000);
	const m = Math.floor(s / 60);
	const sec = s % 60;
	const cs = Math.floor((ms % 1000) / 10);
	return `${m}:${sec.toString().padStart(2, '0')}.${cs.toString().padStart(2, '0')}`;
}
