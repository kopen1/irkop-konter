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

        if (!auth.isAuthenticated) {
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
    _future = _repository.ensureForCurrentUser();
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
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal menyiapkan bisnis: ${snapshot.error}'),
              ),
            ),
          );
        }

        return HomePage(
          demoMode: false,
          businessContext: snapshot.data,
        );
      },
    );
  }
}
