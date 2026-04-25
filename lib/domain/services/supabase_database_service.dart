import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:prep_up/domain/entities/app_settings_model.dart';
import 'package:prep_up/domain/entities/interview_result_model.dart';
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
        .from('usuarios')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final response = await _supabase
        .from('usuarios')
        .select()
        .eq('email', email.toLowerCase())
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  @override
  Future<void> upsertUser(UserModel user) async {
    await _supabase.from('usuarios').upsert(user.toJson());
  }

  @override
  Future<AppSettingsModel?> getSettingsForUser(String userId) async {
    final response = await _supabase
        .from('configuraciones')
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
      enableHaptics: response['enable_haptics'] ?? true,
      enableNotifications: response['enable_notifications'] ?? true,
    );
  }

  @override
  Future<void> saveSettingsForUser(String userId, AppSettingsModel settings) async {
    await _supabase.from('configuraciones').upsert({
      'user_id': userId,
      'theme_mode': settings.themeMode.name,
      'enable_haptics': settings.enableHaptics,
      'enable_notifications': settings.enableNotifications,
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
      'created_at': data['createdAt'],
      'updated_at': data['updatedAt'],
    };
    await _supabase.from('sesiones_entrevista').upsert(dbData);
  }

  @override
  Future<InterviewSessionModel?> getInterviewSessionById(String sessionId) async {
    final response = await _supabase
        .from('sesiones_entrevista')
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
      'createdAt': response['created_at'],
      'updatedAt': response['updated_at'],
    };
    return InterviewSessionModel.fromJson(modelData);
  }

  @override
  Future<List<InterviewSessionModel>> getInterviewHistoryForUser(String userId) async {
    final response = await _supabase
        .from('sesiones_entrevista')
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
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      };
      return InterviewSessionModel.fromJson(modelData);
    }).toList();
  }

  @override
  Future<void> saveInterviewResult(InterviewResultModel result) async {
    final data = result.toJson();
    final dbData = {
      'id': data['id'],
      'session_id': data['sessionId'],
      'user_id': data['userId'],
      'score': data['score'],
      'success_probability': data['successProbability'],
      'breakdown': data['breakdown'],
      'recommendations': data['recommendations'],
      'analyzed_at': data['analyzedAt'],
    };
    await _supabase.from('resultados_entrevista').upsert(dbData);
  }

  @override
  Future<InterviewResultModel?> getInterviewResultForSession(String sessionId) async {
    final response = await _supabase
        .from('resultados_entrevista')
        .select()
        .eq('session_id', sessionId)
        .maybeSingle();

    if (response == null) return null;

    final modelData = {
      'id': response['id'],
      'sessionId': response['session_id'],
      'userId': response['user_id'],
      'score': response['score'],
      'successProbability': response['success_probability'],
      'breakdown': response['breakdown'],
      'recommendations': response['recommendations'],
      'analyzedAt': response['analyzed_at'],
    };
    return InterviewResultModel.fromJson(modelData);
  }
}
