import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

class AuthRepository {
  SupabaseClient? get _client =>
      Env.isSupabaseConfigured ? Supabase.instance.client : null;

  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  User? get currentUser => _client?.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase belum dikonfigurasi.');
    }

    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('Supabase belum dikonfigurasi.');
    }

    await client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      await client.auth.signOut();
    }
  }
}
