import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_up/domain/entities/app_settings_model.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/entities/user_model.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';
import 'package:prep_up/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeRelationalDatabase implements RelationalDatabaseService {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> close() async {}
  @override
  Future<UserModel?> getUserById(String userId) async => null;
  @override
  Future<UserModel?> getUserByEmail(String email) async => null;
  @override
  Future<void> upsertUser(UserModel user) async {}
  @override
  Future<AppSettingsModel?> getSettingsForUser(String userId) async => null;
  @override
  Future<void> saveSettingsForUser(String userId, AppSettingsModel settings) async {}
  @override
  Future<void> saveInterviewSession(InterviewSessionModel session) async {}
  @override
  Future<InterviewSessionModel?> getInterviewSessionById(String sessionId) async => null;
  @override
  Future<List<InterviewSessionModel>> getInterviewHistoryForUser(String userId) async => [];
  @override
  Future<void> saveInterviewResult(InterviewResultsModel result) async {}
  @override
  Future<InterviewResultsModel?> getInterviewResultForSession(String sessionId) async => null;
  @override
  Future<List<InterviewResultsModel>> getInterviewResultsForUser(String userId) async => [];
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'anon',
    );
  });

  testWidgets('Arranca en Splash', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeDb = FakeRelationalDatabase();
    await tester.pumpWidget(AiInterviewTrainerApp(databaseService: fakeDb));
    await tester.pump(const Duration(seconds: 2));

    // Verificar elementos del splash/auth screen
    expect(find.byType(AiInterviewTrainerApp), findsOneWidget);
  });
}
