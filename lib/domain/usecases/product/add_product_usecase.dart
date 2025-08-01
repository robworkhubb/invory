import '../../repositories/product_repository.dart';
import '../../entities/product.dart';

class AddProductUseCase {
  final ProductRepository _productRepository;

  AddProductUseCase(this._productRepository);

  Future<void> execute(Product product) {
    return _productRepository.addProduct(product);
  }
}
