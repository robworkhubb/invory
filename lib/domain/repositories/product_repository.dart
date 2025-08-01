import '../entities/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> fetchProducts();
  Future<void> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);
}
