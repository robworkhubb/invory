import 'package:flutter/material.dart';
import '../../domain/entities/fornitore.dart';
import '../../domain/repositories/supplier_repository.dart';

class SupplierProvider with ChangeNotifier {
  final SupplierRepository _supplierRepository;
  List<Fornitore> _suppliers = [];
  bool _loading = true;

  SupplierProvider(this._supplierRepository) {
    _loadSuppliers();
  }

  List<Fornitore> get suppliers => _suppliers;
  bool get loading => _loading;

  void _loadSuppliers() {
    try {
      _supplierRepository.fetchSuppliers().listen(
        (suppliers) {
          _suppliers = suppliers;
          _loading = false;
          notifyListeners();
        },
        onError: (error) {
          print('Errore nel caricamento fornitori: $error');
          _suppliers = [];
          _loading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('Errore nell\'inizializzazione del stream fornitori: $e');
      _suppliers = [];
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addSupplier(String nome, String numero) async {
    try {
      final nuovoSupplier = Fornitore(id: '', nome: nome, numero: numero);
      await _supplierRepository.addSupplier(nuovoSupplier);
    } catch (e) {
      print('Errore nell\'aggiunta del fornitore nel provider: $e');
      rethrow;
    }
  }

  Future<void> updateSupplier(Fornitore supplier) async {
    try {
      await _supplierRepository.updateSupplier(supplier);
    } catch (e) {
      print('Errore nell\'aggiornamento del fornitore nel provider: $e');
      rethrow;
    }
  }

  Future<void> deleteSupplier(String supplierId) async {
    try {
      await _supplierRepository.deleteSupplier(supplierId);
    } catch (e) {
      print('Errore nell\'eliminazione del fornitore nel provider: $e');
      rethrow;
    }
  }

  // Metodo per ricaricare i fornitori (utile per cambio account)
  void reloadSuppliers() {
    _suppliers = [];
    _loading = true;
    notifyListeners();
    _loadSuppliers();
  }

  // Metodo per pulire i dati (utile per logout)
  void clearSuppliers() {
    _suppliers = [];
    _loading = false;
    notifyListeners();
  }
}
