const FCMService = require('./FCMService');
const winston = require('winston');

/**
 * Servizio di notifiche specifico per Invory
 * Gestisce le notifiche per prodotti sotto soglia o esauriti
 */
class InvoryNotificationService {
  constructor() {
    this.fcmService = new FCMService();
    
    // Configurazione logger
    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json()
      ),
      defaultMeta: { service: 'invory-notifications' },
      transports: [
        new winston.transports.File({ filename: 'logs/invory-error.log', level: 'error' }),
        new winston.transports.File({ filename: 'logs/invory-combined.log' }),
        new winston.transports.Console({
          format: winston.format.simple()
        })
      ]
    });
  }

  /**
   * Inizializza il servizio
   */
  async initialize() {
    try {
      await this.fcmService.initializeAuth();
      this.logger.info('Invory notification service initialized successfully');
      return true;
    } catch (error) {
      this.logger.error('Failed to initialize notification service', { error: error.message });
      throw error;
    }
  }

  /**
   * Notifica per prodotto sotto soglia
   */
  async notifyLowStock(product, userTokens) {
    try {
      const notification = {
        title: 'Scorte in Esaurimento',
        body: `${product.nome} ha raggiunto la soglia minima (${product.quantita}/${product.soglia})`
      };

      const data = {
        type: 'low_stock',
        productId: product.id,
        productName: product.nome,
        quantity: product.quantita.toString(),
        threshold: product.soglia.toString(),
        timestamp: new Date().toISOString()
      };

      const result = await this.fcmService.sendToMultipleTokens(userTokens, notification, data);
      
      this.logger.info('Low stock notification sent', {
        productId: product.id,
        productName: product.nome,
        success: result.success,
        failure: result.failure
      });

      // Pulisci i token non validi
      if (result.invalidTokens.length > 0) {
        await this.cleanupInvalidTokens(result.invalidTokens);
      }

      return result;
    } catch (error) {
      this.logger.error('Failed to send low stock notification', {
        productId: product.id,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Notifica per prodotto esaurito
   */
  async notifyOutOfStock(product, userTokens) {
    try {
      const notification = {
        title: 'Prodotto Esaurito!',
        body: `${product.nome} è completamente esaurito!`
      };

      const data = {
        type: 'out_of_stock',
        productId: product.id,
        productName: product.nome,
        quantity: '0',
        timestamp: new Date().toISOString()
      };

      const result = await this.fcmService.sendToMultipleTokens(userTokens, notification, data);
      
      this.logger.info('Out of stock notification sent', {
        productId: product.id,
        productName: product.nome,
        success: result.success,
        failure: result.failure
      });

      // Pulisci i token non validi
      if (result.invalidTokens.length > 0) {
        await this.cleanupInvalidTokens(result.invalidTokens);
      }

      return result;
    } catch (error) {
      this.logger.error('Failed to send out of stock notification', {
        productId: product.id,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Notifica automatica per cambiamento quantità prodotto
   */
  async notifyProductQuantityChange(product, previousQuantity, userTokens) {
    try {
      // Controlla se il prodotto è sotto soglia o esaurito
      if (product.quantita <= product.soglia) {
        if (product.quantita === 0) {
          return await this.notifyOutOfStock(product, userTokens);
        } else {
          return await this.notifyLowStock(product, userTokens);
        }
      }

      this.logger.info('Product quantity change - no notification needed', {
        productId: product.id,
        currentQuantity: product.quantita,
        threshold: product.soglia,
        previousQuantity
      });

      return { success: true, message: 'No notification needed' };
    } catch (error) {
      this.logger.error('Failed to process product quantity change notification', {
        productId: product.id,
        error: error.message
      });
      throw error;
    }
  }

  /**
   * Notifica di test
   */
  async sendTestNotification(userTokens, message = 'Test notification from Invory') {
    try {
      const notification = {
        title: 'Test Notifica',
        body: message
      };

      const data = {
        type: 'test',
        timestamp: new Date().toISOString()
      };

      const result = await this.fcmService.sendToMultipleTokens(userTokens, notification, data);
      
      this.logger.info('Test notification sent', {
        success: result.success,
        failure: result.failure
      });

      return result;
    } catch (error) {
      this.logger.error('Failed to send test notification', { error: error.message });
      throw error;
    }
  }

  /**
   * Pulisce i token non validi dal database
   */
  async cleanupInvalidTokens(invalidTokens) {
    try {
      // Implementa la logica per rimuovere i token dal database
      // Questo è un esempio - adatta alla tua struttura dati
      
      this.logger.info('Cleaning up invalid tokens', { count: invalidTokens.length });
      
      // Esempio con Firestore (se usi Firebase)
      // const admin = require('firebase-admin');
      // const db = admin.firestore();
      
      // for (const token of invalidTokens) {
      //   const tokenRefs = await db.collectionGroup('fcmTokens')
      //     .where('token', '==', token)
      //     .get();
      
      //   const batch = db.batch();
      //   tokenRefs.docs.forEach(doc => batch.delete(doc.ref));
      //   await batch.commit();
      // }

      return true;
    } catch (error) {
      this.logger.error('Failed to cleanup invalid tokens', { error: error.message });
      return false;
    }
  }

  /**
   * Ottiene i token FCM di un utente dal database
   */
  async getUserTokens(userId) {
    try {
      // Implementa la logica per recuperare i token dal database
      // Questo è un esempio - adatta alla tua struttura dati
      
      // Esempio con Firestore
      // const admin = require('firebase-admin');
      // const db = admin.firestore();
      
      // const tokensSnapshot = await db
      //   .collection('users')
      //   .doc(userId)
      //   .collection('fcmTokens')
      //   .where('isActive', '==', true)
      //   .get();
      
      // return tokensSnapshot.docs.map(doc => doc.data().token);

      // Per ora, restituisce un array vuoto
      return [];
    } catch (error) {
      this.logger.error('Failed to get user tokens', { userId, error: error.message });
      return [];
    }
  }

  /**
   * Testa il servizio completo
   */
  async testService() {
    try {
      const results = {
        fcmConnection: false,
        testNotification: false
      };

      // Test connessione FCM
      results.fcmConnection = await this.fcmService.testConnection();

      // Test notifica (con token di test se disponibili)
      const testTokens = process.env.TEST_FCM_TOKENS ? 
        process.env.TEST_FCM_TOKENS.split(',') : [];
      
      if (testTokens.length > 0) {
        const testResult = await this.sendTestNotification(testTokens);
        results.testNotification = testResult.success > 0;
      }

      this.logger.info('Service test completed', results);
      return results;
    } catch (error) {
      this.logger.error('Service test failed', { error: error.message });
      throw error;
    }
  }
}

module.exports = InvoryNotificationService; 