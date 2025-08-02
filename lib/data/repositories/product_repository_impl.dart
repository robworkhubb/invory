import '../../domain/repositories/product_repository.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/product/check_low_stock_notification_usecase.dart';
import '../datasources/firestore_service.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirestoreService _firestoreService;
  final CheckLowStockNotificationUseCase _checkLowStockNotificationUseCase;

  ProductRepositoryImpl(
    this._firestoreService,
    this._checkLowStockNotificationUseCase,
  );

  @override
  Stream<List<Product>> fetchProducts() {
    return _firestoreService.fetchProducts();
  }

  @override
  Future<void> addProduct(Product product) async {
    await _firestoreService.addProduct(product);
    // Verifica se il prodotto appena aggiunto è sotto scorta
    await _checkLowStockNotificationUseCase.execute(product);
  }

  @override
  Future<void> updateProduct(Product product) async {
    await _firestoreService.updateProduct(product);
    // Verifica se il prodotto aggiornato è sotto scorta
    await _checkLowStockNotificationUseCase.execute(product);
    // Verifica se il prodotto è esaurito
    await _checkLowStockNotificationUseCase.checkOutOfStock(product);
  }

  @override
  Future<void> deleteProduct(String id) {
    return _firestoreService.deleteProduct(id);
  }
}
