import 'package:flutter/foundation.dart';
import '../core/services/notification_service.dart';
import '../core/services/fcm_notification_service.dart';
import '../core/services/fcm_web_service.dart';
import '../../domain/entities/product.dart';

/// Helper per testare le notifiche web
class WebNotificationTest {
  static final NotificationService _notificationService = NotificationService();
  static final FCMNotificationService _fcmService = FCMNotificationService();
  static final FCMWebService _webService = FCMWebService();

  /// Testa le notifiche web locali
  static Future<void> testWebNotifications() async {
    if (!kIsWeb) {
      debugPrint('❌ Questo test è solo per il web');
      return;
    }

    try {
      debugPrint('🧪 Testando notifiche web...');

      // Test 1: Notifica locale semplice
      await _testLocalNotification();

      // Test 2: Notifica FCM
      await _testFCMNotification();

      // Test 3: Notifica prodotto sotto scorta
      await _testLowStockNotification();

      debugPrint('✅ Tutti i test web completati con successo!');
    } catch (e) {
      debugPrint('❌ Errore nei test web: $e');
    }
  }

  /// Testa notifica locale web
  static Future<void> _testLocalNotification() async {
    try {
      debugPrint('📱 Test notifica locale web...');

      await _webService.sendLowStockNotification(
        productName: 'Prodotto Test Web',
        currentQuantity: 5,
        threshold: 10,
      );

      debugPrint('✅ Notifica locale web inviata');
    } catch (e) {
      debugPrint('❌ Errore notifica locale web: $e');
    }
  }

  /// Testa notifica FCM
  static Future<void> _testFCMNotification() async {
    try {
      debugPrint('🔥 Test notifica web nativa...');

      await _webService.sendWebNotification(
        title: 'Test Notifica Web',
        body: 'Questa è una notifica di test web nativa',
      );

      debugPrint('✅ Notifica web nativa inviata');
    } catch (e) {
      debugPrint('❌ Errore notifica web: $e');
    }
  }

  /// Testa notifica prodotto sotto scorta
  static Future<void> _testLowStockNotification() async {
    try {
      debugPrint('📦 Test notifica prodotto sotto scorta...');

      await _webService.sendLowStockNotification(
        productName: 'Prodotto Test Scorte',
        currentQuantity: 3,
        threshold: 10,
      );

      debugPrint('✅ Notifica scorte basse inviata');
    } catch (e) {
      debugPrint('❌ Errore notifica scorte: $e');
    }
  }

  /// Testa i permessi web
  static Future<void> testWebPermissions() async {
    if (!kIsWeb) return;

    try {
      debugPrint('🔐 Testando permessi web...');

      final isSupported = await _notificationService.isSupported();
      debugPrint('📱 Supporto notifiche: $isSupported');

      final permissionsGranted =
          await _notificationService.arePermissionsGranted();
      debugPrint('✅ Permessi concessi: $permissionsGranted');

      if (!permissionsGranted) {
        debugPrint('🔔 Richiedendo permessi...');
        await _notificationService.requestPermissions();

        final newPermissions =
            await _notificationService.arePermissionsGranted();
        debugPrint('✅ Nuovi permessi: $newPermissions');
      }

      final canInstall = await _notificationService.canInstallPWA();
      debugPrint('📱 PWA installabile: $canInstall');
    } catch (e) {
      debugPrint('❌ Errore test permessi: $e');
    }
  }

  /// Testa l'installazione PWA
  static Future<void> testPWAInstall() async {
    if (!kIsWeb) return;

    try {
      debugPrint('📱 Testando installazione PWA...');

      final canInstall = _webService.canInstallPWA();
      final isInstalled = _webService.isAppInstalled();

      debugPrint('📱 PWA installabile: $canInstall');
      debugPrint('📱 PWA già installata: $isInstalled');

      if (canInstall) {
        debugPrint('🚀 Mostrando prompt installazione...');
        await _webService.showInstallPrompt();
        debugPrint('✅ Prompt installazione mostrato');
      } else if (isInstalled) {
        debugPrint('✅ PWA già installata');
      } else {
        debugPrint(
          'ℹ️ PWA non installabile al momento (criteri non soddisfatti)',
        );
      }
    } catch (e) {
      debugPrint('❌ Errore test PWA: $e');
    }
  }

  /// Esegue tutti i test web
  static Future<void> runAllWebTests() async {
    if (!kIsWeb) {
      debugPrint('❌ Questi test sono solo per il web');
      return;
    }

    debugPrint('🌐 Iniziando test completi per il web...');

    await testWebPermissions();
    await Future.delayed(const Duration(seconds: 1));

    await testWebNotifications();
    await Future.delayed(const Duration(seconds: 1));

    await testPWAInstall();

    debugPrint('🎉 Tutti i test web completati!');
  }
}

/// Esempio di utilizzo:
/// 
/// ```dart
/// // In un widget web
/// ElevatedButton(
///   onPressed: () => WebNotificationTest.runAllWebTests(),
///   child: Text('Test Web Notifiche'),
/// )
/// 
/// // Test specifici
/// ElevatedButton(
///   onPressed: () => WebNotificationTest.testWebPermissions(),
///   child: Text('Test Permessi'),
/// )
/// 
/// ElevatedButton(
///   onPressed: () => WebNotificationTest.testWebNotifications(),
///   child: Text('Test Notifiche'),
/// )
/// ``` 