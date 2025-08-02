// ignore_for_file: unnecessary_null_comparison, deprecated_member_use, unused_import, unused_element

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/product.dart';
import '../../presentation/providers/product_provider.dart';
import '../widgets/product_card.dart';
import 'addproductform.dart';

class ProdottiPage extends StatelessWidget {
  const ProdottiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataOggi = DateFormat('d MMMM', 'it_IT').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: _AppBarTitle(dataOggi: dataOggi),
        toolbarHeight: 70,
      ),
      body: Column(
        children: const [
          _FilterControls(),
          SizedBox(height: 8),
          Expanded(child: _ProductList()),
        ],
      ),
      floatingActionButton: _AddProductFab(
        onPressed: () => _showProductDialog(context),
      ),
    );
  }
}

void _showProductDialog(BuildContext context, {Product? prodotto}) {
  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            prodotto == null ? 'Aggiungi Prodotto' : 'Modifica Prodotto',
          ),
          content: AddProductForm(
            prodottoDaModificare:
                prodotto != null
                    ? {
                      'id': prodotto.id,
                      'nome': prodotto.nome,
                      'categoria': prodotto.categoria,
                      'quantita': prodotto.quantita,
                      'soglia': prodotto.soglia,
                      'prezzoUnitario': prodotto.prezzoUnitario,
                      'consumati': prodotto.consumati,
                      'ultimaModifica': prodotto.ultimaModifica,
                    }
                    : null,
            onSave: (modifiche) async {
              if (modifiche == null) return;

              final provider = Provider.of<ProductProvider>(
                context,
                listen: false,
              );
              final productData = Product(
                id: prodotto?.id ?? '',
                nome: modifiche['nome'],
                categoria: modifiche['categoria'] ?? '',
                quantita: modifiche['quantita'],
                soglia: modifiche['soglia'],
                prezzoUnitario: modifiche['prezzoUnitario'] ?? 0.0,
                consumati: prodotto?.consumati ?? 0,
                ultimaModifica: DateTime.now(),
              );

              if (prodotto == null) {
                await provider.addProduct(productData);
              } else {
                await provider.updateProduct(productData);
              }
              Navigator.of(dialogContext).pop();
            },
          ),
        ),
  );
}

class _AppBarTitle extends StatelessWidget {
  final String dataOggi;
  const _AppBarTitle({required this.dataOggi});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.warehouse_outlined,
          color: Color(0xFF009688),
          size: 28,
        ),
        const SizedBox(width: 10),
        const Text(
          'Gestione Prodotti',
          style: TextStyle(
            color: Color(0xFF009688),
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        Text(
          dataOggi,
          style: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FilterControls extends StatelessWidget {
  const _FilterControls();
  @override
  Widget build(BuildContext context) {
    // Usa Consumer per ricostruire solo i controlli
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7FA),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) => provider.setSearchTerm(value),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF212121),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Cerca prodotto...',
                      hintStyle: TextStyle(
                        color: Color(0xFF616161),
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Color(0xFF009688),
                        size: 24,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: provider.activeCategory ?? 'Tutti',
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    style: const TextStyle(
                      color: Color(0xFF009688),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    items:
                        ['Tutti', ...provider.uniqueCategories]
                            .map(
                              (f) => DropdownMenuItem<String>(
                                value: f,
                                child: Text(f),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == 'Tutti') {
                        provider.setFilterCategory(null);
                      } else {
                        provider.setFilterCategory(value);
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: Color(0xFF009688),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductList extends StatelessWidget {
  const _ProductList();
  @override
  Widget build(BuildContext context) {
    // Usa Consumer per ricostruire solo la lista
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final prodotti = provider.prodotti;
        if (prodotti.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 64, color: Colors.teal.shade100),
                const SizedBox(height: 16),
                const Text(
                  'Nessun prodotto trovato',
                  style: TextStyle(fontSize: 18, color: Color(0xFF757575)),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 100,
          ),
          itemCount: prodotti.length,
          // Performance optimizations
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          itemBuilder: (context, index) {
            final prodotto = prodotti[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ProductCard(
                nome: prodotto.nome,
                quantita: prodotto.quantita,
                soglia: prodotto.soglia,
                onDecrement:
                    () => provider.updateQuantity(
                      prodotto,
                      prodotto.quantita - 1,
                    ),
                onIncrement:
                    () => provider.updateQuantity(
                      prodotto,
                      prodotto.quantita + 1,
                    ),
                onEdit: () => _showProductDialog(context, prodotto: prodotto),
                onDelete: () => provider.deleteProduct(prodotto.id),
              ),
            );
          },
        );
      },
    );
  }
}

class _AddProductFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddProductFab({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.teal,
        elevation: 6,
        shape: const CircleBorder(),
        tooltip: 'Aggiungi prodotto',
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
    );
  }
}
