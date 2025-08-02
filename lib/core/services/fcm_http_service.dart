import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/product.dart';

/// Servizio per l'invio di notifiche push tramite Firebase Cloud Messaging.
/// Utilizza l'API HTTP di FCM per inviare notifiche a token singoli o gruppi.
class FCMHttpService {
  factory FCMHttpService() => _instance;
  FCMHttpService._internal();
  static final FCMHttpService _instance = FCMHttpService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // URL del servizio di notifiche Invory (API HTTP v1)
  static const String _apiUrl =
      'https://your-notification-service.railway.app'; // URL di produzione - cambia con il tuo
  static const String _apiKey =
      '790f63ac0c4d020fe9facf85cbba85cfce14f5e81d5d828e160e3ea61c414ee0'; // API key per autenticazione

  // Metodo per inviare notifica a un singolo token (API HTTP v1)
  Future<bool> sendToToken({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/test'),
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
        body: jsonEncode({
          'tokens': [token],
          'message': body,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] > 0;
      }

      return false;
    } on Exception catch (e) {
      debugPrint("Errore nell'invio notifica API v1: $e");
      return false;
    }
  }

  // Metodo per inviare notifica a più token (API HTTP v1)
  Future<Map<String, dynamic>> sendToMultipleTokens({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/test'),
        headers: {'Content-Type': 'application/json', 'x-api-key': _apiKey},
        body: jsonEncode({'tokens': tokens, 'message': body}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': responseData['success'] ?? 0,
          'failure': responseData['failure'] ?? 0,
          'results': responseData['results'] ?? [],
        };
      }

      return {'success': 0, 'failure': tokens.length, 'results': []};
    } on Exception catch (e) {
      debugPrint("Errore nell'invio notifica multipla API v1: $e");
      return {'success': 0, 'failure': tokens.length, 'results': []};
    }
  }

  // Metodo per inviare notifica a un utente specifico
  Future<bool> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Recupera tutti i token dell'utente direttamente da Firestore
      final tokens = await _getUserTokensFromFirestore(userId);

      if (tokens.isEmpty) {
        debugPrint("Nessun token trovato per l'utente: $userId");
        return false;
      }

      debugPrint("Trovati ${tokens.length} token per l'utente: $userId");

      final result = await sendToMultipleTokens(
        tokens: tokens,
        title: title,
        body: body,
        data: data,
      );

      // Gestisci token non validi
      if (result['results'] != null) {
        final results = result['results'] as List;
        final invalidTokens = <String>[];

        for (var i = 0; i < results.length; i++) {
          final resultItem = results[i];
          if (resultItem['error'] != null) {
            invalidTokens.add(tokens[i]);
          }
        }

        // Rimuovi token non validi
        if (invalidTokens.isNotEmpty) {
          await _removeInvalidTokens(userId, invalidTokens);
        }
      }

      return result['success'] > 0;
    } on Exception catch (e) {
      debugPrint("Errore nell'invio notifica all'utente: $e");
      return false;
    }
  }

  // Recupera i token dell'utente direttamente da Firestore
  Future<List<String>> _getUserTokensFromFirestore(String userId) async {
    try {
      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .where('isActive', isEqualTo: true)
          .get();

      return tokensSnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Errore nel recupero token da Firestore: $e');
      return [];
    }
  }

  // Metodo per rimuovere token non validi
  Future<void> _removeInvalidTokens(
    String userId,
    List<String> invalidTokens,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final token in invalidTokens) {
        final tokenRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('fcmTokens')
            .doc(token);
        batch.delete(tokenRef);
      }

      await batch.commit();
      debugPrint(
        "Rimossi ${invalidTokens.length} token non validi per l'utente: $userId",
      );
    } on Exception catch (e) {
      debugPrint('Errore nella rimozione dei token non validi: $e');
    }
  }

  // Verifica i token salvati per l'utente corrente
  Future<List<Map<String, dynamic>>> getCurrentUserTokens() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Utente non autenticato');
        return [];
      }

      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .get();

      final tokens = tokensSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'token': doc.id,
          'platform': data['platform'] ?? 'unknown',
          'isActive': data['isActive'] ?? false,
          'lastUsed': data['lastUsed']?.toDate()?.toString() ?? 'N/A',
          'createdAt': data['createdAt']?.toDate()?.toString() ?? 'N/A',
        };
      }).toList();

      debugPrint('Trovati ${tokens.length} token per l\'utente corrente');
      return tokens;
    } catch (e) {
      debugPrint('Errore nel recupero token utente corrente: $e');
      return [];
    }
  }

  // Testa la connessione API
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/health'),
        headers: {'x-api-key': _apiKey},
      );

      // Se riceviamo una risposta 200, significa che il servizio è raggiungibile
      return response.statusCode == 200;
    } on Exception catch (e) {
      debugPrint('Errore nel test della connessione API: $e');
      return false;
    }
  }

  // NUOVI METODI PER GESTIONE TOKEN FCM

  // Salva o aggiorna il token FCM
  Future<void> saveToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('Utente non autenticato, impossibile salvare il token FCM');
        return;
      }

      debugPrint('Salvando token FCM per utente: ${user.uid}');
      debugPrint('Token: ${token.substring(0, 20)}...');

      // Salva direttamente in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'token': token,
            'platform': getPlatform(),
            'lastUsed': FieldValue.serverTimestamp(),
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint('Token FCM salvato con successo in Firestore');

      // Opzionalmente, invia anche al servizio Node.js per backup
      try {
        await _sendTokenToNotificationService(token, user.uid);
      } catch (e) {
        debugPrint('Errore nell\'invio token al servizio di notifiche: $e');
        // Non bloccare il flusso principale se il servizio è down
      }
    } catch (e) {
      debugPrint('Errore nel salvataggio del token FCM: $e');
      rethrow;
    }
  }

  // Metodo per inviare il token al servizio di notifiche (opzionale)
  Future<void> _sendTokenToNotificationService(String token, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/save-token'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: jsonEncode({
          'token': token,
          'platform': getPlatform(),
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Token inviato con successo al servizio di notifiche');
      } else {
        debugPrint('Errore nell\'invio token al servizio: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Errore nella comunicazione con il servizio di notifiche: $e');
    }
  }

  // Disattiva un token FCM
  Future<void> deactivateToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token)
          .update({'isActive': false});
    } catch (e) {
      debugPrint('Errore nella disattivazione del token FCM: $e');
    }
  }

  // Controlla e invia notifiche per prodotto sotto soglia
  Future<void> checkAndNotifyLowStock(Product product) async {
    if (!product.isLowStock) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title =
        product.quantita == 0 ? 'Prodotto Esaurito!' : 'Scorte in Esaurimento';

    final body =
        product.quantita == 0
            ? '${product.nome} è esaurito!'
            : '${product.nome} ha raggiunto la soglia minima (${product.quantita}/${product.soglia})';

    await sendToUser(
      userId: user.uid,
      title: title,
      body: body,
      data: {
        'type': product.quantita == 0 ? 'out_of_stock' : 'low_stock',
        'productId': product.id,
      },
    );
  }

  // Ottieni la piattaforma corrente
  String getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }
}
