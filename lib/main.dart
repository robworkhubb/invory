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
import 'package:invory/core/services/notifications_service.dart';
import 'package:invory/core/services/fcm_notification_service.dart';
import 'package:invory/core/services/fcm_web_service.dart';
import 'package:invory/core/services/stock_notification_service.dart';
import 'package:invory/presentation/widgets/notification_handler.dart';
import 'package:invory/core/config/app_config.dart';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Recupera le variabili d'ambiente da --dart-define
  final vapidKey = const String.fromEnvironment('VAPID_KEY', defaultValue: '');

  // Variabili FCM V1
  final fcmProjectId = const String.fromEnvironment(
    'FCM_PROJECT_ID',
    defaultValue: '',
  );
  final fcmClientEmail = const String.fromEnvironment(
    'FCM_CLIENT_EMAIL',
    defaultValue: '',
  );
  final fcmPrivateKey = const String.fromEnvironment(
    'FCM_PRIVATE_KEY',
    defaultValue: '',
  );

  // Passa le variabili d'ambiente al JavaScript per il web
  js.context['flutterConfiguration'] = {
    'FIREBASE_API_KEY': AppConfig.firebaseApiKey,
    'FIREBASE_AUTH_DOMAIN': AppConfig.firebaseAuthDomain,
    'FIREBASE_PROJECT_ID': AppConfig.firebaseProjectId,
    'FIREBASE_STORAGE_BUCKET': AppConfig.firebaseStorageBucket,
    'FIREBASE_MESSAGING_SENDER_ID': AppConfig.firebaseMessagingSenderId,
    'FIREBASE_APP_ID': AppConfig.firebaseAppId,
    'FIREBASE_MEASUREMENT_ID': AppConfig.firebaseMeasurementId,
    'VAPID_KEY': vapidKey,
    'FCM_PROJECT_ID': fcmProjectId,
    'FCM_CLIENT_EMAIL': fcmClientEmail,
    'FCM_PRIVATE_KEY': fcmPrivateKey,
  };

  if (AppConfig.enableLogging) {
    print('${AppConfig.logPrefix} 🔧 Configurazione passata al JavaScript:');
    print('${AppConfig.logPrefix}    - Firebase API Key: ✅');
    print('${AppConfig.logPrefix}    - Firebase Auth Domain: ✅');
    print('${AppConfig.logPrefix}    - Firebase Project ID: ✅');
    print(
      '${AppConfig.logPrefix}    - VAPID_KEY: ${vapidKey.isNotEmpty ? "✅" : "❌"}',
    );
    print(
      '${AppConfig.logPrefix}    - FCM_PROJECT_ID: ${fcmProjectId.isNotEmpty ? "✅" : "❌"}',
    );
    print(
      '${AppConfig.logPrefix}    - FCM_CLIENT_EMAIL: ${fcmClientEmail.isNotEmpty ? "✅" : "❌"}',
    );
    print(
      '${AppConfig.logPrefix}    - FCM_PRIVATE_KEY: ${fcmPrivateKey.isNotEmpty ? "✅" : "❌"}',
    );
  }

  // Parallel initialization for better startup time
  await Future.wait([
    initializeDateFormatting('it_IT', null),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
  ]);

  // Initialize dependency injection
  await di.init();

  // Initialize notification services through GetIt
  try {
    final notificationService = di.sl<NotificationsService>();
    await notificationService.initialize();

    final fcmNotificationService = di.sl<FCMNotificationService>();
    await fcmNotificationService.initialize();

    final fcmWebService = di.sl<FCMWebService>();
    await fcmWebService.initialize();

    final stockNotificationService = di.sl<StockNotificationService>();
    await stockNotificationService.initialize();

    if (AppConfig.enableLogging) {
      print(
        '${AppConfig.logPrefix} ✅ Tutti i servizi di notifica inizializzati',
      );
    }
  } catch (e) {
    if (AppConfig.enableLogging) {
      print(
        '${AppConfig.logPrefix} ⚠️ Errore nell\'inizializzazione dei servizi di notifica: $e',
      );
    }
  }

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
