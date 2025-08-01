import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:invory/core/services/fcm_http_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../domain/entities/product.dart';

abstract class INotificationService {
  Future<void> initialize();
  Future<void> requestPermissions();
  Future<void> showLowStockNotification(Product product);
  Future<void> showOutOfStockNotification(Product product);
  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
  Future<bool> isSupported();
  Future<bool> arePermissionsGranted();
  Future<bool> canInstallPWA();
  Future<void> showInstallPrompt();
}

class NotificationService implements INotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FCMHttpService _fcmService = FCMHttpService();

  bool _isInitialized = false;
  bool _permissionsGranted = false;
  @override
  Future<bool> isSupported() async {
    return true; // Supporto per mobile e web
  }

  @override
  Future<bool> arePermissionsGranted() async {
    return _permissionsGranted;
  }

  @override
  Future<bool> canInstallPWA() async {
    if (kIsWeb) {
      // Controlla se l'app può essere installata
      return html.window.localStorage['beforeinstallprompt'] == 'true';
    }
    return false;
  }

  @override
  Future<void> showInstallPrompt() async {
    if (kIsWeb) {
      try {
        // Trigger installazione PWA usando l'evento salvato
        final beforeInstallPrompt =
            html.window.localStorage['beforeinstallprompt'];
        if (beforeInstallPrompt == 'true') {
          // Dispatch dell'evento per mostrare il prompt nativo di Chrome
          html.window.dispatchEvent(html.Event('beforeinstallprompt'));

          // Pulisci il localStorage dopo aver mostrato il prompt
          html.window.localStorage.remove('beforeinstallprompt');
        }
      } catch (e) {
        print('Errore nel mostrare il prompt di installazione: $e');
      }
    }
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Inizializza FCM
    await _initializeFCM();

    if (kIsWeb) {
      await _initializeWeb();
    } else {
      await _initializeMobile();
    }

    _isInitialized = true;
  }

  Future<void> _initializeFCM() async {
    try {
      // Richiedi permesso per le notifiche
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _permissionsGranted = true;

        // Ottieni e salva il token FCM
        final token = await _messaging.getToken();
        if (token != null) {
          await _fcmService.saveToken(token);
        }

        // Ascolta i cambiamenti del token
        _messaging.onTokenRefresh.listen((token) {
          _fcmService.saveToken(token);
        });

        // Gestisci le notifiche in foreground
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          if (message.notification != null) {
            if (kIsWeb) {
              _showWebNotification(
                message.notification!.title ?? '',
                message.notification!.body ?? '',
                message.data['type'] ?? 'default',
                message.hashCode,
              );
            } else {
              // Crea un Product "placeholder" minimale se necessario, oppure gestisci il caso senza Product
              final product =
                  _extractProductFromMessage(message) ?? Product.empty();
              _showMobileNotification(
                product,
                message.notification?.title ?? '',
                message.notification?.body ?? '',
                message.data['type'] == 'out_of_stock'
                    ? 'out_of_stock_channel'
                    : 'low_stock_channel',
                message.hashCode,
                message.data['type'] == 'out_of_stock'
                    ? const Color(0xFFF44336)
                    : const Color(0xFFFF9800),
              );
            }
          }
        });

        // Gestisci il click sulla notifica quando l'app è in background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          // Implementa la navigazione se necessario
          print('Notifica aperta: ${message.data}');
        });
      }
    } catch (e) {
      debugPrint('Errore nell\'inizializzazione FCM: $e');
    }
  }

  Future<void> _initializeWeb() async {
    try {
      // Registra il service worker per le notifiche PWA
      if (html.window.navigator.serviceWorker != null) {
        await html.window.navigator.serviceWorker?.register('/sw.js');
      }

      // Controlla se l'app può essere installata
      // Listener per l'evento beforeinstallprompt
      html.window.addEventListener('beforeinstallprompt', (event) {});
    } catch (e) {
      print('Errore nell\'inizializzazione web: $e');
    }
  }

  Future<void> _initializeMobile() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  @override
  Future<void> requestPermissions() async {
    if (kIsWeb) {
      await _requestWebPermissions();
    } else {
      await _requestMobilePermissions();
    }
  }

  Future<void> _requestWebPermissions() async {
    try {
      if (html.window.navigator.serviceWorker != null) {
        final permission = await html.window.navigator.permissions?.query({
          'name': 'notifications',
        });

        if (permission?.state == 'granted') {
          _permissionsGranted = true;
        } else if (permission?.state == 'prompt') {
          // Richiedi permesso
          final result = await html.Notification.requestPermission();
          _permissionsGranted = result == 'granted';
        }
      }
    } catch (e) {
      print('Errore nella richiesta permessi web: $e');
    }
  }

  Future<void> _requestMobilePermissions() async {
    try {
      if (await Permission.notification.request().isGranted) {
        _permissionsGranted = true;
      }
    } catch (e) {
      print('Errore nella richiesta permessi: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notifica cliccata: ${response.payload}');
  }

  // Estrae le informazioni del prodotto dal messaggio FCM
  Product? _extractProductFromMessage(RemoteMessage message) {
    try {
      final data = message.data;
      if (data.containsKey('productId') && data.containsKey('productName')) {
        return Product(
          id: data['productId'] ?? '',
          nome: data['productName'] ?? '',
          categoria: '',
          quantita: 0,
          soglia: 0,
          prezzoUnitario: 0.0,
          consumati: 0,
        );
      }
    } catch (e) {
      debugPrint('Errore nell\'estrazione del prodotto dal messaggio: $e');
    }
    return null;
  }

  @override
  Future<void> showLowStockNotification(Product product) async {
    if (!_permissionsGranted) return;

    // Invia notifica FCM
    await _fcmService.checkAndNotifyLowStock(product);

    // Mostra anche notifica locale se l'app è in foreground
    if (kIsWeb) {
      await _showWebNotification(
        'Scorte Basse: ${product.nome}',
        'Quantità: ${product.quantita} (Soglia: ${product.soglia})',
        'low_stock',
        product.hashCode,
      );
    } else {
      await _showMobileNotification(
        product,
        'Scorte Basse: ${product.nome}',
        'Quantità: ${product.quantita} (Soglia: ${product.soglia})',
        'low_stock_channel',
        product.hashCode,
        const Color(0xFFFF9800), // Orange
      );
    }
  }

  @override
  Future<void> showOutOfStockNotification(Product product) async {
    if (!_permissionsGranted) return;

    // Invia notifica FCM
    await _fcmService.checkAndNotifyLowStock(product);

    // Mostra anche notifica locale se l'app è in foreground
    if (kIsWeb) {
      await _showWebNotification(
        'Prodotto Esaurito: ${product.nome}',
        'Il prodotto è completamente esaurito!',
        'out_of_stock',
        product.hashCode + 1000,
      );
    } else {
      await _showMobileNotification(
        product,
        'Prodotto Esaurito: ${product.nome}',
        'Il prodotto è completamente esaurito!',
        'out_of_stock_channel',
        product.hashCode + 1000,
        const Color(0xFFF44336), // Red
      );
    }
  }

  Future<void> _showWebNotification(
    String title,
    String body,
    String tag,
    int id,
  ) async {
    try {
      if (html.Notification.permission == 'granted') {
        html.Notification(
          title,
          body: body,
          icon: '/icons/Icon-192.png',
          tag: tag,
        );
      }
    } catch (e) {
      print('Errore nella notifica web: $e');
    }
  }

  Future<void> _showMobileNotification(
    Product product,
    String title,
    String body,
    String channelId,
    int id,
    Color color,
  ) async {
    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            channelId,
            channelId == 'low_stock_channel'
                ? 'Scorte Basse'
                : 'Prodotto Esaurito',
            channelDescription: 'Notifiche per prodotti con scorte basse',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            color: color,
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notifications.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: 'product_${product.id}',
      );
    } catch (e) {
      print('Errore nella notifica mobile: $e');
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      if (!kIsWeb) {
        await _notifications.cancel(id);
      }
    } catch (e) {
      print('Errore nella cancellazione notifica: $e');
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      if (!kIsWeb) {
        await _notifications.cancelAll();
      }
    } catch (e) {
      print('Errore nella cancellazione di tutte le notifiche: $e');
    }
  }
}
