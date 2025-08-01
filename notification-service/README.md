# Invory Notification Service

Servizio di notifiche push per Invory che utilizza Firebase Cloud Messaging (FCM) con l'API HTTP v1.

## 🚀 Caratteristiche

- ✅ **API HTTP v1**: Utilizza l'API moderna di FCM (non deprecata)
- ✅ **Autenticazione OAuth2**: Gestione automatica dei token di accesso
- ✅ **Notifiche personalizzate**: Solo per utenti proprietari dei prodotti
- ✅ **Multi-dispositivo**: Supporto per più dispositivi per utente
- ✅ **Gestione errori**: Pulizia automatica token non validi
- ✅ **Rate limiting**: Protezione da abusi
- ✅ **Logging completo**: Winston logger con rotazione file
- ✅ **Sicurezza**: Helmet, CORS, validazione input
- ✅ **Performance**: Batch processing, caching token

## 📋 Prerequisiti

- Node.js 18+
- Firebase Project con FCM abilitato
- Service Account Key (file JSON)

## 🛠️ Installazione

1. **Clona e installa dipendenze**:
```bash
cd notification-service
npm install
```

2. **Configura le variabili d'ambiente**:
```bash
cp env.example .env
```

3. **Modifica `.env`**:
```env
FIREBASE_PROJECT_ID=invory-b9a72
API_KEY=your-secret-api-key-here
ALLOWED_ORIGINS=http://localhost:3000
```

4. **Aggiungi il service account**:
- Scarica il file `firebase-service-account.json` da Firebase Console
- Mettilo nella root del progetto

## 🚀 Avvio

### Sviluppo
```bash
npm run dev
```

### Produzione
```bash
npm start
```

### Test
```bash
npm test
```

## 📡 API Endpoints

### Health Check
```http
GET /health
```

### Test Notifica
```http
POST /test
Headers: x-api-key: your-api-key
Body: {
  "tokens": ["token1", "token2"],
  "message": "Test message"
}
```

### Notifica Scorte Basse
```http
POST /notify/low-stock
Headers: x-api-key: your-api-key
Body: {
  "product": {
    "id": "product-1",
    "nome": "Caffè",
    "quantita": 5,
    "soglia": 10
  },
  "userTokens": ["token1", "token2"]
}
```

### Notifica Prodotto Esaurito
```http
POST /notify/out-of-stock
Headers: x-api-key: your-api-key
Body: {
  "product": {
    "id": "product-1",
    "nome": "Caffè",
    "quantita": 0,
    "soglia": 10
  },
  "userTokens": ["token1", "token2"]
}
```

### Notifica Cambio Quantità
```http
POST /notify/quantity-change
Headers: x-api-key: your-api-key
Body: {
  "product": {
    "id": "product-1",
    "nome": "Caffè",
    "quantita": 5,
    "soglia": 10
  },
  "previousQuantity": 10,
  "userTokens": ["token1", "token2"]
}
```

## 🔧 Integrazione con Flutter

Aggiorna il servizio FCM in Flutter per usare l'API HTTP v1:

```dart
// lib/core/services/fcm_http_service.dart

class FCMHttpService {
  static const String _apiUrl = 'http://localhost:3000'; // URL del tuo servizio
  static const String _apiKey = 'your-api-key';

  Future<bool> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/notify/user'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: jsonEncode({
          'userId': userId,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] > 0;
      }

      return false;
    } catch (e) {
      debugPrint('Errore invio notifica: $e');
      return false;
    }
  }
}
```

## 🔐 Sicurezza

### Service Account
- Il file `firebase-service-account.json` contiene credenziali sensibili
- Non committare mai questo file nel repository
- Usa variabili d'ambiente in produzione

### API Key
- Genera una API key sicura per l'autenticazione
- Usa HTTPS in produzione
- Implementa rate limiting

### CORS
- Configura `ALLOWED_ORIGINS` per limitare l'accesso
- Usa credenziali solo se necessario

## 📊 Monitoraggio

### Logs
I log vengono salvati in:
- `logs/fcm-error.log` - Errori FCM
- `logs/fcm-combined.log` - Tutti i log FCM
- `logs/invory-error.log` - Errori Invory
- `logs/invory-combined.log` - Tutti i log Invory
- `logs/api-error.log` - Errori API
- `logs/api-combined.log` - Tutti i log API

### Health Check
```bash
curl http://localhost:3000/health
```

## 🚀 Deploy

### Docker
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### PM2
```bash
npm install -g pm2
pm2 start src/index.js --name "invory-notifications"
pm2 save
pm2 startup
```

## 🔧 Configurazione Firebase

1. **Abilita FCM** in Firebase Console
2. **Crea Service Account**:
   - Project Settings > Service Accounts
   - Generate New Private Key
   - Scarica il file JSON

3. **Configura regole Firestore**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/fcmTokens/{tokenId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 🐛 Troubleshooting

### Token non validi
- I token vengono puliti automaticamente
- Controlla i log per dettagli
- Verifica che l'app sia aggiornata

### Errori di autenticazione
- Verifica il service account
- Controlla i permessi FCM
- Verifica l'API key

### Rate limiting
- Implementa backoff esponenziale
- Usa batch processing per grandi volumi
- Monitora i limiti FCM

## 📈 Performance

### Ottimizzazioni
- Cache dei token di accesso
- Batch processing (500 token per volta)
- Connection pooling
- Rate limiting

### Metriche
- Monitora success/failure rate
- Traccia latenza API
- Controlla uso memoria

## 🤝 Contribuire

1. Fork il progetto
2. Crea un branch feature
3. Commit le modifiche
4. Push al branch
5. Crea Pull Request

## 📄 Licenza

MIT License - vedi [LICENSE](LICENSE) per dettagli. 