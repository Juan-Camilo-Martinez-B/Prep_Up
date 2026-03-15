import 'package:prep_up/models/app_settings_model.dart';
import 'package:prep_up/models/interview_result_model.dart';
import 'package:prep_up/models/interview_session_model.dart';
import 'package:prep_up/models/user_model.dart';

abstract class RelationalDatabaseService {
  Future<void> initialize();
  Future<void> close();

  Future<UserModel?> getUserById(String userId);
  Future<UserModel?> getUserByEmail(String email);
  Future<void> upsertUser(UserModel user);

  Future<AppSettingsModel?> getSettingsForUser(String userId);
  Future<void> saveSettingsForUser(String userId, AppSettingsModel settings);

  Future<void> saveInterviewSession(InterviewSessionModel session);
  Future<InterviewSessionModel?> getInterviewSessionById(String sessionId);
  Future<List<InterviewSessionModel>> getInterviewHistoryForUser(String userId);

  Future<void> saveInterviewResult(InterviewResultModel result);
  Future<InterviewResultModel?> getInterviewResultForSession(String sessionId);

  // TODO: implementar repositorios y persistencia real usando una BD relacional.
}

class InMemoryRelationalDatabaseService implements RelationalDatabaseService {
  final Map<String, UserModel> _usersById = {};
  final Map<String, String> _userIdByEmail = {};
  final Map<String, AppSettingsModel> _settingsByUserId = {};
  final Map<String, InterviewSessionModel> _sessionsById = {};
  final Map<String, List<String>> _sessionIdsByUserId = {};
  final Map<String, InterviewResultModel> _resultsBySessionId = {};

  var _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<void> close() async {
    _initialized = false;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('RelationalDatabaseService no inicializado');
    }
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    _ensureInitialized();
    return _usersById[userId];
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    _ensureInitialized();
    final userId = _userIdByEmail[email.toLowerCase()];
    if (userId == null) return null;
    return _usersById[userId];
  }

  @override
  Future<void> upsertUser(UserModel user) async {
    _ensureInitialized();
    _usersById[user.id] = user;
    _userIdByEmail[user.email.toLowerCase()] = user.id;
  }

  @override
  Future<AppSettingsModel?> getSettingsForUser(String userId) async {
    _ensureInitialized();
    return _settingsByUserId[userId];
  }

  @override
  Future<void> saveSettingsForUser(
    String userId,
    AppSettingsModel settings,
  ) async {
    _ensureInitialized();
    _settingsByUserId[userId] = settings;
  }

  @override
  Future<void> saveInterviewSession(InterviewSessionModel session) async {
    _ensureInitialized();
    _sessionsById[session.id] = session;
    final list = _sessionIdsByUserId.putIfAbsent(session.userId, () => []);
    if (!list.contains(session.id)) {
      list.add(session.id);
    }
  }

  @override
  Future<InterviewSessionModel?> getInterviewSessionById(String sessionId) async {
    _ensureInitialized();
    return _sessionsById[sessionId];
  }

  @override
  Future<List<InterviewSessionModel>> getInterviewHistoryForUser(
    String userId,
  ) async {
    _ensureInitialized();
    final sessionIds = _sessionIdsByUserId[userId] ?? const <String>[];
    return sessionIds
        .map((id) => _sessionsById[id])
        .whereType<InterviewSessionModel>()
        .toList();
  }

  @override
  Future<void> saveInterviewResult(InterviewResultModel result) async {
    _ensureInitialized();
    _resultsBySessionId[result.sessionId] = result;
  }

  @override
  Future<InterviewResultModel?> getInterviewResultForSession(
    String sessionId,
  ) async {
    _ensureInitialized();
    return _resultsBySessionId[sessionId];
  }
}
