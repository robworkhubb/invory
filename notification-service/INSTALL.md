# Guida Installazione - Invory Notification Service

## 🚀 Installazione Rapida

### 1. Prerequisiti
- Node.js 18+ installato
- Firebase project configurato
- Service account key scaricato

### 2. Setup Iniziale
```bash
# Clona o naviga nella directory
cd notification-service

# Installa dipendenze
npm install

# Copia il file di configurazione
cp env.example .env

# Aggiungi il service account
cp ../firebase-service-account.json ./
```

### 3. Configurazione
Modifica il file `.env`:
```env
PORT=3000
NODE_ENV=production
ALLOWED_ORIGINS=https://invory-b9a72.web.app
FIREBASE_PROJECT_ID=invory-b9a72
```

### 4. Test
```bash
# Test del servizio
npm test

# Avvia in sviluppo
npm run dev

# Test delle API
node test-api.js
```

## 🔧 Configurazione Dettagliata

### Firebase Setup

1. **Vai su Firebase Console**
   - https://console.firebase.google.com/
   - Seleziona il tuo progetto

2. **Abilita Cloud Messaging**
   - Project Settings > Cloud Messaging
   - Abilita FCM per il progetto

3. **Crea Service Account**
   - Project Settings > Service Accounts
   - Click "Generate New Private Key"
   - Scarica il file JSON
   - Rinominalo in `firebase-service-account.json`

4. **Configura Regole Firestore**
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

### Configurazione Avanzata

#### Variabili d'Ambiente
```env
# Server
PORT=3000
NODE_ENV=production

# CORS
ALLOWED_ORIGINS=https://invory-b9a72.web.app,http://localhost:3000

# Logging
LOG_LEVEL=info

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
NOTIFICATION_RATE_LIMIT_WINDOW_MS=60000
NOTIFICATION_RATE_LIMIT_MAX_REQUESTS=10

# Firebase
FIREBASE_PROJECT_ID=invory-b9a72
```

#### Rate Limiting
- **Generale**: 100 richieste per 15 minuti
- **Notifiche**: 10 notifiche per minuto per IP
- **Burst**: 5 richieste immediate per notifiche

## 🚀 Deployment

### Opzione 1: Docker (Raccomandato)
```bash
# Build e avvia
docker-compose up -d

# Verifica
docker-compose ps

# Logs
docker-compose logs -f notification-service
```

### Opzione 2: PM2
```bash
# Installa PM2 globalmente
npm install -g pm2

# Avvia con PM2
pm2 start ecosystem.config.js --env production

# Salva configurazione
pm2 save
pm2 startup
```

### Opzione 3: Manuale
```bash
# Avvia in produzione
NODE_ENV=production npm start

# Con nohup (background)
nohup npm start > logs/app.log 2>&1 &
```

## 🔍 Verifica Installazione

### 1. Health Check
```bash
curl http://localhost:3000/health
```
Risposta attesa:
```json
{
  "status": "OK",
  "timestamp": "2024-01-01T12:00:00.000Z",
  "service": "invory-notification-service"
}
```

### 2. Test Connessione FCM
```bash
curl http://localhost:3000/test-connection
```
Risposta attesa:
```json
{
  "success": true,
  "connected": true,
  "message": "Connessione FCM OK"
}
```

### 3. Test Notifica
```bash
curl -X POST http://localhost:3000/send-to-token \
  -H "Content-Type: application/json" \
  -d '{
    "token": "test-token",
    "title": "Test",
    "body": "Test notification"
  }'
```

## 🔧 Integrazione con Flutter

### Aggiorna il servizio FCM in Flutter

```dart
// lib/core/services/fcm_http_service.dart

class FCMHttpService {
  static const String _apiUrl = 'http://localhost:3000'; // Cambia con il tuo URL

  Future<bool> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/send-to-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': title,
          'body': body,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Errore nell\'invio notifica: $e');
      return false;
    }
  }
}
```

## 📊 Monitoraggio

### Logs
I log vengono salvati in:
- `logs/error.log` - Errori
- `logs/combined.log` - Tutti i log

### Metriche
- **Success Rate**: Percentuale notifiche inviate con successo
- **Token Validity**: Percentuale token validi
- **Response Time**: Tempo di risposta medio
- **Error Rate**: Tasso di errori

### Alerting
Configura alert per:
- Error rate > 5%
- Response time > 2s
- Service down

## 🔐 Sicurezza

### Best Practices
1. **Service Account**: Non committare mai il file JSON
2. **Environment Variables**: Usa variabili d'ambiente per configurazioni sensibili
3. **HTTPS**: Usa sempre HTTPS in produzione
4. **Rate Limiting**: Configura limiti appropriati
5. **CORS**: Limita le origini consentite

### Firewall
```bash
# Apri solo la porta necessaria
sudo ufw allow 3000/tcp
sudo ufw enable
```

## 🐛 Troubleshooting

### Problemi Comuni

#### 1. Errore "Service Account not found"
```bash
# Verifica che il file esista
ls -la firebase-service-account.json

# Verifica i permessi
chmod 600 firebase-service-account.json
```

#### 2. Errore "Invalid project ID"
```bash
# Verifica il project ID nel file .env
cat .env | grep FIREBASE_PROJECT_ID

# Verifica nel service account
cat firebase-service-account.json | grep project_id
```

#### 3. Errore "Permission denied"
```bash
# Verifica i permessi del service account
# Il service account deve avere il ruolo "Firebase Admin"
```

#### 4. Rate Limiting
```bash
# Aumenta i limiti se necessario
# Modifica le variabili d'ambiente
NOTIFICATION_RATE_LIMIT_MAX_REQUESTS=20
```

### Debug Mode
```bash
# Avvia in debug mode
DEBUG=* npm run dev

# Log dettagliati
LOG_LEVEL=debug npm start
```

## 📈 Performance

### Ottimizzazioni
1. **Connection Pooling**: Configurato automaticamente
2. **Token Caching**: Cache dei token di accesso
3. **Batch Processing**: Invio parallelo per multipli token
4. **Retry Logic**: Tentativi automatici in caso di errore

### Benchmark
- **Singola notifica**: ~100ms
- **100 notifiche**: ~2s
- **1000 notifiche**: ~15s

## 🔄 Aggiornamenti

### Aggiornamento Servizio
```bash
# Backup configurazione
cp .env .env.backup

# Pull aggiornamenti
git pull origin main

# Reinstalla dipendenze
npm install

# Restart servizio
pm2 restart invory-notification-service
# oppure
docker-compose restart notification-service
```

### Rollback
```bash
# Ripristina configurazione
cp .env.backup .env

# Restart con configurazione precedente
pm2 restart invory-notification-service
```

## 📞 Supporto

Per problemi o domande:
1. Controlla i log: `tail -f logs/error.log`
2. Verifica configurazione: `cat .env`
3. Test connessione: `curl http://localhost:3000/health`
4. Controlla Firebase Console per errori FCM

## 📚 Risorse

- [FCM HTTP v1 API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)
- [Google Auth Library](https://github.com/googleapis/google-auth-library-nodejs)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Express Rate Limiting](https://github.com/nfriedly/express-rate-limit) 