import '../entities/fornitore.dart';

abstract class SupplierRepository {
  Stream<List<Fornitore>> fetchSuppliers();
  Future<void> addSupplier(Fornitore supplier);
  Future<void> updateSupplier(Fornitore supplier);
  Future<void> deleteSupplier(String id);
}
