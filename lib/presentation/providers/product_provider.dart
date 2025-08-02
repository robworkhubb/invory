import 'package:flutter/foundation.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/product/check_stock_notifications_usecase.dart';
import '../../../core/services/notification_service.dart';
import 'dart:async'; // Import per StreamSubscription

class ProductProvider with ChangeNotifier {
  final ProductRepository _productRepository;
  final INotificationService _notificationService;
  late final CheckStockNotificationsUseCase _checkStockNotificationsUseCase;

  List<Product> _prodotti = [];
  bool _loading = true;
  String _searchTerm = '';
  String? _filterCategory;
  StreamSubscription<List<Product>>? _productsSubscription;

  // Cache for better performance
  bool _isInitialized = false;

  // Set per tracciare i prodotti che hanno già ricevuto notifiche
  final Set<String> _notifiedProducts = <String>{};
  DateTime? _lastNotificationCheck;

  ProductProvider(this._productRepository, this._notificationService) {
    _checkStockNotificationsUseCase = CheckStockNotificationsUseCase(
      _productRepository,
    );
    // Lazy loading - only load when needed
    _initializeProvider();
    _initializeNotifications();
  }

  void _initializeProvider() {
    if (!_isInitialized) {
      _loadProducts();
      _isInitialized = true;
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      await _notificationService.requestPermissions();
    } catch (e) {
      print('Errore nell\'inizializzazione notifiche: $e');
    }
  }

  Future<void> checkAndShowNotifications() async {
    try {
      final now = DateTime.now();

      // Evita controlli troppo frequenti (almeno 30 secondi tra un controllo e l'altro)
      if (_lastNotificationCheck != null &&
          now.difference(_lastNotificationCheck!).inSeconds < 30) {
        return;
      }

      _lastNotificationCheck = now;
      final lowStockProducts = await _checkStockNotificationsUseCase();
      final Set<String> currentLowStockIds = <String>{};

      for (final product in lowStockProducts) {
        currentLowStockIds.add(product.id);

        // Invia notifica solo se non è già stata inviata per questo prodotto
        if (!_notifiedProducts.contains(product.id)) {
          if (product.quantita == 0) {
            await _notificationService.showOutOfStockNotification(product);
          } else if (product.quantita <= product.soglia) {
            await _notificationService.showLowStockNotification(product);
          }
          _notifiedProducts.add(product.id);
        }
      }

      // Rimuovi dai prodotti notificati quelli che non sono più a scorte basse
      _notifiedProducts.removeWhere((id) => !currentLowStockIds.contains(id));
    } catch (e) {
      print('Errore durante il controllo delle notifiche: $e');
    }
  }

  List<Product> get prodotti {
    List<Product> filteredProducts = _prodotti;

    if (_filterCategory != null && _filterCategory!.isNotEmpty) {
      filteredProducts =
          filteredProducts
              .where((p) => p.categoria == _filterCategory)
              .toList();
    }

    if (_searchTerm.isNotEmpty) {
      filteredProducts =
          filteredProducts
              .where(
                (p) =>
                    p.nome.toLowerCase().contains(_searchTerm.toLowerCase()) ||
                    p.categoria.toLowerCase().contains(
                      _searchTerm.toLowerCase(),
                    ),
              )
              .toList();
    }
    return filteredProducts;
  }

  bool get loading => _loading;
  String? get activeCategory => _filterCategory;
  List<String> get uniqueCategories =>
      _prodotti.map((p) => p.categoria).toSet().toList();

  // Metodo privato per caricare i prodotti automaticamente
  void _loadProducts() {
    try {
      _productsSubscription = _productRepository.fetchProducts().listen(
        (prodotti) {
          _prodotti = prodotti;
          _loading = false;
          notifyListeners();

          // Controlla le notifiche dopo aver caricato i prodotti
          checkAndShowNotifications();
        },
        onError: (error) {
          print('Errore nel caricamento prodotti: $error');
          _prodotti = [];
          _loading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('Errore nell\'inizializzazione del stream prodotti: $e');
      _prodotti = [];
      _loading = false;
      notifyListeners();
    }
  }

  // Metodo pubblico per ricaricare i prodotti (utile per cambio account)
  void reloadProducts() {
    _productsSubscription?.cancel();
    _productsSubscription = null;
    _prodotti = [];
    _loading = true;
    notifyListeners();
    _loadProducts();
  }

  // Metodo per pulire i dati (utile per logout)
  void clearProducts() {
    _productsSubscription?.cancel();
    _productsSubscription = null;
    _prodotti = [];
    _loading = false;
    _searchTerm = '';
    _filterCategory = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  Future<void> addProduct(Product product) async {
    try {
      await _productRepository.addProduct(product);
      // Controlla le notifiche dopo aver aggiunto il prodotto
      await checkAndShowNotifications();
    } catch (e) {
      print('Errore nell\'aggiunta del prodotto nel provider: $e');
      rethrow; // Rilancia l'errore per gestirlo nell'UI
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _productRepository.updateProduct(product);

      // Rimuovi il prodotto dalla lista dei notificati per permettere una nuova notifica
      // se le condizioni cambiano
      _notifiedProducts.remove(product.id);

      // Controlla le notifiche dopo aver aggiornato il prodotto
      await checkAndShowNotifications();
    } catch (e) {
      print('Errore nell\'aggiornamento del prodotto nel provider: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _productRepository.deleteProduct(productId);
      // Controlla le notifiche dopo aver eliminato il prodotto
      await checkAndShowNotifications();
    } catch (e) {
      print('Errore nell\'eliminazione del prodotto nel provider: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(Product product, int newQuantity) async {
    // Impedisce che la quantità scenda sotto zero
    final clampedQuantity = newQuantity.clamp(0, double.infinity).toInt();

    int consumatiDelta = product.quantita - clampedQuantity;
    if (consumatiDelta < 0) consumatiDelta = 0;

    final updatedProduct = Product(
      id: product.id,
      nome: product.nome,
      categoria: product.categoria,
      quantita: clampedQuantity,
      soglia: product.soglia,
      prezzoUnitario: product.prezzoUnitario,
      consumati: product.consumati + consumatiDelta,
      ultimaModifica: DateTime.now(),
    );

    try {
      await _productRepository.updateProduct(updatedProduct);

      // Rimuovi il prodotto dalla lista dei notificati per permettere una nuova notifica
      _notifiedProducts.remove(product.id);

      // Forza il controllo delle notifiche quando si scala un prodotto
      await _forceCheckNotifications();
    } catch (e) {
      print('Errore nell\'aggiornamento della quantità: $e');
      rethrow;
    }
  }

  // Metodo per forzare il controllo delle notifiche (bypassa il controllo temporale)
  Future<void> _forceCheckNotifications() async {
    try {
      final lowStockProducts = await _checkStockNotificationsUseCase();
      final Set<String> currentLowStockIds = <String>{};

      for (final product in lowStockProducts) {
        currentLowStockIds.add(product.id);

        // Invia notifica solo se non è già stata inviata per questo prodotto
        if (!_notifiedProducts.contains(product.id)) {
          if (product.quantita == 0) {
            await _notificationService.showOutOfStockNotification(product);
          } else if (product.quantita <= product.soglia) {
            await _notificationService.showLowStockNotification(product);
          }
          _notifiedProducts.add(product.id);
        }
      }

      // Rimuovi dai prodotti notificati quelli che non sono più a scorte basse
      _notifiedProducts.removeWhere((id) => !currentLowStockIds.contains(id));
    } catch (e) {
      print('Errore durante il controllo forzato delle notifiche: $e');
    }
  }

  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void setFilterCategory(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchTerm = '';
    _filterCategory = null;
    notifyListeners();
  }

  // Metodi di analisi per la dashboard
  List<Product> topConsumati({int count = 5}) {
    final sorted = List<Product>.from(_prodotti)
      ..sort((a, b) => b.consumati.compareTo(a.consumati));
    return sorted.take(count).toList();
  }

  Map<String, int> distribuzionePerCategoria() {
    final Map<String, int> dist = {};
    for (var p in _prodotti) {
      dist[p.categoria] = (dist[p.categoria] ?? 0) + p.consumati;
    }
    return dist;
  }

  Map<String, double> spesaMensile() {
    final Map<String, double> monthly = {};
    for (var p in _prodotti) {
      if (p.ultimaModifica != null) {
        final key =
            "${p.ultimaModifica!.year}-${p.ultimaModifica!.month.toString().padLeft(2, '0')}";
        monthly[key] = (monthly[key] ?? 0) + (p.consumati * p.prezzoUnitario);
      }
    }
    return monthly;
  }
}
