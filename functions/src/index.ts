import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

interface Product {
  nome: string;
  quantita: number;
  soglia: number;
  uid: string;
}

export const onProductUpdate = functions.firestore
  .document('users/{userId}/prodotti/{productId}')
  .onWrite(async (change, context) => {
    const product = change.after.data() as Product;
    const previousProduct = change.before.data() as Product;

    // Se il prodotto è stato eliminato o non c'è un cambiamento nella quantità
    if (!product || product.quantita === previousProduct?.quantita) {
      return null;
    }

    // Controlla se il prodotto è sotto soglia o esaurito
    if (product.quantita <= product.soglia) {
      await sendNotification(product, context.params.userId);
    }
  });

async function sendNotification(product: Product, userId: string) {
  try {
    // Recupera tutti i token FCM dell'utente
    const tokensSnapshot = await admin
      .firestore()
      .collection('users')
      .doc(userId)
      .collection('fcmTokens')
      .where('isActive', '==', true)
      .get();

    if (tokensSnapshot.empty) {
      console.log(`Nessun token trovato per l'utente: ${userId}`);
      return;
    }

    const tokens = tokensSnapshot.docs.map(doc => doc.data().token);

    // Prepara il messaggio
    const title = product.quantita === 0 
      ? 'Prodotto Esaurito!' 
      : 'Scorte in Esaurimento';
    
    const body = product.quantita === 0
      ? `${product.nome} è esaurito!`
      : `${product.nome} ha raggiunto la soglia minima (${product.quantita}/${product.soglia})`;

    const message = {
      notification: {
        title,
        body,
      },
      data: {
        type: product.quantita === 0 ? 'out_of_stock' : 'low_stock',
        productId: product.id || '',
        productName: product.nome,
      },
      tokens,
    };

    // Invia la notifica a tutti i dispositivi dell'utente
    const response = await admin.messaging().sendMulticast(message);

    console.log(`Notifica inviata a ${response.successCount} dispositivi per l'utente ${userId}`);

    // Gestisci i token non validi
    if (response.failureCount > 0) {
      const batch = admin.firestore().batch();
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const tokenDoc = tokensSnapshot.docs[idx].ref;
          batch.update(tokenDoc, { isActive: false });
          console.log(`Token non valido rimosso: ${tokens[idx]}`);
        }
      });
      await batch.commit();
      console.log(`${response.failureCount} token non validi rimossi per l'utente ${userId}`);
    }
  } catch (error) {
    console.error('Errore nell\'invio della notifica:', error);
  }
}

// Funzione per pulire i token inattivi (opzionale)
export const cleanupInactiveTokens = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - 30); // 30 giorni fa

      const inactiveTokensSnapshot = await admin
        .firestore()
        .collectionGroup('fcmTokens')
        .where('isActive', '==', false)
        .where('lastUsed', '<', cutoffDate)
        .get();

      if (!inactiveTokensSnapshot.empty) {
        const batch = admin.firestore().batch();
        inactiveTokensSnapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
        await batch.commit();
        console.log(`Rimossi ${inactiveTokensSnapshot.size} token inattivi`);
      }
    } catch (error) {
      console.error('Errore nella pulizia dei token:', error);
    }
  }); 