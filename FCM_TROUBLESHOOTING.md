# FCM Troubleshooting Guide

## Problema: "Nessun token trovato per l'utente"

### Errore identificato:
```
AbortError: Failed to execute 'subscribe' on 'PushManager': Subscription failed - no active Service Worker
```

### Causa:
Il Service Worker non è registrato correttamente per le notifiche push FCM.

### Soluzioni:

#### 1. Verifica Service Worker
- Apri DevTools (F12)
- Vai su Application > Service Workers
- Verifica che il service worker sia registrato e attivo

#### 2. Registrazione Service Worker
Il service worker deve essere registrato prima di richiedere i permessi FCM.

#### 3. Ordine di inizializzazione
1. Registra il service worker
2. Richiedi i permessi
3. Ottieni il token FCM

### Debug Steps:
1. Usa il pulsante di debug nella dashboard (icona bug)
2. Verifica i token salvati
3. Usa il pulsante "Refresh" per forzare un nuovo token

### Log da monitorare:
- "Inizializzazione FCM..."
- "Stato autorizzazione FCM: AuthorizationStatus.authorized"
- "Token FCM ottenuto: ..."
- "Token FCM salvato con successo in Firestore"

### Configurazione richiesta:
- Firebase config corretto
- Service worker registrato
- Permessi concessi
- Connessione internet attiva 

##  Risoluzione Problema Sicurezza GitHub

### 1. **Rimuovi le Credenziali dal Repository**

```bash
# 1. Rimuovi il file delle credenziali dal tracking Git
git rm --cached invory-b9a72-firebase-adminsdk-fbsvc-7f58979a15.json

# 2. Aggiungi il file al .gitignore
echo "invory-b9a72-firebase-adminsdk-fbsvc-7f58979a15.json" >> .gitignore
echo "*.json" >> .gitignore

# 3. Commit le modifiche
git add .gitignore
git commit -m "Remove Firebase credentials and update .gitignore"

# 4. Prova a pushare di nuovo
git push -u origin main
```

### 2. **Configurazione Sicura per Railway**

Ora dobbiamo configurare le credenziali Firebase come variabili d'ambiente su Railway invece di usare il file JSON.

Crea un file `notification-service/src/config/firebase-admin.js`:

```javascript
<code_block_to_apply_changes_from>
```

### 3. **Aggiorna il Servizio di Notifiche**

Modifica `notification-service/src/services/InvoryNotificationService.js`:

```javascript
const admin = require('../config/firebase-admin');
const db = admin.firestore();

// Nel metodo saveToken
async saveToken(token, platform = 'web', userId = null) {
  try {
    if (userId) {
      // Salva nel database Firebase
      await db.collection('users').doc(userId)
        .collection('fcmTokens').doc(token)
        .set({
          token: token,
          platform: platform,
          lastUsed: admin.firestore.FieldValue.serverTimestamp(),
          isActive: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      
      this.logger.info('Token saved to Firebase', {
        token: token.substring(0, 20) + '...',
        platform,
        userId
      });
    }
    
    return { success: true };
  } catch (error) {
    this.logger.error('Failed to save token', { error: error.message });
    throw error;
  }
}

// Aggiungi metodo per ottenere token da Firebase
async getUserTokens(userId) {
  try {
    const tokensSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('fcmTokens')
      .where('isActive', '==', true)
      .get();
    
    return tokensSnapshot.docs.map(doc => doc.id);
  } catch (error) {
    this.logger.error('Failed to get user tokens', { userId, error: error.message });
    return [];
  }
}
```

### 4. **Estrai le Credenziali dal File JSON**

Dal file `invory-b9a72-firebase-adminsdk-fbsvc-7f58979a15.json`, estrai questi valori:

```bash
# Leggi il file JSON per estrarre le credenziali
cat invory-b9a72-firebase-adminsdk-fbsvc-7f58979a15.json
```

### 5. **Deploy su Railway con Variabili d'Ambiente**

```bash
# 1. Installa Railway CLI
npm install -g @railway/cli

# 2. Login su Railway
railway login

# 3. Crea un nuovo progetto
railway init

# 4. Collega il repository
railway link

# 5. Configura le variabili d'ambiente (sostituisci con i tuoi valori reali)
railway variables set FIREBASE_PROJECT_ID=invory-b9a72
railway variables set FIREBASE_PRIVATE_KEY_ID=your_private_key_id
railway variables set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY\n-----END PRIVATE KEY-----\n"
railway variables set FIREBASE_CLIENT_EMAIL=firebase-adminsdk-fbsvc@invory-b9a72.iam.gserviceaccount.com
railway variables set FIREBASE_CLIENT_ID=your_client_id
railway variables set FIREBASE_CLIENT_X509_CERT_URL=https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40invory-b9a72.iam.gserviceaccount.com
railway variables set API_KEY=790f63ac0c4d020fe9facf85cbba85cfce14f5e81d5d828e160e3ea61c414ee0

# 6. Deploy
railway up
```

### 6. **Comandi per Risolvere il Problema GitHub**

Esegui questi comandi nella cartella `notification-service`:

```bash
# 1. Rimuovi il file delle credenziali dal tracking
git rm --cached invory-b9a72-firebase-adminsdk-fbsvc-7f58979a15.json

# 2. Aggiorna .gitignore
echo "invory-b9a72-firebase-adminsdk-fbsvc-7f58979a15.json" >> .gitignore
echo "*.json" >> .gitignore
echo "node_modules/" >> .gitignore
echo ".env" >> .gitignore

# 3. Commit le modifiche
git add .gitignore
git commit -m "Remove Firebase credentials and update .gitignore"

# 4. Push
git push -u origin main
```

### 7. **Test del Deploy**

Dopo il deploy su Railway, testa il servizio:

```bash
# Test health check
curl https://your-railway-app.up.railway.app/health

# Test notifica
curl -X POST https://your-railway-app.up.railway.app/test \
  -H "Content-Type: application/json" \
  -H "x-api-key: 790f63ac0c4d020fe9facf85cbba85cfce14f5e81d5d828e160e3ea61c414ee0" \
  -d '{"tokens":["test-token"],"message":"Test notification"}'
```

Vuoi che proceda con l'estrazione delle credenziali dal file JSON o preferisci farlo tu manualmente? 