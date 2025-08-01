const fetch = require('node-fetch');

const BASE_URL = 'http://localhost:3000';

/**
 * Test delle API del servizio di notifiche
 */
async function testAPIs() {
  console.log('🧪 Test delle API del servizio notifiche\n');

  try {
    // Test 1: Health Check
    console.log('📋 Test 1: Health Check');
    const healthResponse = await fetch(`${BASE_URL}/health`);
    const healthData = await healthResponse.json();
    console.log('✅ Health Check:', healthData);
    console.log('');

    // Test 2: Test Connessione FCM
    console.log('📋 Test 2: Test Connessione FCM');
    const connectionResponse = await fetch(`${BASE_URL}/test-connection`);
    const connectionData = await connectionResponse.json();
    console.log('✅ Test Connessione:', connectionData);
    console.log('');

    // Test 3: Invia Notifica a Token Singolo
    console.log('📋 Test 3: Invia Notifica a Token Singolo');
    const tokenResponse = await fetch(`${BASE_URL}/send-to-token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: 'test-token-123',
        title: 'Test Notifica',
        body: 'Questa è una notifica di test',
        data: { type: 'test', timestamp: Date.now().toString() }
      })
    });
    const tokenData = await tokenResponse.json();
    console.log('✅ Test Token Singolo:', tokenData);
    console.log('');

    // Test 4: Invia Notifica a Utente
    console.log('📋 Test 4: Invia Notifica a Utente');
    const userResponse = await fetch(`${BASE_URL}/send-to-user`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: 'test-user-123',
        title: 'Test Notifica Utente',
        body: 'Notifica inviata a tutti i dispositivi dell\'utente',
        data: { type: 'user_test', timestamp: Date.now().toString() }
      })
    });
    const userData = await userResponse.json();
    console.log('✅ Test Utente:', userData);
    console.log('');

    // Test 5: Invia Notifica Scorte Basse
    console.log('📋 Test 5: Invia Notifica Scorte Basse');
    const lowStockResponse = await fetch(`${BASE_URL}/send-low-stock-notification`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        userId: 'test-user-123',
        product: {
          id: 'test-product-123',
          nome: 'Prodotto Test',
          quantita: 5,
          soglia: 10
        }
      })
    });
    const lowStockData = await lowStockResponse.json();
    console.log('✅ Test Scorte Basse:', lowStockData);
    console.log('');

    // Test 6: Invia Notifica a Più Token
    console.log('📋 Test 6: Invia Notifica a Più Token');
    const multipleTokensResponse = await fetch(`${BASE_URL}/send-to-multiple-tokens`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        tokens: ['token1', 'token2', 'token3'],
        title: 'Test Notifica Multipla',
        body: 'Notifica inviata a più dispositivi',
        data: { type: 'multiple_test', timestamp: Date.now().toString() }
      })
    });
    const multipleTokensData = await multipleTokensResponse.json();
    console.log('✅ Test Multipli Token:', multipleTokensData);
    console.log('');

    console.log('🎉 Tutti i test completati!');

  } catch (error) {
    console.error('❌ Errore durante i test:', error);
  }
}

// Test con rate limiting
async function testRateLimiting() {
  console.log('🚦 Test Rate Limiting\n');

  try {
    const promises = [];
    
    // Invia 15 richieste rapidamente (oltre il limite di 10/min)
    for (let i = 0; i < 15; i++) {
      promises.push(
        fetch(`${BASE_URL}/send-to-token`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            token: `test-token-${i}`,
            title: `Test ${i}`,
            body: `Notifica test ${i}`
          })
        }).then(res => res.json())
      );
    }

    const results = await Promise.allSettled(promises);
    
    let successCount = 0;
    let rateLimitCount = 0;

    results.forEach((result, index) => {
      if (result.status === 'fulfilled') {
        if (result.value.error?.includes('Troppe notifiche')) {
          rateLimitCount++;
        } else {
          successCount++;
        }
      }
    });

    console.log(`✅ Test Rate Limiting completato:`);
    console.log(`   Successi: ${successCount}`);
    console.log(`   Rate Limited: ${rateLimitCount}`);
    console.log('');

  } catch (error) {
    console.error('❌ Errore nel test rate limiting:', error);
  }
}

// Esegui i test
async function runAllTests() {
  await testAPIs();
  await testRateLimiting();
}

// Esegui se chiamato direttamente
if (require.main === module) {
  runAllTests();
} 