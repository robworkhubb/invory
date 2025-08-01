import '../../repositories/product_repository.dart';
import '../../entities/product.dart';

class GetProductsUseCase {
  final ProductRepository _productRepository;

  GetProductsUseCase(this._productRepository);

  Stream<List<Product>> execute() {
    return _productRepository.fetchProducts();
  }
}
