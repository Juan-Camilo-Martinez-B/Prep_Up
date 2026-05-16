import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_up/domain/entities/app_settings_model.dart';
import 'package:prep_up/domain/entities/interview_results_model.dart';
import 'package:prep_up/domain/entities/interview_session_model.dart';
import 'package:prep_up/domain/entities/user_model.dart';
import 'package:prep_up/domain/services/relational_database_service.dart';

class SupabaseDatabaseService implements RelationalDatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<void> initialize() async {
    // Supabase ya se inicializa en el main.dart
  }

  @override
  Future<void> close() async {
    // No es necesario cerrar explícitamente el cliente de Supabase aquí
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('email', email.toLowerCase())
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  @override
  Future<void> upsertUser(UserModel user) async {
    await _supabase.from('users').upsert(user.toJson());
  }

  @override
  Future<AppSettingsModel?> getSettingsForUser(String userId) async {
    final response = await _supabase
        .from('settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    // Mapear campos de la BD al modelo AppSettingsModel
    return AppSettingsModel(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == response['theme_mode'],
        orElse: () => AppThemeMode.system,
      ),
    );
  }

  @override
  Future<void> saveSettingsForUser(
    String userId,
    AppSettingsModel settings,
  ) async {
    await _supabase.from('settings').upsert({
      'user_id': userId,
      'theme_mode': settings.themeMode.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> saveInterviewSession(InterviewSessionModel session) async {
    final data = session.toJson();
    // Ajustar nombres de campos para la BD si es necesario
    final dbData = {
      'id': data['id'],
      'user_id': data['userId'],
      'type': data['type'],
      'job_role': data['jobRole'],
      'status': data['status'],
      'question_count': data['questionCount'],
      'time_limit_seconds': data['timeLimitSeconds'],
      'video_reference': data['videoReference'],
      'turns': data['turns'],
      'created_at': data['createdAt'],
      'updated_at': data['updatedAt'],
    };
    await _supabase.from('interview_sessions').upsert(dbData);
  }

  @override
  Future<InterviewSessionModel?> getInterviewSessionById(
    String sessionId,
  ) async {
    final response = await _supabase
        .from('interview_sessions')
        .select()
        .eq('id', sessionId)
        .maybeSingle();

    if (response == null) return null;

    // Remapear campos de la BD al JSON esperado por InterviewSessionModel.fromJson
    final modelData = {
      'id': response['id'],
      'userId': response['user_id'],
      'type': response['type'],
      'jobRole': response['job_role'],
      'status': response['status'],
      'questionCount': response['question_count'],
      'timeLimitSeconds': response['time_limit_seconds'],
      'videoReference': response['video_reference'],
      'turns': response['turns'],
      'createdAt': response['created_at'],
      'updatedAt': response['updated_at'],
    };
    return InterviewSessionModel.fromJson(modelData);
  }

  @override
  Future<List<InterviewSessionModel>> getInterviewHistoryForUser(
    String userId,
  ) async {
    final response = await _supabase
        .from('interview_sessions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((row) {
      final modelData = {
        'id': row['id'],
        'userId': row['user_id'],
        'type': row['type'],
        'jobRole': row['job_role'],
        'status': row['status'],
        'questionCount': row['question_count'],
        'timeLimitSeconds': row['time_limit_seconds'],
        'videoReference': row['video_reference'],
        'turns': row['turns'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      };
      return InterviewSessionModel.fromJson(modelData);
    }).toList();
  }

  @override
  Future<void> saveInterviewResult(InterviewResultsModel result) async {
    final data = result.toJson();
    final dbData = {
      'id': data['id'],
      'session_id': data['sessionId'],
      'user_id': data['userId'],
      'score': data['overallScore'],
      'outcome': data['outcome'],
      'breakdown': data['breakdown'],
      'highlights': data['highlights'],
      'personalized_feedback': data['personalizedFeedback'],
      'recommendations': data['recommendations'],
      'improvement_tips': data['improvementTips'],
      'average_response_seconds': data['averageResponseSeconds'],
      'total_response_seconds': data['totalResponseSeconds'],
      'valid_answers_count': data['validAnswersCount'],
      'analyzed_at': data['analyzedAt'],
    };
    await _supabase.from('interview_results').upsert(dbData);
  }

  @override
  Future<InterviewResultsModel?> getInterviewResultForSession(
    String sessionId,
  ) async {
    final response = await _supabase
        .from('interview_results')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();

    if (response == null) return null;

    final modelData = {
      'id': response['id'],
      'sessionId': response['session_id'],
      'userId': response['user_id'],
      'overallScore': response['score'],
      'outcome': response['outcome'],
      'breakdown': response['breakdown'],
      'highlights': response['highlights'],
      'personalizedFeedback': response['personalized_feedback'],
      'recommendations': response['recommendations'],
      'improvementTips': response['improvement_tips'],
      'averageResponseSeconds': response['average_response_seconds'] ?? 0,
      'totalResponseSeconds': response['total_response_seconds'] ?? 0,
      'validAnswersCount': response['valid_answers_count'] ?? 0,
      'analyzedAt': response['analyzed_at'],
    };
    return InterviewResultsModel.fromJson(modelData);
  }

  @override
  Future<List<InterviewResultsModel>> getInterviewResultsForUser(
    String userId,
  ) async {
    final response = await _supabase
        .from('interview_results')
        .select()
        .eq('user_id', userId)
        .order('analyzed_at', ascending: false);

    return (response as List).map((row) {
      final modelData = {
        'id': row['id'],
        'sessionId': row['session_id'],
        'userId': row['user_id'],
        'overallScore': row['score'],
        'outcome': row['outcome'],
        'breakdown': row['breakdown'],
        'highlights': row['highlights'],
        'personalizedFeedback': row['personalized_feedback'],
        'recommendations': row['recommendations'],
        'improvementTips': row['improvement_tips'],
        'averageResponseSeconds': row['average_response_seconds'] ?? 0,
        'totalResponseSeconds': row['total_response_seconds'] ?? 0,
        'validAnswersCount': row['valid_answers_count'] ?? 0,
        'analyzedAt': row['analyzed_at'],
      };
      return InterviewResultsModel.fromJson(modelData);
    }).toList();
  }
}
