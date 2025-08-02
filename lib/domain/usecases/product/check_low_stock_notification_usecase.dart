import '../../entities/product.dart';
import '../../../core/services/fcm_notification_service.dart';

class CheckLowStockNotificationUseCase {
  final FCMNotificationService _notificationService;

  CheckLowStockNotificationUseCase(this._notificationService);

  /// Verifica se un prodotto è sotto scorta e invia notifica se necessario
  Future<void> execute(Product product) async {
    try {
      // Verifica se la quantità è sotto o uguale alla soglia
      if (product.quantita <= product.soglia) {
        await _notificationService.sendLowStockNotification(
          productName: product.nome,
          currentQuantity: product.quantita,
          threshold: product.soglia,
        );
      }
    } catch (e) {
      // Log dell'errore ma non bloccare l'operazione principale
      print('Errore nella verifica notifica scorta: $e');
    }
  }

  /// Verifica se un prodotto è esaurito (quantità = 0) e invia notifica
  Future<void> checkOutOfStock(Product product) async {
    try {
      if (product.quantita == 0) {
        await _notificationService.sendNotificationToUser(
          title: 'Prodotto esaurito',
          body: 'Il prodotto ${product.nome} è completamente esaurito',
          data: {
            'type': 'out_of_stock',
            'productName': product.nome,
            'currentQuantity': '0',
          },
        );
      }
    } catch (e) {
      print('Errore nella verifica notifica esaurimento: $e');
    }
  }
} 