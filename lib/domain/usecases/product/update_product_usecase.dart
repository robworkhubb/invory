import '../../repositories/product_repository.dart';
import '../../entities/product.dart';

class UpdateProductUseCase {
  final ProductRepository _productRepository;

  UpdateProductUseCase(this._productRepository);

  Future<void> execute(Product product) {
    return _productRepository.updateProduct(product);
  }
}
