# Sistema di Notifiche - Invory

## Panoramica

Il sistema di notifiche di Invory è stato implementato seguendo i principi della Clean Architecture e funziona su piattaforme mobile (Android/iOS) con notifiche native del sistema.

## Funzionalità

### ✅ Notifiche Automatiche
- **Scorte Basse**: Notifica quando un prodotto scende sotto la soglia minima
- **Prodotto Esaurito**: Notifica quando un prodotto raggiunge quantità zero
- **Controllo Automatico**: Le notifiche vengono controllate automaticamente dopo ogni operazione CRUD

### ✅ UI Integrata
- **Alert Visivo**: Widget che mostra i prodotti con scorte basse nella home
- **Refresh**: Possibilità di aggiornare manualmente e controllare le notifiche
- **Design Responsive**: Interfaccia ottimizzata per tutti i dispositivi

### ✅ Gestione Permessi
- **Richiesta Automatica**: I permessi vengono richiesti automaticamente all'avvio
- **Gestione Errori**: Sistema robusto che gestisce i casi di errore
- **Fallback Graceful**: L'app continua a funzionare anche se le notifiche non sono disponibili

## Architettura

### 1. Service Layer (`lib/core/services/notification_service.dart`)
```dart
abstract class INotificationService {
  Future<void> initialize();
  Future<void> requestPermissions();
  Future<void> showLowStockNotification(Product product);
  Future<void> showOutOfStockNotification(Product product);
  Future<bool> arePermissionsGranted();
}
```

**Caratteristiche:**
- Singleton pattern per ottimizzazione
- Gestione errori robusta
- Supporto cross-platform
- Inizializzazione lazy

### 2. Use Case (`lib/domain/usecases/product/check_stock_notifications_usecase.dart`)
```dart
class CheckStockNotificationsUseCase {
  Future<List<Product>> call() async {
    // Controlla prodotti con scorte basse o esauriti
  }
}
```

**Funzionalità:**
- Logica di business centralizzata
- Controllo automatico delle scorte
- Gestione errori

### 3. Provider Integration (`lib/presentation/providers/product_provider.dart`)
```dart
class ProductProvider with ChangeNotifier {
  Future<void> checkAndShowNotifications() async {
    // Controlla e mostra notifiche automaticamente
  }
}
```

**Integrazione:**
- Controllo automatico dopo ogni operazione CRUD
- Inizializzazione automatica del servizio
- Gestione dello stato delle notifiche

### 4. UI Components

#### Low Stock Alert (`lib/presentation/widgets/low_stock_alert.dart`)
- Mostra prodotti con scorte basse
- Design responsive e ottimizzato
- Possibilità di refresh manuale

#### Web Notification Prompt (`lib/presentation/widgets/web_notification_prompt.dart`)
- Preparato per future implementazioni web
- Gestione permessi cross-platform

## Configurazione

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- Receivers per notifiche programmate -->
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.PACKAGE_REPLACED" android:dataScheme="package"/>
    </intent-filter>
</receiver>
```

### Dependency Injection (`lib/core/di/injection_container.dart`)
```dart
// Services
sl.registerLazySingleton<INotificationService>(() => NotificationService());

// Use cases
sl.registerLazySingleton(() => CheckStockNotificationsUseCase(sl()));
```

## Flusso di Funzionamento

### 1. Inizializzazione
```dart
// main.dart
final notificationService = NotificationService();
await notificationService.initialize();
```

### 2. Controllo Automatico
```dart
// Dopo ogni operazione CRUD
await checkAndShowNotifications();
```

### 3. Logica di Business
```dart
// Controlla prodotti con scorte basse
final lowStockProducts = await _checkStockNotificationsUseCase();

for (final product in lowStockProducts) {
  if (product.quantita == 0) {
    await _notificationService.showOutOfStockNotification(product);
  } else if (product.quantita <= product.soglia) {
    await _notificationService.showLowStockNotification(product);
  }
}
```

## Tipi di Notifiche

### Scorte Basse
- **Titolo**: "Scorte Basse: [Nome Prodotto]"
- **Messaggio**: "Quantità: X (Soglia: Y)"
- **Colore**: Arancione
- **Priorità**: Alta
- **Suono**: Sì
- **Vibrazione**: Sì

### Prodotto Esaurito
- **Titolo**: "Prodotto Esaurito: [Nome Prodotto]"
- **Messaggio**: "Il prodotto è completamente esaurito!"
- **Colore**: Rosso
- **Priorità**: Alta
- **Suono**: Sì
- **Vibrazione**: Sì

## Ottimizzazioni Implementate

### 1. Performance
- **Lazy Loading**: Inizializzazione solo quando necessario
- **Singleton Pattern**: Una sola istanza del servizio
- **Caching**: Gestione efficiente della memoria
- **Stream Management**: Gestione ottimizzata dei listener

### 2. UX
- **Non Bloccante**: Le notifiche non bloccano l'interfaccia
- **Feedback Visivo**: Alert nella home per scorte basse
- **Refresh Manuale**: Possibilità di aggiornare manualmente
- **Gestione Errori**: Messaggi di errore appropriati

### 3. Robustezza
- **Try-Catch**: Gestione completa degli errori
- **Fallback**: L'app funziona anche senza notifiche
- **Permessi**: Gestione automatica dei permessi
- **Platform Check**: Controllo della piattaforma

## Test e Debug

### Log di Debug
```dart
print('Errore nell\'inizializzazione notifiche: $e');
print('Errore durante il controllo delle notifiche: $e');
print('Notifica cliccata: ${response.payload}');
```

### Controllo Permessi
```dart
final permissionsGranted = await notificationService.arePermissionsGranted();
```

### Test Manuale
1. Aggiungi un prodotto con quantità bassa
2. Verifica che appaia la notifica
3. Controlla l'alert nella home
4. Testa il refresh manuale

## Future Implementazioni

### Web Support
- Service Worker per PWA
- Notifiche push tramite Chrome
- Install prompt per PWA

### Notifiche Programmabili
- Controllo periodico delle scorte
- Notifiche di reminder
- Scheduling personalizzato

### Analytics
- Tracking delle notifiche visualizzate
- Metriche di engagement
- A/B testing

## Troubleshooting

### Problemi Comuni

1. **Notifiche non appaiono**
   - Verifica i permessi
   - Controlla i log di debug
   - Riavvia l'app

2. **Errore di inizializzazione**
   - Verifica le dipendenze
   - Controlla la configurazione Android
   - Verifica il manifest

3. **Performance lente**
   - Verifica il lazy loading
   - Controlla la gestione della memoria
   - Ottimizza i listener

### Log Utili
```bash
flutter logs
flutter analyze
flutter doctor
```

## Conclusione

Il sistema di notifiche è stato implementato seguendo le best practices della Clean Architecture, con focus su:

- ✅ **Performance**: Ottimizzato per dispositivi lenti
- ✅ **UX**: Esperienza utente fluida e intuitiva
- ✅ **Robustezza**: Gestione errori completa
- ✅ **Manutenibilità**: Codice pulito e ben strutturato
- ✅ **Scalabilità**: Pronto per future espansioni

Il sistema è pronto per la produzione e fornisce un'esperienza completa di gestione delle scorte con notifiche intelligenti e tempestive. 