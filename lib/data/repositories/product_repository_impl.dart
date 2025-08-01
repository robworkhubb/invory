import '../../domain/repositories/product_repository.dart';
import '../../domain/entities/product.dart';
import '../datasources/firestore_service.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirestoreService _firestoreService;

  ProductRepositoryImpl(this._firestoreService);

  @override
  Stream<List<Product>> fetchProducts() {
    return _firestoreService.fetchProducts();
  }

  @override
  Future<void> addProduct(Product product) {
    return _firestoreService.addProduct(product);
  }

  @override
  Future<void> updateProduct(Product product) {
    return _firestoreService.updateProduct(product);
  }

  @override
  Future<void> deleteProduct(String id) {
    return _firestoreService.deleteProduct(id);
  }
}
