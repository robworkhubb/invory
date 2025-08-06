import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

/// Configurazione per la gestione delle localizzazioni
class LocaleConfig {
  static const String _logPrefix = '[LocaleConfig]';

  /// Inizializza i dati di localizzazione per l'app
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('$_logPrefix 🔧 Inizializzazione dati di localizzazione...');
      }

      // Inizializza i dati per l'italiano
      await initializeDateFormatting('it_IT');

      if (kDebugMode) {
        print('$_logPrefix ✅ Dati di localizzazione inizializzati');
      }
    } catch (e) {
      if (kDebugMode) {
        print('$_logPrefix ❌ Errore inizializzazione localizzazione: $e');
      }
      // Non bloccare l'avvio dell'app se l'inizializzazione fallisce
    }
  }

  /// Verifica se i dati di localizzazione sono stati inizializzati
  static bool get isInitialized {
    try {
      // Prova a formattare una data per verificare se i dati sono caricati
      final testDate = DateTime.now();
      final formatter = DateFormat('d MMMM yyyy', 'it_IT');
      formatter.format(testDate);
      return true;
    } catch (e) {
      return false;
    }
  }
}
