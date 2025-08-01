import '../../repositories/supplier_repository.dart';

class DeleteSupplierUseCase {
  final SupplierRepository _supplierRepository;

  DeleteSupplierUseCase(this._supplierRepository);

  Future<void> execute(String id) {
    return _supplierRepository.deleteSupplier(id);
  }
}
