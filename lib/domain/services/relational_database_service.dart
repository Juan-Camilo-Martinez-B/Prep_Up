import 'package:prep_up/domain/entities/app_settings_model.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/entities/user_model.dart';

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

  Future<void> saveInterviewResult(InterviewResultsModel result);
  Future<InterviewResultsModel?> getInterviewResultForSession(String sessionId);
}
