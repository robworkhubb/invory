import '../../domain/repositories/supplier_repository.dart';
import '../../domain/entities/fornitore.dart';
import '../datasources/firestore_service.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final FirestoreService _firestoreService;

  SupplierRepositoryImpl(this._firestoreService);

  @override
  Stream<List<Fornitore>> fetchSuppliers() {
    return _firestoreService.fetchSuppliers();
  }

  @override
  Future<void> addSupplier(Fornitore supplier) {
    return _firestoreService.addSupplier(supplier);
  }

  @override
  Future<void> updateSupplier(Fornitore supplier) {
    return _firestoreService.updateSupplier(supplier);
  }

  @override
  Future<void> deleteSupplier(String id) {
    return _firestoreService.deleteSupplier(id);
  }
}
