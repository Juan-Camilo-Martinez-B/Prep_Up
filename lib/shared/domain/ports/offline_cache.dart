import 'package:prep_up/shared/domain/entities/interview_results_model.dart';
import 'package:prep_up/shared/domain/entities/interview_session_model.dart';
import 'package:prep_up/shared/domain/entities/user_model.dart';

/// Lectura inmediata del almacén local, antes del sincronizado remoto.
abstract class OfflineCache {
  Future<UserModel?> readUser(String userId);

  Future<List<InterviewSessionModel>> readHistory(String userId);

  Future<List<InterviewResultsModel>> readResults(String userId);
}
