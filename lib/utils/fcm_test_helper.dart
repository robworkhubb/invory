import 'package:flutter/foundation.dart';
import '../core/services/fcm_notification_service.dart';

/// Helper per testare il sistema FCM durante lo sviluppo
class FCMTestHelper {
  static final FCMNotificationService _fcmService = FCMNotificationService();

  /// Testa l'invio di una notifica di prodotto sotto scorta
  static Future<void> testLowStockNotification() async {
    try {
      await _fcmService.sendLowStockNotification(
        productName: "Prodotto Test",
        currentQuantity: 5,
        threshold: 10,
      );
      
      if (kDebugMode) {
        print('✅ Test notifica sotto scorta completato');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nel test notifica sotto scorta: $e');
      }
    }
  }

  /// Testa l'invio di una notifica di prodotto esaurito
  static Future<void> testOutOfStockNotification() async {
    try {
      await _fcmService.sendNotificationToUser(
        title: 'Prodotto esaurito',
        body: 'Il prodotto Prodotto Test è completamente esaurito',
        data: {
          'type': 'out_of_stock',
          'productName': 'Prodotto Test',
          'currentQuantity': '0',
        },
      );
      
      if (kDebugMode) {
        print('✅ Test notifica esaurito completato');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nel test notifica esaurito: $e');
      }
    }
  }

  /// Testa l'invio di una notifica personalizzata
  static Future<void> testCustomNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _fcmService.sendNotificationToUser(
        title: title,
        body: body,
        data: data,
      );
      
      if (kDebugMode) {
        print('✅ Test notifica personalizzata completato');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nel test notifica personalizzata: $e');
      }
    }
  }

  /// Pulisce i token obsoleti
  static Future<void> cleanupOldTokens() async {
    try {
      await _fcmService.cleanupOldTokens();
      
      if (kDebugMode) {
        print('✅ Pulizia token obsoleti completata');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nella pulizia token: $e');
      }
    }
  }

  /// Esegue tutti i test FCM
  static Future<void> runAllTests() async {
    if (kDebugMode) {
      print('🧪 Iniziando test FCM...');
    }
    
    await testLowStockNotification();
    await Future.delayed(const Duration(seconds: 2));
    
    await testOutOfStockNotification();
    await Future.delayed(const Duration(seconds: 2));
    
    await testCustomNotification(
      title: 'Test Personalizzato',
      body: 'Questa è una notifica di test personalizzata',
      data: {'test': 'true'},
    );
    
    await cleanupOldTokens();
    
    if (kDebugMode) {
      print('🎉 Tutti i test FCM completati!');
    }
  }
}

/// Esempio di utilizzo nel codice:
/// 
/// ```dart
/// // In un widget o provider
/// ElevatedButton(
///   onPressed: () => FCMTestHelper.testLowStockNotification(),
///   child: Text('Test Notifica'),
/// )
/// 
/// // Oppure per tutti i test
/// ElevatedButton(
///   onPressed: () => FCMTestHelper.runAllTests(),
///   child: Text('Esegui Tutti i Test'),
/// )
/// ``` 