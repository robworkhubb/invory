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