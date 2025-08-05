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
import '../services/notifications_service.dart';
import '../services/fcm_notification_service.dart';
import '../services/fcm_web_service.dart';
import '../services/stock_notification_service.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/product_provider.dart';
import '../../presentation/providers/supplier_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Data sources
  sl.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  sl.registerLazySingleton<FirestoreService>(() => FirestoreService());

  // Services - Registrazione dei servizi di notifica
  sl.registerLazySingleton<NotificationsService>(() => NotificationsService());
  sl.registerLazySingleton<FCMNotificationService>(
    () => FCMNotificationService(),
  );
  sl.registerLazySingleton<FCMWebService>(() => FCMWebService());
  sl.registerLazySingleton<StockNotificationService>(
    () => StockNotificationService(),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => CheckStockNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => CheckLowStockNotificationUseCase(sl()));
  sl.registerLazySingleton(() => GetSuppliersUseCase(sl()));
  sl.registerLazySingleton(() => AddSupplierUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSupplierUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSupplierUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<SupplierRepository>(
    () => SupplierRepositoryImpl(sl()),
  );

  // Providers - Aggiornati per usare i nuovi servizi
  sl.registerFactory(() => AuthProvider(sl()));
  sl.registerFactory(() => ProductProvider(sl(), sl(), sl()));
  sl.registerFactory(() => SupplierProvider(sl()));
}
