# 🌐 Notifiche Web - Sistema Client-Side FCM

## ✅ Sistema Implementato

Il sistema di notifiche web è ora completamente funzionante senza backend esterni. Utilizza Firebase Cloud Messaging HTTP v1 API direttamente dall'app Flutter.

## 🎯 Caratteristiche Web

### ✅ Notifiche Locali Web
- **Service Worker**: Configurato in `web/firebase-messaging-sw.js`
- **Permessi**: Gestione automatica dei permessi del browser
- **PWA**: Supporto per installazione come Progressive Web App
- **Icone**: Utilizza le icone configurate in `web/icons/`

### ✅ Notifiche Push FCM
- **Client-Side**: Invio diretto tramite FCM HTTP v1 API
- **Autenticazione**: Utilizza Firebase ID token
- **Multi-dispositivo**: Supporto per più dispositivi web per lo stesso utente
- **Token Management**: Salvataggio automatico in Firestore

### ✅ Gestione Token
- **Salvataggio**: Automatico al login/registrazione
- **Aggiornamento**: Gestione automatica dei refresh token
- **Pulizia**: Rimozione automatica dei token non validi
- **Piattaforma**: Identificazione automatica (web/ios/android)

## 🔧 Configurazione Web

### 1. Service Worker
Il file `web/firebase-messaging-sw.js` è già configurato con:
- Firebase SDK
- Gestione notifiche background
- Gestione click notifiche
- Icone personalizzate

### 2. Firebase Config
```javascript
const firebaseConfig = {
  apiKey: "AIzaSyDjoMnOeETgX5-8U97I_HjgJFI8NxItAcg",
  authDomain: "invory-b9a72.firebaseapp.com",
  projectId: "invory-b9a72",
  storageBucket: "invory-b9a72.firebasestorage.app",
  messagingSenderId: "524552556806",
  appId: "1:524552556806:web:4bae50045374103e684e87",
  measurementId: "G-MTDPNYBZG4"
};
```

### 3. Project ID
Il Project ID è configurato in `fcm_notification_service.dart`:
```dart
static const String _projectId = 'invory-b9a72';
```

## 🧪 Test Web

### Test Automatici
```dart
// Test completi
WebNotificationTest.runAllWebTests();

// Test specifici
WebNotificationTest.testWebPermissions();
WebNotificationTest.testWebNotifications();
WebNotificationTest.testPWAInstall();
```

### Test Manuali
1. **Apri l'app web** in Chrome/Firefox
2. **Accetta i permessi** per le notifiche
3. **Aggiungi un prodotto** con quantità sotto la soglia
4. **Verifica** che arrivi la notifica
5. **Testa** con più tab/dispositivi

## 📱 Funzionalità PWA

### Installazione
- **Prompt automatico**: Mostrato quando l'app è installabile
- **Icone**: Configurate per diverse dimensioni
- **Manifest**: Configurato per installazione nativa

### Notifiche PWA
- **Background**: Funzionano anche quando l'app è chiusa
- **Click**: Aprire l'app quando si clicca sulla notifica
- **Badge**: Contatore notifiche nell'icona

## 🔄 Flusso Web

### 1. Inizializzazione
```dart
// Al caricamento dell'app web
await notificationService.initialize();
// Registra service worker e richiede permessi
```

### 2. Salvataggio Token
```dart
// Automatico dopo autenticazione
String? token = await _messaging.getToken();
await _saveTokenToFirestore(token);
// Salva in users/{uid}/tokens/{token}
```

### 3. Invio Notifica
```dart
// Quando un prodotto è sotto scorta
await _fcmService.sendLowStockNotification(
  productName: product.nome,
  currentQuantity: product.quantita,
  threshold: product.soglia,
);
```

### 4. Ricezione Web
```javascript
// Nel service worker
messaging.onBackgroundMessage((payload) => {
  // Mostra notifica nativa del browser
  return self.registration.showNotification(title, options);
});
```

## 🛠️ Troubleshooting Web

### Problemi Comuni

1. **Notifiche non arrivano**
   - Verifica i permessi del browser
   - Controlla che il service worker sia registrato
   - Verifica la connessione internet

2. **Service Worker non si registra**
   - Verifica che il file `firebase-messaging-sw.js` sia accessibile
   - Controlla la console per errori
   - Verifica la configurazione Firebase

3. **Token non si salva**
   - Verifica che l'utente sia autenticato
   - Controlla le regole Firestore
   - Verifica la connessione a Firebase

### Debug
```dart
// Abilita log dettagliati
if (kDebugMode) {
  print('Token FCM: ${token.substring(0, 20)}...');
  print('Permessi: $permissionsGranted');
  print('Service Worker: $registration');
}
```

## 📊 Monitoraggio Web

### Metriche da Controllare
- **Token salvati**: Numero di token per utente web
- **Permessi**: Tasso di accettazione permessi
- **Notifiche inviate**: Successo delle notifiche web
- **PWA installazioni**: Numero di installazioni PWA

### Log da Monitorare
```bash
# Service Worker
Service worker registrato: /firebase-messaging-sw.js
Received background message: {...}

# Token
Token FCM salvato: [token]
Token FCM aggiornato: [token]

# Notifiche
Notifica web inviata: [title]
Errore notifica web: [error]
```

## 🎯 Vantaggi Web

1. **✅ Nessun Backend**: Tutto gestito client-side
2. **✅ PWA**: Installazione come app nativa
3. **✅ Cross-Platform**: Funziona su tutti i browser moderni
4. **✅ Offline**: Service worker per funzionalità offline
5. **✅ Performance**: Ottimizzato per dispositivi lenti
6. **✅ Sicurezza**: Autenticazione Firebase integrata

## 🚀 Prossimi Passi

1. **Test in Produzione**: Verifica con utenti reali
2. **Analytics**: Traccia l'uso delle notifiche web
3. **Personalizzazione**: Opzioni per personalizzare le notifiche
4. **Offline**: Migliora le funzionalità offline

---

**🎉 Sistema notifiche web client-side implementato con successo!** 