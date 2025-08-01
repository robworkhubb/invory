const { GoogleAuth } = require('google-auth-library');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const winston = require('winston');

/**
 * Servizio FCM moderno che utilizza l'API HTTP v1
 * Gestisce l'autenticazione OAuth2 e l'invio di notifiche push
 */
class FCMService {
  constructor() {
    this.projectId = process.env.FIREBASE_PROJECT_ID;
    this.serviceAccountPath = path.join(process.cwd(), 'firebase-service-account.json');
    this.accessToken = null;
    this.tokenExpiry = null;
    
    // Configurazione logger
    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
      ),
      defaultMeta: { service: 'fcm-service' },
      transports: [
        new winston.transports.File({ filename: 'logs/fcm-error.log', level: 'error' }),
        new winston.transports.File({ filename: 'logs/fcm-combined.log' }),
        new winston.transports.Console({
          format: winston.format.simple()
        })
      ]
    });

    // Inizializza l'autenticazione
    this.initializeAuth();
  }

  /**
   * Inizializza l'autenticazione Google OAuth2
   */
  async initializeAuth() {
    try {
      if (!fs.existsSync(this.serviceAccountPath)) {
        throw new Error(`Service account file not found: ${this.serviceAccountPath}`);
      }

      const serviceAccount = JSON.parse(fs.readFileSync(this.serviceAccountPath, 'utf8'));
      
      this.auth = new GoogleAuth({
        credentials: serviceAccount,
        scopes: ['https://www.googleapis.com/auth/firebase.messaging']
      });

      this.logger.info('FCM authentication initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize FCM authentication', { error: error.message });
      throw error;
    }
  }

  /**
   * Ottiene un access token valido (con cache e refresh automatico)
   */
  async getAccessToken() {
    try {
      // Controlla se il token è ancora valido (con margine di 5 minuti)
      if (this.accessToken && this.tokenExpiry && Date.now() < this.tokenExpiry - 300000) {
        return this.accessToken;
      }

      // Ottieni un nuovo token
      const client = await this.auth.getClient();
      const tokenResponse = await client.getAccessToken();
      
      this.accessToken = tokenResponse.token;
      // Gestisci sia la vecchia che la nuova struttura della risposta
      const expiresIn = tokenResponse.res?.data?.expires_in || tokenResponse.expires_in || 3600;
      this.tokenExpiry = Date.now() + (expiresIn * 1000);
      
      this.logger.info('New access token obtained', { 
        expiresIn: expiresIn 
      });
      
      return this.accessToken;
    } catch (error) {
      this.logger.error('Failed to get access token', { error: error.message });
      throw error;
    }
  }

  /**
   * Invia una notifica a un singolo device token
   */
  async sendToToken(token, notification, data = {}) {
    try {
      const accessToken = await this.getAccessToken();
      
      const message = {
        message: {
          token: token,
          notification: {
            title: notification.title,
            body: notification.body
          },
          data: data,
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channel_id: 'invory_notifications'
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
            headers: {
              Urgency: 'high'
            },
            notification: {
              icon: '/icons/Icon-192.png',
              badge: '/icons/Icon-192.png',
              requireInteraction: true
            }
          }
        }
      };

      const response = await axios.post(
        `https://fcm.googleapis.com/v1/projects/${this.projectId}/messages:send`,
        message,
        {
          headers: {
            'Authorization': `Bearer ${accessToken}`,
            'Content-Type': 'application/json'
          }
        }
      );

      this.logger.info('Notification sent successfully', {
        token: token.substring(0, 20) + '...',
        messageId: response.data.name
      });

      return {
        success: true,
        messageId: response.data.name
      };
    } catch (error) {
      this.handleFCMError(error, token);
      return {
        success: false,
        error: error.response?.data?.error?.message || error.message
      };
    }
  }

  /**
   * Invia notifiche a più device token (batch)
   */
  async sendToMultipleTokens(tokens, notification, data = {}) {
    const results = {
      success: 0,
      failure: 0,
      invalidTokens: [],
      errors: []
    };

    // Processa i token in batch di 500 (limite FCM)
    const batchSize = 500;
    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);
      
      const promises = batch.map(token => 
        this.sendToToken(token, notification, data)
      );

      const batchResults = await Promise.allSettled(promises);
      
      batchResults.forEach((result, index) => {
        if (result.status === 'fulfilled' && result.value.success) {
          results.success++;
        } else {
          results.failure++;
          const token = batch[index];
          results.invalidTokens.push(token);
          
          if (result.status === 'rejected') {
            results.errors.push({
              token: token.substring(0, 20) + '...',
              error: result.reason.message
            });
          } else if (result.value.error) {
            results.errors.push({
              token: token.substring(0, 20) + '...',
              error: result.value.error
            });
          }
        }
      });
    }

    this.logger.info('Batch notification completed', {
      total: tokens.length,
      success: results.success,
      failure: results.failure
    });

    return results;
  }

  /**
   * Invia notifica a tutti i dispositivi di un utente
   */
  async sendToUser(userId, notification, data = {}) {
    try {
      // Qui dovresti recuperare i token dall'utente dal database
      // Per ora, assumiamo che i token siano passati nei data
      const userTokens = data.userTokens || [];
      
      if (userTokens.length === 0) {
        this.logger.warn('No tokens found for user', { userId });
        return {
          success: false,
          error: 'No device tokens found for user'
        };
      }

      return await this.sendToMultipleTokens(userTokens, notification, data);
    } catch (error) {
      this.logger.error('Failed to send notification to user', {
        userId,
        error: error.message
      });
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Gestisce gli errori FCM comuni
   */
  handleFCMError(error, token) {
    const errorCode = error.response?.data?.error?.code;
    const errorMessage = error.response?.data?.error?.message;

    switch (errorCode) {
      case 400:
        this.logger.error('Invalid request', { token: token.substring(0, 20) + '...', errorMessage });
        break;
      case 401:
        this.logger.error('Authentication failed - token may be expired');
        // Forza il refresh del token
        this.accessToken = null;
        this.tokenExpiry = null;
        break;
      case 403:
        this.logger.error('Permission denied - check service account permissions');
        break;
      case 404:
        this.logger.error('Token not found or invalid', { token: token.substring(0, 20) + '...' });
        break;
      case 429:
        this.logger.error('Rate limit exceeded - implement backoff strategy');
        break;
      default:
        this.logger.error('FCM error', { 
          code: errorCode, 
          message: errorMessage,
          token: token.substring(0, 20) + '...'
        });
    }
  }

  /**
   * Testa la connessione FCM
   */
  async testConnection() {
    try {
      const accessToken = await this.getAccessToken();
      this.logger.info('FCM connection test successful');
      return true;
    } catch (error) {
      this.logger.error('FCM connection test failed', { error: error.message });
      return false;
    }
  }

  /**
   * Pulisce i token non validi
   */
  async cleanupInvalidTokens(invalidTokens) {
    try {
      // Qui implementeresti la logica per rimuovere i token dal database
      this.logger.info('Cleaning up invalid tokens', { count: invalidTokens.length });
      
      // Esempio di implementazione con database
      // await db.collection('users').doc(userId).collection('fcmTokens')
      //   .where('token', 'in', invalidTokens)
      //   .get()
      //   .then(snapshot => {
      //     const batch = db.batch();
      //     snapshot.docs.forEach(doc => batch.delete(doc.ref));
      //     return batch.commit();
      //   });

      return true;
    } catch (error) {
      this.logger.error('Failed to cleanup invalid tokens', { error: error.message });
      return false;
    }
  }
}

module.exports = FCMService; 