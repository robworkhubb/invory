class FCMConfig {
  // Configurazione per Firebase Cloud Messaging V1 API
  // Le credenziali vengono caricate dalle variabili d'ambiente
  static String get projectId =>
      const String.fromEnvironment('FCM_PROJECT_ID', defaultValue: '');

  // Endpoint FCM V1 API
  static const String fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/{projectId}/messages:send';

  // Configurazione notifiche
  static const String defaultNotificationTitle = '⚠️ Invory';
  static const String outOfStockTitle = '⚠️ Prodotto terminato';
  static const String lowStockTitle = '⚠️ Prodotto sotto scorta';

  // Scopes per l'autenticazione
  static const String scope =
      'https://www.googleapis.com/auth/firebase.messaging';

  // Credenziali Service Account (da variabili d'ambiente)
  static String get clientEmail =>
      const String.fromEnvironment('FCM_CLIENT_EMAIL', defaultValue: '');
  static String get privateKey =>
      const String.fromEnvironment('FCM_PRIVATE_KEY', defaultValue: '');

  // Verifica se le credenziali sono configurate
  static bool get isConfigured =>
      projectId.isNotEmpty && clientEmail.isNotEmpty && privateKey.isNotEmpty;
}
