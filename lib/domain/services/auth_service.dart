import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_up/domain/entities/user_model.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';
import 'package:prep_up/domain/services/supabase_database_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final RelationalDatabaseService _dbService = SupabaseDatabaseService();

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

      if (response.user != null) {
        final newUser = UserModel(
          id: response.user!.id,
          email: email,
          displayName: metadata['full_name'] ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _dbService.upsertUser(newUser);
      }

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

      if (response.user != null) {
        // Asegurar que el perfil existe en la tabla usuarios al iniciar sesión
        final existing = await _dbService.getUserById(response.user!.id);
        if (existing == null) {
          final newUser = UserModel(
            id: response.user!.id,
            email: email,
            displayName: response.user!.userMetadata?['full_name'] ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _dbService.upsertUser(newUser);
        }
      }

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

  /// Verificar si un correo electrónico ya está registrado en la base de datos pública
  Future<bool> isEmailRegistered(String email) async {
    try {
      final response = await _supabase
          .from('usuarios')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      return response != null;
    } catch (e) {
      // Si hay error (ej. tabla no accesible), asumimos que no existe
      return false;
    }
  }
}
