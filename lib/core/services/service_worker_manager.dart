import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class ServiceWorkerManager {
  static final ServiceWorkerManager _instance =
      ServiceWorkerManager._internal();
  factory ServiceWorkerManager() => _instance;
  ServiceWorkerManager._internal();

  html.ServiceWorkerRegistration? _registration;
  bool _isInitialized = false;
  bool _isInitializing = false;
  final List<Completer<void>> _initializationCompleters = [];

  /// Inizializza il service worker con retry logic
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('${AppConfig.logPrefix} 🔧 Service Worker già inizializzato');
      }
      return;
    }

    if (_isInitializing) {
      // Se è già in corso l'inizializzazione, aspetta
      final completer = Completer<void>();
      _initializationCompleters.add(completer);
      return completer.future;
    }

    _isInitializing = true;

    try {
      if (kDebugMode) {
        print('${AppConfig.logPrefix} 🔧 Inizializzazione Service Worker...');
      }

      // Verifica supporto Service Worker
      if (!_isServiceWorkerSupported()) {
        throw Exception('Service Worker non supportato dal browser');
      }

      // Registra il service worker con retry
      await _registerServiceWorkerWithRetry();

      // Configura i listener per gli eventi del service worker
      _setupServiceWorkerListeners();

      _isInitialized = true;
      _isInitializing = false;

      // Completa tutti i completer in attesa
      for (final completer in _initializationCompleters) {
        completer.complete();
      }
      _initializationCompleters.clear();

      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ✅ Service Worker inizializzato con successo',
        );
      }
    } catch (e) {
      _isInitializing = false;

      // Completa tutti i completer con errore
      for (final completer in _initializationCompleters) {
        completer.completeError(e);
      }
      _initializationCompleters.clear();

      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ❌ Errore inizializzazione Service Worker: $e',
        );
      }
      rethrow;
    }
  }

  /// Verifica se il Service Worker è supportato
  bool _isServiceWorkerSupported() {
    return html.window.navigator.serviceWorker != null;
  }

  /// Registra il service worker con retry logic
  Future<void> _registerServiceWorkerWithRetry() async {
    int attempts = 0;
    Exception? lastError;

    while (attempts < AppConfig.maxServiceWorkerRetryAttempts) {
      try {
        attempts++;

        if (kDebugMode) {
          print(
            '${AppConfig.logPrefix} 🔧 Tentativo registrazione Service Worker $attempts/${AppConfig.maxServiceWorkerRetryAttempts}',
          );
        }

        _registration = await html.window.navigator.serviceWorker!
            .register(AppConfig.serviceWorkerPath)
            .timeout(AppConfig.serviceWorkerRegistrationTimeout);

        if (kDebugMode) {
          print(
            '${AppConfig.logPrefix} ✅ Service Worker registrato con successo',
          );
        }
        return;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());

        if (kDebugMode) {
          print('${AppConfig.logPrefix} ⚠️ Tentativo $attempts fallito: $e');
        }

        if (attempts < AppConfig.maxServiceWorkerRetryAttempts) {
          await Future.delayed(AppConfig.retryDelay * attempts);
        }
      }
    }

    throw Exception(
      'Impossibile registrare il Service Worker dopo ${AppConfig.maxServiceWorkerRetryAttempts} tentativi: ${lastError?.toString()}',
    );
  }

  /// Configura i listener per gli eventi del service worker
  void _setupServiceWorkerListeners() {
    if (_registration == null) return;

    // Listener per i messaggi dal service worker
    html.window.navigator.serviceWorker?.onMessage.listen((event) {
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} 📨 Messaggio ricevuto dal Service Worker: ${event.data}',
        );
      }
      _handleServiceWorkerMessage(event.data);
    });
  }

  /// Gestisce i messaggi dal service worker
  void _handleServiceWorkerMessage(dynamic data) {
    if (data is Map) {
      final type = data['type'];
      final payload = data['payload'];

      switch (type) {
        case 'FCM_TOKEN_GENERATED':
          if (kDebugMode) {
            print(
              '${AppConfig.logPrefix} ✅ Token FCM generato dal Service Worker',
            );
          }
          break;
        case 'NOTIFICATION_RECEIVED':
          if (kDebugMode) {
            print(
              '${AppConfig.logPrefix} 🔔 Notifica ricevuta dal Service Worker',
            );
          }
          break;
        case 'ERROR':
          if (kDebugMode) {
            print(
              '${AppConfig.logPrefix} ❌ Errore dal Service Worker: $payload',
            );
          }
          break;
        default:
          if (kDebugMode) {
            print(
              '${AppConfig.logPrefix} 📨 Messaggio sconosciuto dal Service Worker: $type',
            );
          }
      }
    }
  }

  /// Mostra un prompt per aggiornare l'app
  // ignore: unused_element
  void _showUpdatePrompt() {
    // Implementazione opzionale per mostrare un banner di aggiornamento
    if (kDebugMode) {
      print('${AppConfig.logPrefix} 🔄 Aggiornamento disponibile');
    }
  }

  /// Invia un messaggio al service worker
  Future<void> sendMessageToServiceWorker(
    String type, [
    dynamic payload,
  ]) async {
    if (_registration?.active == null) {
      throw Exception('Service Worker non attivo');
    }

    try {
      _registration!.active!.postMessage({
        'type': type,
        'payload': payload,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} 📤 Messaggio inviato al Service Worker: $type',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} ❌ Errore invio messaggio al Service Worker: $e',
        );
      }
      rethrow;
    }
  }

  /// Verifica se il service worker è attivo
  bool get isActive => _registration?.active != null;

  /// Ottiene il registration del service worker
  html.ServiceWorkerRegistration? get registration => _registration;

  /// Verifica se è inizializzato
  bool get isInitialized => _isInitialized;

  /// Forza l'aggiornamento del service worker
  Future<void> update() async {
    if (_registration != null) {
      await _registration!.update();
      if (kDebugMode) {
        print(
          '${AppConfig.logPrefix} 🔄 Aggiornamento Service Worker richiesto',
        );
      }
    }
  }

  /// Disinstalla il service worker (per testing)
  Future<void> unregister() async {
    if (_registration != null) {
      await _registration!.unregister();
      _registration = null;
      _isInitialized = false;
      if (kDebugMode) {
        print('${AppConfig.logPrefix} 🗑️ Service Worker disinstallato');
      }
    }
  }
}
