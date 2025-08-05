// Configurazione notifiche push per GitHub Pages
// Questo file gestisce la configurazione delle notifiche per l'ambiente web

const NOTIFICATION_CONFIG = {
  // Configurazione Firebase
  firebaseConfig: {
    apiKey: "AIzaSyDjoMnOeETgX5-8U97I_HjgJFI8NxItAcg",
    authDomain: "invory-b9a72.firebaseapp.com",
    projectId: "invory-b9a72",
    storageBucket: "invory-b9a72.firebasestorage.app",
    messagingSenderId: "524552556806",
    appId: "1:524552556806:web:4bae50045374103e684e87",
    measurementId: "G-MTDPNYBZG4"
  },

  // Configurazione notifiche
  notificationOptions: {
    icon: '/invory/icons/Icon-192.png',
    badge: '/invory/icons/Icon-192.png',
    tag: 'invory-notification',
    requireInteraction: true,
    actions: [
      {
        action: 'open',
        title: 'Apri',
        icon: '/invory/icons/Icon-192.png'
      },
      {
        action: 'close',
        title: 'Chiudi',
        icon: '/invory/icons/Icon-192.png'
      }
    ]
  },

  // Configurazione Service Worker
  serviceWorkerPath: '/invory/firebase-messaging-sw.js',

  // Configurazione cache
  cacheName: 'invory-v1',
  cacheUrls: [
    '/invory/',
    '/invory/icons/Icon-192.png',
    '/invory/icons/Icon-512.png',
    '/invory/manifest.json',
    '/invory/favicon.png',
    '/invory/firebase-messaging-sw.js'
  ]
};

// Funzione per richiedere i permessi delle notifiche
async function requestNotificationPermission() {
  if (!('Notification' in window)) {
    console.log('❌ Questo browser non supporta le notifiche desktop');
    return false;
  }

  if (Notification.permission === 'granted') {
    console.log('✅ Permessi notifiche già concessi');
    return true;
  }

  if (Notification.permission === 'denied') {
    console.log('❌ Permessi notifiche negati');
    return false;
  }

  try {
    const permission = await Notification.requestPermission();
    if (permission === 'granted') {
      console.log('✅ Permessi notifiche concessi');
      return true;
    } else {
      console.log('❌ Permessi notifiche negati');
      return false;
    }
  } catch (error) {
    console.error('❌ Errore richiesta permessi:', error);
    return false;
  }
}

// Funzione per registrare il Service Worker
async function registerServiceWorker() {
  if (!('serviceWorker' in navigator)) {
    console.log('❌ Questo browser non supporta i Service Worker');
    return null;
  }

  try {
    const registration = await navigator.serviceWorker.register(NOTIFICATION_CONFIG.serviceWorkerPath);
    console.log('✅ Service Worker registrato:', registration.scope);
    
    // Gestisce gli aggiornamenti del Service Worker
    registration.addEventListener('updatefound', () => {
      console.log('🔄 Nuovo Service Worker disponibile');
      const newWorker = registration.installing;
      newWorker.addEventListener('statechange', () => {
        if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
          console.log('🔄 Nuovo Service Worker installato, ricarica per aggiornare');
        }
      });
    });

    return registration;
  } catch (error) {
    console.error('❌ Errore registrazione Service Worker:', error);
    return null;
  }
}

// Funzione per inizializzare le notifiche
async function initializeNotifications() {
  console.log('🚀 Inizializzazione notifiche...');

  // Richiedi permessi
  const hasPermission = await requestNotificationPermission();
  if (!hasPermission) {
    console.log('⚠️ Impossibile inizializzare notifiche senza permessi');
    return false;
  }

  // Registra Service Worker
  const registration = await registerServiceWorker();
  if (!registration) {
    console.log('⚠️ Impossibile registrare Service Worker');
    return false;
  }

  console.log('✅ Notifiche inizializzate con successo');
  return true;
}

// Esporta le funzioni per uso globale
window.NOTIFICATION_CONFIG = NOTIFICATION_CONFIG;
window.requestNotificationPermission = requestNotificationPermission;
window.registerServiceWorker = registerServiceWorker;
window.initializeNotifications = initializeNotifications;

// Inizializza automaticamente se la pagina è caricata
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeNotifications);
} else {
  initializeNotifications();
} 