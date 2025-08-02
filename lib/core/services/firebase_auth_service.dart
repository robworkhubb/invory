import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Ottiene l'utente corrente
  User? get currentUser => _auth.currentUser;

  /// Stream per ascoltare i cambiamenti di autenticazione
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Accedi con email e password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (kDebugMode) {
        print('Utente autenticato: ${credential.user?.email}');
      }
      
      return credential;
    } catch (e) {
      if (kDebugMode) {
        print('Errore nel login: $e');
      }
      rethrow;
    }
  }

  /// Registra un nuovo utente
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (kDebugMode) {
        print('Utente registrato: ${credential.user?.email}');
      }
      
      return credential;
    } catch (e) {
      if (kDebugMode) {
        print('Errore nella registrazione: $e');
      }
      rethrow;
    }
  }

  /// Disconnetti l'utente
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      if (kDebugMode) {
        print('Utente disconnesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nel logout: $e');
      }
      rethrow;
    }
  }

  /// Ottieni l'ID token per autenticare le chiamate API
  Future<String?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final idToken = await user.getIdToken();
      
      if (kDebugMode) {
        print('ID Token ottenuto con successo');
      }
      
      return idToken;
    } catch (e) {
      if (kDebugMode) {
        print('Errore nell\'ottenimento dell\'ID token: $e');
      }
      return null;
    }
  }

  /// Ottieni l'ID token forzando il refresh
  Future<String?> getIdTokenForceRefresh() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final idToken = await user.getIdToken(true); // Force refresh
      
      if (kDebugMode) {
        print('ID Token aggiornato con successo');
      }
      
      return idToken;
    } catch (e) {
      if (kDebugMode) {
        print('Errore nell\'aggiornamento dell\'ID token: $e');
      }
      return null;
    }
  }

  /// Verifica se l'utente è autenticato
  bool get isAuthenticated => _auth.currentUser != null;

  /// Ottieni l'email dell'utente corrente
  String? get userEmail => _auth.currentUser?.email;

  /// Ottieni l'UID dell'utente corrente
  String? get userId => _auth.currentUser?.uid;
} 