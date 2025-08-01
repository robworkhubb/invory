import '../../entities/product.dart';
import '../../repositories/product_repository.dart';

class CheckStockNotificationsUseCase {
  final ProductRepository repository;

  CheckStockNotificationsUseCase(this.repository);

  Future<List<Product>> call() async {
    try {
      final productsStream = repository.fetchProducts();
      final products = await productsStream.first;
      return products
          .where(
            (product) =>
                product.quantita <= product.soglia || product.quantita == 0,
          )
          .toList();
    } catch (e) {
      print('Errore nel controllo scorte: $e');
      return [];
    }
  }
}
