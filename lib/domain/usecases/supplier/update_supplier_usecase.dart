import '../../repositories/supplier_repository.dart';
import '../../entities/fornitore.dart';

class UpdateSupplierUseCase {
  final SupplierRepository _supplierRepository;

  UpdateSupplierUseCase(this._supplierRepository);

  Future<void> execute(Fornitore supplier) {
    return _supplierRepository.updateSupplier(supplier);
  }
}
