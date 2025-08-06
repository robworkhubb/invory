import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class FCMNotificationService {
  static final FCMNotificationService _instance =
      FCMNotificationService._internal();
  factory FCMNotificationService() => _instance;
  FCMNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Configurazione FCM
  static const String _fcmEndpoint = 'https://fcm.googleapis.com/v1/projects/';
  static const String _projectId =
      'invory-b9a72'; // Project ID dal firebase-messaging-sw.js

  /// Inizializza il servizio FCM
  Future<void> initialize() async {
    // Non inizializzare FCM sul web
    if (kIsWeb) {
      if (kDebugMode) {
        print('FCM non inizializzato sul web - usa FCMWebService');
      }
      return;
    }

    try {
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
        print('Permessi notifiche: ${settings.authorizationStatus}');
      }

      // Ottieni il token FCM
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      // Ascolta i cambiamenti del token
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
      });

      // Gestisci le notifiche in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print(
            'Notifica ricevuta in foreground: ${message.notification?.title}',
          );
        }
        // Qui puoi aggiungere la logica per mostrare la notifica localmente
      });
    } catch (e) {
      if (kDebugMode) {
        print('Errore nell\'inizializzazione FCM: $e');
      }
    }
  }

  /// Salva il token FCM nel database
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
            'platform': Platform.isIOS ? 'ios' : 'android',
          });

      if (kDebugMode) {
        print(
          'Token FCM salvato: ${token.length > 20 ? '${token.substring(0, 20)}...' : token}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nel salvataggio del token: $e');
      }
    }
  }

  /// Ottiene tutti i token dell'utente corrente
  Future<List<String>> _getUserTokens() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('tokens')
              .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['token'] as String)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Errore nel recupero dei token: $e');
      }
      return [];
    }
  }

  /// Ottiene il token corrente del dispositivo
  Future<String?> _getCurrentToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Errore nell\'ottenimento del token corrente: $e');
      }
      return null;
    }
  }

  /// Ottiene tutti i token dell'utente corrente con dettagli (per debug)
  Future<List<Map<String, dynamic>>> getCurrentUserTokens() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('Utente non autenticato');
        }
        return [];
      }

      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('tokens')
              .get();

      final tokens =
          querySnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'token': doc.id,
              'platform': data['platform'] ?? 'unknown',
              'isActive': data['isActive'] ?? true,
              'lastUsed': data['lastUsed']?.toDate()?.toString() ?? 'N/A',
              'createdAt': data['createdAt']?.toDate()?.toString() ?? 'N/A',
            };
          }).toList();

      if (kDebugMode) {
        print('Trovati ${tokens.length} token per l\'utente corrente');
      }
      return tokens;
    } catch (e) {
      if (kDebugMode) {
        print('Errore nel recupero token utente corrente: $e');
      }
      return [];
    }
  }

  /// Ottiene l'access token per autenticare le chiamate a FCM
  Future<String?> _getAccessToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Per il web, usiamo l'ID token di Firebase Auth
      // Per mobile, potremmo aver bisogno di un approccio diverso
      final idToken = await user.getIdToken();

      if (kDebugMode && idToken != null) {
        print('Access token ottenuto: ${idToken.substring(0, 20)}...');
      }

      return idToken;
    } catch (e) {
      if (kDebugMode) {
        print('Errore nell\'ottenimento dell\'access token: $e');
      }
      return null;
    }
  }

  /// Invia una notifica push a tutti i dispositivi dell'utente (tranne quello corrente)
  Future<void> sendNotificationToUser({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Non inviare FCM dal web
    if (kIsWeb) {
      if (kDebugMode) {
        print('FCM non supportato sul web - usa FCMWebService');
      }
      return;
    }

    try {
      final tokens = await _getUserTokens();
      if (tokens.isEmpty) {
        if (kDebugMode) {
          print('Nessun token trovato per l\'utente');
        }
        return;
      }

      final currentToken = await _getCurrentToken();
      if (kDebugMode) {
        print('Token corrente: ${currentToken?.substring(0, 20) ?? 'null'}...');
        print('Trovati ${tokens.length} token totali');
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        if (kDebugMode) {
          print('Impossibile ottenere l\'access token');
        }
        return;
      }

      // Invia la notifica a tutti i token TRANNE quello corrente
      int notificationsSent = 0;
      for (String token in tokens) {
        // Salta il token corrente (dispositivo che ha fatto la modifica)
        if (currentToken != null && token == currentToken) {
          if (kDebugMode) {
            print(
              '⏭️ Salto token corrente (modificatore): ${token.substring(0, 20)}...',
            );
          }
          continue;
        }

        await _sendSingleNotification(
          token: token,
          title: title,
          body: body,
          data: data,
          accessToken: accessToken,
        );
        notificationsSent++;
      }

      if (kDebugMode) {
        print(
          'Notifiche inviate a $notificationsSent dispositivi (escluso il modificatore)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nell\'invio della notifica: $e');
      }
    }
  }

  /// Invia una singola notifica a un token specifico
  Future<void> _sendSingleNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    required String accessToken,
  }) async {
    try {
      final url = '$_fcmEndpoint$_projectId/messages:send';

      final message = {
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body},
          'data': data ?? {},
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'low_stock_alerts',
              'priority': 'high',
              'default_sound': true,
              'default_vibrate_timings': true,
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {'title': title, 'body': body},
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print(
            'Notifica inviata con successo al token: ${token.substring(0, 20)}...',
          );
        }
      } else {
        if (kDebugMode) {
          print(
            'Errore nell\'invio della notifica: ${response.statusCode} - ${response.body}',
          );
        }

        // Se il token non è valido, rimuovilo dal database
        if (response.statusCode == 404 || response.statusCode == 400) {
          await _removeInvalidToken(token);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nell\'invio della notifica singola: $e');
      }
    }
  }

  /// Rimuove un token non valido dal database
  Future<void> _removeInvalidToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc(token)
          .delete();

      if (kDebugMode) {
        print('Token non valido rimosso: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nella rimozione del token non valido: $e');
      }
    }
  }

  /// Invia una notifica per prodotto sotto scorta
  Future<void> sendLowStockNotification({
    required String productName,
    required int currentQuantity,
    required int threshold,
  }) async {
    // Non inviare FCM dal web
    if (kIsWeb) {
      if (kDebugMode) {
        print('FCM low stock non supportato sul web - usa FCMWebService');
      }
      return;
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

    await sendNotificationToUser(title: title, body: body, data: data);
  }

  /// Invia una notifica per prodotto esaurito
  Future<void> sendOutOfStockNotification({required String productName}) async {
    // Non inviare FCM dal web
    if (kIsWeb) {
      if (kDebugMode) {
        print('FCM out of stock non supportato sul web - usa FCMWebService');
      }
      return;
    }

    final title = 'Prodotto esaurito';
    final body = 'Il prodotto $productName è completamente esaurito';

    final data = {
      'type': 'out_of_stock',
      'productName': productName,
      'currentQuantity': '0',
    };

    await sendNotificationToUser(title: title, body: body, data: data);
  }

  /// Pulisce i token obsoleti (opzionale)
  Future<void> cleanupOldTokens() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('tokens')
              .where('lastUsed', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
              .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      if (kDebugMode) {
        print('Puliti ${querySnapshot.docs.length} token obsoleti');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nella pulizia dei token: $e');
      }
    }
  }
}
