import 'package:flutter/material.dart';
import 'package:invory/presentation/widgets/floating_navbar.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isFormValid = false;

  late AnimationController _logoAnimationController;
  late AnimationController _formAnimationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupListeners();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  /// Configura le animazioni
  void _setupAnimations() {
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _startAnimations();
  }

  /// Avvia le animazioni
  void _startAnimations() {
    _logoAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _formAnimationController.forward();
    });
  }

  /// Configura i listener per la validazione del form
  void _setupListeners() {
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  /// Valida il form in tempo reale
  void _validateForm() {
    final isValid = _isFormValidInput();

    if (isValid != _isFormValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  /// Verifica se l'input del form è valido
  bool _isFormValidInput() {
    return _emailController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _emailController.text.contains('@');
  }

  /// Pulisce i controller
  void _disposeControllers() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _logoAnimationController.dispose();
    _formAnimationController.dispose();
  }

  /// Gestisce il login
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _performLogin();
      if (mounted) {
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Esegue il login
  Future<void> _performLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  /// Naviga alla home page
  void _navigateToHome() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.reloadUserData(context);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const FloatingBottomNavBar(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  /// Mostra un messaggio di errore
  void _showErrorSnackBar(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage.replaceAll('Exception: ', '')),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      body: Container(
        decoration: BoxDecoration(color: Colors.teal.shade50),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildAnimatedLogo(),
                  const SizedBox(height: 60),
                  _buildAnimatedForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Logo e titolo animati
  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoAnimation.value,
          child: Column(
            children: [
              _buildLogoContainer(),
              const SizedBox(height: 24),
              _buildAppTitle(),
              const SizedBox(height: 8),
              _buildAppSubtitle(),
            ],
          ),
        );
      },
    );
  }

  /// Container del logo
  Widget _buildLogoContainer() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.inventory_2,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  /// Titolo dell'app
  Widget _buildAppTitle() {
    return Text(
      'Invory',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.teal.shade700,
        fontFamily: 'Poppins',
      ),
    );
  }

  /// Sottotitolo dell'app
  Widget _buildAppSubtitle() {
    return Text(
      'Organizza, Controlla, Rifornisci',
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey.shade600,
        fontFamily: 'Poppins',
      ),
    );
  }

  /// Form animato
  Widget _buildAnimatedForm() {
    return AnimatedBuilder(
      animation: _formAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _formAnimation.value)),
          child: Opacity(
            opacity: _formAnimation.value.clamp(0.0, 1.0),
            child: Column(
              children: [
                _buildEmailField(),
                const SizedBox(height: 20),
                _buildPasswordField(),
                const SizedBox(height: 40),
                _buildLoginButton(),
                const SizedBox(height: 24),
                _buildHelpText(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Campo email
  Widget _buildEmailField() {
    return _buildTextField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      label: 'Email',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: _validateEmail,
      onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
    );
  }

  /// Campo password
  Widget _buildPasswordField() {
    return _buildTextField(
      controller: _passwordController,
      focusNode: _passwordFocusNode,
      label: 'Password',
      icon: Icons.lock_outline,
      isPassword: true,
      validator: _validatePassword,
      onFieldSubmitted: (_) => _handleLogin(),
    );
  }

  /// Bottone di login
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isFormValid && !_isLoading ? _handleLogin : null,
        style: _getLoginButtonStyle(),
        child: _isLoading ? _buildLoadingIndicator() : _buildLoginText(),
      ),
    );
  }

  /// Stile del bottone di login
  ButtonStyle _getLoginButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.teal,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      elevation: _isFormValid ? 8 : 0,
      shadowColor: Colors.teal.withValues(alpha: 0.3),
    );
  }

  /// Indicatore di caricamento
  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  /// Testo del bottone di login
  Widget _buildLoginText() {
    return const Text(
      'ACCEDI',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
    );
  }

  /// Testo di aiuto
  Widget _buildHelpText() {
    return Text(
      'Inserisci le tue credenziali per accedere',
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade600,
        fontFamily: 'Poppins',
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Validatore per l'email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci la tua email';
    }
    if (!value.contains('@')) {
      return 'Inserisci un\'email valida';
    }
    return null;
  }

  /// Validatore per la password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci la password';
    }
    if (value.length < 6) {
      return 'La password deve essere di almeno 6 caratteri';
    }
    return null;
  }

  /// Costruisce un campo di testo
  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: isPassword && !_isPasswordVisible,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 16),
      decoration: _buildTextFieldDecoration(
        label: label,
        icon: icon,
        isPassword: isPassword,
        focusNode: focusNode,
      ),
    );
  }

  /// Costruisce la decorazione del campo di testo
  InputDecoration _buildTextFieldDecoration({
    required String label,
    required IconData icon,
    required bool isPassword,
    required FocusNode focusNode,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: focusNode.hasFocus ? Colors.teal : Colors.grey.shade600,
      ),
      suffixIcon: isPassword ? _buildPasswordVisibilityToggle() : null,
      filled: true,
      fillColor: Colors.white,
      border: _buildTextFieldBorder(Colors.grey.shade300),
      enabledBorder: _buildTextFieldBorder(Colors.grey.shade300),
      focusedBorder: _buildTextFieldBorder(Colors.teal, width: 2),
      errorBorder: _buildTextFieldBorder(Colors.red.shade400),
      focusedErrorBorder: _buildTextFieldBorder(Colors.red.shade400, width: 2),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      labelStyle: TextStyle(
        color: focusNode.hasFocus ? Colors.teal : Colors.grey.shade600,
        fontFamily: 'Poppins',
      ),
    );
  }

  /// Costruisce il bordo del campo di testo
  OutlineInputBorder _buildTextFieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Toggle per la visibilità della password
  Widget _buildPasswordVisibilityToggle() {
    return IconButton(
      icon: Icon(
        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
        color: Colors.grey.shade600,
      ),
      onPressed: () {
        setState(() {
          _isPasswordVisible = !_isPasswordVisible;
        });
      },
    );
  }
}
