import 'dart:html' as html;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../domain/entities/product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fcm_notification_service.dart';
import 'fcm_web_service.dart';

abstract class INotificationService {
  Future<void> initialize();
  Future<void> requestPermissions();
  Future<void> showLowStockNotification(Product product);
  Future<void> showOutOfStockNotification(Product product);
  Future<void> sendLowStockNotification({
    required String productName,
    required int currentQuantity,
    required int threshold,
  });
  Future<void> sendOutOfStockNotification({required String productName});
  Future<void> sendNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  });
  Future<void> cancelNotification(int id);
  Future<void> cancelAllNotifications();
  Future<bool> isSupported();
  Future<bool> arePermissionsGranted();
  Future<bool> canInstallPWA();
  Future<void> showInstallPrompt();
  Future<void> savePendingToken();
  Future<void> savePendingTokens();
  Future<List<Map<String, dynamic>>> getCurrentUserTokens();
  Future<void> cleanupOldTokens();
}

class NotificationService implements INotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    _fcmService = FCMNotificationService();
    _webService = FCMWebService();
  }

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  late final FCMNotificationService _fcmService;
  late final FCMWebService _webService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      return _webService.canInstallPWA();
    }
    return false;
  }

  @override
  Future<void> showInstallPrompt() async {
    if (kIsWeb) {
      await _webService.showInstallPrompt();
    }
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('Inizializzazione servizio notifiche...');

    // Inizializza prima il web se necessario
    if (kIsWeb) {
      await _initializeWeb();
    } else {
      await _initializeMobile();
    }

    // Poi inizializza FCM
    await _initializeFCM();

    _isInitialized = true;
    debugPrint('Servizio notifiche inizializzato con successo');
  }

  Future<void> _initializeFCM() async {
    try {
      if (kIsWeb) {
        // Per il web, usa il servizio web
        debugPrint('Inizializzazione servizio web...');
        await _webService.initialize();
        _permissionsGranted = _webService.hasPermission();

        if (_permissionsGranted) {
          debugPrint('Permessi notifiche web concessi');

          // Genera un token univoco per il dispositivo web
          final deviceId =
              html.window.localStorage['deviceId'] ??
              DateTime.now().millisecondsSinceEpoch.toString();
          html.window.localStorage['deviceId'] = deviceId;

          // Salva il token
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await _webService.saveToken(deviceId);
            debugPrint('Token web salvato per il dispositivo');
          } else {
            _pendingToken = deviceId;
            debugPrint('Token web in attesa di autenticazione');
          }

          // Configura il listener per le notifiche in tempo reale
          _setupRealtimeNotifications();
          debugPrint('Listener notifiche in tempo reale configurato');

          // AGGIUNGI: Configura il listener per le notifiche in background
          _setupBackgroundNotifications();
          debugPrint('Listener notifiche in background configurato');
        } else {
          debugPrint('Permessi notifiche web negati');
        }
      } else {
        // Per mobile, usa FCM
        debugPrint('Inizializzazione FCM...');

        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        debugPrint('Stato autorizzazione FCM: ${settings.authorizationStatus}');

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          _permissionsGranted = true;
          debugPrint('Permessi FCM concessi');

          // Ottieni e salva il token FCM con retry
          await _getAndSaveTokenWithRetry();

          // Ascolta i cambiamenti del token
          _messaging.onTokenRefresh.listen((token) {
            debugPrint('Token FCM aggiornato: ${token.substring(0, 20)}...');
            _saveTokenToFirestore(token);
          });

          // Gestisci le notifiche in foreground
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            debugPrint(
              'Notifica FCM ricevuta in foreground: ${message.notification?.title}',
            );
            if (message.notification != null) {
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
          });

          // Gestisci il click sulla notifica quando l'app è in background
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            debugPrint('Notifica aperta: ${message.data}');
          });
        } else {
          debugPrint('Permessi FCM negati: ${settings.authorizationStatus}');
        }
      }
    } catch (e) {
      debugPrint('Errore nell\'inizializzazione: $e');
    }
  }

  // Salva il token FCM in Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Utente non autenticato, impossibile salvare il token FCM');
        return;
      }

      if (kIsWeb) {
        // Per il web, usa il servizio web
        await _webService.saveToken(token);
      } else {
        // Per mobile, salva direttamente
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('tokens')
            .doc(token)
            .set({
              'token': token,
              'createdAt': FieldValue.serverTimestamp(),
              'lastUsed': FieldValue.serverTimestamp(),
              'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
              'isActive': true,
            }, SetOptions(merge: true));

        debugPrint('Token FCM salvato con successo');
      }
    } catch (e) {
      debugPrint('Errore nel salvataggio del token FCM: $e');
    }
  }

  // Ottieni e salva il token con retry logic
  Future<void> _getAndSaveTokenWithRetry() async {
    int attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        attempts++;
        debugPrint(
          'Tentativo $attempts/$maxAttempts per ottenere token FCM...',
        );

        final token = await _messaging.getToken();
        if (token != null) {
          debugPrint('Token FCM ottenuto: ${token.substring(0, 20)}...');

          // Salva il token solo se l'utente è autenticato
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await _saveTokenToFirestore(token);
            debugPrint('Token FCM salvato con successo');
          } else {
            debugPrint(
              'Utente non autenticato, token FCM ottenuto ma non salvato',
            );
            _pendingToken = token;
          }
          return;
        } else {
          debugPrint('Token FCM nullo, tentativo $attempts');
        }
      } catch (e) {
        debugPrint('Errore nel tentativo $attempts: $e');
      }

      if (attempts < maxAttempts) {
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }

    debugPrint('Impossibile ottenere token FCM dopo $maxAttempts tentativi');
  }

  // Token in attesa di essere salvato dopo l'autenticazione
  String? _pendingToken;

  @override
  Future<void> savePendingToken() async {
    if (_pendingToken != null) {
      debugPrint('Salvando token FCM pendente dopo autenticazione...');
      await _saveTokenToFirestore(_pendingToken!);
      _pendingToken = null;
      debugPrint('Token FCM pendente salvato con successo');
    }
  }

  @override
  Future<void> savePendingTokens() async {
    await savePendingToken();
  }

  @override
  Future<List<Map<String, dynamic>>> getCurrentUserTokens() async {
    try {
      if (kIsWeb) {
        return await _webService.getUserTokens();
      } else {
        return await _fcmService.getCurrentUserTokens();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nel recupero dei token: $e');
      }
      return [];
    }
  }

  @override
  Future<void> cleanupOldTokens() async {
    try {
      if (kIsWeb) {
        // La pulizia per web è gestita dal FCMWebService
        return;
      } else {
        await _fcmService.cleanupOldTokens();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nella pulizia dei token: $e');
      }
    }
  }

  Future<String?> forceTokenRefresh() async {
    try {
      debugPrint('Forzando refresh del token FCM...');
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('Nuovo token FCM ottenuto: ${token.substring(0, 20)}...');
        await _saveTokenToFirestore(token);
        return token;
      } else {
        debugPrint('Errore: Nuovo token FCM nullo');
        return null;
      }
    } catch (e) {
      debugPrint('Errore nel refresh del token FCM: $e');
      return null;
    }
  }

  Future<void> _initializeWeb() async {
    try {
      debugPrint('Inizializzazione web...');

      // Registra il service worker per le notifiche
      if (html.window.navigator.serviceWorker != null) {
        debugPrint('Registrazione service worker...');
        try {
          final registration = await html.window.navigator.serviceWorker
              ?.register('/firebase-messaging-sw.js');
          debugPrint('Service worker registrato: ${registration?.scope}');
          if (registration != null) {
            await _waitForServiceWorkerActivation(registration);
          }
        } catch (e) {
          debugPrint('Errore nella registrazione service worker: $e');
        }
      } else {
        debugPrint('Service Worker non supportato');
      }

      html.window.addEventListener('beforeinstallprompt', (event) {
        debugPrint('Evento beforeinstallprompt catturato');
        html.window.localStorage['beforeinstallprompt'] = 'true';
      });

      debugPrint('Inizializzazione web completata');
    } catch (e) {
      debugPrint('Errore nell\'inizializzazione web: $e');
    }
  }

  Future<void> _waitForServiceWorkerActivation(
    html.ServiceWorkerRegistration registration,
  ) async {
    if (registration.active != null) {
      debugPrint('Service worker già attivo');
      return;
    }

    debugPrint('In attesa dell\'attivazione del service worker...');

    int attempts = 0;
    const maxAttempts = 20;

    while (registration.active == null && attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
      debugPrint(
        'Tentativo $attempts/$maxAttempts per attivazione service worker...',
      );
    }

    if (registration.active != null) {
      debugPrint('Service worker attivato con successo');
    } else {
      debugPrint('Timeout nell\'attivazione del service worker');
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
          final result = await html.Notification.requestPermission();
          _permissionsGranted = result == 'granted';
        }
      }
    } catch (e) {
      debugPrint('Errore nella richiesta permessi web: $e');
    }
  }

  Future<void> _requestMobilePermissions() async {
    try {
      if (await Permission.notification.request().isGranted) {
        _permissionsGranted = true;
      }
    } catch (e) {
      debugPrint('Errore nella richiesta permessi: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notifica cliccata: ${response.payload}');
  }

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
    await _sendNotificationWithLogging(
      product: product,
      notificationType: 'low_stock',
      webServiceCall: () => _webService.sendLowStockNotification(
        productName: product.nome,
        currentQuantity: product.quantita,
        threshold: product.soglia,
      ),
      mobileServiceCall: () => _fcmService.sendLowStockNotification(
        productName: product.nome,
        currentQuantity: product.quantita,
        threshold: product.soglia,
      ),
      mobileLocalNotification: () => _showMobileNotification(
        product,
        'Scorte Basse: ${product.nome}',
        'Quantità: ${product.quantita} (Soglia: ${product.soglia})',
        'low_stock_channel',
        product.hashCode,
        const Color(0xFFFF9800),
      ),
    );
  }

  /// Metodo helper per inviare notifiche con logging
  Future<void> _sendNotificationWithLogging({
    required Product product,
    required String notificationType,
    required Future<void> Function() webServiceCall,
    required Future<void> Function() mobileServiceCall,
    Future<void> Function()? mobileLocalNotification,
  }) async {
    if (kDebugMode) {
      print(
        '🔔 NotificationService: ${notificationType}_notification chiamato per ${product.nome}',
      );
      print('📊 Permessi concessi: $_permissionsGranted');
      print('🌐 È web: $kIsWeb');
    }

    if (!_permissionsGranted) {
      if (kDebugMode) {
        print('❌ Permessi non concessi, notifica non inviata');
      }
      return;
    }

    try {
      if (kIsWeb) {
        if (kDebugMode) {
          print('🌐 Invio notifica web per: ${product.nome}');
        }
        await webServiceCall();
        if (kDebugMode) {
          print('✅ Notifica web inviata per: ${product.nome}');
        }
      } else {
        if (kDebugMode) {
          print('📱 Invio notifica mobile per: ${product.nome}');
        }
        await mobileServiceCall();
        
        if (mobileLocalNotification != null) {
          await mobileLocalNotification();
        }
        
        if (kDebugMode) {
          print('✅ Notifica mobile inviata per: ${product.nome}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'invio notifica: $e');
      }
    }
  }

  @override
  Future<void> showOutOfStockNotification(Product product) async {
    await _sendNotificationWithLogging(
      product: product,
      notificationType: 'out_of_stock',
      webServiceCall: () => _webService.sendOutOfStockNotification(productName: product.nome),
      mobileServiceCall: () => _fcmService.sendNotificationToUser(
        title: 'Prodotto esaurito',
        body: 'Il prodotto ${product.nome} è completamente esaurito',
        data: {
          'type': 'out_of_stock',
          'productName': product.nome,
          'currentQuantity': '0',
        },
      ),
      mobileLocalNotification: () => _showMobileNotification(
        product,
        'Prodotto Esaurito: ${product.nome}',
        'Il prodotto è completamente esaurito!',
        'out_of_stock_channel',
        product.hashCode + 1000,
        const Color(0xFFF44336),
      ),
    );
  }

  @override
  Future<void> sendLowStockNotification({
    required String productName,
    required int currentQuantity,
    required int threshold,
  }) async {
    if (kDebugMode) {
      print(
        '🔔 NotificationService: sendLowStockNotification chiamato per $productName',
      );
    }

    if (!_permissionsGranted) {
      if (kDebugMode) {
        print('❌ Permessi non concessi, notifica non inviata');
      }
      return;
    }

    if (kIsWeb) {
      await _webService.sendLowStockNotification(
        productName: productName,
        currentQuantity: currentQuantity,
        threshold: threshold,
      );
    } else {
      await _fcmService.sendLowStockNotification(
        productName: productName,
        currentQuantity: currentQuantity,
        threshold: threshold,
      );
    }
  }

  @override
  Future<void> sendOutOfStockNotification({required String productName}) async {
    if (kDebugMode) {
      print(
        '🔔 NotificationService: sendOutOfStockNotification chiamato per $productName',
      );
    }

    if (!_permissionsGranted) {
      if (kDebugMode) {
        print('❌ Permessi non concessi, notifica non inviata');
      }
      return;
    }

    if (kIsWeb) {
      await _webService.sendOutOfStockNotification(productName: productName);
    } else {
      await _fcmService.sendOutOfStockNotification(productName: productName);
    }
  }

  @override
  Future<void> sendNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (kDebugMode) {
      print('🔔 NotificationService: sendNotification chiamato per $title');
    }

    if (!_permissionsGranted) {
      if (kDebugMode) {
        print('❌ Permessi non concessi, notifica non inviata');
      }
      return;
    }

    if (kIsWeb) {
      await _webService.sendNotificationToAllDevices(
        title: title,
        body: body,
        data: data,
      );
    } else {
      await _fcmService.sendNotificationToUser(
        title: title,
        body: body,
        data: data,
      );
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
      debugPrint('Errore nella notifica mobile: $e');
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      if (!kIsWeb) {
        await _notifications.cancel(id);
      }
    } catch (e) {
      debugPrint('Errore nella cancellazione notifica: $e');
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      if (!kIsWeb) {
        await _notifications.cancelAll();
      }
    } catch (e) {
      debugPrint('Errore nella cancellazione di tutte le notifiche: $e');
    }
  }

  void _setupRealtimeNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      debugPrint(
        '🔔 Configurazione listener notifiche in tempo reale per utente: ${user.uid}',
      );

      // Set per tenere traccia delle notifiche già mostrate
      final Set<String> shownNotifications = <String>{};
      final currentDeviceId = html.window.localStorage['deviceId'] ?? '';

      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .snapshots()
          .listen(
            (snapshot) {
              debugPrint(
                '📨 Ricevute ${snapshot.docChanges.length} nuove notifiche',
              );

              for (final change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added) {
                  final data = change.doc.data();
                  if (data != null) {
                    final notificationId = data['notificationId'] ?? '';
                    final targetDeviceId = data['targetDeviceId'] ?? '';
                    final sourceDeviceId = data['sourceDeviceId'] ?? '';

                    // CONTROLLO 1: Verifica se la notifica è per questo dispositivo
                    if (targetDeviceId != currentDeviceId) {
                      debugPrint(
                        '⚠️ Notifica non per questo dispositivo, salto',
                      );
                      continue;
                    }

                    // CONTROLLO 2: Verifica se la notifica viene dal dispositivo corrente
                    if (sourceDeviceId == currentDeviceId) {
                      debugPrint('⚠️ Notifica dal dispositivo corrente, salto');
                      continue;
                    }

                    // CONTROLLO 3: Verifica se la notifica è già stata mostrata
                    if (shownNotifications.contains(notificationId)) {
                      debugPrint(
                        '⚠️ Notifica già mostrata, salto: ${data['title']}',
                      );
                      continue;
                    }

                    debugPrint(
                      ' Mostrando notifica: ${data['title']} - ${data['body']}',
                    );

                    _showLocalWebNotification(
                      data['title'] ?? '',
                      data['body'] ?? '',
                    );

                    // Aggiungi alla lista delle notifiche mostrate
                    shownNotifications.add(notificationId);

                    // Marca come letta
                    change.doc.reference.update({'read': true});
                    debugPrint('✅ Notifica marcata come letta');
                  }
                }
              }
            },
            onError: (error) {
              debugPrint('❌ Errore nel listener notifiche: $error');
            },
          );
    } else {
      debugPrint(
        '❌ Utente non autenticato, impossibile configurare listener notifiche',
      );
    }
  }

  void _setupBackgroundNotifications() {
    // Gestisci le notifiche quando l'app è in background
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '📨 Notifica ricevuta in background: ${message.notification?.title}',
      );

      if (message.notification != null) {
        _showLocalWebNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
        );
      }
    });
  }

  void _showLocalWebNotification(String title, String body) {
    try {
      if (html.Notification.permission == 'granted') {
        debugPrint('👀 Mostrando notifica web: $title');

        final notification = html.Notification(
          title,
          body: body,
          icon: '/invory/icons/Icon-192.png',
          tag: 'invory_notification_${DateTime.now().millisecondsSinceEpoch}',
        );

        notification.onClick.listen((event) {
          if (kDebugMode) {
            print('👆 Notifica locale cliccata: $title');
          }
        });

        notification.onShow.listen((event) {
          debugPrint('✅ Notifica web mostrata con successo: $title');
        });

        notification.onError.listen((error) {
          debugPrint('❌ Errore nella notifica web: $error');
        });
      } else {
        debugPrint('❌ Permessi notifiche web non concessi');
      }
    } catch (e) {
      debugPrint('❌ Errore nel mostrare notifica web: $e');
    }
  }
}
