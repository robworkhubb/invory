import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../widgets/floating_navbar.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(milliseconds: 4400), () {});

    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      print('🔍 Controllo autenticazione utente...');
      print('   - isAuthenticated: ${authProvider.isAuthenticated}');
      print('   - currentUser: ${authProvider.currentUser?.email ?? 'null'}');

      if (authProvider.isAuthenticated) {
        print('✅ Utente autenticato, navigando alla home...');
        // Utente già autenticato, vai alla home
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    FloatingBottomNavBar(),
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
      } else {
        print('❌ Utente non autenticato, navigando al login...');
        // Utente non autenticato, vai al login
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const LoginPage(),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('animations/splash.json', repeat: false),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
