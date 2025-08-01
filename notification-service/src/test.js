const InvoryNotificationService = require('./services/InvoryNotificationService');

/**
 * Test del servizio di notifiche Invory
 */
async function testNotificationService() {
  console.log('🚀 Avvio test del servizio di notifiche Invory...\n');

  const notificationService = new InvoryNotificationService();

  try {
    // 1. Inizializza il servizio
    console.log('1️⃣ Inizializzazione servizio...');
    await notificationService.initialize();
    console.log('✅ Servizio inizializzato con successo\n');

    // 2. Test connessione FCM
    console.log('2️⃣ Test connessione FCM...');
    const connectionTest = await notificationService.testService();
    console.log('✅ Test connessione completato:', connectionTest);

    // 3. Test notifica con token di esempio
    console.log('\n3️⃣ Test notifica...');
    const testTokens = process.env.TEST_FCM_TOKENS ? 
      process.env.TEST_FCM_TOKENS.split(',') : [];
    
    if (testTokens.length > 0) {
      const testResult = await notificationService.sendTestNotification(
        testTokens, 
        'Test notifica da Invory Notification Service'
      );
      console.log('✅ Test notifica completato:', testResult);
    } else {
      console.log('⚠️  Nessun token di test configurato, salto test notifica');
    }

    // 4. Test notifica prodotto sotto soglia
    console.log('\n4️⃣ Test notifica prodotto sotto soglia...');
    const testProduct = {
      id: 'test-product-1',
      nome: 'Caffè Espresso',
      categoria: 'Bevande',
      quantita: 5,
      soglia: 10,
      prezzoUnitario: 1.50,
      consumati: 0
    };

    const lowStockResult = await notificationService.notifyLowStock(
      testProduct, 
      testTokens
    );
    console.log('✅ Test notifica scorte basse completato:', lowStockResult);

    // 5. Test notifica prodotto esaurito
    console.log('\n5️⃣ Test notifica prodotto esaurito...');
    const emptyProduct = {
      ...testProduct,
      id: 'test-product-2',
      nome: 'Latte',
      quantita: 0
    };

    const outOfStockResult = await notificationService.notifyOutOfStock(
      emptyProduct, 
      testTokens
    );
    console.log('✅ Test notifica prodotto esaurito completato:', outOfStockResult);

    console.log('\n🎉 Tutti i test completati con successo!');
    
  } catch (error) {
    console.error('\n❌ Errore durante i test:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

// Esegui i test se il file viene chiamato direttamente
if (require.main === module) {
  require('dotenv').config();
  testNotificationService();
}

module.exports = { testNotificationService }; 