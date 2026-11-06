import 'package:supabase_flutter/supabase_flutter.dart';

/// Puerto de autenticación. Las pantallas dependen de este contrato;
/// Supabase queda en el adapter.
abstract class AuthGateway {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
    String? emailRedirectTo,
  });

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> resetPassword(String email);

  User? get currentUser;

  Stream<AuthState> get authStateChanges;

  Future<bool> isEmailRegistered(String email);

  Future<AuthResponse> verifyEmailOTP({
    required String email,
    required String token,
  });

  Future<AuthResponse> verifyRecoveryOTP({
    required String email,
    required String token,
  });

  Future<UserResponse> updatePassword(String newPassword);
}
