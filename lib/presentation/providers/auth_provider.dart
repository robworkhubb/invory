import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import 'package:provider/provider.dart';
import 'product_provider.dart';
import 'supplier_provider.dart';
import '../../core/services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final INotificationService _notificationService;
  User? _currentUser;
  bool _isLoading = false;

  AuthProvider(this._authRepository, this._notificationService) {
    _currentUser = _authRepository.getCurrentUser();
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authRepository.login(email, password);

      // Salva il token FCM pendente dopo l'autenticazione
      try {
        await _notificationService.savePendingToken();
      } catch (e) {
        print('Errore nel salvataggio del token FCM: $e');
      }

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.logout();
      _currentUser = null;

      // Pulisci i dati dei provider
      try {
        final productProvider = Provider.of<ProductProvider>(
          context,
          listen: false,
        );
        productProvider.clearProducts();

        final supplierProvider = Provider.of<SupplierProvider>(
          context,
          listen: false,
        );
        supplierProvider.clearSuppliers();
      } catch (e) {
        print('Errore nella pulizia dei provider: $e');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Metodo per ricaricare i dati quando l'utente fa login
  void reloadUserData(BuildContext context) {
    try {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      productProvider.reloadProducts();

      final supplierProvider = Provider.of<SupplierProvider>(
        context,
        listen: false,
      );
      supplierProvider.reloadSuppliers();
    } catch (e) {
      print('Errore nel ricaricamento dei dati: $e');
    }
  }

  void updateCurrentUser() {
    _currentUser = _authRepository.getCurrentUser();
    notifyListeners();
  }
}
