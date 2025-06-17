// sw.js (Service Worker)

// Service Worker for Iran Airspace Monitor
const CACHE_NAME = 'iran-airspace-v1';

// Install event
self.addEventListener('install', function(event) {
    console.log('Service Worker installing...');
    self.skipWaiting();
});

// Activate event
self.addEventListener('activate', function(event) {
    console.log('Service Worker activating...');
    event.waitUntil(self.clients.claim());
});

// Push event for notifications
self.addEventListener('push', function(event) {
    console.log('Push received:', event);
    
    const options = {
        icon: '/static/icon-192.png',
        badge: '/static/badge-72.png',
        vibrate: [200, 100, 200],
        data: {
            dateOfArrival: Date.now(),
            primaryKey: 1
        },
        actions: [
            {
                action: 'explore',
                title: 'View Aircraft',
                icon: '/static/checkmark.png'
            },
            {
                action: 'close',
                title: 'Close',
                icon: '/static/xmark.png'
            }
        ]
    };

    if (event.data) {
        const data = event.data.json();
        options.body = data.body || 'New aircraft detected in Iran FIR';
        options.title = data.title || 'Iran Airspace Alert';
    } else {
        options.title = 'Iran Airspace Monitor';
        options.body = 'New aircraft activity detected';
    }

    event.waitUntil(
        self.registration.showNotification(options.title, options)
    );
});

// Notification click event
self.addEventListener('notificationclick', function(event) {
    console.log('Notification click received.');
    
    event.notification.close();
    
    if (event.action === 'explore') {
        event.waitUntil(
            clients.openWindow('https://iranairspacemonitor.xyz')
        );
    } else if (event.action === 'close') {
        event.notification.close();
    } else {
        event.waitUntil(
            clients.openWindow('https://iranairspacemonitor.xyz')
        );
    }
}); 