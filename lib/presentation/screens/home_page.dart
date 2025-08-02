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
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Inizializza notifiche e salva il token FCM se necessario
    NotificationService().initialize().then((_) {
      NotificationService().savePendingToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dataOggi = DateFormat('d MMMM yyyy', 'it_IT').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: _AppBarTitle(dataOggi: dataOggi),
        toolbarHeight: 70,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF009688)),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              await authProvider.logout(context);
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            const LoginPage(),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: const _HomePageContent(),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  final String dataOggi;
  const _AppBarTitle({required this.dataOggi});

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

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    final scrollPhysics =
        Theme.of(context).platform == TargetPlatform.iOS
            ? const BouncingScrollPhysics()
            : const ClampingScrollPhysics();

    return RefreshIndicator(
      onRefresh: () async {
        final productProvider = Provider.of<ProductProvider>(
          context,
          listen: false,
        );
        productProvider.reloadProducts();
        await productProvider.checkAndShowNotifications();
      },
      child: SingleChildScrollView(
        physics: scrollPhysics,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner automatico per installazione PWA (solo web)
            if (kIsWeb) const AutoInstallPrompt(),

            Row(
              children: [
                Expanded(
                  child: Selector<ProductProvider, int>(
                    selector:
                        (_, provider) =>
                            provider.prodotti
                                .where(
                                  (p) =>
                                      p.quantita < p.soglia && p.quantita > 0,
                                )
                                .length,
                    builder:
                        (_, value, __) => InfoBox(
                          title: 'Sotto soglia',
                          value: value,
                          gradientColors: const [
                            Color(0xFFFFE16D),
                            Color(0xFFFFD54F),
                          ],
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.orange,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Selector<ProductProvider, int>(
                    selector:
                        (_, provider) =>
                            provider.prodotti
                                .where((p) => p.quantita == 0)
                                .length,
                    builder:
                        (_, value, __) => InfoBox(
                          title: 'Esauriti',
                          value: value,
                          gradientColors: const [
                            Color(0xFFFF8A80),
                            Color(0xFFFF5252),
                          ],
                          icon: Icons.error,
                          iconColor: Colors.red,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Prodotti da ordinare',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 8),
            Selector<ProductProvider, List<Product>>(
              selector:
                  (_, provider) =>
                      provider.prodotti
                          .where(
                            (p) => p.quantita == 0 || p.quantita < p.soglia,
                          )
                          .toList(),
              builder: (_, critici, __) {
                if (critici.isEmpty) {
                  return const _EmptyState();
                }
                return _CriticalProductsList(critici: critici);
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _CriticalProductsList extends StatelessWidget {
  final List<Product> critici;
  const _CriticalProductsList({required this.critici});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: critici.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final prodotto = critici[index];
        return ProductCard(
          nome: prodotto.nome,
          quantita: prodotto.quantita,
          soglia: prodotto.soglia,
          suggerita: -1, // visualizza solo nome e stato
          showEditDelete: false,
        );
      },
    );
  }
}

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
            color: Colors.black.withOpacity(0.04),
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
