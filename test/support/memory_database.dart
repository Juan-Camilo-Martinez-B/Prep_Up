import 'package:prep_up/shared/domain/entities/app_settings_model.dart';
import 'package:prep_up/shared/domain/entities/interview_results_model.dart';
import 'package:prep_up/shared/domain/entities/interview_session_model.dart';
import 'package:prep_up/shared/domain/entities/user_model.dart';
import 'package:prep_up/shared/domain/ports/relational_database_service.dart';

/// Base en memoria. [failReads] y [failWrites] simulan que Supabase no responde.
class MemoryDatabase implements RelationalDatabaseService {
  final Map<String, UserModel> usersById = {};
  final Map<String, AppSettingsModel> settingsByUser = {};
  final Map<String, InterviewSessionModel> sessionsById = {};
  final Map<String, InterviewResultsModel> resultsBySession = {};

  var failReads = false;
  var failWrites = false;
  var readCalls = 0;
  var writeCalls = 0;

  void _read() {
    readCalls++;
    if (failReads) throw StateError('lectura remota no disponible');
  }

  void _write() {
    writeCalls++;
    if (failWrites) throw StateError('escritura remota no disponible');
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> close() async {}

  @override
  Future<UserModel?> getUserById(String userId) async {
    _read();
    return usersById[userId];
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    _read();
    for (final user in usersById.values) {
      if (user.email == email) return user;
    }
    return null;
  }

  @override
  Future<void> upsertUser(UserModel user) async {
    _write();
    usersById[user.id] = user;
  }

  @override
  Future<AppSettingsModel?> getSettingsForUser(String userId) async {
    _read();
    return settingsByUser[userId];
  }

  @override
  Future<void> saveSettingsForUser(
    String userId,
    AppSettingsModel settings,
  ) async {
    _write();
    settingsByUser[userId] = settings;
  }

  @override
  Future<void> saveInterviewSession(InterviewSessionModel session) async {
    _write();
    sessionsById[session.id] = session;
  }

  @override
  Future<InterviewSessionModel?> getInterviewSessionById(
    String sessionId,
  ) async {
    _read();
    return sessionsById[sessionId];
  }

  @override
  Future<List<InterviewSessionModel>> getInterviewHistoryForUser(
    String userId,
  ) async {
    _read();
    return [
      for (final session in sessionsById.values)
        if (session.userId == userId) session,
    ];
  }

  @override
  Future<void> saveInterviewResult(InterviewResultsModel result) async {
    _write();
    resultsBySession[result.sessionId] = result;
  }

  @override
  Future<InterviewResultsModel?> getInterviewResultForSession(
    String sessionId,
  ) async {
    _read();
    return resultsBySession[sessionId];
  }

  @override
  Future<List<InterviewResultsModel>> getInterviewResultsForUser(
    String userId,
  ) async {
    _read();
    return [
      for (final result in resultsBySession.values)
        if (result.userId == userId) result,
    ];
  }
}
