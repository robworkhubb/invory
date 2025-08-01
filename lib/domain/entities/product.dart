class Product {
  final String id;
  final String nome;
  final String categoria;
  final int quantita;
  final int soglia;
  final double prezzoUnitario;
  final int consumati;
  final DateTime? ultimaModifica;

  Product({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.quantita,
    required this.soglia,
    required this.prezzoUnitario,
    required this.consumati,
    this.ultimaModifica,
  });

  // Business logic methods
  bool get isLowStock => quantita <= soglia;
  double get totalValue => quantita * prezzoUnitario;
  int get availableQuantity => quantita - consumati;

  Product copyWith({
    String? id,
    String? nome,
    String? categoria,
    int? quantita,
    int? soglia,
    double? prezzoUnitario,
    int? consumati,
    DateTime? ultimaModifica,
  }) {
    return Product(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      categoria: categoria ?? this.categoria,
      quantita: quantita ?? this.quantita,
      soglia: soglia ?? this.soglia,
      prezzoUnitario: prezzoUnitario ?? this.prezzoUnitario,
      consumati: consumati ?? this.consumati,
      ultimaModifica: ultimaModifica ?? this.ultimaModifica,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product{id: $id, nome: $nome, categoria: $categoria, quantita: $quantita, soglia: $soglia, prezzoUnitario: $prezzoUnitario, consumati: $consumati, ultimaModifica: $ultimaModifica}';
  }

  // Factory method per creare un Product vuoto
  factory Product.empty() {
    return Product(
      id: '',
      nome: '',
      categoria: '',
      quantita: 0,
      soglia: 0,
      prezzoUnitario: 0.0,
      consumati: 0,
    );
  }
}
