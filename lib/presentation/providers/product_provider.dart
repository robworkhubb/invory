import 'package:flutter/foundation.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/entities/product.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/stock_notification_service.dart';
import 'dart:async'; // Import per StreamSubscription

class ProductProvider with ChangeNotifier {
  final ProductRepository _productRepository;
  final INotificationService _notificationService;
  final StockNotificationService _stockNotificationService;

  List<Product> _prodotti = [];
  bool _loading = true;
  String _searchTerm = '';
  String? _filterCategory;
  StreamSubscription<List<Product>>? _productsSubscription;

  // Cache for better performance
  bool _isInitialized = false;

  // Set per tracciare i prodotti che hanno già ricevuto notifiche
  DateTime? _lastNotificationCheck;

  // Flag per evitare notifiche duplicate durante l'inizializzazione
  bool _isNotificationCheckInProgress = false;

  ProductProvider(
    this._productRepository,
    this._notificationService,
    this._stockNotificationService,
  ) {
    // Lazy loading - only load when needed
    _initializeProvider();
  }

  void _initializeProvider() {
    if (!_isInitialized) {
      _loadProducts();
      _isInitialized = true;
    }
  }

  Future<void> checkAndShowNotifications() async {
    try {
      // Evita controlli simultanei
      if (_isNotificationCheckInProgress) {
        print('⚠️ Controllo notifiche già in corso, saltato');
        return;
      }

      final now = DateTime.now();

      // Evita controlli troppo frequenti (almeno 30 secondi tra un controllo e l'altro)
      if (_lastNotificationCheck != null &&
          now.difference(_lastNotificationCheck!).inSeconds < 30) {
        print('⚠️ Controllo notifiche troppo frequente, saltato');
        return;
      }

      _isNotificationCheckInProgress = true;
      _lastNotificationCheck = now;

      print(
        '🔍 Iniziando controllo notifiche per ${_prodotti.length} prodotti',
      );

      // Usa il nuovo servizio per controllare tutti i prodotti
      await _stockNotificationService.checkAllProducts();

      print('✅ Controllo notifiche completato');
    } catch (e) {
      print('❌ Errore durante il controllo delle notifiche: $e');
    } finally {
      _isNotificationCheckInProgress = false;
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

  void _loadProducts() {
    try {
      print('🔄 Iniziando caricamento prodotti...');
      _productsSubscription = _productRepository.fetchProducts().listen(
        (prodotti) {
          print('✅ Prodotti caricati: ${prodotti.length} elementi');
          _prodotti = prodotti;
          _loading = false;
          notifyListeners();

          // Controlla le notifiche dopo aver caricato i prodotti
          try {
            checkAndShowNotifications();
          } catch (e) {
            print('⚠️ Errore nel controllo notifiche: $e');
          }
        },
        onError: (error) {
          print('❌ Errore nel caricamento prodotti: $error');
          _prodotti = [];
          _loading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('❌ Errore nell\'inizializzazione del stream prodotti: $e');
      _prodotti = [];
      _loading = false;
      notifyListeners();
    }
  }

  void reloadProducts() {
    _productsSubscription?.cancel();
    _productsSubscription = null;
    _prodotti = [];
    _loading = true;
    notifyListeners();
    _loadProducts();
  }

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

      // Controlla se il prodotto necessita di notifica push
      await _checkProductForNotifications(product);
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

      // Controlla se il prodotto necessita di notifica push
      await _checkProductForNotifications(updatedProduct);
    } catch (e) {
      print('Errore nell\'aggiornamento della quantità: $e');
      rethrow;
    }
  }

  /// Controlla se un prodotto necessita di notifiche
  Future<void> _checkProductForNotifications(Product product) async {
    try {
      // Controlla se il prodotto è esaurito
      if (product.quantita <= 0) {
        await _notificationService.sendOutOfStockNotification(
          productName: product.nome,
        );
      }
      // Controlla se il prodotto è sotto scorta
      else if (product.quantita <= product.soglia) {
        await _notificationService.sendLowStockNotification(
          productName: product.nome,
          currentQuantity: product.quantita,
          threshold: product.soglia,
        );
      }
    } catch (e) {
      print('Errore nel controllo notifiche per prodotto ${product.nome}: $e');
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
