const CACHE_NAME = 'invory-v1';
const urlsToCache = [
  '/',
  '/index.html',
  '/main.dart.js',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => response || fetch(event.request))
  );
});

self.addEventListener('push', (event) => {
  const options = {
    body: event.data ? event.data.text() : 'Nuova notifica da Invory',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    vibrate: [100, 50, 100],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1
    },
    actions: [
      {
        action: 'explore',
        title: 'Apri Invory',
        icon: '/icons/Icon-192.png'
      },
      {
        action: 'close',
        title: 'Chiudi',
        icon: '/icons/Icon-192.png'
      }
    ]
  };

  event.waitUntil(
    self.registration.showNotification('Invory', options)
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  if (event.action === 'explore') {
    event.waitUntil(
      clients.openWindow('/')
    );
  }
}); 