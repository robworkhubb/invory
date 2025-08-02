# 🚀 Guida Configurazione FCM Client-Side

## 📋 Panoramica

Questo sistema implementa notifiche push client-side utilizzando Firebase Cloud Messaging (FCM) HTTP v1 API. Non richiede backend esterni e tutto viene gestito direttamente dall'app Flutter.

## 🏗️ Struttura del Database

```
users/
├── {uid}/
│   ├── prodotti/
│   │   └── {productId}/
│   │       ├── nome: string
│   │       ├── quantita: number
│   │       ├── soglia: number
│   │       └── ...
│   └── tokens/
│       └── {fcmToken}/
│           ├── token: string
│           ├── createdAt: timestamp
│           ├── lastUsed: timestamp
│           └── platform: string
```

## ⚙️ Configurazione Firebase

### 1. Firebase Console Setup

1. Vai su [Firebase Console](https://console.firebase.google.com/)
2. Seleziona il tuo progetto `invory-app`
3. Vai su **Project Settings** > **Service accounts**
4. Clicca su **Generate new private key**
5. Scarica il file JSON delle credenziali

### 2. Configurazione FCM

1. Vai su **Project Settings** > **Cloud Messaging**
2. Copia il **Project ID** (es: `invory-app`)
3. Assicurati che FCM sia abilitato per il progetto

### 3. Aggiorna il Project ID

Nel file `lib/core/services/fcm_notification_service.dart`, aggiorna la costante:

```dart
static const String _projectId = 'invory-b9a72'; // Il tuo Project ID
```

**Nota**: Il Project ID è già configurato correttamente per il tuo progetto.

## 🔐 Autenticazione FCM

Il sistema utilizza l'ID token di Firebase Auth per autenticare le chiamate a FCM:

```dart
// Ottiene automaticamente l'access token
final accessToken = await _getAccessToken();
```

### Come funziona:

1. **Login Utente**: Quando l'utente si autentica, Firebase genera un ID token
2. **Token FCM**: L'app ottiene il token FCM del dispositivo
3. **Salvataggio**: Il token viene salvato in `users/{uid}/tokens/{token}`
4. **Autenticazione API**: L'ID token viene usato per autenticare le chiamate FCM

## 📱 Configurazione App

### Android

1. **google-services.json**: Assicurati che sia presente in `android/app/`
2. **AndroidManifest.xml**: Le notifiche sono già configurate
3. **Canale Notifiche**: Creato automaticamente con ID `low_stock_alerts`

### iOS

1. **GoogleService-Info.plist**: Assicurati che sia presente in `ios/Runner/`
2. **Capabilities**: Abilita Push Notifications nel progetto Xcode
3. **APNs**: Configura il certificato APNs in Firebase Console

## 🔄 Flusso delle Notifiche

### 1. Inizializzazione
```dart
// In main.dart
final fcmNotificationService = FCMNotificationService();
await fcmNotificationService.initialize();
```

### 2. Salvataggio Token
```dart
// Automatico al login/registrazione
String? token = await _messaging.getToken();
await _saveTokenToFirestore(token);
```

### 3. Verifica Scorte
```dart
// Automatico quando un prodotto viene aggiornato
if (product.quantita <= product.soglia) {
  await sendLowStockNotification(
    productName: product.nome,
    currentQuantity: product.quantita,
    threshold: product.soglia,
  );
}
```

### 4. Invio Notifica
```dart
// Chiamata HTTP POST a FCM v1
POST https://fcm.googleapis.com/v1/projects/{projectId}/messages:send
Authorization: Bearer {idToken}
```

## 📨 Struttura Notifica

### Notifica Sotto Scorta
```json
{
  "message": {
    "token": "fcm_token",
    "notification": {
      "title": "Prodotto sotto scorta",
      "body": "Il prodotto [nomeProdotto] è sotto la soglia (quantità/soglia)"
    },
    "data": {
      "type": "low_stock",
      "productName": "nomeProdotto",
      "currentQuantity": "5",
      "threshold": "10"
    }
  }
}
```

### Notifica Esaurito
```json
{
  "message": {
    "token": "fcm_token",
    "notification": {
      "title": "Prodotto esaurito",
      "body": "Il prodotto [nomeProdotto] è completamente esaurito"
    },
    "data": {
      "type": "out_of_stock",
      "productName": "nomeProdotto",
      "currentQuantity": "0"
    }
  }
}
```

## 🛠️ Troubleshooting

### Problemi Comuni

1. **Token non valido (404/400)**
   - Il sistema rimuove automaticamente i token non validi
   - Controlla i log per vedere i token rimossi

2. **Errore di autenticazione (401)**
   - Verifica che l'utente sia autenticato
   - L'ID token potrebbe essere scaduto, il sistema lo aggiorna automaticamente

3. **Notifiche non ricevute**
   - Verifica i permessi delle notifiche
   - Controlla che il token FCM sia salvato nel database
   - Verifica la configurazione Firebase

### Debug

Abilita i log di debug:

```dart
if (kDebugMode) {
  print('Token FCM salvato: $token');
  print('Notifica inviata con successo');
  print('Errore nell\'invio: $e');
}
```

## 🔧 Ottimizzazioni

### Performance
- **Lazy Loading**: I token vengono caricati solo quando necessario
- **Batch Operations**: Le notifiche vengono inviate in parallelo
- **Error Handling**: Gestione robusta degli errori senza bloccare l'UI

### Sicurezza
- **Token Validation**: Rimozione automatica dei token non validi
- **User Isolation**: Ogni utente vede solo i propri token
- **Secure Storage**: I token sono protetti dalle regole Firestore

### Manutenzione
- **Cleanup Automatico**: Rimozione dei token obsoleti (>30 giorni)
- **Retry Logic**: Tentativi automatici in caso di errori temporanei
- **Monitoring**: Log dettagliati per il debugging

## 📊 Monitoraggio

### Metriche da Monitorare
- Numero di token per utente
- Tasso di successo delle notifiche
- Token non validi rimossi
- Tempo di invio delle notifiche

### Log da Controllare
```bash
# Token salvati
Token FCM salvato: [token]

# Notifiche inviate
Notifica inviata con successo al token: [token]

# Errori
Errore nell'invio della notifica: [status] - [body]
Token non valido rimosso: [token]
```

## ✅ Test

### Test Manuali
1. Aggiungi un prodotto con quantità sotto la soglia
2. Verifica che la notifica arrivi
3. Controlla che il token sia salvato nel database
4. Testa con più dispositivi per lo stesso utente

### Test Automatici
```dart
// Test del servizio
final service = FCMNotificationService();
await service.initialize();
await service.sendLowStockNotification(
  productName: "Test Product",
  currentQuantity: 5,
  threshold: 10,
);
```

## 🎯 Vantaggi della Soluzione Client-Side

1. **Nessun Backend**: Tutto gestito dall'app
2. **Scalabilità**: Ogni dispositivo gestisce le proprie notifiche
3. **Sicurezza**: Autenticazione Firebase integrata
4. **Performance**: Invio immediato senza latenza di rete
5. **Costi**: Nessun costo di server o hosting
6. **Manutenzione**: Meno componenti da mantenere

## 📚 Risorse

- [FCM HTTP v1 API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
- [Firebase Auth](https://firebase.google.com/docs/auth)
- [Flutter Firebase Messaging](https://pub.dev/packages/firebase_messaging)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started) 