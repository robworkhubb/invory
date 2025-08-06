// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../presentation/screens/dashboard_page.dart';
import '../../presentation/screens/home_page.dart';
import '../../presentation/screens/ordinerapido.dart';
import '../../presentation/screens/prodotti_page.dart';

class FloatingBottomNavBar extends StatefulWidget {
  const FloatingBottomNavBar({super.key});

  @override
  State<FloatingBottomNavBar> createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar> {
  int _selectedIndex = 0;

  /// Lista delle pagine dell'app
  final List<Widget> _pages = const [
    Center(child: HomePage()),
    Center(child: DashboardPage()),
    Center(child: ProdottiPage()),
    Center(child: OrdineRapidoPage()),
  ];

  /// Icone per la navigazione
  final List<IconData> _navigationIcons = const [
    Icons.home_outlined,
    Icons.analytics_outlined,
    Icons.warehouse_outlined,
    Icons.send_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          _buildPageContent(),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  /// Contenuto delle pagine con animazione
  Widget _buildPageContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey<int>(_selectedIndex),
        child: _pages[_selectedIndex],
      ),
    );
  }

  /// Barra di navigazione inferiore
  Widget _buildBottomNavigationBar() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: SafeArea(
        bottom: true,
        child: Container(
          height: 70,
          decoration: _getNavigationBarDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _buildNavigationItems(),
          ),
        ),
      ),
    );
  }

  /// Decorazione della barra di navigazione
  BoxDecoration _getNavigationBarDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Costruisce gli elementi di navigazione
  List<Widget> _buildNavigationItems() {
    return List.generate(_navigationIcons.length, (index) {
      return _buildNavigationItem(index);
    });
  }

  /// Costruisce un singolo elemento di navigazione
  Widget _buildNavigationItem(int index) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: isSelected ? _getSelectedItemDecoration() : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNavigationIcon(index, isSelected),
            if (isSelected) _buildSelectionIndicator(),
          ],
        ),
      ),
    );
  }

  /// Decorazione per l'elemento selezionato
  BoxDecoration _getSelectedItemDecoration() {
    return BoxDecoration(
      color: Colors.teal.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
    );
  }

  /// Icona di navigazione
  Widget _buildNavigationIcon(int index, bool isSelected) {
    return Icon(
      _navigationIcons[index],
      color: isSelected ? Colors.teal : Colors.grey,
      size: 26,
    );
  }

  /// Indicatore di selezione
  Widget _buildSelectionIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 4),
      height: 5,
      width: 25,
      decoration: BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  /// Gestisce il tap su un elemento di navigazione
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }
}
