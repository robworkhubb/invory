// Service Worker per Firebase Cloud Messaging
// Questo file deve essere nella cartella web/ per essere accessibile

importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Configurazione Firebase - sostituisci con le tue credenziali
firebase.initializeApp({
  apiKey: 'AIzaSyDjoMnOeETgX5-8U97I_HjgJFI8NxItAcg',
  appId: '1:524552556806:web:4bae50045374103e684e87',
  messagingSenderId: '524552556806',
  projectId: 'invory-b9a72',
  authDomain: 'invory-b9a72.firebaseapp.com',
  storageBucket: 'invory-b9a72.firebasestorage.app',
  measurementId: 'G-MTDPNYBZG4',
});

const messaging = firebase.messaging();

// Gestisci le notifiche in background
messaging.onBackgroundMessage((payload) => {
  console.log('Ricevuta notifica in background:', payload);
  
  const { title, body } = payload.notification;
  const notificationOptions = {
    body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
    requireInteraction: true,
    actions: [
      {
        action: 'view',
        title: 'Visualizza'
      },
      {
        action: 'dismiss',
        title: 'Ignora'
      }
    ]
  };

  return self.registration.showNotification(title, notificationOptions);
});

// Gestisci il click sulla notifica
self.addEventListener('notificationclick', (event) => {
  console.log('Notifica cliccata:', event);
  
  event.notification.close();
  
  if (event.action === 'view') {
    // Apri l'app o naviga alla pagina del prodotto
    event.waitUntil(
      clients.openWindow('/')
    );
  }
}); 