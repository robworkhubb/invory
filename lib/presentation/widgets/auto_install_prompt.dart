import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import '../../../core/services/notification_service.dart';

class AutoInstallPrompt extends StatefulWidget {
  const AutoInstallPrompt({super.key});

  @override
  State<AutoInstallPrompt> createState() => _AutoInstallPromptState();
}

class _AutoInstallPromptState extends State<AutoInstallPrompt> {
  bool _showPrompt = false;
  bool _isInstalled = false;
  bool _hasShownPrompt = false;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _checkInstallation();
    }
  }

  void _checkInstallation() {
    if (kIsWeb) {
      try {
        // Controlla se l'app è già installata
        if (html.window.matchMedia('(display-mode: standalone)').matches) {
          setState(() {
            _isInstalled = true;
          });
        } else {
          // Controlla se l'evento beforeinstallprompt è disponibile
          if (html.window.localStorage['beforeinstallprompt'] == 'true' &&
              !_hasShownPrompt) {
            // Mostra il prompt automaticamente dopo 1 secondo (più veloce)
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted && !_isInstalled) {
                setState(() {
                  _showPrompt = true;
                  _hasShownPrompt = true;
                });
              }
            });
          }
        }
      } catch (e) {
        print('Errore nel controllo installazione: $e');
      }
    }
  }

  void _installApp() async {
    if (kIsWeb) {
      try {
        // Usa il servizio di notifiche per mostrare il prompt
        await _notificationService.showInstallPrompt();

        setState(() {
          _showPrompt = false;
        });
      } catch (e) {
        print('Errore nell\'installazione: $e');
      }
    }
  }

  void _dismissPrompt() {
    setState(() {
      _showPrompt = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _isInstalled || !_showPrompt) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.download_rounded,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Installa Invory',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _dismissPrompt,
                icon: const Icon(Icons.close),
                color: Colors.blue.shade700,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Aggiungi Invory alla schermata home per un accesso più veloce e notifiche push.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _installApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Installa'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _dismissPrompt,
                child: const Text('Più tardi'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
