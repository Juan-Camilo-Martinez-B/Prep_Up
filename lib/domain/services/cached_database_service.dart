import 'package:flutter/foundation.dart';
import 'package:prep_up/domain/entities/app_settings_model.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/entities/user_model.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';

/// Un servicio que actúa como decorador para manejar la lógica de caché entre
/// una base de datos remota (Supabase) y una local (SQLite).
class CachedDatabaseService implements RelationalDatabaseService {
  CachedDatabaseService({
    required RelationalDatabaseService remote,
    required RelationalDatabaseService local,
  })  : remote = remote,
        local = local;

  final RelationalDatabaseService remote;
  final RelationalDatabaseService local;

  @override
  Future<void> initialize() async {
    await Future.wait([
      remote.initialize(),
      local.initialize(),
    ]);
  }

  @override
  Future<void> close() async {
    await Future.wait([
      remote.close(),
      local.close(),
    ]);
  }

  // --- Métodos de Usuario ---

  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      final remoteUser = await remote.getUserById(userId);
      if (remoteUser != null) {
        await local.upsertUser(remoteUser);
        return remoteUser;
      }
    } catch (e) {
      debugPrint('Error fetching user from remote: $e');
    }
    return local.getUserById(userId);
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final remoteUser = await remote.getUserByEmail(email);
      if (remoteUser != null) {
        await local.upsertUser(remoteUser);
        return remoteUser;
      }
    } catch (e) {
      debugPrint('Error fetching user by email from remote: $e');
    }
    return local.getUserByEmail(email);
  }

  @override
  Future<void> upsertUser(UserModel user) async {
    // Intentar guardar en ambos, priorizando local para rapidez
    await local.upsertUser(user);
    try {
      await remote.upsertUser(user);
    } catch (e) {
      debugPrint('Error upserting user to remote: $e');
      // Podríamos marcar para sincronización futura
    }
  }

  // --- Métodos de Configuración ---

  @override
  Future<AppSettingsModel?> getSettingsForUser(String userId) async {
    try {
      final remoteSettings = await remote.getSettingsForUser(userId);
      if (remoteSettings != null) {
        await local.saveSettingsForUser(userId, remoteSettings);
        return remoteSettings;
      }
    } catch (e) {
      debugPrint('Error fetching settings from remote: $e');
    }
    return local.getSettingsForUser(userId);
  }

  @override
  Future<void> saveSettingsForUser(String userId, AppSettingsModel settings) async {
    await local.saveSettingsForUser(userId, settings);
    try {
      await remote.saveSettingsForUser(userId, settings);
    } catch (e) {
      debugPrint('Error saving settings to remote: $e');
    }
  }

  // --- Métodos de Sesiones de Entrevista ---

  @override
  Future<void> saveInterviewSession(InterviewSessionModel session) async {
    await local.saveInterviewSession(session);
    try {
      await remote.saveInterviewSession(session);
    } catch (e) {
      debugPrint('Error saving session to remote: $e');
    }
  }

  @override
  Future<InterviewSessionModel?> getInterviewSessionById(String sessionId) async {
    try {
      final remoteSession = await remote.getInterviewSessionById(sessionId);
      if (remoteSession != null) {
        await local.saveInterviewSession(remoteSession);
        return remoteSession;
      }
    } catch (e) {
      debugPrint('Error fetching session from remote: $e');
    }
    return local.getInterviewSessionById(sessionId);
  }

  @override
  Future<List<InterviewSessionModel>> getInterviewHistoryForUser(String userId) async {
    // Para el historial, devolvemos lo local inmediatamente si existe
    // y actualizamos desde el remoto en segundo plano o si no hay nada local
    List<InterviewSessionModel> localHistory = await local.getInterviewHistoryForUser(userId);
    
    try {
      final remoteHistory = await remote.getInterviewHistoryForUser(userId);
      // Actualizar caché local con datos frescos
      for (final session in remoteHistory) {
        await local.saveInterviewSession(session);
      }
      return remoteHistory;
    } catch (e) {
      debugPrint('Error fetching history from remote: $e');
      return localHistory;
    }
  }

  // --- Métodos de Resultados ---

  @override
  Future<void> saveInterviewResult(InterviewResultsModel result) async {
    await local.saveInterviewResult(result);
    try {
      await remote.saveInterviewResult(result);
    } catch (e) {
      debugPrint('Error saving result to remote: $e');
    }
  }

  @override
  Future<InterviewResultsModel?> getInterviewResultForSession(String sessionId) async {
    try {
      final remoteResult = await remote.getInterviewResultForSession(sessionId);
      if (remoteResult != null) {
        await local.saveInterviewResult(remoteResult);
        return remoteResult;
      }
    } catch (e) {
      debugPrint('Error fetching result from remote: $e');
    }
    return local.getInterviewResultForSession(sessionId);
  }

  @override
  Future<List<InterviewResultsModel>> getInterviewResultsForUser(String userId) async {
    List<InterviewResultsModel> localResults = await local.getInterviewResultsForUser(userId);

    try {
      final remoteResults = await remote.getInterviewResultsForUser(userId);
      for (final result in remoteResults) {
        await local.saveInterviewResult(result);
      }
      return remoteResults;
    } catch (e) {
      debugPrint('Error fetching results from remote: $e');
      return localResults;
    }
  }
}
