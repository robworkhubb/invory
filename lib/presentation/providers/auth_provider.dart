import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';
import 'package:provider/provider.dart';
import 'product_provider.dart';
import 'supplier_provider.dart';
import '../../core/services/notifications_service.dart';
import '../../core/services/fcm_web_service.dart';
import '../../core/services/fcm_notification_service.dart';
import 'package:flutter/foundation.dart';
import '../../core/di/injection_container.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final NotificationsService _notificationsService;
  final FCMWebService _fcmWebService;
  final FCMNotificationService _fcmNotificationService;
  User? _currentUser;
  bool _isLoading = false;

  AuthProvider(this._authRepository)
    : _notificationsService = sl<NotificationsService>(),
      _fcmWebService = sl<FCMWebService>(),
      _fcmNotificationService = sl<FCMNotificationService>() {
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

      if (_currentUser != null) {
        // Salva i token FCM pendenti dopo l'autenticazione
        await _saveFCMTokensAfterLogin();
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

  /// Salva i token FCM dopo il login
  Future<void> _saveFCMTokensAfterLogin() async {
    try {
      if (kDebugMode) {
        print(
          '🔐 Salvataggio token FCM dopo login per: ${_currentUser?.email}',
        );
      }

      // Salva i token pendenti dal NotificationsService
      await _notificationsService.savePendingTokens();

      // Per il web, salva anche tramite FCMWebService
      if (kIsWeb) {
        await _fcmWebService.initialize();
      } else {
        // Per mobile, reinizializza FCM
        await _fcmNotificationService.initialize();
      }

      if (kDebugMode) {
        print('✅ Token FCM salvati con successo dopo login');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Errore nel salvataggio dei token FCM dopo login: $e');
      }
    }
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
