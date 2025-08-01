// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../presentation/screens/dashboard_page.dart';
import '../../presentation/screens/home_page.dart';
import '../../presentation/screens/ordinerapido.dart';
import '../../presentation/screens/prodotti_page.dart';

class FloatingBottomNavBar extends StatefulWidget {
  @override
  _FloatingBottomNavBarState createState() => _FloatingBottomNavBarState();
}

class _FloatingBottomNavBarState extends State<FloatingBottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: HomePage()),
    Center(child: DashboardPage()),
    Center(child: ProdottiPage()),
    Center(child: OrdineRapidoPage()),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      Icons.home_outlined,
      Icons.analytics_outlined,
      Icons.warehouse_outlined,
      Icons.send_outlined,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Container(
              key: ValueKey<int>(_selectedIndex),
              child: _pages[_selectedIndex],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              bottom: true,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(items.length, (index) {
                    final isSelected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () => _onItemTapped(index),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration:
                            isSelected
                                ? BoxDecoration(
                                  color: Colors.teal.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                )
                                : null,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              items[index],
                              color: isSelected ? Colors.teal : Colors.grey,
                              size: 26,
                            ),
                            if (isSelected)
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(top: 4),
                                height: 5,
                                width: 25,
                                decoration: BoxDecoration(
                                  color: Colors.teal,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
