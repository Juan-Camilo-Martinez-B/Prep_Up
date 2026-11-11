import 'package:flutter_test/flutter_test.dart';
import 'package:prep_up/shared/domain/entities/app_settings_model.dart';
import 'package:prep_up/shared/domain/entities/interview_results_model.dart';
import 'package:prep_up/shared/domain/entities/interview_session_model.dart';
import 'package:prep_up/shared/domain/entities/interview_tags.dart';
import 'package:prep_up/shared/domain/entities/user_model.dart';
import 'package:prep_up/shared/infrastructure/cached_database_service.dart';

import '../../support/memory_database.dart';

void main() {
  late MemoryDatabase remote;
  late MemoryDatabase local;
  late CachedDatabaseService cache;

  final now = DateTime.utc(2026, 11, 10);
  final user = UserModel(
    id: 'u1',
    email: 'ana@correo.com',
    displayName: 'Ana',
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    remote = MemoryDatabase();
    local = MemoryDatabase();
    cache = CachedDatabaseService(remote: remote, local: local);
  });

  test('una lectura remota se copia en local', () async {
    remote.usersById[user.id] = user;

    final found = await cache.getUserById(user.id);

    expect(found?.email, 'ana@correo.com');
    expect(local.usersById[user.id]?.email, 'ana@correo.com');
  });

  test('si el remoto falla, la lectura vuelve a local', () async {
    local.usersById[user.id] = user;
    remote.failReads = true;

    final found = await cache.getUserById(user.id);

    expect(found?.displayName, 'Ana');
  });

  test('la escritura llega a local aunque el remoto falle', () async {
    remote.failWrites = true;

    await cache.upsertUser(user);

    expect(local.usersById[user.id]?.email, 'ana@correo.com');
    expect(remote.usersById.containsKey(user.id), isFalse);
  });

  test(
    'el historial remoto reemplaza la respuesta y refresca la caché',
    () async {
      final session = _session('s1');
      remote.sessionsById[session.id] = session;

      final history = await cache.getInterviewHistoryForUser('u1');

      expect(history.map((item) => item.id), ['s1']);
      expect(local.sessionsById['s1']?.id, 's1');
    },
  );

  test('si el historial remoto falla, se devuelve el local', () async {
    local.sessionsById['s1'] = _session('s1');
    remote.failReads = true;

    final history = await cache.getInterviewHistoryForUser('u1');

    expect(history, hasLength(1));
  });

  test('OfflineCache lee solo local', () async {
    local.usersById[user.id] = user;
    remote.failReads = true;

    final found = await cache.readUser(user.id);

    expect(found?.id, 'u1');
    expect(remote.readCalls, 0);
  });

  test('los ajustes se guardan primero en local', () async {
    const settings = AppSettingsModel(themeMode: AppThemeMode.dark);
    remote.failWrites = true;

    await cache.saveSettingsForUser('u1', settings);

    expect(local.settingsByUser['u1']?.themeMode, AppThemeMode.dark);
  });

  test('un resultado remoto se copia en local', () async {
    final result = _result();
    remote.resultsBySession[result.sessionId] = result;

    final found = await cache.getInterviewResultForSession(result.sessionId);

    expect(found?.overallScore, 80);
    expect(local.resultsBySession[result.sessionId]?.overallScore, 80);
  });
}

InterviewSessionModel _session(String id) {
  final now = DateTime.utc(2026, 11, 10);
  return InterviewSessionModel(
    id: id,
    userId: 'u1',
    createdAt: now,
    updatedAt: now,
    type: InterviewType.technical,
    jobRole: JobRole.mobileDeveloper,
    status: InterviewSessionStatus.completed,
    questionCount: 4,
    timeLimitSeconds: 600,
  );
}

InterviewResultsModel _result() {
  return InterviewResultsModel(
    id: 'r1',
    sessionId: 's1',
    userId: 'u1',
    analyzedAt: DateTime.utc(2026, 11, 10),
    overallScore: 80,
    outcome: InterviewOutcome.approved,
    breakdown: const InterviewResultsBreakdownModel(
      communication: 70,
      technicalKnowledge: 80,
      confidence: 75,
      subjectMastery: 80,
    ),
    highlights: const ['clara'],
    personalizedFeedback: 'Buen recorrido de la respuesta.',
    recommendations: const ['profundiza un ejemplo'],
    improvementTips: const ['mide el tiempo'],
    averageResponseSeconds: 20,
    totalResponseSeconds: 80,
    validAnswersCount: 4,
  );
}
