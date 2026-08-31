import 'package:flutter/material.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/config/env.dart';
import '../../core/data/business_context_repository.dart';
import '../home/home_page.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Env.isSupabaseConfigured) {
      return const HomePage(demoMode: true);
    }

    final auth = AuthRepository();
    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            auth.currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !auth.isAuthenticated) {
          return const LoginPage();
        }

        return _BusinessBootstrap(userId: auth.currentUser!.id);
      },
    );
  }
}

class _BusinessBootstrap extends StatefulWidget {
  const _BusinessBootstrap({required this.userId});

  final String userId;

  @override
  State<_BusinessBootstrap> createState() => _BusinessBootstrapState();
}

class _BusinessBootstrapState extends State<_BusinessBootstrap> {
  final _repository = BusinessContextRepository();
  late Future<BusinessContext> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _repository
        .ensureForCurrentUser()
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw StateError(
            'Koneksi ke database terlalu lama. Periksa jaringan lalu coba lagi.',
          ),
        );
  }

  void _retry() {
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BusinessContext>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 40),
                      const SizedBox(height: 16),
                      const Text(
                        'Gagal menyiapkan bisnis',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final businessContext = snapshot.data;
        if (businessContext == null) {
          return Scaffold(
            body: Center(
              child: FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Muat ulang'),
              ),
            ),
          );
        }

        return HomePage(
          demoMode: false,
          businessContext: businessContext,
        );
      },
    );
  }
}
