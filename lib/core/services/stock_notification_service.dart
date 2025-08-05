import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notifications_service.dart';

class StockNotificationService {
  static final StockNotificationService _instance =
      StockNotificationService._internal();
  factory StockNotificationService() => _instance;
  StockNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationsService _notificationsService = NotificationsService();

  DateTime? _lastCheckTime;
  static const Duration _checkInterval = Duration(
    minutes: 5,
  ); // Controlla ogni 5 minuti

  /// Inizializza il servizio
  Future<void> initialize() async {
    if (kDebugMode) {
      print('🔧 Inizializzazione servizio notifiche scorte...');
    }

    // Configura il listener per i prodotti in tempo reale
    _setupProductListeners();

    if (kDebugMode) {
      print('✅ Servizio notifiche scorte inizializzato');
    }
  }

  /// Configura i listener per i prodotti
  void _setupProductListeners() {
    final user = _auth.currentUser;
    if (user == null) {
      if (kDebugMode) {
        print(
          '❌ Utente non autenticato, impossibile configurare listener notifiche',
        );
      }
      return;
    }

    // Listener per prodotti in tempo reale
    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('products')
        .snapshots()
        .listen((snapshot) {
          _checkLowStockProducts(snapshot.docs);
        });

    if (kDebugMode) {
      print('👂 Listener notifiche in tempo reale configurato');
    }
  }

  /// Controlla i prodotti sotto scorta
  Future<void> _checkLowStockProducts(
    List<QueryDocumentSnapshot> products,
  ) async {
    // Evita controlli troppo frequenti
    final now = DateTime.now();
    if (_lastCheckTime != null &&
        now.difference(_lastCheckTime!) < _checkInterval) {
      if (kDebugMode) {
        print('⚠️ Controllo notifiche troppo frequente, saltato');
      }
      return;
    }
    _lastCheckTime = now;

    if (kDebugMode) {
      print('🔍 Iniziando controllo notifiche per ${products.length} prodotti');
    }

    int outOfStockCount = 0;
    int lowStockCount = 0;

    for (final productDoc in products) {
      try {
        final productData = productDoc.data() as Map<String, dynamic>;
        final productName =
            productData['name'] as String? ?? 'Prodotto sconosciuto';
        final currentQuantity = productData['quantity'] as int? ?? 0;
        final threshold = productData['threshold'] as int? ?? 10;

        // Controlla se il prodotto è esaurito
        if (currentQuantity <= 0) {
          await _sendOutOfStockNotification(productName);
          outOfStockCount++;
        }
        // Controlla se il prodotto è sotto scorta
        else if (currentQuantity <= threshold) {
          await _sendLowStockNotification(
            productName,
            currentQuantity,
            threshold,
          );
          lowStockCount++;
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Errore nel controllo del prodotto ${productDoc.id}: $e');
        }
      }
    }

    if (kDebugMode) {
      print(
        'Controllo scorte completato: $outOfStockCount terminati, $lowStockCount sotto scorta',
      );
      print('✅ Controllo notifiche completato');
    }
  }

  /// Invia notifica per prodotto sotto scorta
  Future<void> _sendLowStockNotification(
    String productName,
    int currentQuantity,
    int threshold,
  ) async {
    try {
      if (kDebugMode) {
        print('🔔 Notifica prodotto sotto scorta inviata per: $productName');
      }

      await _notificationsService.sendLowStockNotification(
        productName: productName,
        currentQuantity: currentQuantity,
        threshold: threshold,
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ Errore nell\'invio notifica scorta bassa per $productName: $e',
        );
      }
    }
  }

  /// Invia notifica per prodotto esaurito
  Future<void> _sendOutOfStockNotification(String productName) async {
    try {
      if (kDebugMode) {
        print('🔔 Notifica prodotto esaurito inviata per: $productName');
      }

      await _notificationsService.sendOutOfStockNotification(
        productName: productName,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'invio notifica esaurimento per $productName: $e');
      }
    }
  }

  /// Controlla manualmente tutti i prodotti
  Future<void> checkAllProducts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('❌ Utente non autenticato, impossibile controllare prodotti');
        }
        return;
      }

      final productsSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('products')
              .get();

      await _checkLowStockProducts(productsSnapshot.docs);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nel controllo manuale dei prodotti: $e');
      }
    }
  }

  /// Invia notifica personalizzata
  Future<void> sendCustomNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _notificationsService.sendNotification(
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'invio notifica personalizzata: $e');
      }
    }
  }

  /// Ottieni statistiche delle notifiche
  Future<Map<String, int>> getNotificationStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final productsSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('products')
              .get();

      int outOfStockCount = 0;
      int lowStockCount = 0;

      for (final productDoc in productsSnapshot.docs) {
        final productData = productDoc.data() as Map<String, dynamic>;
        final currentQuantity = productData['quantity'] as int? ?? 0;
        final threshold = productData['threshold'] as int? ?? 10;

        if (currentQuantity <= 0) {
          outOfStockCount++;
        } else if (currentQuantity <= threshold) {
          lowStockCount++;
        }
      }

      return {
        'outOfStock': outOfStockCount,
        'lowStock': lowStockCount,
        'total': productsSnapshot.docs.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nel calcolo statistiche notifiche: $e');
      }
      return {};
    }
  }

  /// Pulisce le notifiche vecchie
  Future<void> cleanupOldNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final notificationsSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
              .get();

      for (final notification in notificationsSnapshot.docs) {
        await notification.reference.delete();
      }

      if (kDebugMode) {
        print(
          '🧹 Pulisce ${notificationsSnapshot.docs.length} notifiche vecchie',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nella pulizia delle notifiche: $e');
      }
    }
  }
}
