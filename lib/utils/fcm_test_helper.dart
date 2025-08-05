import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/services/stock_notification_service.dart';
import '../core/services/notifications_service.dart';

class FCMTestHelper {
  final StockNotificationService _stockNotificationService =
      StockNotificationService();
  final NotificationsService _notificationsService = NotificationsService();

  /// Testa l'invio di una notifica di test
  Future<void> sendTestNotification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ Utente non autenticato');
        return;
      }

      debugPrint('🧪 Invio notifica di test...');

      // Invia una notifica di test personalizzata
      await _notificationsService.sendNotification(
        title: 'Test Notifica',
        body: 'Questa è una notifica di test da FCMTestHelper',
        data: {'type': 'test', 'timestamp': DateTime.now().toIso8601String()},
      );

      debugPrint('✅ Notifica di test inviata con successo');
    } catch (e) {
      debugPrint('❌ Errore nell\'invio notifica di test: $e');
    }
  }

  /// Testa l'invio di notifiche multiple
  Future<void> sendMultipleTestNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ Utente non autenticato');
        return;
      }

      debugPrint('🧪 Invio notifiche multiple di test...');

      // Invia notifiche di test per prodotti sotto scorta
      await _notificationsService.sendLowStockNotification(
        productName: 'Acqua Naturale',
        currentQuantity: 0,
        threshold: 10,
      );

      await _notificationsService.sendLowStockNotification(
        productName: 'Caffè',
        currentQuantity: 3,
        threshold: 5,
      );

      await _notificationsService.sendOutOfStockNotification(
        productName: 'Pane',
      );

      debugPrint('✅ Notifiche multiple di test inviate con successo');
    } catch (e) {
      debugPrint('❌ Errore nell\'invio notifiche multiple: $e');
    }
  }

  /// Verifica lo stato del sistema di notifiche
  Future<void> checkNotificationStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ Utente non autenticato');
        return;
      }

      debugPrint('🔍 Verifica stato sistema notifiche...');
      debugPrint('   - UID: ${user.uid}');
      debugPrint('   - Email: ${user.email}');

      // Inizializza i servizi
      await _notificationsService.initialize();
      await _stockNotificationService.initialize();

      // Ottieni i token dell'utente
      final tokens = await _notificationsService.getCurrentUserTokens();
      debugPrint('   - Token registrati: ${tokens.length}');

      // Ottieni statistiche notifiche
      final stats = await _stockNotificationService.getNotificationStats();
      debugPrint('   - Prodotti sotto scorta: ${stats['lowStock'] ?? 0}');
      debugPrint('   - Prodotti esauriti: ${stats['outOfStock'] ?? 0}');

      debugPrint('✅ Sistema notifiche verificato');
    } catch (e) {
      debugPrint('❌ Errore nella verifica stato: $e');
    }
  }

  /// Pulisce le notifiche vecchie
  Future<void> cleanupOldNotifications() async {
    try {
      debugPrint('🧹 Pulizia notifiche vecchie...');
      await _stockNotificationService.cleanupOldNotifications();
      await _notificationsService.cleanupOldTokens();
      debugPrint('✅ Pulizia completata');
    } catch (e) {
      debugPrint('❌ Errore nella pulizia: $e');
    }
  }

  /// Controlla manualmente tutti i prodotti per notifiche
  Future<void> checkAllProducts() async {
    try {
      debugPrint('🔍 Controllo manuale di tutti i prodotti...');
      await _stockNotificationService.checkAllProducts();
      debugPrint('✅ Controllo prodotti completato');
    } catch (e) {
      debugPrint('❌ Errore nel controllo prodotti: $e');
    }
  }

  /// Invia notifica personalizzata
  Future<void> sendCustomNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('🔔 Invio notifica personalizzata: $title');
      await _stockNotificationService.sendCustomNotification(
        title: title,
        body: body,
        data: data,
      );
      debugPrint('✅ Notifica personalizzata inviata');
    } catch (e) {
      debugPrint('❌ Errore nell\'invio notifica personalizzata: $e');
    }
  }
}
