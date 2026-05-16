import 'package:flutter/foundation.dart';
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
        try {
          final newUser = UserModel(
            id: response.user!.id,
            email: email,
            displayName: metadata['full_name'] ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          // Intentar crear el perfil, pero no fallar si no hay permisos aún
          await _dbService.upsertUser(newUser);
        } catch (e) {
          // Loggear el error pero no interrumpir el flujo de registro
          debugPrint('Info: No se pudo crear el perfil inicial (esperado si requiere verificación): $e');
        }
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
        // Asegurar que el perfil existe en la tabla users al iniciar sesión
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
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      return response != null;
    } catch (e) {
      // Si hay error (ej. tabla no accesible), asumimos que no existe
      return false;
    }
  }

  /// Verificar código OTP enviado al correo
  Future<AuthResponse> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();

    try {
      // Intentar primero con tipo signup
      final response = await _supabase.auth.verifyOTP(
        email: cleanEmail,
        token: cleanToken,
        type: OtpType.signup,
      );

      if (response.user != null) {
        final existing = await _dbService.getUserById(response.user!.id);
        if (existing == null) {
          final newUser = UserModel(
            id: response.user!.id,
            email: cleanEmail,
            displayName: response.user!.userMetadata?['full_name'] ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _dbService.upsertUser(newUser);
        }
      }

      return response;
    } on AuthException {
      // Si falla como signup, intentamos como email por robustez
      try {
        final retryResponse = await _supabase.auth.verifyOTP(
          email: cleanEmail,
          token: cleanToken,
          type: OtpType.email,
        );
        return retryResponse;
      } catch (_) {
        rethrow; 
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Verificar código OTP para recuperación de contraseña
  Future<AuthResponse> verifyRecoveryOTP({
    required String email,
    required String token,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanToken = token.trim();

    try {
      final response = await _supabase.auth.verifyOTP(
        email: cleanEmail,
        token: cleanToken,
        type: OtpType.recovery,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Actualizar contraseña del usuario actual
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
