import 'package:get_it/get_it.dart';
import '../../data/datasources/firebaseauth_service.dart';
import '../../data/datasources/firestore_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/supplier_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../../domain/usecases/auth/login_usecase.dart';
import '../../domain/usecases/product/get_products_usecase.dart';
import '../../domain/usecases/product/add_product_usecase.dart';
import '../../domain/usecases/product/update_product_usecase.dart';
import '../../domain/usecases/product/delete_product_usecase.dart';
import '../../domain/usecases/product/check_stock_notifications_usecase.dart';
import '../../domain/usecases/product/check_low_stock_notification_usecase.dart';
import '../../domain/usecases/supplier/get_suppliers_usecase.dart';
import '../../domain/usecases/supplier/add_supplier_usecase.dart';
import '../../domain/usecases/supplier/update_supplier_usecase.dart';
import '../../domain/usecases/supplier/delete_supplier_usecase.dart';
import '../services/notification_service.dart';
import '../services/fcm_notification_service.dart';
import '../services/fcm_web_service.dart';
import '../services/stock_notification_service.dart';
import '../services/fcm_auth_service.dart';
import '../services/service_worker_manager.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/product_provider.dart';
import '../../presentation/providers/supplier_provider.dart';

final sl = GetIt.instance;

/// Inizializza tutte le dipendenze dell'applicazione
Future<void> init() async {
  await _initDataSources();
  await _initServices();
  await _initUseCases();
  await _initRepositories();
  await _initProviders();
}

/// Inizializza i data sources
Future<void> _initDataSources() async {
  sl.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  sl.registerLazySingleton<FirestoreService>(() => FirestoreService());
}

/// Inizializza i servizi
Future<void> _initServices() async {
  // Servizi di notifica
  sl.registerLazySingleton<FCMNotificationService>(
    () => FCMNotificationService(),
  );
  sl.registerLazySingleton<FCMWebService>(() => FCMWebService());
  sl.registerLazySingleton<StockNotificationService>(
    () => StockNotificationService(),
  );

  // Servizio di autenticazione FCM
  sl.registerLazySingleton<FCMAuthService>(() => FCMAuthService());

  // Service Worker Manager
  sl.registerLazySingleton<ServiceWorkerManager>(() => ServiceWorkerManager());

  // Registra il servizio notifiche
  sl.registerLazySingleton<INotificationService>(() => NotificationService());
  sl.registerLazySingleton<NotificationService>(() => NotificationService());
}

/// Inizializza i use cases
Future<void> _initUseCases() async {
  // Auth use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));

  // Product use cases
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => CheckStockNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => CheckLowStockNotificationUseCase(sl()));

  // Supplier use cases
  sl.registerLazySingleton(() => GetSuppliersUseCase(sl()));
  sl.registerLazySingleton(() => AddSupplierUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSupplierUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSupplierUseCase(sl()));
}

/// Inizializza i repositories
Future<void> _initRepositories() async {
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<SupplierRepository>(
    () => SupplierRepositoryImpl(sl()),
  );
}

/// Inizializza i providers
Future<void> _initProviders() async {
  sl.registerFactory(() => AuthProvider(sl()));
  sl.registerFactory(
    () => ProductProvider(
      sl<ProductRepository>(),
      sl<INotificationService>(),
      sl<StockNotificationService>(),
    ),
  );
  sl.registerFactory(() => SupplierProvider(sl()));
}
