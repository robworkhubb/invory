import { GoogleAuth } from 'google-auth-library';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Generatore di token di accesso OAuth2 per FCM HTTP v1 API
 * Questo servizio genera manualmente i token senza usare firebase-admin
 */
export class TokenGenerator {
  constructor() {
    this.auth = null;
    this.accessToken = null;
    this.tokenExpiry = null;
  }

  /**
   * Inizializza il generatore con le credenziali del service account
   */
  async initialize() {
    try {
      // Carica le credenziali del service account
      const serviceAccountPath = path.join(__dirname, '../../firebase-service-account.json');
      const serviceAccount = JSON.parse(await fs.readFile(serviceAccountPath, 'utf8'));
      
      // Crea l'autenticatore Google Auth
      this.auth = new GoogleAuth({
        credentials: serviceAccount,
        scopes: ['https://www.googleapis.com/auth/firebase.messaging']
      });

      console.log('✅ Token Generator inizializzato');
      return true;
    } catch (error) {
      console.error('❌ Errore nell\'inizializzazione del Token Generator:', error);
      throw error;
    }
  }

  /**
   * Genera un nuovo token di accesso
   */
  async generateAccessToken() {
    try {
      if (!this.auth) {
        throw new Error('Token Generator non inizializzato');
      }

      const client = await this.auth.getClient();
      const tokenResponse = await client.getAccessToken();
      
      this.accessToken = tokenResponse.token;
      this.tokenExpiry = Date.now() + (tokenResponse.res?.data?.expires_in * 1000) || Date.now() + 3600000;
      
      console.log('🔄 Nuovo token di accesso generato');
      return this.accessToken;
    } catch (error) {
      console.error('❌ Errore nella generazione del token:', error);
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
   * Ottieni il token corrente, generandone uno nuovo se necessario
   */
  async getValidToken() {
    if (!this.isTokenValid()) {
      await this.generateAccessToken();
    }
    return this.accessToken;
  }

  /**
   * Invia una richiesta HTTP con autenticazione automatica
   */
  async makeAuthenticatedRequest(url, options = {}) {
    const token = await this.getValidToken();
    
    const requestOptions = {
      ...options,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        ...options.headers
      }
    };

    return fetch(url, requestOptions);
  }

  /**
   * Testa l'invio di una notifica usando il token generato manualmente
   */
  async testNotification(projectId, token) {
    try {
      const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
      
      const message = {
        message: {
          token,
          notification: {
            title: 'Test Manual Token',
            body: 'Notifica inviata con token generato manualmente'
          },
          data: {
            type: 'test',
            timestamp: Date.now().toString()
          }
        }
      };

      const response = await this.makeAuthenticatedRequest(url, {
        method: 'POST',
        body: JSON.stringify(message)
      });

      if (response.ok) {
        const result = await response.json();
        return { success: true, messageId: result.name };
      } else {
        const errorData = await response.json();
        return { 
          success: false, 
          error: errorData.error?.message || 'Errore sconosciuto',
          code: errorData.error?.code 
        };
      }
    } catch (error) {
      return { 
        success: false, 
        error: error.message,
        code: 'NETWORK_ERROR' 
      };
    }
  }
}

/**
 * Esempio di utilizzo del Token Generator
 */
async function example() {
  console.log('🔑 Esempio di utilizzo del Token Generator\n');
  
  const tokenGenerator = new TokenGenerator();
  
  try {
    // Inizializza
    await tokenGenerator.initialize();
    
    // Genera un token
    const token = await tokenGenerator.generateAccessToken();
    console.log('Token generato:', token.substring(0, 50) + '...');
    
    // Verifica validità
    const isValid = tokenGenerator.isTokenValid();
    console.log('Token valido:', isValid);
    
    // Test notifica (con projectId e token di test)
    const projectId = 'invory-b9a72';
    const testToken = 'test-token-123';
    
    const result = await tokenGenerator.testNotification(projectId, testToken);
    console.log('Test notifica:', result);
    
  } catch (error) {
    console.error('Errore nell\'esempio:', error);
  }
}

// Esegui l'esempio se il file viene chiamato direttamente
if (import.meta.url === `file://${process.argv[1]}`) {
  example();
} 