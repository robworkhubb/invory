import '../../repositories/supplier_repository.dart';
import '../../entities/fornitore.dart';

class AddSupplierUseCase {
  final SupplierRepository _supplierRepository;

  AddSupplierUseCase(this._supplierRepository);

  Future<void> execute(Fornitore supplier) {
    return _supplierRepository.addSupplier(supplier);
  }
}
