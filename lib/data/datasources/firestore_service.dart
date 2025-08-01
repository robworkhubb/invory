import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/fornitore_model.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/fornitore.dart';

class FirestoreService {
  // Use lazy initialization instead of immediate initialization
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Connection pooling and retry configuration

  // Helper method to get current user ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Helper method to get user products collection reference
  CollectionReference<Map<String, dynamic>>? get _userProductsCollection {
    final userId = _currentUserId;
    if (userId == null) return null;
    return _db.collection('users').doc(userId).collection('prodotti');
  }

  // Helper method to get user suppliers collection reference
  CollectionReference<Map<String, dynamic>>? get _userSuppliersCollection {
    final userId = _currentUserId;
    if (userId == null) return null;
    return _db.collection('users').doc(userId).collection('fornitori');
  }

  // Helper method to ensure user document exists
  Future<void> _ensureUserDocument() async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Utente non autenticato');
    }

    try {
      final userDoc = _db.collection('users').doc(userId);
      final userDocSnapshot = await userDoc.get();

      if (!userDocSnapshot.exists) {
        // Create user document with basic info
        await userDoc.set({
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'email': FirebaseAuth.instance.currentUser?.email ?? '',
        });
      } else {
        // Update last login
        await userDoc.update({'lastLogin': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Errore nella creazione/aggiornamento documento utente: $e');
      }
      // Non lanciare l'eccezione, permette all'operazione di continuare
      // Il documento verrà creato automaticamente quando necessario
    }
  }

  // 📦 PRODOTTI - Metodi per gestione prodotti specifici dell'utente
  // users/{uid}/prodotti

  /// Aggiunge un prodotto alla collezione specifica dell'utente
  Future<void> addProduct(Product product) async {
    final collection = _userProductsCollection;
    if (collection == null) {
      throw Exception('Utente non autenticato');
    }

    final productModel = ProductModel.fromEntity(product);

    try {
      await collection.add(productModel.toMap());
    } catch (e) {
      print('Errore nell\'aggiunta del prodotto: $e');
      // Se l'errore è dovuto al fatto che la collezione non esiste,
      // proviamo a creare il documento utente e riprovare
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('not-found') ||
          e.toString().contains('unavailable')) {
        try {
          print('Tentativo di creazione documento utente e retry...');
          await _ensureUserDocument();
          await collection.add(productModel.toMap());
          print('Prodotto aggiunto con successo dopo retry!');
        } catch (retryError) {
          print('Errore nel retry: $retryError');
          throw Exception(
            'Impossibile aggiungere il prodotto dopo il retry: $retryError',
          );
        }
      } else {
        throw Exception('Errore nell\'aggiunta del prodotto: $e');
      }
    }
  }

  /// Recupera tutti i prodotti dell'utente corrente come stream
  Stream<List<Product>> fetchProducts() {
    final collection = _userProductsCollection;
    if (collection == null) {
      return Stream.value([]); // Return empty list if user not authenticated
    }
    return collection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList(),
    );
  }

  /// Aggiorna un prodotto nella collezione specifica dell'utente
  Future<void> updateProduct(Product product) async {
    await _ensureUserDocument();
    final collection = _userProductsCollection;
    if (collection == null) {
      throw Exception('Utente non autenticato');
    }
    final productModel = ProductModel.fromEntity(product);
    return collection.doc(product.id).update(productModel.toMap());
  }

  /// Elimina un prodotto dalla collezione specifica dell'utente
  Future<void> deleteProduct(String id) async {
    await _ensureUserDocument();
    final collection = _userProductsCollection;
    if (collection == null) {
      throw Exception('Utente non autenticato');
    }
    return collection.doc(id).delete();
  }

  // 🧑‍💼 FORNITORI - Metodi per gestione fornitori specifici dell'utente
  // users/{uid}/fornitori

  /// Aggiunge un fornitore alla collezione specifica dell'utente
  Future<void> addSupplier(Fornitore supplier) async {
    final collection = _userSuppliersCollection;
    if (collection == null) {
      throw Exception('Utente non autenticato');
    }

    final supplierModel = FornitoreModel.fromEntity(supplier);

    try {
      await collection.add(supplierModel.toMap());
    } catch (e) {
      print('Errore nell\'aggiunta del fornitore: $e');
      // Se l'errore è dovuto al fatto che la collezione non esiste,
      // proviamo a creare il documento utente e riprovare
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('not-found') ||
          e.toString().contains('unavailable')) {
        try {
          print(
            'Tentativo di creazione documento utente e retry per fornitore...',
          );
          await _ensureUserDocument();
          await collection.add(supplierModel.toMap());
          print('Fornitore aggiunto con successo dopo retry!');
        } catch (retryError) {
          print('Errore nel retry fornitore: $retryError');
          throw Exception(
            'Impossibile aggiungere il fornitore dopo il retry: $retryError',
          );
        }
      } else {
        throw Exception('Errore nell\'aggiunta del fornitore: $e');
      }
    }
  }

  /// Recupera tutti i fornitori dell'utente corrente come stream
  Stream<List<Fornitore>> fetchSuppliers() {
    final collection = _userSuppliersCollection;
    if (collection == null) {
      return Stream.value([]); // Return empty list if user not authenticated
    }
    return collection.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map((doc) => FornitoreModel.fromFirestore(doc))
              .toList(),
    );
  }

  /// Aggiorna un fornitore nella collezione specifica dell'utente
  Future<void> updateSupplier(Fornitore supplier) async {
    await _ensureUserDocument();
    final collection = _userSuppliersCollection;
    if (collection == null) {
      throw Exception('Utente non autenticato');
    }
    final supplierModel = FornitoreModel.fromEntity(supplier);
    return collection.doc(supplier.id).update(supplierModel.toMap());
  }

  /// Elimina un fornitore dalla collezione specifica dell'utente
  Future<void> deleteSupplier(String id) async {
    await _ensureUserDocument();
    final collection = _userSuppliersCollection;
    if (collection == null) {
      throw Exception('Utente non autenticato');
    }
    return collection.doc(id).delete();
  }
}
