import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      if (_isLogin) {
        await auth.login(_email.text.trim(), _password.text.trim());
      } else {
        await auth.register(_email.text.trim(), _password.text.trim());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('BuurtLeen', style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(controller: _email,
                decoration: const InputDecoration(labelText: 'E-mail',
                    border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _password, obscureText: true,
                decoration: const InputDecoration(labelText: 'Wachtwoord',
                    border: OutlineInputBorder())),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                    child: Text(_isLogin ? 'Inloggen' : 'Registreren')),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin
                  ? 'Nog geen account? Registreer hier'
                  : 'Al een account? Log in')),
          ],
        ),
      ),
    );
  }
}