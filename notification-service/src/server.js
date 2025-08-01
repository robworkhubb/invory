import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import winston from 'winston';
import { FCMService } from './fcm-service.js';

// Configurazione logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'notification-service' },
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' }),
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});

// Configurazione rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuti
  max: 100, // massimo 100 richieste per finestra
  message: {
    error: 'Troppe richieste, riprova più tardi',
    retryAfter: '15 minuti'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limiting specifico per le notifiche
const notificationLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minuto
  max: 10, // massimo 10 notifiche al minuto per IP
  message: {
    error: 'Troppe notifiche inviate, riprova più tardi',
    retryAfter: '1 minuto'
  }
});

const app = express();
const PORT = process.env.PORT || 3000;

// Inizializza il servizio FCM
const fcmService = new FCMService();

// Middleware di sicurezza
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000', 'https://invory-b9a72.web.app'],
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(limiter);

// Middleware di logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });
  next();
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    service: 'invory-notification-service'
  });
});

// Test connessione FCM
app.get('/test-connection', async (req, res) => {
  try {
    const isConnected = await fcmService.testConnection();
    res.json({ 
      success: true, 
      connected: isConnected,
      message: isConnected ? 'Connessione FCM OK' : 'Connessione FCM fallita'
    });
  } catch (error) {
    logger.error('Errore nel test connessione:', error);
    res.status(500).json({ 
      success: false, 
      error: error.message 
    });
  }
});

// Invia notifica a un singolo token
app.post('/send-to-token', notificationLimiter, async (req, res) => {
  try {
    const { token, title, body, data } = req.body;
    
    if (!token || !title || !body) {
      return res.status(400).json({
        success: false,
        error: 'Token, title e body sono obbligatori'
      });
    }

    const result = await fcmService.sendToToken(token, { title, body }, data);
    
    if (result.success) {
      logger.info('Notifica inviata con successo', { token, title });
      res.json({ success: true, messageId: result.messageId });
    } else {
      logger.warn('Invio notifica fallito', { token, error: result.error });
      res.status(400).json({ success: false, error: result.error });
    }
  } catch (error) {
    logger.error('Errore nell\'invio notifica:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Invia notifica a un utente (tutti i suoi dispositivi)
app.post('/send-to-user', notificationLimiter, async (req, res) => {
  try {
    const { userId, title, body, data } = req.body;
    
    if (!userId || !title || !body) {
      return res.status(400).json({
        success: false,
        error: 'userId, title e body sono obbligatori'
      });
    }

    const result = await fcmService.sendToUser(userId, { title, body }, data);
    
    logger.info('Notifica inviata all\'utente', { 
      userId, 
      success: result.success, 
      failure: result.failure 
    });
    
    res.json({
      success: true,
      results: result
    });
  } catch (error) {
    logger.error('Errore nell\'invio notifica all\'utente:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Invia notifica per prodotto sotto soglia
app.post('/send-low-stock-notification', notificationLimiter, async (req, res) => {
  try {
    const { userId, product } = req.body;
    
    if (!userId || !product) {
      return res.status(400).json({
        success: false,
        error: 'userId e product sono obbligatori'
      });
    }

    const result = await fcmService.sendLowStockNotification(userId, product);
    
    logger.info('Notifica scorte basse inviata', { 
      userId, 
      productId: product.id,
      success: result.success, 
      failure: result.failure 
    });
    
    res.json({
      success: true,
      results: result
    });
  } catch (error) {
    logger.error('Errore nell\'invio notifica scorte basse:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Invia notifica a più token
app.post('/send-to-multiple-tokens', notificationLimiter, async (req, res) => {
  try {
    const { tokens, title, body, data } = req.body;
    
    if (!tokens || !Array.isArray(tokens) || !title || !body) {
      return res.status(400).json({
        success: false,
        error: 'tokens (array), title e body sono obbligatori'
      });
    }

    if (tokens.length > 100) {
      return res.status(400).json({
        success: false,
        error: 'Massimo 100 token per richiesta'
      });
    }

    const result = await fcmService.sendToMultipleTokens(tokens, { title, body }, data);
    
    logger.info('Notifica inviata a più token', { 
      tokenCount: tokens.length,
      success: result.success, 
      failure: result.failure 
    });
    
    res.json({
      success: true,
      results: result
    });
  } catch (error) {
    logger.error('Errore nell\'invio notifica a più token:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Gestione errori 404
app.use((req, res) => {
  res.status(404).json({ 
    success: false, 
    error: 'Endpoint non trovato' 
  });
});

// Gestione errori globali
app.use((error, req, res, next) => {
  logger.error('Errore non gestito:', error);
  res.status(500).json({ 
    success: false, 
    error: 'Errore interno del server' 
  });
});

// Avvia il server
async function startServer() {
  try {
    // Inizializza il servizio FCM
    await fcmService.initialize();
    
    app.listen(PORT, () => {
      logger.info(`🚀 Server avviato sulla porta ${PORT}`);
      logger.info(`📱 Servizio notifiche pronto`);
    });
  } catch (error) {
    logger.error('❌ Errore nell\'avvio del server:', error);
    process.exit(1);
  }
}

// Gestione graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM ricevuto, chiusura graceful...');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT ricevuto, chiusura graceful...');
  process.exit(0);
});

startServer(); 