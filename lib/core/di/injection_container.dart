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
import '../../domain/usecases/supplier/get_suppliers_usecase.dart';
import '../../domain/usecases/supplier/add_supplier_usecase.dart';
import '../../domain/usecases/supplier/update_supplier_usecase.dart';
import '../../domain/usecases/supplier/delete_supplier_usecase.dart';
import '../services/notification_service.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/product_provider.dart';
import '../../presentation/providers/supplier_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Data sources
  sl.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  sl.registerLazySingleton<FirestoreService>(() => FirestoreService());

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<SupplierRepository>(
    () => SupplierRepositoryImpl(sl()),
  );

  // Services
  sl.registerLazySingleton<INotificationService>(() => NotificationService());

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => AddProductUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProductUseCase(sl()));
  sl.registerLazySingleton(() => DeleteProductUseCase(sl()));
  sl.registerLazySingleton(() => CheckStockNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetSuppliersUseCase(sl()));
  sl.registerLazySingleton(() => AddSupplierUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSupplierUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSupplierUseCase(sl()));

  // Providers
  sl.registerFactory(() => AuthProvider(sl()));
  sl.registerFactory(() => ProductProvider(sl()));
  sl.registerFactory(() => SupplierProvider(sl()));
}
