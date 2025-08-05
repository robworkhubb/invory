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

  // Helper method to get current user ID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Helper method to get user products collection reference
  CollectionReference<Map<String, dynamic>> get _userProductsCollection {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Utente non autenticato');
    }
    return _db.collection('users').doc(userId).collection('products');
  }

  // Helper method to get user suppliers collection reference
  CollectionReference<Map<String, dynamic>> get _userSuppliersCollection {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('Utente non autenticato');
    }
    return _db.collection('users').doc(userId).collection('suppliers');
  }

  // Helper method to ensure user document exists
  Future<void> _ensureUserDocumentExists() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        await _db.collection('users').doc(userId).set({
          'uid': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        if (kDebugMode) {
          print('✅ Documento utente creato: $userId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Errore nella creazione documento utente: $e');
      }
    }
  }

  // 📦 PRODOTTI - Metodi per gestione prodotti specifici dell'utente
  // users/{uid}/products/{productId}

  /// Aggiunge un prodotto alla collezione products dell'utente
  Future<void> addProduct(Product product) async {
    await _ensureUserDocumentExists();

    final productModel = ProductModel.fromEntity(product);
    final productData = productModel.toMap();

    try {
      await _userProductsCollection.add(productData);
      if (kDebugMode) {
        print('✅ Prodotto aggiunto: ${product.nome}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'aggiunta del prodotto: $e');
      }
      throw Exception('Errore nell\'aggiunta del prodotto: $e');
    }
  }

  /// Recupera tutti i prodotti dell'utente corrente come stream
  Stream<List<Product>> fetchProducts() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]); // Return empty list if user not authenticated
    }

    return _userProductsCollection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList(),
    );
  }

  /// Aggiorna un prodotto nella collezione products dell'utente
  Future<void> updateProduct(Product product) async {
    await _ensureUserDocumentExists();

    final productModel = ProductModel.fromEntity(product);
    final productData = productModel.toMap();

    try {
      await _userProductsCollection.doc(product.id).update(productData);
      if (kDebugMode) {
        print('✅ Prodotto aggiornato: ${product.nome}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'aggiornamento del prodotto: $e');
      }
      throw Exception('Errore nell\'aggiornamento del prodotto: $e');
    }
  }

  /// Elimina un prodotto dalla collezione products dell'utente
  Future<void> deleteProduct(String id) async {
    try {
      await _userProductsCollection.doc(id).delete();
      if (kDebugMode) {
        print('✅ Prodotto eliminato: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'eliminazione del prodotto: $e');
      }
      throw Exception('Errore nell\'eliminazione del prodotto: $e');
    }
  }

  // 🧑‍💼 FORNITORI - Metodi per gestione fornitori specifici dell'utente
  // users/{uid}/suppliers/{supplierId}

  /// Aggiunge un fornitore alla collezione suppliers dell'utente
  Future<void> addSupplier(Fornitore supplier) async {
    await _ensureUserDocumentExists();

    final supplierModel = FornitoreModel.fromEntity(supplier);
    final supplierData = supplierModel.toMap();

    try {
      await _userSuppliersCollection.add(supplierData);
      if (kDebugMode) {
        print('✅ Fornitore aggiunto: ${supplier.nome}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'aggiunta del fornitore: $e');
      }
      throw Exception('Errore nell\'aggiunta del fornitore: $e');
    }
  }

  /// Recupera tutti i fornitori dell'utente corrente come stream
  Stream<List<Fornitore>> fetchSuppliers() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]); // Return empty list if user not authenticated
    }

    return _userSuppliersCollection.snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map((doc) => FornitoreModel.fromFirestore(doc))
              .toList(),
    );
  }

  /// Aggiorna un fornitore nella collezione suppliers dell'utente
  Future<void> updateSupplier(Fornitore supplier) async {
    await _ensureUserDocumentExists();

    final supplierModel = FornitoreModel.fromEntity(supplier);
    final supplierData = supplierModel.toMap();

    try {
      await _userSuppliersCollection.doc(supplier.id).update(supplierData);
      if (kDebugMode) {
        print('✅ Fornitore aggiornato: ${supplier.nome}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'aggiornamento del fornitore: $e');
      }
      throw Exception('Errore nell\'aggiornamento del fornitore: $e');
    }
  }

  /// Elimina un fornitore dalla collezione suppliers dell'utente
  Future<void> deleteSupplier(String id) async {
    try {
      await _userSuppliersCollection.doc(id).delete();
      if (kDebugMode) {
        print('✅ Fornitore eliminato: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Errore nell\'eliminazione del fornitore: $e');
      }
      throw Exception('Errore nell\'eliminazione del fornitore: $e');
    }
  }
}
