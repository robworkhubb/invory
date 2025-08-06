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
    final currentDate = DateFormat('d MMMM', 'it_IT').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(currentDate),
      body: const _ProductPageContent(),
      floatingActionButton: _AddProductFab(
        onPressed: () => _showProductDialog(context),
      ),
    );
  }

  /// Costruisce l'AppBar
  PreferredSizeWidget _buildAppBar(String currentDate) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      title: _AppBarTitle(currentDate: currentDate),
      toolbarHeight: 70,
    );
  }
}

/// Mostra il dialog per aggiungere/modificare un prodotto
void _showProductDialog(BuildContext context, {Product? product}) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        product == null ? 'Aggiungi Prodotto' : 'Modifica Prodotto',
      ),
      content: AddProductForm(
        prodottoDaModificare: product != null ? _convertProductToMap(product) : null,
        onSave: (modifications) => _handleProductSave(context, dialogContext, product, modifications),
      ),
    ),
  );
}

/// Converte un Product in Map per il form
Map<String, dynamic> _convertProductToMap(Product product) {
  return {
    'id': product.id,
    'nome': product.nome,
    'categoria': product.categoria,
    'quantita': product.quantita,
    'soglia': product.soglia,
    'prezzoUnitario': product.prezzoUnitario,
    'consumati': product.consumati,
    'ultimaModifica': product.ultimaModifica,
  };
}

/// Gestisce il salvataggio del prodotto
Future<void> _handleProductSave(
  BuildContext context,
  BuildContext dialogContext,
  Product? existingProduct,
  Map<String, dynamic> modifications,
) async {
  if (modifications.isEmpty) return;

  final provider = Provider.of<ProductProvider>(context, listen: false);
  final productData = _createProductData(existingProduct, modifications);

  if (existingProduct == null) {
    await provider.addProduct(productData);
  } else {
    await provider.updateProduct(productData);
  }
  
  Navigator.of(dialogContext).pop();
}

/// Crea i dati del prodotto per il salvataggio
Product _createProductData(Product? existingProduct, Map<String, dynamic> modifications) {
  return Product(
    id: existingProduct?.id ?? '',
    nome: modifications['nome'],
    categoria: modifications['categoria'] ?? '',
    quantita: modifications['quantita'],
    soglia: modifications['soglia'],
    prezzoUnitario: modifications['prezzoUnitario'] ?? 0.0,
    consumati: existingProduct?.consumati ?? 0,
    ultimaModifica: DateTime.now(),
  );
}

/// Widget per il titolo dell'AppBar
class _AppBarTitle extends StatelessWidget {
  final String currentDate;
  
  const _AppBarTitle({required this.currentDate});

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
          currentDate,
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

/// Contenuto principale della pagina prodotti
class _ProductPageContent extends StatelessWidget {
  const _ProductPageContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _FilterControls(),
        SizedBox(height: 8),
        Expanded(child: _ProductList()),
      ],
    );
  }
}

/// Controlli per filtrare i prodotti
class _FilterControls extends StatelessWidget {
  const _FilterControls();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Row(
            children: [
              Expanded(child: _buildSearchField(provider)),
              const SizedBox(width: 16),
              _buildCategoryFilter(provider),
            ],
          ),
        );
      },
    );
  }

  /// Campo di ricerca
  Widget _buildSearchField(ProductProvider provider) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
    );
  }

  /// Filtro per categoria
  Widget _buildCategoryFilter(ProductProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
          items: _buildCategoryItems(provider),
          onChanged: (value) => _handleCategoryChange(provider, value),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF009688),
          ),
        ),
      ),
    );
  }

  /// Costruisce gli elementi del dropdown categoria
  List<DropdownMenuItem<String>> _buildCategoryItems(ProductProvider provider) {
    return ['Tutti', ...provider.uniqueCategories]
        .map((category) => DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            ))
        .toList();
  }

  /// Gestisce il cambio di categoria
  void _handleCategoryChange(ProductProvider provider, String? value) {
    if (value == 'Tutti') {
      provider.setFilterCategory(null);
    } else {
      provider.setFilterCategory(value);
    }
  }
}

/// Lista dei prodotti
class _ProductList extends StatelessWidget {
  const _ProductList();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = provider.prodotti;
        if (products.isEmpty) {
          return _buildEmptyState();
        }

        return _buildProductListView(provider, products);
      },
    );
  }

  /// Stato vuoto quando non ci sono prodotti
  Widget _buildEmptyState() {
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

  /// Lista scrollabile dei prodotti
  Widget _buildProductListView(ProductProvider provider, List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 100,
      ),
      itemCount: products.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (context, index) {
        final product = products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ProductCard(
            nome: product.nome,
            quantita: product.quantita,
            soglia: product.soglia,
            onDecrement: () => _handleQuantityChange(provider, product, -1),
            onIncrement: () => _handleQuantityChange(provider, product, 1),
            onEdit: () => _showProductDialog(context, product: product),
            onDelete: () => provider.deleteProduct(product.id),
          ),
        );
      },
    );
  }

  /// Gestisce il cambio di quantità
  void _handleQuantityChange(ProductProvider provider, Product product, int change) {
    final newQuantity = product.quantita + change;
    if (newQuantity >= 0) {
      provider.updateQuantity(product, newQuantity);
    }
  }
}

/// Floating Action Button per aggiungere prodotti
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
