// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

// Performance optimization: data class for card colors
class _CardColors {
  final Color bgColor;
  final Color iconBg;
  final IconData iconData;
  final Color iconColor;

  const _CardColors({
    required this.bgColor,
    required this.iconBg,
    required this.iconData,
    required this.iconColor,
  });
}

class ProductCard extends StatelessWidget {
  final String nome;
  final int quantita;
  final int soglia;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showEditDelete;
  final int? suggerita;

  const ProductCard({
    Key? key,
    required this.nome,
    required this.quantita,
    required this.soglia,
    this.onIncrement,
    this.onDecrement,
    this.onEdit,
    this.onDelete,
    this.showEditDelete = true,
    this.suggerita,
  }) : super(key: key); // Costruttore const: ottimo per performance

  // Performance optimization: calculate colors once
  _CardColors _getCardColors() {
    if (quantita == 0) {
      return _CardColors(
        bgColor: const Color(0xFFFFF1F1),
        iconBg: const Color(0xFFFF5252),
        iconData: Icons.error_outline,
        iconColor: Colors.white,
      );
    } else if (quantita < soglia) {
      return _CardColors(
        bgColor: const Color(0xFFFFF8E1),
        iconBg: const Color(0xFFFFB300),
        iconData: Icons.warning_amber_rounded,
        iconColor: Colors.white,
      );
    } else {
      return _CardColors(
        bgColor: const Color(0xFFE8F5E9),
        iconBg: const Color(0xFF43A047),
        iconData: Icons.check_circle_outline,
        iconColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Performance optimization: calculate colors once
    final cardColors = _getCardColors();

    return RepaintBoundary(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        color: cardColors.bgColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Leading icon in colored circle
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cardColors.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  cardColors.iconData,
                  color: cardColors.iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF212121),
                      ),
                    ),
                    if (suggerita == -1)
                      ...[]
                    else if (suggerita != null) ...[
                      Text(
                        'Quantità suggerita: $suggerita',
                        style: const TextStyle(
                          color: Color(0xFF009688),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Text(
                            'Quantità: ',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 15,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            constraints: const BoxConstraints(minWidth: 22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              '$quantita',
                              style: TextStyle(
                                color:
                                    quantita == 0
                                        ? const Color(0xFFFF5252)
                                        : quantita < soglia
                                        ? const Color(0xFFFFB300)
                                        : const Color(0xFF43A047),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Soglia: ',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 15,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            constraints: const BoxConstraints(minWidth: 22),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              '$soglia',
                              style: const TextStyle(
                                color: Color(0xFF009688),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          if (onDecrement != null)
                            Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.remove, size: 18),
                                color: Colors.red,
                                onPressed: onDecrement,
                                splashRadius: 20,
                              ),
                            ),
                          if (onIncrement != null)
                            Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(Icons.add, size: 18),
                                color: Colors.green,
                                onPressed: onIncrement,
                                splashRadius: 20,
                              ),
                            ),
                          if (showEditDelete && onEdit != null)
                            Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                onPressed: onEdit,
                                splashRadius: 20,
                              ),
                            ),
                          if (showEditDelete && onDelete != null)
                            Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                onPressed: onDelete,
                                splashRadius: 20,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
