// Firebase Cloud Messaging Service Worker
importScripts('https://www.gstatic.com/firebasejs/10.11.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.11.1/firebase-messaging-compat.js');

// Configurazione Firebase per il service worker
const firebaseConfig = {
  apiKey: "AIzaSyDjoMnOeETgX5-8U97I_HjgJFI8NxItAcg",
  authDomain: "invory-b9a72.firebaseapp.com",
  projectId: "invory-b9a72",
  storageBucket: "invory-b9a72.firebasestorage.app",
  messagingSenderId: "524552556806",
  appId: "1:524552556806:web:4bae50045374103e684e87",
  measurementId: "G-MTDPNYBZG4"
};

// Inizializza Firebase
firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

// Gestisci le notifiche in background
messaging.onBackgroundMessage((payload) => {
  console.log('🔔 Notifica ricevuta in background:', payload);
  
  const notificationTitle = payload.notification?.title || 'Invory';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/invory/icons/Icon-192.png',
    badge: '/invory/icons/Icon-192.png',
    tag: 'invory_notification',
    data: payload.data || {},
    requireInteraction: true,
    actions: [
      {
        action: 'open',
        title: 'Apri',
        icon: '/invory/icons/Icon-192.png'
      },
      {
        action: 'close',
        title: 'Chiudi'
      }
    ]
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Gestisci il click sulla notifica
self.addEventListener('notificationclick', (event) => {
  console.log('🔔 Notifica cliccata:', event);
  
  event.notification.close();
  
  if (event.action === 'close') {
    return;
  }
  
  // Apri l'app
  event.waitUntil(
    clients.openWindow('/invory/')
  );
});

// Gestisci le notifiche push
self.addEventListener('push', (event) => {
  console.log('🔔 Push notification ricevuta:', event);
  
  if (event.data) {
    try {
      const payload = event.data.json();
      const notificationTitle = payload.notification?.title || 'Invory';
      const notificationOptions = {
        body: payload.notification?.body || '',
        icon: '/invory/icons/Icon-192.png',
        badge: '/invory/icons/Icon-192.png',
        tag: 'invory_notification',
        data: payload.data || {},
        requireInteraction: true,
        actions: [
          {
            action: 'open',
            title: 'Apri',
            icon: '/invory/icons/Icon-192.png'
          },
          {
            action: 'close',
            title: 'Chiudi'
          }
        ]
      };

      event.waitUntil(
        self.registration.showNotification(notificationTitle, notificationOptions)
      );
    } catch (error) {
      console.error('❌ Errore nel parsing della notifica push:', error);
    }
  }
});

// Gestisci l'installazione del service worker
self.addEventListener('install', (event) => {
  console.log('🔧 Service Worker installato');
  self.skipWaiting();
});

// Gestisci l'attivazione del service worker
self.addEventListener('activate', (event) => {
  console.log('🔧 Service Worker attivato');
  event.waitUntil(self.clients.claim());
});

// Gestisci i messaggi dal client
self.addEventListener('message', (event) => {
  console.log('📨 Messaggio ricevuto dal client:', event.data);
  
  if (event.data && event.data.type === 'FIREBASE_CONFIG') {
    console.log('✅ Configurazione Firebase ricevuta');
  }
}); 