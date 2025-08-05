import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'fcm_web_service.dart';
import 'fcm_notification_service.dart';

class NotificationsService {
  static final NotificationsService _instance =
      NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FCMWebService _fcmWebService = FCMWebService();
  final FCMNotificationService _fcmNotificationService =
      FCMNotificationService();

  String? _pendingToken;
  bool _isInitialized = false;

  /// Inizializza il servizio di notifiche
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('🔧 NotificationsService già inizializzato');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔧 Inizializzazione servizio notifiche...');
      }

      // Richiedi permessi per le notifiche
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('🔔 Permessi notifiche: ${settings.authorizationStatus}');
      }

      // Ottieni il token FCM
      String? token = await _messaging.getToken();
      if (token != null) {
        _pendingToken = token;
        if (kDebugMode) {
          print(
            '✅ Token FCM ottenuto: ${token.length > 20 ? token.substring(0, 20) + '...' : token}',
          );
        }
      }

      // Ascolta i cambiamenti del token
      _messaging.onTokenRefresh.listen((newToken) {
        _pendingToken = newToken;
        if (kDebugMode) {
          print('🔄 Token FCM aggiornato');
        }
        _saveTokenIfAuthenticated(newToken);
      });

      // Gestisci le notifiche in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print(
            '🔔 Notifica ricevuta in foreground: ${message.notification?.title}',
          );
        }
        _handleForegroundMessage(message);
      });

      // Inizializza i servizi specifici per piattaforma
      if (kIsWeb) {
        await _fcmWebService.initialize();
      } else {
        await _fcmNotificationService.initialize();
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Servizio notifiche inizializzato con successo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'inizializzazione del servizio notifiche: $e');
      }
    }
  }

  /// Salva i token FCM pendenti dopo l'autenticazione
  Future<void> savePendingTokens() async {
    try {
      if (kDebugMode) {
        print('💾 Salvataggio token FCM pendenti...');
      }

      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('⚠️ Utente non autenticato, token salvati in attesa');
        }
        return;
      }

      // Salva il token pendente se presente
      if (_pendingToken != null) {
        await _saveTokenToFirestore(_pendingToken!);
        _pendingToken = null;
      }

      // Salva anche i token specifici per piattaforma
      if (kIsWeb) {
        final webToken = _fcmWebService.currentToken;
        if (webToken != null) {
          await _saveTokenToFirestore(webToken);
        }
      }

      if (kDebugMode) {
        print('✅ Token FCM pendenti salvati con successo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nel salvataggio dei token pendenti: $e');
      }
    }
  }

  /// Salva un token nel database Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc(token)
          .set({
            'token': token,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUsed': FieldValue.serverTimestamp(),
            'platform':
                kIsWeb
                    ? 'web'
                    : (defaultTargetPlatform == TargetPlatform.iOS
                        ? 'ios'
                        : 'android'),
            'isActive': true,
          }, SetOptions(merge: true));

      if (kDebugMode) {
        print(
          '✅ Token salvato in Firestore: ${token.length > 20 ? token.substring(0, 20) + '...' : token}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nel salvataggio del token in Firestore: $e');
      }
    }
  }

  /// Salva il token se l'utente è autenticato
  Future<void> _saveTokenIfAuthenticated(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _saveTokenToFirestore(token);
    } else {
      _pendingToken = token;
    }
  }

  /// Gestisci le notifiche in foreground
  void _handleForegroundMessage(RemoteMessage message) {
    // Qui puoi aggiungere la logica per mostrare notifiche locali
    // o aggiornare l'UI dell'app
    if (kDebugMode) {
      print('🔔 Gestione notifica foreground: ${message.notification?.title}');
    }
  }

  /// Invia notifica per prodotto sotto scorta
  Future<void> sendLowStockNotification({
    required String productName,
    required int currentQuantity,
    required int threshold,
  }) async {
    try {
      if (kDebugMode) {
        print('🔔 Invio notifica scorta bassa per: $productName');
      }

      if (kIsWeb) {
        await _fcmWebService.sendLowStockNotification(
          productName: productName,
          currentQuantity: currentQuantity,
          threshold: threshold,
        );
      } else {
        await _fcmNotificationService.sendLowStockNotification(
          productName: productName,
          currentQuantity: currentQuantity,
          threshold: threshold,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'invio notifica scorta bassa: $e');
      }
    }
  }

  /// Invia notifica per prodotto esaurito
  Future<void> sendOutOfStockNotification({required String productName}) async {
    try {
      if (kDebugMode) {
        print('🔔 Invio notifica prodotto esaurito per: $productName');
      }

      if (kIsWeb) {
        await _fcmWebService.sendOutOfStockNotification(
          productName: productName,
        );
      } else {
        await _fcmNotificationService.sendOutOfStockNotification(
          productName: productName,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'invio notifica prodotto esaurito: $e');
      }
    }
  }

  /// Invia notifica generica
  Future<void> sendNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print('🔔 Invio notifica generica: $title');
      }

      if (kIsWeb) {
        await _fcmWebService.sendNotificationToAllDevices(
          title: title,
          body: body,
          data: data,
        );
      } else {
        await _fcmNotificationService.sendNotificationToUser(
          title: title,
          body: body,
          data: data,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'invio notifica generica: $e');
      }
    }
  }

  /// Ottieni tutti i token dell'utente corrente
  Future<List<Map<String, dynamic>>> getCurrentUserTokens() async {
    try {
      if (kIsWeb) {
        return await _fcmWebService.getUserTokens();
      } else {
        return await _fcmNotificationService.getCurrentUserTokens();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nel recupero dei token: $e');
      }
      return [];
    }
  }

  /// Pulisce i token obsoleti
  Future<void> cleanupOldTokens() async {
    try {
      if (kIsWeb) {
        // La pulizia per web è gestita dal FCMWebService
        return;
      } else {
        await _fcmNotificationService.cleanupOldTokens();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nella pulizia dei token: $e');
      }
    }
  }

  /// Verifica se il servizio è inizializzato
  bool get isInitialized => _isInitialized;

  /// Ottieni il token pendente
  String? get pendingToken => _pendingToken;
}
