import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/fornitore.dart';

class FornitoreModel extends Fornitore {
  FornitoreModel({
    required super.id,
    required super.nome,
    required super.numero,
  });

  factory FornitoreModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return FornitoreModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      numero: data['numero'] ?? '',
    );
  }

  factory FornitoreModel.fromEntity(Fornitore fornitore) {
    return FornitoreModel(
      id: fornitore.id,
      nome: fornitore.nome,
      numero: fornitore.numero,
    );
  }

  Map<String, dynamic> toMap() {
    return {'nome': nome, 'numero': numero};
  }
}
