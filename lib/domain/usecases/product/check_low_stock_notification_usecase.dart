import '../../entities/product.dart';
import '../../../core/services/notification_service.dart';
import 'package:flutter/foundation.dart';

class CheckLowStockNotificationUseCase {
  final INotificationService _notificationService;

  CheckLowStockNotificationUseCase(this._notificationService);

  /// Verifica se un prodotto è sotto scorta e invia notifica se necessario
  Future<void> execute(Product product) async {
    try {
      if (kDebugMode) {
        print('🔍 Verificando notifica scorta per: ${product.nome}');
        print('📊 Quantità: ${product.quantita}, Soglia: ${product.soglia}');
      }

      // Verifica se la quantità è sotto o uguale alla soglia
      if (product.quantita <= product.soglia) {
        if (kDebugMode) {
          print('🚨 PRODOTTO SOTTO SCORTA! Invio notifica...');
        }
        await _notificationService.showLowStockNotification(product);
        if (kDebugMode) {
          print('✅ Notifica scorta inviata per: ${product.nome}');
        }
      } else {
        if (kDebugMode) {
          print('✅ Prodotto ${product.nome} sopra la soglia, nessuna notifica');
        }
      }
    } catch (e) {
      // Log dell'errore ma non bloccare l'operazione principale
      print('❌ Errore nella verifica notifica scorta: $e');
    }
  }

  /// Verifica se un prodotto è esaurito (quantità = 0) e invia notifica
  Future<void> checkOutOfStock(Product product) async {
    try {
      if (kDebugMode) {
        print('🔍 Verificando esaurimento per: ${product.nome}');
        print('📊 Quantità: ${product.quantita}');
      }

      if (product.quantita == 0) {
        if (kDebugMode) {
          print('🚨 PRODOTTO ESAURITO! Invio notifica...');
        }
        await _notificationService.showOutOfStockNotification(product);
        if (kDebugMode) {
          print('✅ Notifica esaurimento inviata per: ${product.nome}');
        }
      } else {
        if (kDebugMode) {
          print('✅ Prodotto ${product.nome} non esaurito, nessuna notifica');
        }
      }
    } catch (e) {
      print('❌ Errore nella verifica notifica esaurimento: $e');
    }
  }
}
