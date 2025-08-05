import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:js' as js;

class FCMWebService {
  static final FCMWebService _instance = FCMWebService._internal();
  factory FCMWebService() => _instance;
  FCMWebService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _currentToken;
  bool _isInitialized = false;

  /// Inizializza il servizio web
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('🔧 FCM Web Service già inizializzato');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('🔧 Inizializzazione servizio notifiche web...');
      }

      // Richiedi permessi per le notifiche
      if (html.Notification.permission == 'default') {
        final permission = await html.Notification.requestPermission();
        if (kDebugMode) {
          print('🔔 Permesso notifiche web: $permission');
        }
      }

      // Genera e salva l'ID del dispositivo se non esiste
      final deviceId = _getDeviceId();
      if (html.window.localStorage['deviceId'] == null) {
        html.window.localStorage['deviceId'] = deviceId;
        if (kDebugMode) {
          print(
            '📱 Nuovo ID dispositivo generato: ${deviceId.length > 20 ? deviceId.substring(0, 20) + '...' : deviceId}',
          );
        }
      }

      // Ottieni il token FCM per il web
      await _getAndSaveToken();

      // Configura il listener per le notifiche in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print(
            '🔔 Notifica ricevuta in foreground: ${message.notification?.title}',
          );
        }
        _showLocalNotification(message);
      });

      // Configura il listener per i cambiamenti del token
      _messaging.onTokenRefresh.listen((newToken) {
        if (kDebugMode) {
          print('🔄 Token FCM aggiornato');
        }
        _currentToken = newToken;
        saveToken(newToken);
      });

      _isInitialized = true;

      if (kDebugMode) {
        print('✅ Servizio FCM Web inizializzato con successo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'inizializzazione servizio web: $e');
      }
    }
  }

  /// Ottieni e salva il token FCM
  Future<void> _getAndSaveToken() async {
    try {
      // Prova prima dal localStorage (se già generato dal JavaScript)
      final storedToken = html.window.localStorage['fcm_token'];
      if (storedToken != null && storedToken.isNotEmpty) {
        _currentToken = storedToken;
        await saveToken(storedToken);
        if (kDebugMode) {
          print('✅ Token FCM recuperato dal localStorage');
        }
        return;
      }

      // Altrimenti, ottieni il token tramite Firebase Messaging
      final fcmToken = await _messaging.getToken();
      if (fcmToken != null) {
        _currentToken = fcmToken;
        await saveToken(fcmToken);
        if (kDebugMode) {
          print('✅ Token FCM generato tramite Firebase Messaging');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Impossibile ottenere token FCM');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'ottenimento del token FCM: $e');
      }
    }
  }

  /// Genera un ID univoco per il browser
  String _generateBrowserId() {
    final userAgent = html.window.navigator.userAgent;
    final platform = html.window.navigator.platform;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random =
        timestamp.toString() + (100000 + DateTime.now().microsecond).toString();

    // Crea un hash univoco per questo browser
    final hash = '$userAgent-$platform-$random'.hashCode.toString();
    return 'web_${hash}_${timestamp}';
  }

  /// Ottieni l'ID del dispositivo corrente
  String _getDeviceId() {
    return html.window.localStorage['deviceId'] ?? _generateBrowserId();
  }

  /// Salva il token FCM nel database
  Future<void> saveToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('⚠️ Utente non autenticato, impossibile salvare il token FCM');
        }
        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc(token)
          .set({
            'token': token,
            'deviceId': _getDeviceId(),
            'createdAt': FieldValue.serverTimestamp(),
            'lastUsed': FieldValue.serverTimestamp(),
            'platform': 'web',
            'isActive': true,
            'userAgent': html.window.navigator.userAgent,
            'platform': html.window.navigator.platform,
          }, SetOptions(merge: true));

      if (kDebugMode) {
        print(
          '✅ Token FCM web salvato: ${token.length > 20 ? token.substring(0, 20) + '...' : token}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nel salvataggio del token FCM web: $e');
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
              .collection('tokens')
              .where('platform', isEqualTo: 'web')
              .where('isActive', isEqualTo: true)
              .get();

      return querySnapshot.docs
          .map(
            (doc) => {
              'token': doc.data()['token'],
              'deviceId': doc.data()['deviceId'],
              'lastUsed': doc.data()['lastUsed'],
            },
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nel recupero dei token web: $e');
      }
      return [];
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
        print('🔔 Invio notifica a tutti i dispositivi: $title');
      }

      // Ottieni tutti i token attivi dell'utente
      final tokens = await getUserTokens();
      if (tokens.isEmpty) {
        if (kDebugMode) {
          print('❌ Nessun dispositivo registrato per le notifiche');
        }
        return;
      }

      final currentDeviceId = _getDeviceId();
      if (kDebugMode) {
        print(
          '📱 Dispositivo corrente: ${currentDeviceId.length > 20 ? currentDeviceId.substring(0, 20) + '...' : currentDeviceId}',
        );
        print('📱 Trovati ${tokens.length} dispositivi registrati');
      }

      // Crea un ID univoco per questa notifica per evitare duplicati
      final notificationId =
          '${DateTime.now().millisecondsSinceEpoch}_${title.hashCode}_${currentDeviceId}';

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
                '⏭️ SALTO dispositivo corrente (modificatore): ${deviceId.length > 20 ? deviceId.substring(0, 20) + '...' : deviceId}',
              );
            }
            continue; // IMPORTANTE: salta completamente questo dispositivo
          }

          // Invia la notifica FCM al dispositivo specifico
          await _sendFCMNotification(token, title, body, data, notificationId);
          notificationsSent++;

          if (kDebugMode) {
            print(
              '✅ Notifica FCM inviata al dispositivo: ${deviceId.length > 20 ? deviceId.substring(0, 20) + '...' : deviceId}',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              '❌ Errore nell\'invio della notifica al dispositivo: ${deviceId.length > 20 ? deviceId.substring(0, 20) + '...' : deviceId} - $e',
            );
          }
        }
      }

      if (kDebugMode) {
        print(
          '✅ Notifiche inviate a $notificationsSent dispositivi (escluso il modificatore)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'invio delle notifiche: $e');
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
              '⚠️ Notifica già inviata, salto duplicato per token: ${fcmToken.length > 20 ? fcmToken.substring(0, 20) + '...' : fcmToken}',
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
            '📝 Notifica salvata in Firestore per dispositivo: ${fcmToken.length > 20 ? fcmToken.substring(0, 20) + '...' : fcmToken}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'invio notifica FCM al dispositivo $fcmToken: $e');
      }
    }
  }

  /// Mostra notifica locale
  void _showLocalNotification(RemoteMessage message) {
    if (html.Notification.permission == 'granted') {
      final notification = html.Notification(
        message.notification?.title ?? 'Notifica Invory',
        body: message.notification?.body ?? '',
        icon: '/invory/icons/Icon-192.png',
        tag: 'invory_notification_${DateTime.now().millisecondsSinceEpoch}',
      );

      notification.onClick.listen((event) {
        if (kDebugMode) {
          print('🔔 Notifica locale cliccata: ${message.notification?.title}');
        }
        notification.close();
      });
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
        print('🔔 INVIO NOTIFICA SCORTA BASSA per: $productName');
        print('   Quantità: $currentQuantity, Soglia: $threshold');
        print('📱 Dispositivo corrente: ${_getDeviceId()}');
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
        print('✅ NOTIFICA SCORTA BASSA COMPLETATA per: $productName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'invio della notifica di scorta bassa: $e');
      }
    }
  }

  /// Invia notifica per prodotto esaurito
  Future<void> sendOutOfStockNotification({required String productName}) async {
    try {
      if (kDebugMode) {
        print('🔔 Invio notifica prodotto esaurito per: $productName');
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
        print('❌ Errore nell\'invio della notifica di esaurimento: $e');
      }
    }
  }

  /// Controlla se ha i permessi
  bool hasPermission() {
    return html.Notification.permission == 'granted';
  }

  /// Controlla se può installare PWA
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
        print('❌ Errore nel mostrare il prompt di installazione: $e');
      }
    }
  }

  /// Ottieni il token corrente
  String? get currentToken => _currentToken;

  /// Verifica se il servizio è inizializzato
  bool get isInitialized => _isInitialized;
}
