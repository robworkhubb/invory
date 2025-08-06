// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Classe per i colori della card basati sullo stato del prodotto
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
    super.key,
    required this.nome,
    required this.quantita,
    required this.soglia,
    this.onIncrement,
    this.onDecrement,
    this.onEdit,
    this.onDelete,
    this.showEditDelete = true,
    this.suggerita,
  });

  @override
  Widget build(BuildContext context) {
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
              _buildStatusIcon(cardColors),
              const SizedBox(width: 16),
              Expanded(child: _buildProductInfo(cardColors)),
            ],
          ),
        ),
      ),
    );
  }

  /// Determina i colori della card basati sullo stato del prodotto
  _CardColors _getCardColors() {
    if (quantita == 0) {
      return const _CardColors(
        bgColor: Color(0xFFFFF1F1),
        iconBg: Color(0xFFFF5252),
        iconData: Icons.error_outline,
        iconColor: Colors.white,
      );
    } else if (quantita < soglia) {
      return const _CardColors(
        bgColor: Color(0xFFFFF8E1),
        iconBg: Color(0xFFFFB300),
        iconData: Icons.warning_amber_rounded,
        iconColor: Colors.white,
      );
    } else {
      return const _CardColors(
        bgColor: Color(0xFFE8F5E9),
        iconBg: Color(0xFF43A047),
        iconData: Icons.check_circle_outline,
        iconColor: Colors.white,
      );
    }
  }

  /// Icona di stato del prodotto
  Widget _buildStatusIcon(_CardColors cardColors) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: cardColors.iconBg,
        shape: BoxShape.circle,
      ),
      child: Icon(cardColors.iconData, color: cardColors.iconColor, size: 22),
    );
  }

  /// Informazioni del prodotto
  Widget _buildProductInfo(_CardColors cardColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProductName(),
        if (suggerita == -1)
          const SizedBox.shrink()
        else if (suggerita != null)
          _buildSuggestedQuantity()
        else
          _buildQuantityInfo(cardColors),
      ],
    );
  }

  /// Nome del prodotto
  Widget _buildProductName() {
    return Text(
      nome,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: Color(0xFF212121),
      ),
    );
  }

  /// Quantità suggerita
  Widget _buildSuggestedQuantity() {
    return Text(
      'Quantità suggerita: $suggerita',
      style: const TextStyle(
        color: Color(0xFF009688),
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
    );
  }

  /// Informazioni sulla quantità e soglia
  Widget _buildQuantityInfo(_CardColors cardColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuantityRow(),
        const SizedBox(height: 8),
        _buildActionButtons(),
      ],
    );
  }

  /// Riga con quantità e soglia
  Widget _buildQuantityRow() {
    return Row(
      children: [
        _buildQuantityLabel(),
        _buildQuantityBadge(),
        const SizedBox(width: 6),
        _buildThresholdLabel(),
        _buildThresholdBadge(),
      ],
    );
  }

  /// Label per la quantità
  Widget _buildQuantityLabel() {
    return Text(
      'Quantità: ',
      style: TextStyle(color: Colors.grey[700], fontSize: 15),
    );
  }

  /// Badge per la quantità
  Widget _buildQuantityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 22),
      decoration: _getBadgeDecoration(),
      child: Text(
        '$quantita',
        style: TextStyle(
          color: _getQuantityColor(),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }

  /// Label per la soglia
  Widget _buildThresholdLabel() {
    return Text(
      'Soglia: ',
      style: TextStyle(color: Colors.grey[700], fontSize: 15),
    );
  }

  /// Badge per la soglia
  Widget _buildThresholdBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 22),
      decoration: _getBadgeDecoration(),
      child: Text(
        '$soglia',
        style: TextStyle(
          color: Color(0xFF009688),
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }

  /// Decorazione per i badge
  BoxDecoration _getBadgeDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Colore per la quantità basato sullo stato
  Color _getQuantityColor() {
    if (quantita == 0) {
      return const Color(0xFFFF5252);
    } else if (quantita < soglia) {
      return const Color(0xFFFFB300);
    } else {
      return const Color(0xFF43A047);
    }
  }

  /// Pulsanti di azione
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (onDecrement != null) _buildDecrementButton(),
        if (onIncrement != null) _buildIncrementButton(),
        if (showEditDelete && onEdit != null) _buildEditButton(),
        if (showEditDelete && onDelete != null) _buildDeleteButton(),
      ],
    );
  }

  /// Pulsante decremento
  Widget _buildDecrementButton() {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: IconButton(
        icon: const Icon(Icons.remove, size: 18),
        color: Colors.red,
        onPressed: onDecrement,
        splashRadius: 20,
      ),
    );
  }

  /// Pulsante incremento
  Widget _buildIncrementButton() {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: IconButton(
        icon: const Icon(Icons.add, size: 18),
        color: Colors.green,
        onPressed: onIncrement,
        splashRadius: 20,
      ),
    );
  }

  /// Pulsante modifica
  Widget _buildEditButton() {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: IconButton(
        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 18),
        onPressed: onEdit,
        splashRadius: 20,
      ),
    );
  }

  /// Pulsante eliminazione
  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
        onPressed: onDelete,
        splashRadius: 20,
      ),
    );
  }
}
