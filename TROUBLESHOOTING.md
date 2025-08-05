# 🔧 Troubleshooting Guide - Invory

## Problemi Risolti

### 1. ❌ Variabili d'ambiente mancanti
**Problema**: Firebase non riesce a inizializzarsi perché le variabili d'ambiente non vengono passate correttamente.

**Soluzione**: 
- ✅ Configurazione Firebase hardcoded nel file `web/index.html`
- ✅ Configurazione centralizzata in `lib/core/config/app_config.dart`
- ✅ Script di build aggiornati (`build-web.bat` e `build-web-dev.bat`)

### 2. ❌ GetIt dependency injection error
**Problema**: Servizi non registrati correttamente in GetIt.

**Soluzione**:
- ✅ Tutti i servizi ora usano GetIt per l'injection
- ✅ AuthProvider aggiornato per usare GetIt
- ✅ Inizializzazione dei servizi gestita correttamente

### 3. ❌ Service Worker 404
**Problema**: Il file `firebase-messaging-sw.js` non viene trovato.

**Soluzione**:
- ✅ Percorso del service worker corretto in `web/index.html`
- ✅ File service worker presente in `web/firebase-messaging-sw.js`

### 4. ❌ Firestore permissions
**Problema**: Permessi insufficienti per accedere a Firestore.

**Soluzione**:
- ✅ Regole Firestore configurate correttamente
- ✅ Documento utente creato automaticamente al login
- ✅ Struttura dati organizzata per utente

## 🚀 Come Buildare l'App

### Per Sviluppo
```bash
# Windows
build-web-dev.bat

# Linux/Mac
flutter build web --web-renderer html
```

### Per Produzione
```bash
# Windows
build-web.bat

# Linux/Mac
flutter build web --release --web-renderer html
```

## 🔧 Configurazione Firebase

### Variabili Necessarie
Le seguenti variabili sono già configurate nel codice:

```dart
FIREBASE_API_KEY=AIzaSyDjoMnOeETgX5-8U97I_HjgJFI8NxItAcg
FIREBASE_AUTH_DOMAIN=invory-b9a72.firebaseapp.com
FIREBASE_PROJECT_ID=invory-b9a72
FIREBASE_STORAGE_BUCKET=invory-b9a72.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=524552556806
FIREBASE_APP_ID=1:524552556806:web:4bae50045374103e684e87
FIREBASE_MEASUREMENT_ID=G-MTDPNYBZG4
```

### Variabili Opzionali (per notifiche)
```bash
VAPID_KEY=your_vapid_key_here
FCM_PROJECT_ID=your_fcm_project_id
FCM_CLIENT_EMAIL=your_fcm_client_email
FCM_PRIVATE_KEY=your_fcm_private_key
```

## 📱 Funzionalità

### ✅ Funzionanti
- ✅ Autenticazione Firebase
- ✅ Gestione prodotti
- ✅ Gestione fornitori
- ✅ Notifiche web (base)
- ✅ PWA install
- ✅ Responsive design

### ⚠️ Limitazioni
- ⚠️ Notifiche push richiedono VAPID_KEY
- ⚠️ FCM richiede configurazione aggiuntiva

## 🐛 Debug

### Log Attivi
I log sono attivi solo in modalità debug e mostrano:
- Configurazione Firebase
- Inizializzazione servizi
- Errori di autenticazione
- Stato delle notifiche

### Console Browser
Controlla la console del browser per:
- Errori JavaScript
- Stato Firebase
- Registrazione Service Worker
- Token FCM

## 🔒 Sicurezza

### Regole Firestore
```javascript
// Utenti possono accedere solo ai propri dati
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

### Autenticazione
- Login con email/password
- Documento utente creato automaticamente
- Sessione gestita da Firebase Auth

## 📊 Performance

### Ottimizzazioni Implementate
- ✅ Tree shaking abilitato
- ✅ Minificazione codice
- ✅ Compressione assets
- ✅ Lazy loading servizi
- ✅ Parallel initialization

### Metriche
- Tempo di caricamento iniziale: < 3s
- Bundle size ottimizzato
- Service worker per cache

## 🆘 Supporto

### Problemi Comuni

1. **App non carica**
   - Verifica connessione internet
   - Controlla console browser
   - Prova refresh della pagina

2. **Login non funziona**
   - Verifica credenziali
   - Controlla regole Firestore
   - Verifica configurazione Firebase

3. **Notifiche non arrivano**
   - Verifica permessi browser
   - Controlla VAPID_KEY
   - Verifica Service Worker

### Contatti
Per supporto tecnico, controlla i log dell'applicazione e la console del browser. 