import '../../repositories/supplier_repository.dart';
import '../../entities/fornitore.dart';

class GetSuppliersUseCase {
  final SupplierRepository _supplierRepository;

  GetSuppliersUseCase(this._supplierRepository);

  Stream<List<Fornitore>> execute() {
    return _supplierRepository.fetchSuppliers();
  }
}
