class Fornitore {
  final String id;
  final String nome;
  final String numero;

  Fornitore({required this.id, required this.nome, required this.numero});

  // Business logic methods
  bool get isValidPhoneNumber => numero.length >= 10;
  String get displayName => nome.isNotEmpty ? nome : 'Fornitore senza nome';

  Fornitore copyWith({String? id, String? nome, String? numero}) {
    return Fornitore(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      numero: numero ?? this.numero,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fornitore && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Fornitore{id: $id, nome: $nome, numero: $numero}';
  }
}
