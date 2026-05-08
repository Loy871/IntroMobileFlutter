import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError('Vul alle velden in');
      return;
    }
    if (!_isLogin && _name.text.trim().isEmpty) {
      _showError('Vul je naam in');
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (_isLogin) {
        await auth.login(email, password);
      } else {
        await auth.register(email, password);
      }
    } on Exception catch (e) {
      String msg = e.toString();
      if (msg.contains('wrong-password') || msg.contains('invalid-credential'))
        msg = 'Verkeerd e-mail of wachtwoord';
      else if (msg.contains('email-already-in-use'))
        msg = 'Dit e-mailadres is al in gebruik';
      else if (msg.contains('weak-password'))
        msg = 'Wachtwoord moet minstens 6 tekens zijn';
      else if (msg.contains('user-not-found'))
        msg = 'Geen account gevonden met dit e-mailadres';
      _showError(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFB85C38),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2E1A),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            // Achtergrond decoratie
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2D6A4F).withOpacity(0.3),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF52B788).withOpacity(0.15),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 60),
                    // Logo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF52B788),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.handshake_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BuurtLeen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Deel met je buurt',
                              style: TextStyle(
                                color: Color(0xFF52B788),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    // Tab switcher
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1F0D),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _tabButton('Inloggen', _isLogin, () {
                            setState(() => _isLogin = true);
                          }),
                          _tabButton('Registreren', !_isLogin, () {
                            setState(() => _isLogin = false);
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Naam veld (alleen bij registratie)
                    if (!_isLogin) ...[
                      _inputField(
                        controller: _name,
                        hint: 'Volledige naam',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Email
                    _inputField(
                      controller: _email,
                      hint: 'E-mailadres',
                      icon: Icons.mail_outline_rounded,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),

                    // Wachtwoord
                    _inputField(
                      controller: _password,
                      hint: 'Wachtwoord',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF52B788),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit knop
                    GestureDetector(
                      onTap: _loading ? null : _submit,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D6A4F).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _loading
                            ? const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Text(
                                _isLogin ? 'Inloggen' : 'Account aanmaken',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Ondertitel
                    Center(
                      child: Text(
                        _isLogin
                            ? 'Nog geen account? Registreer gratis'
                            : 'Al een account? Log hierboven in',
                        style: const TextStyle(
                          color: Color(0xFF52B788),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2D6A4F) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF52B788),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF0D1F0D),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF2D6A4F).withOpacity(0.4)),
    ),
    child: TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF52B788), size: 20),
        suffixIcon: suffix,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    ),
  );
}
