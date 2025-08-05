import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> loginWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Crea automaticamente il documento utente con la struttura richiesta
        await _createUserDocument(user);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Utente non trovato.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Password errata.');
      } else {
        throw Exception('Errore di login: ${e.message}');
      }
    }
  }

  /// Crea il documento utente con la struttura richiesta
  Future<void> _createUserDocument(User user) async {
    try {
      final userDocRef = _firestore.collection('users').doc(user.uid);

      // Verifica se il documento esiste già
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        // Crea il documento utente con la struttura base
        await userDocRef.set({
          'uid': user.uid,
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        if (kDebugMode) {
          print('✅ Documento utente creato per: ${user.email}');
        }
      } else {
        // Aggiorna solo l'ultimo login
        await userDocRef.update({'lastLogin': FieldValue.serverTimestamp()});

        if (kDebugMode) {
          print('✅ Login aggiornato per: ${user.email}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Errore nella creazione/aggiornamento documento utente: $e');
      }
      // Non bloccare il login se c'è un errore nella creazione del documento
    }
  }

  User? get currentUser => _auth.currentUser;

  Future<void> logout() async {
    await _auth.signOut();
  }
}
