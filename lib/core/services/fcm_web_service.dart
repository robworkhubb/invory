import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servizio specifico per le notifiche web che funziona senza backend
class FCMWebService {
  static final FCMWebService _instance = FCMWebService._internal();
  factory FCMWebService() => _instance;
  FCMWebService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Inizializza il servizio web
  Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('Inizializzazione servizio notifiche web...');
      }

      // Richiedi permessi per le notifiche
      if (html.Notification.permission == 'default') {
        final permission = await html.Notification.requestPermission();
        if (kDebugMode) {
          print('Permesso notifiche web: $permission');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nell\'inizializzazione servizio web: $e');
      }
    }
  }

  /// Salva il token FCM nel database
  Future<void> saveToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('Utente non autenticato, impossibile salvare il token FCM');
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
            'createdAt': FieldValue.serverTimestamp(),
            'lastUsed': FieldValue.serverTimestamp(),
            'platform': 'web',
            'isActive': true,
          }, SetOptions(merge: true));

      if (kDebugMode) {
        print('Token FCM web salvato: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nel salvataggio del token FCM web: $e');
      }
    }
  }

  /// Ottiene tutti i token dell'utente
  Future<List<String>> getUserTokens() async {
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

      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Errore nel recupero dei token web: $e');
      }
      return [];
    }
  }

  /// Invia una notifica web locale
  Future<void> sendWebNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (html.Notification.permission != 'granted') {
        if (kDebugMode) {
          print('Permessi notifiche web non concessi');
        }
        return;
      }

      // Crea la notifica web
      final notification = html.Notification(
        title,
        body: body,
        icon: '/icons/Icon-192.png',
        tag: 'invory_notification',
      );

      if (kDebugMode) {
        print('Notifica web inviata: $title - $body');
      }

      // Gestisci il click sulla notifica
      notification.onClick.listen((event) {
        if (kDebugMode) {
          print('Notifica web cliccata: $title');
        }
        // Qui puoi aggiungere la logica per aprire l'app o navigare
      });
    } catch (e) {
      if (kDebugMode) {
        print('Errore nell\'invio notifica web: $e');
      }
    }
  }

  /// Invia notifica per prodotto sotto scorta
  Future<void> sendLowStockNotification({
    required String productName,
    required int currentQuantity,
    required int threshold,
  }) async {
    final title = 'Prodotto sotto scorta';
    final body =
        'Il prodotto $productName è sotto la soglia (${currentQuantity}/${threshold})';

    final data = {
      'type': 'low_stock',
      'productName': productName,
      'currentQuantity': currentQuantity.toString(),
      'threshold': threshold.toString(),
    };

    await sendWebNotification(title: title, body: body, data: data);
  }

  /// Invia notifica per prodotto esaurito
  Future<void> sendOutOfStockNotification({required String productName}) async {
    final title = 'Prodotto esaurito';
    final body = 'Il prodotto $productName è completamente esaurito';

    final data = {
      'type': 'out_of_stock',
      'productName': productName,
      'currentQuantity': '0',
    };

    await sendWebNotification(title: title, body: body, data: data);
  }

  /// Rimuove un token non valido
  Future<void> removeToken(String token) async {
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
        print('Token web rimosso: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nella rimozione del token web: $e');
      }
    }
  }

  /// Pulisce i token obsoleti
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
              .where('platform', isEqualTo: 'web')
              .where('lastUsed', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
              .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      if (kDebugMode) {
        print('Puliti ${querySnapshot.docs.length} token web obsoleti');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nella pulizia dei token web: $e');
      }
    }
  }

  /// Verifica se le notifiche web sono supportate
  bool isSupported() {
    return html.Notification.supported;
  }

  /// Verifica se i permessi sono concessi
  bool hasPermission() {
    return html.Notification.permission == 'granted';
  }

  /// Richiede i permessi per le notifiche
  Future<bool> requestPermission() async {
    try {
      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    } catch (e) {
      if (kDebugMode) {
        print('Errore nella richiesta permessi web: $e');
      }
      return false;
    }
  }

  /// Verifica se l'app può essere installata
  bool canInstallPWA() {
    // Controlla se il prompt è disponibile
    final hasPrompt = html.window.localStorage['beforeinstallprompt'] == 'true';

    // Controlla se l'app è già installata
    final isStandalone =
        html.window.matchMedia('(display-mode: standalone)').matches;

    return hasPrompt && !isStandalone;
  }

  /// Mostra il prompt di installazione PWA
  Future<void> showInstallPrompt() async {
    try {
      // Trigger dell'evento beforeinstallprompt
      html.window.dispatchEvent(html.Event('beforeinstallprompt'));

      if (kDebugMode) {
        print('Prompt di installazione PWA mostrato');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nel mostrare il prompt PWA: $e');
      }
    }
  }

  /// Verifica se l'app è installata
  bool isAppInstalled() {
    return html.window.matchMedia('(display-mode: standalone)').matches;
  }
}
