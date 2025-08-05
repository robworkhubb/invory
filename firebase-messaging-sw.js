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

// Variabili globali
let messaging = null;
let isInitialized = false;

// Inizializza Firebase
function initializeFirebase() {
  if (isInitialized) {
    console.log('🔧 Firebase già inizializzato nel Service Worker');
    return;
  }

  try {
    console.log('🔧 Inizializzazione Firebase nel Service Worker...');
    firebase.initializeApp(firebaseConfig);
    messaging = firebase.messaging();
    isInitialized = true;
    console.log('✅ Firebase inizializzato nel Service Worker');
  } catch (error) {
    console.error('❌ Errore inizializzazione Firebase nel Service Worker:', error);
    throw error;
  }
}

// Inizializza Firebase all'avvio
initializeFirebase();

// Gestisci le notifiche in background con retry
messaging.onBackgroundMessage((payload) => {
  console.log('🔔 Notifica ricevuta in background:', payload);
  
  try {
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
  } catch (error) {
    console.error('❌ Errore nella gestione notifica background:', error);
  }
});

// Gestisci il click sulla notifica con retry
self.addEventListener('notificationclick', (event) => {
  console.log('🔔 Notifica cliccata:', event);
  
  try {
    event.notification.close();
    
    if (event.action === 'close') {
      return;
    }
    
    // Apri l'app con retry - gestisci sia GitHub Pages che localhost
    event.waitUntil(
      clients.openWindow('/invory/').catch(error => {
        console.error('❌ Errore apertura app:', error);
        // Fallback: prova ad aprire la root
        return clients.openWindow('/');
      })
    );
  } catch (error) {
    console.error('❌ Errore gestione click notifica:', error);
  }
});

// Gestisci le notifiche push con retry
self.addEventListener('push', (event) => {
  console.log('🔔 Push notification ricevuta:', event);
  
  try {
    if (event.data) {
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
    }
  } catch (error) {
    console.error('❌ Errore nel parsing della notifica push:', error);
  }
});

// Gestisci l'installazione del service worker con retry
self.addEventListener('install', (event) => {
  console.log('🔧 Service Worker installato');
  
  try {
    // Forza l'attivazione immediata
    self.skipWaiting();
    
    // Notifica al client che l'installazione è completata
    event.waitUntil(
      self.clients.matchAll().then(clients => {
        clients.forEach(client => {
          client.postMessage({
            type: 'SERVICE_WORKER_INSTALLED',
            payload: { timestamp: Date.now() }
          });
        });
      })
    );
  } catch (error) {
    console.error('❌ Errore installazione Service Worker:', error);
  }
});

// Gestisci l'attivazione del service worker con retry
self.addEventListener('activate', (event) => {
  console.log('🔧 Service Worker attivato');
  
  try {
    // Prendi il controllo di tutti i client
    event.waitUntil(
      Promise.all([
        self.clients.claim(),
        // Pulisci le cache vecchie se necessario
        caches.keys().then(cacheNames => {
          return Promise.all(
            cacheNames.map(cacheName => {
              if (cacheName !== 'invory-cache-v1') {
                console.log('🗑️ Rimozione cache vecchia:', cacheName);
                return caches.delete(cacheName);
              }
            })
          );
        })
      ])
    );
    
    // Notifica al client che l'attivazione è completata
    event.waitUntil(
      self.clients.matchAll().then(clients => {
        clients.forEach(client => {
          client.postMessage({
            type: 'SERVICE_WORKER_ACTIVATED',
            payload: { timestamp: Date.now() }
          });
        });
      })
    );
  } catch (error) {
    console.error('❌ Errore attivazione Service Worker:', error);
  }
});

// Gestisci i messaggi dal client con retry
self.addEventListener('message', (event) => {
  console.log('📨 Messaggio ricevuto dal client:', event.data);
  
  try {
    if (event.data && event.data.type) {
      switch (event.data.type) {
        case 'FIREBASE_CONFIG':
          console.log('✅ Configurazione Firebase ricevuta');
          // Opzionale: aggiorna la configurazione Firebase
          break;
          
        case 'FCM_TOKEN_GENERATED':
          console.log('✅ Token FCM generato ricevuto');
          // Opzionale: salva il token o esegui altre operazioni
          break;
          
        case 'PING':
          // Rispondi al ping per verificare che il service worker sia attivo
          event.ports[0]?.postMessage({
            type: 'PONG',
            payload: { timestamp: Date.now() }
          });
          break;
          
        default:
          console.log('📨 Messaggio sconosciuto:', event.data.type);
      }
    }
  } catch (error) {
    console.error('❌ Errore gestione messaggio:', error);
  }
});

// Gestisci gli errori del service worker
self.addEventListener('error', (event) => {
  console.error('❌ Errore Service Worker:', event.error);
});

// Gestisci i rejections non gestiti
self.addEventListener('unhandledrejection', (event) => {
  console.error('❌ Rejection non gestito nel Service Worker:', event.reason);
});

// Funzione di utilità per retry
async function retryOperation(operation, maxAttempts = 3, delay = 1000) {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await operation();
    } catch (error) {
      console.warn(`⚠️ Tentativo ${attempt}/${maxAttempts} fallito:`, error);
      
      if (attempt === maxAttempts) {
        throw error;
      }
      
      // Aspetta prima del prossimo tentativo
      await new Promise(resolve => setTimeout(resolve, delay * attempt));
    }
  }
}

// Funzione di utilità per logging
function logWithTimestamp(message, level = 'info') {
  const timestamp = new Date().toISOString();
  const logMessage = `[${timestamp}] ${message}`;
  
  switch (level) {
    case 'error':
      console.error(logMessage);
      break;
    case 'warn':
      console.warn(logMessage);
      break;
    default:
      console.log(logMessage);
  }
} 