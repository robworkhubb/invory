import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';

class ProductModel extends Product {
  ProductModel({
    required super.id,
    required super.nome,
    required super.categoria,
    required super.quantita,
    required super.soglia,
    required super.prezzoUnitario,
    required super.consumati,
    super.ultimaModifica,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      nome: data['nome'],
      categoria: data['categoria'] ?? '',
      quantita: data['quantita'],
      soglia: data['soglia'],
      prezzoUnitario: (data['prezzoUnitario'] ?? 0).toDouble(),
      consumati: data['consumati'] ?? 0,
      ultimaModifica:
          data['ultimaModifica'] != null
              ? (data['ultimaModifica'] as Timestamp).toDate()
              : null,
    );
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      nome: product.nome,
      categoria: product.categoria,
      quantita: product.quantita,
      soglia: product.soglia,
      prezzoUnitario: product.prezzoUnitario,
      consumati: product.consumati,
      ultimaModifica: product.ultimaModifica,
    );
  }

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'categoria': categoria,
    'quantita': quantita,
    'soglia': soglia,
    'prezzoUnitario': prezzoUnitario,
    'consumati': consumati,
    'ultimaModifica':
        ultimaModifica != null ? Timestamp.fromDate(ultimaModifica!) : null,
  };
}
