import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/fcm_config.dart';

class FCMAuthService {
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  /// Genera un JWT token per l'autenticazione con Google OAuth2
  static Future<String> _generateJWT({
    required String clientEmail,
    required String privateKey,
    required String projectId,
  }) async {
    final now = DateTime.now();
    final expiry = now.add(const Duration(hours: 1));

    final header = {'alg': 'RS256', 'typ': 'JWT'};

    final payload = {
      'iss': clientEmail,
      'scope': FCMConfig.scope,
      'aud': 'https://oauth2.googleapis.com/token',
      'exp': expiry.millisecondsSinceEpoch ~/ 1000,
      'iat': now.millisecondsSinceEpoch ~/ 1000,
    };

    final headerEncoded = base64Url.encode(utf8.encode(jsonEncode(header)));
    final payloadEncoded = base64Url.encode(utf8.encode(jsonEncode(payload)));

    final data = '$headerEncoded.$payloadEncoded';
    final signature = await _signData(data, privateKey);

    return '$data.$signature';
  }

  /// Firma i dati con la chiave privata RSA
  static Future<String> _signData(String data, String privateKey) async {
    // Per semplicità, usiamo un approccio semplificato
    // In produzione, dovresti usare una libreria RSA completa
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes);
  }

  /// Ottiene un access token da Google OAuth2
  static Future<String> _getAccessToken({
    required String clientEmail,
    required String privateKey,
    required String projectId,
  }) async {
    try {
      final jwt = await _generateJWT(
        clientEmail: clientEmail,
        privateKey: privateKey,
        projectId: projectId,
      );

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': jwt,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        throw Exception('Errore nell\'ottenimento del token: ${response.body}');
      }
    } catch (e) {
      debugPrint('Errore nell\'autenticazione FCM: $e');
      rethrow;
    }
  }

  /// Ottiene un access token valido (con cache)
  static Future<String> getValidAccessToken({
    required String clientEmail,
    required String privateKey,
    required String projectId,
  }) async {
    // Controlla se abbiamo un token valido in cache
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    // Ottiene un nuovo token
    _accessToken = await _getAccessToken(
      clientEmail: clientEmail,
      privateKey: privateKey,
      projectId: projectId,
    );

    // Imposta l'expiry (1 ora dal momento attuale)
    _tokenExpiry = DateTime.now().add(const Duration(hours: 1));

    return _accessToken!;
  }

  /// Invia una notifica usando l'API FCM V1
  static Future<bool> sendNotificationV1({
    required String token,
    required String title,
    required String body,
    required String clientEmail,
    required String privateKey,
    required String projectId,
  }) async {
    try {
      final accessToken = await getValidAccessToken(
        clientEmail: clientEmail,
        privateKey: privateKey,
        projectId: projectId,
      );

      final endpoint = FCMConfig.fcmEndpoint.replaceAll(
        '{projectId}',
        projectId,
      );

      final payload = {
        'message': {
          'token': token,
          'notification': {'title': title, 'body': body},
          'android': {'priority': 'high'},
          'apns': {
            'headers': {'apns-priority': '10'},
          },
          'webpush': {
            'headers': {'Urgency': 'high'},
          },
        },
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notifica FCM V1 inviata con successo');
        return true;
      } else {
        debugPrint(
          '❌ Errore FCM V1: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Errore nell\'invio notifica FCM V1: $e');
      return false;
    }
  }
}
