// Firebase Cloud Messaging Service Worker
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDjoMnOeETgX5-8U97I_HjgJFI8NxItAcg",
  authDomain: "invory-b9a72.firebaseapp.com",
  projectId: "invory-b9a72",
  storageBucket: "invory-b9a72.firebasestorage.app",
  messagingSenderId: "524552556806",
  appId: "1:524552556806:web:4bae50045374103e684e87",
  measurementId: "G-MTDPNYBZG4"
});

const messaging = firebase.messaging();

// Gestisci le notifiche in background
messaging.onBackgroundMessage((payload) => {
  console.log('Notifica ricevuta in background:', payload);
  
  const notificationTitle = payload.notification?.title || 'Invory';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/invory/icons/Icon-192.png',
    badge: '/invory/icons/Icon-192.png',
    tag: 'invory_notification',
    data: payload.data
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Gestisci il click sulla notifica
self.addEventListener('notificationclick', (event) => {
  console.log('Notifica cliccata:', event);
  
  event.notification.close();
  
  // Apri l'app
  event.waitUntil(
    clients.openWindow('/invory/')
  );
});

// Gestisci le notifiche push
self.addEventListener('push', (event) => {
  console.log('Push notification ricevuta:', event);
  
  if (event.data) {
    const payload = event.data.json();
    const notificationTitle = payload.notification?.title || 'Invory';
    const notificationOptions = {
      body: payload.notification?.body || '',
      icon: '/invory/icons/Icon-192.png',
      badge: '/invory/icons/Icon-192.png',
      tag: 'invory_notification',
      data: payload.data
    };

    event.waitUntil(
      self.registration.showNotification(notificationTitle, notificationOptions)
    );
  }
}); 