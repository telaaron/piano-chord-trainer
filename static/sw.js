/// Service Worker for Chord Trainer — Push Notification Support
/// Registered from the main app, handles notification click events.

const SW_VERSION = '1.0.0';

self.addEventListener('install', (event) => {
	self.skipWaiting();
});

self.addEventListener('activate', (event) => {
	event.waitUntil(self.clients.claim());
});

// Handle notification clicks — open the trainer
self.addEventListener('notificationclick', (event) => {
	event.notification.close();

	event.waitUntil(
		self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
			// If app is already open, focus it
			for (const client of clientList) {
				if (client.url.includes('/train') && 'focus' in client) {
					return client.focus();
				}
			}
			// Otherwise open the train page
			if (self.clients.openWindow) {
				return self.clients.openWindow('/train');
			}
		})
	);
});
