import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:invory/presentation/providers/supplier_provider.dart';
import 'package:invory/presentation/providers/product_provider.dart';
import 'package:invory/presentation/providers/auth_provider.dart';
import 'package:invory/presentation/screens/splash_screen.dart';
import 'package:invory/firebase_options.dart';
import 'package:invory/theme.dart';
import 'package:invory/core/di/injection_container.dart' as di;
import 'package:invory/core/services/notification_service.dart';
import 'package:invory/core/services/fcm_notification_service.dart';
import 'package:invory/presentation/widgets/notification_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parallel initialization for better startup time
  await Future.wait([
    initializeDateFormatting('it_IT', null),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);

  // Initialize dependency injection
  await di.init();

  // Initialize notification services
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize FCM notification service
  final fcmNotificationService = FCMNotificationService();
  await fcmNotificationService.initialize();

  runApp(
    NotificationHandler(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => di.sl<ProductProvider>()),
          ChangeNotifierProvider(create: (_) => di.sl<SupplierProvider>()),
          ChangeNotifierProvider(create: (_) => di.sl<AuthProvider>()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
          // Performance optimizations
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
        ),
      ),
    ),
  );
}
