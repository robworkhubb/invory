const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { RateLimiterMemory } = require('rate-limiter-flexible');
const winston = require('winston');
require('dotenv').config();

const InvoryNotificationService = require('./services/InvoryNotificationService');

// Configurazione logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'invory-api' },
  transports: [
    new winston.transports.File({ filename: 'logs/api-error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/api-combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

// Configurazione rate limiter
const rateLimiter = new RateLimiterMemory({
  keyGenerator: (req) => req.ip,
  points: 100, // Numero di richieste
  duration: 60, // Per 60 secondi
});

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware di sicurezza
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : ['http://localhost:3000'],
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));

// Middleware di logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`, {
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });
  next();
});

// Middleware rate limiting
app.use(async (req, res, next) => {
  try {
    await rateLimiter.consume(req.ip);
    next();
  } catch (error) {
    logger.warn('Rate limit exceeded', { ip: req.ip });
    res.status(429).json({
      error: 'Too many requests',
      retryAfter: error.msBeforeNext / 1000
    });
  }
});

// Inizializza il servizio di notifiche
const notificationService = new InvoryNotificationService();

// Middleware di autenticazione (esempio)
const authenticateRequest = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  
  if (!apiKey || apiKey !== process.env.API_KEY) {
    logger.warn('Unauthorized request', { ip: req.ip });
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  next();
};

// Health check
app.get('/health', async (req, res) => {
  try {
    const isHealthy = await notificationService.testService();
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: isHealthy
    });
  } catch (error) {
    logger.error('Health check failed', { error: error.message });
    res.status(503).json({
      status: 'unhealthy',
      error: error.message
    });
  }
});

// Salva token FCM
app.post('/save-token', authenticateRequest, async (req, res) => {
  try {
    const { token, platform, userId } = req.body;
    
    if (!token) {
      return res.status(400).json({ error: 'Token is required' });
    }

    // Salva il token nel database Firebase
    const result = await notificationService.saveToken(token, platform, userId);
    res.json({ success: true, message: 'Token saved successfully' });
  } catch (error) {
    logger.error('Save token failed', { error: error.message });
    res.status(500).json({ error: error.message });
  }
});

// Test del servizio
app.post('/test', authenticateRequest, async (req, res) => {
  try {
    const { tokens, message } = req.body;
    
    if (!tokens || !Array.isArray(tokens)) {
      return res.status(400).json({ error: 'Tokens array is required' });
    }

    const result = await notificationService.sendTestNotification(tokens, message);
    res.json(result);
  } catch (error) {
    logger.error('Test notification failed', { error: error.message });
    res.status(500).json({ error: error.message });
  }
});

// Notifica per prodotto sotto soglia
app.post('/notify/low-stock', authenticateRequest, async (req, res) => {
  try {
    const { product, userTokens } = req.body;
    
    if (!product || !userTokens || !Array.isArray(userTokens)) {
      return res.status(400).json({ 
        error: 'Product and userTokens array are required' 
      });
    }

    const result = await notificationService.notifyLowStock(product, userTokens);
    res.json(result);
  } catch (error) {
    logger.error('Low stock notification failed', { error: error.message });
    res.status(500).json({ error: error.message });
  }
});

// Notifica per prodotto esaurito
app.post('/notify/out-of-stock', authenticateRequest, async (req, res) => {
  try {
    const { product, userTokens } = req.body;
    
    if (!product || !userTokens || !Array.isArray(userTokens)) {
      return res.status(400).json({ 
        error: 'Product and userTokens array are required' 
      });
    }

    const result = await notificationService.notifyOutOfStock(product, userTokens);
    res.json(result);
  } catch (error) {
    logger.error('Out of stock notification failed', { error: error.message });
    res.status(500).json({ error: error.message });
  }
});

// Notifica automatica per cambiamento quantità
app.post('/notify/quantity-change', authenticateRequest, async (req, res) => {
  try {
    const { product, previousQuantity, userTokens } = req.body;
    
    if (!product || !userTokens || !Array.isArray(userTokens)) {
      return res.status(400).json({ 
        error: 'Product, previousQuantity and userTokens array are required' 
      });
    }

    const result = await notificationService.notifyProductQuantityChange(
      product, 
      previousQuantity, 
      userTokens
    );
    res.json(result);
  } catch (error) {
    logger.error('Quantity change notification failed', { error: error.message });
    res.status(500).json({ error: error.message });
  }
});

// Notifica generica a utente
app.post('/notify/user', authenticateRequest, async (req, res) => {
  try {
    const { userId, notification, data } = req.body;
    
    if (!userId || !notification) {
      return res.status(400).json({ 
        error: 'UserId and notification are required' 
      });
    }

    // Recupera i token dell'utente
    const userTokens = await notificationService.getUserTokens(userId);
    
    if (userTokens.length === 0) {
      return res.status(404).json({ 
        error: 'No device tokens found for user' 
      });
    }

    const result = await notificationService.fcmService.sendToMultipleTokens(
      userTokens, 
      notification, 
      data || {}
    );
    res.json(result);
  } catch (error) {
    logger.error('User notification failed', { error: error.message });
    res.status(500).json({ error: error.message });
  }
});

// Gestione errori
app.use((error, req, res, next) => {
  logger.error('Unhandled error', { 
    error: error.message, 
    stack: error.stack,
    path: req.path 
  });
  
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// Gestione route non trovate
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Inizializza e avvia il server
async function startServer() {
  try {
    await notificationService.initialize();
    
    app.listen(PORT, () => {
      logger.info(`Invory Notification Service running on port ${PORT}`);
      logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  } catch (error) {
    logger.error('Failed to start server', { error: error.message });
    process.exit(1);
  }
}

// Gestione graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  logger.info('SIGINT received, shutting down gracefully');
  process.exit(0);
});

startServer(); 