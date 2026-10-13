// Focus mode for /train. The trainer's start screen sits inside the site's
// frame (global nav + footer); only a running drill hides them, so nothing
// competes with the chord. The train page sets this, the root layout reads it.

let active = $state(false);

export const trainFocus = {
	get active() {
		return active;
	},
};

export function setTrainFocus(on: boolean): void {
	active = on;
}
