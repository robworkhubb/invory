import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class AppConfig {
  // Firebase Configuration
  static const String firebaseApiKey =
      'AIzaSyDjoMnOeETgX5-8U97I_HjgJFI8NxItAcg';
  static const String firebaseAuthDomain = 'invory-b9a72.firebaseapp.com';
  static const String firebaseProjectId = 'invory-b9a72';
  static const String firebaseStorageBucket =
      'invory-b9a72.firebasestorage.app';
  static const String firebaseMessagingSenderId = '524552556806';
  static const String firebaseAppId =
      '1:524552556806:web:4bae50045374103e684e87';
  static const String firebaseMeasurementId = 'G-MTDPNYBZG4';

  // VAPID Configuration
  static String get vapidKey => VapidKeys.vapidKey;
  static bool get hasVapidKey => vapidKey.isNotEmpty;

  // App Configuration
  static const String appName = 'Invory';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Gestione intelligente del magazzino';

  // Feature Flags
  static const bool enableNotifications = true;
  static const bool enableFCM = true;
  static const bool enableWebOptimizations = true;
  static const bool enableServiceWorkerRetry = true;
  static const bool enableVapidKeyValidation = true;

  // Debug Configuration
  static bool get isDebugMode => kDebugMode;
  static bool get isReleaseMode => kReleaseMode;
  static bool get isProfileMode => kProfileMode;

  // Web Configuration
  static const String webBaseUrl = '/invory/';
  static const String serviceWorkerPath = '/invory/firebase-messaging-sw.js';
  static const String serviceWorkerScope = '/invory/';
  static const Duration serviceWorkerRegistrationTimeout = Duration(
    seconds: 10,
  );
  static const int maxServiceWorkerRetryAttempts = 3;

  // Error Messages
  static const String errorFirebaseNotInitialized =
      'Firebase non inizializzato correttamente';
  static const String errorUserNotAuthenticated = 'Utente non autenticato';
  static const String errorNetworkConnection = 'Errore di connessione di rete';
  static const String errorPermissionDenied = 'Permessi insufficienti';
  static const String errorVapidKeyMissing = 'Chiave VAPID mancante';
  static const String errorServiceWorkerRegistration =
      'Errore registrazione Service Worker';

  // Success Messages
  static const String successLogin = 'Login effettuato con successo';
  static const String successLogout = 'Logout effettuato con successo';
  static const String successDataSaved = 'Dati salvati con successo';
  static const String successServiceWorkerRegistered =
      'Service Worker registrato con successo';

  // Validation Messages
  static const String validationEmailRequired = 'Email richiesta';
  static const String validationPasswordRequired = 'Password richiesta';
  static const String validationInvalidEmail = 'Email non valida';
  static const String validationPasswordTooShort = 'Password troppo corta';

  // Performance Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration tokenGenerationTimeout = Duration(seconds: 15);

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 100;

  // Notification Configuration
  static const String notificationChannelId = 'invory_notifications';
  static const String notificationChannelName = 'Invory Notifiche';
  static const String notificationChannelDescription =
      'Notifiche per la gestione del magazzino';

  // Logging Configuration
  static bool get enableLogging => isDebugMode;
  static const String logPrefix = '[Invory]';

  // Development Configuration
  static const bool enableMockData = false;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableCrashReporting = true;

  // Firebase Config Map for JavaScript
  static Map<String, String> get firebaseConfigMap => {
    'apiKey': firebaseApiKey,
    'authDomain': firebaseAuthDomain,
    'projectId': firebaseProjectId,
    'storageBucket': firebaseStorageBucket,
    'messagingSenderId': firebaseMessagingSenderId,
    'appId': firebaseAppId,
    'measurementId': firebaseMeasurementId,
  };

  // Validation methods
  static bool get isFirebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseAuthDomain.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  static bool get isWebNotificationReady =>
      isFirebaseConfigured && (hasVapidKey || !enableVapidKeyValidation);
}
