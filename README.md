# Invory - Gestione Magazzino Intelligente

Organizza, Controlla, Rifornisci - Gestione intelligente del magazzino con notifiche push in tempo reale.

## 🚀 Caratteristiche

- ✅ **Gestione Prodotti**: Aggiungi, modifica, elimina prodotti con soglie di scorta
- ✅ **Gestione Fornitori**: Mantieni una lista dei tuoi fornitori
- ✅ **Notifiche Push**: Ricevi notifiche quando i prodotti sono sotto scorta
- ✅ **Multi-Device**: Sincronizzazione automatica tra dispositivi
- ✅ **PWA**: Installabile come app nativa
- ✅ **Responsive**: Ottimizzato per desktop, tablet e mobile

## 🔧 Configurazione

### 1. Variabili d'Ambiente

Crea un file `.env` nella root del progetto con le seguenti variabili:

```env
# Firebase Configuration
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_project.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id
FIREBASE_MEASUREMENT_ID=your_measurement_id

# FCM Configuration
VAPID_KEY=your_vapid_key
FCM_PROJECT_ID=your_project_id
FCM_CLIENT_EMAIL=your_service_account_email
FCM_PRIVATE_KEY=your_private_key
```

### 2. Firebase Setup

1. Crea un progetto Firebase
2. Abilita Authentication con Email/Password
3. Crea un database Firestore
4. Configura le regole Firestore (vedi `firestore.rules`)
5. Genera una chiave VAPID per le notifiche web
6. Crea un service account per FCM

### 3. Struttura Database

Il database utilizza la seguente struttura:

```
users/
  {uid}/
    products/
      {productId}/
        name: string
        category: string
        quantity: number
        threshold: number
        price: number
        consumed: number
        lastModified: timestamp
    suppliers/
      {supplierId}/
        name: string
        email: string
        phone: string
        address: string
    tokens/
      {tokenId}/
        token: string
        deviceId: string
        platform: string
        createdAt: timestamp
        lastUsed: timestamp
        isActive: boolean
    notifications/
      {notificationId}/
        title: string
        body: string
        data: map
        timestamp: timestamp
        read: boolean
        targetDeviceId: string
        notificationId: string
        sourceDeviceId: string
```

## 🏗️ Build e Deploy

### Build per Web (GitHub Pages)

```bash
# Build ottimizzato per GitHub Pages
flutter build web --base-href /invory/ --dart-define=FIREBASE_API_KEY=your_key --dart-define=VAPID_KEY=your_vapid_key

# Oppure usa lo script di build
./build-web.bat
```

### Build per Mobile

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 📱 Sistema di Notifiche

### Come Funziona

1. **Registrazione Token**: Al login, ogni dispositivo registra il proprio token FCM
2. **Salvataggio**: I token vengono salvati in `users/{uid}/tokens/{token}`
3. **Notifiche**: Quando un prodotto viene modificato, vengono inviate notifiche a tutti gli altri dispositivi
4. **Esclusione**: Il dispositivo che ha fatto la modifica non riceve la notifica

### Tipi di Notifiche

- **Scorta Bassa**: Quando la quantità scende sotto la soglia
- **Prodotto Esaurito**: Quando la quantità raggiunge zero
- **Notifiche Personalizzate**: Per eventi specifici

## 🔒 Sicurezza

- Autenticazione Firebase Auth
- Regole Firestore per isolamento dati per utente
- Token FCM sicuri e gestiti automaticamente
- Nessun dato condiviso tra utenti

## 🚀 Deploy su GitHub Pages

1. **Configura GitHub Actions** (opzionale):
   ```yaml
   name: Deploy to GitHub Pages
   on:
     push:
       branches: [ main ]
   jobs:
     build_and_deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v2
         - uses: subosito/flutter-action@v2
         - run: flutter build web --base-href /invory/
         - uses: peaceiris/actions-gh-pages@v3
           with:
             github_token: ${{ secrets.GITHUB_TOKEN }}
             publish_dir: ./build/web
   ```

2. **Deploy Manuale**:
   - Esegui `flutter build web --base-href /invory/`
   - Copia il contenuto di `build/web/` nella branch `gh-pages`
   - Abilita GitHub Pages nelle impostazioni del repository

## 🧪 Testing

### Test Notifiche

```dart
// Usa FCMTestHelper per testare le notifiche
final testHelper = FCMTestHelper();

// Test notifica singola
await testHelper.sendTestNotification();

// Test notifiche multiple
await testHelper.sendMultipleTestNotifications();

// Verifica stato sistema
await testHelper.checkNotificationStatus();
```

## 📊 Performance

- **Lazy Loading**: Caricamento ottimizzato dei dati
- **Cache Intelligente**: Cache locale per migliori performance
- **Ottimizzazioni Web**: Bundle ridotto e ottimizzato
- **Service Worker**: Cache offline e notifiche push

## 🐛 Troubleshooting

### Problemi Comuni

1. **Service Worker 404**:
   - Verifica che `firebase-messaging-sw.js` sia nella root di `web/`
   - Controlla che il path sia corretto in `index.html`

2. **Notifiche non funzionano**:
   - Verifica le variabili d'ambiente
   - Controlla i permessi del browser
   - Verifica la configurazione VAPID

3. **Errore di autenticazione**:
   - Verifica le regole Firestore
   - Controlla la configurazione Firebase

## 📄 Licenza

Questo progetto è sotto licenza MIT. Vedi il file `LICENSE` per i dettagli.

## 🤝 Contributi

I contributi sono benvenuti! Per favore:

1. Fai un fork del progetto
2. Crea una branch per la tua feature
3. Committa le tue modifiche
4. Fai un push alla branch
5. Apri una Pull Request

## 📞 Supporto

Per supporto o domande:
- Apri una issue su GitHub
- Contatta il team di sviluppo

---

**Invory** - Organizza, Controlla, Rifornisci 🚀

