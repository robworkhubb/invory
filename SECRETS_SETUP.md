# 🔐 Configurazione Secrets GitHub

Questo file contiene le istruzioni per configurare i secrets necessari per il deploy automatico su GitHub Pages.

## 📋 Secrets Richiesti

Configura i seguenti secrets nel tuo repository GitHub:

### 🔥 Firebase Configuration

1. **FIREBASE_API_KEY**
   - Vai su [Firebase Console](https://console.firebase.google.com)
   - Seleziona il tuo progetto
   - Vai su Project Settings > General
   - Copia la "Web API Key"

2. **FIREBASE_AUTH_DOMAIN**
   - Nello stesso Project Settings
   - Copia il "Authorized domain" (es: `invory-b9a72.firebaseapp.com`)

3. **FIREBASE_PROJECT_ID**
   - Il Project ID del tuo progetto Firebase (es: `invory-b9a72`)

4. **FIREBASE_STORAGE_BUCKET**
   - Il bucket di storage (es: `invory-b9a72.firebasestorage.app`)

5. **FIREBASE_MESSAGING_SENDER_ID**
   - Il Sender ID per le notifiche (es: `524552556806`)

6. **FIREBASE_APP_ID**
   - L'App ID della tua app web Firebase

7. **FIREBASE_MEASUREMENT_ID**
   - L'ID di Google Analytics (es: `G-MTDPNYBZG4`)

### 🔔 FCM Configuration

8. **VAPID_KEY**
   - Vai su Project Settings > Cloud Messaging
   - Nella sezione "Web configuration"
   - Genera una nuova chiave VAPID o usa quella esistente

9. **FCM_PROJECT_ID**
   - Stesso valore di FIREBASE_PROJECT_ID

10. **FCM_CLIENT_EMAIL**
    - Vai su Project Settings > Service Accounts
    - Crea un nuovo service account o usa quello esistente
    - Copia l'email del service account

11. **FCM_PRIVATE_KEY**
    - Nello stesso service account
    - Genera una nuova chiave privata
    - Copia l'intera chiave (inclusi i `-----BEGIN PRIVATE KEY-----` e `-----END PRIVATE KEY-----`)

## 🛠️ Come Configurare i Secrets

1. Vai nel tuo repository GitHub
2. Clicca su **Settings**
3. Nel menu laterale, clicca su **Secrets and variables** > **Actions**
4. Clicca su **New repository secret**
5. Aggiungi ogni secret con il nome e valore corrispondenti

## 📝 Esempio di Configurazione

```bash
# Firebase Configuration
FIREBASE_API_KEY=AIzaSyDjoMnOeETgX5-8U97I_HjgJFI8NxItAcg
FIREBASE_AUTH_DOMAIN=invory-b9a72.firebaseapp.com
FIREBASE_PROJECT_ID=invory-b9a72
FIREBASE_STORAGE_BUCKET=invory-b9a72.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=524552556806
FIREBASE_APP_ID=1:524552556806:web:4bae50045374103e684e87
FIREBASE_MEASUREMENT_ID=G-MTDPNYBZG4

# FCM Configuration
VAPID_KEY=YOUR_VAPID_KEY_HERE
FCM_PROJECT_ID=invory-b9a72
FCM_CLIENT_EMAIL=firebase-adminsdk-xxxxx@invory-b9a72.iam.gserviceaccount.com
FCM_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----
```

## 🔍 Verifica Configurazione

Dopo aver configurato tutti i secrets:

1. Fai un push sulla branch `main`
2. Vai su **Actions** nel tuo repository
3. Verifica che il workflow "Deploy to GitHub Pages" si esegua correttamente
4. Controlla i log per eventuali errori

## 🚨 Note Importanti

- **FCM_PRIVATE_KEY**: Deve includere i caratteri di escape `\n` per le nuove righe
- **VAPID_KEY**: Deve essere generata specificamente per il tuo dominio
- **FCM_CLIENT_EMAIL**: Deve avere i permessi necessari per inviare notifiche
- **Sicurezza**: Non condividere mai questi secrets pubblicamente

## 🐛 Troubleshooting

### Errore "Secret not found"
- Verifica che tutti i secrets siano configurati correttamente
- Controlla che i nomi dei secrets corrispondano esattamente a quelli nel workflow

### Errore "Invalid API key"
- Verifica che la FIREBASE_API_KEY sia corretta
- Controlla che il progetto Firebase sia configurato correttamente

### Errore "VAPID key invalid"
- Genera una nuova chiave VAPID
- Verifica che sia associata al dominio corretto

### Errore "Service account not found"
- Verifica che il FCM_CLIENT_EMAIL sia corretto
- Controlla che il service account abbia i permessi necessari

## 📞 Supporto

Se hai problemi con la configurazione:
1. Controlla i log del workflow GitHub Actions
2. Verifica la configurazione Firebase
3. Apri una issue nel repository

---

**Invory** - Configurazione Secrets 🔐 