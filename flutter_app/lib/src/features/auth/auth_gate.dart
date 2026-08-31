import 'package:flutter/material.dart';

import '../../core/auth/auth_repository.dart';
import '../../core/config/env.dart';
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

        if (auth.isAuthenticated) {
          return const HomePage(demoMode: false);
        }

        return const LoginPage();
      },
    );
  }
}
