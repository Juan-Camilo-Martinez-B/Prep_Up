import 'package:prep_up/features/auth/domain/auth_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth de prueba. [signInError] es lo que verá la pantalla de login.
class ScriptedAuthGateway implements AuthGateway {
  ScriptedAuthGateway({this.signInError});

  Object? signInError;
  int signInCalls = 0;
  String? lastEmail;

  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastEmail = email;
    final error = signInError;
    if (error != null) throw error;
    throw StateError('esta prueba no inicia sesión');
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
    String? emailRedirectTo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<bool> isEmailRegistered(String email) async => false;

  @override
  Future<AuthResponse> verifyEmailOTP({
    required String email,
    required String token,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponse> verifyRecoveryOTP({
    required String email,
    required String token,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) {
    throw UnimplementedError();
  }
}
