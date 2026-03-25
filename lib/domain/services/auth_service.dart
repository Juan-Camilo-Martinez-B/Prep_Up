import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Registro de usuario
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
    String? emailRedirectTo,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
        emailRedirectTo: emailRedirectTo,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Inicio de sesión
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Recuperación de contraseña
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener usuario actual
  User? get currentUser => _supabase.auth.currentUser;

  /// Stream de estado de autenticación
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
