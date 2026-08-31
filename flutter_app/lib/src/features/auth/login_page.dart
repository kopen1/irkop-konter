import 'package:flutter/material.dart';

import '../../core/auth/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthRepository();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email=_email.text.trim();
    final password=_password.text;
    if(!email.contains('@')){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Masukkan email yang valid.')));return;}
    if(password.length<6){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Password minimal 6 karakter.')));return;}
    setState(() => _loading = true);
    try {
      if (_register) {
        await _auth.signUpWithEmail(
          email: email,
          password: password,
        );
      } else {
        await _auth.signInWithEmail(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (mounted && _register) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun dibuat. Cek email jika konfirmasi diaktifkan.')),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login gagal. Periksa data Anda.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.storefront, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        _register ? 'Daftar IRKOP Konter' : 'Masuk IRKOP Konter',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: Text(_loading
                            ? 'Memproses...'
                            : _register
                                ? 'Daftar'
                                : 'Masuk'),
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() => _register = !_register),
                        child: Text(
                          _register
                              ? 'Sudah punya akun? Masuk'
                              : 'Belum punya akun? Daftar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
