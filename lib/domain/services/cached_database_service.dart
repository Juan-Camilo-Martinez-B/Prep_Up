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
  })  : _remote = remote,
        _local = local;

  final RelationalDatabaseService _remote;
  final RelationalDatabaseService _local;

  @override
  Future<void> initialize() async {
    await Future.wait([
      _remote.initialize(),
      _local.initialize(),
    ]);
  }

  @override
  Future<void> close() async {
    await Future.wait([
      _remote.close(),
      _local.close(),
    ]);
  }

  // --- Métodos de Usuario ---

  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      final remoteUser = await _remote.getUserById(userId);
      if (remoteUser != null) {
        await _local.upsertUser(remoteUser);
        return remoteUser;
      }
    } catch (e) {
      debugPrint('Error fetching user from remote: $e');
    }
    return _local.getUserById(userId);
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final remoteUser = await _remote.getUserByEmail(email);
      if (remoteUser != null) {
        await _local.upsertUser(remoteUser);
        return remoteUser;
      }
    } catch (e) {
      debugPrint('Error fetching user by email from remote: $e');
    }
    return _local.getUserByEmail(email);
  }

  @override
  Future<void> upsertUser(UserModel user) async {
    // Intentar guardar en ambos, priorizando local para rapidez
    await _local.upsertUser(user);
    try {
      await _remote.upsertUser(user);
    } catch (e) {
      debugPrint('Error upserting user to remote: $e');
      // Podríamos marcar para sincronización futura
    }
  }

  // --- Métodos de Configuración ---

  @override
  Future<AppSettingsModel?> getSettingsForUser(String userId) async {
    try {
      final remoteSettings = await _remote.getSettingsForUser(userId);
      if (remoteSettings != null) {
        await _local.saveSettingsForUser(userId, remoteSettings);
        return remoteSettings;
      }
    } catch (e) {
      debugPrint('Error fetching settings from remote: $e');
    }
    return _local.getSettingsForUser(userId);
  }

  @override
  Future<void> saveSettingsForUser(String userId, AppSettingsModel settings) async {
    await _local.saveSettingsForUser(userId, settings);
    try {
      await _remote.saveSettingsForUser(userId, settings);
    } catch (e) {
      debugPrint('Error saving settings to remote: $e');
    }
  }

  // --- Métodos de Sesiones de Entrevista ---

  @override
  Future<void> saveInterviewSession(InterviewSessionModel session) async {
    await _local.saveInterviewSession(session);
    try {
      await _remote.saveInterviewSession(session);
    } catch (e) {
      debugPrint('Error saving session to remote: $e');
    }
  }

  @override
  Future<InterviewSessionModel?> getInterviewSessionById(String sessionId) async {
    try {
      final remoteSession = await _remote.getInterviewSessionById(sessionId);
      if (remoteSession != null) {
        await _local.saveInterviewSession(remoteSession);
        return remoteSession;
      }
    } catch (e) {
      debugPrint('Error fetching session from remote: $e');
    }
    return _local.getInterviewSessionById(sessionId);
  }

  @override
  Future<List<InterviewSessionModel>> getInterviewHistoryForUser(String userId) async {
    // Para el historial, devolvemos lo local inmediatamente si existe
    // y actualizamos desde el remoto en segundo plano o si no hay nada local
    List<InterviewSessionModel> localHistory = await _local.getInterviewHistoryForUser(userId);
    
    try {
      final remoteHistory = await _remote.getInterviewHistoryForUser(userId);
      // Actualizar caché local con datos frescos
      for (final session in remoteHistory) {
        await _local.saveInterviewSession(session);
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
    await _local.saveInterviewResult(result);
    try {
      await _remote.saveInterviewResult(result);
    } catch (e) {
      debugPrint('Error saving result to remote: $e');
    }
  }

  @override
  Future<InterviewResultsModel?> getInterviewResultForSession(String sessionId) async {
    try {
      final remoteResult = await _remote.getInterviewResultForSession(sessionId);
      if (remoteResult != null) {
        await _local.saveInterviewResult(remoteResult);
        return remoteResult;
      }
    } catch (e) {
      debugPrint('Error fetching result from remote: $e');
    }
    return _local.getInterviewResultForSession(sessionId);
  }

  @override
  Future<List<InterviewResultsModel>> getInterviewResultsForUser(String userId) async {
    List<InterviewResultsModel> localResults = await _local.getInterviewResultsForUser(userId);

    try {
      final remoteResults = await _remote.getInterviewResultsForUser(userId);
      for (final result in remoteResults) {
        await _local.saveInterviewResult(result);
      }
      return remoteResults;
    } catch (e) {
      debugPrint('Error fetching results from remote: $e');
      return localResults;
    }
  }
}
