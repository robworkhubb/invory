import 'dart:html' as html;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:js' as js;
import '../config/app_config.dart';
import 'service_worker_manager.dart';

class FCMWebService {
  static final FCMWebService _instance = FCMWebService._internal();
  factory FCMWebService() => _instance;
  FCMWebService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ServiceWorkerManager _swManager = ServiceWorkerManager();

  String? _currentToken;
  bool _isInitialized = false;
  bool _permissionsGranted = false;
  final Completer<void> _initializationCompleter = Completer<void>();

  /// Inizializza il servizio web con gestione migliorata
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('${AppConfig.logPrefix} 🔧 FCM Web Service già inizializzato');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} 🔧 Inizializzazione servizio notifiche web...',
        );
      }

      // Verifica configurazione Firebase
      if (!AppConfig.isFirebaseConfigured) {
        throw Exception(AppConfig.errorFirebaseNotInitialized);
      }

      // Verifica VAPID key se richiesta
      if (AppConfig.enableVapidKeyValidation && !AppConfig.hasVapidKey) {
        if (kDebugMode) {
          print('${AppConfig.logPrefix} ⚠️ VAPID_KEY mancante ma richiesta');
        }
        // Non bloccare l'inizializzazione, ma loggare l'avviso
      }

      // Inizializza il Service Worker in parallelo
      final swFuture = _swManager.initialize();

      // Richiedi permessi per le notifiche
      await _requestNotificationPermissions();

      // Aspetta che il Service Worker sia pronto
      await swFuture;

      // Genera e salva l'ID del dispositivo se non esiste
      final deviceId = _getDeviceId();
      if (html.window.localStorage['deviceId'] == null) {
        html.window.localStorage['deviceId'] = deviceId;
        if (kDebugMode) {
          print(
            '${AppConfig.logPrefix} 📱 Nuovo ID dispositivo generato: ${deviceId.length > 20 ? '${deviceId.substring(0, 20)}...' : deviceId}',
          );
        }
      }

      // Ottieni il token FCM per il web con retry
      await _getAndSaveTokenWithRetry();

      // Configura i listener per le notifiche
      _setupNotificationListeners();

      _isInitialized = true;
      _initializationCompleter.complete();

      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ✅ Servizio FCM Web inizializzato con successo',
        );
      }
    } catch (e) {
      _initializationCompleter.completeError(e);
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ❌ Errore nell\'inizializzazione servizio web: $e',
        );
      }
      rethrow;
    }
  }

  /// Richiede i permessi per le notifiche con gestione migliorata
  Future<void> _requestNotificationPermissions() async {
    try {
      if (html.Notification.permission == 'default') {
        if (kDebugMode) {
          print('${AppConfig.logPrefix} 🔔 Richiesta permessi notifiche...');
        }

        final permission = await html.Notification.requestPermission();
        _permissionsGranted = permission == 'granted';

        if (kDebugMode) {
          print(
            '${AppConfig.logPrefix} 🔔 Permesso notifiche web: $permission',
          );
        }
      } else {
        _permissionsGranted = html.Notification.permission == 'granted';
        if (kDebugMode) {
          print(
            '${AppConfig.logPrefix} 🔔 Permesso notifiche già: ${html.Notification.permission}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('${AppConfig.logPrefix} ❌ Errore richiesta permessi: $e');
      }
      _permissionsGranted = false;
    }
  }

  /// Ottieni e salva il token FCM con retry logic migliorata
  Future<void> _getAndSaveTokenWithRetry() async {
    int attempts = 0;

    while (attempts < AppConfig.maxRetryAttempts) {
      try {
        attempts++;

        if (kDebugMode) {
          print(
            '${AppConfig.logPrefix} 🔧 Tentativo generazione token FCM $attempts/${AppConfig.maxRetryAttempts}',
          );
        }

        // Prova prima dal localStorage (se già generato dal JavaScript)
        final storedToken = html.window.localStorage['fcm_token'];
        if (storedToken != null && storedToken.isNotEmpty) {
          _currentToken = storedToken;
          await saveToken(storedToken);
          if (kDebugMode) {
            print(
              '${AppConfig.logPrefix} ✅ Token FCM recuperato dal localStorage',
            );
          }
          return;
        }

        // Se non c'è token salvato, prova a generarne uno nuovo
        if (_permissionsGranted) {
          final token = await _generateFCMToken();
          if (token != null && token.isNotEmpty) {
            _currentToken = token;
            await saveToken(token);
            if (kDebugMode) {
              print('${AppConfig.logPrefix} ✅ Nuovo token FCM generato');
            }
            return;
          }
        }

        // Se arriviamo qui, non è stato possibile generare il token
        throw Exception('Impossibile generare token FCM');
      } catch (e) {
        if (kDebugMode) {
          print('${AppConfig.logPrefix} ⚠️ Tentativo $attempts fallito: $e');
        }

        if (attempts < AppConfig.maxRetryAttempts) {
          await Future.delayed(AppConfig.retryDelay * attempts);
        }
      }
    }

    if (kDebugMode) {
      print(
        '${AppConfig.logPrefix} ⚠️ Impossibile generare token FCM dopo ${AppConfig.maxRetryAttempts} tentativi',
      );
    }
    // Non lanciare eccezione, permette all'app di continuare senza notifiche
  }

  /// Genera un token FCM per il web
  Future<String?> _generateFCMToken() async {
    try {
      // Usa il JavaScript per generare il token
      final result = js.context.callMethod('eval', [
        '''
        (async () => {
          try {
            if (window.firebaseMessaging && window.firebaseMessaging.getToken) {
              return await window.firebaseMessaging.getToken();
            }
            return null;
          } catch (e) {
            console.error('Errore generazione token:', e);
            return null;
          }
        })()
      ''',
      ]);

      if (result != null && result.toString().isNotEmpty) {
        return result.toString();
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ❌ Errore generazione token JavaScript: $e',
        );
      }
    }

    return null;
  }

  /// Configura i listener per le notifiche
  void _setupNotificationListeners() {
    // Configura il listener per le notifiche in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} 🔔 Notifica ricevuta in foreground: ${message.notification?.title}',
        );
      }
      _showLocalNotification(message);
    });

    // Configura il listener per i cambiamenti del token
    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('${AppConfig.logPrefix} 🔄 Token FCM aggiornato');
      }
      _currentToken = newToken;
      saveToken(newToken);
    });

    // Configura il listener per le notifiche cliccate
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('${AppConfig.logPrefix} 🔔 Notifica aperta: ${message.data}');
      }
      _handleNotificationClick(message);
    });
  }

  /// Gestisce il click su una notifica
  void _handleNotificationClick(RemoteMessage message) {
    // Implementazione per gestire il click sulle notifiche
    if (kDebugMode) {
      print(
        '${AppConfig.logPrefix} 🔔 Gestione click notifica: ${message.data}',
      );
    }
  }

  /// Mostra una notifica locale
  void _showLocalNotification(RemoteMessage message) {
    if (!_permissionsGranted) return;

    try {
      final notification = html.Notification(
        message.notification?.title ?? 'Invory',
        body: message.notification?.body ?? '',
        icon: '${AppConfig.webBaseUrl}icons/Icon-192.png',
        tag: 'invory_notification',
      );

      notification.onClick.listen((event) {
        if (kDebugMode) {
          print('${AppConfig.logPrefix} 🔔 Notifica locale cliccata');
        }
        notification.close();
      });

      if (kDebugMode) {
        print('${AppConfig.logPrefix} 🔔 Notifica locale mostrata');
      }
    } catch (e) {
      if (kDebugMode) {
        print('${AppConfig.logPrefix} ❌ Errore mostra notifica locale: $e');
      }
    }
  }

  /// Genera un ID dispositivo univoco
  String _getDeviceId() {
    final existingId = html.window.localStorage['deviceId'];
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    // Genera un ID univoco basato su timestamp e random
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return 'web_${timestamp}_$random';
  }

  /// Salva il token in Firestore
  Future<void> saveToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print(
            '${AppConfig.logPrefix} ⚠️ Utente non autenticato, token salvato in locale',
          );
        }
        html.window.localStorage['fcm_token'] = token;
        return;
      }

      final deviceId = html.window.localStorage['deviceId'] ?? _getDeviceId();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId)
          .set({
            'token': token,
            'platform': 'web',
            'lastSeen': FieldValue.serverTimestamp(),
            'userAgent': html.window.navigator.userAgent,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (kDebugMode) {
        print('${AppConfig.logPrefix} ✅ Token salvato in Firestore');
      }
    } catch (e) {
      if (kDebugMode) {
        print('${AppConfig.logPrefix} ❌ Errore salvataggio token: $e');
      }
      // Fallback: salva in localStorage
      html.window.localStorage['fcm_token'] = token;
    }
  }

  /// Verifica se ha i permessi
  bool hasPermission() => _permissionsGranted;

  /// Ottiene il token corrente
  String? get currentToken => _currentToken;

  /// Verifica se è inizializzato
  bool get isInitialized => _isInitialized;

  /// Ottiene il future di inizializzazione
  Future<void> get initializationFuture => _initializationCompleter.future;

  /// Pulisce i dati del servizio
  void cleanup() {
    _currentToken = null;
    _isInitialized = false;
    _permissionsGranted = false;
    if (kDebugMode) {
      print('${AppConfig.logPrefix} 🧹 FCM Web Service pulito');
    }
  }

  /// Verifica se può installare PWA
  bool canInstallPWA() {
    return html.window.localStorage['beforeinstallprompt'] == 'true';
  }

  /// Mostra prompt di installazione PWA
  Future<void> showInstallPrompt() async {
    try {
      // Chiama la funzione JavaScript per mostrare il prompt
      js.context.callMethod('showInstallPrompt');
    } catch (e) {
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ❌ Errore nel mostrare il prompt di installazione: $e',
        );
      }
    }
  }

  /// Ottiene tutti i token dell'utente
  Future<List<Map<String, dynamic>>> getUserTokens() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('devices')
              .where('platform', isEqualTo: 'web')
              .get();

      return querySnapshot.docs
          .map(
            (doc) => {
              'token': doc.data()['token'],
              'deviceId': doc.id,
              'lastSeen': doc.data()['lastSeen'],
            },
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('${AppConfig.logPrefix} ❌ Errore nel recupero dei token web: $e');
      }
      return [];
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
        print(
          '${AppConfig.logPrefix} 🔔 INVIO NOTIFICA SCORTA BASSA per: $productName',
        );
        print(
          '${AppConfig.logPrefix}    Quantità: $currentQuantity, Soglia: $threshold',
        );
      }

      final title = 'Prodotto sotto scorta';
      final body =
          'Il prodotto $productName è sotto la soglia ($currentQuantity/$threshold)';

      final data = {
        'type': 'low_stock',
        'productName': productName,
        'currentQuantity': currentQuantity.toString(),
        'threshold': threshold.toString(),
      };

      await sendNotificationToAllDevices(title: title, body: body, data: data);

      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ✅ NOTIFICA SCORTA BASSA COMPLETATA per: $productName',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ❌ Errore nell\'invio della notifica di scorta bassa: $e',
        );
      }
    }
  }

  /// Invia notifica per prodotto esaurito
  Future<void> sendOutOfStockNotification({required String productName}) async {
    try {
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} 🔔 Invio notifica prodotto esaurito per: $productName',
        );
      }

      final title = 'Prodotto esaurito';
      final body = 'Il prodotto $productName è completamente esaurito';

      final data = {
        'type': 'out_of_stock',
        'productName': productName,
        'currentQuantity': '0',
      };

      await sendNotificationToAllDevices(title: title, body: body, data: data);
    } catch (e) {
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ❌ Errore nell\'invio della notifica di esaurimento: $e',
        );
      }
    }
  }

  /// Invia notifica a tutti i dispositivi registrati (tranne quello che ha fatto la modifica)
  Future<void> sendNotificationToAllDevices({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} 🔔 Invio notifica a tutti i dispositivi: $title',
        );
      }

      // Ottieni tutti i token attivi dell'utente
      final tokens = await getUserTokens();
      if (tokens.isEmpty) {
        if (kDebugMode) {
          print(
            '${AppConfig.logPrefix} ❌ Nessun dispositivo registrato per le notifiche',
          );
        }
        return;
      }

      final currentDeviceId = _getDeviceId();
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} 📱 Dispositivo corrente: ${currentDeviceId.length > 20 ? '${currentDeviceId.substring(0, 20)}...' : currentDeviceId}',
        );
        print(
          '${AppConfig.logPrefix} 📱 Trovati ${tokens.length} dispositivi registrati',
        );
      }

      // Crea un ID univoco per questa notifica per evitare duplicati
      final notificationId =
          '${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}_$currentDeviceId';

      // Invia la notifica a tutti i dispositivi TRANNE quello corrente
      int notificationsSent = 0;
      for (final tokenData in tokens) {
        final token = tokenData['token'];
        final deviceId = tokenData['deviceId'];

        try {
          // SALTA il dispositivo corrente (quello che ha fatto la modifica)
          if (deviceId == currentDeviceId) {
            if (kDebugMode) {
              print(
                '${AppConfig.logPrefix} ⏭️ SALTO dispositivo corrente (modificatore): ${deviceId.length > 20 ? deviceId.substring(0, 20) + '...' : deviceId}',
              );
            }
            continue; // IMPORTANTE: salta completamente questo dispositivo
          }

          // Invia la notifica FCM al dispositivo specifico
          await _sendFCMNotification(token, title, body, data, notificationId);
          notificationsSent++;

          if (kDebugMode) {
            print(
              '${AppConfig.logPrefix} ✅ Notifica FCM inviata al dispositivo: ${deviceId.length > 20 ? deviceId.substring(0, 20) + '...' : deviceId}',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '${AppConfig.logPrefix} ❌ Errore nell\'invio della notifica al dispositivo: ${deviceId.length > 20 ? deviceId.substring(0, 20) + '...' : deviceId} - $e',
            );
          }
        }
      }

      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ✅ Notifiche inviate a $notificationsSent dispositivi (escluso il modificatore)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ❌ Errore nell\'invio delle notifiche: $e',
        );
      }
    }
  }

  /// Invia notifica FCM a un dispositivo specifico
  Future<void> _sendFCMNotification(
    String fcmToken,
    String title,
    String body,
    Map<String, dynamic>? data,
    String notificationId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // CONTROLLO DUPLICATI: Verifica se la notifica è già stata inviata
        final existingNotification =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .where('notificationId', isEqualTo: notificationId)
                .where('targetDeviceId', isEqualTo: fcmToken)
                .limit(1) // Limita a 1 risultato per efficienza
                .get();

        if (existingNotification.docs.isNotEmpty) {
          if (kDebugMode) {
            print(
              '${AppConfig.logPrefix} ⚠️ Notifica già inviata, salto duplicato per token: ${fcmToken.length > 20 ? '${fcmToken.substring(0, 20)}...' : fcmToken}',
            );
          }
          return; // Esci senza salvare la notifica
        }

        // Salva la notifica solo se non esiste già
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
              'title': title,
              'body': body,
              'data': data,
              'timestamp': FieldValue.serverTimestamp(),
              'read': false,
              'targetDeviceId': fcmToken,
              'notificationId': notificationId,
              'sourceDeviceId':
                  _getDeviceId(), // Aggiungi il dispositivo sorgente
            });

        if (kDebugMode) {
          print(
            '${AppConfig.logPrefix} 📝 Notifica salvata in Firestore per dispositivo: ${fcmToken.length > 20 ? '${fcmToken.substring(0, 20)}...' : fcmToken}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ❌ Errore nell\'invio notifica FCM al dispositivo $fcmToken: $e',
        );
      }
    }
  }
}
