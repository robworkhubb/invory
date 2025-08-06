import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'core/config/locale_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/services/service_worker_manager.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/supplier_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'theme.dart';
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

  // Inizializzazione sequenziale per garantire l'ordine corretto
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.init();

  // Inizializza i dati di localizzazione per intl
  await LocaleConfig.initialize();

  // Inizializza il Service Worker Manager (solo per web)
  if (kIsWeb) {
    await _initializeServiceWorker();
  }

  runApp(const MyApp());
}

/// Inizializza il Service Worker Manager per il web
Future<void> _initializeServiceWorker() async {
  try {
    if (AppConfig.enableLogging) {
      print(
        '${AppConfig.logPrefix} 🔧 Inizializzazione Service Worker Manager...',
      );
    }

    final swManager = ServiceWorkerManager();
    await swManager.initialize();

    if (AppConfig.enableLogging) {
      print('${AppConfig.logPrefix} ✅ Service Worker Manager inizializzato');
    }
  } catch (e) {
    if (AppConfig.enableLogging) {
      print(
        '${AppConfig.logPrefix} ⚠️ Errore inizializzazione Service Worker Manager: $e',
      );
    }
    // Non bloccare l'avvio dell'app se il service worker fallisce
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<AuthProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<ProductProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<SupplierProvider>()),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: AppConfig.isDebugMode,
        home: const SplashScreen(),
        builder: (context, child) {
          // Ottimizzazioni per il web
          if (kIsWeb && AppConfig.enableWebOptimizations) {
            return _buildWebOptimizedApp(context, child);
          }
          return child!;
        },
      ),
    );
  }

  /// Builder ottimizzato per il web
  Widget _buildWebOptimizedApp(BuildContext context, Widget? child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: child!,
    );
  }
}
