import 'package:flutter/material.dart';
import '../../domain/entities/product.dart';

class LowStockAlert extends StatelessWidget {
  final List<Product> products;
  final VoidCallback? onRefresh;

  const LowStockAlert({Key? key, required this.products, this.onRefresh})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lowStockProducts = products.where((p) => p.isLowStock).toList();

    if (lowStockProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Scorte Basse',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
              if (onRefresh != null)
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  color: Colors.orange.shade700,
                  tooltip: 'Aggiorna',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${lowStockProducts.length} prodotto${lowStockProducts.length == 1 ? '' : 'i'} con scorte basse',
            style: TextStyle(fontSize: 14, color: Colors.orange.shade600),
          ),
          const SizedBox(height: 12),
          ...lowStockProducts
              .take(3)
              .map(
                (product) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              product.quantita == 0
                                  ? Colors.red.shade100
                                  : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.quantita == 0
                              ? 'Esaurito'
                              : '${product.quantita}/${product.soglia}',
                          style: TextStyle(
                            color:
                                product.quantita == 0
                                    ? Colors.red.shade700
                                    : Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          if (lowStockProducts.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'E altri ${lowStockProducts.length - 3} prodotti...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
