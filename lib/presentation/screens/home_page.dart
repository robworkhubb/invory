import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/product.dart';
import '../../presentation/providers/product_provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../widgets/info_box.dart';
import '../widgets/product_card.dart';
import '../widgets/auto_install_prompt.dart';
import 'login_page.dart';
import '../../core/services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  /// Inizializza il sistema di notifiche
  Future<void> _initializeNotifications() async {
    try {
      await NotificationService().initialize();
      await NotificationService().savePendingToken();
    } catch (e) {
      if (kDebugMode) {
        print('Errore inizializzazione notifiche: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = DateFormat('d MMMM yyyy', 'it_IT').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(currentDate),
      body: const _HomePageContent(),
    );
  }

  /// Costruisce l'AppBar con titolo e pulsante logout
  PreferredSizeWidget _buildAppBar(String currentDate) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      title: _AppBarTitle(currentDate: currentDate),
      toolbarHeight: 70,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF009688)),
          onPressed: () => _handleLogout(context),
        ),
      ],
    );
  }

  /// Gestisce il logout dell'utente
  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout(context);
    
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }
}

/// Widget per il titolo dell'AppBar
class _AppBarTitle extends StatelessWidget {
  final String currentDate;
  
  const _AppBarTitle({required this.currentDate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.inventory_2, color: Color(0xFF009688), size: 28),
        const SizedBox(width: 10),
        const Text(
          'Invory',
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

/// Contenuto principale della HomePage
class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    final scrollPhysics = _getScrollPhysics(context);

    return RefreshIndicator(
      onRefresh: () => _handleRefresh(context),
      child: SingleChildScrollView(
        physics: scrollPhysics,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kIsWeb) const AutoInstallPrompt(),
            const SizedBox(height: 16),
            _buildStatisticsCards(),
            const SizedBox(height: 24),
            _buildCriticalProductsSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// Determina la fisica di scroll in base alla piattaforma
  ScrollPhysics _getScrollPhysics(BuildContext context) {
    return Theme.of(context).platform == TargetPlatform.iOS
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
  }

  /// Gestisce il refresh della pagina
  Future<void> _handleRefresh(BuildContext context) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.reloadProducts();
    await productProvider.checkAndShowNotifications();
  }

  /// Costruisce le card statistiche
  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildLowStockCard(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildOutOfStockCard(),
        ),
      ],
    );
  }

  /// Card per prodotti sotto soglia
  Widget _buildLowStockCard() {
    return Selector<ProductProvider, int>(
      selector: (_, provider) => provider.prodotti
          .where((p) => p.quantita < p.soglia && p.quantita > 0)
          .length,
      builder: (_, value, __) => InfoBox(
        title: 'Sotto soglia',
        value: value,
        gradientColors: const [
          Color(0xFFFFE16D),
          Color(0xFFFFD54F),
        ],
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
      ),
    );
  }

  /// Card per prodotti esauriti
  Widget _buildOutOfStockCard() {
    return Selector<ProductProvider, int>(
      selector: (_, provider) => provider.prodotti
          .where((p) => p.quantita == 0)
          .length,
      builder: (_, value, __) => InfoBox(
        title: 'Esauriti',
        value: value,
        gradientColors: const [
          Color(0xFFFF8A80),
          Color(0xFFFF5252),
        ],
        icon: Icons.error,
        iconColor: Colors.red,
      ),
    );
  }

  /// Sezione prodotti critici
  Widget _buildCriticalProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prodotti da ordinare',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        _buildCriticalProductsList(),
      ],
    );
  }

  /// Lista prodotti critici
  Widget _buildCriticalProductsList() {
    return Selector<ProductProvider, List<Product>>(
      selector: (_, provider) => provider.prodotti
          .where((p) => p.quantita == 0 || p.quantita < p.soglia)
          .toList(),
      builder: (_, criticalProducts, __) {
        if (criticalProducts.isEmpty) {
          return const _EmptyState();
        }
        return _CriticalProductsList(criticalProducts: criticalProducts);
      },
    );
  }
}

/// Lista dei prodotti critici
class _CriticalProductsList extends StatelessWidget {
  final List<Product> criticalProducts;
  
  const _CriticalProductsList({required this.criticalProducts});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: criticalProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = criticalProducts[index];
        return ProductCard(
          nome: product.nome,
          quantita: product.quantita,
          soglia: product.soglia,
          suggerita: -1, // Visualizza solo nome e stato
          showEditDelete: false,
        );
      },
    );
  }
}

/// Stato vuoto quando non ci sono prodotti critici
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Nessun prodotto critico',
          style: TextStyle(color: Color(0xFF757575), fontSize: 16),
        ),
      ),
    );
  }
}
