# Sistema Notifiche FCM - Invory

## Panoramica

Il sistema di notifiche push implementato in Invory utilizza Firebase Cloud Messaging (FCM) per inviare notifiche personalizzate agli utenti quando i prodotti scendono sotto la soglia minima o si esauriscono.

## Caratteristiche

✅ **Notifiche personalizzate per utente**: Ogni utente riceve solo le notifiche dei propri prodotti
✅ **Multi-dispositivo**: Supporto per più dispositivi per utente
✅ **Notifiche automatiche**: Trigger automatico quando i prodotti scendono sotto soglia
✅ **Gestione token**: Pulizia automatica dei token non validi
✅ **Supporto cross-platform**: Web, iOS, Android
✅ **Ottimizzazioni performance**: Batch operations, caching, retry logic

## Configurazione

### 1. Firebase Console

1. Vai su [Firebase Console](https://console.firebase.google.com/)
2. Seleziona il tuo progetto Invory
3. Vai su **Project Settings** > **Cloud Messaging**
4. Copia il **Server Key** e aggiornalo in `lib/core/services/fcm_http_service.dart`

### 2. Service Worker (Web)

Aggiorna le credenziali Firebase in `web/firebase-messaging-sw.js`:

```javascript
firebase.initializeApp({
  apiKey: "TUA_API_KEY",
  authDomain: "invory-XXXXX.firebaseapp.com",
  projectId: "invory-XXXXX",
  storageBucket: "invory-XXXXX.appspot.com",
  messagingSenderId: "TUA_SENDER_ID",
  appId: "TUA_APP_ID"
});
```

### 3. Cloud Functions

1. Installa le dipendenze:
```bash
cd functions
npm install
```

2. Deploy delle funzioni:
```bash
firebase deploy --only functions
```

### 4. Permessi Firestore

Assicurati che le regole Firestore permettano l'accesso alle collezioni FCM:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permetti accesso ai token FCM dell'utente
    match /users/{userId}/fcmTokens/{tokenId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Regole esistenti per i prodotti...
  }
}
```

## Struttura Dati

### Token FCM
```
users/{uid}/fcmTokens/{token}
{
  token: string,
  platform: "web" | "ios" | "android",
  lastUsed: timestamp,
  isActive: boolean
}
```

### Notifiche
Le notifiche vengono inviate automaticamente quando:
- `product.quantita <= product.soglia`
- `product.quantita == 0` (esaurito)

## Funzionalità

### 1. Gestione Token
- **Salvataggio automatico**: I token vengono salvati quando l'utente accede
- **Aggiornamento**: I token vengono aggiornati quando cambiano
- **Pulizia**: I token non validi vengono rimossi automaticamente

### 2. Notifiche Automatiche
- **Trigger**: Modifica della quantità di un prodotto
- **Controllo**: Verifica se il prodotto è sotto soglia
- **Invio**: Notifica a tutti i dispositivi dell'utente

### 3. Gestione Errori
- **Retry logic**: Tentativi automatici in caso di errore
- **Token invalidi**: Rimozione automatica dei token non validi
- **Logging**: Log dettagliati per debugging

## Test

### 1. Test Locale
```bash
# Avvia l'emulatore Firebase
firebase emulators:start

# Testa le funzioni
firebase functions:shell
```

### 2. Test Produzione
1. Modifica la quantità di un prodotto sotto la soglia
2. Verifica che la notifica arrivi su tutti i dispositivi
3. Controlla i log delle Cloud Functions

## Troubleshooting

### Notifiche non arrivano
1. Verifica i permessi del browser/app
2. Controlla che i token siano salvati in Firestore
3. Verifica i log delle Cloud Functions
4. Controlla la configurazione Firebase

### Token non validi
1. I token vengono puliti automaticamente
2. Verifica la connessione internet
3. Controlla che l'app sia aggiornata

### Performance
1. Le notifiche sono ottimizzate per batch
2. I token vengono cacheati localmente
3. Le operazioni sono asincrone

## Sicurezza

- ✅ Autenticazione richiesta per tutte le operazioni
- ✅ Token isolati per utente
- ✅ Validazione dei dati
- ✅ Rate limiting nelle Cloud Functions

## Monitoraggio

### Log delle Cloud Functions
```bash
firebase functions:log
```

### Metriche Firebase
- Firebase Console > Analytics
- Firebase Console > Performance
- Firebase Console > Crashlytics

## Aggiornamenti

Per aggiornare il sistema:

1. Aggiorna le dipendenze:
```bash
flutter pub get
cd functions && npm install
```

2. Deploy delle modifiche:
```bash
firebase deploy --only functions
```

3. Testa le nuove funzionalità

## Supporto

Per problemi o domande:
1. Controlla i log delle Cloud Functions
2. Verifica la configurazione Firebase
3. Testa con l'emulatore locale
4. Controlla la documentazione Firebase 