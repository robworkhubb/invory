import { GoogleAuth } from 'google-auth-library';
import fetch from 'node-fetch';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Servizio FCM moderno che utilizza l'API HTTP v1 di Firebase Cloud Messaging
 * Con autenticazione OAuth2 e gestione avanzata degli errori
 */
export class FCMService {
  constructor() {
    this.auth = null;
    this.projectId = null;
    this.accessToken = null;
    this.tokenExpiry = null;
    this.baseUrl = 'https://fcm.googleapis.com/v1/projects';
    this.retryAttempts = 3;
    this.retryDelay = 1000; // 1 secondo
  }

  /**
   * Inizializza il servizio con le credenziali del service account
   */
  async initialize() {
    try {
      // Carica le credenziali del service account
      const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');
      const serviceAccount = JSON.parse(await fs.readFile(serviceAccountPath, 'utf8'));
      
      this.projectId = serviceAccount.project_id;
      
      // Crea l'autenticatore Google Auth
      this.auth = new GoogleAuth({
        credentials: serviceAccount,
        scopes: ['https://www.googleapis.com/auth/firebase.messaging']
      });

      // Ottieni il token di accesso iniziale
      await this.refreshAccessToken();
      
      console.log(`✅ FCM Service inizializzato per il progetto: ${this.projectId}`);
      return true;
    } catch (error) {
      console.error('❌ Errore nell\'inizializzazione del FCM Service:', error);
      throw error;
    }
  }

  /**
   * Aggiorna il token di accesso se necessario
   */
  async refreshAccessToken() {
    try {
      if (!this.auth) {
        throw new Error('Servizio FCM non inizializzato');
      }

      const client = await this.auth.getClient();
      const tokenResponse = await client.getAccessToken();
      
      this.accessToken = tokenResponse.token;
      this.tokenExpiry = Date.now() + (tokenResponse.res?.data?.expires_in * 1000) || Date.now() + 3600000;
      
      console.log('🔄 Token di accesso aggiornato');
    } catch (error) {
      console.error('❌ Errore nell\'aggiornamento del token:', error);
      throw error;
    }
  }

  /**
   * Verifica se il token è ancora valido
   */
  isTokenValid() {
    return this.accessToken && this.tokenExpiry && Date.now() < this.tokenExpiry - 60000; // 1 minuto di margine
  }

  /**
   * Invia una notifica a un singolo device token
   */
  async sendToToken(token, notification, data = {}) {
    const message = {
      message: {
        token,
        notification,
        data,
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            priority: 'high'
          }
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        },
        webpush: {
          notification: {
            icon: '/icons/Icon-192.png',
            badge: '/icons/Icon-192.png',
            requireInteraction: true
          }
        }
      }
    };

    return this.sendMessage(message);
  }

  /**
   * Invia una notifica a più device token
   */
  async sendToMultipleTokens(tokens, notification, data = {}) {
    const results = {
      success: 0,
      failure: 0,
      invalidTokens: [],
      errors: []
    };

    // FCM v1 supporta solo un token per richiesta, quindi inviamo in parallelo
    const promises = tokens.map(async (token) => {
      try {
        const result = await this.sendToToken(token, notification, data);
        if (result.success) {
          results.success++;
        } else {
          results.failure++;
          if (result.error?.includes('InvalidRegistration') || result.error?.includes('NotRegistered')) {
            results.invalidTokens.push(token);
          }
          results.errors.push({ token, error: result.error });
        }
      } catch (error) {
        results.failure++;
        results.errors.push({ token, error: error.message });
      }
    });

    await Promise.allSettled(promises);
    return results;
  }

  /**
   * Invia una notifica a un utente specifico (tutti i suoi dispositivi)
   */
  async sendToUser(userId, notification, data = {}) {
    try {
      // Importa Firebase Admin per accedere a Firestore
      const { initializeApp, cert } = await import('firebase-admin/app');
      const { getFirestore } = await import('firebase-admin/firestore');
      
      // Inizializza Firebase Admin se non è già inizializzato
      if (!global.firebaseAdminInitialized) {
        const serviceAccount = JSON.parse(
          await fs.readFile(path.join(__dirname, '../../firebase-service-account.json'), 'utf8')
        );
        
        initializeApp({
          credential: cert(serviceAccount)
        });
        
        global.firebaseAdminInitialized = true;
      }

      const db = getFirestore();
      
      // Recupera tutti i token FCM dell'utente
      const tokensSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('fcmTokens')
        .where('isActive', '==', true)
        .get();

      if (tokensSnapshot.empty) {
        console.log(`📱 Nessun token trovato per l'utente: ${userId}`);
        return { success: 0, failure: 0, invalidTokens: [], errors: [] };
      }

      const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
      console.log(`📱 Invio notifica a ${tokens.length} dispositivi per l'utente: ${userId}`);

      const results = await this.sendToMultipleTokens(tokens, notification, data);

      // Rimuovi i token non validi
      if (results.invalidTokens.length > 0) {
        await this.removeInvalidTokens(userId, results.invalidTokens);
      }

      return results;
    } catch (error) {
      console.error(`❌ Errore nell'invio notifica all'utente ${userId}:`, error);
      throw error;
    }
  }

  /**
   * Rimuove i token non validi da Firestore
   */
  async removeInvalidTokens(userId, invalidTokens) {
    try {
      const { getFirestore } = await import('firebase-admin/firestore');
      const db = getFirestore();
      
      const batch = db.batch();
      
      invalidTokens.forEach(token => {
        const tokenRef = db
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token);
        batch.update(tokenRef, { isActive: false });
      });

      await batch.commit();
      console.log(`🗑️ Rimossi ${invalidTokens.length} token non validi per l'utente: ${userId}`);
    } catch (error) {
      console.error('❌ Errore nella rimozione dei token non validi:', error);
    }
  }

  /**
   * Invia il messaggio usando l'API HTTP v1
   */
  async sendMessage(message) {
    if (!this.isTokenValid()) {
      await this.refreshAccessToken();
    }

    const url = `${this.baseUrl}/${this.projectId}/messages:send`;
    
    for (let attempt = 1; attempt <= this.retryAttempts; attempt++) {
      try {
        const response = await fetch(url, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this.accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(message)
        });

        if (response.ok) {
          const result = await response.json();
          return { success: true, messageId: result.name };
        } else {
          const errorData = await response.json();
          const error = errorData.error || {};
          
          // Gestisci errori specifici
          if (error.code === 401) {
            // Token scaduto, aggiorna e riprova
            await this.refreshAccessToken();
            continue;
          } else if (error.code === 400) {
            // Errore di validazione, non riprovare
            return { 
              success: false, 
              error: error.message || 'Errore di validazione',
              code: error.code 
            };
          } else if (error.code === 429) {
            // Rate limit, aspetta e riprova
            const delay = Math.pow(2, attempt) * this.retryDelay;
            await new Promise(resolve => setTimeout(resolve, delay));
            continue;
          } else {
            // Altri errori, riprova se possibile
            if (attempt === this.retryAttempts) {
              return { 
                success: false, 
                error: error.message || 'Errore sconosciuto',
                code: error.code 
              };
            }
            continue;
          }
        }
      } catch (error) {
        if (attempt === this.retryAttempts) {
          return { 
            success: false, 
            error: error.message || 'Errore di rete',
            code: 'NETWORK_ERROR' 
          };
        }
        
        // Aspetta prima di riprovare
        await new Promise(resolve => setTimeout(resolve, this.retryDelay * attempt));
      }
    }

    return { 
      success: false, 
      error: 'Numero massimo di tentativi raggiunto',
      code: 'MAX_RETRIES' 
    };
  }

  /**
   * Invia notifica per prodotto sotto soglia
   */
  async sendLowStockNotification(userId, product) {
    const title = product.quantita === 0 ? 'Prodotto Esaurito!' : 'Scorte in Esaurimento';
    const body = product.quantita === 0
      ? `${product.nome} è esaurito!`
      : `${product.nome} ha raggiunto la soglia minima (${product.quantita}/${product.soglia})`;

    const notification = {
      title,
      body
    };

    const data = {
      type: product.quantita === 0 ? 'out_of_stock' : 'low_stock',
      productId: product.id,
      productName: product.nome,
      timestamp: Date.now().toString()
    };

    return this.sendToUser(userId, notification, data);
  }

  /**
   * Testa la connessione al servizio FCM
   */
  async testConnection() {
    try {
      const testMessage = {
        message: {
          token: 'test-token',
          notification: {
            title: 'Test',
            body: 'Test'
          }
        }
      };

      const result = await this.sendMessage(testMessage);
      // Ci aspettiamo un errore di token non valido, ma questo conferma che la connessione funziona
      return result.error?.includes('InvalidArgument') || result.error?.includes('InvalidRegistration');
    } catch (error) {
      console.error('❌ Test connessione fallito:', error);
      return false;
    }
  }
} 